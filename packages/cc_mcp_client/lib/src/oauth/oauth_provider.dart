import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    this.tokenAuthMethods = const [],
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
        tokenAuthMethods:
            (json['token_endpoint_auth_methods_supported'] as List?)
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

  /// How a client may authenticate at the token endpoint; empty when the
  /// server does not say.
  final List<String> tokenAuthMethods;

  /// Whether a client with no secret (a public client) is accepted.
  bool get acceptsPublicClient =>
      tokenAuthMethods.isEmpty || tokenAuthMethods.contains('none');

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

/// A browser sign-in that has been started and not yet finished: what
/// [McpOAuthProvider.complete] needs once the provider hands back a code.
/// Held in memory by whoever began it; never sent to a client.
class McpOAuthPending {
  McpOAuthPending._({
    required this.authorizationUrl,
    required this.redirectUri,
    required this._verifier,
    required this._metadata,
    required this._client,
  });

  /// Where to send the browser.
  final Uri authorizationUrl;

  /// The redirect URI the request named, reused verbatim for the exchange.
  final String redirectUri;

  final String _verifier;
  final OAuthServerMetadata _metadata;
  final _ClientCredentials _client;
}

/// Implements the OAuth 2.1 + PKCE + dynamic-client-registration flow MCP
/// servers use to gate their endpoints (RFC 8414 metadata discovery, RFC 7591
/// dynamic registration, RFC 7636 PKCE, RFC 8707 resource indicators).
///
/// One provider serves one server origin. It opens no browser and listens on
/// no port: [begin] returns the URL to send a browser to, the host receives
/// the redirect wherever it told the provider it would ([McpOAuthPending
/// .redirectUri]), and [complete] exchanges the code. Thereafter
/// [validToken] refreshes silently. Tokens are persisted via the injected
/// [McpOAuthTokenStore].
class McpOAuthProvider {
  /// Creates an [McpOAuthProvider]. [httpClient] is how discovery,
  /// registration and the token endpoint are reached; a caller that may only
  /// reach public addresses passes a client confined to them.
  McpOAuthProvider({
    required this.serverUrl,
    required this._tokenStore,
    this.scopes = const [],
    HttpClient? httpClient,
  }) : _http = httpClient ?? HttpClient();

  /// How long any one request of the flow may take.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// The largest response body read from an authorization server.
  static const int maxResponseBytes = 256 * 1024;

  /// The MCP server URL (its origin keys the stored token + scopes discovery).
  final String serverUrl;

  /// Requested scopes (may be overridden by discovery).
  final List<String> scopes;

  final McpOAuthTokenStore _tokenStore;
  final HttpClient _http;

  String get _serverKey => oauthServerKey(serverUrl);

  /// The token store key of the server at [serverUrl]: its origin.
  static String oauthServerKey(String serverUrl) => _origin(serverUrl);

  /// Returns a valid bearer token, refreshing if needed, or null if no token is
  /// stored (the caller should then run [begin]).
  Future<McpOAuthToken?> validToken() async {
    final token = await _tokenStore.read(_serverKey);
    if (token == null || token.accessToken.isEmpty) {
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

  /// Starts a browser sign-in: discovers the endpoints, registers a client
  /// for [redirectUri] when none is known for it, and builds the
  /// authorization URL carrying [state]. Nothing is stored. Throws
  /// [OAuthException] on failure.
  Future<McpOAuthPending> begin({
    required String redirectUri,
    required String state,
  }) async {
    final metadata = await discoverMetadata();
    if (!metadata.isComplete) {
      throw const OAuthException('could not discover authorization endpoints');
    }
    final client = await _resolveClientId(metadata, redirectUri);
    final pkce = PkcePair.generate();
    final effectiveScopes = scopes.isNotEmpty
        ? scopes
        : metadata.scopesSupported;
    final endpoint = Uri.parse(metadata.authorizationEndpoint);
    return McpOAuthPending._(
      authorizationUrl: endpoint.replace(
        queryParameters: {
          ...endpoint.queryParameters,
          'response_type': 'code',
          'client_id': client.clientId,
          'redirect_uri': redirectUri,
          'state': state,
          'code_challenge': pkce.codeChallenge,
          'code_challenge_method': pkce.codeChallengeMethod,
          if (effectiveScopes.isNotEmpty) 'scope': effectiveScopes.join(' '),
          'resource': _resourceIndicator(),
        },
      ),
      redirectUri: redirectUri,
      verifier: pkce.codeVerifier,
      metadata: metadata,
      client: client,
    );
  }

  /// Finishes [pending] with the authorization [code] the provider returned:
  /// exchanges it and persists the token. Throws [OAuthException] on failure.
  Future<McpOAuthToken> complete(McpOAuthPending pending, String code) async {
    final token = await _exchangeCode(
      metadata: pending._metadata,
      code: code,
      verifier: pending._verifier,
      redirectUri: pending.redirectUri,
      clientId: pending._client,
    );
    await _tokenStore.write(_serverKey, token);
    return token;
  }

  /// Forgets the stored sign-in.
  Future<void> signOut() => _tokenStore.delete(_serverKey);

  /// Discovers the authorization server metadata for [serverUrl].
  ///
  /// Follows RFC 9728 protected-resource metadata first (to learn which
  /// authorization server guards the resource), then RFC 8414 / OpenID
  /// metadata, with the documented well-known fallbacks.
  Future<OAuthServerMetadata> discoverMetadata() async {
    final origin = _origin(serverUrl);
    final path = Uri.parse(serverUrl).path;

    // RFC 9728: protected-resource metadata → authorization_servers[]. The
    // path-suffixed document names this resource; the root one is the
    // fallback older servers publish.
    String authServer = origin;
    for (final url in [
      if (path.isNotEmpty && path != '/')
        '$origin/.well-known/oauth-protected-resource$path',
      '$origin/.well-known/oauth-protected-resource',
    ]) {
      final prm = await _getJson(url);
      final servers = prm?['authorization_servers'];
      if (servers is List && servers.isNotEmpty) {
        authServer = servers.first.toString();
        break;
      }
    }
    final authServerOrigin = _origin(authServer);
    final issuerPath = Uri.parse(authServer).path;
    final hasIssuerPath = issuerPath.isNotEmpty && issuerPath != '/';

    for (final url in [
      if (hasIssuerPath) ...[
        '$authServerOrigin/.well-known/oauth-authorization-server$issuerPath',
        '$authServerOrigin/.well-known/openid-configuration$issuerPath',
        '$authServerOrigin$issuerPath/.well-known/openid-configuration',
      ],
      '$authServerOrigin/.well-known/oauth-authorization-server',
      '$authServerOrigin/.well-known/openid-configuration',
    ]) {
      final doc = await _getJson(url);
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
    // Reuse a previously-registered client, but only for the redirect URI it
    // was registered with: a server that moved needs a new registration.
    final stored = await _tokenStore.read(_serverKey);
    if (stored?.clientId != null && stored!.redirectUri == redirectUri) {
      return _ClientCredentials(
        clientId: stored.clientId!,
        clientSecret: stored.clientSecret,
      );
    }
    final registration = metadata.registrationEndpoint;
    if (registration == null || registration.isEmpty) {
      throw const OAuthException(
        'server requires a client_id but offers no dynamic registration',
      );
    }
    final redirect = Uri.parse(redirectUri);
    final loopback =
        redirect.host == '127.0.0.1' ||
        redirect.host == '[::1]' ||
        redirect.host == '::1' ||
        redirect.host == 'localhost';
    final body = {
      'client_name': McpProtocol.clientName,
      'redirect_uris': [redirectUri],
      'grant_types': ['authorization_code', 'refresh_token'],
      'response_types': ['code'],
      'token_endpoint_auth_method': metadata.acceptsPublicClient
          ? 'none'
          : metadata.tokenAuthMethods.contains('client_secret_post')
          ? 'client_secret_post'
          : metadata.tokenAuthMethods.first,
      'application_type': loopback ? 'native' : 'web',
      if (scopes.isNotEmpty) 'scope': scopes.join(' '),
    };
    String? refusal;
    final response = await _postJson(
      registration,
      jsonEncode(body),
      form: false,
      onRefused: (status, text) => refusal = _refusalDetail(status, text),
    );
    if (response == null) {
      throw OAuthException(
        refusal == null
            ? 'dynamic client registration failed'
            : 'the server refused to register this client: $refusal',
      );
    }
    final clientId = response['client_id'] as String?;
    if (clientId == null || clientId.isEmpty) {
      throw const OAuthException('registration response missing client_id');
    }
    return _ClientCredentials(
      clientId: clientId,
      clientSecret: response['client_secret'] as String?,
      basicAuth:
          response['token_endpoint_auth_method'] == 'client_secret_basic',
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
      if (clientId.clientSecret != null && !clientId.basicAuth)
        'client_secret': clientId.clientSecret!,
    };
    final response = await _postJson(
      metadata.tokenEndpoint,
      _encodeForm(form),
      form: true,
      basic: clientId.basicAuth ? clientId : null,
    );
    if (response == null) {
      throw const OAuthException('token exchange failed');
    }
    return _tokenFromResponse(
      response,
      tokenUrl: metadata.tokenEndpoint,
      clientId: clientId,
      authServer: metadata.issuer,
      redirectUri: redirectUri,
    );
  }

  Future<McpOAuthToken> _refresh(McpOAuthToken token) async {
    final form = {
      'grant_type': 'refresh_token',
      'refresh_token': token.refreshToken!,
      if (token.clientId != null) 'client_id': token.clientId!,
      'resource': _resourceIndicator(),
      if (token.clientSecret != null && !token.clientBasicAuth)
        'client_secret': token.clientSecret!,
    };
    final response = await _postJson(
      token.tokenUrl!,
      _encodeForm(form),
      form: true,
      basic: token.clientBasicAuth && token.clientId != null
          ? _ClientCredentials(
              clientId: token.clientId!,
              clientSecret: token.clientSecret,
              basicAuth: true,
            )
          : null,
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
    required String redirectUri,
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
      clientBasicAuth: clientId.basicAuth,
      authorizationServer: authServer,
      redirectUri: redirectUri,
    );
  }

  /// RFC 8707 resource indicator — the canonical server URL.
  String _resourceIndicator() => serverUrl;

  Future<Map<String, dynamic>?> _getJson(String url) async {
    try {
      return await () async {
        final request = await _http.getUrl(Uri.parse(url));
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        if (response.statusCode != 200) {
          await response.drain<void>();
          return null;
        }
        final decoded = jsonDecode(await _boundedBody(response));
        return decoded is Map<String, dynamic> ? decoded : null;
      }().timeout(requestTimeout);
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _postJson(
    String url,
    String body, {
    required bool form,
    _ClientCredentials? basic,
    void Function(int status, String body)? onRefused,
  }) async {
    try {
      return await () async {
        final request = await _http.postUrl(Uri.parse(url));
        request.followRedirects = false;
        if (basic != null) {
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Basic ${base64.encode(utf8.encode('${Uri.encodeQueryComponent(basic.clientId)}:${Uri.encodeQueryComponent(basic.clientSecret ?? '')}'))}',
          );
        }
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
        final text = await _boundedBody(response);
        if (response.statusCode >= 400) {
          onRefused?.call(response.statusCode, text);
          return null;
        }
        final decoded = jsonDecode(text);
        return decoded is Map<String, dynamic> ? decoded : null;
      }().timeout(requestTimeout);
    } on Object {
      return null;
    }
  }

  /// What a refusing authorization server said, as plain bounded text: the
  /// status and its RFC 6749 `error_description` (or `error`). The server is
  /// untrusted, so only printable ASCII survives.
  static String _refusalDetail(int status, String body) {
    var said = '';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final raw = decoded['error_description'] ?? decoded['error'];
        if (raw is String) {
          said = raw;
        }
      }
    } on FormatException {
      // Not JSON: the status alone is reported.
    }
    said = said.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ').trim();
    if (said.length > 120) {
      said = '${said.substring(0, 120)}...';
    }
    return said.isEmpty ? 'HTTP $status' : 'HTTP $status, $said';
  }

  static Future<String> _boundedBody(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > maxResponseBytes) {
        throw const OAuthException('response too large');
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
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
  const _ClientCredentials({
    required this.clientId,
    this.clientSecret,
    this.basicAuth = false,
  });

  final String clientId;
  final String? clientSecret;

  /// Whether the secret goes in an `Authorization: Basic` header rather than
  /// the form.
  final bool basicAuth;
}
