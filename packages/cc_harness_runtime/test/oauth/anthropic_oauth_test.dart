import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/anthropic_oauth.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:test/test.dart';

/// A [ProviderHttp] that returns canned JSON for `postJson`.
class _FakeHttp extends ProviderHttp {
  _FakeHttp(this._postJsonResult);

  final Map<String, dynamic> _postJsonResult;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    lastUri = uri;
    lastHeaders = headers;
    lastBody = body;
    return Map<String, dynamic>.from(_postJsonResult);
  }
}

const _pkce = Pkce(verifier: 'v', challenge: 'c');

void main() {
  group('AnthropicOAuth', () {
    test('exposes fixed provider id and callback config', () {
      final oauth = AnthropicOAuth();
      expect(oauth.providerId, 'anthropic');
      expect(oauth.callbackPort, 54545);
      expect(oauth.callbackPath, '/callback');
      expect(oauth.redirectUri, 'http://localhost:54545/callback');
    });

    test('buildAuthUrl contains the required OAuth params', () {
      final oauth = AnthropicOAuth();
      final url = Uri.parse(oauth.buildAuthUrl(pkce: _pkce, state: 'st'));
      expect(url.scheme, 'https');
      expect(url.host, 'claude.ai');
      expect(url.path, '/oauth/authorize');
      expect(url.queryParameters['response_type'], 'code');
      expect(url.queryParameters['client_id'], AnthropicOAuth.clientId);
      expect(
        url.queryParameters['redirect_uri'],
        'http://localhost:54545/callback',
      );
      expect(url.queryParameters['code_challenge'], 'c');
      expect(url.queryParameters['code_challenge_method'], 'S256');
      expect(url.queryParameters['state'], 'st');
      expect(url.queryParameters['code'], 'true');
      expect(url.queryParameters['scope'], contains('user:inference'));
    });

    test(
      'exchange posts the auth-code grant and decodes the account shape',
      () async {
        final http = _FakeHttp({
          'access_token': 'at',
          'refresh_token': 'rt',
          'expires_in': 3600,
          'account': {'uuid': 'acct-1', 'email_address': 'u@example.com'},
        });
        final oauth = AnthropicOAuth(http: http);

        final cred = await oauth.exchange(code: 'c', pkce: _pkce);

        expect(
          http.lastUri.toString(),
          'https://api.anthropic.com/v1/oauth/token',
        );
        expect(http.lastHeaders!['anthropic-beta'], 'oauth-2025-04-20');
        expect(http.lastBody!['grant_type'], 'authorization_code');
        expect(http.lastBody!['client_id'], AnthropicOAuth.clientId);
        expect(http.lastBody!['code'], 'c');
        expect(http.lastBody!['code_verifier'], 'v');
        expect(
          http.lastBody!['redirect_uri'],
          'http://localhost:54545/callback',
        );

        expect(cred.providerId, 'anthropic');
        expect(cred.method, HarnessAuthMethod.oauth);
        expect(cred.accessToken, 'at');
        expect(cred.refreshToken, 'rt');
        expect(cred.email, 'u@example.com');
        expect(cred.accountId, 'acct-1');
        expect(cred.accountLabel, 'u@example.com');
      },
    );

    test('exchange splits code and state from code#state', () async {
      final http = _FakeHttp({
        'access_token': 'at',
        'refresh_token': 'rt',
        'expires_in': 3600,
      });
      final oauth = AnthropicOAuth(http: http);

      await oauth.exchange(code: 'authcode#returning-state', pkce: _pkce);

      expect(http.lastBody!['code'], 'authcode');
      expect(http.lastBody!['state'], 'returning-state');
    });

    test('exchange omits state when code has no #fragment', () async {
      final http = _FakeHttp({
        'access_token': 'at',
        'refresh_token': 'rt',
        'expires_in': 3600,
      });
      final oauth = AnthropicOAuth(http: http);

      await oauth.exchange(code: 'plain', pkce: _pkce);

      expect(http.lastBody!['code'], 'plain');
      expect(http.lastBody!.containsKey('state'), isFalse);
    });

    test('exchange uses default expires_in when missing', () async {
      final http = _FakeHttp({'access_token': 'at', 'refresh_token': 'rt'});
      final oauth = AnthropicOAuth(http: http);

      final cred = await oauth.exchange(code: 'c', pkce: _pkce);

      expect(cred.expiresAt, isNotNull);
    });

    test('exchange falls back when account absent', () async {
      final http = _FakeHttp({
        'access_token': 'at',
        'refresh_token': 'rt',
        'expires_in': 600,
      });
      final oauth = AnthropicOAuth(http: http);

      final cred = await oauth.exchange(code: 'c', pkce: _pkce);

      expect(cred.email, isNull);
      expect(cred.accountId, isNull);
      expect(cred.accountLabel, 'Claude account');
    });

    test('refresh posts the refresh-token grant', () async {
      final http = _FakeHttp({
        'access_token': 'new',
        'refresh_token': 'new-rt',
        'expires_in': 3600,
        'account': {'uuid': 'a2', 'email_address': 'fresh@example.com'},
      });
      final oauth = AnthropicOAuth(http: http);

      const previous = ProviderCredential(
        providerId: 'anthropic',
        method: HarnessAuthMethod.oauth,
        accessToken: 'old',
        refreshToken: 'old-rt',
        email: 'old@example.com',
      );

      final refreshed = await oauth.refresh(previous);

      expect(http.lastBody!['grant_type'], 'refresh_token');
      expect(http.lastBody!['refresh_token'], 'old-rt');
      expect(refreshed.accessToken, 'new');
      expect(refreshed.refreshToken, 'new-rt');
      // Account refreshed from response.
      expect(refreshed.email, 'fresh@example.com');
      expect(refreshed.accountId, 'a2');
    });

    test(
      'refresh preserves old refresh_token when response omits it',
      () async {
        final http = _FakeHttp({'access_token': 'new', 'expires_in': 600});
        final oauth = AnthropicOAuth(http: http);

        const previous = ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.oauth,
          accessToken: 'old',
          refreshToken: 'kept',
        );

        final refreshed = await oauth.refresh(previous);

        expect(refreshed.refreshToken, 'kept');
      },
    );

    test(
      'refresh preserves old email/accountLabel when response omits them',
      () async {
        final http = _FakeHttp({
          'access_token': 'new',
          'refresh_token': 'rt',
          'expires_in': 600,
        });
        final oauth = AnthropicOAuth(http: http);

        const previous = ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.oauth,
          accessToken: 'old',
          refreshToken: 'rt',
          email: 'kept@example.com',
          accountId: 'kept-acct',
          accountLabel: 'Kept label',
        );

        final refreshed = await oauth.refresh(previous);

        expect(refreshed.email, 'kept@example.com');
        expect(refreshed.accountId, 'kept-acct');
        expect(refreshed.accountLabel, 'Kept label');
      },
    );
  });
}
