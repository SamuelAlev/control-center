import 'package:cc_domain/src/errors/app_exceptions.dart';

/// The transport a configured MCP server speaks.
enum McpServerTransport {
  /// A local child process speaking newline-delimited JSON-RPC on stdio. It
  /// runs on the server host, as the server's OS user.
  stdio,

  /// The Streamable HTTP transport.
  http,

  /// The legacy Server-Sent-Events transport.
  sse;

  /// The canonical wire string.
  String get wire => name;

  /// Parses [raw], or throws an [McpServerDefinitionException] for anything
  /// else: a stored or requested transport is never guessed.
  static McpServerTransport fromWire(Object? raw) {
    for (final value in values) {
      if (value.wire == raw) {
        return value;
      }
    }
    throw McpServerDefinitionException.invalid('transport');
  }

  /// Whether a server on this transport is dialled at a URL.
  bool get isRemote => this != stdio;
}

/// Why a configured MCP server was refused, as a `data.kind` the clients
/// localize (`mcp_server.<reason>`), with the offending field when there is
/// one.
class McpServerDefinitionException extends ValidationException {
  /// Creates an [McpServerDefinitionException] with [code].
  const McpServerDefinitionException(super.message, {required super.code});

  /// A field that does not hold a usable value.
  McpServerDefinitionException.invalid(String field)
    : this('MCP server $field is not valid', code: 'mcp_server.invalid_$field');

  /// Another server in the same scope already has this name.
  const McpServerDefinitionException.nameTaken()
    : this(
        'Another MCP server already has this name',
        code: 'mcp_server.name_taken',
      );
}

/// A configured MCP server is not known in this scope.
class McpServerNotFoundException extends NotFoundException {
  /// Creates an [McpServerNotFoundException].
  const McpServerNotFoundException()
    : super('MCP server not found', code: 'mcp_server.not_found');
}

/// The names a server, environment variable or header may take.
// ignore: avoid_classes_with_only_static_members
abstract final class McpServerNames {
  /// A server name: it becomes the tool namespace `mcp__<name>__<tool>`,
  /// which has to fit a 43-character tool name, so it stays short.
  static final RegExp server = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,23}$');

  /// A process environment variable name.
  static final RegExp env = RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,127}$');

  /// An HTTP header field name (RFC 9110 token).
  static final RegExp header = RegExp(r"^[A-Za-z0-9!#$%&'*+.^_`|~-]{1,128}$");

  /// Headers the transport owns. A configured value would corrupt framing,
  /// redirect the request or replace the MCP session.
  static const Set<String> reservedHeaders = {
    'connection',
    'content-length',
    'content-type',
    'host',
    'keep-alive',
    'mcp-session-id',
    'proxy-authorization',
    'te',
    'trailer',
    'transfer-encoding',
    'upgrade',
  };

  /// Whether [name] is a header a configured server may set.
  static bool isAllowedHeader(String name) =>
      header.hasMatch(name) && !reservedHeaders.contains(name.toLowerCase());
}

/// An MCP server someone configured by hand, either for one workspace (its
/// [workspaceId]) or as one of the server owner's personal servers (no
/// workspace).
///
/// It holds no secret: environment variable and header values live in the
/// server's secrets store, and the definition keeps only their names
/// ([envNames], [headerNames]).
///
/// A [McpServerTransport.stdio] server runs on the host, so in a workspace it
/// is dialled only once the current server owner approved it
/// ([hostApprovedBy]). A remote one reaches only public addresses until then.
class McpServerDefinition {
  /// Creates a definition, refusing any field that cannot be dialled.
  McpServerDefinition({
    required this.id,
    this.workspaceId,
    required this.name,
    required this.transport,
    this.command,
    List<String> args = const [],
    this.url,
    List<String> envNames = const [],
    List<String> headerNames = const [],
    this.enabled = true,
    this.createdBy,
    this.hostApprovedBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : createdAt = _toStoredPrecision(createdAt),
       updatedAt = _toStoredPrecision(updatedAt),
       args = List.unmodifiable(args),
       envNames = List.unmodifiable(_sortedUnique(envNames)),
       headerNames = List.unmodifiable(_sortedUnique(headerNames)) {
    if (id.trim().isEmpty) {
      throw McpServerDefinitionException.invalid('id');
    }
    if (workspaceId != null && workspaceId!.trim().isEmpty) {
      throw McpServerDefinitionException.invalid('workspace');
    }
    if (!McpServerNames.server.hasMatch(name)) {
      throw McpServerDefinitionException.invalid('name');
    }
    switch (transport) {
      case McpServerTransport.stdio:
        final cmd = command;
        if (cmd == null || cmd.trim().isEmpty || cmd.contains('\u0000')) {
          throw McpServerDefinitionException.invalid('command');
        }
        if (args.any((a) => a.contains('\u0000'))) {
          throw McpServerDefinitionException.invalid('args');
        }
        if (url != null || headerNames.isNotEmpty) {
          throw McpServerDefinitionException.invalid('transport');
        }
        if (!this.envNames.every(McpServerNames.env.hasMatch)) {
          throw McpServerDefinitionException.invalid('env');
        }
      case McpServerTransport.http:
      case McpServerTransport.sse:
        if (!isDialableUrl(url)) {
          throw McpServerDefinitionException.invalid('url');
        }
        if (command != null || args.isNotEmpty || envNames.isNotEmpty) {
          throw McpServerDefinitionException.invalid('transport');
        }
        if (!this.headerNames.every(McpServerNames.isAllowedHeader)) {
          throw McpServerDefinitionException.invalid('header');
        }
        final lowered = {for (final h in this.headerNames) h.toLowerCase()};
        if (lowered.length != this.headerNames.length) {
          throw McpServerDefinitionException.invalid('header');
        }
    }
  }

  /// Reads the wire shape [toJson] writes.
  factory McpServerDefinition.fromJson(Map<String, dynamic> json) =>
      McpServerDefinition(
        id: json['id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String?,
        name: json['name'] as String? ?? '',
        transport: McpServerTransport.fromWire(json['transport']),
        command: json['command'] as String?,
        args: _strings(json['args']),
        url: json['url'] as String?,
        envNames: _strings(json['env_names']),
        headerNames: _strings(json['header_names']),
        enabled: json['enabled'] as bool? ?? true,
        createdBy: json['created_by'] as String?,
        hostApprovedBy: json['host_approved_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Stable id.
  final String id;

  /// The workspace it belongs to, or null for a personal server.
  final String? workspaceId;

  /// Unique within its scope; namespaces its tools (`mcp__<name>__<tool>`).
  final String name;

  /// How it is reached.
  final McpServerTransport transport;

  /// The executable (stdio only).
  final String? command;

  /// The executable's arguments (stdio only).
  final List<String> args;

  /// The endpoint (http and sse only).
  final String? url;

  /// The environment variables set for the process, by name; values are
  /// secrets (stdio only).
  final List<String> envNames;

  /// The headers sent with every request, by name; values are secrets (http
  /// and sse only).
  final List<String> headerNames;

  /// Whether it is dialled at all.
  final bool enabled;

  /// Who added it. No foreign key: users live in the global database.
  final String? createdBy;

  /// The server owner who approved it as it stands, or null. Written only by
  /// the server, never from a client's copy; an edit by anyone else clears it.
  final String? hostApprovedBy;

  /// When it was added.
  final DateTime createdAt;

  /// When it last changed.
  final DateTime updatedAt;

  /// Whether it runs a process on the host.
  bool get runsOnHost => transport == McpServerTransport.stdio;

  /// Whether [serverOwnerUserId], the current server owner, approved it. No
  /// owner known: nobody did.
  bool isHostApprovedBy(String? serverOwnerUserId) =>
      serverOwnerUserId != null &&
      serverOwnerUserId.isNotEmpty &&
      hostApprovedBy == serverOwnerUserId;

  /// Whether [url] is an absolute `http`/`https` URL with a host and no user
  /// info (a password in a URL would be stored in the clear).
  static bool isDialableUrl(String? url) {
    final parsed = url == null ? null : Uri.tryParse(url.trim());
    return parsed != null &&
        (parsed.scheme == 'https' || parsed.scheme == 'http') &&
        parsed.host.isNotEmpty &&
        parsed.userInfo.isEmpty &&
        parsed.fragment.isEmpty;
  }

  /// A copy with [enabled] or the approval changed. The launch fields never
  /// change in place: a save builds a new definition, so switching transport
  /// cannot leave a stale command or URL behind. [hostApprovedBy] is set with
  /// a new value or dropped with [clearHostApproval]; omitted, it is kept.
  McpServerDefinition copyWith({
    bool? enabled,
    String? hostApprovedBy,
    bool clearHostApproval = false,
    DateTime? updatedAt,
  }) => McpServerDefinition(
    id: id,
    workspaceId: workspaceId,
    name: name,
    transport: transport,
    command: command,
    args: args,
    url: url,
    envNames: envNames,
    headerNames: headerNames,
    enabled: enabled ?? this.enabled,
    createdBy: createdBy,
    hostApprovedBy: clearHostApproval
        ? null
        : hostApprovedBy ?? this.hostApprovedBy,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// The snake_case wire shape. Carries no secret value.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (workspaceId != null) 'workspace_id': workspaceId,
    'name': name,
    'transport': transport.wire,
    if (command != null) 'command': command,
    'args': args,
    if (url != null) 'url': url,
    'env_names': envNames,
    'header_names': headerNames,
    'enabled': enabled,
    if (createdBy != null) 'created_by': createdBy,
    if (hostApprovedBy != null) 'host_approved_by': hostApprovedBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is McpServerDefinition &&
      other.id == id &&
      other.workspaceId == workspaceId &&
      other.name == name &&
      other.transport == transport &&
      other.command == command &&
      _listEq(other.args, args) &&
      other.url == url &&
      _listEq(other.envNames, envNames) &&
      _listEq(other.headerNames, headerNames) &&
      other.enabled == enabled &&
      other.createdBy == createdBy &&
      other.hostApprovedBy == hostApprovedBy &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    transport,
    command,
    Object.hashAll(args),
    url,
    Object.hashAll(envNames),
    Object.hashAll(headerNames),
    enabled,
    createdBy,
    hostApprovedBy,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'McpServerDefinition($id, $name, ${transport.wire}, '
      'workspace: $workspaceId)';

  /// UTC whole seconds: what the database keeps, so a definition equals the
  /// copy read back from storage or the wire.
  static DateTime _toStoredPrecision(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  static List<String> _sortedUnique(List<String> values) =>
      values.toSet().toList()..sort();

  static List<String> _strings(Object? raw) => raw is List
      ? [for (final value in raw) '$value']
      : const <String>[];

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
}
