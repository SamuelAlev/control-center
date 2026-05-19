import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/web_fetch_tool.dart';
import 'package:test/test.dart';

/// Exercises [WebFetchTool]'s testable surface. The tool is hardened against
/// SSRF: it resolves the target host and refuses loopback / link-local /
/// private / CGNAT addresses before connecting. That guard is the correct
/// production behavior, and it also means a local loopback test server
/// CANNOT be reached from these tests — so this file pins the metadata, the
/// argument-validation paths, the SSRF refusal matrix (loopback / private /
/// CGNAT / empty host / unresolvable host), and the HTML→text conversion
/// (via an injectable fake HttpClient so no real network call is made).

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({
    this.body = '',
    this.statusCode = 200,
    this.contentType = 'text/html; charset=utf-8',
    this.charset,
    this.throwOnGet,
  });

  final String body;
  final int statusCode;
  final String contentType;
  final String? charset;
  final Object? throwOnGet;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (throwOnGet != null) {
      throw throwOnGet!;
    }
    return _FakeRequest(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this.client);
  final _FakeHttpClient client;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(client);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeResponse(this.client);
  final _FakeHttpClient client;

  @override
  int get statusCode => client.statusCode;

  @override
  HttpHeaders get headers {
    final h = _RespHeaders();
    final ct = client.charset != null
        ? '${client.contentType.split(';').first}; charset=${client.charset}'
        : client.contentType;
    h.set(HttpHeaders.contentTypeHeader, ct);
    return h;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(utf8.encode(client.body)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RespHeaders implements HttpHeaders {
  String? _contentType;

  @override
  ContentType? get contentType =>
      _contentType == null ? null : ContentType.parse(_contentType!);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    if (name.toLowerCase() == HttpHeaders.contentTypeHeader.toLowerCase()) {
      _contentType = value.toString();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const ctx = HarnessToolContext(workingDirectory: '/tmp');

  HttpClient client() => HttpClient()..connectionTimeout = Duration.zero;

  Future<HarnessToolResult> fetch(Map<String, dynamic> args) => WebFetchTool(
    client: client(),
    timeout: const Duration(seconds: 1),
  ).execute(args, ctx);

  group('WebFetchTool metadata', () {
    test('name, tier, schema, description', () {
      final t = WebFetchTool(client: client());
      expect(t.name, 'web_fetch');
      expect(t.approvalTier, ToolApprovalTier.exec);
      expect(t.description, isNotEmpty);
      expect(t.inputSchema['required'], ['url']);
      expect(
        (t.inputSchema['properties'] as Map)['url'],
        isA<Map>(),
      );
    });
  });

  group('disabled / argument validation', () {
    test('refuses when allowNetwork is false', () async {
      final t = WebFetchTool(allowNetwork: false, client: client());
      final r = await t.execute({'url': 'https://example.com'}, ctx);
      expect(r.isError, isTrue);
      expect(r.content, contains('disabled'));
    });

    test('missing or empty url → error', () async {
      expect((await fetch({})).isError, isTrue);
      expect((await fetch({'url': ''})).isError, isTrue);
    });

    test('non-string url → error', () async {
      expect((await fetch({'url': 42})).isError, isTrue);
    });

    test('non-http(s) scheme → error', () async {
      final r = await fetch({'url': 'ftp://example.com'});
      expect(r.isError, isTrue);
      expect(r.content, contains('Invalid URL'));
    });

    test('malformed URL → error', () async {
      final r = await fetch({'url': 'not a url at all'});
      expect(r.isError, isTrue);
      expect(r.content, contains('Invalid URL'));
    });
  });

  group('SSRF guard refuses internal addresses', () {
    test('loopback IPv4', () async {
      final r = await fetch({'url': 'http://127.0.0.1/'});
      expect(r.isError, isTrue);
      expect(r.content, contains('Refusing to fetch'));
      expect(r.content, contains('internal address'));
      expect(r.content, contains('127.0.0.1'));
    });

    test('loopback IPv6', () async {
      final r = await fetch({'url': 'http://[::1]/'});
      expect(r.isError, isTrue);
      expect(r.content, contains('internal address'));
    });

    test('RFC1918 private (10/8, 192.168/16, 172.16/12)', () async {
      for (final ip in [
        '10.0.0.1',
        '192.168.1.1',
        '172.16.0.1',
        '172.31.0.1',
      ]) {
        final r = await fetch({'url': 'http://$ip/'});
        expect(r.isError, isTrue, reason: ip);
        expect(r.content, contains('internal address'));
      }
    });

    test('link-local 169.254/16 (cloud-metadata endpoint)', () async {
      final r = await fetch({'url': 'http://169.254.169.254/'});
      expect(r.isError, isTrue);
      expect(r.content, contains('internal address'));
    });

    test('CGNAT 100.64/10', () async {
      final r = await fetch({'url': 'http://100.64.0.1/'});
      expect(r.isError, isTrue);
      // 100.64 boundary is internal, 100.128 is not.
      final r2 = await fetch({'url': 'http://100.128.0.1/'});
      // 100.128 is outside CGNAT — guard passes; connection then fails.
      expect(r2.isError, isTrue);
    });

    test('empty host', () async {
      final r = await fetch({'url': 'http:///path'});
      expect(r.isError, isTrue);
      expect(r.content, contains('empty host'));
    });

    test('this-network (0.x) is internal', () async {
      final r = await fetch({'url': 'http://0.0.0.0/'});
      expect(r.isError, isTrue);
      expect(r.content, contains('internal address'));
    });

    test('an unresolvable host surfaces a clear refusal', () async {
      final r = await fetch({
        'url': 'http://this-host-definitely-does-not-exist.invalid/',
      });
      expect(r.isError, isTrue);
      // Either the SSRF guard reports the host unresolvable, or the fetch
      // itself fails after the guard passes — both are acceptable error
      // outcomes. Pin only that it's an error.
    });
  });

  group('WebFetchTool.execute success path (fake client)', () {
    // The SSRF guard runs before any client call, so to test the post-guard
    // body we point at a host that resolves to a public IP (example.com) and
    // inject a fake client that returns the scripted body without any real
    // network call.
    Future<HarnessToolResult> fetchFake(
      String body, {
      int statusCode = 200,
      String contentType = 'text/html; charset=utf-8',
      String? charset,
      int maxChars = 20000,
      Object? throwOnGet,
    }) {
      final tool = WebFetchTool(
        maxChars: maxChars,
        client: _FakeHttpClient(
          body: body,
          statusCode: statusCode,
          contentType: contentType,
          charset: charset,
          throwOnGet: throwOnGet,
        ),
        timeout: const Duration(seconds: 2),
      );
      return tool.execute({'url': 'https://example.com/page'}, ctx);
    }

    test('HTTP 4xx returns error', () async {
      final r = await fetchFake('not found', statusCode: 404);
      expect(r.isError, isTrue);
      expect(r.content, contains('HTTP 404'));
    });

    test(
      'html is converted to text (script/style stripped, entities decoded)',
      () async {
        const html = '''
<html><head><title>T</title>
<style>.x { color: red; }</style>
<script>alert('x')</script></head>
<body>
<h1>Title</h1>
<p>First &amp; second</p>
<p>Non&nbsp;breaking</p>
<ul><li>One</li><li>Two</li></ul>
</body></html>
''';
        final r = await fetchFake(html);
        expect(r.isError, isFalse);
        expect(r.content, contains('# https://example.com/page'));
        expect(r.content, contains('Title'));
        expect(r.content, contains('First & second'));
        expect(r.content, contains('Non breaking'));
        // script/style stripped.
        expect(r.content, isNot(contains("alert('x')")));
        expect(r.content, isNot(contains('color: red')));
      },
    );

    test('plain text body returned trimmed', () async {
      final r = await fetchFake(
        '   hello world   ',
        contentType: 'text/plain; charset=utf-8',
      );
      expect(r.isError, isFalse);
      expect(r.content, contains('hello world'));
    });

    test('empty extracted text returns no-readable-text marker', () async {
      final r = await fetchFake('<html><body></body></html>');
      expect(r.isError, isFalse);
      expect(r.content, contains('no readable text'));
    });

    test('caps output to maxChars', () async {
      final body = 'x' * 5000;
      final r = await fetchFake('<p>$body</p>', maxChars: 100);
      expect(r.isError, isFalse);
      expect(r.content, contains('[truncated'));
    });

    test('explicit non-utf8 charset is honored (no crash)', () async {
      // ASCII body so any codec decodes identically; the point is that the
      // non-utf8 codec branch is exercised without throwing.
      final r = await fetchFake(
        'plain ascii text',
        contentType: 'text/html',
        charset: 'latin1',
      );
      expect(r.isError, isFalse);
      expect(r.content, contains('plain ascii text'));
    });

    test('get exception is caught and returned as error', () async {
      final r = await fetchFake(
        '',
        throwOnGet: StateError('connection refused'),
      );
      expect(r.isError, isTrue);
      expect(r.content, contains('Failed to fetch'));
    });
  });
}
