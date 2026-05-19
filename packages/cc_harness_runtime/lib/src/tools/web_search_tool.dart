import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/search_backends.dart';

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
    // Walk the chain until one backend answers. A single backend fails in the
    // least useful way: a bot challenge returns HTTP 200 with no results,
    // which reads to the model as "there is nothing about this on the
    // internet" — a wrong answer rather than a missing one, and the agent
    // proceeds on it.
    final attempted = <String>[];
    var sawBlock = false;
    for (final backend in searchBackends) {
      attempted.add(backend.name);
      final String body;
      try {
        final request = await _client
            .getUrl(backend.queryUrl(query))
            .timeout(_timeout);
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'ControlCenter-Agent/1.0',
        );
        final response = await request.close().timeout(_timeout);
        if (response.statusCode >= 400) {
          sawBlock = true;
          continue;
        }
        body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(_timeout);
      } on Object {
        // A dead or unreachable backend is the next backend's problem.
        continue;
      }

      final hits = backend.parse(body).take(maxResults).toList();
      if (hits.isNotEmpty) {
        final buf = StringBuffer('Search results for "$query":\n');
        for (var i = 0; i < hits.length; i++) {
          final hit = hits[i];
          buf.writeln('\n${i + 1}. ${hit.title}\n   ${hit.url}');
          if (hit.snippet.isNotEmpty) {
            buf.writeln('   ${hit.snippet}');
          }
        }
        return HarnessToolResult.success(buf.toString().trimRight());
      }
      if (looksBlocked(body)) {
        sawBlock = true;
        continue;
      }
      // A clean, parseable page with genuinely nothing on it. Believe it —
      // and stop, because asking three engines the same question and getting
      // three empty answers costs three round-trips to learn one fact.
      return HarnessToolResult.success('No results for "$query".');
    }

    return HarnessToolResult.error(
      sawBlock
          ? 'Every search backend (${attempted.join(', ')}) blocked or failed '
                'the request. This is NOT evidence that nothing exists — try '
                'web_fetch on a known URL, or ask again later.'
          : 'No search backend could be reached (${attempted.join(', ')}).',
    );
  }
}
