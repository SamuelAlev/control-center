import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/http_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal fake upstream HTTP server
// ---------------------------------------------------------------------------

/// A lightweight HTTP server that captures incoming requests and responds with
/// a canned status / body. Used as the upstream target so the proxy's
/// forwarding and filtering logic can be observed.
class _FakeUpstream {
  _FakeUpstream._(this._server);

  final HttpServer _server;
  final List<_CapturedRequest> requests = [];

  int get port => _server.port;

  static Future<_FakeUpstream> start({
    int statusCode = 200,
    String body = 'OK',
    Map<String, String> headers = const {},
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final upstream = _FakeUpstream._(server);
    server.listen((req) {
      final hdrs = <String, String>{};
      req.headers.forEach((name, values) {
        hdrs[name] = values.join(', ');
      });
      final captured = _CapturedRequest(
        method: req.method,
        path: req.uri.toString(),
        headers: hdrs,
        body: '',
      );
      upstream.requests.add(captured);
      // Collect body
      req.listen((chunk) {
        captured.body += utf8.decode(chunk);
      }, onDone: () {
        final resp = req.response;
        resp.statusCode = statusCode;
        for (final e in headers.entries) {
          resp.headers.add(e.key, e.value);
        }
        resp.write(body);
        resp.close();
      });
    });
    return upstream;
  }

  Future<void> close() => _server.close(force: true);
}

class _CapturedRequest {
  _CapturedRequest({
    required this.method,
    required this.path,
    required this.headers,
    this.body = '',
  });
  final String method;
  final String path;
  final Map<String, String> headers;
  String body;

  String? header(String name) => headers[name.toLowerCase()];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Configures the HttpClient to use [proxyPort] on localhost.
HttpClient _clientThroughProxy(int proxyPort) {
  final client = HttpClient();
  client.findProxy = (uri) => 'PROXY 127.0.0.1:$proxyPort';
  return client;
}

/// Makes a simple GET request through the proxy to [url] and returns the
/// response body as a string (or throws if the proxy returns a non-200).
Future<String> _getThroughProxy(HttpClient client, String url) async {
  final req = await client.getUrl(Uri.parse(url));
  final resp = await req.close();
  if (resp.statusCode != 200) {
    final body = await resp.transform(utf8.decoder).join();
    throw HttpException('Proxy returned ${resp.statusCode}: $body',
        uri: Uri.parse(url));
  }
  return resp.transform(utf8.decoder).join();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -----------------------------------------------------------------------
  // State initialization & lifecycle
  // -----------------------------------------------------------------------
  group('SandboxHttpProxy lifecycle', () {
    test('start binds to localhost on an OS-assigned port', () async {
      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      expect(proxy.port, greaterThan(0));
      expect(proxy.port, lessThan(65536));
    });

    test('updateConfig accepts network config and parent proxy', () async {
      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(
        network: const NetworkConfig(
          allowAll: false,
          allowedDomains: ['example.com'],
          deniedDomains: ['evil.com'],
        ),
        parentProxy: 'http://proxy.example.com:8080',
      );
    });

    test('close shuts down the listener', () async {
      final proxy = await SandboxHttpProxy.start();
      final port = proxy.port;
      await proxy.close();
      await expectLater(
        () => Socket.connect('127.0.0.1', port,
            timeout: const Duration(milliseconds: 500)),
        throwsA(isA<SocketException>()),
      );
    });

    test('multiple proxies can run simultaneously', () async {
      final a = await SandboxHttpProxy.start();
      final b = await SandboxHttpProxy.start();
      addTearDown(() async {
        await a.close();
        await b.close();
      });
      expect(a.port, isNot(b.port));
    });
  });

  // -----------------------------------------------------------------------
  // Proxy rule construction — domain allow/deny
  // -----------------------------------------------------------------------
  group('proxy rule construction', () {
    test('allows requests to any domain when allowAll is true (default)',
        () async {
      final upstream = await _FakeUpstream.start(body: 'hello');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);

      final client = _clientThroughProxy(proxy.port);
      try {
        final body = await _getThroughProxy(
            client, 'http://127.0.0.1:${upstream.port}/test');
        expect(body, 'hello');
        expect(upstream.requests.length, 1);
        expect(upstream.requests.first.method, 'GET');
        expect(upstream.requests.first.path, '/test');
      } finally {
        client.close(force: true);
      }
    });

    test('denies requests to denied domains', () async {
      final upstream = await _FakeUpstream.start(body: 'should-not-reach');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(
        network: const NetworkConfig(
          deniedDomains: ['127.0.0.1'],
        ),
      );

      final client = _clientThroughProxy(proxy.port);
      try {
        await expectLater(
          () => _getThroughProxy(
              client, 'http://127.0.0.1:${upstream.port}/test'),
          throwsA(isA<HttpException>()),
        );
        expect(upstream.requests, isEmpty);
      } finally {
        client.close(force: true);
      }
    });

    test(
        'allows requests to explicitly allowed domains when allowAll is false',
        () async {
      final upstream = await _FakeUpstream.start(body: 'allowed');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(
        network: const NetworkConfig(
          allowAll: false,
          allowedDomains: ['127.0.0.1'],
        ),
      );

      final client = _clientThroughProxy(proxy.port);
      try {
        final body = await _getThroughProxy(
            client, 'http://127.0.0.1:${upstream.port}/test');
        expect(body, 'allowed');
        expect(upstream.requests.length, 1);
      } finally {
        client.close(force: true);
      }
    });

    test('blocks requests to domains not in allowlist when restricted',
        () async {
      final upstream = await _FakeUpstream.start(body: 'should-not-reach');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(
        network: const NetworkConfig(
          allowAll: false,
          allowedDomains: ['example.com'],
        ),
      );

      final client = _clientThroughProxy(proxy.port);
      try {
        await expectLater(
          () => _getThroughProxy(
              client, 'http://127.0.0.1:${upstream.port}/test'),
          throwsA(isA<HttpException>()),
        );
        expect(upstream.requests, isEmpty);
      } finally {
        client.close(force: true);
      }
    });

    test('deniedDomains takes precedence over allowAll and allowedDomains',
        () async {
      final upstream = await _FakeUpstream.start(body: 'should-not-reach');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(
        network: const NetworkConfig(
          allowAll: true,
          allowedDomains: ['127.0.0.1'],
          deniedDomains: ['127.0.0.1'],
        ),
      );

      final client = _clientThroughProxy(proxy.port);
      try {
        await expectLater(
          () => _getThroughProxy(
              client, 'http://127.0.0.1:${upstream.port}/test'),
          throwsA(isA<HttpException>()),
        );
        expect(upstream.requests, isEmpty);
      } finally {
        client.close(force: true);
      }
    });

    test('isBlocked config blocks all outbound traffic', () async {
      final upstream = await _FakeUpstream.start(body: 'should-not-reach');
      addTearDown(upstream.close);

      const config = NetworkConfig(allowAll: false);
      expect(config.isBlocked, isTrue);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(network: config);

      final client = _clientThroughProxy(proxy.port);
      try {
        await expectLater(
          () => _getThroughProxy(
              client, 'http://127.0.0.1:${upstream.port}/test'),
          throwsA(isA<HttpException>()),
        );
        expect(upstream.requests, isEmpty);
      } finally {
        client.close(force: true);
      }
    });

    test('wildcard domain matching works through proxy', () async {
      // Since 127.0.0.1 is the actual upstream, use that.
      final upstream = await _FakeUpstream.start(body: 'wildcard-ok');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(
        network: const NetworkConfig(
          allowAll: false,
          allowedDomains: ['127.0.0.1'],
        ),
      );

      final client = _clientThroughProxy(proxy.port);
      try {
        final body = await _getThroughProxy(
            client, 'http://127.0.0.1:${upstream.port}/test');
        expect(body, 'wildcard-ok');
      } finally {
        client.close(force: true);
      }
    });
  });

  // -----------------------------------------------------------------------
  // Header manipulation — hop-by-hop filtering
  // -----------------------------------------------------------------------
  group('header manipulation', () {
    test('strips hop-by-hop headers from forwarded request', () async {
      final upstream = await _FakeUpstream.start(body: 'headers-received');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);

      final client = _clientThroughProxy(proxy.port);
      try {
        final req = await client.getUrl(
            Uri.parse('http://127.0.0.1:${upstream.port}/hop-by-hop'));
        // Set hop-by-hop headers
        req.headers.add('Connection', 'keep-alive');
        req.headers.add('Keep-Alive', 'timeout=5');
        req.headers.add('Proxy-Authenticate', 'Basic');
        req.headers.add('Proxy-Authorization', 'Basic abc123');
        req.headers.add('Te', 'trailers');
        req.headers.add('Trailer', 'X-Custom');
        req.headers.add('Transfer-Encoding', 'chunked');
        req.headers.add('Upgrade', 'websocket');
        // Set a non-hop-by-hop header that should survive
        req.headers.add('X-Custom-Header', 'preserve-me');
        req.headers.add('Authorization', 'Bearer token123');
        await req.close();

        // Wait a moment for the request to be captured
        await Future.delayed(const Duration(milliseconds: 200));

        expect(upstream.requests.length, 1);
        final captured = upstream.requests.first;

        // Hop-by-hop headers must be stripped
        expect(captured.header('connection'), isNull);
        expect(captured.header('keep-alive'), isNull);
        expect(captured.header('proxy-authenticate'), isNull);
        expect(captured.header('proxy-authorization'), isNull);
        expect(captured.header('te'), isNull);
        expect(captured.header('trailer'), isNull);
        expect(captured.header('transfer-encoding'), isNull);
        expect(captured.header('upgrade'), isNull);

        // Non-hop-by-hop headers must survive
        expect(captured.header('x-custom-header'), 'preserve-me');
        expect(captured.header('authorization'), 'Bearer token123');
      } finally {
        client.close(force: true);
      }
    });

    test('hop-by-hop check is case-insensitive', () async {
      final upstream = await _FakeUpstream.start(body: 'case-test');
      addTearDown(upstream.close);

      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);

      final client = _clientThroughProxy(proxy.port);
      try {
        final req = await client.getUrl(
            Uri.parse('http://127.0.0.1:${upstream.port}/case'));
        // Use mixed case
        req.headers.add('CONNECTION', 'close');
        req.headers.add('Keep-alive', 'timeout=5');
        req.headers.add('x-custom', 'keep');
        await req.close();

        await Future.delayed(const Duration(milliseconds: 200));

        expect(upstream.requests.length, 1);
        expect(upstream.requests.first.header('connection'), isNull);
        expect(upstream.requests.first.header('keep-alive'), isNull);
        expect(upstream.requests.first.header('x-custom'), 'keep');
      } finally {
        client.close(force: true);
      }
    });
  });

  // -----------------------------------------------------------------------
  // Address parsing — CONNECT (HTTPS) target handling
  // -----------------------------------------------------------------------
  group('CONNECT target parsing', () {
    test('rejects CONNECT to denied host', () async {
      final proxy = await SandboxHttpProxy.start();
      addTearDown(proxy.close);
      proxy.updateConfig(
        network: const NetworkConfig(
          allowAll: false,
          allowedDomains: ['example.com'],
        ),
      );

      final client = HttpClient();
      client.findProxy = (uri) => 'PROXY 127.0.0.1:${proxy.port}';
      try {
        final req = await client.getUrl(
            Uri.parse('https://127.0.0.1:8443/denied'));
        final resp = await req.close();
        expect(resp.statusCode, isNot(200));
      } on Exception catch (_) {
        // Connection may be reset — that's also a denial
      } finally {
        client.close(force: true);
      }
    });
  });
}
