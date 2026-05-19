import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_infra/cc_infra.dart' show ChatDeepLinks;
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// Proof of `GET /open/...`: the one hop that turns a link a chat app will accept
/// into the `control-center://` deep link only the desktop understands.
///
/// It is the only route that hands a browser somewhere else, so the properties
/// that matter are that the destination is always this app's own scheme and that
/// an id which did not come from Control Center is a 404 rather than something
/// echoed into a page.
void main() {
  late LocalRpcServer server;

  setUp(() async {
    server = LocalRpcServer(
      dispatcher: _StubDispatcher(),
      devicesDao: _StubDevicesDao(),
      secrets: _StubSecrets(),
      eventBus: DomainEventBus(),
      workspaceResolver: (_) async => const [],
      address: InternetAddress.loopbackIPv4,
      port: 0,
    );
    await server.start();
  });

  tearDown(() => server.stop());

  Future<HttpClientResponse> request(String path, {String method = 'GET'}) async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    return (await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:${server.boundPort}$path'),
    )).close();
  }

  test('a space link bounces to the desktop route', () async {
    final resp = await request(
      '${ChatDeepLinks.pathPrefix}/workspaces/ws-1/spaces/chan-1',
    );
    final body = await resp.transform(utf8.decoder).join();

    expect(resp.statusCode, 200);
    expect(resp.headers.contentType?.mimeType, 'text/html');
    // Never cached: the page is a redirect and a stale one sends the reader to
    // the wrong conversation.
    expect(resp.headers.value('cache-control'), 'no-store');
    expect(resp.headers.value('x-frame-options'), 'DENY');
    // Both hand-offs: the automatic one and the button for browsers that want a
    // gesture before leaving for another scheme.
    expect(body, contains('location.replace'));
    expect(
      body,
      contains('control-center://workspaces/ws-1/spaces/chan-1'),
    );
  });

  test('a ticket link bounces to the ticket route', () async {
    final resp = await request(
      '${ChatDeepLinks.pathPrefix}/workspaces/ws-1/tickets/ticket-9',
    );
    final body = await resp.transform(utf8.decoder).join();

    expect(resp.statusCode, 200);
    expect(body, contains('control-center://workspaces/ws-1/tickets/ticket-9'));
  });

  test('the page reads nothing: an unknown workspace still bounces', () async {
    // Deliberate. Resolving the id here would turn a public route into an
    // existence oracle; the app the link opens does the authorization.
    final resp = await request(
      '${ChatDeepLinks.pathPrefix}/workspaces/ws-nope/spaces/chan-nope',
    );
    await resp.drain<void>();

    expect(resp.statusCode, 200);
  });

  test('anything but a plain id is a 404, not a redirect', () async {
    for (final path in [
      // A traversal that would otherwise reach another route's shape.
      '/open/workspaces/ws-1/spaces/..%2F..%2Fetc',
      // A scheme smuggled into the id — the reason the shape check exists.
      '/open/workspaces/ws-1/spaces/https:%2F%2Fevil.example',
      // An unknown kind, a missing segment and a segment too many.
      '/open/workspaces/ws-1/secrets/x',
      '/open/workspaces/ws-1/spaces',
      '/open/workspaces/ws-1/spaces/chan-1/extra',
      '/open/ws-1/spaces/chan-1',
      '/open/',
    ]) {
      final resp = await request(path);
      await resp.drain<void>();
      expect(resp.statusCode, 404, reason: path);
    }
  });

  test('only a read opens a link', () async {
    final resp = await request(
      '${ChatDeepLinks.pathPrefix}/workspaces/ws-1/spaces/chan-1',
      method: 'POST',
    );
    await resp.drain<void>();

    expect(resp.statusCode, 405);
  });
}

/// Minimal no-op RPC dispatcher (the bounce page never dispatches RPC).
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      const {};
}

/// No PSK exists, because no device does.
class _StubSecrets implements PairedDeviceSecretsPort {
  @override
  Future<String?> readPsk(String deviceId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// No device is ever paired: the bounce page is reachable without one.
class _StubDevicesDao implements PairedDeviceDao {
  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  Future<PairedDevicesTableData?> getById(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
