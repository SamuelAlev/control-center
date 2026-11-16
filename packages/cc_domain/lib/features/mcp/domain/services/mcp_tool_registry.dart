import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Read-only view of the tool definitions any caller may see. The BM25
/// tool-discovery search tool indexes this to help agents find the right tool
/// in a large catalogue.
abstract interface class ToolCatalog {
  /// Every shared tool definition (native + extras). External servers' tools
  /// (see [McpToolRegistry]) are left out: a catalogue tool serves every run.
  List<ToolDef> allToolDefinitions();
}

/// Which bridged MCP layers one caller may see, beyond the shared tools.
///
/// External servers are not everyone's: a workspace's servers belong to that
/// workspace's runs, and the server owner's personal servers act with their
/// own identity. A view is decided by whoever knows the caller (the run's
/// grant, the harness's own context), never by a request argument.
final class McpToolView {
  /// Creates a view. [workspaceId] adds that workspace's servers;
  /// [includePersonal] adds the server owner's own.
  const McpToolView({this.workspaceId, this.includePersonal = false});

  /// The shared tools only: no external server at all.
  static const McpToolView shared = McpToolView();

  /// The workspace whose configured servers this caller may use, or null.
  final String? workspaceId;

  /// Whether this caller may use the server owner's personal servers.
  final bool includePersonal;

  @override
  bool operator ==(Object other) =>
      other is McpToolView &&
      other.workspaceId == workspaceId &&
      other.includePersonal == includePersonal;

  @override
  int get hashCode => Object.hash(workspaceId, includePersonal);

  @override
  String toString() =>
      'McpToolView(workspace: $workspaceId, personal: $includePersonal)';
}

/// The live set of MCP tools served to agents.
///
/// Layers, in the order a name resolves: **extra** (host singletons via
/// [register]), **personal** (the server owner's own servers via
/// [setPersonalTools]), **workspace** (each workspace's configured servers via
/// [setWorkspaceTools]) and **base** (native, fixed at construction).
///
/// The personal layer holds the servers discovered in, or added to, the server
/// OS user's own configuration, which act with that user's identity and
/// credentials. Only a run the server owner is accountable for may be handed
/// them. A workspace layer belongs to that workspace's runs alone. Every
/// run-facing read therefore takes an [McpToolView], and a tool outside it is
/// absent: not listed, not callable, and never standing in for another tool of
/// the same name. Personal resolves before workspace, so a workspace server
/// can never shadow one of the owner's in the owner's own run.
///
/// Every tool a view admits is in `tools/list`, ungated. Gating was
/// unenforceable: Claude Code validates names against its cached list
/// client-side and refuses unlisted tools, so gated writes were unreachable.
/// Harness deferral belongs in the harness layer. [onToolsChanged] drives
/// `tools/list_changed`; [toolsetRevision] fingerprints the shared catalogue
/// for dispatch config-hash busts.
class McpToolRegistry implements ToolCatalog {
  /// Creates a registry over the [tools] base set.
  McpToolRegistry(List<McpTool> tools)
    : _base = {for (final t in tools) t.name: t};

  final Map<String, McpTool> _base;
  final Map<String, McpTool> _personal = {};
  final Map<String, Map<String, McpTool>> _workspace = {};
  final Map<String, McpTool> _extra = {};

  /// Invoked after every mutation of the tool set ([setPersonalTools],
  /// [setWorkspaceTools], [register]). The host wires this to the MCP HTTP
  /// server so connected clients receive `notifications/tools/list_changed`.
  void Function()? onToolsChanged;

  /// Replaces the personal (bridged) tool set. Called by the owner's MCP
  /// connection manager whenever their servers connect, disconnect, or
  /// hot-reload.
  void setPersonalTools(List<McpTool> tools) {
    _personal
      ..clear()
      ..addEntries(tools.map((t) => MapEntry(t.name, t)));
    onToolsChanged?.call();
  }

  /// Replaces [workspaceId]'s bridged tool set; an empty list drops the
  /// workspace's layer.
  void setWorkspaceTools(String workspaceId, List<McpTool> tools) {
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(workspaceId, 'workspaceId', 'is empty');
    }
    if (tools.isEmpty) {
      _workspace.remove(workspaceId);
    } else {
      _workspace[workspaceId] = {for (final t in tools) t.name: t};
    }
    onToolsChanged?.call();
  }

  /// Registers a host singleton tool (e.g. the BM25 search tool).
  void register(McpTool tool) {
    _extra[tool.name] = tool;
    onToolsChanged?.call();
  }

  /// Looks up a tool by name among the shared layers and the external ones
  /// [view] admits.
  McpTool? lookup(String name, {required McpToolView view}) =>
      _extra[name] ??
      (view.includePersonal ? _personal[name] : null) ??
      _workspaceLayer(view)?[name] ??
      _base[name];

  /// Whether [name] resolves, for [view], to a tool bridged from an external
  /// server (a personal or workspace one) rather than a Control Center tool.
  ///
  /// Such a tool takes no `workspace_id`: it is confined by the layer it sits
  /// in, which only a caller entitled to it can see.
  bool isExternal(String name, {required McpToolView view}) {
    if (_extra.containsKey(name)) {
      return false;
    }
    if (view.includePersonal && _personal.containsKey(name)) {
      return true;
    }
    return _workspaceLayer(view)?.containsKey(name) ?? false;
  }

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
  McpTool? resolve(String name, {required McpToolView view}) {
    final exact = lookup(name, view: view);
    if (exact != null) {
      return exact;
    }
    for (final candidate in _dePrefixedCandidates(name)) {
      final tool = lookup(candidate, view: view);
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

  /// The tool definitions advertised in `tools/list` to a caller with [view].
  List<ToolDef> listDefinitions({required McpToolView view}) =>
      _visible(view).values.map((t) => t.definition).toList();

  @override
  List<ToolDef> allToolDefinitions() =>
      listDefinitions(view: McpToolView.shared);

  /// Tool names a caller with [view] may use.
  Iterable<String> toolNames({required McpToolView view}) =>
      _visible(view).keys;

  /// Stable fingerprint of the shared catalogue (names + schema keys),
  /// as a hex string. Changes exactly when the advertised toolset changes, so
  /// embedding it in a client config invalidates config-hash-keyed tool-list
  /// caches on server upgrades.
  String get toolsetRevision {
    final entries = _visible(McpToolView.shared).values.map((t) {
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

  /// Every tool in every layer, counted once per name.
  Map<String, McpTool> _allTools() => {
    ..._base,
    for (final layer in _workspace.values) ...layer,
    ..._personal,
    ..._extra,
  };

  Map<String, McpTool>? _workspaceLayer(McpToolView view) {
    final id = view.workspaceId;
    return id == null || id.isEmpty ? null : _workspace[id];
  }

  /// What [view] admits, keyed by name, in [lookup]'s precedence: a later
  /// spread wins a clash.
  Map<String, McpTool> _visible(McpToolView view) => {
    ..._base,
    ...?_workspaceLayer(view),
    if (view.includePersonal) ..._personal,
    ..._extra,
  };
}
