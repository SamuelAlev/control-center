import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_mcp_client/src/config/mcp_client_models.dart';
import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/connection_manager.dart';
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
/// whenever servers connect or hot-reload) and hands out each server's OAuth
/// provider. One instance per set of servers that share an audience: one
/// workspace's configured servers, or one member's own in it. Every config
/// it is handed is already scoped by the caller, and so is its token store: a
/// sign-in stored for one audience is never sent on another's connection.
class McpClientService {
  /// Creates an [McpClientService] that publishes to `publishTools`.
  ///
  /// [publicOnlyConnection] dials the http/sse servers marked
  /// [McpServerConfig.publicOnly]; without it they are refused.
  McpClientService({
    required this._publishTools,
    McpOAuthTokenStore? tokenStore,
    McpClientLogSink? log,
    NeedsAuthCallback? onNeedsAuth,
    String? toolCachePath,
    McpConnectionFactory? publicOnlyConnection,
  }) : _factory = DefaultMcpTransportFactory(
         tokenStore: tokenStore ?? InMemoryOAuthTokenStore(),
         publicOnlyConnection: publicOnlyConnection,
       ) {
    _manager = ConnectionManager(
      transportFactory: _factory.create,
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
  final DefaultMcpTransportFactory _factory;
  late final ConnectionManager _manager;

  /// A status snapshot per known server.
  List<McpServerStatusSnapshot> get serverStatuses => _manager.statuses;

  /// Connects every server in [configs] (concurrent). Replaces the prior set.
  Future<void> start(List<McpServerConfig> configs) =>
      _manager.connectAll(configs);

  /// The OAuth provider of the server named [name], for the host to run a
  /// browser sign-in with and then [reconnect]. Null when no such remote
  /// server is known.
  McpOAuthProvider? oauthProviderFor(String name) {
    final config = _manager.configFor(name);
    return config == null ? null : _factory.oauthProviderFor(config);
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
