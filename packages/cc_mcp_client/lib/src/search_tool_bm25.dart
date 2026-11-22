import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';
import 'package:cc_mcp_client/src/list_my_tools_tool.dart'
    show ReplAvailableFn, callerHasRepl;

/// The agent-facing tool-discovery search tool.
///
/// `tools/list` already advertises the full catalogue; this tool exists purely
/// as a navigation aid — BM25-ranking the catalogue so an agent facing 60+
/// tools can find the right one by intent instead of scanning the list.
///
/// When a [ModeToolGuard] is wired, each hit is annotated with
/// whether it is actually *callable right now* — some tools are restricted by
/// the conversation's mode (plan / review / orchestrate). This is the fix for
/// the old "the search says a tool exists, then the call fails" trap: the
/// answer to "can I call this?" is in the same response as the search hit.
///
/// This is `read`-tier (it only inspects the catalogue) and never prompts.
class SearchToolBm25 extends McpTool {
  /// Creates a [SearchToolBm25] over [_catalog].
  ///
  /// [_modeGuard] is optional: when supplied, hits are annotated with their
  /// callable/restricted status for the caller's conversation mode. Without it
  /// (e.g. the MCP Inspector, or a non-scoped transport), every hit is reported
  /// as callable.
  ///
  /// [_replAvailable] answers whether this server runs scripts; `repl`
  /// (code mode's script tool) is a hit only then, and only for a caller
  /// that names its workspace. Without it, `repl` is never one.
  SearchToolBm25({
    required this._catalog,
    this._modeGuard,
    this._replAvailable,
  });

  final ToolCatalog _catalog;
  final ModeToolGuard? _modeGuard;
  final ReplAvailableFn? _replAvailable;

  /// The canonical name agents call.
  static const String toolName = 'search_tool_bm25';

  @override
  String get name => toolName;

  /// A script has `searchTools()` and `ALL_TOOLS` of its own.
  @override
  bool get scriptCallable => false;

  @override
  String get description =>
      'Search the tool catalogue by keyword to find the right tool for a '
      'task. Returns the best-matching tools with their names and argument '
      'schemas and — for each hit — whether it is callable right now in this '
      'conversation (some tools are restricted in plan/review/orchestrate '
      'mode). Call a tool by the `name` returned here. Note: your MCP client '
      'may surface these under a server prefix (e.g. '
      '`mcp__control-center__<name>`); the server also resolves the bare name.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'What you want to do, in natural language or keywords.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of tools to return (default 8).',
      },
      // Injected automatically from the session scope for dispatched agents;
      // used only to report per-mode callability. Safe to omit.
      'workspace_id': {
        'type': 'string',
        'description':
            'Your workspace id (auto-injected). Determines which '
            "conversation's mode classifies each hit.",
      },
      'agent_id': {
        'type': 'string',
        'description': 'Your agent id (auto-injected; used for callability).',
      },
      'space_id': {
        'type': 'string',
        'description':
            'The conversation id (auto-injected; used for callability).',
      },
    },
    'required': ['query'],
  };

  /// The BM25 index of [definitions]: the shared one
  /// ([ToolIndex.shared]), built once per distinct tool set as indexed and
  /// handed to every caller with the same set, so a call pays only for
  /// comparing the set, not for indexing it again.
  static ToolIndex _indexFor(List<ToolDef> definitions) =>
      ToolIndex.shared(definitions);

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final query = arguments['query'];
    if (query is! String || query.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: query');
    }
    final limit = (arguments['limit'] as num?)?.toInt() ?? 8;
    final wanted = limit <= 0 ? 8 : limit;
    final definitions = _catalog.allToolDefinitions();
    final index = _indexFor(definitions);
    final agentId = arguments['agent_id'];
    final spaceId = arguments['space_id'];
    final workspaceId = arguments['workspace_id'];
    // The index covers the shared catalogue; `repl` is dropped from the hits
    // for a caller that cannot run scripts (one extra hit asked for keeps
    // the count).
    final withRepl = callerHasRepl(_replAvailable, workspaceId: workspaceId);
    final hits = [
      for (final hit in index.search(query, limit: wanted + 1))
        if (withRepl || hit.name != ReplToolDescription.toolName) hit,
    ].take(wanted).toList();
    final totalTools = withRepl
        ? definitions.length
        : definitions
              .where((d) => d.name != ReplToolDescription.toolName)
              .length;

    // Resolve the caller's conversation mode ONCE, then classify each hit
    // in-memory (avoids a DB round-trip per hit).
    // The space whose mode classifies each hit lives in one workspace's
    // database, so without a workspace there is no mode and every hit reports as
    // callable. Honest for a search aid: each tool enforces its own workspace and
    // gate when invoked.
    final mode = (workspaceId is String && workspaceId.isNotEmpty)
        ? await _modeGuard?.resolveMode(
            workspaceId: workspaceId,
            agentId: agentId is String ? agentId : null,
            spaceId: spaceId is String ? spaceId : null,
          )
        : null;

    final tools = hits.map((h) {
      final json = h.toJson();
      final callable = _isCallable(h.name, mode);
      json['callable'] = callable;
      if (!callable && mode != null) {
        json['restricted_reason'] = _modeGuard!.refusalMessage(h.name, mode);
      }
      return json;
    }).toList();

    return CallResult.success(
      jsonEncode({
        'query': query,
        'limit': limit,
        'total_tools': totalTools,
        if (mode != null) 'conversation_mode': mode.name,
        'matches': hits.map((h) => h.name).toList(),
        'tools': tools,
        'note': mode == null
            ? 'Every hit is directly callable by its `name`.'
            // Names no other tool: the caller may not have one (a run with
            // `repl` has no `list_my_tools`).
            : 'This conversation is in ${mode.name} mode. Hits with '
                  '`"callable": false` are restricted here; see '
                  '`restricted_reason`.',
      }),
    );
  }

  bool _isCallable(String toolName, Mode? mode) {
    final guard = _modeGuard;
    if (guard == null || mode == null) {
      return true;
    }
    return guard.isAllowed(toolName, mode);
  }
}
