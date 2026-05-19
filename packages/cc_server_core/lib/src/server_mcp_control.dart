import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart'
    show McpToolRegistry;
import 'package:cc_mcp/cc_mcp.dart';
import 'package:path/path.dart' as p;

/// The main cc_server HTTP listener the MCP surface rides on (implemented by
/// `LocalRpcServer`). `ServerMcpControl` mounts its request handler here so
/// MCP shares the server's single port instead of binding one of its own.
abstract interface class McpHostServer {
  /// Whether the listener is bound and accepting connections.
  bool get isRunning;

  /// The port the listener is bound to.
  int get boundPort;

  /// Whether the listener terminates TLS in-process. When true, server-
  /// spawned agent CLIs cannot validate the host cert against 127.0.0.1, so
  /// the control keeps a plaintext loopback companion for dispatch.
  bool get tlsInProcess;

  /// Mounts (or clears, with null) the MCP request handler. Read per request
  /// by the listener, so mounting never rebinds the socket.
  set mcpHandler(McpRequestHandler? handler);
}

/// Runs and controls the headless server's MCP surface, and adapts it to the
/// platform-neutral [McpServerControl] the RPC catalog exposes (`mcp.*` ops).
///
/// The MCP surface is a single process-wide concern (NOT workspace data), so
/// this is a host-global singleton. It owns ONE [McpRequestHandler] over the
/// SAME [McpToolDispatcher] the RPC server uses — one tool registry, two
/// transports — and mounts it on the main cc_server listener (the single-port
/// topology: `POST /mcp` + `GET /sse` share the server port, default 9030).
///
/// Two cases still bind a loopback companion [McpHttpServer] on
/// [loopbackPort] (the historic MCP default):
///  * the main listener serves TLS in-process — local agent CLIs cannot
///    validate the host cert against 127.0.0.1, so dispatch keeps a plaintext
///    loopback endpoint;
///  * no main listener is attached (unit tests, minimal embeddings) — the
///    pre-unification standalone topology.
///
/// Config (enabled / token) is persisted to `mcp_config.json` under the
/// server's data dir so it survives restarts; a legacy `port` key from the
/// standalone-listener era is ignored on load. `status()` reflects the live
/// mount/listener state rather than a cached flag. Token changes apply to the
/// live handler directly — no restart, so the "restart to apply" semantics
/// are gone for good.
///
/// The surface is **on by default**: with no persisted preference (fresh
/// install) [startIfEnabled] mounts it, so an external client that points at
/// `/mcp` works without a settings trip. That widens nothing — a tokenless
/// surface is refused for off-host callers by the listener's fail-closed
/// guard, and loopback already got the surface unconditionally via
/// [ensureRunningForDispatch]. Turning it off is [setEnabled] (the settings
/// toggle), the ONLY thing that writes the flag: [start]/[stop] are session
/// controls, so neither they nor shutdown rewrite the user's choice.
class ServerMcpControl implements McpServerControl {
  /// Creates a control bound to [dispatcher], persisting config under [dataDir].
  ///
  /// [companionPort] overrides the companion listener's port — a test seam so
  /// suites never collide with a running instance on [loopbackPort].
  ServerMcpControl({
    required McpToolDispatcher dispatcher,
    required String dataDir,
    int companionPort = loopbackPort,
  }) : _dispatcher = dispatcher,
       _companionPort = companionPort,
       _file = File(p.join(dataDir, 'mcp_config.json'));

  /// The loopback port the companion listener binds when one is needed (TLS
  /// in-process, or no main listener). The historic MCP default, so configs
  /// written for the standalone-listener era keep working in those topologies.
  static const int loopbackPort = 9020;

  final McpToolDispatcher _dispatcher;
  final int _companionPort;
  final File _file;

  McpConfig _config = const McpConfig(enabled: true);
  McpRequestHandler? _handler;
  McpHttpServer? _companion;
  McpHostServer? _mainServer;
  bool _loaded = false;

  /// Wires the main cc_server listener the MCP surface mounts on. Called by
  /// the runtime once the listener exists (it is constructed after this
  /// control); never called in minimal embeddings, where [start] falls back
  /// to the standalone companion.
  void attachMainServer(McpHostServer server) {
    _mainServer = server;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    if (!_file.existsSync()) {
      return;
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map) {
        final json = decoded.cast<String, dynamic>();
        _config = McpConfig(
          token: json['token'] as String?,
          enabled: json['enabled'] as bool? ?? true,
        );
      }
    } on Object {
      // Corrupt config — fall back to defaults.
    }
  }

  Future<void> _persist() async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        if (_config.token != null) 'token': _config.token,
        'enabled': _config.enabled,
      }),
    );
    await tmp.rename(_file.path);
  }

  /// Starts the surface on boot unless the user explicitly turned it off.
  /// Called once by the runtime; respects the same gate the desktop uses.
  Future<void> startIfEnabled() async {
    await _ensureLoaded();
    if (_config.enabled) {
      await _startSurface();
    }
  }

  bool get _running =>
      _handler != null &&
      ((_mainServer?.isRunning ?? false) || (_companion?.isRunning ?? false));

  @override
  Future<McpServerStatus> status() async {
    await _ensureLoaded();
    return McpServerStatus(
      running: _running,
      // Where clients point their MCP client: the main listener's port. The
      // companion (TLS topology) is an internal dispatch detail.
      port: _mainServer?.boundPort ?? _companionPort,
      enabled: _config.enabled,
      hasToken: _config.token != null && _config.token!.isNotEmpty,
    );
  }

  @override
  Future<void> start() async {
    await _ensureLoaded();
    await _startSurface();
  }

  @override
  Future<void> stop() => _stopSurface();

  /// Mounts the surface. A no-op when already running.
  ///
  /// Neither this nor [_stopSurface] touches the persisted preference: the
  /// enable toggle owns that bit, so a session-level start/stop (or a dispatch
  /// force-start, or shutdown) never rewrites the user's choice under them.
  Future<void> _startSurface() async {
    if (_running) {
      return;
    }
    final handler = McpRequestHandler(
      config: McpConfig(token: _config.token, enabled: true),
      dispatcher: _dispatcher,
    );
    final main = _mainServer;
    // Bind the companion first so a bind failure (port in use) aborts before
    // any visible state change.
    McpHttpServer? companion;
    if (main == null || main.tlsInProcess) {
      companion = McpHttpServer(
        port: _companionPort,
        dispatcher: _dispatcher,
        handler: handler,
      );
      await companion.start();
    }
    main?.mcpHandler = handler;
    _handler = handler;
    _companion = companion;
  }

  /// Unmounts the surface.
  Future<void> _stopSurface() async {
    final main = _mainServer;
    if (main != null && _handler != null) {
      main.mcpHandler = null;
    }
    final companion = _companion;
    _companion = null;
    final handler = _handler;
    _handler = null;
    if (companion != null) {
      await companion.stop();
    }
    if (handler != null) {
      await handler.close();
    }
  }

  @override
  Future<void> setEnabled({required bool enabled}) async {
    await _ensureLoaded();
    _config = McpConfig(token: _config.token, enabled: enabled);
    await _persist();
    if (enabled) {
      await _startSurface();
    } else {
      await _stopSurface();
    }
  }

  @override
  Future<void> setToken(String? token) async {
    await _ensureLoaded();
    final normalized = (token == null || token.isEmpty) ? null : token;
    _config = McpConfig(token: normalized, enabled: _config.enabled);
    await _persist();
    // The handler reads its config per request — a token change is live
    // immediately, no rebind.
    _handler?.updateConfig(McpConfig(token: normalized, enabled: true));
  }

  /// Ensures the MCP surface is served so server-run agents can reach the
  /// `mcp__*` tool surface (incl. `submit_output`), regardless of the
  /// persisted `enabled` flag.
  ///
  /// The `enabled` flag governs auto-start on boot for EXTERNAL/web use (and
  /// what [status] reports as the user's preference). Internal agent dispatch
  /// needs the endpoint unconditionally, so this force-starts it. Idempotent
  /// (a no-op when already running). Agents reach it over loopback — on the
  /// main listener when it is plaintext, on the companion when the main
  /// listener terminates TLS in-process.
  Future<void> ensureRunningForDispatch() async {
    await _ensureLoaded();
    await _startSurface();
  }

  /// Fans `notifications/tools/list_changed` out to connected SSE clients.
  /// The runtime wires this to [McpToolRegistry.onToolsChanged].
  void notifyToolsChanged() => _handler?.notifyToolsListChanged();

  /// Writes (and returns the path to) an MCP client config that points a
  /// server-spawned agent CLI (`claude`, `pi`, ACP) at this loopback MCP
  /// endpoint. Call after the surface is running ([ensureRunningForDispatch]).
  ///
  /// The config carries three kinds of headers:
  /// * `Authorization` — the configured bearer token, when set.
  /// * `X-CC-Workspace-Id` / `X-CC-Agent-Id` / `X-CC-Conversation-Id` — the
  ///   dispatch identity scope. The request handler forces `workspace_id` and
  ///   fills empty `agent_id`/`conversation_id`/`channel_id` args from these,
  ///   so a dispatched agent can never name a foreign workspace and never has
  ///   to thread its own UUIDs.
  /// * `X-CC-Toolset-Rev` — the registry's catalogue fingerprint. Clients that
  ///   key their tool-list cache on a config hash (pi's mcp-adapter persists
  ///   tool lists for 7 days) see a new hash whenever the toolset changes,
  ///   which busts the stale cache that once hid new tools for a week.
  ///
  /// Alongside `<cwd>/.mcp.json` this also writes `<cwd>/.pi/mcp.json` with
  /// the same server entry plus `"lifecycle": "eager"`. pi merges the
  /// `.pi/mcp.json` project source last (per-server it wins over `.mcp.json`),
  /// so pi connects at session start and re-lists tools fresh instead of
  /// serving a disk cache; Claude reads only the `--mcp-config` file and never
  /// sees the pi-specific key.
  Future<String> writeAgentMcpConfig(
    File target, {
    String? workspaceId,
    String? agentId,
    String? conversationId,
  }) async {
    await _ensureLoaded();
    final headers = <String, String>{
      if (_config.token != null && _config.token!.isNotEmpty)
        'Authorization': 'Bearer ${_config.token}',
      if (workspaceId != null && workspaceId.isNotEmpty)
        'X-CC-Workspace-Id': workspaceId,
      if (agentId != null && agentId.isNotEmpty) 'X-CC-Agent-Id': agentId,
      if (conversationId != null && conversationId.isNotEmpty)
        'X-CC-Conversation-Id': conversationId,
      'X-CC-Toolset-Rev': _dispatcher.registry.toolsetRevision,
    };
    // Agents always dial loopback: the companion when one is bound (TLS
    // topology / no main listener), the main listener's port otherwise.
    final port = (_companion?.isRunning ?? false)
        ? _companionPort
        : (_mainServer?.boundPort ?? loopbackPort);
    final server = <String, dynamic>{
      'type': 'http',
      'url': 'http://127.0.0.1:$port/mcp',
      'headers': headers,
    };
    await _writeJson(target, {
      'mcpServers': {'control-center': server},
    });
    await _writeJson(File(p.join(target.parent.path, '.pi', 'mcp.json')), {
      'mcpServers': {
        'control-center': {...server, 'lifecycle': 'eager'},
      },
    });
    return target.path;
  }

  Future<void> _writeJson(File target, Map<String, dynamic> json) async {
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(jsonEncode(json));
    await tmp.rename(target.path);
  }

  /// Stops the underlying surface (called from `CcServer.shutdown()`).
  /// Shutdown is not a user preference, so it leaves the persisted flag alone.
  Future<void> dispose() => _stopSurface();
}
