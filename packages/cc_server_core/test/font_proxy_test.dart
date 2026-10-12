import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:test/test.dart';

/// Proof of `/proxy/font`: a client asks for one variant BY NAME and the host
/// resolves it against its own catalogue.
///
/// The route exists because a client cannot fetch a usable font itself — an
/// upstream picks `woff2` for anything browser-shaped and Skia cannot decode it
/// — so the interesting properties are that the request carries no URL, that
/// only a catalogued family resolves and that the bytes arrive verbatim.
void main() {
  group('/proxy/font', () {
    late Directory tmp;
    late HttpServer upstream;
    late LocalRpcServer server;
    late RemoteRpcClient client;
    late String psk;
    late List<String> resolved;
    late int upstreamHits;

    const deviceId = 'device-a';
    const userId = 'user-a';
    final fontBytes = Uint8List.fromList([
      0x00, 0x01, 0x00, 0x00, // a TrueType version tag
      ...List<int>.filled(64, 0x42),
    ]);

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_font_proxy_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      psk = RemoteControlCrypto.generatePsk();
      final identity = await ServerIdentityStore.load(tmp.path);
      resolved = [];
      upstreamHits = 0;

      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => upstream.close(force: true));
      upstream.listen((req) async {
        upstreamHits++;
        req.response
          ..headers.contentType = ContentType('font', 'ttf')
          ..headers.set(HttpHeaders.cacheControlHeader, 'max-age=86400')
          ..add(fontBytes);
        await req.response.close();
      });

      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(deviceId: deviceId, userId: userId),
        secrets: _StubSecrets(psk: psk),
        eventBus: DomainEventBus(),
        identity: identity,
        workspaceExists: (_) async => false,
        resolveRole: (_, _) async => null,
        workspaceResolver: (_) async => const [],
        fontCacheDir: '${tmp.path}/font_cache',
        // Stands in for the catalogue: only 'Inter' exists and the snapped
        // variant is recorded so the parse can be asserted.
        fontFile:
            ({
              required String family,
              required int weight,
              required bool italic,
              required String subset,
            }) async {
              resolved.add('$family/$subset/$weight/$italic');
              if (family != 'Inter') {
                return null;
              }
              return Uri.parse(
                'http://127.0.0.1:${upstream.port}/inter-$weight.ttf',
              );
            },
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

    /// Mirrors `MediaProxyConfig.fontUrl`.
    String signedUrl({
      String family = 'Inter',
      int weight = 400,
      String style = 'normal',
      String subset = 'latin',
      String? device,
      String? signature,
    }) {
      final target = 'font:$family/$subset/$weight/$style';
      final sig = signature ?? RemoteControlCrypto.signProxyTarget(target, psk);
      return Uri(
        path: '/proxy/font',
        queryParameters: {
          'f': family,
          'wt': '$weight',
          'st': style,
          'sub': subset,
          'd': device ?? deviceId,
          's': sig,
        },
      ).toString();
    }

    Future<RemoteResourceResponse> get(String path) =>
        client.resources.request('GET', Uri.parse(path));

    test('serves the resolved font bytes verbatim', () async {
      final resp = await get(signedUrl());
      final bytes = await resp.body.expand((chunk) => chunk).toList();

      expect(resp.statusCode, 200);
      expect(bytes, fontBytes);
      expect(
        ContentType.parse(
          resp.headers[HttpHeaders.contentTypeHeader]!.single,
        ).mimeType,
        'font/ttf',
      );
    });

    test('passes the requested variant to the resolver', () async {
      await (await get(
        signedUrl(weight: 700, style: 'italic', subset: 'cyrillic'),
      )).body.drain<void>();

      expect(resolved, ['Inter/cyrillic/700/true']);
    });

    test(
      'caches the file, so a second client costs no upstream fetch',
      () async {
        // A font is not an image; without the buffering opt-in it would stream
        // straight through and never be stored.
        await (await get(signedUrl())).body.drain<void>();
        await (await get(signedUrl())).body.drain<void>();

        expect(upstreamHits, 1);
      },
    );

    test('403 for a bad signature', () async {
      final resp = await get(signedUrl(signature: 'bogus'));
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('403 when the signature covers a different variant', () async {
      // Otherwise one signed URL would authorise the whole family.
      final forWeight400 = RemoteControlCrypto.signProxyTarget(
        'font:Inter/latin/400/normal',
        psk,
      );
      final resp = await get(signedUrl(weight: 700, signature: forWeight400));
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('403 for an unknown device', () async {
      final resp = await get(signedUrl(device: 'ghost-device'));
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('404 for a family the catalogue does not have', () async {
      // The ownership check: an OS-installed family, or an injected URL, has no
      // catalogue entry and therefore no upstream.
      final resp = await get(signedUrl(family: 'Menlo'));
      await resp.body.drain<void>();
      expect(resp.statusCode, 404);
      expect(upstreamHits, 0);
    });

    test('400 for missing parameters', () async {
      final resp = await get('/proxy/font?f=Inter&d=$deviceId');
      await resp.body.drain<void>();
      expect(resp.statusCode, 400);
    });

    test('400 for an out-of-range weight or unknown style', () async {
      for (final url in [
        signedUrl(weight: 0),
        signedUrl(weight: 5000),
        signedUrl(style: 'oblique'),
      ]) {
        final resp = await get(url);
        await resp.body.drain<void>();
        expect(resp.statusCode, 400, reason: url);
      }
      expect(resolved, isEmpty, reason: 'rejected before resolving');
    });

    test('404 when no font resolver is wired', () async {
      final noResolver = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(deviceId: deviceId, userId: userId),
        secrets: _StubSecrets(psk: psk),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        identity: await ServerIdentityStore.load(tmp.path),
        workspaceExists: (_) async => false,
        resolveRole: (_, _) async => null,
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
        Uri.parse(signedUrl()),
      );
      await resp.body.drain<void>();

      expect(resp.statusCode, 404);
    });

    test('public HTTP refuses signed font URLs even on loopback', () async {
      final publicClient = HttpClient();
      addTearDown(() => publicClient.close(force: true));
      final resp = await (await publicClient.getUrl(
        Uri.parse('http://127.0.0.1:${server.boundPort}${signedUrl()}'),
      )).close();
      await resp.drain<void>();

      expect(resp.statusCode, HttpStatus.upgradeRequired);
      expect(upstreamHits, 0);
      expect(resolved, isEmpty);
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

/// Returns a valid, non-expired [PairedDevicesTableData] for [deviceId].
class _StubDevicesDao implements PairedDeviceDao {
  _StubDevicesDao({required this.deviceId, required this.userId});

  final String deviceId;
  final String userId;

  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  Future<PairedDevicesTableData?> getById(String id) async {
    if (id != deviceId) {
      return null;
    }
    return PairedDevicesTableData(
      id: id,
      userId: userId,
      label: 'Test',
      pskRef: 'paired_device_psk_$id',
      status: PairedDeviceStatus.active,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      pairedAt: DateTime.now(),
      platform: 'web',
    );
  }

  @override
  Future<int> markSeen(String id, DateTime at) async => id == deviceId ? 1 : 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns the paired device's PSK for signing and authenticating test requests.
class _StubSecrets implements PairedDeviceSecretsPort {
  _StubSecrets({required this.psk});

  final String psk;

  @override
  Future<String?> readPsk(String deviceId) async => psk;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
