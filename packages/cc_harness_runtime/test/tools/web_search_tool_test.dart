import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/web_search_tool.dart';
import 'package:test/test.dart';

/// A minimal HttpClient fake that returns a canned HTML body for any GET.
class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({this.body = '', this.statusCode = 200, this.throwOnGet});

  final String body;
  final int statusCode;
  final Object? throwOnGet;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (throwOnGet != null) {
      throw throwOnGet!;
    }
    return _FakeRequest(body, statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this.body, this.statusCode);
  final String body;
  final int statusCode;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(body, statusCode);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Implements [HttpClientResponse] by wrapping a real [Stream<List<int>>] and
/// forwarding the Stream methods the tool uses (`transform`, `join`, `listen`)
/// to it. HttpClientResponse itself extends Stream, so we implement its
/// non-stream members via noSuchMethod.
class _FakeResponse implements HttpClientResponse {
  _FakeResponse(this.body, this.statusCode);

  final String body;
  @override
  final int statusCode;

  Stream<List<int>> get _stream => Stream<List<int>>.value(utf8.encode(body));

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> transformer) =>
      _stream.transform(transformer);

  @override
  Future<String> join([String separator = '']) => _stream.join(separator);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HarnessToolContext _ctx() => const HarnessToolContext(workingDirectory: '/tmp');

/// Builds a DuckDuckGo-style HTML body with N results.
String _ddgHtml(
  int count, {
  bool withSnippets = true,
  bool asProtocolRelative = false,
}) {
  final anchors = <String>[];
  for (var i = 0; i < count; i++) {
    final href = asProtocolRelative
        ? '//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2F$i'
        : 'https://example.com/$i';
    anchors.add('<a class="result__a" href="$href">Result $i &amp; co</a>');
    if (withSnippets) {
      anchors.add('<a class="result__snippet" >Snippet $i &#x27;s text</a>');
    }
  }
  return '<html><body>${anchors.join('\n')}</body></html>';
}

void main() {
  group('WebSearchTool metadata', () {
    test('exposes name, tier, schema', () {
      final tool = WebSearchTool();
      expect(tool.name, 'web_search');
      expect(tool.approvalTier, ToolApprovalTier.exec);
      expect(tool.description, contains('Search the web'));
      expect(tool.inputSchema['required'], ['query']);
      expect(tool.maxResults, 8);
    });
  });

  group('WebSearchTool.execute', () {
    test('refuses when network disabled', () async {
      final tool = WebSearchTool(allowNetwork: false);
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('Network access is disabled'));
    });

    test('missing query returns error', () async {
      final tool = WebSearchTool(client: _FakeHttpClient());
      final res = await tool.execute({}, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('query'));
    });

    test('non-string query returns error', () async {
      final tool = WebSearchTool(client: _FakeHttpClient());
      final res = await tool.execute({'query': 42}, _ctx());
      expect(res.isError, isTrue);
    });

    test('empty query returns error', () async {
      final tool = WebSearchTool(client: _FakeHttpClient());
      final res = await tool.execute({'query': '   '}, _ctx());
      expect(res.isError, isTrue);
    });

    test('HTTP 4xx returns error', () async {
      final tool = WebSearchTool(
        client: _FakeHttpClient(statusCode: 429, body: 'blocked'),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('HTTP 429'));
    });

    test('successful parse renders ranked results', () async {
      final tool = WebSearchTool(
        maxResults: 3,
        client: _FakeHttpClient(body: _ddgHtml(5)),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isFalse);
      // Only the first 3 of 5.
      expect(res.content, contains('Search results for "cats"'));
      expect(res.content, contains('1. Result 0 & co'));
      expect(res.content, contains('https://example.com/0'));
      expect(res.content, contains("Snippet 0 's text"));
      expect(res.content, contains('3. Result 2'));
      expect(res.content, isNot(contains('Result 3')));
    });

    test('protocol-relative duck-redirect URLs are unwrapped', () async {
      final tool = WebSearchTool(
        client: _FakeHttpClient(body: _ddgHtml(1, asProtocolRelative: true)),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isFalse);
      // The /l/?uddg= wrapper decodes to the inner example.com URL.
      expect(res.content, contains('https://example.com/0'));
    });

    test('results without snippets render without snippet line', () async {
      final tool = WebSearchTool(
        client: _FakeHttpClient(body: _ddgHtml(2, withSnippets: false)),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isFalse);
      expect(res.content, contains('Result 0'));
      expect(res.content, contains('Result 1'));
    });

    test('empty results with large body returns no-results message', () async {
      // Large enough body (>= 512 chars) without result anchors and without
      // any blocked-markers → "No results" path.
      final padding = 'x' * 600;
      final tool = WebSearchTool(
        client: _FakeHttpClient(body: '<html>$padding</html>'),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isFalse);
      expect(res.content, 'No results for "cats".');
    });

    test('empty short body is treated as blocked', () async {
      final tool = WebSearchTool(client: _FakeHttpClient(body: 'short'));
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('blocked the request'));
    });

    test('empty body containing "captcha" is treated as blocked', () async {
      final padding = 'x' * 600;
      final tool = WebSearchTool(
        client: _FakeHttpClient(body: 'captcha $padding'),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('blocked the request'));
    });

    test('empty body containing "anomaly" is treated as blocked', () async {
      final padding = 'x' * 600;
      final tool = WebSearchTool(
        client: _FakeHttpClient(body: 'anomaly detected $padding'),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isTrue);
    });

    test('empty body containing "challenge" is treated as blocked', () async {
      final padding = 'x' * 600;
      final tool = WebSearchTool(
        client: _FakeHttpClient(body: 'challenge $padding'),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isTrue);
    });

    test('get exception is caught and returned as error', () async {
      final tool = WebSearchTool(
        client: _FakeHttpClient(throwOnGet: StateError('network down')),
      );
      final res = await tool.execute({'query': 'cats'}, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('Search failed'));
    });
  });
}
