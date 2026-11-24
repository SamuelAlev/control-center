import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/oauth/oauth_provider.dart';
import 'package:cc_mcp_client/src/oauth/oauth_token_store.dart';
import 'package:cc_mcp_client/src/transports/http_transport.dart';
import 'package:cc_mcp_client/src/transports/mcp_transport.dart';
import 'package:cc_mcp_client/src/transports/stdio_transport.dart';

/// Builds the right [McpTransport] for an [McpServerConfig], wiring the stored
/// OAuth sign-in of an `http`/`sse` server into its requests.
///
/// Injected into the `ConnectionManager` so it stays transport-agnostic. The
/// default factory covers all three transports; tests can substitute a fake.
class DefaultMcpTransportFactory {
  /// Creates a [DefaultMcpTransportFactory].
  ///
  /// [tokenStore] holds the sign-ins of this factory's audience; the browser
  /// sign-in itself is driven by the host ([oauthProviderFor]). Without a
  /// store, a server gets only the static headers its config carries.
  DefaultMcpTransportFactory({this.tokenStore, this.publicOnlyConnection});

  /// How an http/sse server marked [McpServerConfig.publicOnly] is dialled:
  /// resolved once, refused unless every address is public, and connected to
  /// exactly that address. Null refuses such servers outright.
  final McpConnectionFactory? publicOnlyConnection;

  /// Token store used to read/refresh OAuth tokens for the auth header.
  final McpOAuthTokenStore? tokenStore;

  /// Builds a transport for [config], starting it is the caller's job.
  Future<McpTransport> create(McpServerConfig config) async {
    switch (config.transport) {
      case McpTransportKind.stdio:
        return StdioTransport(config);
      case McpTransportKind.http:
        return StreamableHttpTransport(
          config,
          authHeaderProvider: _authProviderFor(config),
          publicOnlyConnection: publicOnlyConnection,
        );
      case McpTransportKind.sse:
        return SseTransport(
          config,
          authHeaderProvider: _authProviderFor(config),
          publicOnlyConnection: publicOnlyConnection,
        );
    }
  }

  /// The OAuth provider of [config], reaching the authorization server
  /// under the same address rule as the server itself; null for a server
  /// with no URL or a factory with no token store.
  McpOAuthProvider? oauthProviderFor(McpServerConfig config) {
    final store = tokenStore;
    final url = config.url;
    if (store == null ||
        url == null ||
        config.transport == McpTransportKind.stdio) {
      return null;
    }
    return McpOAuthProvider(
      serverUrl: url,
      tokenStore: store,
      scopes: config.oauthScopes,
      httpClient: confinedMcpHttpClient(config, publicOnlyConnection),
    );
  }

  /// A stored sign-in is offered to every remote server that sets no
  /// `Authorization` header of its own; with none stored it adds nothing.
  AuthHeaderProvider? _authProviderFor(McpServerConfig config) {
    if (config.headers.keys.any((h) => h.toLowerCase() == 'authorization')) {
      return null;
    }
    final provider = oauthProviderFor(config);
    return provider?.authHeaders;
  }
}
