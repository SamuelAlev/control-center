import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// Proof of the `/workspace/logo` endpoint: a thin client fetches the
/// workspace mark through the signed, PSK-authenticated route instead of
/// reading the server's disk directly. Mirrors `/meeting/audio`'s auth model.
void main() {
  group('/workspace/logo', () {
    late Directory tmp;
    late LocalRpcServer server;
    late int serverPort;
    late File logoFile;

    const deviceId = 'device-a';
    const workspaceId = 'ws-1';
    const psk = 'test-psk-12345';

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_workspace_logo_test');
      // A minimal valid 1x1 PNG the endpoint serves verbatim.
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      ]);
      logoFile = File('${tmp.path}/logo.png')..writeAsBytesSync(pngBytes);

      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(deviceId: deviceId),
        secrets: _StubSecrets(psk: psk),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
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
      await server.start();
      serverPort = server.boundPort;
    });

    tearDown(() async {
      await server.stop();
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    });

    /// Builds the signed query string mirroring [MediaProxyConfig.workspaceLogoUrl].
    String signedUrl(String wsId, {String? device, String? pskOverride}) {
      final d = device ?? deviceId;
      final target = 'workspace-logo:$wsId';
      final sig = RemoteControlCrypto.signProxyTarget(
        target,
        pskOverride ?? psk,
      );
      return '/workspace/logo?w=$wsId&d=$d&s=$sig';
    }

    Future<HttpClientResponse> get(String path) async {
      final client = HttpClient();
      return (await client.getUrl(
        Uri.parse('http://127.0.0.1:$serverPort$path'),
      )).close();
    }

    Future<HttpClientResponse> getWithHeaders(
      String path,
      Map<String, String> headers,
    ) async {
      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:$serverPort$path'),
      );
      headers.forEach(req.headers.set);
      return req.close();
    }

    test('serves the logo file with a valid signature', () async {
      final resp = await get(signedUrl(workspaceId));
      final bytes = await resp.expand((c) => c).toList();
      expect(resp.statusCode, 200);
      expect(resp.headers.contentType?.mimeType, 'image/png');
      expect(
        resp.headers.value('cross-origin-resource-policy'),
        'cross-origin',
      );
      // The exact bytes written to disk are the bytes served (TOCTOU-free).
      expect(bytes, logoFile.readAsBytesSync());
    });

    test('serves HTTP caching headers so the web tier stops re-fetching', () async {
      final resp = await get(signedUrl(workspaceId));
      await resp.drain<void>();
      expect(resp.statusCode, 200);
      final etag = resp.headers.value(HttpHeaders.etagHeader);
      expect(etag, isNotNull);
      expect(resp.headers.value('cache-control'), 'private, max-age=3600');
      expect(
        resp.headers.value(HttpHeaders.lastModifiedHeader),
        isNotNull,
      );

      // A conditional GET with the validator answers a cheap 304.
      final revalidated = await getWithHeaders(signedUrl(workspaceId), {
        HttpHeaders.ifNoneMatchHeader: etag!,
      });
      await revalidated.drain<void>();
      expect(revalidated.statusCode, 304);

      // A REPLACED logo (new mtime/size → new ETag) revalidates to a 200.
      logoFile.writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4]));
      final changed = await getWithHeaders(signedUrl(workspaceId), {
        HttpHeaders.ifNoneMatchHeader: etag,
      });
      await changed.drain<void>();
      expect(changed.statusCode, 200);
    });

    test('403 for a bad signature', () async {
      final resp = await get(
        '/workspace/logo?w=$workspaceId&d=$deviceId&s=bogus-sig',
      );
      await resp.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('403 for an unknown device (no PSK)', () async {
      final resp = await get(signedUrl(workspaceId, device: 'ghost-device'));
      await resp.drain<void>();
      expect(resp.statusCode, 403);
    });

    test(
      '404 when the workspace has no logo (resolver returns null)',
      () async {
        final resp = await get(signedUrl('ws-no-logo'));
        await resp.drain<void>();
        expect(resp.statusCode, 404);
      },
    );

    test('400 for missing query parameters', () async {
      final resp = await get('/workspace/logo?w=$workspaceId');
      await resp.drain<void>();
      expect(resp.statusCode, 400);
    });

    test('404 when no workspaceLogo resolver is wired', () async {
      final noResolver = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(deviceId: deviceId),
        secrets: _StubSecrets(psk: psk),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(noResolver.stop);
      await noResolver.start();
      final port = noResolver.boundPort;

      final client = HttpClient();
      final resp = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:$port${signedUrl(workspaceId)}'),
      )).close();
      await resp.drain<void>();
      expect(resp.statusCode, 404);
    });
  });
}

/// Minimal no-op RPC dispatcher (the logo route never dispatches RPC).
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      const {};
}

/// Returns a valid, non-expired [PairedDevicesTableData] for [deviceId].
class _StubDevicesDao implements PairedDeviceDao {
  _StubDevicesDao({required this.deviceId});

  final String deviceId;

  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  Future<PairedDevicesTableData?> getById(String id) async {
    if (id != deviceId) {
      return null;
    }
    return PairedDevicesTableData(
      id: id,
      label: 'Test',
      pskRef: 'paired_device_psk_$id',
      status: PairedDeviceStatus.active,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      pairedAt: DateTime.now(),
      platform: 'web',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns [psk] for any device (the test signs URLs with the same PSK).
class _StubSecrets implements PairedDeviceSecretsPort {
  _StubSecrets({required this.psk});

  final String psk;

  @override
  Future<String?> readPsk(String deviceId) async => psk;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
