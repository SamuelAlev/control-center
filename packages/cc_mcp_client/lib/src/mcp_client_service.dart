import 'package:cc_domain/features/mcp/domain/ports/mcp_resource_prompt_ports.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp_client/src/bridged_resource_prompt.dart';
import 'package:cc_mcp_client/src/config/mcp_client_models.dart';
import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/connection_manager.dart';
import 'package:cc_mcp_client/src/discovery/config_discovery.dart';
import 'package:cc_mcp_client/src/oauth/oauth_provider.dart';
import 'package:cc_mcp_client/src/oauth/oauth_token_store.dart';
import 'package:cc_mcp_client/src/transport_factory.dart';

/// The host-facing facade for the MCP client subsystem.
///
/// Wires the [ConnectionManager] to a [McpToolRegistry] (bridged tools are
/// pushed into the registry's dynamic layer whenever servers connect or
/// hot-reload), drives multi-format config discovery, owns OAuth authorization,
/// and exposes the external servers' resources/prompts as CC MCP providers.
/// One service instance per workspace — every config it is handed is already
/// workspace-scoped by the caller.
class McpClientService {
  /// Creates an [McpClientService].
  McpClientService({
    required McpToolRegistry registry,
    McpOAuthTokenStore? tokenStore,
    BrowserLauncher? launchBrowser,
    McpClientLogSink? log,
    NeedsAuthCallback? onNeedsAuth,
  }) : _registry = registry,
       _tokenStore = tokenStore ?? InMemoryOAuthTokenStore(),
       _launchBrowser = launchBrowser {
    final factory = DefaultMcpTransportFactory(
      tokenStore: _tokenStore,
      launchBrowser: launchBrowser,
    );
    _manager = ConnectionManager(
      transportFactory: factory.create,
      log: log,
      onNeedsAuth: onNeedsAuth,
      onToolsChanged: _syncRegistry,
    );
    _resourceProvider = BridgedResourceProvider(_manager);
    _promptProvider = BridgedPromptProvider(_manager);
  }

  final McpToolRegistry _registry;
  final McpOAuthTokenStore _tokenStore;
  final BrowserLauncher? _launchBrowser;
  late final ConnectionManager _manager;
  late final BridgedResourceProvider _resourceProvider;
  late final BridgedPromptProvider _promptProvider;

  /// Bridges external servers' resources into CC's MCP server.
  McpResourceProvider get resourceProvider => _resourceProvider;

  /// Bridges external servers' prompts into CC's MCP server.
  McpPromptProvider get promptProvider => _promptProvider;

  /// A status snapshot per known server.
  List<McpServerStatusSnapshot> get serverStatuses => _manager.statuses;

  /// Connects every server in [configs] (concurrent). Replaces the prior set.
  Future<void> start(List<McpServerConfig> configs) =>
      _manager.connectAll(configs);

  /// Auto-discovers IDE/tool MCP configs under [homeDir] (and [workspaceDir])
  /// and connects them, returning the discovered configs.
  Future<List<McpServerConfig>> discoverAndStart({
    required String homeDir,
    String? workspaceDir,
  }) async {
    final discovery = McpConfigDiscovery(
      homeDir: homeDir,
      workspaceDir: workspaceDir,
    );
    final configs = await discovery.discover();
    await _manager.connectAll(configs);
    return configs;
  }

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

  void _syncRegistry() => _registry.setDynamicTools(_manager.tools);

  /// Shuts down all connections (SIGTERMs stdio child trees) and clears the
  /// registry's dynamic layer.
  Future<void> shutdown() async {
    await _manager.shutdown();
    _registry.setDynamicTools(const []);
  }
}
