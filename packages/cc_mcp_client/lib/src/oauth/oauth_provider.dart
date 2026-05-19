import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_mcp_client/src/oauth/oauth_callback_server.dart';
import 'package:cc_mcp_client/src/oauth/oauth_token_store.dart';
import 'package:cc_mcp_client/src/oauth/pkce.dart';
import 'package:cc_mcp_client/src/protocol.dart';

/// The discovered OAuth endpoints for an authorization server.
class OAuthServerMetadata {
  /// Creates an [OAuthServerMetadata].
  const OAuthServerMetadata({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.registrationEndpoint,
    this.scopesSupported = const [],
  });

  /// Parses an RFC 8414 / OpenID metadata document.
  factory OAuthServerMetadata.fromJson(Map<String, dynamic> json) =>
      OAuthServerMetadata(
        issuer: json['issuer'] as String? ?? '',
        authorizationEndpoint: json['authorization_endpoint'] as String? ?? '',
        tokenEndpoint: json['token_endpoint'] as String? ?? '',
        registrationEndpoint: json['registration_endpoint'] as String?,
        scopesSupported:
            (json['scopes_supported'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  /// The issuer identifier.
  final String issuer;

  /// The authorization endpoint (`/authorize`).
  final String authorizationEndpoint;

  /// The token endpoint (`/token`).
  final String tokenEndpoint;

  /// The dynamic-client-registration endpoint, when supported.
  final String? registrationEndpoint;

  /// Scopes the server advertises.
  final List<String> scopesSupported;

  /// True when both required endpoints were discovered.
  bool get isComplete =>
      authorizationEndpoint.isNotEmpty && tokenEndpoint.isNotEmpty;
}

/// Raised when any step of the OAuth flow fails.
class OAuthException implements Exception {
  /// Creates an [OAuthException].
  const OAuthException(this.message);

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'OAuthException: $message';
}

/// Opens [url] in the user's browser (the host wires this to url_launcher /
/// nativeapi). Returns once the launch is dispatched, not when it completes.
typedef BrowserLauncher = Future<void> Function(Uri url);

/// Implements the OAuth 2.1 + PKCE + dynamic-client-registration flow MCP
/// servers use to gate their endpoints (RFC 8414 metadata discovery, RFC 7591
/// dynamic registration, RFC 7636 PKCE, RFC 8707 resource indicators).
///
/// One provider serves one server origin. It performs the interactive
/// authorization once (launching the browser, capturing the loopback redirect)
/// and thereafter refreshes silently. Tokens are persisted via the injected
/// [McpOAuthTokenStore].
class McpOAuthProvider {
  /// Creates an [McpOAuthProvider].
  McpOAuthProvider({
    required this.serverUrl,
    required McpOAuthTokenStore tokenStore,
    required BrowserLauncher launchBrowser,
    this.scopes = const [],
    this.callbackPort = 33418,
    this.callbackPath = '/callback',
    HttpClient? httpClient,
  }) : _tokenStore = tokenStore,
       _launchBrowser = launchBrowser,
       _http = httpClient ?? HttpClient();

  /// The MCP server URL (its origin keys the stored token + scopes discovery).
  final String serverUrl;

  /// Requested scopes (may be overridden by discovery).
  final List<String> scopes;

  /// Loopback callback port.
  final int callbackPort;

  /// Loopback callback path.
  final String callbackPath;

  final McpOAuthTokenStore _tokenStore;
  final BrowserLauncher _launchBrowser;
  final HttpClient _http;

  String get _serverKey => _origin(serverUrl);

  /// Returns a valid bearer token, refreshing if needed, or null if no token is
  /// stored (the caller should then run [authorize]).
  Future<McpOAuthToken?> validToken() async {
    final token = await _tokenStore.read(_serverKey);
    if (token == null) {
      return null;
    }
    if (!token.isExpired()) {
      return token;
    }
    if (token.refreshToken == null || token.tokenUrl == null) {
      return null; // can't refresh; re-authorize
    }
    try {
      final refreshed = await _refresh(token);
      await _tokenStore.write(_serverKey, refreshed);
      return refreshed;
    } on Object {
      return null; // refresh failed; caller re-authorizes
    }
  }

  /// The `Authorization` header for the current token, or an empty map when no
  /// valid token exists. Suitable as a transport `AuthHeaderProvider`.
  Future<Map<String, String>> authHeaders() async {
    final token = await validToken();
    if (token == null) {
      return const {};
    }
    return {'Authorization': token.authorizationHeader};
  }

  /// Runs the full interactive authorization: discover endpoints, (dynamically)
  /// register a client, launch the browser, capture the code, exchange it, and
  /// persist the token. Throws [OAuthException] on failure.
  Future<McpOAuthToken> authorize() async {
    final metadata = await discoverMetadata();
    if (!metadata.isComplete) {
      throw const OAuthException('could not discover authorization endpoints');
    }

    final callback = OAuthCallbackServer(
      port: callbackPort,
      path: callbackPath,
    );
    await callback.start();
    try {
      final redirectUri = callback.redirectUri;
      final clientId = await _resolveClientId(metadata, redirectUri);
      final pkce = PkcePair.generate();

      final effectiveScopes = scopes.isNotEmpty
          ? scopes
          : metadata.scopesSupported;
      final authUrl = Uri.parse(metadata.authorizationEndpoint).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': clientId.clientId,
          'redirect_uri': redirectUri,
          'state': pkce.state,
          'code_challenge': pkce.codeChallenge,
          'code_challenge_method': pkce.codeChallengeMethod,
          if (effectiveScopes.isNotEmpty) 'scope': effectiveScopes.join(' '),
          'resource': _resourceIndicator(),
        },
      );

      await _launchBrowser(authUrl);
      final result = await callback.waitForCallback();
      if (result.error != null) {
        throw OAuthException('authorization denied: ${result.error}');
      }
      if (result.code == null || result.code!.isEmpty) {
        throw const OAuthException('no authorization code returned');
      }
      if (result.state != pkce.state) {
        throw const OAuthException('state mismatch (possible CSRF)');
      }

      final token = await _exchangeCode(
        metadata: metadata,
        code: result.code!,
        verifier: pkce.codeVerifier,
        redirectUri: redirectUri,
        clientId: clientId,
      );
      await _tokenStore.write(_serverKey, token);
      return token;
    } finally {
      await callback.close();
    }
  }

  /// Discovers the authorization server metadata for [serverUrl].
  ///
  /// Follows RFC 9728 protected-resource metadata first (to learn which
  /// authorization server guards the resource), then RFC 8414 / OpenID
  /// metadata, with the documented well-known fallbacks.
  Future<OAuthServerMetadata> discoverMetadata() async {
    final origin = _origin(serverUrl);

    // RFC 9728: protected-resource metadata → authorization_servers[].
    String authServerOrigin = origin;
    final prm = await _getJson(
      '$origin/.well-known/oauth-protected-resource',
    );
    if (prm != null) {
      final servers = prm['authorization_servers'];
      if (servers is List && servers.isNotEmpty) {
        authServerOrigin = _origin(servers.first.toString());
      }
    }

    for (final wellKnown in const [
      '/.well-known/oauth-authorization-server',
      '/.well-known/openid-configuration',
    ]) {
      final doc = await _getJson('$authServerOrigin$wellKnown');
      if (doc != null) {
        final meta = OAuthServerMetadata.fromJson(doc);
        if (meta.isComplete) {
          return meta;
        }
      }
    }

    // Last-resort default endpoints at the auth server origin.
    return OAuthServerMetadata(
      issuer: authServerOrigin,
      authorizationEndpoint: '$authServerOrigin/authorize',
      tokenEndpoint: '$authServerOrigin/token',
      registrationEndpoint: '$authServerOrigin/register',
    );
  }

  Future<_ClientCredentials> _resolveClientId(
    OAuthServerMetadata metadata,
    String redirectUri,
  ) async {
    // Reuse a previously-registered client when one is stored.
    final stored = await _tokenStore.read(_serverKey);
    if (stored?.clientId != null) {
      return _ClientCredentials(
        clientId: stored!.clientId!,
        clientSecret: stored.clientSecret,
      );
    }
    final registration = metadata.registrationEndpoint;
    if (registration == null || registration.isEmpty) {
      throw const OAuthException(
        'server requires a client_id but offers no dynamic registration',
      );
    }
    final body = {
      'client_name': McpProtocol.clientName,
      'redirect_uris': [redirectUri],
      'grant_types': ['authorization_code', 'refresh_token'],
      'response_types': ['code'],
      'token_endpoint_auth_method': 'none',
      'application_type': 'native',
      if (scopes.isNotEmpty) 'scope': scopes.join(' '),
    };
    final response = await _postJson(registration, jsonEncode(body), form: false);
    if (response == null) {
      throw const OAuthException('dynamic client registration failed');
    }
    final clientId = response['client_id'] as String?;
    if (clientId == null || clientId.isEmpty) {
      throw const OAuthException('registration response missing client_id');
    }
    return _ClientCredentials(
      clientId: clientId,
      clientSecret: response['client_secret'] as String?,
    );
  }

  Future<McpOAuthToken> _exchangeCode({
    required OAuthServerMetadata metadata,
    required String code,
    required String verifier,
    required String redirectUri,
    required _ClientCredentials clientId,
  }) async {
    final form = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId.clientId,
      'code_verifier': verifier,
      'resource': _resourceIndicator(),
      if (clientId.clientSecret != null) 'client_secret': clientId.clientSecret!,
    };
    final response = await _postJson(
      metadata.tokenEndpoint,
      _encodeForm(form),
      form: true,
    );
    if (response == null) {
      throw const OAuthException('token exchange failed');
    }
    return _tokenFromResponse(
      response,
      tokenUrl: metadata.tokenEndpoint,
      clientId: clientId,
      authServer: metadata.issuer,
    );
  }

  Future<McpOAuthToken> _refresh(McpOAuthToken token) async {
    final form = {
      'grant_type': 'refresh_token',
      'refresh_token': token.refreshToken!,
      if (token.clientId != null) 'client_id': token.clientId!,
      'resource': _resourceIndicator(),
      if (token.clientSecret != null) 'client_secret': token.clientSecret!,
    };
    final response = await _postJson(
      token.tokenUrl!,
      _encodeForm(form),
      form: true,
    );
    if (response == null) {
      throw const OAuthException('token refresh failed');
    }
    final accessToken = response['access_token'] as String?;
    if (accessToken == null) {
      throw const OAuthException('refresh response missing access_token');
    }
    final expiresIn = (response['expires_in'] as num?)?.toInt();
    return token.copyWith(
      accessToken: accessToken,
      refreshToken: response['refresh_token'] as String? ?? token.refreshToken,
      expiresAt: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : null,
      scope: response['scope'] as String?,
    );
  }

  McpOAuthToken _tokenFromResponse(
    Map<String, dynamic> response, {
    required String tokenUrl,
    required _ClientCredentials clientId,
    required String authServer,
  }) {
    final accessToken = response['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const OAuthException('token response missing access_token');
    }
    final expiresIn = (response['expires_in'] as num?)?.toInt();
    return McpOAuthToken(
      accessToken: accessToken,
      refreshToken: response['refresh_token'] as String?,
      expiresAt: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : null,
      tokenType: response['token_type'] as String? ?? 'Bearer',
      scope: response['scope'] as String?,
      tokenUrl: tokenUrl,
      clientId: clientId.clientId,
      clientSecret: clientId.clientSecret,
      authorizationServer: authServer,
    );
  }

  /// RFC 8707 resource indicator — the canonical server URL.
  String _resourceIndicator() => serverUrl;

  Future<Map<String, dynamic>?> _getJson(String url) async {
    try {
      final request = await _http.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode != 200) {
        await response.drain<void>();
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _postJson(
    String url,
    String body, {
    required bool form,
  }) async {
    try {
      final request = await _http.postUrl(Uri.parse(url));
      request.headers
        ..contentType = form
            ? ContentType(
                'application',
                'x-www-form-urlencoded',
                charset: 'utf-8',
              )
            : ContentType('application', 'json', charset: 'utf-8')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      request.add(utf8.encode(body));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        return null;
      }
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  static String _encodeForm(Map<String, String> form) => form.entries
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');

  static String _origin(String url) {
    final uri = Uri.parse(url);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  /// Closes the underlying HTTP client.
  void dispose() => _http.close(force: true);
}

class _ClientCredentials {
  const _ClientCredentials({required this.clientId, this.clientSecret});

  final String clientId;
  final String? clientSecret;
}
