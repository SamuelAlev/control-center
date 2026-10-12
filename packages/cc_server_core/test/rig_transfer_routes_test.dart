import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
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
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:test/test.dart';

/// The rig clipboard, files and audio lanes use the Noise-authenticated
/// resource tunnel. Their signed targets remain separate operation gates.
void main() {
  group('rig transfer routes', () {
    final psk = RemoteControlCrypto.generatePsk();
    final otherPsk = RemoteControlCrypto.generatePsk();
    const deviceId = 'device-a';
    const workspaceId = 'wsA';
    const rigId = 'rig-1';

    late LocalRpcServer server;
    late _RecordingRigPort rigs;
    late RemoteRpcClient remote;
    late HttpClient publicClient;
    late Directory dataDir;
    late int port;
    late Uint8List microphoneBytes;
    late Principal microphoneActor;
    late bool microphoneEnd;
    late String microphoneSession;
    late bool microphoneStart;

    String sign(String target) =>
        RemoteControlCrypto.signProxyTarget(target, psk);

    Uri url(String path, {Map<String, String> extra = const {}}) => Uri(
      path: path,
      queryParameters: {
        'w': workspaceId,
        'd': deviceId,
        's': sign(LocalRpcServer.rigTransferTarget(workspaceId, rigId)),
        ...extra,
      },
    );

    Uri microphoneUrl({bool start = false, bool end = false}) => Uri(
      path: '/rig/stream/$rigId',
      queryParameters: {
        'w': workspaceId,
        'd': deviceId,
        's': sign('rig:$workspaceId/$rigId'),
        'lane': 'microphone',
        'rate': '16000',
        'channels': '1',
        'session': 'capture-a',
        if (start) 'start': '1',
        if (end) 'end': '1',
      },
    );

    Uri audioUrl() => Uri(
      path: '/rig/stream/$rigId',
      queryParameters: {
        'w': workspaceId,
        'd': deviceId,
        's': sign('rig:$workspaceId/$rigId'),
        'lane': 'audio',
      },
    );

    setUp(() async {
      dataDir = await Directory.systemTemp.createTemp('rig-transfer-routes-');
      addTearDown(() => dataDir.delete(recursive: true));
      rigs = _RecordingRigPort();
      publicClient = HttpClient();
      addTearDown(() => publicClient.close(force: true));
      microphoneBytes = Uint8List(0);
      microphoneActor = const UserPrincipal('unset');
      microphoneEnd = false;
      microphoneSession = '';
      microphoneStart = false;
      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets({deviceId: psk, 'device-b': otherPsk}),
        identity: await ServerIdentityStore.load(dataDir.path),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => id == workspaceId,
        rigTransfer: rigs,
        rigStream:
            ({
              required String workspaceId,
              required String rigId,
              required Map<String, dynamic> request,
            }) async => request['lane'] == 'audio'
            ? (
                bytes: Stream<List<int>>.value([0x49, 0x44, 0x33]),
                contentType: 'audio/mpeg',
              )
            : null,
        rigAudioInput:
            ({
              required String workspaceId,
              required String rigId,
              required Principal actor,
              required String sessionId,
              required Uint8List bytes,
              required int sampleRate,
              required int channels,
              required bool start,
              required bool end,
            }) async {
              microphoneBytes = Uint8List.fromList(bytes);
              microphoneActor = actor;
              microphoneSession = sessionId;
              microphoneStart = start;
              microphoneEnd = end;
              return sampleRate == 16000 && channels == 1;
            },
        // Membership is checked in addition to the signed target and the
        // Noise-authenticated device identity.
        resolveRole: (ws, userId) async =>
            ws == workspaceId && userId == 'user-a'
            ? WorkspaceRole.member
            : null,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(server.stop);
      await server.start();
      port = server.boundPort;
      remote = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:$port/rpc'),
        deviceId: deviceId,
        psk: psk,
        insecureAllowed: true,
      );
      addTearDown(() => remote.close());
    });

    Future<RemoteResourceResponse> get(Uri uri) =>
        remote.resources.request('GET', uri);

    Future<RemoteResourceResponse> post(Uri uri, Object body) {
      final bytes = utf8.encode(jsonEncode(body));
      return remote.resources.request(
        'POST',
        uri,
        headers: const {
          'content-type': ['application/json'],
        },
        body: Stream<List<int>>.value(bytes),
      );
    }

    Future<RemoteResourceResponse> postBytes(Uri uri, Uint8List bytes) =>
        remote.resources.request(
          'POST',
          uri,
          headers: const {
            'content-type': ['application/octet-stream'],
          },
          body: Stream<List<int>>.value(bytes),
        );

    test('GET /rig/clipboard returns the guest clipboard as JSON', () async {
      rigs.clipboard = const RigClipboardData(
        text: 'hello',
        files: [RigGuestFile(name: 'a.txt', guestPath: '/home/cc/a.txt')],
      );

      final response = await get(url('/rig/clipboard/$rigId'));
      final body =
          jsonDecode(await utf8.decoder.bind(response.body).join())
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
        )).body.drain<void>();
        expect(rigs.lastSelection, RigClipboardSelection.xdnd);

        await (await get(url('/rig/clipboard/$rigId'))).body.drain<void>();
        expect(rigs.lastSelection, RigClipboardSelection.clipboard);
      },
    );

    test('the caller is attributed to their USER, not their device', () async {
      // Every one of these lands in `rig_action_log`, and "device 4f2a" is not
      // an answer to "who took that file out of the machine".
      await (await get(url('/rig/clipboard/$rigId'))).body.drain<void>();

      expect(rigs.lastActor, const UserPrincipal('user-a'));
    });

    test('POST /rig/stream microphone attributes and forwards PCM', () async {
      final start = await postBytes(microphoneUrl(start: true), Uint8List(0));
      await start.body.drain<void>();
      expect(start.statusCode, HttpStatus.noContent);
      expect(microphoneSession, 'capture-a');
      expect(microphoneStart, isTrue);

      final response = await postBytes(
        microphoneUrl(),
        Uint8List.fromList([0, 1, 255, 127]),
      );
      await response.body.drain<void>();

      expect(response.statusCode, HttpStatus.noContent);
      expect(microphoneBytes, [0, 1, 255, 127]);
      expect(microphoneActor, const UserPrincipal('user-a'));
      expect(microphoneEnd, isFalse);
      expect(microphoneSession, 'capture-a');
      expect(microphoneStart, isFalse);

      final end = await postBytes(microphoneUrl(end: true), Uint8List(0));
      await end.body.drain<void>();
      expect(end.statusCode, HttpStatus.noContent);
      expect(microphoneBytes, isEmpty);
      expect(microphoneEnd, isTrue);
    });

    test('GET /rig/stream audio relays the guest output unchanged', () async {
      final response = await get(audioUrl());
      final bytes = await response.body.expand((chunk) => chunk).toList();

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers['content-type']?.single,
        startsWith('audio/mpeg'),
      );
      expect(bytes, [0x49, 0x44, 0x33]);
    });

    test('POST /rig/clipboard writes text and an image', () async {
      final response = await post(url('/rig/clipboard/$rigId'), {
        'text': 'hi',
        'image_base64': 'QUFB',
        'image_media_type': 'image/png',
      });
      final body =
          jsonDecode(await utf8.decoder.bind(response.body).join())
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
          jsonDecode(await utf8.decoder.bind(response.body).join())
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
      await response.body.drain<void>();

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
      await response.body.drain<void>();

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
      final bytes = await response.body.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );

      expect(response.statusCode, 200);
      expect(bytes, [1, 2, 3]);
      expect(rigs.lastPath, '/home/cc/Drops/report.pdf');
      expect(
        response.headers['content-type']?.single,
        startsWith('application/pdf'),
      );
      // RFC 5987: the name is guest-controlled, so a quote in it must not be
      // able to end the header value early.
      expect(
        response.headers['content-disposition']?.single,
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
      await response.body.drain<void>();

      expect(response.statusCode, 404);
    });

    test('a bad signature is refused', () async {
      final response = await get(
        Uri(path: '/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': 'not-the-signature',
          },
        ),
      );
      await response.body.drain<void>();

      expect(response.statusCode, 403);
      expect(rigs.reads, 0, reason: 'the port must not have been touched');
    });

    test('the WATCH lane signature does not open the transfer lane', () async {
      // The two targets are separate on purpose: a URL minted to watch a
      // machine should not, by being pasted somewhere, also write files into
      // it.
      final response = await get(
        Uri(path: '/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': sign('rig:$workspaceId/$rigId'),
          },
        ),
      );
      await response.body.drain<void>();

      expect(response.statusCode, 403);
    });

    test('a signature for ANOTHER rig does not open this one', () async {
      final response = await get(
        Uri(path: '/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': workspaceId,
            'd': deviceId,
            's': sign(
              LocalRpcServer.rigTransferTarget(workspaceId, 'some-other-rig'),
            ),
          },
        ),
      );
      await response.body.drain<void>();

      expect(response.statusCode, 403);
    });

    test('a non-member is refused even with a valid signature', () async {
      // Membership, not possession of a pairing key, is the access boundary.
      final response = await get(
        Uri(path: '/rig/clipboard/$rigId').replace(
          queryParameters: {
            'w': 'wsForeign',
            'd': deviceId,
            's': sign(LocalRpcServer.rigTransferTarget('wsForeign', rigId)),
          },
        ),
      );
      await response.body.drain<void>();

      expect(response.statusCode, 403);
      expect(rigs.reads, 0);
    });

    test(
      'a different authenticated device cannot reuse the signed URL',
      () async {
        final other = await connectRemoteRpc(
          uri: Uri.parse('ws://127.0.0.1:$port/rpc'),
          deviceId: 'device-b',
          psk: otherPsk,
          insecureAllowed: true,
        );
        try {
          final response = await other.resources.request(
            'GET',
            url('/rig/clipboard/$rigId'),
          );
          await response.body.drain<void>();
          expect(response.statusCode, HttpStatus.forbidden);
          final ownUrl = Uri(
            path: '/rig/clipboard/$rigId',
            queryParameters: {
              'w': workspaceId,
              'd': 'device-b',
              's': RemoteControlCrypto.signProxyTarget(
                LocalRpcServer.rigTransferTarget(workspaceId, rigId),
                otherPsk,
              ),
            },
          );
          final nonMember = await other.resources.request('GET', ownUrl);
          await nonMember.body.drain<void>();
          expect(nonMember.statusCode, HttpStatus.forbidden);
          expect(rigs.reads, 0);
        } finally {
          await other.close();
        }
      },
    );

    test(
      'an unregistered workspace is refused before reaching the rig',
      () async {
        final response = await get(
          Uri(
            path: '/rig/files/$rigId',
            queryParameters: {
              'w': 'wsForeign',
              'd': deviceId,
              's': sign(LocalRpcServer.rigTransferTarget('wsForeign', rigId)),
              'p': base64Url.encode(utf8.encode('/secret')).replaceAll('=', ''),
            },
          ),
        );
        await response.body.drain<void>();
        expect(response.statusCode, HttpStatus.forbidden);
        expect(rigs.lastPath, isNull);
      },
    );

    test('sealed OPTIONS retains the JSON POST preflight metadata', () async {
      final response = await remote.resources.request(
        'OPTIONS',
        url('/rig/clipboard/$rigId'),
      );
      await response.body.drain<void>();
      expect(response.statusCode, HttpStatus.noContent);
      expect(
        response.headers['access-control-allow-methods']?.single,
        contains('POST'),
      );
      expect(
        response.headers['access-control-allow-headers']?.single,
        contains('Content-Type'),
      );
    });

    test('signed public rig routes reject all byte methods with 426', () async {
      for (final (method, uri) in [
        ('GET', url('/rig/clipboard/$rigId')),
        ('POST', url('/rig/clipboard/$rigId')),
        ('OPTIONS', url('/rig/clipboard/$rigId')),
        ('GET', url('/rig/files/$rigId')),
        ('POST', url('/rig/files/$rigId')),
        ('GET', audioUrl()),
        ('POST', microphoneUrl()),
      ]) {
        final request = await publicClient.openUrl(
          method,
          Uri.parse('http://127.0.0.1:$port').resolveUri(uri),
        );
        final response = await request.close();
        await response.drain<void>();
        expect(
          response.statusCode,
          HttpStatus.upgradeRequired,
          reason: '$method ${uri.path}',
        );
      }
      expect(rigs.reads, 0);
      expect(rigs.written, isNull);
      expect(rigs.dropped, isNull);
      expect(microphoneSession, isEmpty);
    });

    test('a host with no enclosure support 404s through Noise', () async {
      final bare = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets({deviceId: psk}),
        identity: await ServerIdentityStore.load(dataDir.path),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => id == workspaceId,
        resolveRole: (ws, userId) async =>
            ws == workspaceId && userId == 'user-a'
            ? WorkspaceRole.member
            : null,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      await bare.start();
      try {
        final client = await connectRemoteRpc(
          uri: Uri.parse('ws://127.0.0.1:${bare.boundPort}/rpc'),
          deviceId: deviceId,
          psk: psk,
          insecureAllowed: true,
        );
        try {
          final response = await client.resources.request(
            'GET',
            url('/rig/clipboard/$rigId'),
          );
          await response.body.drain<void>();
          expect(response.statusCode, HttpStatus.notFound);
        } finally {
          await client.close();
        }
      } finally {
        await bare.stop();
      }
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
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      request.id == null
      ? const {}
      : {'jsonrpc': '2.0', 'id': request.id, 'result': <String, dynamic>{}};
}

class _StubDevicesDao implements PairedDeviceDao {
  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  /// The route resolves the device's USER for attribution, so this has to
  /// answer with one.
  @override
  Future<PairedDevicesTableData?> getById(String id) async =>
      id == 'device-a' || id == 'device-b'
      ? PairedDevicesTableData(
          id: id,
          userId: id == 'device-a' ? 'user-a' : 'user-b',
          label: 'test device',
          platform: 'macos',
          pskRef: 'paired_device_psk_$id',
          status: 'active',
          pairedAt: DateTime.now(),
          lastSeenAt: DateTime.now(),
        )
      : null;

  @override
  Future<int> markSeen(String id, DateTime at) async =>
      id == 'device-a' || id == 'device-b' ? 1 : 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSecrets implements PairedDeviceSecretsPort {
  _StubSecrets(this.psks);

  final Map<String, String> psks;

  @override
  Future<String?> readPsk(String deviceId) async => psks[deviceId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
