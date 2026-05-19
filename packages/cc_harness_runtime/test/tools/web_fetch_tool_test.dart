import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/web_fetch_tool.dart';
import 'package:test/test.dart';

/// Exercises [WebFetchTool]'s testable surface. The tool is hardened against
/// SSRF: it resolves the target host and refuses loopback / link-local /
/// private / CGNAT addresses before connecting. That guard is the correct
/// production behavior and it also means a local loopback test server
/// CANNOT be reached from these tests — so this file pins the metadata, the
/// argument-validation paths, the SSRF refusal matrix (loopback / private /
/// CGNAT / empty host / unresolvable host) and the HTML→text conversion
/// (via an injectable fake HttpClient so no real network call is made).

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({
    this.body = '',
    this.statusCode = 200,
    this.contentType = 'text/html; charset=utf-8',
    this.charset,
    this.throwOnGet,
    this.redirects = const {},
  });

  final String body;
  final int statusCode;
  final String contentType;
  final String? charset;
  final Object? throwOnGet;

  /// `requested url → Location header`, so a test can script a redirect chain
  /// (the tool follows hops itself, re-validating each against the SSRF
  /// guard).
  final Map<String, String> redirects;

  /// Every URL the tool actually dialled, in order.
  final List<Uri> requested = [];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    if (throwOnGet != null) {
      throw throwOnGet!;
    }
    return _FakeRequest(this, url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this.client, this.url);
  final _FakeHttpClient client;

  /// The URL this request was created for (the fake resolves redirects by it).
  final Uri url;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(client, url);

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
  _FakeResponse(this.client, this.url);
  final _FakeHttpClient client;
  final Uri url;

  String? get _location => client.redirects[url.toString()];

  @override
  int get statusCode => _location != null ? 302 : client.statusCode;

  @override
  bool get isRedirect => _location != null;

  @override
  HttpHeaders get headers {
    final h = _RespHeaders();
    final location = _location;
    if (location != null) {
      h.set(HttpHeaders.locationHeader, location);
      return h;
    }
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
  final Map<String, String> _values = {};

  @override
  ContentType? get contentType =>
      _contentType == null ? null : ContentType.parse(_contentType!);

  @override
  String? value(String name) => _values[name.toLowerCase()];

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = value.toString();
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
      expect((t.inputSchema['properties'] as Map)['url'], isA<Map>());
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

  group('SSRF guard — redirects', () {
    test('a redirect to an internal address is refused', () async {
      // The bypass: the pre-fetch check passed on the public host, then
      // `followRedirects: true` let dart:io chase a 302 to the cloud-metadata
      // endpoint with nothing looking again.
      final client = _FakeHttpClient(
        body: 'secret',
        contentType: 'text/plain',
        redirects: {
          'https://example.com/page': 'http://169.254.169.254/latest/meta-data',
        },
      );
      final tool = WebFetchTool(client: client);

      final result = await tool.execute(const {
        'url': 'https://example.com/page',
      }, const HarnessToolContext(workingDirectory: '/tmp'));

      expect(result.isError, isTrue);
      expect(result.content, contains('169.254.169.254'));
      expect(client.requested.map((u) => u.host), [
        'example.com',
      ], reason: 'the internal hop must never be dialled');
    });

    test('a redirect to another public host is followed', () async {
      final client = _FakeHttpClient(
        body: 'moved body',
        contentType: 'text/plain',
        redirects: {'https://example.com/page': 'https://example.org/final'},
      );
      final tool = WebFetchTool(client: client);

      final result = await tool.execute(const {
        'url': 'https://example.com/page',
      }, const HarnessToolContext(workingDirectory: '/tmp'));

      expect(result.isError, isFalse);
      expect(result.content, contains('moved body'));
      expect(client.requested.map((u) => u.host), [
        'example.com',
        'example.org',
      ]);
    });

    test('a non-http(s) redirect is refused', () async {
      final client = _FakeHttpClient(
        redirects: {'https://example.com/page': 'file:///etc/passwd'},
      );
      final tool = WebFetchTool(client: client);

      final result = await tool.execute(const {
        'url': 'https://example.com/page',
      }, const HarnessToolContext(workingDirectory: '/tmp'));

      expect(result.isError, isTrue);
      expect(result.content, contains('non-http'));
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

  // The HTML→text conversion is a single pass over the source rather than the
  // nine full-string `replaceAll`s it replaced (a 5 MB page churned ~50 MB of
  // transient strings per fetch). These pin the conversion's observable
  // contract so the optimization cannot silently change what an agent reads.
  group('WebFetchTool html→text', () {
    String convert(String html) => WebFetchTool.debugHtmlToText(html);

    test('drops script/style/head/noscript bodies entirely', () {
      expect(convert('<script>var x = 1;</script>after'), 'after');
      expect(convert('<style>.a{color:red}</style>after'), 'after');
      expect(convert('<head><title>t</title></head>after'), 'after');
      expect(convert('<noscript>ns</noscript>after'), 'after');
    });

    test('an UNCLOSED script does not swallow the rest of the page', () {
      // A body truncated at the size cap mid-script must not lose everything
      // after it — the opener degrades to an ordinary stripped tag.
      expect(convert('before<script>tail text'), 'before tail text');
    });

    test('block closers and <br> become newlines', () {
      expect(convert('<p>a</p><p>b</p>'), 'a\nb');
      expect(convert('<div>a<br>b<br/>c</div>'), 'a\nb\nc');
      expect(convert('<h2>h</h2>body'), 'h\nbody');
    });

    test('list items become bullets, including the first', () {
      expect(convert('<ul><li>one</li><li>two</li></ul>'), '- one\n- two');
      expect(convert('<li class="x">item</li>'), '- item');
    });

    test('entities decode and &nbsp; collapses like a literal space', () {
      expect(convert('a &amp; b'), 'a & b');
      expect(
        convert('&lt;x&gt; &quot;q&quot; &#39;s&#39; &apos;a&apos;'),
        '<x> "q" \'s\' \'a\'',
      );
      expect(convert('<p>a&nbsp;&nbsp;b</p>'), 'a b');
    });

    test('whitespace collapses and the result is trimmed', () {
      expect(
        convert('<p>  spaced   out  </p>\n\n\n<p>next</p>'),
        'spaced out\n\nnext',
      );
      expect(convert('   <p>x</p>   '), 'x');
    });

    test('blank-line runs squeeze to at most one blank line', () {
      expect(convert('a<br><br><br><br>b'), 'a\n\nb');
    });

    test('text with no markup passes through', () {
      expect(convert('plain text no tags'), 'plain text no tags');
    });

    test('an unterminated tag is treated as text, not dropped', () {
      expect(convert('visible <div'), 'visible <div');
    });

    test('tag names are matched case-insensitively', () {
      // `</P>` and `<BR>` each end a line, so two breaks — one blank line.
      expect(convert('<P>UPPER</P><BR>x'), 'UPPER\n\nx');
      expect(convert('<SCRIPT>s</SCRIPT>y'), 'y');
    });
  });
}
