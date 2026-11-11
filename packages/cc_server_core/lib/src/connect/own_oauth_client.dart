part of 'sign_in_service.dart';

/// The outcome of a refresh the provider refused with [error] (an OAuth
/// error code): [RefreshRejected] for one in [oauthRefreshRejectedErrors],
/// otherwise [RefreshUnavailable].
RefreshOutcome refreshOutcomeOfError(String error) =>
    oauthRefreshRejectedErrors.contains(error)
    ? const RefreshRejected()
    : const RefreshUnavailable();

/// A token endpoint's answer: the JSON body, the HTTP status and the
/// provider's request id (empty when it sent none).
typedef _TokenAnswer = ({
  Map<String, Object?> body,
  int status,
  String requestId,
});

/// The own-app half of OAuth: the code exchange and the refresh, against a
/// provider's token endpoint with the operator's client credentials.
final class _OwnOAuthClient {
  _OwnOAuthClient(this._http, this._now);

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxResponseBytes = 256 * 1024;

  final HttpClient _http;
  final DateTime Function() _now;

  /// Exchanges an authorization [code] and confirms who it belongs to.
  /// Throws [_ExchangeRefused].
  Future<ProviderToken> exchange({
    required ConnectOAuthLane lane,
    required Uri tokenEndpoint,
    required String clientId,
    required String clientSecret,
    required String code,
    required Uri redirectUri,
    required String verifier,
    required List<String> expectedScopes,
    required SignInLaneBinding binding,
  }) async {
    final _TokenAnswer answer;
    try {
      answer = await _postToken(tokenEndpoint, {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri.toString(),
        'code_verifier': verifier,
        'client_id': clientId,
        if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
      });
    } on Object {
      throw const _ExchangeRefused(
        SignInFailure.providerUnavailable,
        'The provider could not be reached. Try again.',
        reason: 'unreachable',
      );
    }
    final decoded = answer.body;
    final error = _oauthError(decoded['error']);
    if (error != null) {
      // The message reaches the client: only an OAuth error code shaped like
      // one (RFC 6749 §5.2), never `error_description` or anything else the
      // provider wrote.
      throw _ExchangeRefused(
        SignInFailure.exchangeFailed,
        'The provider refused the sign-in ($error).',
        reason: 'provider_error:$error',
        requestId: answer.requestId,
      );
    }
    final token = _tokenFrom(decoded, appId: clientId);
    if (token == null) {
      throw _ExchangeRefused(
        SignInFailure.exchangeFailed,
        'The provider returned no token.',
        reason: 'no_token',
        requestId: answer.requestId,
      );
    }
    if (expectedScopes.isNotEmpty) {
      final raw = decoded['scope'];
      final granted = raw is List
          ? [for (final s in raw) '$s']
          : splitScopes(raw is String ? raw : null);
      if (!scopesExactlyMatch(granted, expectedScopes)) {
        throw _ExchangeRefused(
          SignInFailure.scopeMismatch,
          'The provider granted different access than Control Center asks '
          'for, so the sign-in was refused. Try again and approve the '
          'requested access as shown.',
          reason: 'scope_mismatch',
          requestId: answer.requestId,
        );
      }
    }
    _checkGitHubUserToken(lane, token);
    final who = await _confirmIdentity(binding, token.accessToken);
    return token.copyWith(accountId: who.id, accountLogin: who.login);
  }

  /// Renews [expired] at [tokenEndpoint] as [clientId].
  Future<RefreshOutcome> refresh(
    ConnectOAuthLane lane,
    ProviderToken expired, {
    required Uri tokenEndpoint,
    required String clientId,
    required String clientSecret,
  }) async {
    final _TokenAnswer answer;
    try {
      answer = await _postToken(tokenEndpoint, {
        'grant_type': 'refresh_token',
        'refresh_token': expired.refreshToken,
        'client_id': clientId,
        if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
      });
    } on Object catch (e) {
      forgeAudit(ForgeAuditEvent.grantRefreshUnavailable, {
        'lane': lane.wire,
        'path': 'own',
        'reason': e is TimeoutException ? 'timeout' : 'unreachable',
      });
      return const RefreshUnavailable();
    }
    final error = _oauthError(answer.body['error']);
    if (error != null) {
      final outcome = refreshOutcomeOfError(error);
      forgeAudit(
        outcome is RefreshRejected
            ? ForgeAuditEvent.grantRefreshRejected
            : ForgeAuditEvent.grantRefreshUnavailable,
        {
          'lane': lane.wire,
          'path': 'own',
          'reason': 'provider_error:$error',
          'upstream_status': answer.status,
          'request_id': answer.requestId,
        },
      );
      return outcome;
    }
    final fresh = _tokenFrom(answer.body, appId: clientId);
    if (fresh == null) {
      forgeAudit(ForgeAuditEvent.grantRefreshUnavailable, {
        'lane': lane.wire,
        'path': 'own',
        'reason': 'no_token',
        'upstream_status': answer.status,
        'request_id': answer.requestId,
      });
      return const RefreshUnavailable();
    }
    forgeAudit(ForgeAuditEvent.grantRefreshed, {
      'lane': lane.wire,
      'path': 'own',
    }, token: fresh.accessToken);
    return Refreshed(
      fresh.copyWith(
        refreshToken: fresh.refreshToken.isEmpty
            ? expired.refreshToken
            : fresh.refreshToken,
        refreshExpiresAt: fresh.refreshExpiresAt ?? expired.refreshExpiresAt,
        accountLogin: expired.accountLogin,
        accountId: expired.accountId,
      ),
    );
  }

  /// An OAuth error code shaped like one, `'other'` for any other value, or
  /// null when there is no error.
  static String? _oauthError(Object? error) {
    if (error == null) {
      return null;
    }
    return error is String && RegExp(r'^[a-z_]{1,64}$').hasMatch(error)
        ? error
        : 'other';
  }

  ProviderToken? _tokenFrom(Map<String, Object?> decoded, {String appId = ''}) {
    final access = decoded['access_token'];
    if (access is! String || access.isEmpty) {
      return null;
    }
    final expiresIn = decoded['expires_in'];
    final refreshExpiresIn = decoded['refresh_token_expires_in'];
    final refresh = decoded['refresh_token'];
    return ProviderToken(
      accessToken: access,
      refreshToken: refresh is String ? refresh : '',
      expiresAt: expiresIn is num
          ? _now().add(Duration(seconds: expiresIn.toInt()))
          : null,
      refreshExpiresAt: refreshExpiresIn is num
          ? _now().add(Duration(seconds: refreshExpiresIn.toInt()))
          : null,
      source: ForgeCredentialSource.oauth,
      appId: appId,
      issuedAt: _now(),
    );
  }

  Future<_TokenAnswer> _postToken(Uri url, Map<String, String> body) async {
    final request = await _http.postUrl(url);
    // A 307/308 would re-POST the code and the client secret elsewhere.
    request.followRedirects = false;
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(Uri(queryParameters: body).query);
    final response = await request.close().timeout(_timeout);
    final requestId = _requestIdOf(response.headers);
    final raw = await readBoundedText(
      response,
      maxBytes: _maxResponseBytes,
      timeout: _timeout,
    );
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
    if (decoded is Map<String, Object?> && response.statusCode < 500) {
      return (body: decoded, status: response.statusCode, requestId: requestId);
    }
    throw HttpException('HTTP ${response.statusCode}');
  }

  /// The provider's request id, for a support case: GitHub's, else the
  /// common `x-request-id`. Only an id-shaped value is kept.
  static String _requestIdOf(HttpHeaders headers) {
    for (final name in const ['x-github-request-id', 'x-request-id']) {
      final value = headers.value(name);
      if (value != null && RegExp(r'^[A-Za-z0-9:._-]{1,80}$').hasMatch(value)) {
        return value;
      }
    }
    return '';
  }
}

/// Refuses a GitHub user token that is not an expiring GitHub App user token
/// (`ghu_…` with an expiry): a non-expiring one would be a standing
/// credential nobody can rotate. Throws [_ExchangeRefused].
void _checkGitHubUserToken(ConnectOAuthLane lane, ProviderToken token) {
  if (lane != ConnectOAuthLane.github) {
    return;
  }
  if (!token.accessToken.startsWith('ghu_') || token.expiresAt == null) {
    throw const _ExchangeRefused(
      SignInFailure.exchangeFailed,
      'This GitHub App issues tokens that never expire. Turn on '
      '"Expire user authorization tokens" in the app settings.',
      reason: 'non_expiring_token',
    );
  }
}

/// Who [accessToken] belongs to, from the lane's provider. Throws
/// [_ExchangeRefused] when the provider cannot say.
Future<SignInIdentity> _confirmIdentity(
  SignInLaneBinding binding,
  String accessToken,
) async {
  final SignInIdentity who;
  try {
    who = await binding.identify(accessToken);
  } on Object {
    throw const _ExchangeRefused(
      SignInFailure.providerUnavailable,
      'The provider did not say who signed in. Try again.',
      reason: 'identify_failed',
    );
  }
  if (who.id.isEmpty) {
    throw const _ExchangeRefused(
      SignInFailure.exchangeFailed,
      'The provider did not say who signed in.',
      reason: 'no_identity',
    );
  }
  return who;
}

/// A sign-in the provider, Connect or this server refused, with a message
/// written by this server and a closed [reason] for the log.
final class _ExchangeRefused implements Exception {
  const _ExchangeRefused(
    this.code,
    this.message, {
    required this.reason,
    this.requestId = '',
  });

  final SignInFailure code;
  final String message;
  final String reason;
  final String requestId;
}
