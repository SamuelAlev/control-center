import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/jwt_claims.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:path/path.dart' as p;

/// The Kimi Code OAuth flow — an RFC 8628 device authorization grant against
/// `auth.kimi.com`, using the public Kimi Code client id.
///
/// This is the only way into the Kimi Code plan: it issues no API key, so the
/// plan cannot be reached with a pasted secret the way the metered Moonshot
/// open platform can. The device grant (rather than a redirect) is what the
/// provider implements, and it is also what lets a headless or remote
/// `cc_server` be authorized from whatever machine the user's browser is on.
class KimiOAuth implements HarnessDeviceOAuthProvider {
  /// Creates a [KimiOAuth].
  ///
  /// [dataDir] is where the stable device id is persisted; when null (or
  /// unwritable) the id is per-process, which still authenticates but makes the
  /// server look like a new device on every restart.
  KimiOAuth({String? dataDir, ProviderHttp? http, String? oauthHost})
    : _dataDir = dataDir,
      _http = http ?? ProviderHttp(),
      _host =
          oauthHost ??
          Platform.environment['KIMI_CODE_OAUTH_HOST'] ??
          Platform.environment['KIMI_OAUTH_HOST'] ??
          defaultOAuthHost;

  final String? _dataDir;
  final ProviderHttp _http;
  final String _host;

  /// The public Kimi Code OAuth client id (the same one the Kimi CLI uses).
  /// A device-grant public client holds no secret — this is an identifier, not
  /// a credential.
  static const String clientId = '17e5f671-d194-4dfb-9706-5516cb48c098';

  /// Default OAuth host, overridable via `KIMI_CODE_OAUTH_HOST`.
  static const String defaultOAuthHost = 'https://auth.kimi.com';

  /// The API host a Kimi Code access token is valid against.
  static const String apiBaseUrl = 'https://api.kimi.com/coding/v1';

  /// The grant type of the device-code token exchange.
  static const String _deviceGrant =
      'urn:ietf:params:oauth:grant-type:device_code';

  /// Filename holding the stable device id under the data dir.
  static const String _deviceIdFile = 'kimi_device_id';

  /// Renew this far ahead of the real expiry. Kimi access tokens are short
  /// (~1h), so a run that starts just under the wire must not have the token
  /// die mid-stream.
  static const Duration _expirySkew = Duration(minutes: 5);

  @override
  String get providerId => 'kimi-code';

  /// The `X-Msh-*` identity headers Kimi expects on both its OAuth endpoints
  /// and its API, for the device [deviceId].
  ///
  /// Static and id-parameterised so the API path can rebuild the exact headers
  /// the login sent without reaching for the disk: Kimi binds the token to the
  /// device that requested it, and the id the credential was minted with is
  /// stored on the credential itself.
  static Map<String, String> headersFor(String deviceId) => {
    'User-Agent': 'ControlCenter/1.0',
    'X-Msh-Platform': 'kimi_cli',
    'X-Msh-Version': '1.0',
    'X-Msh-Device-Name': _ascii(Platform.localHostname, 'unknown'),
    'X-Msh-Device-Model': _ascii(_deviceModel(), 'unknown'),
    'X-Msh-Os-Version': _ascii(Platform.operatingSystemVersion, 'unknown'),
    'X-Msh-Device-Id': _ascii(deviceId, 'unknown'),
  };

  /// This flow's headers, using its persisted device id.
  Map<String, String> commonHeaders() => headersFor(deviceId());

  @override
  Future<HarnessDeviceAuthorization> authorize() async {
    final json = await _http.postForm(
      Uri.parse('$_host/api/oauth/device_authorization'),
      headers: commonHeaders(),
      fields: {'client_id': clientId},
    );
    final deviceCode = json['device_code'] as String?;
    final userCode = json['user_code'] as String?;
    final verificationUri = json['verification_uri'] as String?;
    if (deviceCode == null || userCode == null || verificationUri == null) {
      throw const HarnessDeviceAuthException(
        'Kimi device authorization response was missing required fields.',
      );
    }
    return HarnessDeviceAuthorization(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUri:
          json['verification_uri_complete'] as String? ?? verificationUri,
      interval: Duration(seconds: (json['interval'] as num?)?.toInt() ?? 5),
      expiresIn: Duration(
        seconds: (json['expires_in'] as num?)?.toInt() ?? 900,
      ),
    );
  }

  @override
  Future<ProviderCredential?> poll(String deviceCode) async {
    final Map<String, dynamic> json;
    try {
      json = await _http.postForm(
        Uri.parse('$_host/api/oauth/token'),
        headers: commonHeaders(),
        fields: {
          'client_id': clientId,
          'device_code': deviceCode,
          'grant_type': _deviceGrant,
        },
      );
    } on ProviderHttpException catch (e) {
      // The device grant reports "not yet" as a 4xx with an error code, so a
      // non-2xx is only fatal once we have read which code it is.
      return _handlePollError(_errorCode(e.body), e);
    }
    if (json['access_token'] == null) {
      return _handlePollError(json['error'] as String?, null);
    }
    return _credentialFrom(json);
  }

  /// Maps a device-grant error code to "keep polling" (null) or a throw.
  ProviderCredential? _handlePollError(String? code, Object? cause) {
    switch (code) {
      case 'authorization_pending':
        return null;
      case 'slow_down':
        throw const HarnessDeviceSlowDown();
      case 'access_denied':
        throw const HarnessDeviceAuthException('Kimi Code sign-in was denied.');
      case 'expired_token':
        throw const HarnessDeviceAuthException(
          'The Kimi Code sign-in code expired. Start the login again.',
        );
      default:
        throw HarnessDeviceAuthException(
          'Kimi Code sign-in failed: ${code ?? cause ?? 'unknown error'}',
        );
    }
  }

  @override
  Future<ProviderCredential> refresh(ProviderCredential credential) async {
    final json = await _http.postForm(
      Uri.parse('$_host/api/oauth/token'),
      headers: commonHeaders(),
      fields: {
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'refresh_token': credential.refreshToken ?? '',
      },
    );
    return _credentialFrom(json, previous: credential);
  }

  ProviderCredential _credentialFrom(
    Map<String, dynamic> json, {
    ProviderCredential? previous,
  }) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final accessToken = json['access_token'] as String?;
    // Kimi does not document an identity endpoint, but its access token is a
    // JWT — read the account off it when the claims are there, and fall back to
    // naming the plan when they are not. Never invent an identity.
    final claims = decodeJwtClaims(accessToken);
    final email = firstClaim(claims, [
      'email',
      'user_email',
      'preferred_username',
    ]);
    final name = firstClaim(claims, ['name', 'nickname', 'username']);
    return ProviderCredential(
      providerId: providerId,
      method: HarnessAuthMethod.oauth,
      accessToken: accessToken,
      // A refresh response may omit the refresh token, meaning "keep the one
      // you have"; dropping it would silently end the session at the next
      // expiry.
      refreshToken: json['refresh_token'] as String? ?? previous?.refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn) - _expirySkew),
      baseUrl: apiBaseUrl,
      // The device this token was issued to. Carried on the credential so API
      // calls can replay the same `X-Msh-Device-Id` the login used, and so a
      // second login from the same install replaces rather than duplicates.
      accountId: previous?.accountId ?? deviceId(),
      email: email ?? previous?.email,
      accountLabel: email ?? name ?? previous?.accountLabel ?? 'Kimi Code plan',
    );
  }

  /// The stable per-install device id, persisted under the data dir.
  ///
  /// Best-effort: an unreadable or unwritable data dir yields a per-process id
  /// rather than an error, because every API call carries this header and a
  /// broken disk must not take authentication down with it.
  String deviceId() {
    final cached = _cachedDeviceId;
    if (cached != null) {
      return cached;
    }
    final dir = _dataDir;
    if (dir != null) {
      final file = File(p.join(dir, _deviceIdFile));
      try {
        final existing = file.readAsStringSync().trim();
        if (existing.isNotEmpty) {
          return _cachedDeviceId = existing;
        }
      } on Object {
        // Missing or unreadable — mint a new one below.
      }
      final minted = _randomDeviceId();
      try {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('$minted\n');
      } on Object {
        // Not persistable — still usable for this process.
      }
      return _cachedDeviceId = minted;
    }
    return _cachedDeviceId = _randomDeviceId();
  }

  String? _cachedDeviceId;

  static String _randomDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _deviceModel() {
    final os = switch (Platform.operatingSystem) {
      'macos' => 'macOS',
      'windows' => 'Windows',
      'linux' => 'Linux',
      final other => other,
    };
    return '$os ${Platform.operatingSystemVersion}';
  }

  /// Header values must be printable ASCII — a hostname with an accent or an
  /// emoji would otherwise make every request fail at the transport layer.
  static String _ascii(String value, String fallback) {
    final cleaned = value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  static String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded['error'] as String?
          : null;
    } on Object {
      return null;
    }
  }
}
