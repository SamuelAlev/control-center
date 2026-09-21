import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Read-only view of every tool definition the registry knows. The BM25
/// tool-discovery search tool indexes this to help agents find the right tool
/// in a large catalogue.
abstract interface class ToolCatalog {
  /// Every tool definition (native + bridged + extras).
  List<ToolDef> allToolDefinitions();
}

/// The live set of MCP tools served to agents.
///
/// Layers: **base** (native, fixed at construction), **dynamic** (external MCP
/// via [setDynamicTools]), **extra** (host singletons via [register]).
/// Every registered tool is in `tools/list` — ungated. Gating was unenforceable:
/// Claude Code validates names against its cached list client-side and refuses
/// unlisted tools, so gated writes were unreachable. Harness deferral belongs
/// in the harness layer. [onToolsChanged] drives `tools/list_changed`;
/// [toolsetRevision] fingerprints the catalogue for dispatch config-hash busts.
class McpToolRegistry implements ToolCatalog {
  /// Creates a registry over the [tools] base set.
  McpToolRegistry(List<McpTool> tools)
    : _base = {for (final t in tools) t.name: t};

  final Map<String, McpTool> _base;
  final Map<String, McpTool> _dynamic = {};
  final Map<String, McpTool> _extra = {};

  /// Invoked after every mutation of the tool set ([setDynamicTools] /
  /// [register]). The host wires this to the MCP HTTP server so connected
  /// clients receive `notifications/tools/list_changed`.
  void Function()? onToolsChanged;

  /// Replaces the dynamic (bridged) tool set. Called by the MCP connection
  /// manager whenever external servers connect, disconnect, or hot-reload.
  void setDynamicTools(List<McpTool> tools) {
    _dynamic
      ..clear()
      ..addEntries(tools.map((t) => MapEntry(t.name, t)));
    onToolsChanged?.call();
  }

  /// Registers a host singleton tool (e.g. the BM25 search tool).
  void register(McpTool tool) {
    _extra[tool.name] = tool;
    onToolsChanged?.call();
  }

  /// Looks up a tool by name across all three layers.
  McpTool? lookup(String name) => _extra[name] ?? _dynamic[name] ?? _base[name];

  /// Resolves an incoming tool name tolerantly.
  ///
  /// An exact [lookup] wins first (so a legitimately bridged `mcp__server__tool`
  /// always resolves as itself). Only when the exact name is unknown does this
  /// strip the client-imposed server namespace prefix and retry — because a
  /// client surfaces CC's tools to the agent under the server's name (Claude
  /// Code: `mcp__control-center__<tool>`; other adapters sanitise the hyphen to
  /// `control_center_<tool>`) and an agent that types the prefixed name it was
  /// shown should not get "unknown tool" from the server. Returns null when no
  /// candidate resolves.
  McpTool? resolve(String name) {
    final exact = lookup(name);
    if (exact != null) {
      return exact;
    }
    for (final candidate in _dePrefixedCandidates(name)) {
      final tool = lookup(candidate);
      if (tool != null) {
        return tool;
      }
    }
    return null;
  }

  /// Candidate bare names for [name] after stripping a client namespace prefix.
  static Iterable<String> _dePrefixedCandidates(String name) sync* {
    // `mcp__<server>__<tool>` → `<tool>` (the segment after the last `__`).
    if (name.startsWith('mcp__')) {
      final idx = name.lastIndexOf('__');
      if (idx > 3 && idx + 2 < name.length) {
        yield name.substring(idx + 2);
      }
    }
    // `control-center` / `control_center` prefix + `_`/`-`/`__` separator.
    final m = RegExp(
      r'^control[-_]center[-_]+(.+)$',
    ).firstMatch(name.toLowerCase());
    if (m != null) {
      yield m.group(1)!;
    }
  }

  /// The total number of known tools.
  int get totalToolCount => _allTools().length;

  /// The tool definitions advertised in `tools/list` — the full catalogue.
  List<ToolDef> listDefinitions() =>
      _allTools().values.map((t) => t.definition).toList();

  @override
  List<ToolDef> allToolDefinitions() => listDefinitions();

  /// All tool names.
  Iterable<String> get toolNames => _allTools().keys;

  /// Stable fingerprint of the current catalogue (names + schema keys),
  /// as a hex string. Changes exactly when the advertised toolset changes, so
  /// embedding it in a client config invalidates config-hash-keyed tool-list
  /// caches on server upgrades.
  String get toolsetRevision {
    final entries = _allTools().values.map((t) {
      final props = t.inputSchema['properties'];
      final keys = props is Map
          ? (props.keys.map((k) => '$k').toList()..sort())
          : const <String>[];
      return '${t.name}(${keys.join(',')})';
    }).toList()..sort();
    // FNV-1a 64-bit over the joined entries — dependency-free and stable
    // across processes (Dart's String.hashCode is per-process-seeded).
    var hash = 0xcbf29ce484222325;
    for (final code in entries.join(';').codeUnits) {
      hash ^= code;
      hash *= 0x100000001b3; // wraps to 64 bits on the VM
    }
    final hi = (hash >>> 32).toRadixString(16).padLeft(8, '0');
    final lo = (hash & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return '$hi$lo';
  }

  /// base ∪ dynamic ∪ extra, with extras/dynamic taking precedence on a clash.
  Map<String, McpTool> _allTools() => {..._base, ..._dynamic, ..._extra};
}
