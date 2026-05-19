import 'dart:async';

import 'package:cc_mcp_client/src/config/mcp_client_models.dart';
import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/mcp_client.dart';
import 'package:cc_mcp_client/src/protocol.dart';
import 'package:cc_mcp_client/src/tool_bridge.dart';
import 'package:cc_mcp_client/src/transports/mcp_transport.dart';

/// Builds a transport for a given server config. Injected so the manager stays
/// ignorant of stdio-vs-HTTP-vs-SSE and of OAuth.
typedef McpTransportFactory =
    Future<McpTransport> Function(McpServerConfig config);

/// A structured log sink. The host wires this to `CcMcpLog` (or a test spy).
typedef McpClientLogSink =
    void Function(String level, String message, {Object? error});

/// A signal that authorization is required for [config]. The host can launch
/// the OAuth flow in response.
typedef NeedsAuthCallback = void Function(McpServerConfig config);

/// Manages the lifecycle of connections to a set of external MCP servers and
/// exposes their tools — bridged into CC's local [BridgedMcpTool] surface —
/// as a single live collection.
///
/// Responsibilities (PRD 01, phase 1.1):
/// * **Concurrent connect on boot** — every enabled server is dialled in
///   parallel; a slow/dead server never blocks the others.
/// * **Per-server lifecycle** — `connecting → connected | failed | needs_auth`
///   etc., surfaced via [statuses].
/// * **Crash-storm circuit breaker** — more than [reconnectBurstLimit] reconnects
///   inside [reconnectBurstWindow] trips the breaker; it stays open until a
///   *manual* reconnect resets the window. Stops a crash-looping server from
///   pinning a CPU.
/// * **Hot-reload** — subscribes to `notifications/tools/list_changed` and
///   re-lists, emitting on [toolsChanged].
/// * **Clean shutdown** — closes every client, which SIGTERMs stdio child
///   process trees so no zombies survive.
class ConnectionManager {
  /// Creates a [ConnectionManager].
  ConnectionManager({
    required McpTransportFactory transportFactory,
    this.onToolsChanged,
    this.onNeedsAuth,
    this.log,
    this.reconnectBurstLimit = 5,
    this.reconnectBurstWindow = const Duration(seconds: 30),
    this.reconnectBackoff = const [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  }) : _transportFactory = transportFactory;

  final McpTransportFactory _transportFactory;

  /// Invoked (debounced to a microtask) whenever the aggregate tool set
  /// changes — a server connects/disconnects or hot-reloads its tools.
  final void Function()? onToolsChanged;

  /// Invoked when a server reports it needs authorization.
  final NeedsAuthCallback? onNeedsAuth;

  /// Optional structured log sink.
  final McpClientLogSink? log;

  /// Reconnects allowed inside [reconnectBurstWindow] before the breaker trips.
  final int reconnectBurstLimit;

  /// Sliding window for the crash-storm circuit breaker.
  final Duration reconnectBurstWindow;

  /// Per-attempt reconnect backoff delays. After the last entry, the manager
  /// gives up until a manual reconnect.
  final List<Duration> reconnectBackoff;

  final _connections = <String, _ServerConnection>{};
  final _toolsChanged = StreamController<void>.broadcast();
  bool _shuttingDown = false;

  /// Fires whenever the aggregate tool set changes.
  Stream<void> get toolsChanged => _toolsChanged.stream;

  /// All bridged tools across every connected server, sorted by name for
  /// prompt-cache stability (a stable ordering keeps the agent's tool-list
  /// prefix cacheable across turns).
  List<BridgedMcpTool> get tools {
    final all = <BridgedMcpTool>[];
    for (final conn in _connections.values) {
      all.addAll(conn.tools);
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  /// All resources advertised across every connected server.
  List<({String server, McpRemoteResource resource})> get resources => [
    for (final conn in _connections.values)
      for (final r in conn.resources) (server: conn.config.name, resource: r),
  ];

  /// All prompts advertised across every connected server.
  List<({String server, McpRemotePrompt prompt})> get prompts => [
    for (final conn in _connections.values)
      for (final p in conn.prompts) (server: conn.config.name, prompt: p),
  ];

  /// A status snapshot per known server.
  List<McpServerStatusSnapshot> get statuses => [
    for (final conn in _connections.values)
      McpServerStatusSnapshot(
        name: conn.config.name,
        transport: conn.config.transport.wire,
        lifecycle: conn.lifecycle,
        auth: conn.config.auth.wire,
        toolCount: conn.tools.length,
        resourceCount: conn.resources.length,
        promptCount: conn.prompts.length,
        source: conn.config.source,
        lastError: conn.lastError,
      ),
  ];

  /// The config for the server named [name], or null if unknown. Used by the
  /// control surface to resolve a name → config for the interactive OAuth flow.
  McpServerConfig? configFor(String name) => _connections[name]?.config;

  /// Dials every enabled server in [configs] concurrently. Disabled servers are
  /// tracked (so the UI can flip them on) but not dialled. Replaces any prior
  /// set — servers no longer present are disconnected.
  Future<void> connectAll(List<McpServerConfig> configs) async {
    _shuttingDown = false;
    final desired = {for (final c in configs) c.name};

    // Drop servers no longer configured.
    final removed = _connections.keys
        .where((name) => !desired.contains(name))
        .toList();
    for (final name in removed) {
      await disconnect(name);
      _connections.remove(name);
    }

    final tasks = <Future<void>>[];
    for (final config in configs) {
      final existing = _connections[config.name];
      if (existing != null && existing.config == config) {
        continue; // unchanged
      }
      tasks.add(connect(config));
    }
    await Future.wait(tasks);
  }

  /// Connects (or re-connects) a single server.
  Future<void> connect(McpServerConfig config) async {
    final conn = _connections.putIfAbsent(
      config.name,
      () => _ServerConnection(config),
    )..config = config;

    if (!config.enabled) {
      conn.lifecycle = McpServerLifecycle.disabled;
      await conn.teardown();
      _emitToolsChanged();
      return;
    }
    if (!config.isValid) {
      conn
        ..lifecycle = McpServerLifecycle.failed
        ..lastError = 'invalid configuration';
      return;
    }

    conn.lifecycle = McpServerLifecycle.connecting;
    try {
      final transport = await _transportFactory(config);
      final client = McpClient(transport);
      await client.initialize(timeout: config.timeout);
      conn.client = client;
      conn.lastError = null;
      await _loadServer(conn);
      conn.lifecycle = McpServerLifecycle.connected;
      _wireNotifications(conn);
      _watchClose(conn);
      _log('info', 'connected to "${config.name}" (${conn.tools.length} tools)');
    } on Object catch (e) {
      conn.lastError = e.toString();
      if (_looksLikeAuthError(e)) {
        conn.lifecycle = McpServerLifecycle.needsAuth;
        onNeedsAuth?.call(config);
        _log('warn', 'server "${config.name}" needs authorization');
      } else {
        conn.lifecycle = McpServerLifecycle.failed;
        _log('warn', 'failed to connect "${config.name}": $e', error: e);
      }
      await conn.teardown();
    }
    _emitToolsChanged();
  }

  /// Disconnects a server (idempotent). Keeps the config record so it can be
  /// re-enabled.
  Future<void> disconnect(String name) async {
    final conn = _connections[name];
    if (conn == null) {
      return;
    }
    conn.lifecycle = McpServerLifecycle.disabled;
    await conn.teardown();
    _emitToolsChanged();
  }

  /// Reconnects a server. A [manual] reconnect resets the crash-storm window so
  /// the breaker can re-arm.
  Future<void> reconnect(String name, {bool manual = false}) async {
    final conn = _connections[name];
    if (conn == null) {
      return;
    }
    if (manual) {
      conn.reconnectHistory.clear();
    }
    await conn.teardown();
    await connect(conn.config);
  }

  Future<void> _loadServer(_ServerConnection conn) async {
    final client = conn.client!;
    final remoteTools = await client.listTools(timeout: conn.config.timeout);
    conn.tools = [
      for (final t in remoteTools)
        BridgedMcpTool(
          serverName: conn.config.name,
          remoteTool: t,
          invoker: _invoke,
        ),
    ];
    if (client.capabilities.resources) {
      conn.resources = await client.listResources(timeout: conn.config.timeout);
    }
    if (client.capabilities.prompts) {
      conn.prompts = await client.listPrompts(timeout: conn.config.timeout);
    }
  }

  void _wireNotifications(_ServerConnection conn) {
    final client = conn.client;
    if (client == null) {
      return;
    }
    conn.notifSub = client.notifications.listen((notif) async {
      switch (notif.method) {
        case McpProtocol.toolListChanged:
          await _refreshTools(conn);
        case McpProtocol.resourceListChanged:
          if (client.capabilities.resources) {
            conn.resources = await client.listResources(
              timeout: conn.config.timeout,
            );
            _emitToolsChanged();
          }
        case McpProtocol.promptListChanged:
          if (client.capabilities.prompts) {
            conn.prompts = await client.listPrompts(
              timeout: conn.config.timeout,
            );
            _emitToolsChanged();
          }
      }
    });
  }

  Future<void> _refreshTools(_ServerConnection conn) async {
    final client = conn.client;
    if (client == null) {
      return;
    }
    try {
      final remoteTools = await client.listTools(timeout: conn.config.timeout);
      conn.tools = [
        for (final t in remoteTools)
          BridgedMcpTool(
            serverName: conn.config.name,
            remoteTool: t,
            invoker: _invoke,
          ),
      ];
      _log('info', 'hot-reloaded "${conn.config.name}" '
          '(${conn.tools.length} tools)');
      _emitToolsChanged();
    } on Object catch (e) {
      _log('warn', 'tool refresh failed for "${conn.config.name}": $e');
    }
  }

  void _watchClose(_ServerConnection conn) {
    final client = conn.client;
    if (client == null) {
      return;
    }
    unawaited(
      client.done.then((_) {
        if (_shuttingDown ||
            conn.lifecycle == McpServerLifecycle.disabled) {
          return;
        }
        // Unexpected drop while we believed we were connected → reconnect.
        unawaited(_handleUnexpectedClose(conn));
      }),
    );
  }

  Future<void> _handleUnexpectedClose(_ServerConnection conn) async {
    if (_tripBreaker(conn)) {
      conn
        ..lifecycle = McpServerLifecycle.circuitOpen
        ..lastError = 'circuit breaker open (too many reconnects)';
      await conn.teardown();
      _log('warn', 'circuit breaker tripped for "${conn.config.name}"');
      _emitToolsChanged();
      return;
    }
    _log('info', 'server "${conn.config.name}" dropped — reconnecting');
    await conn.teardown();
    for (var attempt = 0; attempt < reconnectBackoff.length; attempt++) {
      if (_shuttingDown) {
        return;
      }
      await Future<void>.delayed(reconnectBackoff[attempt]);
      await connect(conn.config);
      if (conn.lifecycle == McpServerLifecycle.connected) {
        return;
      }
    }
  }

  /// Records a reconnect attempt and returns true if the breaker should open.
  /// Sliding window: drop timestamps older than [reconnectBurstWindow], append
  /// now, trip if the count exceeds [reconnectBurstLimit].
  bool _tripBreaker(_ServerConnection conn) {
    final now = DateTime.now();
    conn.reconnectHistory.removeWhere(
      (t) => now.difference(t) > reconnectBurstWindow,
    );
    conn.reconnectHistory.add(now);
    return conn.reconnectHistory.length > reconnectBurstLimit;
  }

  /// Reads a resource [uri] from [serverName]. Returns the raw
  /// `resources/read` result. Throws if the server is unknown/disconnected.
  Future<Map<String, dynamic>> readResource(String serverName, String uri) {
    final client = _connections[serverName]?.client;
    if (client == null) {
      throw McpTransportException('server "$serverName" is not connected');
    }
    return client.readResource(uri, timeout: _connections[serverName]!.config.timeout);
  }

  /// Gets a prompt [name] from [serverName] with [arguments]. Returns the raw
  /// `prompts/get` result. Throws if the server is unknown/disconnected.
  Future<Map<String, dynamic>> getPrompt(
    String serverName,
    String name, {
    Map<String, String> arguments = const {},
  }) {
    final client = _connections[serverName]?.client;
    if (client == null) {
      throw McpTransportException('server "$serverName" is not connected');
    }
    return client.getPrompt(
      name,
      arguments: arguments,
      timeout: _connections[serverName]!.config.timeout,
    );
  }

  Future<Map<String, dynamic>> _invoke(
    String serverName,
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final conn = _connections[serverName];
    if (conn == null) {
      throw McpTransportException('unknown server "$serverName"');
    }
    Future<Map<String, dynamic>> call() async {
      final client = conn.client;
      if (client == null) {
        throw McpTransportException('server "$serverName" is not connected');
      }
      return client.callTool(toolName, arguments, timeout: conn.config.timeout);
    }

    try {
      return await call();
    } on McpTransportException {
      // One reconnect-and-retry: the transport may have dropped between calls.
      await reconnect(serverName);
      return call();
    }
  }

  bool _looksLikeAuthError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('401') ||
        s.contains('unauthorized') ||
        s.contains('needs_auth') ||
        s.contains('www-authenticate');
  }

  void _emitToolsChanged() {
    if (_toolsChanged.isClosed) {
      return;
    }
    _toolsChanged.add(null);
    onToolsChanged?.call();
  }

  void _log(String level, String message, {Object? error}) {
    log?.call(level, message, error: error);
  }

  /// Closes every connection and the change stream. After this the manager is
  /// inert. Stdio child process trees are SIGTERM'd by each transport's close.
  Future<void> shutdown() async {
    _shuttingDown = true;
    final conns = _connections.values.toList();
    await Future.wait(conns.map((c) => c.teardown()));
    _connections.clear();
    if (!_toolsChanged.isClosed) {
      await _toolsChanged.close();
    }
  }
}

/// Mutable per-server connection record.
class _ServerConnection {
  _ServerConnection(this.config);

  McpServerConfig config;
  McpClient? client;
  McpServerLifecycle lifecycle = McpServerLifecycle.connecting;
  List<BridgedMcpTool> tools = const [];
  List<McpRemoteResource> resources = const [];
  List<McpRemotePrompt> prompts = const [];
  String? lastError;
  StreamSubscription<McpNotification>? notifSub;
  final List<DateTime> reconnectHistory = [];

  Future<void> teardown() async {
    await notifSub?.cancel();
    notifSub = null;
    final c = client;
    client = null;
    tools = const [];
    resources = const [];
    prompts = const [];
    if (c != null) {
      await c.close();
    }
  }
}
