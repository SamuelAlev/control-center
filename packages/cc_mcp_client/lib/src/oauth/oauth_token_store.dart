/// A persisted OAuth token bundle for one MCP server, plus the material needed
/// to refresh it without re-running the whole flow.
class McpOAuthToken {
  /// Creates an [McpOAuthToken].
  const McpOAuthToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
    this.scope,
    this.tokenUrl,
    this.clientId,
    this.clientSecret,
    this.clientBasicAuth = false,
    this.authorizationServer,
    this.redirectUri,
  });

  /// Reconstructs from a JSON map.
  factory McpOAuthToken.fromJson(Map<String, dynamic> json) => McpOAuthToken(
    accessToken: json['access_token'] as String? ?? '',
    refreshToken: json['refresh_token'] as String?,
    expiresAt: json['expires_at'] is num
        ? DateTime.fromMillisecondsSinceEpoch(
            (json['expires_at'] as num).toInt(),
          )
        : null,
    tokenType: json['token_type'] as String? ?? 'Bearer',
    scope: json['scope'] as String?,
    tokenUrl: json['token_url'] as String?,
    clientId: json['client_id'] as String?,
    clientSecret: json['client_secret'] as String?,
    clientBasicAuth: json['client_basic_auth'] as bool? ?? false,
    authorizationServer: json['authorization_server'] as String?,
    redirectUri: json['redirect_uri'] as String?,
  );

  /// The bearer access token.
  final String accessToken;

  /// The refresh token, when the server issued one.
  final String? refreshToken;

  /// Absolute expiry time, when known.
  final DateTime? expiresAt;

  /// Token type (almost always `Bearer`).
  final String tokenType;

  /// Granted scopes (space-delimited), when echoed by the server.
  final String? scope;

  /// The token endpoint, persisted so a refresh needs no re-discovery.
  final String? tokenUrl;

  /// The (possibly dynamically-registered) client id, persisted for refresh.
  final String? clientId;

  /// The client secret, when the server issued a confidential client.
  final String? clientSecret;

  /// Whether [clientSecret] is sent as HTTP Basic rather than in the form.
  final bool clientBasicAuth;

  /// The authorization server origin, persisted for same-origin resource
  /// filtering on refresh.
  final String? authorizationServer;

  /// The redirect URI [clientId] was registered with: the registration is
  /// reused only for the same one.
  final String? redirectUri;

  /// True when [expiresAt] is within [buffer] of now (or already past). A null
  /// expiry is treated as non-expiring.
  bool isExpired({Duration buffer = const Duration(minutes: 5)}) {
    final exp = expiresAt;
    if (exp == null) {
      return false;
    }
    return DateTime.now().add(buffer).isAfter(exp);
  }

  /// The `Authorization` header value for this token.
  String get authorizationHeader => '$tokenType $accessToken';

  /// Serialises to a JSON map.
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    if (refreshToken != null) 'refresh_token': refreshToken,
    if (expiresAt != null) 'expires_at': expiresAt!.millisecondsSinceEpoch,
    'token_type': tokenType,
    if (scope != null) 'scope': scope,
    if (tokenUrl != null) 'token_url': tokenUrl,
    if (clientId != null) 'client_id': clientId,
    if (clientSecret != null) 'client_secret': clientSecret,
    if (clientBasicAuth) 'client_basic_auth': true,
    if (authorizationServer != null)
      'authorization_server': authorizationServer,
    if (redirectUri != null) 'redirect_uri': redirectUri,
  };

  /// Returns a copy with the access/refresh material replaced (used after a
  /// refresh, which keeps the registration material).
  McpOAuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? scope,
  }) => McpOAuthToken(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    tokenType: tokenType,
    scope: scope ?? this.scope,
    tokenUrl: tokenUrl,
    clientId: clientId,
    clientSecret: clientSecret,
    clientBasicAuth: clientBasicAuth,
    authorizationServer: authorizationServer,
    redirectUri: redirectUri,
  );
}

/// Persists OAuth tokens per MCP server, keyed by the server origin/url.
///
/// Tokens are secrets: the host backs this with its secrets store, one store
/// per audience (a workspace's servers, one member's own), so a sign-in never
/// reaches another audience's connection to the same origin. This package only
/// ships [InMemoryOAuthTokenStore] for tests.
abstract interface class McpOAuthTokenStore {
  /// Reads the token for [serverKey], or null if none is stored.
  Future<McpOAuthToken?> read(String serverKey);

  /// Stores [token] for [serverKey].
  Future<void> write(String serverKey, McpOAuthToken token);

  /// Deletes any token for [serverKey].
  Future<void> delete(String serverKey);
}

/// A non-persistent token store (tests).
class InMemoryOAuthTokenStore implements McpOAuthTokenStore {
  final _tokens = <String, McpOAuthToken>{};

  @override
  Future<McpOAuthToken?> read(String serverKey) async => _tokens[serverKey];

  @override
  Future<void> write(String serverKey, McpOAuthToken token) async {
    _tokens[serverKey] = token;
  }

  @override
  Future<void> delete(String serverKey) async {
    _tokens.remove(serverKey);
  }
}
