import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:cc_mcp_client/src/oauth/oauth_provider.dart';
import 'package:cc_mcp_client/src/oauth/oauth_token_store.dart';
import 'package:cc_mcp_client/src/transports/http_transport.dart';
import 'package:cc_mcp_client/src/transports/mcp_transport.dart';
import 'package:cc_mcp_client/src/transports/stdio_transport.dart';

/// Builds the right [McpTransport] for an [McpServerConfig], wiring OAuth auth
/// headers for `http`/`sse` servers configured with [McpAuthKind.oauth].
///
/// Injected into the `ConnectionManager` so it stays transport-agnostic. The
/// default factory covers all three transports; tests can substitute a fake.
class DefaultMcpTransportFactory {
  /// Creates a [DefaultMcpTransportFactory].
  ///
  /// [tokenStore] and [launchBrowser] are required only to *refresh* tokens for
  /// OAuth servers at connect time; the interactive `authorize` flow is driven
  /// separately by the host (it needs a UI gesture). When absent, OAuth servers
  /// fall back to whatever static headers the config carries.
  DefaultMcpTransportFactory({this.tokenStore, this.launchBrowser});

  /// Token store used to read/refresh OAuth tokens for the auth header.
  final McpOAuthTokenStore? tokenStore;

  /// Browser launcher passed through to the OAuth provider (for refresh that
  /// needs re-auth — rare). May be null in headless contexts.
  final BrowserLauncher? launchBrowser;

  /// Builds a transport for [config], starting it is the caller's job.
  Future<McpTransport> create(McpServerConfig config) async {
    switch (config.transport) {
      case McpTransportKind.stdio:
        return StdioTransport(config);
      case McpTransportKind.http:
        return StreamableHttpTransport(
          config,
          authHeaderProvider: _authProviderFor(config),
        );
      case McpTransportKind.sse:
        return SseTransport(
          config,
          authHeaderProvider: _authProviderFor(config),
        );
    }
  }

  AuthHeaderProvider? _authProviderFor(McpServerConfig config) {
    if (config.auth != McpAuthKind.oauth) {
      return null;
    }
    final store = tokenStore;
    final launcher = launchBrowser;
    if (store == null || launcher == null) {
      return null;
    }
    final provider = McpOAuthProvider(
      serverUrl: config.url!,
      tokenStore: store,
      launchBrowser: launcher,
      scopes: config.oauthScopes,
    );
    return provider.authHeaders;
  }
}
