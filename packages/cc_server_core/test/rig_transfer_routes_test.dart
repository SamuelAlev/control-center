import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// The `/rig/clipboard/<id>` and `/rig/files/<id>` lanes.
///
/// These carry BYTES, which is why they are HTTP routes rather than RPC ops
/// (the RPC socket closes a connection on an inbound frame over 256 KB). That
/// makes their auth a thing of their own rather than something inherited from
/// the RPC session, so it is what this file mostly pins: a signature over a
/// target of their own, an active device, workspace membership, and a
/// principal resolved for attribution.
void main() {
  group('rig transfer routes', () {
    const psk = 'test-psk-0123456789';
    const deviceId = 'device-a';
    const workspaceId = 'wsA';
    const rigId = 'rig-1';

    late LocalRpcServer server;
    late _RecordingRigPort rigs;
    late HttpClient client;
    late int port;

    String sign(String target) =>
        RemoteControlCrypto.signProxyTarget(target, psk);

    Uri url(String path, {Map<String, String> extra = const {}}) =>
        Uri.parse('http://127.0.0.1:$port$path').replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': sign(LocalRpcServer.rigTransferTarget(workspaceId, rigId)),
            ...extra,
          },
        );

    setUp(() async {
      rigs = _RecordingRigPort();
      client = HttpClient();
      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets(psk),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        rigTransfer: rigs,
        // Membership is the access boundary in this product, not possession
        // of a pairing key — the routes check it on top of the signature.
        resolveRole: (ws, userId) async =>
            ws == workspaceId ? WorkspaceRole.member : null,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      await server.start();
      port = server.boundPort;
    });

    tearDown(() async {
      client.close(force: true);
      await server.stop();
    });

    Future<HttpClientResponse> get(Uri uri) async =>
        (await client.getUrl(uri)).close();

    Future<HttpClientResponse> post(Uri uri, Object body) async {
      final request = await client.postUrl(uri);
      final bytes = utf8.encode(jsonEncode(body));
      request.headers.contentType = ContentType.json;
      request.contentLength = bytes.length;
      request.add(bytes);
      return request.close();
    }

    test('GET /rig/clipboard returns the guest clipboard as JSON', () async {
      rigs.clipboard = const RigClipboardData(
        text: 'hello',
        files: [RigGuestFile(name: 'a.txt', guestPath: '/home/cc/a.txt')],
      );

      final response = await get(url('/rig/clipboard/$rigId'));
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['text'], 'hello');
      final files = (body['files'] as List).cast<Map<String, dynamic>>();
      expect(files.single['guest_path'], '/home/cc/a.txt');
    });

    test(
      'the selection is passed through, defaulting to the clipboard',
      () async {
        await (await get(
          url('/rig/clipboard/$rigId', extra: {'sel': 'xdnd'}),
        )).drain<void>();
        expect(rigs.lastSelection, RigClipboardSelection.xdnd);

        await (await get(url('/rig/clipboard/$rigId'))).drain<void>();
        expect(rigs.lastSelection, RigClipboardSelection.clipboard);
      },
    );

    test('the caller is attributed to their USER, not their device', () async {
      // Every one of these lands in `rig_action_log`, and "device 4f2a" is not
      // an answer to "who took that file out of the machine".
      await (await get(url('/rig/clipboard/$rigId'))).drain<void>();

      expect(rigs.lastActor, const UserPrincipal('user-a'));
    });

    test('POST /rig/clipboard writes text and an image', () async {
      final response = await post(url('/rig/clipboard/$rigId'), {
        'text': 'hi',
        'image_base64': 'QUFB',
        'image_media_type': 'image/png',
      });
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['ok'], isTrue);
      expect(rigs.written?.text, 'hi');
      expect(rigs.written?.imageBase64, 'QUFB');
    });

    test('a refusal is a 200 with is_error, not an HTTP status', () async {
      // "A person holds control of this rig" is an ANSWER with a sentence the
      // client shows verbatim. An HTTP status has no room for that sentence.
      rigs.writeResult = RigActionResult.error('A person has taken control.');

      final response = await post(url('/rig/clipboard/$rigId'), {'text': 'x'});
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['is_error'], isTrue);
      expect(body['summary'], contains('taken control'));
    });

    test('POST /rig/files decodes the files and the drop point', () async {
      final response = await post(url('/rig/files/$rigId'), {
        'files': [
          {'name': 'a.txt', 'bytes': base64Encode(utf8.encode('body'))},
        ],
        'x': 40,
        'y': 12,
      });
      await response.drain<void>();

      expect(response.statusCode, 200);
      expect(rigs.dropped?.files.single.name, 'a.txt');
      expect(utf8.decode(rigs.dropped!.files.single.bytes), 'body');
      expect(rigs.dropped?.x, 40);
      expect(rigs.dropped?.y, 12);
    });

    test('a non-base64 payload is a 400, not a 500', () async {
      final response = await post(url('/rig/files/$rigId'), {
        'files': [
          {'name': 'a.txt', 'bytes': 'not base64!!'},
        ],
      });
      await response.drain<void>();

      expect(response.statusCode, 400);
    });

    test('GET /rig/files streams one file with its name and type', () async {
      rigs.file = RigFileBytes(
        name: 'report.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        mediaType: 'application/pdf',
      );

      final response = await get(
        url(
          '/rig/files/$rigId',
          // base64url, unpadded — the client strips '=' and the route re-pads.
          extra: {
            'p': base64Url
                .encode(utf8.encode('/home/cc/Drops/report.pdf'))
                .replaceAll('=', ''),
          },
        ),
      );
      final bytes = await response.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );

      expect(response.statusCode, 200);
      expect(bytes, [1, 2, 3]);
      expect(rigs.lastPath, '/home/cc/Drops/report.pdf');
      expect(response.headers.contentType?.mimeType, 'application/pdf');
      // RFC 5987: the name is guest-controlled, so a quote in it must not be
      // able to end the header value early.
      expect(
        response.headers.value('content-disposition'),
        contains("filename*=UTF-8''report.pdf"),
      );
    });

    test('an unreadable file is a 404', () async {
      rigs.file = null;

      final response = await get(
        url(
          '/rig/files/$rigId',
          extra: {
            'p': base64Url.encode(utf8.encode('/nope')).replaceAll('=', ''),
          },
        ),
      );
      await response.drain<void>();

      expect(response.statusCode, 404);
    });

    test('a bad signature is refused', () async {
      final response = await get(
        Uri.parse('http://127.0.0.1:$port/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': 'not-the-signature',
          },
        ),
      );
      await response.drain<void>();

      expect(response.statusCode, 403);
      expect(rigs.reads, 0, reason: 'the port must not have been touched');
    });

    test('the WATCH lane signature does not open the transfer lane', () async {
      // The two targets are separate on purpose: a URL minted to watch a
      // machine should not, by being pasted somewhere, also write files into
      // it.
      final response = await get(
        Uri.parse('http://127.0.0.1:$port/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': sign('rig:$workspaceId/$rigId'),
          },
        ),
      );
      await response.drain<void>();

      expect(response.statusCode, 403);
    });

    test('a signature for ANOTHER rig does not open this one', () async {
      final response = await get(
        Uri.parse('http://127.0.0.1:$port/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': sign(
              LocalRpcServer.rigTransferTarget(workspaceId, 'some-other-rig'),
            ),
          },
        ),
      );
      await response.drain<void>();

      expect(response.statusCode, 403);
    });

    test('a non-member is refused even with a valid signature', () async {
      // Membership, not possession of a pairing key, is the access boundary.
      final response = await get(
        Uri.parse('http://127.0.0.1:$port/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': 'wsForeign',
            'd': deviceId,
            's': sign(LocalRpcServer.rigTransferTarget('wsForeign', rigId)),
          },
        ),
      );
      await response.drain<void>();

      expect(response.statusCode, 403);
      expect(rigs.reads, 0);
    });

    test('a preflight allows the JSON POST a browser has to make', () async {
      // The shared proxy CORS allows GET only; a JSON POST is preflighted and
      // would be blocked by it.
      final request = await client.openUrl(
        'OPTIONS',
        url('/rig/clipboard/$rigId'),
      );
      final response = await request.close();
      await response.drain<void>();

      expect(response.statusCode, HttpStatus.noContent);
      expect(
        response.headers.value('access-control-allow-methods'),
        contains('POST'),
      );
      expect(
        response.headers.value('access-control-allow-headers'),
        contains('Content-Type'),
      );
    });

    test('a host with no enclosure support 404s rather than hanging', () async {
      final bare = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets(psk),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        resolveRole: (ws, userId) async => WorkspaceRole.member,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(bare.stop);
      await bare.start();

      final response = await (await client.getUrl(
        Uri.parse(
          'http://127.0.0.1:${bare.boundPort}/rig/clipboard/$rigId',
        ).replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': sign(LocalRpcServer.rigTransferTarget(workspaceId, rigId)),
          },
        ),
      )).close();
      await response.drain<void>();

      expect(response.statusCode, 404);
    });
  });
}

/// A [RigPort] that records what the routes asked it, and answers fixtures.
class _RecordingRigPort implements RigPort {
  RigClipboardData clipboard = RigClipboardData.empty;
  RigActionResult writeResult = RigActionResult.ok('written');
  RigFileBytes? file;

  int reads = 0;
  RigClipboardSelection? lastSelection;
  Principal? lastActor;
  RigClipboardData? written;
  RigDropRequest? dropped;
  String? lastPath;

  @override
  Future<RigClipboardData> readClipboard({
    required String workspaceId,
    required String rigId,
    required Principal actor,
    RigClipboardSelection selection = RigClipboardSelection.clipboard,
  }) async {
    reads++;
    lastSelection = selection;
    lastActor = actor;
    return clipboard;
  }

  @override
  Future<RigActionResult> writeClipboard({
    required String workspaceId,
    required String rigId,
    required RigClipboardData data,
    required Principal actor,
  }) async {
    written = data;
    lastActor = actor;
    return writeResult;
  }

  @override
  Future<RigDropResult> dropFiles({
    required String workspaceId,
    required String rigId,
    required RigDropRequest request,
    required Principal actor,
  }) async {
    dropped = request;
    lastActor = actor;
    return const RigDropResult(files: [], summary: 'ok');
  }

  @override
  Future<RigFileBytes?> readFile({
    required String workspaceId,
    required String rigId,
    required String guestPath,
    required Principal actor,
  }) async {
    lastPath = guestPath;
    lastActor = actor;
    return file;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubDispatcher implements RpcDispatcher {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubDevicesDao implements PairedDeviceDao {
  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  /// The route resolves the device's USER for attribution, so this has to
  /// answer with one.
  @override
  Future<PairedDevicesTableData?> getById(String id) async =>
      PairedDevicesTableData(
        id: id,
        userId: 'user-a',
        label: 'test device',
        platform: 'macos',
        pskRef: 'paired_device_psk_\$id',
        status: 'active',
        pairedAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSecrets implements PairedDeviceSecretsPort {
  _StubSecrets(this.psk);

  final String psk;

  @override
  Future<String?> readPsk(String deviceId) async => psk;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
