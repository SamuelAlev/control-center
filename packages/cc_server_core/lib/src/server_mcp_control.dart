import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:path/path.dart' as p;

/// Runs and controls the headless server's MCP HTTP server, and adapts it to the
/// platform-neutral [McpServerControl] the RPC catalog exposes (`mcp.*` ops).
///
/// The MCP server is a single process-wide listener (NOT workspace data), so
/// this is a host-global singleton. It owns ONE [McpHttpServer] over the SAME
/// [McpToolDispatcher] the RPC server uses — one tool registry, two transports.
/// Config (port / enabled / token) is persisted to `mcp_config.json` under the
/// server's data dir so it survives restarts; `status()` reflects the live
/// server's `isRunning` rather than a cached flag.
///
/// Reconfiguring port or token while running rebinds the server (stop → apply →
/// start) so the change takes effect immediately, mirroring the desktop's
/// "restart to apply" semantics but doing the restart for the caller.
class ServerMcpControl implements McpServerControl {
  /// Creates a control bound to [dispatcher], persisting config under [dataDir].
  ServerMcpControl({
    required McpToolDispatcher dispatcher,
    required String dataDir,
  }) : _dispatcher = dispatcher,
       _file = File(p.join(dataDir, 'mcp_config.json'));

  final McpToolDispatcher _dispatcher;
  final File _file;

  McpConfig _config = const McpConfig(port: 9020, enabled: false);
  McpHttpServer? _server;
  bool _loaded = false;

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
          port: (json['port'] as num?)?.toInt() ?? 9020,
          token: json['token'] as String?,
          enabled: json['enabled'] as bool? ?? false,
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
        'port': _config.port,
        if (_config.token != null) 'token': _config.token,
        'enabled': _config.enabled,
      }),
    );
    await tmp.rename(_file.path);
  }

  /// Starts the server on boot when the persisted config has it enabled. Called
  /// once by the runtime; respects the same gate the desktop uses.
  Future<void> startIfEnabled() async {
    await _ensureLoaded();
    if (_config.enabled) {
      await start();
    }
  }

  McpHttpServer _build() {
    // The HTTP server only binds when `config.enabled` is true (see
    // McpHttpServer.start), so the instance carries an enabled-forced copy and
    // the persisted `enabled` flag governs whether we call start() at all.
    final running = McpConfig(
      port: _config.port,
      token: _config.token,
      enabled: true,
    );
    return McpHttpServer(config: running, dispatcher: _dispatcher);
  }

  @override
  Future<McpServerStatus> status() async {
    await _ensureLoaded();
    return McpServerStatus(
      running: _server?.isRunning ?? false,
      port: _config.port,
      enabled: _config.enabled,
      hasToken: _config.token != null && _config.token!.isNotEmpty,
    );
  }

  @override
  Future<void> start() async {
    await _ensureLoaded();
    if (_server?.isRunning ?? false) {
      return;
    }
    final server = _build();
    await server.start();
    _server = server;
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.stop();
    }
  }

  @override
  Future<void> setEnabled({required bool enabled}) async {
    await _ensureLoaded();
    _config = McpConfig(
      port: _config.port,
      token: _config.token,
      enabled: enabled,
    );
    await _persist();
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }

  @override
  Future<void> setPort(int port) async {
    await _ensureLoaded();
    final wasRunning = _server?.isRunning ?? false;
    if (wasRunning) {
      await stop();
    }
    _config = McpConfig(
      port: port,
      token: _config.token,
      enabled: _config.enabled,
    );
    await _persist();
    if (wasRunning) {
      await start();
    }
  }

  @override
  Future<void> setToken(String? token) async {
    await _ensureLoaded();
    final normalized = (token == null || token.isEmpty) ? null : token;
    final wasRunning = _server?.isRunning ?? false;
    if (wasRunning) {
      await stop();
    }
    _config = McpConfig(
      port: _config.port,
      token: normalized,
      enabled: _config.enabled,
    );
    await _persist();
    if (wasRunning) {
      await start();
    }
  }

  /// Ensures the loopback MCP HTTP server is bound so server-run agents can
  /// reach the `mcp__*` tool surface (incl. `submit_output`), regardless of the
  /// persisted `enabled` flag.
  ///
  /// The `enabled` flag governs auto-start on boot for EXTERNAL/web use (and
  /// what [status] reports as the user's preference). Internal agent dispatch
  /// needs the endpoint unconditionally, so this force-starts it. Idempotent
  /// (a no-op when already running); binds loopback-only, so this never exposes
  /// the server beyond this host. A bind failure propagates to the caller.
  Future<void> ensureRunningForDispatch() => start();

  /// Writes (and returns the path to) an MCP client config that points a
  /// server-spawned `claude` at this loopback MCP endpoint, then returns its
  /// path. Includes the configured bearer token as an `Authorization` header
  /// when one is set (EventSource/CLI both honour headers on the HTTP
  /// transport). Call after the server is running ([ensureRunningForDispatch]).
  Future<String> writeAgentMcpConfig(File target) async {
    await _ensureLoaded();
    final server = <String, dynamic>{
      'type': 'http',
      'url': 'http://127.0.0.1:${_config.port}/mcp',
      if (_config.token != null && _config.token!.isNotEmpty)
        'headers': {'Authorization': 'Bearer ${_config.token}'},
    };
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'mcpServers': {'control-center': server},
      }),
    );
    await tmp.rename(target.path);
    return target.path;
  }

  /// Stops the underlying server (called from `CcServer.shutdown()`).
  Future<void> dispose() => stop();
}
