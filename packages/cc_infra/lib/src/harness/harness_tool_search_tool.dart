import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';
import 'package:cc_harness/tools.dart';

/// The largest number of matches one search may return.
///
/// Retrieval depth has to be the MODEL's choice, not a constant: evaluations of
/// fixed top-5 retrieval score zero on the queries where the right tool ranks
/// sixth or lower, and recover most of that when the agent can widen the net.
/// So the default is small and the ceiling is generous.
const int kMaxToolSearchLimit = 25;

/// Default number of matches returned when the model names no limit.
const int kDefaultToolSearchLimit = 5;

/// Words carrying no signal about which tool is wanted.
///
/// The shared BM25 index does no stopword removal by design — it also serves
/// `search_tool_bm25`, where a spurious hit only costs a line of output. Here a
/// hit LOADS a schema, so "launch a rocket" matching "reads a file" on the word
/// "a" would spend real context on an unrelated tool and put it in front of the
/// model as a plausible answer. Filtered here rather than in the index so the
/// two callers keep ranking identically on the terms that matter.
const Set<String> _toolQueryStopwords = {
  'a', 'an', 'and', 'are', 'as', 'at', 'be', 'but', 'by', 'can', 'do', 'does',
  'for', 'from', 'have', 'how', 'i', 'in', 'into', 'is', 'it', 'its', 'me',
  'my', 'need', 'of', 'on', 'or', 'so', 'some', 'that', 'the', 'their', 'them',
  'then', 'there', 'these', 'this', 'to', 'up', 'want', 'was', 'we', 'what',
  'when', 'which', 'will', 'with', 'would', 'you', 'your',
};

/// Fraction of the best score a hit must reach to be returned.
///
/// A long query almost always scrapes a nonzero score off something. Ranking
/// alone would still put the right tool first, but everything under it gets
/// LOADED, so the tail has to be cut rather than merely ordered.
const double _minRelativeScore = 0.25;

/// Finds tools by intent and LOADS the ones it finds.
///
/// The run advertises a small resident set plus a name index of everything
/// else; this is the other half of that bargain. It ranks the whole surface
/// (BM25 over names, descriptions and argument names — the same index the
/// MCP-facing `search_tool_bm25` uses, so the two never disagree) and returns
/// the matches WITH their schemas attached to the run, so the model can call one
/// on its very next turn.
///
/// It cannot widen a surface: the catalogue it indexes is what the mode already
/// admitted, and activation only ever reveals a schema the run was always
/// allowed to call. Approval and the action guard are untouched.
class HarnessToolSearchTool extends HarnessTool {
  /// Creates a search tool over [catalog], reporting residency per [residency].
  HarnessToolSearchTool({
    required List<HarnessTool> catalog,
    required ToolResidencySpec residency,
  }) : _catalog = catalog,
       _residency = residency,
       _index = ToolIndex.build([
         for (final t in catalog)
           ToolDef(
             name: t.name,
             description: t.description,
             inputSchema: t.inputSchema,
           ),
       ]);

  final List<HarnessTool> _catalog;
  final ToolResidencySpec _residency;
  final ToolIndex _index;

  @override
  String get name => 'search_tools';

  @override
  String get description =>
      'Find a tool by what you want to DO and load it for the rest of this '
      'run. Search in plain language ("assign a ticket", "read a PR '
      'comment"), not by guessing a tool name. Matches are returned with '
      'their arguments and become directly callable immediately — you do not '
      'need to call this again before using one.\n'
      'Most tools in this run are listed by name in your system prompt but '
      'carry no schema until they are used. You can always call one of those '
      'names directly; use this when you know the task but not the name.\n'
      'If nothing matches, search again with different words or a bigger '
      '`limit` (the best tool is often not in the first few results) before '
      'concluding the capability does not exist.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description':
            'What you are trying to do, in plain language. Include the object '
            'you are acting on ("ticket", "memory fact", "pull request").',
      },
      'limit': {
        'type': 'integer',
        'description':
            'How many matches to return. Default $kDefaultToolSearchLimit, '
            'max $kMaxToolSearchLimit. Raise it when a first search looks '
            'close but misses.',
      },
    },
    'required': ['query'],
  };

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final query = (args['query'] as String?)?.trim() ?? '';
    if (query.isEmpty) {
      return HarnessToolResult.error(
        'search_tools needs a `query` describing what you want to do.',
      );
    }
    final requested = switch (args['limit']) {
      final int n => n,
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? kDefaultToolSearchLimit,
      _ => kDefaultToolSearchLimit,
    };
    final limit = requested.clamp(1, kMaxToolSearchLimit);
    // Strip the words every query shares before ranking; if that leaves
    // nothing, fall back to the raw query rather than searching for "".
    final meaningful = [
      for (final t in tokenizeToolText(query))
        if (!_toolQueryStopwords.contains(t)) t,
    ].join(' ');
    final ranked = _index.search(
      meaningful.isEmpty ? query : meaningful,
      limit: limit,
    );
    final best = ranked.isEmpty ? 0.0 : ranked.first.score;
    final hits = [
      for (final h in ranked)
        if (h.score >= best * _minRelativeScore) h,
    ];
    if (hits.isEmpty) {
      // A miss must read as a miss. Reporting "no such capability" here would
      // be the model's cue to confabulate one, so say plainly that the search
      // came up empty and name the two things that fix it.
      return HarnessToolResult.success(
        jsonEncode({
          'query': query,
          'matches': <Object>[],
          'tools_searched': _catalog.length,
          'hint':
              'No tool matched those words. Try different vocabulary (the '
              'tool may name the same thing differently), or raise `limit`. '
              'If a second search also finds nothing, this run genuinely has '
              'no tool for that — say so rather than substituting a '
              'different one.',
        }),
      );
    }
    final byName = {for (final t in _catalog) t.name: t};
    final matches = <Map<String, dynamic>>[];
    final activate = <String>{};
    for (final hit in hits) {
      final tool = byName[hit.name];
      if (tool == null) {
        continue;
      }
      final loaded = _residency.isResident(tool);
      if (!loaded) {
        activate.add(tool.name);
      }
      matches.add({
        'name': tool.name,
        'description': tool.description,
        'arguments': hit.schemaKeys,
        // Distinguishes "was already available" from "just loaded for you" so
        // the model does not read a resident tool as a new discovery.
        'already_loaded': loaded,
      });
    }
    return HarnessToolResult.success(
      jsonEncode({
        'query': query,
        'matches': matches,
        'tools_searched': _catalog.length,
        'hint':
            'These tools are now callable by name with their full schemas. '
            'If none of them fits, search again with different words or a '
            'larger `limit`.',
      }),
      activateTools: activate,
    );
  }
}
