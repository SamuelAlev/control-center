import 'dart:convert';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// The full token set returned by a successful interactive authorization.
class GoogleTokenSet {
  /// Creates a [GoogleTokenSet].
  const GoogleTokenSet({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.accountEmail,
    required this.scope,
  });

  /// Short-lived Bearer access token.
  final String accessToken;

  /// Long-lived refresh token (only issued with `access_type=offline`).
  final String refreshToken;

  /// When [accessToken] expires.
  final DateTime expiresAt;

  /// Account email decoded from the id_token (empty if absent).
  final String accountEmail;

  /// The granted scope string.
  final String scope;
}

/// The access token minted by a refresh. Google does **not** return a new
/// refresh token on refresh, so callers reuse the stored one.
class GoogleRefreshedToken {
  /// Creates a [GoogleRefreshedToken].
  const GoogleRefreshedToken({
    required this.accessToken,
    required this.expiresAt,
    required this.scope,
  });

  /// The new short-lived Bearer access token.
  final String accessToken;

  /// When [accessToken] expires.
  final DateTime expiresAt;

  /// The granted scope string.
  final String scope;
}

/// Performs Google's OAuth 2.0 authorization-code flow for a **public iOS-type
/// installed-app client** via PKCE and a reversed-client-id custom-scheme
/// redirect, and refreshes access tokens.
///
/// There is **no client secret**: an iOS OAuth client is a genuinely public
/// client, so Google neither issues nor requires a secret on the token
/// endpoint. PKCE is what binds the authorization code to this client. This is
/// what lets the binary ship without embedding any secret. (The earlier
/// "Desktop app" client type used a loopback redirect but Google's token
/// endpoint rejects its code exchange without the embedded secret — hence the
/// switch.)
///
/// The redirect is the reversed-client-id scheme Google reserves for the iOS
/// client type — `com.googleusercontent.apps.<client>:/oauth2redirect` — which
/// the OS routes back to the app as a deep link. [authenticate] starts awaiting
/// that redirect (via the injected [_awaitRedirect]) *before* opening the
/// browser so none is missed, mirroring how the old loopback server bound its
/// port up front.
///
/// Pure / injectable: the browser launcher, the redirect waiter and the
/// token-call [Dio] are injectable so the flow is testable without a real
/// browser, OS deep link, or network. The token [Dio] is a *plain* [createDio]
/// instance with none of the app's auth interceptors, so a 401 during refresh
/// can never re-enter the refresh logic.
class GoogleOAuthService {
  /// Creates a [GoogleOAuthService].
  GoogleOAuthService({
    required this.clientId,
    required Future<Uri> Function(Duration timeout) awaitRedirect,
    Dio? tokenDio,
    Future<bool> Function(Uri url)? launcher,
    Random? random,
  })  : _awaitRedirect = awaitRedirect,
        _tokenDio = tokenDio ?? createDio(),
        _launch = launcher ??
            ((url) async => openExternalUrl(url.toString())),
        _random = random ?? Random.secure();

  /// The public (iOS-type) OAuth client id.
  final String clientId;

  /// Awaits the next inbound OAuth redirect deep link (with its `code`/`state`/
  /// `error` query params), or throws [GoogleOAuthException] of kind
  /// [GoogleOAuthFailureKind.timedOut] when none arrives within the timeout.
  /// Wired in production to the app-scoped redirect channel fed by the
  /// platform's deep-link handler.
  final Future<Uri> Function(Duration timeout) _awaitRedirect;

  final Dio _tokenDio;
  final Future<bool> Function(Uri url) _launch;
  final Random _random;

  /// The custom URL scheme Google reserves for this iOS client id, i.e.
  /// `com.googleusercontent.apps.<client>` where `<client>` is [clientId] with
  /// its `.apps.googleusercontent.com` suffix stripped. This scheme must also
  /// be registered with the OS (macOS `CFBundleURLSchemes`, Linux
  /// `x-scheme-handler`) so the redirect is routed back to the app.
  @visibleForTesting
  static String reversedClientIdScheme(String clientId) {
    const suffix = '.apps.googleusercontent.com';
    final base = clientId.endsWith(suffix)
        ? clientId.substring(0, clientId.length - suffix.length)
        : clientId;
    return 'com.googleusercontent.apps.$base';
  }

  /// The full OAuth redirect URI for [clientId]'s reversed-client-id scheme.
  @visibleForTesting
  static String redirectUriFor(String clientId) =>
      '${reversedClientIdScheme(clientId)}:/oauth2redirect';

  /// Runs the interactive consent flow and returns the resulting tokens.
  ///
  /// Throws [GoogleOAuthException] on missing client id, browser-launch
  /// failure, consent denial, state mismatch, timeout, or token-exchange
  /// failure.
  Future<GoogleTokenSet> authenticate({
    Duration timeout = const Duration(minutes: 3),
  }) async {
    if (clientId.isEmpty) {
      throw const GoogleOAuthException(
        'Google client id is not configured. Set GOOGLE_OAUTH_CLIENT_ID.',
        kind: GoogleOAuthFailureKind.missingClientId,
      );
    }

    final codeVerifier = generateCodeVerifier(_random);
    final codeChallenge = codeChallengeS256(codeVerifier);
    final state = _generateState(_random);
    final redirectUri = redirectUriFor(clientId);

    final authUrl = buildAuthUrl(
      redirectUri: redirectUri,
      codeChallenge: codeChallenge,
      state: state,
    );

    // Begin awaiting the redirect *before* launching the browser so a fast
    // callback can never race ahead of our listener (the loopback server bound
    // its port up front for the same reason).
    final redirectFuture = _awaitRedirect(timeout);

    final launched = await _launch(authUrl);
    if (!launched) {
      throw const GoogleOAuthException(
        'Could not open the browser for Google sign-in.',
        kind: GoogleOAuthFailureKind.userCancelled,
      );
    }

    final params = (await redirectFuture).queryParameters;

    if (params['state'] != state) {
      throw const GoogleOAuthException(
        'Google sign-in state did not match. Please try again.',
        kind: GoogleOAuthFailureKind.stateMismatch,
      );
    }
    final error = params['error'];
    if (error != null) {
      throw GoogleOAuthException(
        'Google sign-in was not completed: $error',
        kind: error == 'access_denied'
            ? GoogleOAuthFailureKind.consentDenied
            : GoogleOAuthFailureKind.userCancelled,
      );
    }
    final code = params['code'];
    if (code == null || code.isEmpty) {
      throw const GoogleOAuthException(
        'Google sign-in did not return an authorization code.',
        kind: GoogleOAuthFailureKind.tokenExchangeFailed,
      );
    }

    return _exchangeCode(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    );
  }

  /// Exchanges a refresh token for a fresh access token.
  Future<GoogleRefreshedToken> refresh(String refreshToken) async {
    if (clientId.isEmpty) {
      throw const GoogleOAuthException(
        'Google client id is not configured. Set GOOGLE_OAUTH_CLIENT_ID.',
        kind: GoogleOAuthFailureKind.missingClientId,
      );
    }
    try {
      final response = await _tokenDio.post<dynamic>(
        googleOAuthTokenEndpoint,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final body = _asMap(response.data);
      final accessToken = body['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw const GoogleOAuthException(
          'Google did not return a refreshed access token.',
          kind: GoogleOAuthFailureKind.tokenExchangeFailed,
        );
      }
      final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
      return GoogleRefreshedToken(
        accessToken: accessToken,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        scope: body['scope'] as String? ?? '',
      );
    } on DioException catch (e) {
      // Read Google's error body (it is *not* part of DioException.message) so
      // the real cause is visible in logs and so we can tell a terminal
      // `invalid_grant` (refresh token dead → re-consent required) apart from a
      // transient failure (network, 5xx, rate limit) the next sync recovers
      // from. Google returns `{ "error": ..., "error_description": ... }`.
      final body = _asMap(e.response?.data);
      final error = body['error'] as String?;
      final description = body['error_description'] as String?;
      final detail = description ?? error ?? e.message ?? 'unknown error';
      if (error == 'invalid_grant') {
        throw GoogleOAuthException(
          'Google rejected the refresh token (invalid_grant): $detail. '
          'Reconnect the calendar account.',
          kind: GoogleOAuthFailureKind.invalidGrant,
        );
      }
      throw GoogleOAuthException(
        'Failed to refresh the Google access token: $detail',
        kind: GoogleOAuthFailureKind.tokenExchangeFailed,
      );
    }
  }

  Future<GoogleTokenSet> _exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    try {
      final response = await _tokenDio.post<dynamic>(
        googleOAuthTokenEndpoint,
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'code_verifier': codeVerifier,
          'client_id': clientId,
          'redirect_uri': redirectUri,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final body = _asMap(response.data);
      final accessToken = body['access_token'] as String?;
      final refreshToken = body['refresh_token'] as String?;
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw const GoogleOAuthException(
          'Google did not return the expected tokens. Re-authorize with '
          'offline access enabled.',
          kind: GoogleOAuthFailureKind.tokenExchangeFailed,
        );
      }
      final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
      return GoogleTokenSet(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        accountEmail: emailFromIdToken(body['id_token'] as String?) ?? '',
        scope: body['scope'] as String? ?? googleCalendarOAuthScope,
      );
    } on DioException catch (e) {
      throw GoogleOAuthException(
        'Failed to exchange the Google authorization code: ${e.message}',
        kind: GoogleOAuthFailureKind.tokenExchangeFailed,
      );
    }
  }

  /// Builds the Google consent URL for the loopback flow.
  @visibleForTesting
  Uri buildAuthUrl({
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) {
    return Uri.parse(googleOAuthAuthEndpoint).replace(
      queryParameters: <String, String>{
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': googleCalendarOAuthScope,
        'access_type': 'offline',
        'prompt': 'consent',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      },
    );
  }

  /// Generates a high-entropy PKCE code verifier (RFC 7636).
  @visibleForTesting
  static String generateCodeVerifier([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = List<int>.generate(64, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Computes the S256 PKCE challenge: `BASE64URL(SHA256(ASCII(verifier)))`.
  @visibleForTesting
  static String codeChallengeS256(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Decodes the `email` claim from a Google id_token JWT payload. The token is
  /// Google-issued over TLS during the exchange, so we read it without
  /// verifying the signature.
  @visibleForTesting
  static String? emailFromIdToken(String? idToken) {
    if (idToken == null) {
      return null;
    }
    final parts = idToken.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  static String _generateState(Random random) {
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return const <String, dynamic>{};
  }
}
