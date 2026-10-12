import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:test/test.dart';

/// Proof that `/workspace/logo` retains its signed URL semantics while the
/// bytes travel only through an authenticated encrypted resource session.
void main() {
  group('/workspace/logo', () {
    late Directory tmp;
    late LocalRpcServer server;
    late RemoteRpcClient remote;
    late HttpClient publicClient;
    late int serverPort;
    late File logoFile;

    const deviceId = 'device-a';
    const otherDeviceId = 'device-b';
    const workspaceId = 'ws-1';
    const noLogoWorkspaceId = 'ws-no-logo';
    const userId = 'user-a';
    final psk = RemoteControlCrypto.generatePsk();
    final otherPsk = RemoteControlCrypto.generatePsk();

    bool workspaceExists(String id) =>
        id == workspaceId || id == noLogoWorkspaceId;

    Future<WorkspaceRole?> resolveRole(String id, String user) async =>
        workspaceExists(id) && user == userId ? WorkspaceRole.member : null;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_workspace_logo_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      // A minimal valid 1x1 PNG the endpoint serves verbatim.
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      ]);
      logoFile = File('${tmp.path}/logo.png')..writeAsBytesSync(pngBytes);

      publicClient = HttpClient();
      addTearDown(() => publicClient.close(force: true));
      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(deviceIds: {deviceId, otherDeviceId}),
        secrets: _StubSecrets(psks: {deviceId: psk, otherDeviceId: otherPsk}),
        identity: await ServerIdentityStore.load(tmp.path),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => workspaceExists(id),
        resolveRole: resolveRole,
        // The resolver returns the temp logo only for the signed workspace.
        workspaceLogo: ({required workspaceId}) async {
          if (workspaceId == 'ws-1') {
            return logoFile;
          }
          return null;
        },
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(server.stop);
      await server.start();
      serverPort = server.boundPort;
      remote = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:$serverPort/rpc'),
        deviceId: deviceId,
        psk: psk,
        insecureAllowed: true,
      );
      addTearDown(() => remote.close());
    });

    /// Builds the signed query string mirroring [MediaProxyConfig.workspaceLogoUrl].
    Uri signedUrl(String wsId, {String? device, String? pskOverride}) {
      final d = device ?? deviceId;
      final target = 'workspace-logo:$wsId';
      final sig = RemoteControlCrypto.signProxyTarget(
        target,
        pskOverride ?? psk,
      );
      return Uri(
        path: '/workspace/logo',
        queryParameters: {'w': wsId, 'd': d, 's': sig},
      );
    }

    Future<RemoteResourceResponse> get(Uri uri) =>
        remote.resources.request('GET', uri);

    Future<RemoteResourceResponse> getWithHeaders(
      Uri uri,
      Map<String, String> headers,
    ) => remote.resources.request(
      'GET',
      uri,
      headers: headers.map((name, value) => MapEntry(name, [value])),
    );

    String? header(RemoteResourceResponse response, String name) =>
        response.headers[name]?.firstOrNull;

    test('serves the logo file with a valid signature', () async {
      final resp = await get(signedUrl(workspaceId));
      final bytes = await resp.body.expand((c) => c).toList();
      expect(resp.statusCode, 200);
      expect(
        header(resp, HttpHeaders.contentTypeHeader),
        startsWith('image/png'),
      );
      expect(header(resp, 'cross-origin-resource-policy'), 'cross-origin');
      // The exact bytes written to disk are the bytes served (TOCTOU-free).
      expect(bytes, logoFile.readAsBytesSync());
    });

    test(
      'serves HTTP caching headers so the web tier stops re-fetching',
      () async {
        final resp = await get(signedUrl(workspaceId));
        await resp.body.drain<void>();
        expect(resp.statusCode, 200);
        final etag = header(resp, HttpHeaders.etagHeader);
        expect(etag, isNotNull);
        expect(header(resp, 'cache-control'), 'private, max-age=3600');
        expect(header(resp, HttpHeaders.lastModifiedHeader), isNotNull);

        // A conditional GET with the validator answers a cheap 304.
        final revalidated = await getWithHeaders(signedUrl(workspaceId), {
          HttpHeaders.ifNoneMatchHeader: etag!,
        });
        await revalidated.body.drain<void>();
        expect(revalidated.statusCode, 304);

        // A REPLACED logo (new mtime/size → new ETag) revalidates to a 200.
        logoFile.writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4]));
        final changed = await getWithHeaders(signedUrl(workspaceId), {
          HttpHeaders.ifNoneMatchHeader: etag,
        });
        await changed.body.drain<void>();
        expect(changed.statusCode, 200);
      },
    );

    test('403 for a bad signature', () async {
      final resp = await get(
        Uri(
          path: '/workspace/logo',
          queryParameters: {'w': workspaceId, 'd': deviceId, 's': 'bogus-sig'},
        ),
      );
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('403 for an unknown device (no PSK)', () async {
      final resp = await get(signedUrl(workspaceId, device: 'ghost-device'));
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('403 when device A uses device B signed URL', () async {
      final resp = await get(
        signedUrl(workspaceId, device: otherDeviceId, pskOverride: otherPsk),
      );
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test(
      '404 when the workspace has no logo (resolver returns null)',
      () async {
        final resp = await get(signedUrl(noLogoWorkspaceId));
        await resp.body.drain<void>();
        expect(resp.statusCode, 404);
      },
    );

    test('400 for missing query parameters', () async {
      final resp = await get(
        Uri.parse('/workspace/logo?w=$workspaceId&d=$deviceId'),
      );
      await resp.body.drain<void>();
      expect(resp.statusCode, 400);
    });

    test('public HTTP refuses a correctly signed logo URL with 426', () async {
      final resp = await (await publicClient.getUrl(
        Uri.parse(
          'http://127.0.0.1:$serverPort',
        ).resolveUri(signedUrl(workspaceId)),
      )).close();
      await resp.drain<void>();
      expect(resp.statusCode, HttpStatus.upgradeRequired);
    });

    test('404 when no workspaceLogo resolver is wired', () async {
      final noResolver = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(deviceIds: {deviceId, otherDeviceId}),
        secrets: _StubSecrets(psks: {deviceId: psk, otherDeviceId: otherPsk}),
        identity: await ServerIdentityStore.load(tmp.path),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => workspaceExists(id),
        resolveRole: resolveRole,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(noResolver.stop);
      await noResolver.start();
      final noResolverClient = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${noResolver.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
        insecureAllowed: true,
      );
      addTearDown(noResolverClient.close);
      final resp = await noResolverClient.resources.request(
        'GET',
        signedUrl(workspaceId),
      );
      await resp.body.drain<void>();
      expect(resp.statusCode, 404);
    });
  });
}

/// Answers session initialization; resource handlers are exercised separately.
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      request.id == null
      ? const {}
      : {'jsonrpc': '2.0', 'id': request.id, 'result': <String, dynamic>{}};
}

/// Returns active, user-bound paired devices for both signed URLs.
class _StubDevicesDao implements PairedDeviceDao {
  _StubDevicesDao({required this.deviceIds});

  final Set<String> deviceIds;

  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  Future<PairedDevicesTableData?> getById(String id) async {
    if (!deviceIds.contains(id)) {
      return null;
    }
    return PairedDevicesTableData(
      id: id,
      userId: 'user-a',
      label: 'Test',
      pskRef: 'paired_device_psk_$id',
      status: PairedDeviceStatus.active,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      pairedAt: DateTime.now(),
      platform: 'web',
    );
  }

  @override
  Future<int> markSeen(String id, DateTime at) async =>
      deviceIds.contains(id) ? 1 : 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns each paired device's independent PSK.
class _StubSecrets implements PairedDeviceSecretsPort {
  _StubSecrets({required this.psks});

  final Map<String, String> psks;

  @override
  Future<String?> readPsk(String deviceId) async => psks[deviceId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
