import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// The own-app callback page, over real HTTP: it sends the headers that keep
/// a browser from framing, sniffing, caching or leaking it, and it reflects
/// nothing from the request it answers, on success and on refusal alike.
void main() {
  const marker = '<script>alert(1)</script>';
  late Directory dir;
  late LocalRpcServer server;
  late ProviderSignInService service;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_provider_callback_page_');
    service = ProviderSignInService(
      connect: ConnectClient(
        settings: ConnectSettings(
          secrets: FileSecretsStore(dataDir: dir.path),
          environment: const {'CC_CONNECT_URL': 'https://connect.example'},
        ),
      ),
    )..register(_OwnAppLane());
    server = LocalRpcServer(
      dispatcher: _StubDispatcher(),
      devicesDao: _StubDevicesDao(),
      secrets: _StubSecrets(),
      eventBus: DomainEventBus(),
      workspaceResolver: (_) async => const [],
      address: InternetAddress.loopbackIPv4,
      port: 0,
      providerOAuth: service,
    );
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    dir.deleteSync(recursive: true);
  });

  Future<(HttpClientResponse, String)> get(Map<String, String> query) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.http(
          '127.0.0.1:${server.boundPort}',
          '/oauth/github/callback',
          query,
        ),
      );
      final response = await request.close();
      return (response, await response.transform(utf8.decoder).join());
    } finally {
      client.close();
    }
  }

  void expectHardened(HttpClientResponse response) {
    final csp = response.headers.value('content-security-policy')!;
    expect(csp, contains("default-src 'none'"));
    expect(csp, contains("frame-ancestors 'none'"));
    expect(csp, contains("form-action 'none'"));
    expect(csp, isNot(contains('script-src')));
    expect(response.headers.value('x-frame-options'), 'DENY');
    expect(response.headers.value('x-content-type-options'), 'nosniff');
    expect(response.headers.value('cache-control'), 'no-store');
    expect(response.headers.value('referrer-policy'), 'no-referrer');
    expect(response.headers.contentType?.mimeType, 'text/html');
  }

  void expectNothingReflected(String body, Map<String, String> query) {
    for (final value in query.values) {
      expect(body, isNot(contains(value)));
      expect(body, isNot(contains(htmlEscape.convert(value))));
      expect(body, isNot(contains(Uri.encodeQueryComponent(value))));
    }
  }

  test('the confirmation page is hardened and reflects nothing', () async {
    final attempt = await service.begin(
      lane: ConnectOAuthLane.github,
      userId: 'user-1',
      origin: 'http://127.0.0.1:${server.boundPort}',
      workspaceId: 'ws-1',
    );
    final query = {
      'state': attempt.url.queryParameters['state']!,
      'code': 'provider-code-$marker',
      'extra': marker,
    };

    final (response, body) = await get(query);

    expect(response.statusCode, HttpStatus.ok);
    expectHardened(response);
    expectNothingReflected(body, query);
    expect(body, isNot(contains('<script')));
  });

  test('the refusal page is hardened and reflects nothing', () async {
    final query = {
      'state': 'unknown-state-$marker',
      'code': 'provider-code-$marker',
      'error': marker,
      'error_description': 'described $marker',
    };

    final (response, body) = await get(query);

    expect(response.statusCode, HttpStatus.forbidden);
    expectHardened(response);
    expectNothingReflected(body, query);
    expect(body, isNot(contains('<script')));
  });
}

/// A GitHub lane that runs its own app; nothing past the callback is used.
final class _OwnAppLane implements SignInLaneBinding {
  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.github;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async => OwnOAuthApp(
    authorize: Uri.https('github.com', '/login/oauth/authorize'),
    token: Uri.https('github.com', '/login/oauth/access_token'),
    clientId: 'Iv1own',
    clientSecret: 'own-secret',
    scopes: const [],
  );

  @override
  Future<String?> slotFor(String? workspaceId) async => workspaceId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      const {};
}

class _StubDevicesDao implements PairedDeviceDao {
  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSecrets implements PairedDeviceSecretsPort {
  @override
  Future<String?> readPsk(String deviceId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
