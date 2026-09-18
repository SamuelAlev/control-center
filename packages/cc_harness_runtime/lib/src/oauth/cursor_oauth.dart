import 'dart:math';
import 'dart:typed_data';

import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/jwt_claims.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// Cursor's PKCE + poll login (no CLI). Opens `cursor.com/loginDeepControl`
/// and polls `api2.cursor.sh/auth/poll` until the browser session completes.
class CursorOAuth implements HarnessDeviceOAuthProvider {
  /// Creates a [CursorOAuth].
  CursorOAuth({ProviderHttp? http, String? apiBase})
    : _http = http ?? ProviderHttp.shared,
      _apiBase = apiBase ?? defaultApiBase;

  final ProviderHttp _http;
  final String _apiBase;

  /// Provider id this flow authenticates.
  static const String id = 'cursor';

  /// Browser login page.
  static const String loginUrl = 'https://cursor.com/loginDeepControl';

  /// Default AgentService / poll host.
  static const String defaultApiBase = 'https://api2.cursor.sh';

  /// Refresh endpoint.
  static const String refreshPath = '/auth/exchange_user_api_key';

  /// Poll endpoint.
  static const String pollPath = '/auth/poll';

  @override
  String get providerId => id;

  @override
  Future<HarnessDeviceAuthorization> authorize() async {
    final pkce = Pkce.generate();
    final uuid = _uuidV4();
    final params = {
      'challenge': pkce.challenge,
      'uuid': uuid,
      'mode': 'login',
      'redirectTarget': 'cli',
    };
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}='
              '${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return HarnessDeviceAuthorization(
      // Poll needs both the uuid and the PKCE verifier; the broker only
      // holds one secret, so they travel together. `|` is not in a uuid
      // and not in a base64url verifier.
      deviceCode: '$uuid|${pkce.verifier}',
      userCode: uuid.substring(0, 8),
      verificationUri: '$loginUrl?$query',
      interval: const Duration(seconds: 1),
      expiresIn: const Duration(minutes: 15),
    );
  }

  @override
  Future<ProviderCredential?> poll(String deviceCode) async {
    final split = deviceCode.split('|');
    if (split.length < 2) {
      throw const HarnessDeviceAuthException(
        'Cursor sign-in is missing its poll secret. Start the login again.',
      );
    }
    final uuid = split.first;
    final verifier = split.sublist(1).join('|');
    final uri = Uri.parse(
      '$_apiBase$pollPath',
    ).replace(queryParameters: {'uuid': uuid, 'verifier': verifier});
    try {
      final json = await _http.getJson(uri);
      return _credentialFrom(json);
    } on ProviderHttpException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw HarnessDeviceAuthException(
        'Cursor sign-in failed (HTTP ${e.statusCode}).',
      );
    }
  }

  @override
  Future<ProviderCredential> refresh(ProviderCredential credential) async {
    final token = credential.refreshToken ?? credential.accessToken ?? '';
    final json = await _http.postJson(
      Uri.parse('$_apiBase$refreshPath'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: const {},
    );
    return _credentialFrom(json, previous: credential);
  }

  ProviderCredential _credentialFrom(
    Map<String, dynamic> json, {
    ProviderCredential? previous,
  }) {
    final access =
        json['accessToken'] as String? ?? json['access_token'] as String?;
    if (access == null || access.isEmpty) {
      throw const HarnessDeviceAuthException(
        'Cursor sign-in did not return an access token.',
      );
    }
    final refresh =
        json['refreshToken'] as String? ??
        json['refresh_token'] as String? ??
        previous?.refreshToken;
    final claims = decodeJwtClaims(access);
    final email = firstClaim(claims, ['email', 'preferred_username']);
    final name = firstClaim(claims, ['name', 'nickname', 'username']);
    return ProviderCredential(
      providerId: providerId,
      method: HarnessAuthMethod.oauth,
      accessToken: access,
      refreshToken: refresh,
      expiresAt: _expiryFromJwt(access),
      baseUrl: _apiBase,
      accountId: firstClaim(claims, ['sub', 'user_id']) ?? previous?.accountId,
      email: email ?? previous?.email,
      accountLabel: email ?? name ?? previous?.accountLabel ?? 'Cursor',
    );
  }

  DateTime _expiryFromJwt(String accessToken) {
    final claims = decodeJwtClaims(accessToken);
    final exp = claims['exp'];
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      ).subtract(const Duration(minutes: 5));
    }
    return DateTime.now().toUtc().add(const Duration(hours: 1));
  }
}

String _uuidV4() {
  final rnd = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => rnd.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
      '${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-'
      '${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}
