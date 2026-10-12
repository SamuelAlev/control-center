import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// Authenticated code-server reverse proxy: capability authorization, prefix
/// stripping, frame-header rewriting, and byte-faithful loopback forwarding.
void main() {
  group('code-server reverse proxy', () {
    late Directory tmp;
    late HttpServer upstream;
    late HttpHeaders upstreamHeaders;
    late LocalRpcServer server;
    late int serverPort;
    late RemoteRpcClient client;
    late String psk;
    late String secondPsk;
    late _StubDevicesDao devices;
    late DateTime sessionExpiresAt;
    late Completer<void> finishStream;
    const knownSid = 'known-capability-token';
    const foreignSid = 'foreign-capability-token';

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_vscode_proxy_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      psk = RemoteControlCrypto.generatePsk();
      secondPsk = RemoteControlCrypto.generatePsk();
      devices = _StubDevicesDao(psks: {'device-a': psk, 'device-b': secondPsk});
      finishStream = Completer<void>();
      sessionExpiresAt = DateTime.now().add(const Duration(hours: 1));

      // A stub code-server upstream bound loopback. It echoes its received path
      // + method + a frame-blocking header so the test can assert both the
      // prefix-strip and the header rewrite.
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => upstream.close(force: true));
      upstream.listen((req) async {
        upstreamHeaders = req.headers;
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
        if (req.uri.path == '/stream') {
          req.response.bufferOutput = false;
          req.response.write('first');
          await req.response.flush();
          await finishStream.future;
          req.response.write('-second');
          await req.response.close();
          return;
        }
        req.response.writeln('upstream:${req.uri.path}');
        await req.response.close();
      });

      server = LocalRpcServer(
        identity: await ServerIdentityStore.load(tmp.path),
        dispatcher: _StubDispatcher(),
        devicesDao: devices,
        secrets: _StubSecrets(psks: {'device-a': psk, 'device-b': secondPsk}),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => id == 'wsA',
        resolveRole: (id, user) async =>
            id == 'wsA' && user == 'user-a' ? WorkspaceRole.owner : null,
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
              expiresAt: sessionExpiresAt,
              status: CodeServerStatus.ready,
            );
          }
          return null;
        },
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(server.stop);
      await server.start();
      serverPort = server.boundPort;
      client = await _connect(server, 'device-a', psk);
      addTearDown(() => client.close());
    });

    Future<RemoteResourceResponse> get(String path) =>
        client.resources.request('GET', Uri.parse(path));

    test('403 for an unknown / foreign capability', () async {
      final resp = await get('/proxy/vscode/$foreignSid/');
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('403 for a missing capability (bare prefix)', () async {
      final resp = await get('/proxy/vscode/');
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('forwards a known capability to the upstream with prefix stripped', () async {
      final resp = await get('/proxy/vscode/$knownSid/stable/vendor/x.js');
      final body = await resp.body
          .cast<List<int>>()
          .transform(utf8.decoder)
          .join();
      expect(resp.statusCode, 200);
      // The upstream received only the remainder after the sid (prefix stripped).
      expect(_header(resp, 'x-echo-path'), '/stable/vendor/x.js');
      expect(_header(resp, 'x-echo-method'), 'GET');
      expect(body, contains('upstream:/stable/vendor/x.js'));
      expect(upstreamHeaders.value('x-cc-sealed-resource'), isNull);
      expect(upstreamHeaders.value('x-cc-resource-operation'), isNull);
      // The frame-blocking header MUST be stripped so the editor renders framed.
      expect(_header(resp, 'x-frame-options'), isNull);
      // The upstream's restrictive `frame-ancestors 'none'` MUST be rewritten to
      // let the app frame the editor — including a loopback PORT WILDCARD so a
      // web dev bundle on an ephemeral localhost port (e.g. :57272) is allowed
      // (a bare `http://localhost` would match only port 80). Other directives
      // are preserved.
      final csp = _header(resp, 'content-security-policy') ?? '';
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
        await resp.body.drain<void>();
        expect(resp.statusCode, 200);
        expect(_header(resp, 'x-echo-path'), '/');
      },
    );
    test('streams upstream bytes before the upstream finishes', () async {
      addTearDown(() {
        if (!finishStream.isCompleted) finishStream.complete();
      });
      final response = await get('/proxy/vscode/$knownSid/stream');
      expect(response.statusCode, HttpStatus.ok);
      final chunks = StreamIterator<List<int>>(response.body);
      addTearDown(chunks.cancel);
      expect(
        await chunks.moveNext().timeout(const Duration(seconds: 5)),
        isTrue,
      );
      expect(utf8.decode(chunks.current), 'first');
      finishStream.complete();
      final rest = <int>[];
      while (await chunks.moveNext()) {
        rest.addAll(chunks.current);
      }
      expect(utf8.decode(rest), '-second');
    });

    test('no capability lookup is refused before routing', () async {
      final noCap = LocalRpcServer(
        identity: await ServerIdentityStore.load(tmp.path),
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(psks: {'device-a': psk}),
        secrets: _StubSecrets(psks: {'device-a': psk}),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => id == 'wsA',
        resolveRole: (id, user) async =>
            id == 'wsA' && user == 'user-a' ? WorkspaceRole.owner : null,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(noCap.stop);
      await noCap.start();
      final noCapClient = await _connect(noCap, 'device-a', psk);
      addTearDown(noCapClient.close);
      final resp = await noCapClient.resources.request(
        'GET',
        Uri.parse('/proxy/vscode/whatever/'),
      );
      await resp.body.drain<void>();
      expect(resp.statusCode, 403);
    });

    test('another authenticated device cannot use this capability', () async {
      final other = await _connect(server, 'device-b', secondPsk);
      addTearDown(other.close);
      final response = await other.resources.request(
        'GET',
        Uri.parse('/proxy/vscode/$knownSid/'),
      );
      await response.body.drain<void>();
      expect(response.statusCode, HttpStatus.forbidden);
    });

    test('expired code-server session capability is forbidden', () async {
      sessionExpiresAt = DateTime.now().subtract(const Duration(seconds: 1));
      final response = await get('/proxy/vscode/$knownSid/');
      await response.body.drain<void>();
      expect(response.statusCode, HttpStatus.forbidden);
    });

    test(
      'expired paired device cannot use its existing resource channel',
      () async {
        devices.expiresAt['device-a'] = DateTime.now().subtract(
          const Duration(seconds: 1),
        );
        final response = await client.resources.request(
          'GET',
          Uri.parse('/proxy/vscode/$knownSid/'),
        );
        await response.body.drain<void>();
        expect(response.statusCode, HttpStatus.forbidden);
      },
    );

    test(
      'public code-server HTTP and WebSocket require encrypted channel',
      () async {
        final http = HttpClient();
        addTearDown(http.close);
        final response = await (await http.getUrl(
          Uri.parse('http://127.0.0.1:$serverPort/proxy/vscode/$knownSid/'),
        )).close();
        await response.drain<void>();
        expect(response.statusCode, HttpStatus.upgradeRequired);
        await expectLater(
          WebSocket.connect(
            'ws://127.0.0.1:$serverPort/proxy/vscode/$knownSid/',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('code-server reverse proxy content-encoding', () {
    // Regression: code-server gzips responses for `Accept-Encoding: gzip`.
    // Its forwarder must preserve compressed bytes through the private HTTP
    // hop; the secure resource adapter deliberately inflates the body for a
    // browser's synthetic Response and removes stale encoding/length headers.
    const knownSid = 'gzip-known-capability';
    const payload = 'workbench-html-body-that-must-round-trip';
    late Directory tmp;
    late HttpServer upstream;
    late LocalRpcServer server;
    late RemoteRpcClient client;
    late String psk;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_vscode_gzip_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      psk = RemoteControlCrypto.generatePsk();
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => upstream.close(force: true));
      upstream.listen((req) async {
        // Exercise compressed upstream bytes regardless of client negotiation.
        // The gateway owns that hop and returns a decoded synthetic response.
        final compressed = gzip.encode(utf8.encode(payload));
        req.response.headers.contentType = ContentType.html;
        req.response.headers.set('content-encoding', 'gzip');
        req.response.headers.contentLength = compressed.length;
        req.response.add(compressed);
        await req.response.close();
      });

      server = LocalRpcServer(
        identity: await ServerIdentityStore.load(tmp.path),
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(psks: {'device-a': psk}),
        secrets: _StubSecrets(psks: {'device-a': psk}),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => id == 'wsA',
        resolveRole: (id, user) async =>
            id == 'wsA' && user == 'user-a' ? WorkspaceRole.owner : null,
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
      addTearDown(server.stop);
      await server.start();
      client = await _connect(server, 'device-a', psk);
      addTearDown(() => client.close());
    });

    test('delivers one decompressed body with matching headers', () async {
      final resp = await client.resources.request(
        'GET',
        Uri.parse('/proxy/vscode/$knownSid/'),
        headers: const {
          'accept-encoding': ['gzip'],
        },
      );
      final bytes = await resp.body.expand((chunk) => chunk).toList();

      expect(_header(resp, 'content-encoding'), isNull);
      expect(_header(resp, 'content-length'), isNull);
      expect(utf8.decode(bytes), payload);
    });
  });

  group('code-server reverse proxy bridge report endpoint', () {
    // The server-side extension uses a separate, private instance id rather
    // than a client-visible code-server capability. Its reports and command
    // stream must never be reachable through the authenticated client route.
    const knownSid = 'report-known-public-capability';
    const bridgeSid = 'report-known-internal-bridge';
    late HttpServer upstream;
    late LocalRpcServer server;
    late Directory tmp;
    late RemoteRpcClient client;
    late String psk;
    late List<({String sid, String path, int? line, String? window})> reports;
    late List<({String sid, String path, bool dirty})> dirtyReports;
    late DateTime sessionExpiresAt;
    late StreamController<Map<String, dynamic>> commands;
    late Completer<void> commandListener;
    late Completer<void> commandCancelled;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_vscode_report_test');
      addTearDown(() => tmp.delete(recursive: true));
      psk = RemoteControlCrypto.generatePsk();
      sessionExpiresAt = DateTime.now().add(const Duration(hours: 1));
      reports = [];
      dirtyReports = [];
      commandListener = Completer<void>();
      commandCancelled = Completer<void>();
      commands = StreamController<Map<String, dynamic>>(
        onListen: () => commandListener.complete(),
        onCancel: () => commandCancelled.complete(),
      );
      addTearDown(() => unawaited(commands.close()));
      // Upstream that FAILS the test if the proxy ever forwards the report path.
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => upstream.close(force: true));
      upstream.listen((req) async {
        req.response.statusCode = HttpStatus.ok;
        req.response.headers.set('X-Reached-Upstream', req.uri.path);
        await req.response.close();
      });

      server = LocalRpcServer(
        identity: await ServerIdentityStore.load(tmp.path),
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(psks: {'device-a': psk}),
        secrets: _StubSecrets(psks: {'device-a': psk}),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        workspaceExists: (id) async => id == 'wsA',
        resolveRole: (id, user) async =>
            id == 'wsA' && user == 'user-a' ? WorkspaceRole.owner : null,
        codeServerLookup: (sid) => sid == knownSid
            ? CodeServerSession(
                sessionId: sid,
                workspaceId: 'wsA',
                port: upstream.port,
                folderPath: '/tmp/fake-worktree',
                deviceId: 'device-a',
                expiresAt: sessionExpiresAt,
                status: CodeServerStatus.ready,
              )
            : null,
        codeServerBridgeAllowed: (sid) =>
            sid == bridgeSid && sessionExpiresAt.isAfter(DateTime.now()),
        codeServerReport: (sid, path, line, window) =>
            reports.add((sid: sid, path: path, line: line, window: window)),
        codeServerCommandStream: (_) => commands.stream,
        codeServerReportDirty: (sid, path, dirty) =>
            dirtyReports.add((sid: sid, path: path, dirty: dirty)),
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(server.stop);
      await server.start();
      client = await _connect(server, 'device-a', psk);
      addTearDown(() => client.close());
    });

    Uri bridgeUrl(String sid, String endpoint) =>
        server.codeServerBridgeBase.resolve('proxy/vscode/$sid/$endpoint');

    Future<int> rawRequest(
      Uri uri, {
      String method = 'POST',
      String body = '{"path":"/tmp/fake-worktree/lib/foo.dart"}',
    }) async {
      final http = HttpClient();
      try {
        final request = await http.openUrl(method, uri);
        if (method == 'POST') {
          request.headers.contentType = ContentType.json;
          request.add(utf8.encode(body));
        }
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      } finally {
        http.close(force: true);
      }
    }

    Future<int> postReport(String sid, String body) =>
        rawRequest(bridgeUrl(sid, '__cc_open__'), body: body);

    test(
      'a valid private report reaches the reporter, not the upstream',
      () async {
        final status = await postReport(
          bridgeSid,
          '{"path":"/tmp/fake-worktree/lib/foo.dart","line":41}',
        );
        expect(status, HttpStatus.noContent);
        // The upstream would return 200 and never invoke the report callback.
        expect(reports, hasLength(1));
        expect(reports.single.sid, bridgeSid);
        expect(reports.single.path, '/tmp/fake-worktree/lib/foo.dart');
        expect(reports.single.line, 41);
        expect(reports.single.window, isNull);
      },
    );

    test('a private report carries the reporting window id', () async {
      final status = await postReport(
        bridgeSid,
        '{"path":"/tmp/fake-worktree/lib/foo.dart","line":3,"window":"w-1"}',
      );
      expect(status, HttpStatus.noContent);
      expect(reports.single.window, 'w-1');
    });

    test('an unknown bridge instance is refused before reporting', () async {
      expect(
        await postReport('foreign-sid', '{"path":"/x/y.dart"}'),
        HttpStatus.forbidden,
      );
      expect(reports, isEmpty);
    });

    test('a malformed private report is ignored without error', () async {
      expect(await postReport(bridgeSid, 'not-json'), HttpStatus.noContent);
      expect(reports, isEmpty);
    });

    test('a private dirty-state report reaches its callback', () async {
      expect(
        await postReport(
          bridgeSid,
          '{"type":"dirty","path":"/tmp/fake-worktree/lib/foo.dart","dirty":true}',
        ),
        HttpStatus.noContent,
      );
      expect(dirtyReports, [
        (sid: bridgeSid, path: '/tmp/fake-worktree/lib/foo.dart', dirty: true),
      ]);
      expect(reports, isEmpty);
    });

    test(
      'the local code-server bridge receives SSE commands and cancels',
      () async {
        final http = HttpClient();
        addTearDown(() => http.close(force: true));
        final request = await http.getUrl(
          bridgeUrl(bridgeSid, '__cc_commands__'),
        );
        final responseFuture = request.close();
        await commandListener.future.timeout(const Duration(seconds: 5));
        commands.add({
          'cmd': 'save',
          'path': '/tmp/fake-worktree/lib/foo.dart',
        });
        final response = await responseFuture.timeout(
          const Duration(seconds: 5),
        );
        expect(response.statusCode, HttpStatus.ok);
        expect(response.headers.contentType?.mimeType, 'text/event-stream');
        final firstEvent = response
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .firstWhere((line) => line.startsWith('data: '));
        expect(
          await firstEvent.timeout(const Duration(seconds: 5)),
          'data: {"cmd":"save","path":"/tmp/fake-worktree/lib/foo.dart"}',
        );
        http.close(force: true);
        await commandCancelled.future.timeout(const Duration(seconds: 5));
      },
    );

    test(
      'unknown sid and missing or wrong bridge capability cannot report',
      () async {
        expect(
          await rawRequest(bridgeUrl('foreign-sid', '__cc_open__')),
          HttpStatus.forbidden,
        );
        final privateBase = server.codeServerBridgeBase;
        final noCapability = privateBase.replace(
          path: '/proxy/vscode/$bridgeSid/__cc_open__',
        );
        expect(await rawRequest(noCapability), HttpStatus.forbidden);
        final badCapability = privateBase.replace(
          path:
              privateBase.path.replaceFirst(
                RegExp(r'[^/]+/$'),
                '${RemoteControlCrypto.generatePsk()}/',
              ) +
              'proxy/vscode/$bridgeSid/__cc_open__',
        );
        expect(await rawRequest(badCapability), HttpStatus.forbidden);
        expect(reports, isEmpty);
      },
    );

    test(
      'expired sessions and unrelated paths cannot use the private bridge',
      () async {
        final privateBase = server.codeServerBridgeBase;
        expect(
          await rawRequest(
            privateBase.resolve('proxy/vscode/$bridgeSid/stable/vendor/x.js'),
            method: 'GET',
          ),
          HttpStatus.forbidden,
        );
        expect(
          await rawRequest(bridgeUrl(bridgeSid, '__cc_commands__')),
          HttpStatus.forbidden,
        );
        sessionExpiresAt = DateTime.now().subtract(const Duration(seconds: 1));
        expect(
          await rawRequest(bridgeUrl(bridgeSid, '__cc_open__')),
          HttpStatus.forbidden,
        );
        expect(reports, isEmpty);
      },
    );

    test(
      'client-visible capabilities cannot submit extension reports or SSE',
      () async {
        final report = await client.resources.request(
          'POST',
          Uri.parse('/proxy/vscode/$knownSid/__cc_open__'),
          headers: const {
            'content-type': ['application/json'],
          },
          body: Stream.value(
            utf8.encode('{"path":"/tmp/fake-worktree/lib/foo.dart"}'),
          ),
        );
        await report.body.drain<void>();
        expect(report.statusCode, HttpStatus.forbidden);
        final stream = await client.resources.request(
          'GET',
          Uri.parse('/proxy/vscode/$knownSid/__cc_commands__'),
        );
        await stream.body.drain<void>();
        expect(stream.statusCode, HttpStatus.forbidden);
        expect(reports, isEmpty);
        expect(commandListener.isCompleted, isFalse);
      },
    );

    test('the public listener still refuses bridge reports and SSE', () async {
      final publicBase = Uri.parse('http://127.0.0.1:${server.boundPort}/');
      expect(
        await rawRequest(
          publicBase.resolve('proxy/vscode/$knownSid/__cc_open__'),
        ),
        HttpStatus.upgradeRequired,
      );
      expect(
        await rawRequest(
          publicBase.resolve('proxy/vscode/$knownSid/__cc_commands__'),
          method: 'GET',
        ),
        HttpStatus.upgradeRequired,
      );
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

      final client = await env.client.resources.connectWebSocket(
        Uri.parse('/proxy/vscode/$knownSid/stable/echo'),
        protocols: const ['vscode-test'],
      );
      expect(client.protocol, 'vscode-test');
      addTearDown(client.close);

      final firstEcho = Completer<String>();
      late StreamSubscription sub;
      sub = client.incoming.listen(
        (frame) {
          if (frame is String && !firstEcho.isCompleted) {
            firstEcho.complete(frame);
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
      await client.send('hello-vscode');
      // The echo server sends the same bytes back, proving BOTH legs work.
      expect(
        await firstEcho.future.timeout(const Duration(seconds: 5)),
        'hello-vscode',
      );
      await client.close();
    });

    test('pipes multiple frames in order before closing cleanly', () async {
      final env = await _bootWsProxy(knownSid);

      final client = await env.client.resources.connectWebSocket(
        Uri.parse('/proxy/vscode/$knownSid/'),
      );
      addTearDown(client.close);

      const expected = ['frame-0', 'frame-1', 'frame-2', 'frame-3'];
      final received = <String>[];
      final allEchoed = Completer<void>();
      final done = Completer<void>();
      client.incoming.listen(
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
        await client.send(expected[i]);
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

      final client = await env.client.resources.connectWebSocket(
        Uri.parse('/proxy/vscode/$knownSid/'),
      );

      final closed = Completer<void>();
      client.incoming.listen(
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

    test(
      'preserves binary frames over the bidirectional encrypted bridge',
      () async {
        final env = await _bootWsProxy(knownSid);
        final socket = await env.client.resources.connectWebSocket(
          Uri.parse('/proxy/vscode/$knownSid/stable/binary'),
        );
        addTearDown(socket.close);
        final echo = socket.incoming.first;
        await socket.send(<int>[0, 1, 255]);
        expect(await echo.timeout(const Duration(seconds: 5)), <int>[
          0,
          1,
          255,
        ]);
      },
    );

    test(
      'denies a second device the first device WebSocket capability',
      () async {
        final env = await _bootWsProxy(knownSid);
        final other = await _connect(env.server, 'device-b', env.secondPsk);
        addTearDown(other.close);
        await expectLater(
          other.resources.connectWebSocket(
            Uri.parse('/proxy/vscode/$knownSid/'),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('denies a WS upgrade for an unknown capability', () async {
      final env = await _bootWsProxy(knownSid);

      // An unknown capability must NOT bridge — the upgrade is refused before
      // any frame is piped. The encrypted resource upgrade reports 403.
      await expectLater(
        env.client.resources.connectWebSocket(
          Uri.parse('/proxy/vscode/foreign-ws-sid/'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

/// Completes the RPC handshake; resource requests bypass dispatch.
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      request.id == null
      ? const {}
      : {'jsonrpc': '2.0', 'id': request.id, 'result': <String, dynamic>{}};
}

class _StubDevicesDao implements PairedDeviceDao {
  _StubDevicesDao({required this.psks});

  final Map<String, String> psks;
  final Map<String, DateTime> expiresAt = {};

  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  Future<PairedDevicesTableData?> getById(String id) async {
    if (!psks.containsKey(id)) return null;
    return PairedDevicesTableData(
      id: id,
      userId: 'user-a',
      label: 'Test',
      pskRef: 'paired_device_psk_$id',
      status: PairedDeviceStatus.active,
      expiresAt: expiresAt[id] ?? DateTime.now().add(const Duration(hours: 1)),
      pairedAt: DateTime.now(),
      platform: 'web',
    );
  }

  @override
  Future<int> markSeen(String id, DateTime at) async =>
      psks.containsKey(id) ? 1 : 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSecrets implements PairedDeviceSecretsPort {
  _StubSecrets({required this.psks});

  final Map<String, String> psks;

  @override
  Future<String?> readPsk(String deviceId) async => psks[deviceId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String? _header(RemoteResourceResponse response, String name) {
  for (final header in response.headers.entries) {
    if (header.key.toLowerCase() == name) return header.value.join(', ');
  }
  return null;
}

Future<RemoteRpcClient> _connect(
  LocalRpcServer server,
  String deviceId,
  String psk,
) => connectRemoteRpc(
  uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
  deviceId: deviceId,
  psk: psk,
  insecureAllowed: true,
);

/// Boils a LocalRpcServer + a WebSocket-capable upstream echo server for the
/// WS-bridge tests. The known sid maps to the upstream's port; the proxy
/// upgrades the client and bridges to it, so a frame sent by the client lands
/// on the upstream and its echo lands back on the client (bidirectional).
Future<
  ({
    LocalRpcServer server,
    HttpServer upstream,
    RemoteRpcClient client,
    Directory tmp,
    String secondPsk,
  })
>
_bootWsProxy(String knownSid) async {
  // The upstream is a WebSocket ECHO server: whatever it receives, it sends
  // straight back. That exercises BOTH directions of the proxy bridge — the
  // client→upstream leg (the frame we send) and the upstream→client leg (the
  // echo). code-server's extension host / integrated terminal / LSP / file
  // watcher all ride this WS, so piping both ways is load-bearing.
  final tmp = Directory.systemTemp.createTempSync('cc_vscode_ws_test');
  addTearDown(() => tmp.delete(recursive: true));
  final psk = RemoteControlCrypto.generatePsk();
  final secondPsk = RemoteControlCrypto.generatePsk();
  final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => upstream.close(force: true));
  upstream.listen((req) async {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final ws = await WebSocketTransformer.upgrade(
        req,
        protocolSelector: (protocols) =>
            protocols.contains('vscode-test') ? 'vscode-test' : null,
      );
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
    identity: await ServerIdentityStore.load(tmp.path),
    dispatcher: _StubDispatcher(),
    devicesDao: _StubDevicesDao(psks: {'device-a': psk, 'device-b': secondPsk}),
    secrets: _StubSecrets(psks: {'device-a': psk, 'device-b': secondPsk}),
    eventBus: DomainEventBus(),
    workspaceResolver: (_) async => const [],
    workspaceExists: (id) async => id == 'wsA',
    resolveRole: (id, user) async =>
        id == 'wsA' && user == 'user-a' ? WorkspaceRole.owner : null,
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
  addTearDown(server.stop);
  await server.start();
  final client = await _connect(server, 'device-a', psk);
  addTearDown(client.close);
  return (
    server: server,
    upstream: upstream,
    client: client,
    tmp: tmp,
    secondPsk: secondPsk,
  );
}
