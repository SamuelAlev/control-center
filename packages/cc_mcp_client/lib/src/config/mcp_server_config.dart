/// The transport an external MCP server speaks.
///
/// Mirrors the discriminated union the upstream clients (oh-my-pi, kilocode)
/// model on a `type` field: `stdio` (a local child process speaking
/// newline-delimited JSON-RPC over stdio), `http` (the Streamable HTTP
/// transport), and `sse` (the legacy Server-Sent-Events transport).
enum McpTransportKind {
  /// Local child process; JSON-RPC framed as newline-delimited JSON on stdio.
  stdio,

  /// Streamable HTTP transport (`POST` for requests, optional `GET` SSE
  /// stream for server→client messages).
  http,

  /// Legacy Server-Sent-Events transport (a long-lived `GET` SSE stream plus a
  /// per-message `POST` endpoint advertised via an `endpoint` event).
  sse;

  /// Parses a wire string (`stdio` | `http` | `sse`), defaulting to [stdio]
  /// when absent or unrecognised — matching upstream's "stdio is the default
  /// when `type` is omitted" behaviour.
  static McpTransportKind fromWire(String? raw) {
    switch (raw) {
      case 'http':
      case 'streamable-http':
      case 'streamableHttp':
        return McpTransportKind.http;
      case 'sse':
        return McpTransportKind.sse;
      case 'stdio':
      case 'local':
      case null:
      default:
        return McpTransportKind.stdio;
    }
  }

  /// The canonical wire string for this kind.
  String get wire => switch (this) {
    McpTransportKind.stdio => 'stdio',
    McpTransportKind.http => 'http',
    McpTransportKind.sse => 'sse',
  };
}

/// How an external MCP server authenticates incoming requests.
enum McpAuthKind {
  /// No authentication.
  none,

  /// A static bearer token / API key supplied via [McpServerConfig.headers]
  /// or a stored credential.
  apiKey,

  /// OAuth 2.1 with dynamic client registration + PKCE (see the `oauth/`
  /// subsystem).
  oauth;

  /// Parses a wire string, defaulting to [none].
  static McpAuthKind fromWire(String? raw) => switch (raw) {
    'oauth' => McpAuthKind.oauth,
    'apikey' || 'apiKey' || 'api_key' => McpAuthKind.apiKey,
    _ => McpAuthKind.none,
  };

  /// The canonical wire string for this kind.
  String get wire => switch (this) {
    McpAuthKind.none => 'none',
    McpAuthKind.apiKey => 'apikey',
    McpAuthKind.oauth => 'oauth',
  };
}

/// The single canonical configuration for an external MCP server.
///
/// Every multi-format discovery source (Claude, Codex, Cursor, Gemini, VS Code,
/// Windsurf, OpenCode, a standalone `.mcp.json`) normalises down to this one
/// shape. It is workspace-agnostic on its own — the `ConnectionManager` is
/// always handed a workspace-scoped set, never a global one.
class McpServerConfig {
  /// Creates an [McpServerConfig].
  const McpServerConfig({
    required this.name,
    required this.transport,
    this.command,
    this.args = const [],
    this.env = const {},
    this.cwd,
    this.url,
    this.headers = const {},
    this.enabled = true,
    this.timeout = const Duration(seconds: 30),
    this.auth = McpAuthKind.none,
    this.oauthScopes = const [],
    this.source,
  });

  /// Builds a stdio server config.
  factory McpServerConfig.stdio({
    required String name,
    required String command,
    List<String> args = const [],
    Map<String, String> env = const {},
    String? cwd,
    bool enabled = true,
    Duration timeout = const Duration(seconds: 30),
    String? source,
  }) => McpServerConfig(
    name: name,
    transport: McpTransportKind.stdio,
    command: command,
    args: args,
    env: env,
    cwd: cwd,
    enabled: enabled,
    timeout: timeout,
    source: source,
  );

  /// Builds an HTTP (Streamable HTTP) server config.
  factory McpServerConfig.http({
    required String name,
    required String url,
    Map<String, String> headers = const {},
    bool enabled = true,
    Duration timeout = const Duration(seconds: 30),
    McpAuthKind auth = McpAuthKind.none,
    List<String> oauthScopes = const [],
    String? source,
  }) => McpServerConfig(
    name: name,
    transport: McpTransportKind.http,
    url: url,
    headers: headers,
    enabled: enabled,
    timeout: timeout,
    auth: auth,
    oauthScopes: oauthScopes,
    source: source,
  );

  /// Builds an SSE server config.
  factory McpServerConfig.sse({
    required String name,
    required String url,
    Map<String, String> headers = const {},
    bool enabled = true,
    Duration timeout = const Duration(seconds: 30),
    McpAuthKind auth = McpAuthKind.none,
    List<String> oauthScopes = const [],
    String? source,
  }) => McpServerConfig(
    name: name,
    transport: McpTransportKind.sse,
    url: url,
    headers: headers,
    enabled: enabled,
    timeout: timeout,
    auth: auth,
    oauthScopes: oauthScopes,
    source: source,
  );

  /// Reconstructs a config from a canonical JSON map (the shape [toJson]
  /// produces and the discovery normalisers emit).
  factory McpServerConfig.fromJson(String name, Map<String, dynamic> json) {
    final transport = McpTransportKind.fromWire(json['type'] as String?);
    final timeoutMs = (json['timeout'] as num?)?.toInt();
    return McpServerConfig(
      name: name,
      transport: transport,
      command: json['command'] as String?,
      args:
          (json['args'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      env: _stringMap(json['env']),
      cwd: json['cwd'] as String?,
      url: json['url'] as String?,
      headers: _stringMap(json['headers']),
      enabled: json['enabled'] as bool? ?? true,
      timeout: timeoutMs != null && timeoutMs > 0
          ? Duration(milliseconds: timeoutMs)
          : const Duration(seconds: 30),
      auth: McpAuthKind.fromWire(
        (json['auth'] as Map?)?['type'] as String? ?? json['auth'] as String?,
      ),
      oauthScopes:
          (json['scopes'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      source: json['source'] as String?,
    );
  }

  /// Stable, user-facing server name. Tools are namespaced under it.
  final String name;

  /// Which transport this server speaks.
  final McpTransportKind transport;

  /// Executable to launch (stdio only).
  final String? command;

  /// Arguments passed to [command] (stdio only).
  final List<String> args;

  /// Extra environment for the child process (stdio only). Merged over the
  /// inherited environment.
  final Map<String, String> env;

  /// Working directory for the child process (stdio only).
  final String? cwd;

  /// Endpoint URL (http / sse only).
  final String? url;

  /// Static headers attached to every request (http / sse only). A bearer
  /// token / API key lives here for [McpAuthKind.apiKey].
  final Map<String, String> headers;

  /// Whether this server should be connected. A disabled server is tracked
  /// (so it can be flipped on) but never dialled.
  final bool enabled;

  /// Per-request timeout. A zero/negative value disables the timeout.
  final Duration timeout;

  /// How the server authenticates.
  final McpAuthKind auth;

  /// OAuth scopes requested during authorization (oauth only).
  final List<String> oauthScopes;

  /// Where this config was discovered (e.g. `claude:~/.claude.json`,
  /// `workspace:.mcp.json`). Null for hand-built configs. Surfaced in the UI
  /// so the user can tell why a server appeared.
  final String? source;

  /// True when this config carries everything a transport needs to dial it.
  bool get isValid {
    switch (transport) {
      case McpTransportKind.stdio:
        return (command ?? '').trim().isNotEmpty;
      case McpTransportKind.http:
      case McpTransportKind.sse:
        final u = url;
        return u != null && Uri.tryParse(u)?.hasScheme == true;
    }
  }

  /// The server origin (scheme + host + port) for http/sse, used to key OAuth
  /// tokens and validate them against the server URL. Null for stdio.
  String? get origin {
    final u = url;
    if (u == null) {
      return null;
    }
    final parsed = Uri.tryParse(u);
    if (parsed == null || !parsed.hasScheme) {
      return null;
    }
    final port = parsed.hasPort ? ':${parsed.port}' : '';
    return '${parsed.scheme}://${parsed.host}$port';
  }

  /// Returns a copy with selected fields overridden.
  McpServerConfig copyWith({
    String? name,
    McpTransportKind? transport,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    String? cwd,
    String? url,
    Map<String, String>? headers,
    bool? enabled,
    Duration? timeout,
    McpAuthKind? auth,
    List<String>? oauthScopes,
    String? source,
  }) => McpServerConfig(
    name: name ?? this.name,
    transport: transport ?? this.transport,
    command: command ?? this.command,
    args: args ?? this.args,
    env: env ?? this.env,
    cwd: cwd ?? this.cwd,
    url: url ?? this.url,
    headers: headers ?? this.headers,
    enabled: enabled ?? this.enabled,
    timeout: timeout ?? this.timeout,
    auth: auth ?? this.auth,
    oauthScopes: oauthScopes ?? this.oauthScopes,
    source: source ?? this.source,
  );

  /// Serialises to the canonical JSON map (without the [name], which is the
  /// map key in a `mcpServers` object).
  Map<String, dynamic> toJson() => {
    'type': transport.wire,
    if (command != null) 'command': command,
    if (args.isNotEmpty) 'args': args,
    if (env.isNotEmpty) 'env': env,
    if (cwd != null) 'cwd': cwd,
    if (url != null) 'url': url,
    if (headers.isNotEmpty) 'headers': headers,
    'enabled': enabled,
    'timeout': timeout.inMilliseconds,
    if (auth != McpAuthKind.none) 'auth': auth.wire,
    if (oauthScopes.isNotEmpty) 'scopes': oauthScopes,
    if (source != null) 'source': source,
  };

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries) entry.key.toString(): '${entry.value}',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is McpServerConfig &&
      other.name == name &&
      other.transport == transport &&
      other.command == command &&
      other.url == url &&
      other.cwd == cwd &&
      other.enabled == enabled &&
      other.auth == auth &&
      _listEq(other.args, args) &&
      _mapEq(other.env, env) &&
      _mapEq(other.headers, headers);

  @override
  int get hashCode => Object.hash(
    name,
    transport,
    command,
    url,
    cwd,
    enabled,
    auth,
    Object.hashAll(args),
  );

  @override
  String toString() =>
      'McpServerConfig($name, ${transport.wire}, '
      '${transport == McpTransportKind.stdio ? command : url})';

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

  static bool _mapEq(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
