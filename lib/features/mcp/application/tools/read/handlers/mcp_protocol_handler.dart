import 'dart:convert';

import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/mcp/domain/services/mcp_tool_registry.dart';

/// Handles `mcp://<uri>` URLs by introspecting the app's own MCP
/// server tool registry. Full external MCP client proxy is future work.
class McpProtocolHandler {
  /// Creates a [McpProtocolHandler].
  McpProtocolHandler({required McpToolRegistry registry})
    : _registry = registry;

  final McpToolRegistry _registry;

  /// Resolves [url] by listing matching tools/resources from the registry.
  Future<CallResult> handle(McpUrl url, ReadContext context) async {
    final uri = url.uri;

    // List all tool definitions — filter by URI prefix if provided.
    final allDefs = _registry.listDefinitions();
    final normalized = uri.toLowerCase();

    final matching = allDefs.where((def) {
      if (normalized.isEmpty || normalized == '*') return true;
      return def.name.toLowerCase().contains(normalized);
    }).toList();

    if (matching.isEmpty) {
      return CallResult.error(
        'No MCP tools match URI: $uri\n'
        'Available tools: ${allDefs.map((d) => d.name).join(", ")}',
      );
    }

    final result = matching.map((def) => def.toJson()).toList();

    return CallResult.success(
      jsonEncode({
        'uri': uri,
        'tools': result,
        'count': result.length,
      }),
    );
  }
}
