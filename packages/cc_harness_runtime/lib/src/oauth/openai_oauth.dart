import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/jwt_claims.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// The OpenAI (ChatGPT) browser OAuth flow — authorization-code + PKCE against
/// `auth.openai.com`, with a form-encoded token exchange and account identity
/// decoded from the JWT access token.
class OpenAiOAuth extends HarnessOAuthProvider {
  /// Creates an [OpenAiOAuth].
  OpenAiOAuth({ProviderHttp? http}) : _http = http ?? ProviderHttp();

  final ProviderHttp _http;

  /// Public OpenAI (Codex) OAuth client id.
  static const String clientId = 'app_EMoamEEZ73f0CkXaXp7hrann';
  static const String _authorizeUrl = 'https://auth.openai.com/oauth/authorize';
  static const String _tokenUrl = 'https://auth.openai.com/oauth/token';
  static const String _scopes =
      'openid profile email offline_access '
      'api.connectors.read api.connectors.invoke';

  @override
  String get providerId => 'openai';

  @override
  int get callbackPort => 1455;

  @override
  String get callbackPath => '/auth/callback';

  @override
  String buildAuthUrl({required Pkce pkce, required String state}) {
    final params = {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': _scopes,
      'code_challenge': pkce.challenge,
      'code_challenge_method': 'S256',
      'state': state,
      'id_token_add_organizations': 'true',
    };
    return Uri.parse(_authorizeUrl).replace(queryParameters: params).toString();
  }

  @override
  Future<ProviderCredential> exchange({
    required String code,
    required Pkce pkce,
  }) async {
    final authCode = code.split('#').first;
    final json = await _http.postForm(
      Uri.parse(_tokenUrl),
      fields: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': authCode,
        'code_verifier': pkce.verifier,
        'redirect_uri': redirectUri,
      },
    );
    return _credentialFrom(json);
  }

  @override
  Future<ProviderCredential> refresh(ProviderCredential credential) async {
    final json = await _http.postForm(
      Uri.parse(_tokenUrl),
      fields: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
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
    final claims = decodeJwtClaims(accessToken);
    final auth = claims['https://api.openai.com/auth'];
    final profile = claims['https://api.openai.com/profile'];
    final accountId = auth is Map
        ? auth['chatgpt_account_id'] as String?
        : null;
    final email = profile is Map ? profile['email'] as String? : null;
    return ProviderCredential(
      providerId: providerId,
      method: HarnessAuthMethod.oauth,
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String? ?? previous?.refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn - 300)),
      email: email ?? previous?.email,
      accountId: accountId ?? previous?.accountId,
      accountLabel: email ?? previous?.accountLabel ?? 'OpenAI account',
    );
  }
}
