import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';

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
  /// Creates a [SearchToolBm25] over [catalog].
  ///
  /// [modeGuard] is optional: when supplied, hits are annotated with their
  /// callable/restricted status for the caller's conversation mode. Without it
  /// (e.g. the MCP Inspector, or a non-scoped transport), every hit is reported
  /// as callable.
  SearchToolBm25({required ToolCatalog catalog, ModeToolGuard? modeGuard})
    : _catalog = catalog,
      _modeGuard = modeGuard;

  final ToolCatalog _catalog;
  final ModeToolGuard? _modeGuard;

  /// The canonical name agents call.
  static const String toolName = 'search_tool_bm25';

  @override
  String get name => toolName;

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

  /// The BM25 index, rebuilt only when the tool catalog changes.
  ///
  /// `ToolIndex.build` re-tokenizes every tool's name, description and schema
  /// keys — ~80+ bridged tools — and it ran on EVERY `search_tools` call, for
  /// a catalog that changes when an MCP server connects or disconnects and at
  /// no other time.
  ///
  /// Keyed on the definition LIST's identity plus its length: the registry
  /// hands back the same list instance while the catalog is unchanged, and the
  /// length guards the case where a registry rebuilds the list in place.
  static ToolIndex? _cachedIndex;
  static Object? _cachedIndexSource;
  static int _cachedIndexLength = -1;

  static ToolIndex _indexFor(List<ToolDef> definitions) {
    final cached = _cachedIndex;
    if (cached != null &&
        identical(_cachedIndexSource, definitions) &&
        _cachedIndexLength == definitions.length) {
      return cached;
    }
    final index = ToolIndex.build(definitions);
    _cachedIndex = index;
    _cachedIndexSource = definitions;
    _cachedIndexLength = definitions.length;
    return index;
  }

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final query = arguments['query'];
    if (query is! String || query.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: query');
    }
    final limit = (arguments['limit'] as num?)?.toInt() ?? 8;
    final definitions = _catalog.allToolDefinitions();
    final index = _indexFor(definitions);
    final hits = index.search(query, limit: limit <= 0 ? 8 : limit);

    // Resolve the caller's conversation mode ONCE, then classify each hit
    // in-memory (avoids a DB round-trip per hit).
    final agentId = arguments['agent_id'];
    final spaceId = arguments['space_id'];
    final workspaceId = arguments['workspace_id'];
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
        'total_tools': definitions.length,
        if (mode != null) 'conversation_mode': mode.name,
        'matches': hits.map((h) => h.name).toList(),
        'tools': tools,
        'note': mode == null
            ? 'Every hit is directly callable by its `name`.'
            : 'This conversation is in ${mode.name} mode. Hits with '
                  '`"callable": false` are restricted here — see '
                  '`restricted_reason`. Call `list_my_tools` for the full set '
                  'you can use right now.',
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
