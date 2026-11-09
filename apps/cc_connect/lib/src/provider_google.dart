import 'package:cc_connect/src/provider_support.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// A Google token answer.
final class GoogleTokens {
  /// Creates the answer.
  const GoogleTokens({
    required this.access,
    required this.expiresAt,
    required this.refresh,
    required this.scopes,
    required this.idClaims,
  });

  /// The access token.
  final String access;

  /// When it expires.
  final DateTime expiresAt;

  /// The refresh token (empty on a refresh that did not rotate it).
  final String refresh;

  /// The granted scopes as Google reported them.
  final List<String> scopes;

  /// The `id_token` claims, when present.
  final Map<String, Object?>? idClaims;
}

/// Google OAuth calls.
final class GoogleApi {
  /// Creates the client.
  GoogleApi(this._http, this._creds, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final UpstreamHttp _http;
  final GoogleCredentials _creds;
  final DateTime Function() _clock;

  static final Uri _tokenUrl = Uri.parse('https://oauth2.googleapis.com/token');
  static final Uri _revokeUrl = Uri.parse(
    'https://oauth2.googleapis.com/revoke',
  );

  Future<GoogleTokens> _token(Map<String, String> fields) => withDualSecret(
    _creds.clientSecret,
    (secret, _) async {
      final response = await sendUpstream(
        _http,
        UpstreamRequest.form(_tokenUrl, {
          'client_id': _creds.clientId,
          'client_secret': secret,
          ...fields,
        }),
      );
      final json = response.jsonObject;
      final error = json?['error'];
      if (!response.ok || error != null) {
        switch (error) {
          case 'invalid_client' || 'unauthorized_client':
            throw const InvalidClientCredentials();
          case 'invalid_grant':
            throw GrantRejected(logSlug([error, json?['error_description']]));
          default:
            throw const ConnectException(ConnectErrorCode.providerUnavailable);
        }
      }
      final access = json?['access_token'];
      final expiresIn = intField(json?['expires_in']);
      if (access is! String || access.isEmpty || expiresIn == null) {
        throw const ConnectException(ConnectErrorCode.providerUnavailable);
      }
      final refresh = json?['refresh_token'];
      final scope = json?['scope'];
      final idToken = json?['id_token'];
      return GoogleTokens(
        access: access,
        expiresAt: _clock().toUtc().add(Duration(seconds: expiresIn)),
        refresh: refresh is String ? refresh : '',
        scopes: splitScopes(scope is String ? scope : null),
        idClaims: jwtClaims(idToken is String ? idToken : null),
      );
    },
  );

  /// Exchanges an authorization code (claim).
  Future<GoogleTokens> exchangeCode({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    try {
      return await _token({
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      });
    } on GrantRejected catch (e) {
      throw ConnectException(ConnectErrorCode.accessDenied, reason: e.reason);
    }
  }

  /// Refreshes an access token.
  Future<GoogleTokens> refresh(String refreshToken) async {
    try {
      return await _token({
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      });
    } on GrantRejected {
      throw const ConnectException(ConnectErrorCode.needsSignIn);
    }
  }

  /// Revokes [token] (and with a refresh token, the whole grant). Best
  /// effort: a refused grant is refused whether or not this lands.
  Future<void> revoke(String token) async {
    try {
      await _http.send(UpstreamRequest.form(_revokeUrl, {'token': token}));
    } on UpstreamUnavailable {
      // Best effort.
    }
  }
}
