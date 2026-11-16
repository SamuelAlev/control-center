import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_mcp_client/src/config/mcp_client_models.dart';
import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/connection_manager.dart';
import 'package:cc_mcp_client/src/discovery/config_discovery.dart';
import 'package:cc_mcp_client/src/oauth/oauth_provider.dart';
import 'package:cc_mcp_client/src/oauth/oauth_token_store.dart';
import 'package:cc_mcp_client/src/tool_list_cache.dart';
import 'package:cc_mcp_client/src/transport_factory.dart';
import 'package:cc_mcp_client/src/transports/http_transport.dart'
    show McpConnectionFactory;

/// Receives the bridged tools of every connected server, whenever the set
/// changes. The host points it at one layer of its tool registry.
typedef McpToolSink = void Function(List<McpTool> tools);

/// The host-facing facade for the MCP client subsystem.
///
/// Wires the [ConnectionManager] to a [McpToolSink] (bridged tools are pushed
/// whenever servers connect or hot-reload), drives multi-format config
/// discovery and owns OAuth authorization. One instance per set of servers
/// that share an audience: the server owner's personal servers, or one
/// workspace's configured servers. Every config it is handed is already scoped
/// by the caller.
class McpClientService {
  /// Creates an [McpClientService] that publishes to `publishTools`.
  ///
  /// [publicOnlyConnection] dials the http/sse servers marked
  /// [McpServerConfig.publicOnly]; without it they are refused.
  McpClientService({
    required this._publishTools,
    McpOAuthTokenStore? tokenStore,
    BrowserLauncher? launchBrowser,
    McpClientLogSink? log,
    NeedsAuthCallback? onNeedsAuth,
    String? toolCachePath,
    McpConnectionFactory? publicOnlyConnection,
  }) : _tokenStore = tokenStore ?? InMemoryOAuthTokenStore(),
       _launchBrowser = launchBrowser {
    final factory = DefaultMcpTransportFactory(
      tokenStore: _tokenStore,
      launchBrowser: launchBrowser,
      publicOnlyConnection: publicOnlyConnection,
    );
    _manager = ConnectionManager(
      transportFactory: factory.create,
      log: log,
      onNeedsAuth: onNeedsAuth,
      onToolsChanged: _syncRegistry,
      // With a path, a server that is slow to dial still contributes its
      // last-known tools while it connects; without one, the startup gate
      // still bounds how long a slow server can hold up the others.
      toolCache: toolCachePath == null
          ? null
          : FileMcpToolListCache(toolCachePath),
    );
  }

  final McpToolSink _publishTools;
  final McpOAuthTokenStore _tokenStore;
  final BrowserLauncher? _launchBrowser;
  late final ConnectionManager _manager;

  /// A status snapshot per known server.
  List<McpServerStatusSnapshot> get serverStatuses => _manager.statuses;

  /// Connects every server in [configs] (concurrent). Replaces the prior set.
  Future<void> start(List<McpServerConfig> configs) =>
      _manager.connectAll(configs);

  /// The MCP servers already configured for other tools (IDEs, agents) under
  /// [homeDir] (and [workspaceDir]). Reads only; [start] connects.
  Future<List<McpServerConfig>> discover({
    required String homeDir,
    String? workspaceDir,
  }) => McpConfigDiscovery(homeDir: homeDir, workspaceDir: workspaceDir)
      .discover();

  /// Runs the interactive OAuth authorization for the server named [name]
  /// (resolved from the known connections), then reconnects it. Throws a
  /// [StateError] if no such server is known.
  Future<void> authorizeByName(String name) {
    final config = _manager.configFor(name);
    if (config == null) {
      throw StateError('unknown MCP server "$name"');
    }
    return authorize(config);
  }

  /// Runs the interactive OAuth authorization for [config], then reconnects it.
  Future<void> authorize(McpServerConfig config) async {
    final launcher = _launchBrowser;
    if (launcher == null) {
      throw StateError('no browser launcher wired for OAuth');
    }
    final url = config.url;
    if (url == null) {
      throw StateError('cannot authorize a stdio server');
    }
    final provider = McpOAuthProvider(
      serverUrl: url,
      tokenStore: _tokenStore,
      launchBrowser: launcher,
      scopes: config.oauthScopes,
    );
    await provider.authorize();
    await _manager.reconnect(config.name, manual: true);
  }

  /// Reconnects [name]; a [manual] reconnect resets the circuit breaker.
  Future<void> reconnect(String name, {bool manual = false}) =>
      _manager.reconnect(name, manual: manual);

  /// Disconnects [name].
  Future<void> disconnect(String name) => _manager.disconnect(name);

  void _syncRegistry() => _publishTools(_manager.tools);

  /// Shuts down all connections (SIGTERMs stdio child trees) and publishes
  /// an empty tool set.
  Future<void> shutdown() async {
    await _manager.shutdown();
    _publishTools(const []);
  }
}
