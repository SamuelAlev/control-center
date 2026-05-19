import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp_client/src/tool_index.dart';

/// CC's curated "essential" tools — the core that stays visible in
/// `tools/list` even when BM25 discovery gating is active, so an agent can act
/// immediately without searching first. Everything else is found by query and
/// remains callable by name. `search_tool_bm25` is always essential.
const Set<String> defaultEssentialToolNames = {
  SearchToolBm25.toolName,
  'list_workspaces',
  'list_agents',
  'list_channels',
  'get_channel_messages',
  'send_channel_message',
  'list_tickets',
  'get_ticket',
  'search_memory',
  'search_code',
  'read',
  'submit_output',
};

/// The agent-facing tool-discovery search tool (PRD 01 phase 1.4).
///
/// When CC exposes more tools than the discovery threshold, `tools/list` ships
/// only this tool plus a curated essential set; the rest are found by calling
/// `search_tool_bm25("…")`, which BM25-ranks the full catalogue and returns the
/// matching tools' names + schemas. The agent then calls a matched tool by name
/// directly — the registry resolves it even though it was hidden from the list.
///
/// This is `read`-tier (it only inspects the catalogue) and never prompts.
class SearchToolBm25 extends McpTool {
  /// Creates a [SearchToolBm25] over [catalog].
  SearchToolBm25({required ToolCatalog catalog}) : _catalog = catalog;

  final ToolCatalog _catalog;

  /// The canonical name agents call.
  static const String toolName = 'search_tool_bm25';

  @override
  String get name => toolName;

  @override
  String get description =>
      'Search the full tool catalogue by keyword to discover tools that are '
      'not listed by default. Returns the best-matching tools with their '
      'names and argument schemas; call a returned tool by its name directly.';

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
    },
    'required': ['query'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final query = arguments['query'];
    if (query is! String || query.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: query');
    }
    final limit = (arguments['limit'] as num?)?.toInt() ?? 8;
    final definitions = _catalog.allToolDefinitions();
    final index = ToolIndex.build(definitions);
    final hits = index.search(query, limit: limit <= 0 ? 8 : limit);
    return CallResult.success(
      jsonEncode({
        'query': query,
        'limit': limit,
        'total_tools': definitions.length,
        'activated_tools': hits.map((h) => h.name).toList(),
        'tools': hits.map((h) => h.toJson()).toList(),
      }),
    );
  }
}
