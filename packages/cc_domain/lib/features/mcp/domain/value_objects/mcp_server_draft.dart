import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';

/// What a person sends to add or change a configured MCP server.
///
/// Secret values travel one way. [envSet] and [headerSet] write values,
/// [envRemove] and [headerRemove] drop them, and a name in neither keeps the
/// value it already has, so an edit never needs the values it cannot read
/// back.
class McpServerDraft {
  /// Creates a draft. Validation happens in [toDefinition], against the
  /// definition it replaces.
  McpServerDraft({
    this.id,
    required this.name,
    required this.transport,
    this.command,
    List<String> args = const [],
    this.url,
    this.enabled = true,
    Map<String, String> envSet = const {},
    Set<String> envRemove = const {},
    Map<String, String> headerSet = const {},
    Set<String> headerRemove = const {},
  }) : args = List.unmodifiable(args),
       envSet = Map.unmodifiable(envSet),
       envRemove = Set.unmodifiable(envRemove),
       headerSet = Map.unmodifiable(headerSet),
       headerRemove = Set.unmodifiable(headerRemove);

  /// Reads the wire shape [toJson] writes (RPC arguments).
  factory McpServerDraft.fromJson(Map<String, dynamic> json) => McpServerDraft(
    id: _optionalString(json['id']),
    name: (json['name'] as String? ?? '').trim(),
    transport: McpServerTransport.fromWire(json['transport']),
    command: _optionalString(json['command']),
    args: _strings(json['args'], 'args'),
    url: _optionalString(json['url']),
    enabled: json['enabled'] as bool? ?? true,
    envSet: _stringMap(json['env_set'], 'env'),
    envRemove: _strings(json['env_remove'], 'env').toSet(),
    headerSet: _stringMap(json['header_set'], 'header'),
    headerRemove: _strings(json['header_remove'], 'header').toSet(),
  );

  /// The longest secret value accepted.
  static const int maxValueLength = 8192;

  /// The server to change, or null to add one.
  final String? id;

  /// Its name.
  final String name;

  /// Its transport.
  final McpServerTransport transport;

  /// The executable (stdio).
  final String? command;

  /// The executable's arguments (stdio).
  final List<String> args;

  /// The endpoint (http, sse).
  final String? url;

  /// Whether it is dialled.
  final bool enabled;

  /// Environment values to write (stdio).
  final Map<String, String> envSet;

  /// Environment variables to drop.
  final Set<String> envRemove;

  /// Header values to write (http, sse).
  final Map<String, String> headerSet;

  /// Headers to drop.
  final Set<String> headerRemove;

  /// The definition this draft makes of [previous] (null when adding), with
  /// [id], [workspaceId] and [userId] (whose own server it is; null for the
  /// workspace's) decided by the caller, never by the draft.
  ///
  /// A name both written and removed is written: removal applies to the
  /// stored value first. Names carried over from [previous] are kept only on
  /// the same transport:
  /// moving between a process and a URL drops every stored value. Throws an
  /// [McpServerDefinitionException] for any field that cannot be dialled.
  McpServerDefinition toDefinition({
    required String id,
    required String workspaceId,
    required String? userId,
    required McpServerDefinition? previous,
    required String? createdBy,
    required String? hostApprovedBy,
    required DateTime now,
  }) {
    _checkValues();
    final sameTransport = previous?.transport == transport;
    final remote = transport.isRemote;
    final keptEnv = sameTransport ? previous!.envNames : const <String>[];
    final keptHeaders = sameTransport
        ? previous!.headerNames
        : const <String>[];
    return McpServerDefinition(
      id: id,
      workspaceId: workspaceId,
      userId: userId,
      name: name,
      transport: transport,
      command: remote ? null : command?.trim(),
      args: remote ? const [] : args,
      url: remote ? url?.trim() : null,
      envNames: remote
          ? const []
          : ({...keptEnv}
                  ..removeAll(envRemove)
                  ..addAll(envSet.keys))
                .toList(),
      headerNames: remote
          ? [
              ..._withoutCaseInsensitive(
                {...keptHeaders}..removeWhere(
                  (h) => headerSet.keys.any(
                    (k) => k.toLowerCase() == h.toLowerCase(),
                  ),
                ),
                headerRemove,
              ),
              ...headerSet.keys,
            ]
          : const [],
      enabled: enabled,
      createdBy: previous?.createdBy ?? createdBy,
      hostApprovedBy: hostApprovedBy,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Whether applying this draft to [previous] changes how the server is
  /// launched or reached: anything but [enabled].
  bool changesLaunch(McpServerDefinition previous) {
    if (previous.transport != transport ||
        previous.name != name ||
        envSet.isNotEmpty ||
        headerSet.isNotEmpty ||
        envRemove.any(previous.envNames.contains) ||
        headerRemove.any(
          (h) => previous.headerNames.any(
            (p) => p.toLowerCase() == h.toLowerCase(),
          ),
        )) {
      return true;
    }
    if (transport.isRemote) {
      return previous.url != url?.trim();
    }
    if (previous.command != command?.trim() ||
        previous.args.length != args.length) {
      return true;
    }
    for (var i = 0; i < args.length; i++) {
      if (previous.args[i] != args[i]) {
        return true;
      }
    }
    return false;
  }

  /// The snake_case wire shape.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'transport': transport.wire,
    if (command != null) 'command': command,
    'args': args,
    if (url != null) 'url': url,
    'enabled': enabled,
    'env_set': envSet,
    'env_remove': envRemove.toList(),
    'header_set': headerSet,
    'header_remove': headerRemove.toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is McpServerDraft &&
      other.id == id &&
      other.name == name &&
      other.transport == transport &&
      other.command == command &&
      _listEq(other.args, args) &&
      other.url == url &&
      other.enabled == enabled &&
      _mapEq(other.envSet, envSet) &&
      _setEq(other.envRemove, envRemove) &&
      _mapEq(other.headerSet, headerSet) &&
      _setEq(other.headerRemove, headerRemove);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    transport,
    command,
    Object.hashAll(args),
    url,
    enabled,
    Object.hashAllUnordered(envSet.entries.map((e) => '${e.key}=${e.value}')),
    Object.hashAllUnordered(envRemove),
    Object.hashAllUnordered(
      headerSet.entries.map((e) => '${e.key}=${e.value}'),
    ),
    Object.hashAllUnordered(headerRemove),
  );

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _mapEq(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  static bool _setEq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  void _checkValues() {
    for (final entry in envSet.entries) {
      if (!McpServerNames.env.hasMatch(entry.key) ||
          entry.value.length > maxValueLength ||
          entry.value.contains('\u0000')) {
        throw McpServerDefinitionException.invalid('env');
      }
    }
    for (final entry in headerSet.entries) {
      if (!McpServerNames.isAllowedHeader(entry.key) ||
          entry.value.length > maxValueLength ||
          entry.value.contains(RegExp(r'[\r\n\u0000]'))) {
        throw McpServerDefinitionException.invalid('header');
      }
    }
  }

  /// [names] minus [removed], comparing header names without case; the
  /// spelling last written wins.
  static List<String> _withoutCaseInsensitive(
    Set<String> names,
    Set<String> removed,
  ) {
    final drop = {for (final r in removed) r.toLowerCase()};
    final byLower = <String, String>{};
    for (final name in names) {
      if (!drop.contains(name.toLowerCase())) {
        byLower[name.toLowerCase()] = name;
      }
    }
    return byLower.values.toList();
  }

  static String? _optionalString(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw : null;

  static List<String> _strings(Object? raw, String field) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List || raw.any((v) => v is! String)) {
      throw McpServerDefinitionException.invalid(field);
    }
    return raw.cast<String>();
  }

  static Map<String, String> _stringMap(Object? raw, String field) {
    if (raw == null) {
      return const {};
    }
    if (raw is! Map || raw.values.any((v) => v is! String)) {
      throw McpServerDefinitionException.invalid(field);
    }
    return {for (final e in raw.entries) '${e.key}': e.value as String};
  }
}
