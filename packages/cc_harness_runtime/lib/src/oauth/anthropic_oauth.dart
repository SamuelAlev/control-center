import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// The Anthropic (Claude Pro/Max) browser OAuth flow — authorization-code +
/// PKCE against `claude.ai`, exchanging at `api.anthropic.com`.
class AnthropicOAuth extends HarnessOAuthProvider {
  /// Creates an [AnthropicOAuth].
  AnthropicOAuth({ProviderHttp? http}) : _http = http ?? ProviderHttp();

  final ProviderHttp _http;

  /// Public Claude Code OAuth client id.
  static const String clientId = '9d1c250a-e61b-44d9-88ed-5944d1962f5e';
  static const String _authorizeUrl = 'https://claude.ai/oauth/authorize';
  static const String _tokenUrl = 'https://api.anthropic.com/v1/oauth/token';
  static const String _scopes =
      'org:create_api_key user:profile user:inference '
      'user:sessions:claude_code user:mcp_servers user:file_upload';

  @override
  String get providerId => 'anthropic';

  @override
  int get callbackPort => 54545;

  @override
  String get callbackPath => '/callback';

  @override
  String buildAuthUrl({required Pkce pkce, required String state}) {
    final params = {
      'code': 'true',
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': _scopes,
      'code_challenge': pkce.challenge,
      'code_challenge_method': 'S256',
      'state': state,
    };
    return Uri.parse(_authorizeUrl).replace(queryParameters: params).toString();
  }

  @override
  Future<ProviderCredential> exchange({
    required String code,
    required Pkce pkce,
  }) async {
    // The provider may hand back `code#state`; the code is the first segment.
    final parts = code.split('#');
    final authCode = parts.first;
    final state = parts.length > 1 ? parts[1] : null;
    final json = await _http.postJson(
      Uri.parse(_tokenUrl),
      headers: const {'anthropic-beta': 'oauth-2025-04-20'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': authCode,
        'code_verifier': pkce.verifier,
        'redirect_uri': redirectUri,
        'state': ?state,
      },
    );
    return _credentialFrom(json);
  }

  @override
  Future<ProviderCredential> refresh(ProviderCredential credential) async {
    final json = await _http.postJson(
      Uri.parse(_tokenUrl),
      headers: const {'anthropic-beta': 'oauth-2025-04-20'},
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'refresh_token': credential.refreshToken,
      },
    );
    return _credentialFrom(json, previous: credential);
  }

  ProviderCredential _credentialFrom(
    Map<String, dynamic> json, {
    ProviderCredential? previous,
  }) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final account = json['account'] as Map<String, dynamic>?;
    return ProviderCredential(
      providerId: providerId,
      method: HarnessAuthMethod.oauth,
      accessToken: json['access_token'] as String?,
      // A refresh response may omit the refresh token; keep the old one.
      refreshToken: json['refresh_token'] as String? ?? previous?.refreshToken,
      // 5-minute skew so we refresh before the token actually expires.
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn - 300)),
      email: account?['email_address'] as String? ?? previous?.email,
      accountId: account?['uuid'] as String? ?? previous?.accountId,
      accountLabel:
          account?['email_address'] as String? ??
          previous?.accountLabel ??
          'Claude account',
    );
  }
}
