import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/tools.dart';

/// Searches the web and returns ranked result titles, URLs and snippets.
///
/// Uses a keyless best-effort backend (DuckDuckGo's HTML endpoint). It degrades
/// gracefully to a clear message if the endpoint changes or is unreachable —
/// pair with `web_fetch` to read a result. Network-tier via the exec gate.
class WebSearchTool extends HarnessTool {
  /// Creates a [WebSearchTool].
  WebSearchTool({
    this.maxResults = 8,
    this.allowNetwork = true,
    Duration? timeout,
    HttpClient? client,
  }) : _timeout = timeout ?? const Duration(seconds: 20),
       _client =
           client ??
           (HttpClient()..connectionTimeout = const Duration(seconds: 15));

  /// Maximum results returned.
  final int maxResults;

  /// When false the tool refuses (agent has no network capability).
  final bool allowNetwork;

  final Duration _timeout;
  final HttpClient _client;

  @override
  String get name => 'web_search';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.networkEgress};

  @override
  String get description =>
      'Search the web and return ranked results (title, url, snippet). Use '
      'web_fetch to read a result in full.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {'type': 'string'},
    },
    'required': ['query'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    if (!allowNetwork) {
      return HarnessToolResult.error(
        'Network access is disabled for this agent; web_search is unavailable.',
      );
    }
    final query = args['query'];
    if (query is! String || query.trim().isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: query');
    }
    final uri = Uri.parse(
      'https://html.duckduckgo.com/html/',
    ).replace(queryParameters: {'q': query});
    try {
      final request = await _client.getUrl(uri).timeout(_timeout);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'ControlCenter-Agent/1.0',
      );
      final response = await request.close().timeout(_timeout);
      if (response.statusCode >= 400) {
        return HarnessToolResult.error(
          'Search failed: HTTP ${response.statusCode}',
        );
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);
      final results = _parse(body).take(maxResults).toList();
      if (results.isEmpty) {
        // Distinguish a genuine empty result set from a bot-challenge / markup
        // change so the model does not treat a blocked search as "nothing found".
        final looksBlocked =
            body.contains('anomaly') ||
            body.contains('challenge') ||
            body.toLowerCase().contains('captcha') ||
            body.length < 512;
        if (looksBlocked) {
          return HarnessToolResult.error(
            'Search returned no parseable results (the endpoint may have '
            'blocked the request or changed its markup). Try web_fetch on a '
            'known URL instead.',
          );
        }
        return HarnessToolResult.success('No results for "$query".');
      }
      final buf = StringBuffer('Search results for "$query":\n');
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        buf.writeln('\n${i + 1}. ${r.title}\n   ${r.url}');
        if (r.snippet.isNotEmpty) {
          buf.writeln('   ${r.snippet}');
        }
      }
      return HarnessToolResult.success(buf.toString().trimRight());
    } on Object catch (e) {
      return HarnessToolResult.error('Search failed: $e');
    }
  }

  List<_Result> _parse(String html) {
    final out = <_Result>[];
    final anchorRe = RegExp(
      r'<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );
    final snippetRe = RegExp(
      r'<a[^>]*class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );
    final snippets = snippetRe
        .allMatches(html)
        .map((m) => _clean(m.group(1) ?? ''))
        .toList();
    var i = 0;
    for (final m in anchorRe.allMatches(html)) {
      final url = _resolveDuck(m.group(1) ?? '');
      final title = _clean(m.group(2) ?? '');
      if (url.isEmpty || title.isEmpty) {
        continue;
      }
      out.add(
        _Result(
          title: title,
          url: url,
          snippet: i < snippets.length ? snippets[i] : '',
        ),
      );
      i++;
    }
    return out;
  }

  /// DuckDuckGo wraps result URLs as `/l/?uddg=<encoded>`; unwrap when present.
  String _resolveDuck(String href) {
    final normalized = href.startsWith('//') ? 'https:$href' : href;
    final uri = Uri.tryParse(normalized);
    final uddg = uri?.queryParameters['uddg'];
    if (uddg != null && uddg.isNotEmpty) {
      return uddg;
    }
    return normalized;
  }

  static String _clean(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&#x27;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _Result {
  const _Result({
    required this.title,
    required this.url,
    required this.snippet,
  });
  final String title;
  final String url;
  final String snippet;
}
