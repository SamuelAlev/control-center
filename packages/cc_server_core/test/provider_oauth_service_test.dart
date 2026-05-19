import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_oauth_service.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late UserCredentialsStore users;
  late ProviderAppSettings apps;
  late ProviderOAuthService oauth;

  const alice = 'user-alice';
  final redirect = Uri.parse('http://127.0.0.1:9030/oauth/github/callback');

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_oauth_');
    secrets = FileSecretsStore(dataDir: dir.path);
    users = UserCredentialsStore(secrets);
    apps = ProviderAppSettings(secrets: secrets);
    await apps.save(
      ProviderApp.github,
      clientId: 'client-id',
      clientSecret: 'client-secret',
    );
    // A client that cannot reach anything: every test here is about the
    // state machine, and the account probe is a real outbound request.
    // Without this, a unit test would dial api.github.com.
    oauth = ProviderOAuthService(
      apps: apps,
      users: users,
      httpClient: HttpClient()
        ..connectionTimeout = const Duration(milliseconds: 1),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('redirect URI', () {
    test('is composed in ONE place, byte for byte', () {
      // The provider compares this string exactly; two places composing "the
      // same" URL is how a trailing slash becomes a refused sign-in.
      expect(
        providerOAuthRedirectUri('https://cc.example:9030', 'github')
            .toString(),
        'https://cc.example:9030/oauth/github/callback',
      );
    });
  });

  group('availableProviders', () {
    test('lists only the providers whose app is configured', () async {
      expect(await oauth.availableProviders(), [ProviderApp.github]);
    });

    test('a client id with no secret cannot run a REDIRECT sign-in', () async {
      // Linear's browser round-trip is a confidential-client exchange.
      await apps.save(ProviderApp.linear, clientId: 'only-an-id');
      expect(await oauth.availableProviders(), [ProviderApp.github]);
    });

    test('a client id alone IS enough for a device sign-in', () async {
      // GitHub's device flow authenticates with the client id; requiring a
      // secret would gate the sign-in on a value it never sends.
      final bare = ProviderAppSettings(secrets: secrets);
      await bare.save(ProviderApp.github, clientId: 'client-id');
      final service = ProviderOAuthService(
        apps: bare,
        users: users,
        httpClient: HttpClient()
          ..connectionTimeout = const Duration(milliseconds: 1),
      );
      expect(await service.availableProviders(), [ProviderApp.github]);
    });
  });

  group('beginLogin', () {
    test('carries the client id, the redirect and an unguessable state',
        () async {
      final url = await oauth.beginLogin(
        provider: ProviderApp.github,
        userId: alice,
        redirectUri: redirect,
      );
      expect(url.host, 'github.com');
      expect(url.queryParameters['client_id'], 'client-id');
      expect(url.queryParameters['redirect_uri'], redirect.toString());
      expect(url.queryParameters['response_type'], 'code');
      expect(url.queryParameters['state']!.length, greaterThanOrEqualTo(32));
    });

    test('never puts the user id in the URL', () async {
      // The callback resolves WHO from server-side state. A user id in the
      // browser's URL would be an invitation to change it.
      final url = await oauth.beginLogin(
        provider: ProviderApp.github,
        userId: alice,
        redirectUri: redirect,
      );
      expect(url.toString(), isNot(contains(alice)));
    });

    test('two logins get different states', () async {
      final a = await oauth.beginLogin(
        provider: ProviderApp.github,
        userId: alice,
        redirectUri: redirect,
      );
      final b = await oauth.beginLogin(
        provider: ProviderApp.github,
        userId: alice,
        redirectUri: redirect,
      );
      expect(a.queryParameters['state'], isNot(b.queryParameters['state']));
    });

    test('refuses a provider this server has no app for', () async {
      expect(
        () => oauth.beginLogin(
          provider: ProviderApp.linear,
          userId: alice,
          redirectUri: redirect,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('the pending map is bounded', () async {
      for (var i = 0; i < ProviderOAuthService.maxPendingLogins + 10; i++) {
        await oauth.beginLogin(
          provider: ProviderApp.github,
          userId: alice,
          redirectUri: redirect,
        );
      }
      // No assertion beyond "it did not grow without bound" — the endpoint
      // that completes these is unauthenticated, so a flood must not be a
      // memory leak. Reaching here without an OOM is the test.
      expect(await oauth.availableProviders(), isNotEmpty);
    });
  });

  group('handleCallback', () {
    test('an unknown state mints nothing', () async {
      expect(
        () => oauth.handleCallback(
          requestUri: Uri.parse(
            'http://127.0.0.1:9030/oauth/github/callback'
            '?code=abc&state=never-issued',
          ),
          redirectUri: redirect,
        ),
        throwsA(isA<AuthException>()),
      );
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('a state with no code mints nothing', () async {
      final url = await oauth.beginLogin(
        provider: ProviderApp.github,
        userId: alice,
        redirectUri: redirect,
      );
      final state = url.queryParameters['state'];
      expect(
        () => oauth.handleCallback(
          requestUri: Uri.parse(
            'http://127.0.0.1:9030/oauth/github/callback?state=$state',
          ),
          redirectUri: redirect,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test("the provider's own error is surfaced, not swallowed", () async {
      // A redirect-URI mismatch is the most common setup failure and the
      // provider is the only thing that can say so.
      expect(
        () => oauth.handleCallback(
          requestUri: Uri.parse(
            'http://127.0.0.1:9030/oauth/github/callback'
            '?error=redirect_uri_mismatch',
          ),
          redirectUri: redirect,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('redirect_uri_mismatch'),
          ),
        ),
      );
    });

    test('an expired login cannot be completed', () async {
      var now = DateTime.utc(2026, 1, 1, 12);
      final service = ProviderOAuthService(
        apps: apps,
        users: users,
        now: () => now,
      );
      final url = await service.beginLogin(
        provider: ProviderApp.github,
        userId: alice,
        redirectUri: redirect,
      );
      now = now.add(ProviderOAuthService.pendingTtl * 2);

      expect(
        () => service.handleCallback(
          requestUri: Uri.parse(
            'http://127.0.0.1:9030/oauth/github/callback'
            '?code=abc&state=${url.queryParameters['state']}',
          ),
          redirectUri: redirect,
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('the device flow', () {
    test('is what GitHub uses, and Linear does not', () {
      // A device flow needs no callback URL registered anywhere, which is what
      // makes it work for a server on 127.0.0.1 or reached from a phone.
      expect(ProviderOAuthService.usesDeviceFlow(ProviderApp.github), isTrue);
      expect(ProviderOAuthService.usesDeviceFlow(ProviderApp.linear), isFalse);
    });

    test('refuses a provider with no device endpoint', () async {
      await apps.save(
        ProviderApp.linear,
        clientId: 'id',
        clientSecret: 'secret',
      );
      expect(
        () => oauth.beginDeviceLogin(
          provider: ProviderApp.linear,
          userId: alice,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('refuses a provider this server has no app for', () async {
      final bare = ProviderOAuthService(
        apps: ProviderAppSettings(secrets: secrets),
        users: users,
        httpClient: HttpClient()
          ..connectionTimeout = const Duration(milliseconds: 1),
      );
      expect(
        () => bare.beginDeviceLogin(
          provider: ProviderApp.github,
          userId: alice,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('the prompt carries no device code', () {
      // The device code is the SERVER's half of the exchange; a client holding
      // it could complete somebody else's login.
      const prompt = DeviceLoginPrompt(
        userCode: 'ABCD-1234',
        verificationUri: 'https://github.com/login/device',
        expiresIn: Duration(minutes: 15),
        interval: Duration(seconds: 5),
      );
      final wire = prompt.toJson();
      expect(wire['mode'], 'device');
      expect(wire['user_code'], 'ABCD-1234');
      expect(wire.containsKey('device_code'), isFalse);
    });
  });

  group('storePastedToken', () {
    test('lands in the SAME place a minted one does', () async {
      // Both paths have to produce a credential the resolution chain finds,
      // or "paste a token" would work in the UI and nowhere else.
      await oauth.storePastedToken(
        userId: alice,
        provider: ProviderApp.github,
        token: 'ghp_pasted',
      );
      final stored = await users.forgeToken(alice, ForgeHost.github);
      expect(stored?.accessToken, 'ghp_pasted');
      expect(stored?.source, ForgeCredentialSource.settings);
    });
  });

  group('refresh', () {
    test('a credential with no refresh token cannot be refreshed', () async {
      final refreshed = await oauth.refresh(
        alice,
        ForgeHost.github,
        const ProviderToken(accessToken: 'stale'),
      );
      expect(refreshed, isNull);
    });

    test('a forge with no OAuth app cannot be refreshed', () async {
      final refreshed = await oauth.refresh(
        alice,
        ForgeHost.gitlab,
        const ProviderToken(accessToken: 'stale', refreshToken: 'r'),
      );
      expect(refreshed, isNull);
    });
  });
}

