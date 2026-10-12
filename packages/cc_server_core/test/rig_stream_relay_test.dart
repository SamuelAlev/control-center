import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/local_rpc_server.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:test/test.dart';

void main() {
  group('relay content type', () {
    test('a parameterised type keeps its subtype and its parameter', () {
      // The regression this pins: the relay split on '/' and used the tail as
      // the subtype, so this shipped as
      // `multipart/x-mixed-replace; boundary=ccrigframe` SUBTYPED on
      // "x-mixed-replace; boundary=ccrigframe" — a media type no client knows.
      final parsed = relayContentType(
        'multipart/x-mixed-replace; boundary=ccrigframe',
      );
      expect(parsed.primaryType, 'multipart');
      expect(parsed.subType, 'x-mixed-replace');
      expect(parsed.parameters['boundary'], 'ccrigframe');
    });

    test('every codec the rigs declare survives the round trip', () {
      for (final codec in RigStreamCodec.values) {
        final parsed = relayContentType(codec.contentType);
        expect(
          '${parsed.primaryType}/${parsed.subType}',
          codec.contentType,
          reason: 'The header must say exactly what the lane emits.',
        );
      }
    });

    test('the audio lane type is unchanged', () {
      final parsed = relayContentType('audio/mpeg');
      expect(parsed.mimeType, 'audio/mpeg');
    });

    test('a malformed type degrades to a blob rather than throwing', () {
      // A lane that cannot label itself is still a lane; killing the response
      // over the header would be a worse trade than an honest "unknown".
      expect(relayContentType('nonsense').mimeType, 'application/octet-stream');
    });
  });

  group('encrypted rig stream relay', () {
    const deviceId = 'stream-viewer';
    const workspaceId = 'rig-workspace';
    final psk = RemoteControlCrypto.generatePsk();
    late Directory temp;
    late LocalRpcServer server;
    late RemoteRpcClient client;
    late HttpClient publicClient;
    late StreamController<List<int>> audio;
    late Completer<void> cancelled;

    Uri streamUrl({String workspace = workspaceId, String device = deviceId}) =>
        Uri(
          path: '/rig/stream/rig-1',
          queryParameters: {
            'w': workspace,
            'd': device,
            's': RemoteControlCrypto.signProxyTarget(
              'rig:$workspace/rig-1',
              psk,
            ),
            'lane': 'audio',
          },
        );

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('rig-stream-relay-');
      addTearDown(() => temp.delete(recursive: true));
      cancelled = Completer<void>();
      audio = StreamController<List<int>>(
        onListen: () => audio.add([0x49, 0x44, 0x33]),
        onCancel: () {
          if (!cancelled.isCompleted) cancelled.complete();
        },
      );
      addTearDown(() async {
        if (audio.hasListener && !audio.isClosed) await audio.close();
      });
      publicClient = HttpClient();
      addTearDown(() => publicClient.close(force: true));
      server = LocalRpcServer(
        dispatcher: _StreamDispatcher(),
        devicesDao: _StreamDeviceDao(),
        secrets: _StreamSecrets(psk),
        identity: await ServerIdentityStore.load(temp.path),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => id == workspaceId,
        resolveRole: (ws, user) async =>
            ws == workspaceId && user == 'stream-user'
            ? WorkspaceRole.member
            : null,
        rigStream:
            ({
              required String workspaceId,
              required String rigId,
              required Map<String, dynamic> request,
            }) async => (bytes: audio.stream, contentType: 'audio/mpeg'),
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(server.stop);
      await server.start();
      client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
        insecureAllowed: true,
      );
      addTearDown(() => client.close());
    });

    test(
      'cancelling an authenticated audio response stops its source',
      () async {
        final response = await client.resources.request('GET', streamUrl());
        expect(response.statusCode, HttpStatus.ok);
        expect(
          response.headers['content-type']?.single,
          startsWith('audio/mpeg'),
        );

        final first = Completer<List<int>>();
        final subscription = response.body.listen(
          (bytes) {
            if (!first.isCompleted) first.complete(bytes);
          },
          onError: (Object error) {
            if (!first.isCompleted) first.completeError(error);
          },
        );
        expect(await first.future.timeout(const Duration(seconds: 5)), [
          0x49,
          0x44,
          0x33,
        ]);

        await response.close();
        await cancelled.future.timeout(const Duration(seconds: 5));
        await subscription.cancel();
      },
    );

    test('a signed public stream remains unavailable outside Noise', () async {
      final request = await publicClient.getUrl(
        Uri.parse(
          'http://127.0.0.1:${server.boundPort}',
        ).resolveUri(streamUrl()),
      );
      final response = await request.close();
      await response.drain<void>();
      expect(response.statusCode, HttpStatus.upgradeRequired);
    });

    test(
      'a stream URL cannot change its authenticated device or workspace',
      () async {
        for (final uri in [
          streamUrl(device: 'another-device'),
          streamUrl(workspace: 'another-workspace'),
        ]) {
          final response = await client.resources.request('GET', uri);
          await response.body.drain<void>();
          expect(response.statusCode, HttpStatus.forbidden);
        }
      },
    );
  });

  group('RigStreamUnavailable', () {
    test('carries a stable code the viewer can switch on', () {
      // The relay puts this on the wire as `x-rig-stream-error` so the viewer
      // can say "this host needs ffmpeg" instead of "the live view could not
      // be opened", which sends nobody anywhere.
      const error = RigStreamUnavailable(
        code: 'ffmpeg-missing',
        message: 'The mobile live view needs ffmpeg on the host.',
      );
      expect(error.code, 'ffmpeg-missing');
      expect('$error', contains('ffmpeg-missing'));
      expect('$error', contains('needs ffmpeg'));
    });
  });
}

class _StreamDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      request.id == null
      ? const {}
      : {'jsonrpc': '2.0', 'id': request.id, 'result': <String, dynamic>{}};
}

class _StreamDeviceDao implements PairedDeviceDao {
  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  Future<PairedDevicesTableData?> getById(String id) async =>
      id == 'stream-viewer'
      ? PairedDevicesTableData(
          id: id,
          userId: 'stream-user',
          label: 'stream viewer',
          platform: 'macos',
          pskRef: 'paired_device_psk_$id',
          status: 'active',
          pairedAt: DateTime.now(),
          lastSeenAt: DateTime.now(),
        )
      : null;

  @override
  Future<int> markSeen(String id, DateTime at) async =>
      id == 'stream-viewer' ? 1 : 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StreamSecrets implements PairedDeviceSecretsPort {
  _StreamSecrets(this.psk);

  final String psk;

  @override
  Future<String?> readPsk(String deviceId) async =>
      deviceId == 'stream-viewer' ? psk : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
