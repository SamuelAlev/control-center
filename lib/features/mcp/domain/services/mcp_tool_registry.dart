import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Mcp tool registry.
class McpToolRegistry {
  /// Creates a new [Mcp tool registry].
  McpToolRegistry(List<McpTool> tools)
    : _tools = {for (final t in tools) t.name: t};

  final Map<String, McpTool> _tools;

  /// Lookup.
  McpTool? lookup(String name) => _tools[name];

  /// List definitions.
  List<ToolDef> listDefinitions() =>
      _tools.values.map((t) => t.definition).toList();

  /// Tool names.
  Iterable<String> get toolNames => _tools.keys;
}

