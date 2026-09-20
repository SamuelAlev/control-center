import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/jwt_claims.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// The OpenAI (ChatGPT) browser OAuth flow — authorization-code + PKCE against
/// `auth.openai.com`, with a form-encoded token exchange and account identity
/// decoded from the JWT access token.
///
/// `CodexOAuth` is the same client with extra authorize params and a device
/// fallback; this class stays the metered OpenAI tile.
class OpenAiOAuth extends HarnessOAuthProvider {
  /// Creates an [OpenAiOAuth].
  ///
  /// [providerId] / [extraAuthorizeParams] / [fallbackAccountLabel] let the
  /// Codex subclass reuse the token endpoints without copying the exchange.
  OpenAiOAuth({
    ProviderHttp? http,
    this.providerId = 'openai',
    this.extraAuthorizeParams = const {},
    this.fallbackAccountLabel = 'OpenAI account',
  }) : _http = http ?? ProviderHttp.shared;

  final ProviderHttp _http;

  /// Public OpenAI (Codex CLI) OAuth client id.
  static const String clientId = 'app_EMoamEEZ73f0CkXaXp7hrann';

  /// Authorization endpoint.
  static const String authorizeUrl = 'https://auth.openai.com/oauth/authorize';

  /// Token endpoint (auth-code and refresh).
  static const String tokenUrl = 'https://auth.openai.com/oauth/token';

  /// Scopes requested by the Codex CLI public client.
  static const String scopes =
      'openid profile email offline_access '
      'api.connectors.read api.connectors.invoke';

  @override
  final String providerId;

  /// Extra authorize-query fields (Codex adds `codex_cli_simplified_flow`).
  final Map<String, String> extraAuthorizeParams;

  /// Account label when the JWT carries no email.
  final String fallbackAccountLabel;

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
      'scope': scopes,
      'code_challenge': pkce.challenge,
      'code_challenge_method': 'S256',
      'state': state,
      'id_token_add_organizations': 'true',
      ...extraAuthorizeParams,
    };
    return Uri.parse(authorizeUrl).replace(queryParameters: params).toString();
  }

  /// HTTP client used for token exchange (and by `CodexOAuth`'s device poll).
  ProviderHttp get http => _http;

  @override
  Future<ProviderCredential> exchange({
    required String code,
    required Pkce pkce,
  }) => exchangeCode(
    code: code,
    verifier: pkce.verifier,
    redirectUri: redirectUri,
  );

  /// Auth-code grant against [redirectUri]. The device flow uses a different
  /// registered URI than the loopback callback.
  Future<ProviderCredential> exchangeCode({
    required String code,
    required String verifier,
    required String redirectUri,
  }) async {
    final authCode = code.split('#').first;
    final json = await _http.postForm(
      Uri.parse(tokenUrl),
      fields: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': authCode,
        'code_verifier': verifier,
        'redirect_uri': redirectUri,
      },
    );
    return credentialFrom(json);
  }

  @override
  Future<ProviderCredential> refresh(ProviderCredential credential) async {
    final json = await _http.postForm(
      Uri.parse(tokenUrl),
      fields: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'refresh_token': credential.refreshToken ?? '',
      },
    );
    return credentialFrom(json, previous: credential);
  }

  /// Builds a stored credential from a token-endpoint JSON body.
  ProviderCredential credentialFrom(
    Map<String, dynamic> json, {
    ProviderCredential? previous,
  }) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final accessToken = json['access_token'] as String?;
    final idToken = json['id_token'] as String?;
    final claims = decodeJwtClaims(accessToken);
    final idClaims = decodeJwtClaims(idToken);
    final auth = claims['https://api.openai.com/auth'];
    final idAuth = idClaims['https://api.openai.com/auth'];
    final profile = claims['https://api.openai.com/profile'];
    final idProfile = idClaims['https://api.openai.com/profile'];
    final accountId =
        _claimString(auth, 'chatgpt_account_id') ??
        _claimString(idAuth, 'chatgpt_account_id');
    final email =
        _claimString(profile, 'email') ?? _claimString(idProfile, 'email');
    return ProviderCredential(
      providerId: providerId,
      method: HarnessAuthMethod.oauth,
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String? ?? previous?.refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn - 300)),
      email: email ?? previous?.email,
      accountId: accountId ?? previous?.accountId,
      accountLabel: email ?? previous?.accountLabel ?? fallbackAccountLabel,
    );
  }

  static String? _claimString(Object? map, String key) {
    if (map is! Map) {
      return null;
    }
    final value = map[key];
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
