/// The MCP OAuth 2.1 subsystem: PKCE, dynamic client registration, metadata
/// discovery and per-server token persistence + silent refresh. The browser
/// redirect is received by the host, not here.
library;

export 'oauth_provider.dart';
export 'oauth_token_store.dart';
export 'pkce.dart';
