import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart'
    show McpToolRegistry;
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_infra/cc_paths.dart' show writePrivateFile;
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

/// Host-global MCP surface ([McpServerControl] / `mcp.*`): one [McpRequestHandler] over the
/// same [McpToolDispatcher] as RPC, mounted on the main listener (`POST /mcp`, `GET /sse`).
///
/// Loopback companion on [loopbackPort] when the main listener is TLS (CLI can't trust 127.0.0.1)
/// or absent (tests). Config in `mcp_config.json`, written owner-only: the enabled flag and the
/// server's MCP token, minted at first start and never absent. On by default ([startIfEnabled]).
/// Only [setEnabled] persists the enabled flag — [start]/[stop] are session controls.
///
/// Two credentials reach the surface (see [McpRequestHandler]): an agent run's own secret, which
/// is the only thing dispatch hands an agent, and the token, which is the server owner's for their
/// own MCP clients.
class ServerMcpControl implements McpServerControl {
  /// Creates a control bound to [_dispatcher], persisting config under [dataDir].
  ///
  /// [_companionPort] overrides the companion listener's port — a test seam so
  /// suites never collide with a running instance on [loopbackPort].
  ServerMcpControl({
    required this._dispatcher,
    required String dataDir,
    this._companionPort = loopbackPort,
  }) : _file = File(p.join(dataDir, 'mcp_config.json'));

  /// The loopback port the companion listener binds when one is needed (TLS
  /// in-process, or no main listener). The historic MCP default, so configs
  /// written for the standalone-listener era keep working in those topologies.
  static const int loopbackPort = 9020;

  final McpToolDispatcher _dispatcher;
  final int _companionPort;
  final File _file;

  static final Random _random = Random.secure();

  bool _enabled = true;
  String _token = '';

  /// Serves `/agent/…` on every listener the MCP surface is mounted on. Set
  /// by the runtime before the surface starts; see [McpRequestHandler.agentRoutes].
  Future<void> Function(HttpRequest request)? agentRoutes;

  /// Proves a run's identity from its secret. Set with [agentRoutes]; see
  /// [McpRequestHandler.attestRun].
  McpCallScope? Function(String secret)? attestRun;

  /// The server's public host names; see [McpRequestHandler.publicHosts]. Set
  /// by the runtime before the surface starts.
  Iterable<String> Function()? publicHosts;
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

  /// Reads the config, minting and storing a token when none is stored (a
  /// first start, or a file that could not be read).
  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    if (_file.existsSync()) {
      try {
        final decoded = jsonDecode(await _file.readAsString());
        if (decoded is Map) {
          _enabled = decoded['enabled'] as bool? ?? true;
          final token = decoded['token'];
          _token = token is String ? token : '';
        }
      } on Object {
        // Unreadable: start over with a fresh token below.
      }
    }
    if (_token.isEmpty) {
      _token = _mintToken();
      await _persist();
    }
  }

  /// 32 random bytes, base64url without padding.
  static String _mintToken() => base64Url
      .encode([for (var i = 0; i < 32; i++) _random.nextInt(256)])
      .replaceAll('=', '');

  Future<void> _persist() async {
    await _file.parent.create(recursive: true);
    await writePrivateFile(
      _file.path,
      utf8.encode(jsonEncode({'token': _token, 'enabled': _enabled})),
    );
  }

  /// Starts the surface on boot unless the user explicitly turned it off.
  /// Called once by the runtime; respects the same gate the desktop uses.
  Future<void> startIfEnabled() async {
    await _ensureLoaded();
    if (_enabled) {
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
      enabled: _enabled,
    );
  }

  @override
  Future<String> token() async {
    await _ensureLoaded();
    return _token;
  }

  @override
  Future<String> rotateToken() async {
    await _ensureLoaded();
    _token = _mintToken();
    await _persist();
    // The handler reads its token per request — a rotation is live
    // immediately, no rebind.
    _handler?.updateToken(_token);
    return _token;
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
      token: _token,
      dispatcher: _dispatcher,
      agentRoutes: agentRoutes,
      attestRun: attestRun,
      publicHosts: publicHosts,
    );
    final main = _mainServer;
    // Bind the companion first so a bind failure (port in use) aborts before
    // any visible state change.
    McpHttpServer? companion;
    if (main == null || main.tlsInProcess) {
      companion = McpHttpServer(port: _companionPort, handler: handler);
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
    _enabled = enabled;
    await _persist();
    if (enabled) {
      await _startSurface();
    } else {
      await _stopSurface();
    }
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

  /// Where a server-spawned agent reaches this host over loopback — the same
  /// port [writeAgentMcpConfig] points it at. Starts the surface first, as
  /// dispatch does, because the agent run gateway rides it whether or not the
  /// operator enabled MCP for external clients.
  Future<Uri> agentLoopbackBase() async {
    await ensureRunningForDispatch();
    return Uri.parse('http://127.0.0.1:$_agentPort');
  }

  int get _agentPort => (_companion?.isRunning ?? false)
      ? _companionPort
      : (_mainServer?.boundPort ?? loopbackPort);

  /// Fans `notifications/tools/list_changed` out to connected SSE clients.
  /// The runtime wires this to [McpToolRegistry.onToolsChanged].
  void notifyToolsChanged() => _handler?.notifyToolsListChanged();

  /// Writes the MCP client config for a spawned agent CLI to [target] and
  /// returns its path, or deletes [target] and returns null when the run has
  /// no secret: a run without a gateway lease gets no MCP config rather than
  /// one that could not authenticate.
  Future<String?> writeAgentMcpConfig(
    File target, {
    required String? runToken,
  }) async {
    final servers = await agentMcpServersForDispatch(runToken: runToken);
    if (servers == null) {
      if (target.existsSync()) {
        target.deleteSync();
      }
      return null;
    }
    await target.parent.create(recursive: true);
    await writePrivateFile(
      target.path,
      utf8.encode(jsonEncode({'mcpServers': servers})),
    );
    return target.path;
  }

  /// [agentMcpServers] for a run about to start, with the server listening,
  /// or null when the run has no secret. Preferred over the file when the CLI
  /// can take it: the run's secret then reaches `claude` over stdin and never
  /// rests in a directory the agent can read.
  Future<Map<String, Object?>?> agentMcpServersForDispatch({
    required String? runToken,
  }) async {
    if (runToken == null || runToken.isEmpty) {
      return null;
    }
    await ensureRunningForDispatch();
    return agentMcpServers(runToken: runToken);
  }

  /// The server map an agent CLI connects with: the loopback endpoint and the
  /// run's own secret ([McpCallScope.runGrantHeader]), which proves the run
  /// and everything it may touch. No bearer token and no caller-written
  /// scope: the server derives workspace, agent, conversation and space from
  /// the secret. `X-CC-Toolset-Rev` only busts client tool-list caches when
  /// the catalogue changes.
  Map<String, Object?> agentMcpServers({required String runToken}) {
    final headers = <String, String>{
      McpCallScope.runGrantHeader: runToken,
      'X-CC-Toolset-Rev': _dispatcher.registry.toolsetRevision,
    };
    // Agents always dial loopback: the companion when one is bound (TLS
    // topology / no main listener), the main listener's port otherwise.
    final server = <String, dynamic>{
      'type': 'http',
      'url': 'http://127.0.0.1:$_agentPort/mcp',
      'headers': headers,
    };
    return {'control-center': server};
  }

  /// Stops the underlying surface (called from `CcServer.shutdown()`).
  /// Shutdown is not a user preference, so it leaves the persisted flag alone.
  Future<void> dispose() => _stopSurface();
}
