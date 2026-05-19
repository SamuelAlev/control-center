import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// Proof of the `/proxy/vscode/<sid>/*` reverse proxy: capability authz
/// (unknown/foreign → 403, known → forwarded), prefix stripping + header
/// rewrite (frame-blocking headers stripped so the editor can render framed),
/// and HTTP pass-through to the loopbound code-server.
void main() {
  group('code-server reverse proxy', () {
    late Directory tmp;
    late HttpServer upstream;
    late LocalRpcServer server;
    late int serverPort;
    const knownSid = 'known-capability-token';
    const foreignSid = 'foreign-capability-token';

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_vscode_proxy_test');

      // A stub code-server upstream bound loopback. It echoes its received path
      // + method + a frame-blocking header so the test can assert both the
      // prefix-strip and the header rewrite.
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      upstream.listen((req) async {
        // Strip nothing — the proxy already stripped the prefix; this upstream
        // sees only the remainder. Echo it back so the test can verify.
        req.response.headers.set('X-Frame-Options', 'DENY');
        // A restrictive CSP the proxy must relax so the app can frame the editor.
        req.response.headers.set(
          'Content-Security-Policy',
          "default-src 'self'; frame-ancestors 'none'",
        );
        req.response.headers.set('X-Echo-Path', req.uri.path);
        req.response.headers.set('X-Echo-Method', req.method);
        req.response.writeln('upstream:${req.uri.path}');
        await req.response.close();
      });

      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets(),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        // The capability table: a known sid → a live session bound to the
        // upstream's port (in workspace 'wsA'); everything else → null → 403.
        codeServerLookup: (sid) {
          if (sid == knownSid) {
            return CodeServerSession(
              sessionId: sid,
              workspaceId: 'wsA',
              port: upstream.port,
              folderPath: '/tmp/fake-worktree',
              deviceId: 'device-a',
              expiresAt: DateTime.now().add(const Duration(hours: 1)),
              status: CodeServerStatus.ready,
            );
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
      await upstream.close(force: true);
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<HttpClientResponse> get(String path) async {
      final client = HttpClient();
      final resp = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:$serverPort$path'),
      )).close();
      return resp;
    }

    test('403 for an unknown / foreign capability', () async {
      final resp = await get('/proxy/vscode/$foreignSid/');
      await resp.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('403 for a missing capability (bare prefix)', () async {
      final resp = await get('/proxy/vscode/');
      await resp.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('forwards a known capability to the upstream with prefix stripped', () async {
      final resp = await get('/proxy/vscode/$knownSid/stable/vendor/x.js');
      final body = await resp.transform(utf8.decoder).join();
      expect(resp.statusCode, 200);
      // The upstream received only the remainder after the sid (prefix stripped).
      expect(resp.headers.value('x-echo-path'), '/stable/vendor/x.js');
      expect(resp.headers.value('x-echo-method'), 'GET');
      expect(body, contains('upstream:/stable/vendor/x.js'));
      // The frame-blocking header MUST be stripped so the editor renders framed.
      expect(resp.headers.value('x-frame-options'), isNull);
      // The upstream's restrictive `frame-ancestors 'none'` MUST be rewritten to
      // let the app frame the editor — including a loopback PORT WILDCARD so a
      // web dev bundle on an ephemeral localhost port (e.g. :57272) is allowed
      // (a bare `http://localhost` would match only port 80). Other directives
      // are preserved.
      final csp = resp.headers.value('content-security-policy') ?? '';
      expect(csp, contains('frame-ancestors'));
      expect(csp, isNot(contains("frame-ancestors 'none'")));
      expect(csp, contains('http://localhost:*'));
      expect(csp, contains("'self'"));
      expect(csp, contains("default-src 'self'")); // untouched directive kept
    });

    test(
      'forwards to the upstream root when the sid has no remainder',
      () async {
        final resp = await get('/proxy/vscode/$knownSid/');
        await resp.transform(utf8.decoder).join();
        expect(resp.statusCode, 200);
        expect(resp.headers.value('x-echo-path'), '/');
      },
    );

    test(
      '404 when no code-server capability is wired (lookup is null)',
      () async {
        // A second server with NO codeServerLookup → the route 404s honestly
        // rather than falling through to the static bundle.
        final noCap = LocalRpcServer(
          dispatcher: _StubDispatcher(),
          devicesDao: _StubDevicesDao(),
          secrets: _StubSecrets(),
          eventBus: DomainEventBus(),
          workspaceResolver: (_) async => const [],
          address: InternetAddress.loopbackIPv4,
          port: 0,
        );
        addTearDown(noCap.stop);
        await noCap.start();
        final client = HttpClient();
        final resp = await (await client.getUrl(
          Uri.parse(
            'http://127.0.0.1:${noCap.boundPort}/proxy/vscode/whatever/',
          ),
        )).close();
        await resp.drain<void>();
        expect(resp.statusCode, 404);
      },
    );
  });

  group('code-server reverse proxy content-encoding', () {
    // Regression: code-server gzips its responses when the browser sends
    // `Accept-Encoding: gzip`. The proxy MUST pass the compressed body through
    // byte-for-byte alongside its `content-encoding: gzip` header. If the
    // proxy's own HttpClient auto-decompresses the body (Dart's default) but
    // still forwards the gzip header, the browser tries to inflate plain bytes,
    // every asset + the workbench HTML fail to decode and code-server renders
    // a blank page. See LocalRpcServer._forwardCodeServerHttp (autoUncompress:
    // false).
    const knownSid = 'gzip-known-capability';
    const payload = 'workbench-html-body-that-must-round-trip';
    late Directory tmp;
    late HttpServer upstream;
    late LocalRpcServer server;
    late int serverPort;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_vscode_gzip_test');
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      upstream.listen((req) async {
        // Mimic code-server: gzip the body when the client accepts it and set
        // the matching content-encoding header. The proxy forwards the client's
        // Accept-Encoding (it must not inject its own), so this branch is hit
        // exactly when the downstream client asked for gzip.
        final acceptsGzip = (req.headers.value('accept-encoding') ?? '')
            .contains('gzip');
        req.response.headers.contentType = ContentType.html;
        if (acceptsGzip) {
          final gz = gzip.encode(utf8.encode(payload));
          req.response.headers.set('content-encoding', 'gzip');
          req.response.headers.set('content-length', '${gz.length}');
          req.response.add(gz);
        } else {
          req.response.add(utf8.encode(payload));
        }
        await req.response.close();
      });

      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets(),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        codeServerLookup: (sid) => sid == knownSid
            ? CodeServerSession(
                sessionId: sid,
                workspaceId: 'wsA',
                port: upstream.port,
                folderPath: '/tmp/fake-worktree',
                deviceId: 'device-a',
                expiresAt: DateTime.now().add(const Duration(hours: 1)),
                status: CodeServerStatus.ready,
              )
            : null,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      await server.start();
      serverPort = server.boundPort;
    });

    tearDown(() async {
      await server.stop();
      await upstream.close(force: true);
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('forwards a gzip body byte-faithfully (raw bytes stay gzip)', () async {
      // A browser-style client: asks for gzip, does NOT auto-decompress, so we
      // observe exactly what bytes the proxy put on the wire.
      final client = HttpClient()..autoUncompress = false;
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:$serverPort/proxy/vscode/$knownSid/'),
      );
      req.headers.set('accept-encoding', 'gzip');
      final resp = await req.close();
      final raw = <int>[];
      await resp.forEach(raw.addAll);

      // The header the browser will honour must still say gzip...
      expect(resp.headers.value('content-encoding'), 'gzip');
      // ...and the body must ACTUALLY be gzip (magic bytes 0x1f 0x8b), not the
      // silently-decompressed plaintext the pre-fix proxy forwarded.
      expect(raw.length, greaterThan(2));
      expect([raw[0], raw[1]], [0x1f, 0x8b]);
      // And it decodes back to the original payload.
      expect(utf8.decode(gzip.decode(raw)), payload);
      client.close();
    });

    test('a decompressing client gets the correct text end-to-end', () async {
      // The realistic browser path: Accept-Encoding: gzip + transparent inflate.
      // This only yields the right text if the forwarded body and its
      // content-encoding header agree (the bug made them disagree → blank page).
      final client = HttpClient(); // autoUncompress: true (default)
      final resp = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:$serverPort/proxy/vscode/$knownSid/'),
      )).close();
      final body = await resp.transform(utf8.decoder).join();
      expect(body, payload);
      client.close();
    });
  });

  group('code-server reverse proxy bridge report endpoint', () {
    // The bundled in-editor bridge extension POSTs open-file reports to
    // `/proxy/vscode/<sid>/__cc_open__`. The proxy must authorize it by the SAME
    // capability, hand a valid report to the reporter (→ a new app tab on the
    // client) and NOT forward it upstream to code-server.
    const knownSid = 'report-known-capability';
    late HttpServer upstream;
    late LocalRpcServer server;
    late int serverPort;
    late List<({String sid, String path, int? line})> reports;

    setUp(() async {
      reports = [];
      // Upstream that FAILS the test if the proxy ever forwards the report path.
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      upstream.listen((req) async {
        req.response.statusCode = HttpStatus.ok;
        req.response.headers.set('X-Reached-Upstream', req.uri.path);
        await req.response.close();
      });

      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets(),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        codeServerLookup: (sid) => sid == knownSid
            ? CodeServerSession(
                sessionId: sid,
                workspaceId: 'wsA',
                port: upstream.port,
                folderPath: '/tmp/fake-worktree',
                deviceId: 'device-a',
                expiresAt: DateTime.now().add(const Duration(hours: 1)),
                status: CodeServerStatus.ready,
              )
            : null,
        codeServerReport: (sid, path, line) =>
            reports.add((sid: sid, path: path, line: line)),
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      await server.start();
      serverPort = server.boundPort;
    });

    tearDown(() async {
      await server.stop();
      await upstream.close(force: true);
    });

    Future<HttpClientResponse> postReport(String sid, String body) async {
      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$serverPort/proxy/vscode/$sid/__cc_open__'),
      );
      req.headers.contentType = ContentType.json;
      req.write(body);
      return req.close();
    }

    test('a valid report reaches the reporter, not the upstream', () async {
      final resp = await postReport(
        knownSid,
        '{"path":"/tmp/fake-worktree/lib/foo.dart","line":41}',
      );
      await resp.drain<void>();
      expect(resp.statusCode, anyOf(HttpStatus.noContent, HttpStatus.ok));
      // Never forwarded upstream (a code-server would 404 `/__cc_open__`).
      expect(resp.headers.value('x-reached-upstream'), isNull);
      expect(reports, hasLength(1));
      expect(reports.single.sid, knownSid);
      expect(reports.single.path, '/tmp/fake-worktree/lib/foo.dart');
      expect(reports.single.line, 41);
    });

    test(
      'a report for an unknown capability is denied (403), not reported',
      () async {
        final resp = await postReport('foreign-sid', '{"path":"/x/y.dart"}');
        await resp.drain<void>();
        expect(resp.statusCode, 403);
        expect(reports, isEmpty);
      },
    );

    test('a malformed report body is ignored without error', () async {
      final resp = await postReport(knownSid, 'not-json');
      await resp.drain<void>();
      expect(resp.statusCode, anyOf(HttpStatus.noContent, HttpStatus.ok));
      expect(reports, isEmpty);
    });
  });

  group('code-server reverse proxy WebSocket bridge', () {
    const knownSid = 'ws-known-capability';

    // These tests prove the explicit Verification requirement: "WS upgrade
    // pipes frames both ways and closes cleanly." code-server's extension host,
    // integrated terminal, LSP results and file watcher all ride the proxied
    // WS, so the bidirectional bridge is load-bearing — a one-directional or
    // drop-on-close bridge would break the editor.

    test('pipes frames client → upstream → client (echo round-trip)', () async {
      final env = await _bootWsProxy(knownSid);
      addTearDown(env.server.stop);
      addTearDown(() => env.upstream.close(force: true));

      // Connect to the proxy as a WS client (this is what InAppWebView / the
      // iframe does for code-server's WS space).
      final client = await WebSocket.connect(
        'ws://127.0.0.1:${env.serverPort}/proxy/vscode/$knownSid/stable/echo',
      );
      addTearDown(client.close);

      final echoed = <String>[];
      final firstEcho = Completer<String>();
      late StreamSubscription sub;
      sub = client.listen(
        (frame) {
          if (frame is String && !firstEcho.isCompleted) {
            firstEcho.complete(frame);
          }
          if (frame is String) {
            echoed.add(frame);
          }
        },
        onError: (Object e) {
          if (!firstEcho.isCompleted) {
            firstEcho.completeError(e);
          }
        },
      );
      addTearDown(sub.cancel);

      // Client → proxy → upstream, then upstream echoes → proxy → client.
      client.add('hello-vscode');
      // The echo server sends the same bytes back, proving BOTH legs work.
      expect(
        await firstEcho.future.timeout(const Duration(seconds: 5)),
        'hello-vscode',
      );
      await client.close();
    });

    test('pipes multiple frames in order before closing cleanly', () async {
      final env = await _bootWsProxy(knownSid);
      addTearDown(env.server.stop);
      addTearDown(() => env.upstream.close(force: true));

      final client = await WebSocket.connect(
        'ws://127.0.0.1:${env.serverPort}/proxy/vscode/$knownSid/',
      );
      addTearDown(client.close);

      const expected = ['frame-0', 'frame-1', 'frame-2', 'frame-3'];
      final received = <String>[];
      final allEchoed = Completer<void>();
      final done = Completer<void>();
      client.listen(
        (frame) {
          if (frame is String) {
            received.add(frame);
            if (received.length == expected.length && !allEchoed.isCompleted) {
              allEchoed.complete();
            }
          }
        },
        onDone: done.complete,
        onError: (Object e) {
          if (!allEchoed.isCompleted) {
            allEchoed.completeError(e);
          }
          if (!done.isCompleted) {
            done.complete();
          }
        },
        cancelOnError: true,
      );

      // Send several frames; the echo server returns each in turn.
      for (var i = 0; i < expected.length; i++) {
        client.add(expected[i]);
      }
      // Wait for every echo to arrive BEFORE closing, else the close races and
      // cancels the subscription before the pending echoes are read.
      await allEchoed.future.timeout(const Duration(seconds: 5));
      await client.close();
      await done.future.timeout(const Duration(seconds: 5));

      // Order preserved across the bidirectional pipe (no reordering/drop).
      expect(received, expected);
    });

    test('closes cleanly when the client initiates the close', () async {
      final env = await _bootWsProxy(knownSid);
      addTearDown(env.server.stop);
      addTearDown(() => env.upstream.close(force: true));

      final client = await WebSocket.connect(
        'ws://127.0.0.1:${env.serverPort}/proxy/vscode/$knownSid/',
      );

      final closed = Completer<void>();
      client.listen(
        (_) {},
        onDone: closed.complete,
        onError: (_) {
          if (!closed.isCompleted) {
            closed.complete();
          }
        },
        cancelOnError: true,
      );

      await client.close();
      // The proxy's bridge must propagate the client close to the upstream and
      // then back to the client's own socket within a reasonable window — a
      // bridge that hangs open leaks the WS file-watcher connection forever.
      await closed.future.timeout(const Duration(seconds: 5));
    });

    test('denies a WS upgrade for an unknown capability', () async {
      final env = await _bootWsProxy(knownSid);
      addTearDown(env.server.stop);
      addTearDown(() => env.upstream.close(force: true));

      // An unknown capability must NOT bridge — the upgrade is refused before
      // any frame is piped. WebSocket.connect fails when the server rejects the
      // handshake (the proxy returns 403, so the upgrade never completes).
      await expectLater(
        WebSocket.connect(
          'ws://127.0.0.1:${env.serverPort}/proxy/vscode/foreign-ws-sid/',
        ),
        throwsA(
          anyOf(
            isA<WebSocketException>(),
            isA<HttpException>(),
            isA<StateError>(),
            isA<Exception>(),
          ),
        ),
      );
    });
  });
}

/// Minimal no-op RPC dispatcher (the proxy never dispatches RPC).
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      const {};
}

class _StubDevicesDao implements PairedDeviceDao {
  // The server's live-revocation watcher subscribes on start(); an empty
  // never-emitting stream keeps these transport-focused tests inert.
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

/// Boils a LocalRpcServer + a WebSocket-capable upstream echo server for the
/// WS-bridge tests. The known sid maps to the upstream's port; the proxy
/// upgrades the client and bridges to it, so a frame sent by the client lands
/// on the upstream and its echo lands back on the client (bidirectional).
Future<({LocalRpcServer server, HttpServer upstream, int serverPort})>
_bootWsProxy(String knownSid) async {
  // The upstream is a WebSocket ECHO server: whatever it receives, it sends
  // straight back. That exercises BOTH directions of the proxy bridge — the
  // client→upstream leg (the frame we send) and the upstream→client leg (the
  // echo). code-server's extension host / integrated terminal / LSP / file
  // watcher all ride this WS, so piping both ways is load-bearing.
  final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  upstream.listen((req) async {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final ws = await WebSocketTransformer.upgrade(req);
      await for (final frame in ws) {
        ws.add(frame); // echo back verbatim
      }
      await ws.close();
    } else {
      req.response.statusCode = HttpStatus.ok;
      await req.response.close();
    }
  });

  final server = LocalRpcServer(
    dispatcher: _StubDispatcher(),
    devicesDao: _StubDevicesDao(),
    secrets: _StubSecrets(),
    eventBus: DomainEventBus(),
    workspaceResolver: (_) async => const [],
    codeServerLookup: (sid) {
      if (sid == knownSid) {
        return CodeServerSession(
          sessionId: sid,
          workspaceId: 'wsA',
          port: upstream.port,
          folderPath: '/tmp/fake-worktree',
          deviceId: 'device-a',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          status: CodeServerStatus.ready,
        );
      }
      return null;
    },
    address: InternetAddress.loopbackIPv4,
    port: 0,
  );
  await server.start();
  return (server: server, upstream: upstream, serverPort: server.boundPort);
}
