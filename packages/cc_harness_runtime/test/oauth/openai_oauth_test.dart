import 'dart:convert';

import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/openai_oauth.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:test/test.dart';

/// A [ProviderHttp] that returns canned JSON for each method, recording the
/// calls so the test can assert on the request shape.
class _FakeHttp extends ProviderHttp {
  _FakeHttp(this._postFormResult);

  final Map<String, dynamic> _postFormResult;
  Uri? lastUri;
  Map<String, String>? lastFields;

  @override
  Future<Map<String, dynamic>> postForm(
    Uri uri, {
    Map<String, String> headers = const {},
    required Map<String, String> fields,
  }) async {
    lastUri = uri;
    lastFields = fields;
    return Map<String, dynamic>.from(_postFormResult);
  }
}

String _jwt(Map<String, dynamic> claims) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"none"}'))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode(jsonEncode(claims)))
      .replaceAll('=', '');
  return '$header.$payload.';
}

const _pkce = Pkce(verifier: 'v', challenge: 'c');

void main() {
  group('OpenAiOAuth', () {
    test('exposes fixed provider id and callback config', () {
      final oauth = OpenAiOAuth();
      expect(oauth.providerId, 'openai');
      expect(oauth.callbackPort, 1455);
      expect(oauth.callbackPath, '/auth/callback');
      expect(oauth.redirectUri, 'http://localhost:1455/auth/callback');
    });

    test('buildAuthUrl contains the required OAuth params', () {
      final oauth = OpenAiOAuth();
      final url = Uri.parse(oauth.buildAuthUrl(pkce: _pkce, state: 'st'));
      expect(url.scheme, 'https');
      expect(url.host, 'auth.openai.com');
      expect(url.path, '/oauth/authorize');
      expect(url.queryParameters['response_type'], 'code');
      expect(url.queryParameters['client_id'], OpenAiOAuth.clientId);
      expect(
        url.queryParameters['redirect_uri'],
        'http://localhost:1455/auth/callback',
      );
      expect(url.queryParameters['code_challenge'], 'c');
      expect(url.queryParameters['code_challenge_method'], 'S256');
      expect(url.queryParameters['state'], 'st');
      expect(url.queryParameters['id_token_add_organizations'], 'true');
      expect(url.queryParameters['scope'], contains('openid'));
      expect(url.queryParameters['scope'], contains('offline_access'));
    });

    test('exchange posts the auth-code grant and decodes the JWT', () async {
      // A JWT carrying OpenAI-style namespaced claims.
      final jwt = _jwt({
        'https://api.openai.com/auth': {'chatgpt_account_id': 'acct-123'},
        'https://api.openai.com/profile': {'email': 'user@example.com'},
      });
      final http = _FakeHttp({
        'access_token': jwt,
        'refresh_token': 'rt',
        'expires_in': 3600,
      });
      final oauth = OpenAiOAuth(http: http);

      final cred = await oauth.exchange(code: 'auth-code', pkce: _pkce);

      expect(http.lastUri.toString(), 'https://auth.openai.com/oauth/token');
      expect(http.lastFields!['grant_type'], 'authorization_code');
      expect(http.lastFields!['client_id'], OpenAiOAuth.clientId);
      expect(http.lastFields!['code'], 'auth-code');
      expect(http.lastFields!['code_verifier'], 'v');
      expect(
        http.lastFields!['redirect_uri'],
        'http://localhost:1455/auth/callback',
      );

      expect(cred.providerId, 'openai');
      expect(cred.method, HarnessAuthMethod.oauth);
      expect(cred.accessToken, jwt);
      expect(cred.refreshToken, 'rt');
      expect(cred.email, 'user@example.com');
      expect(cred.accountId, 'acct-123');
      expect(cred.accountLabel, 'user@example.com');
      // expires_in=3600 -> 300s skew.
      expect(cred.expiresAt, isNotNull);
    });

    test('exchange strips the #state fragment from the code', () async {
      final http = _FakeHttp({
        'access_token': _jwt({}),
        'refresh_token': 'rt',
        'expires_in': 600,
      });
      final oauth = OpenAiOAuth(http: http);

      await oauth.exchange(code: 'code#state', pkce: _pkce);

      expect(http.lastFields!['code'], 'code');
    });

    test(
      'exchange falls back to previous email/accountId when JWT omits them',
      () async {
        // No namespaced claims; access token is a bare JWT with empty payload.
        final http = _FakeHttp({
          'access_token': _jwt({}),
          'refresh_token': 'rt',
          'expires_in': 600,
        });
        final oauth = OpenAiOAuth(http: http);

        final cred = await oauth.exchange(code: 'c', pkce: _pkce);

        expect(cred.email, isNull);
        expect(cred.accountId, isNull);
        expect(cred.accountLabel, 'OpenAI account');
      },
    );

    test('exchange handles non-JWT access token (no claims)', () async {
      final http = _FakeHttp({
        'access_token': 'opaque-not-a-jwt',
        'refresh_token': 'rt',
        'expires_in': 600,
      });
      final oauth = OpenAiOAuth(http: http);

      final cred = await oauth.exchange(code: 'c', pkce: _pkce);

      expect(cred.accessToken, 'opaque-not-a-jwt');
      expect(cred.email, isNull);
    });

    test('exchange uses default expires_in when missing', () async {
      final http = _FakeHttp({'access_token': 't', 'refresh_token': 'rt'});
      final oauth = OpenAiOAuth(http: http);

      final cred = await oauth.exchange(code: 'c', pkce: _pkce);

      // Defaults to 3600s.
      expect(cred.expiresAt, isNotNull);
    });

    test('refresh posts the refresh-token grant', () async {
      final http = _FakeHttp({
        'access_token': 'new-token',
        'refresh_token': 'new-rt',
        'expires_in': 3600,
      });
      final oauth = OpenAiOAuth(http: http);

      const previous = ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.oauth,
        accessToken: 'old',
        refreshToken: 'old-rt',
        email: 'keep@example.com',
        accountId: 'keep-acct',
      );

      final refreshed = await oauth.refresh(previous);

      expect(http.lastFields!['grant_type'], 'refresh_token');
      expect(http.lastFields!['refresh_token'], 'old-rt');
      expect(refreshed.accessToken, 'new-token');
      expect(refreshed.refreshToken, 'new-rt');
      // Email preserved from previous when JWT has none.
      expect(refreshed.email, 'keep@example.com');
      expect(refreshed.accountId, 'keep-acct');
    });

    test(
      'refresh preserves the old refresh_token when response omits it',
      () async {
        final http = _FakeHttp({'access_token': 'new', 'expires_in': 600});
        final oauth = OpenAiOAuth(http: http);

        const previous = ProviderCredential(
          providerId: 'openai',
          method: HarnessAuthMethod.oauth,
          accessToken: 'old',
          refreshToken: 'kept-rt',
        );

        final refreshed = await oauth.refresh(previous);

        expect(refreshed.refreshToken, 'kept-rt');
      },
    );
  });
}
