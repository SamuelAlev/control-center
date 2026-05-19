import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Read-only view of every tool definition the registry knows, regardless of
/// discovery gating. The BM25 tool-discovery search tool indexes this so it can
/// surface tools that are hidden from `tools/list`.
abstract interface class ToolCatalog {
  /// Every tool definition (native + bridged + extras), ungated.
  List<ToolDef> allToolDefinitions();
}

/// The live set of MCP tools served to agents.
///
/// Holds three layers:
/// * **base** tools — CC's native tool classes, fixed at construction.
/// * **dynamic** tools — tools bridged from external MCP servers, swapped in via
///   [setDynamicTools] as servers connect / hot-reload.
/// * **extra** tools — host-registered singletons such as the BM25 search tool,
///   added via [register].
///
/// When [discoveryThreshold] is positive and the total tool count exceeds it,
/// [listDefinitions] returns only the [essentialToolNames] (the search tool +
/// a curated core) — the rest are discoverable by BM25 search and remain
/// callable by name through [lookup]. This is the context-savings lever from
/// PRD 01 phase 1.4: a stable, small `tools/list` keeps the prompt-cache prefix
/// intact while the long tail stays reachable.
class McpToolRegistry implements ToolCatalog {
  /// Creates a registry over the [tools] base set.
  ///
  /// [discoveryThreshold] of 0 (the default) disables gating — every tool is
  /// listed. [essentialToolNames] are always listed even when gating is active.
  McpToolRegistry(
    List<McpTool> tools, {
    this.discoveryThreshold = 0,
    Set<String> essentialToolNames = const {},
  }) : _base = {for (final t in tools) t.name: t},
       _essential = {...essentialToolNames};

  /// Tool-count threshold above which discovery gating activates (0 = off).
  final int discoveryThreshold;

  final Map<String, McpTool> _base;
  final Map<String, McpTool> _dynamic = {};
  final Map<String, McpTool> _extra = {};
  final Set<String> _essential;

  /// Names always listed even under discovery gating.
  Set<String> get essentialToolNames => Set.unmodifiable(_essential);

  /// Replaces the dynamic (bridged) tool set. Called by the MCP connection
  /// manager whenever external servers connect, disconnect, or hot-reload.
  void setDynamicTools(List<McpTool> tools) {
    _dynamic
      ..clear()
      ..addEntries(tools.map((t) => MapEntry(t.name, t)));
  }

  /// Registers a host singleton tool (e.g. the BM25 search tool). When
  /// [essential] it is always listed even under discovery gating.
  void register(McpTool tool, {bool essential = false}) {
    _extra[tool.name] = tool;
    if (essential) {
      _essential.add(tool.name);
    }
  }

  /// Looks up a tool by name across all three layers. A tool hidden from
  /// `tools/list` by discovery gating is still resolved here — that is how an
  /// agent calls a tool it found via BM25 search.
  McpTool? lookup(String name) =>
      _extra[name] ?? _dynamic[name] ?? _base[name];

  /// The total number of known tools.
  int get totalToolCount => _allTools().length;

  /// Whether discovery gating is currently active.
  bool get isDiscoveryActive =>
      discoveryThreshold > 0 && totalToolCount > discoveryThreshold;

  /// The tool definitions to advertise in `tools/list`. Gated to the essential
  /// set when [isDiscoveryActive]; otherwise everything.
  List<ToolDef> listDefinitions() {
    final all = _allTools();
    if (!isDiscoveryActive) {
      return all.values.map((t) => t.definition).toList();
    }
    return [
      for (final entry in all.entries)
        if (_essential.contains(entry.key)) entry.value.definition,
    ];
  }

  @override
  List<ToolDef> allToolDefinitions() =>
      _allTools().values.map((t) => t.definition).toList();

  /// All tool names (ungated).
  Iterable<String> get toolNames => _allTools().keys;

  /// base ∪ dynamic ∪ extra, with extras/dynamic taking precedence on a clash.
  Map<String, McpTool> _allTools() => {..._base, ..._dynamic, ..._extra};
}
