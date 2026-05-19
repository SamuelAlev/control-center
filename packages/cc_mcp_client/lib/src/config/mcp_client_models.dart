/// The lifecycle state of a connection to a single external MCP server.
///
/// String values match the upstream clients (oh-my-pi / kilocode) so they
/// serialise straight onto the wire for the settings UI.
enum McpServerLifecycle {
  /// Never dialled because the config is disabled.
  disabled,

  /// A connection attempt is in flight.
  connecting,

  /// Connected; tools (and optionally resources/prompts) listed.
  connected,

  /// The last connection attempt failed (non-auth error).
  failed,

  /// The server returned 401/needs authorization before tools can be listed.
  needsAuth,

  /// Dynamic client registration is required before the OAuth flow can start.
  needsClientRegistration,

  /// The crash-storm circuit breaker tripped — too many rapid reconnects.
  /// Held open until a manual reconnect resets the window.
  circuitOpen;

  /// The canonical wire string.
  String get wire => switch (this) {
    McpServerLifecycle.disabled => 'disabled',
    McpServerLifecycle.connecting => 'connecting',
    McpServerLifecycle.connected => 'connected',
    McpServerLifecycle.failed => 'failed',
    McpServerLifecycle.needsAuth => 'needs_auth',
    McpServerLifecycle.needsClientRegistration => 'needs_client_registration',
    McpServerLifecycle.circuitOpen => 'circuit_open',
  };

  /// Parses a wire string, defaulting to [disabled] for unknown values.
  static McpServerLifecycle fromWire(String? raw) => switch (raw) {
    'connecting' => McpServerLifecycle.connecting,
    'connected' => McpServerLifecycle.connected,
    'failed' => McpServerLifecycle.failed,
    'needs_auth' => McpServerLifecycle.needsAuth,
    'needs_client_registration' =>
      McpServerLifecycle.needsClientRegistration,
    'circuit_open' => McpServerLifecycle.circuitOpen,
    _ => McpServerLifecycle.disabled,
  };
}

/// A tool definition as advertised by an external MCP server's `tools/list`.
class McpRemoteTool {
  /// Creates an [McpRemoteTool].
  const McpRemoteTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Parses one entry from a `tools/list` result.
  factory McpRemoteTool.fromJson(Map<String, dynamic> json) => McpRemoteTool(
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    inputSchema:
        (json['inputSchema'] as Map?)?.cast<String, dynamic>() ??
        const {'type': 'object', 'properties': <String, dynamic>{}},
  );

  /// The server-local tool name (un-namespaced).
  final String name;

  /// Human/agent-readable description.
  final String description;

  /// JSON Schema for the tool's arguments.
  final Map<String, dynamic> inputSchema;
}

/// A resource advertised by an external MCP server's `resources/list`.
class McpRemoteResource {
  /// Creates an [McpRemoteResource].
  const McpRemoteResource({
    required this.uri,
    required this.name,
    this.title,
    this.description,
    this.mimeType,
  });

  /// Parses one entry from a `resources/list` result.
  factory McpRemoteResource.fromJson(Map<String, dynamic> json) =>
      McpRemoteResource(
        uri: json['uri'] as String? ?? '',
        name: json['name'] as String? ?? '',
        title: json['title'] as String?,
        description: json['description'] as String?,
        mimeType: json['mimeType'] as String?,
      );

  /// The resource URI (e.g. `file:///path`, `git://...`).
  final String uri;

  /// Stable resource name.
  final String name;

  /// Optional display title.
  final String? title;

  /// Optional description.
  final String? description;

  /// Optional MIME type of the resource contents.
  final String? mimeType;
}

/// A prompt advertised by an external MCP server's `prompts/list`.
class McpRemotePrompt {
  /// Creates an [McpRemotePrompt].
  const McpRemotePrompt({
    required this.name,
    this.title,
    this.description,
    this.arguments = const [],
  });

  /// Parses one entry from a `prompts/list` result.
  factory McpRemotePrompt.fromJson(Map<String, dynamic> json) =>
      McpRemotePrompt(
        name: json['name'] as String? ?? '',
        title: json['title'] as String?,
        description: json['description'] as String?,
        arguments:
            (json['arguments'] as List?)
                ?.whereType<Map>()
                .map((a) => McpPromptArgument.fromJson(a.cast<String, dynamic>()))
                .toList() ??
            const [],
      );

  /// The prompt name (surfaced to agents as a slash command).
  final String name;

  /// Optional display title.
  final String? title;

  /// Optional description.
  final String? description;

  /// Declared arguments.
  final List<McpPromptArgument> arguments;
}

/// A single declared argument of an [McpRemotePrompt].
class McpPromptArgument {
  /// Creates an [McpPromptArgument].
  const McpPromptArgument({
    required this.name,
    this.description,
    this.required = false,
  });

  /// Parses one entry from a prompt's `arguments` array.
  factory McpPromptArgument.fromJson(Map<String, dynamic> json) =>
      McpPromptArgument(
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        required: json['required'] as bool? ?? false,
      );

  /// Argument name.
  final String name;

  /// Optional description.
  final String? description;

  /// Whether the argument must be supplied.
  final bool required;
}

/// What a connected server advertised in its `initialize` capabilities.
class McpServerCapabilities {
  /// Creates an [McpServerCapabilities].
  const McpServerCapabilities({
    this.tools = false,
    this.resources = false,
    this.prompts = false,
    this.toolsListChanged = false,
    this.resourcesListChanged = false,
    this.promptsListChanged = false,
  });

  /// Parses the `capabilities` object from an `initialize` result.
  factory McpServerCapabilities.fromJson(Map<String, dynamic> json) {
    final tools = json['tools'];
    final resources = json['resources'];
    final prompts = json['prompts'];
    bool listChanged(Object? cap) =>
        cap is Map && cap['listChanged'] == true;
    return McpServerCapabilities(
      tools: tools != null,
      resources: resources != null,
      prompts: prompts != null,
      toolsListChanged: listChanged(tools),
      resourcesListChanged: listChanged(resources),
      promptsListChanged: listChanged(prompts),
    );
  }

  /// Server exposes tools.
  final bool tools;

  /// Server exposes resources.
  final bool resources;

  /// Server exposes prompts.
  final bool prompts;

  /// Server emits `notifications/tools/list_changed`.
  final bool toolsListChanged;

  /// Server emits `notifications/resources/list_changed`.
  final bool resourcesListChanged;

  /// Server emits `notifications/prompts/list_changed`.
  final bool promptsListChanged;
}

/// An immutable snapshot of one server's connection state, for the UI and the
/// `mcp.client.servers` RPC op.
class McpServerStatusSnapshot {
  /// Creates an [McpServerStatusSnapshot].
  const McpServerStatusSnapshot({
    required this.name,
    required this.transport,
    required this.lifecycle,
    required this.toolCount,
    required this.resourceCount,
    required this.promptCount,
    this.auth = 'none',
    this.source,
    this.lastError,
  });

  /// Reconstructs the snapshot from the wire map (mirror of [toJson]).
  factory McpServerStatusSnapshot.fromJson(Map<String, dynamic> json) =>
      McpServerStatusSnapshot(
        name: json['name'] as String? ?? '',
        transport: json['transport'] as String? ?? 'stdio',
        lifecycle: McpServerLifecycle.fromWire(json['lifecycle'] as String?),
        toolCount: (json['tool_count'] as num?)?.toInt() ?? 0,
        resourceCount: (json['resource_count'] as num?)?.toInt() ?? 0,
        promptCount: (json['prompt_count'] as num?)?.toInt() ?? 0,
        auth: json['auth'] as String? ?? 'none',
        source: json['source'] as String?,
        lastError: json['last_error'] as String?,
      );

  /// Server name.
  final String name;

  /// Transport wire string.
  final String transport;

  /// Auth wire string (`none` | `oauth` | `header`).
  final String auth;

  /// Current lifecycle state.
  final McpServerLifecycle lifecycle;

  /// Number of bridged tools (0 unless [lifecycle] is connected).
  final int toolCount;

  /// Number of resources advertised.
  final int resourceCount;

  /// Number of prompts advertised.
  final int promptCount;

  /// Where the config came from (discovery source), if known.
  final String? source;

  /// Last error message, when [lifecycle] is failed / needsAuth.
  final String? lastError;

  /// The snake_case wire map for the settings UI / RPC.
  Map<String, dynamic> toJson() => {
    'name': name,
    'transport': transport,
    'lifecycle': lifecycle.wire,
    'auth': auth,
    'tool_count': toolCount,
    'resource_count': resourceCount,
    'prompt_count': promptCount,
    if (source != null) 'source': source,
    if (lastError != null) 'last_error': lastError,
  };
}
