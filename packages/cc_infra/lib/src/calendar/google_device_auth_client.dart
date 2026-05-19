import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/network_constants.dart';
import 'package:dio/dio.dart';

/// The OAuth tokens persisted for one connected server-side Google account.
///
/// The headless `cc_server` keeps these in its own file-backed store (keyed by
/// `accountId`), never on a client device — the whole point of the server-owned
/// flow is that the long-lived refresh token lives next to the database the sync
/// writes into, not on every paired phone/browser.
class GoogleServerCredentials {
  /// Creates [GoogleServerCredentials].
  const GoogleServerCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.accountEmail,
    required this.scope,
    required this.clientId,
    required this.clientSecret,
  });

  /// Reconstructs credentials from [toJson], or null when the access/refresh
  /// token pair that makes an account usable is missing.
  static GoogleServerCredentials? fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      return null;
    }
    return GoogleServerCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      accountEmail: json['accountEmail'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
    );
  }

  /// Short-lived OAuth access token (Bearer).
  final String accessToken;

  /// Long-lived refresh token used to mint new access tokens.
  final String refreshToken;

  /// When [accessToken] expires.
  final DateTime expiresAt;

  /// The connected Google account's email (from the id_token).
  final String accountEmail;

  /// The granted scope string.
  final String scope;

  /// The OAuth client id this account was connected with. Stored per account so
  /// the refresh — which the periodic sync drives — works without re-entering
  /// it (a workspace may connect different accounts under different clients).
  final String clientId;

  /// The OAuth client secret paired with [clientId] (confidential device-code
  /// client). Lives only in the server's credential store.
  final String clientSecret;

  /// Whether [accessToken] is expired (or within [skew] of expiring).
  bool isExpired({Duration skew = const Duration(minutes: 5)}) =>
      DateTime.now().isAfter(expiresAt.subtract(skew));

  /// Returns a copy with the access token + expiry replaced (refresh path).
  /// Google does not return a new refresh token on refresh, so it is reused.
  GoogleServerCredentials copyWithAccessToken({
    required String accessToken,
    required DateTime expiresAt,
  }) => GoogleServerCredentials(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    accountEmail: accountEmail,
    scope: scope,
    clientId: clientId,
    clientSecret: clientSecret,
  );

  /// The JSON form persisted as a single blob.
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
    'accountEmail': accountEmail,
    'scope': scope,
    'clientId': clientId,
    'clientSecret': clientSecret,
  };
}

/// The pending device-authorization a user must approve (RFC 8628 §3.2).
class GoogleDeviceCode {
  /// Creates a [GoogleDeviceCode].
  const GoogleDeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresAt,
    required this.interval,
  });

  /// Opaque code the server polls the token endpoint with.
  final String deviceCode;

  /// Short human code the user types at [verificationUrl].
  final String userCode;

  /// Where the user approves the request (e.g. `https://www.google.com/device`).
  final String verificationUrl;

  /// When the device code expires and polling must stop.
  final DateTime expiresAt;

  /// Minimum seconds between polls (Google may ask us to slow down).
  final Duration interval;
}

/// The status of a single device-token poll ([GoogleDeviceAuthClient.pollOnce]).
enum GoogleDevicePollStatus {
  /// The user has not yet approved — keep polling.
  pending,

  /// Google asked us to poll less frequently — back off, then keep polling.
  slowDown,

  /// The user denied the authorization request — stop.
  denied,

  /// The device code expired before approval — stop and restart the flow.
  expired,

  /// Approved: [GoogleDevicePollOutcome.credentials] is set.
  connected,
}

/// The outcome of [GoogleDeviceAuthClient.pollOnce].
class GoogleDevicePollOutcome {
  /// Creates a [GoogleDevicePollOutcome].
  const GoogleDevicePollOutcome(this.status, {this.credentials});

  /// The poll status.
  final GoogleDevicePollStatus status;

  /// The tokens, set iff [status] is [GoogleDevicePollStatus.connected].
  final GoogleServerCredentials? credentials;
}

/// Performs Google's OAuth 2.0 **device authorization grant** (RFC 8628) and
/// refreshes access tokens — the headless flow for the server, which has no
/// browser to catch a redirect.
///
/// The device-code client type ("TV & limited input devices") is a confidential
/// client: it carries a [clientSecret], which is safe here because it lives only
/// on the trusted server (unlike the iOS/PKCE client the desktop ships, which
/// must be public).
///
/// The token [Dio] is a *plain* [createDio] with none of the app's auth
/// interceptors, so a 401 during refresh can never re-enter the refresh logic.
class GoogleDeviceAuthClient {
  /// Creates a [GoogleDeviceAuthClient].
  GoogleDeviceAuthClient({
    required this.clientId,
    required this.clientSecret,
    Dio? dio,
  }) : _dio = dio ?? createDio();

  /// The device-code (limited-input) OAuth client id.
  final String clientId;

  /// The client secret for the confidential device-code client.
  final String clientSecret;

  final Dio _dio;

  /// Requests a device + user code for [scope] (RFC 8628 §3.1–3.2).
  Future<GoogleDeviceCode> requestDeviceCode({
    String scope = googleCalendarDeviceScope,
  }) async {
    if (clientId.isEmpty) {
      throw const GoogleOAuthException(
        'Google client id is not configured. Set CC_GOOGLE_OAUTH_CLIENT_ID.',
        kind: GoogleOAuthFailureKind.missingClientId,
      );
    }
    try {
      final response = await _dio.post<dynamic>(
        googleOAuthDeviceCodeEndpoint,
        data: {'client_id': clientId, 'scope': scope},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final body = _asMap(response.data);
      final deviceCode = body['device_code'] as String?;
      final userCode = body['user_code'] as String?;
      final verificationUrl =
          (body['verification_url'] ?? body['verification_uri']) as String?;
      if (deviceCode == null || userCode == null || verificationUrl == null) {
        throw const GoogleOAuthException(
          'Google did not return a usable device code.',
          kind: GoogleOAuthFailureKind.tokenExchangeFailed,
        );
      }
      final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 1800;
      final interval = (body['interval'] as num?)?.toInt() ?? 5;
      return GoogleDeviceCode(
        deviceCode: deviceCode,
        userCode: userCode,
        verificationUrl: verificationUrl,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        interval: Duration(seconds: interval),
      );
    } on DioException catch (e) {
      throw _mapDeviceError(e, 'request a device code');
    }
  }

  /// Polls the token endpoint **once** for [code] (RFC 8628 §3.4–3.5), mapping
  /// Google's `authorization_pending` / `slow_down` / `access_denied` /
  /// `expired_token` responses to a [GoogleDevicePollStatus]. Returns the
  /// credentials on success. The GUI connect path drives this one poll per
  /// client tick; it throws only on an unexpected transport error.
  Future<GoogleDevicePollOutcome> pollOnce(GoogleDeviceCode code) async {
    try {
      final response = await _dio.post<dynamic>(
        googleOAuthTokenEndpoint,
        data: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'device_code': code.deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return GoogleDevicePollOutcome(
        GoogleDevicePollStatus.connected,
        credentials: _tokenSetFrom(_asMap(response.data)),
      );
    } on DioException catch (e) {
      final error = (_asMap(e.response?.data)['error'] as String?) ?? '';
      switch (error) {
        case 'authorization_pending':
          return const GoogleDevicePollOutcome(GoogleDevicePollStatus.pending);
        case 'slow_down':
          return const GoogleDevicePollOutcome(GoogleDevicePollStatus.slowDown);
        case 'access_denied':
          return const GoogleDevicePollOutcome(GoogleDevicePollStatus.denied);
        case 'expired_token':
          return const GoogleDevicePollOutcome(GoogleDevicePollStatus.expired);
        default:
          throw _mapDeviceError(e, 'exchange the device code');
      }
    }
  }

  /// Polls until [code] is approved, denied, or expires — the blocking CLI path
  /// (the GUI uses [pollOnce] instead). Honours the device interval +
  /// `slow_down`; [onPending] fires each poll so a CLI can keep the user posted.
  Future<GoogleServerCredentials> pollForToken(
    GoogleDeviceCode code, {
    void Function()? onPending,
  }) async {
    var interval = code.interval;
    while (true) {
      if (DateTime.now().isAfter(code.expiresAt)) {
        throw const GoogleOAuthException(
          'Timed out waiting for the device authorization to be approved.',
          kind: GoogleOAuthFailureKind.timedOut,
        );
      }
      await Future<void>.delayed(interval);
      final outcome = await pollOnce(code);
      switch (outcome.status) {
        case GoogleDevicePollStatus.connected:
          return outcome.credentials!;
        case GoogleDevicePollStatus.pending:
          onPending?.call();
        case GoogleDevicePollStatus.slowDown:
          interval += const Duration(seconds: 5);
          onPending?.call();
        case GoogleDevicePollStatus.denied:
          throw const GoogleOAuthException(
            'The Google authorization request was denied.',
            kind: GoogleOAuthFailureKind.consentDenied,
          );
        case GoogleDevicePollStatus.expired:
          throw const GoogleOAuthException(
            'The device code expired before it was approved.',
            kind: GoogleOAuthFailureKind.timedOut,
          );
      }
    }
  }

  /// Exchanges [current]'s refresh token for a fresh access token. Returns the
  /// same credentials with the access token + expiry replaced.
  Future<GoogleServerCredentials> refresh(
    GoogleServerCredentials current,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        googleOAuthTokenEndpoint,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': current.refreshToken,
          'client_id': clientId,
          'client_secret': clientSecret,
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
      return current.copyWithAccessToken(
        accessToken: accessToken,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
    } on DioException catch (e) {
      final error = _asMap(e.response?.data)['error'] as String?;
      if (error == 'invalid_grant') {
        throw const GoogleOAuthException(
          'Google rejected the refresh token (invalid_grant). Reconnect the '
          'calendar account.',
          kind: GoogleOAuthFailureKind.invalidGrant,
        );
      }
      throw _mapDeviceError(e, 'refresh the Google access token');
    }
  }

  GoogleServerCredentials _tokenSetFrom(Map<String, dynamic> body) {
    final accessToken = body['access_token'] as String?;
    final refreshToken = body['refresh_token'] as String?;
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw const GoogleOAuthException(
        'Google did not return the expected tokens. Re-authorize with offline '
        'access enabled.',
        kind: GoogleOAuthFailureKind.tokenExchangeFailed,
      );
    }
    final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
    return GoogleServerCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      accountEmail: emailFromIdToken(body['id_token'] as String?) ?? '',
      scope: body['scope'] as String? ?? googleCalendarDeviceScope,
      clientId: clientId,
      clientSecret: clientSecret,
    );
  }

  GoogleOAuthException _mapDeviceError(DioException e, String action) {
    final body = _asMap(e.response?.data);
    final detail =
        (body['error_description'] ?? body['error']) as String? ??
        e.message ??
        'unknown error';
    CcInfraLog.warning('google_device_auth: failed to $action: $detail');
    return GoogleOAuthException(
      'Failed to $action: $detail',
      kind: GoogleOAuthFailureKind.tokenExchangeFailed,
    );
  }

  /// Decodes the `email` claim from a Google id_token JWT payload. The token is
  /// Google-issued over TLS during the exchange, so the signature is not
  /// re-verified here.
  static String? emailFromIdToken(String? idToken) {
    if (idToken == null) {
      return null;
    }
    final parts = idToken.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }
}
