import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// A 2048-bit test key, generated for this test and used nowhere else. The
/// GitHub App lane cannot be exercised without one: the client refuses to
/// build when the PEM does not parse, which is the behaviour worth pinning.
const _testPrivateKeyPem = '''
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1oBppJyKMeYgcjUYMYgsuycTm9rDmhmwxlAWPSvKkU7dudpa
B7lcgz4shv5qmOZ69MS3E2wlh7ztPUpE2/gmPGGprEvERAwEnOxC2eVzoVX023Va
yQNdisqWVmsoW/30lVKPCxynVG78cxWE6KzYqbg+ru5plAof7gHt9gKsv55ybJWw
YptP42DrbFh69A2HRtLaoTrk1yPjBNzT/0xxQO1tf2lZbNbd1Z5LOSt7YSmzaUL/
R+JnEF3DLhQxOv4DNdwds//CvfuMvgnjMXqdfWxzQlQAWYYEE55QpJfPpCSMKmIn
7vI16xGoAoyF3yqmp1MNMeulz5ieTe3z/wcGtQIDAQABAoIBAGYJCbfjOx3HcXHC
bfLJ6zVPvlUqOFeqltuPJzUMCr0afgC1rJP2CdrojXfduElpgd3DYa8ch7HNHjFE
jgLxRQb+Eh9Cn2cbLGqVPKu4KUv6vpJSfdAXCL1H50HOkZFI+bq6Xg8UH0jbzrzT
5Lhl2F7LpQ3DnXdtZYjrZA3dcd1oG0BaojY+JnI6HNz/QbPNQQprYkrwykuRcqUF
Y51fCsdktdmB8vYma3yUfMfMpyrvZ6l7xIGJwjulspIuKQWAnraqRV1fB+V6ZHSt
PaZr/p91NXn6GnAYmupCdC1/oqVJVjcMmxBp940lra8vW64TJf6z43zsObD9mqz0
t1Q2rkECgYEA/PCqRj1HOh0YzNbjV1Cv1Y0rtHqT6n2FNM+mXZvNqm0qFR/g2f+G
wOvfAev2a749NxKr2ljl5xPMTwtA/FvH0JR3RLGXqwSoUR7Ag8m3yozWg4EVdKyK
ByQrmTQ1RUvmlF5uELnwsA+A3rgTSa6/hpK7X15Q+RcaStsRmI1ww/ECgYEA2Ri0
6Kw+bNT7+tIoVFERkJXe+5hiPFxuLBTPHwBqYsF4uTIVQk5zQPqZDLaXv+mOYgEU
D5Shd4I/ROMJ5y8ITxkc0HjfqUF/XPgqF3LqWtLLhLrqoo1JaoeoRQzggb9n6MQe
+KSWHTC4FsLjxEc5SbLXXhFbzQHhCqnoqgndYwUCgYEAsZ09tDzrez9bXtu2oGWk
U0ziV8WLgKnLlB4MMMdrUDV/y32rIulv8qCu5GaRj27zBW0zCAxMxEr+uLKqW4sH
cMwQREiAvDJ1DyGNBf3r9WuYZpeKPXe7JPCdPOOQVKzLqXv1xgELplX8pGiWArOX
AiSfNoTAT2mNqOrUHE+V08ECgYBFCZdWOpgrcduj2rsafSFR0mczqTTsLxSWDhQD
rtUmDJKAik26ZUo/irGrGlHNpM8zmVYw0jo6z/+gv3aBvzIsPTctkJLHt11ySjTQ
einOsiQoVGyTPszvBK7dLogimqTHn76doXFfXQPdsSJPY7rzFd1pO6nu2r8e7gNg
N3zgpQKBgQCm/sXLID74u9VtVlhL0nhv6zaKm3UqcMtdu+ivl/intWZTGbXUxJqq
L+pzaH8qXpUpjZynoVk8RE8aCqN9h34//JD4u7TOtcHoZmbA+AMdPmc1vknVbvn5
SVgaUK2148/jd/aKIcXn3k4Hc17BYRgsoeMdfe3jrjOw4SknWBjC5g==
-----END RSA PRIVATE KEY-----
''';

/// A Dio adapter that answers from a fixed table, so the GitHub App lane can
/// be driven without a network.
class _FakeGitHubAdapter implements HttpClientAdapter {
  _FakeGitHubAdapter(this.responses);

  final Map<String, Object> responses;
  final List<String> requested = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.path);
    final body = responses[options.path];
    if (body == null) {
      return ResponseBody.fromString('{}', 404);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        HttpHeaders.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late UserCredentialsStore users;

  const alice = 'user-alice';
  const bob = 'user-bob';

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_forge_creds_');
    secrets = FileSecretsStore(dataDir: dir.path);
    users = UserCredentialsStore(secrets);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  ForgeCredentials build({
    Map<String, String> env = const {},
    ProviderAppSettings? apps,
    String? ownerUserId,
    Future<String?> Function(ForgeHost, String)? viewerProbe,
  }) => ForgeCredentials(
    env: (name) => env[name],
    users: users,
    apps: apps,
    serverOwnerUserId: ownerUserId == null ? null : () async => ownerUserId,
    viewerProbe: viewerProbe,
  );

  /// A settings service whose GitHub app answers [installations] and mints
  /// [token] for whichever installation is asked for.
  ProviderAppSettings appSettingsWith({
    required String token,
    List<Map<String, Object?>> installations = const [
      {
        'id': 42,
        'account': {'login': 'acme'},
        'repository_selection': 'all',
      },
    ],
  }) {
    final adapter = _FakeGitHubAdapter({
      '/app/installations': installations,
      '/app/installations/42/access_tokens': {
        'token': token,
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      },
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
      ..httpClientAdapter = adapter;
    return ProviderAppSettings(
      secrets: secrets,
      githubAppFactory: ({required String appId, required String pem}) =>
          GitHubAppClient(appId: appId, privateKeyPem: pem, dio: dio),
    );
  }

  group('per-user credentials', () {
    test('a user resolves their OWN token, never another member\'s', () async {
      final creds = build();
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.github, 'bob-token', userId: bob);

      expect(
        await creds.tokenFor(ForgeHost.github, userId: alice),
        'alice-token',
      );
      expect(await creds.tokenFor(ForgeHost.github, userId: bob), 'bob-token');
    });

    test('a user with no credential is disconnected, even when another '
        'member has one', () async {
      final creds = build();
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

      expect(await creds.tokenFor(ForgeHost.github, userId: bob), isNull);
      final bobs = await creds.connections(userId: bob);
      expect(
        bobs.firstWhere((c) => c.forge == ForgeHost.github).authenticated,
        isFalse,
      );
    });

    test("a user's lane never falls through to the environment", () async {
      // The environment is the SERVER's credential, not this person's.
      // Falling through would report them signed in as an account they have
      // no relationship with.
      final creds = build(env: {'GITHUB_TOKEN': 'from-env'});
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
    });

    test('clearing removes only that user\'s credential', () async {
      final creds = build();
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.github, 'bob-token', userId: bob);

      await creds.clearToken(ForgeHost.github, userId: alice);

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await creds.tokenFor(ForgeHost.github, userId: bob), 'bob-token');
    });

    test('each forge is stored separately', () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'gl', userId: alice);

      expect(await creds.tokenFor(ForgeHost.gitlab, userId: alice), 'gl');
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
    });
  });

  // Everything a human drives from the UI resolves through this lane, and the
  // question it answers is whose NAME the write carries on the forge. Before
  // it existed the PR surface used the no-caller lookup, so every review the
  // operator approved and every comment they posted arrived as the app.
  group('the actor lane (a human-driven write)', () {
    test('the caller outranks the app identity', () async {
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(
        ProviderApp.github,
        appId: '123',
        privateKeyPem: _testPrivateKeyPem,
      );
      final creds = build(apps: apps, ownerUserId: alice);
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

      // The same server, the same moment: background work stays on the app,
      // Alice's own click goes out as Alice.
      expect(await creds.tokenFor(ForgeHost.github), 'ghs_installation');
      expect(
        await creds.tokenForActor(ForgeHost.github, alice),
        'alice-token',
      );
      expect(await creds.actsAsSelf(ForgeHost.github, alice), isTrue);
    });

    test('one member never acts as another', () async {
      final creds = build();
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.github, 'bob-token', userId: bob);

      expect(await creds.tokenForActor(ForgeHost.github, bob), 'bob-token');
    });

    test('a caller who has not connected the forge falls back to the '
        'server, and says so', () async {
      // The fallback keeps the surface readable for a member who only signed
      // in elsewhere. It is reported rather than hidden, because it is the one
      // state where a write is authored by the app again.
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(
        ProviderApp.github,
        appId: '123',
        privateKeyPem: _testPrivateKeyPem,
      );
      final creds = build(apps: apps);
      await creds.setToken(ForgeHost.gitlab, 'bob-gitlab', userId: bob);

      expect(
        await creds.tokenForActor(ForgeHost.github, bob),
        'ghs_installation',
      );
      expect(await creds.actsAsSelf(ForgeHost.github, bob), isFalse);
    });

    test('no acting user is the background chain', () async {
      final creds = build(ownerUserId: alice, env: {'GITHUB_TOKEN': 'env'});
      expect(await creds.tokenForActor(ForgeHost.github, null), 'env');
      expect(await creds.actsAsSelf(ForgeHost.github, null), isFalse);
    });

    test('signing out reverts the next write to the server identity', () async {
      // The lookup runs per call, so revocation applies immediately — there is
      // no client to rebuild and no cached token to outlive the sign-out.
      final creds = build(ownerUserId: bob, env: {'GITHUB_TOKEN': 'env'});
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      expect(
        await creds.tokenForActor(ForgeHost.github, alice),
        'alice-token',
      );

      await creds.clearToken(ForgeHost.github, userId: alice);
      expect(await creds.tokenForActor(ForgeHost.github, alice), 'env');
    });
  });

  group('the server lane (no calling user)', () {
    test('the app identity answers first', () async {
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(ProviderApp.github, appId: '123', privateKeyPem: _testPrivateKeyPem);
      final creds = build(
        apps: apps,
        env: {'GITHUB_TOKEN': 'from-env'},
        ownerUserId: alice,
      );
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

      expect(await creds.tokenFor(ForgeHost.github), 'ghs_installation');
    });

    test("falls back to the server owner's own credential", () async {
      final creds = build(ownerUserId: alice, env: {'GITHUB_TOKEN': 'env'});
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

      expect(await creds.tokenFor(ForgeHost.github), 'alice-token');
    });

    test('falls back to the environment last', () async {
      final creds = build(ownerUserId: alice, env: {'GITHUB_TOKEN': 'env'});
      expect(await creds.tokenFor(ForgeHost.github), 'env');
    });

    test('each forge reads its own environment variables', () async {
      final creds = build(
        env: {
          'GH_TOKEN': 'gh',
          'GITLAB_TOKEN': 'gl',
          'BITBUCKET_API_TOKEN': 'bb',
        },
      );
      expect(await creds.tokenFor(ForgeHost.github), 'gh');
      expect(await creds.tokenFor(ForgeHost.gitlab), 'gl');
      expect(await creds.tokenFor(ForgeHost.bitbucket), 'bb');
    });

    test('the app identity is GitHub-only', () async {
      // A configured GitHub App must not make GitLab look connected.
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(ProviderApp.github, appId: '123', privateKeyPem: _testPrivateKeyPem);
      final creds = build(apps: apps);
      expect(await creds.tokenFor(ForgeHost.gitlab), isNull);
      expect(await creds.tokenFor(ForgeHost.bitbucket), isNull);
    });

    test('a forge with nothing configured has no token', () async {
      final creds = build();
      for (final forge in ForgeHost.supported) {
        expect(await creds.tokenFor(forge), isNull, reason: forge.name);
      }
    });

    test('the local pseudo-forge never resolves a credential', () async {
      final creds = build(env: {'GITHUB_TOKEN': 'x'});
      expect(await creds.tokenFor(ForgeHost.local), isNull);
    });
  });

  // Repo-scoped background work (the open-PR poller) resolves per owner: a
  // token from "whichever installation answered first" is answered with 404
  // by GitHub for every repo under an owner the app is not installed on.
  group('the per-owner lane (repo-scoped background work)', () {
    test('the installation covering the owner answers first', () async {
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(
        ProviderApp.github,
        appId: '123',
        privateKeyPem: _testPrivateKeyPem,
      );
      final creds = build(apps: apps, ownerUserId: alice);
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

      expect(
        await creds.tokenForRepoOwner(ForgeHost.github, 'acme'),
        'ghs_installation',
      );
    });

    test('owner matching is case-insensitive (GitHub logins are)', () async {
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(
        ProviderApp.github,
        appId: '123',
        privateKeyPem: _testPrivateKeyPem,
      );
      final creds = build(apps: apps);

      expect(
        await creds.tokenForRepoOwner(ForgeHost.github, 'Acme'),
        'ghs_installation',
      );
    });

    test('an owner the app is not installed on falls back to the server '
        "owner's credential, never another installation's token", () async {
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(
        ProviderApp.github,
        appId: '123',
        privateKeyPem: _testPrivateKeyPem,
      );
      final creds = build(
        apps: apps,
        ownerUserId: alice,
        env: {'GITHUB_TOKEN': 'from-env'},
      );
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

      // The app only covers 'acme'; a PAT the owner pasted may reach what the
      // app cannot, while 'ghs_installation' is guaranteed not to.
      expect(
        await creds.tokenForRepoOwner(ForgeHost.github, 'control_center'),
        'alice-token',
      );
    });

    test('falls back to the environment when the owner has none', () async {
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(
        ProviderApp.github,
        appId: '123',
        privateKeyPem: _testPrivateKeyPem,
      );
      final creds = build(apps: apps, env: {'GITHUB_TOKEN': 'from-env'});

      expect(
        await creds.tokenForRepoOwner(ForgeHost.github, 'control_center'),
        'from-env',
      );
    });

    test('resolves nothing when no lane can answer', () async {
      final creds = build();
      expect(
        await creds.tokenForRepoOwner(ForgeHost.github, 'control_center'),
        isNull,
      );
      expect(await creds.tokenForRepoOwner(ForgeHost.local, 'x'), isNull);
    });
  });

  group('expiry', () {
    test('an expired credential is refreshed in place', () async {
      final creds = build();
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        ProviderToken(
          accessToken: 'stale',
          refreshToken: 'refresh-me',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          source: ForgeCredentialSource.oauth,
        ),
      );
      creds.refreshUserToken = (userId, forge, expired) async => ProviderToken(
        accessToken: 'fresh',
        refreshToken: expired.refreshToken,
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
        source: ForgeCredentialSource.oauth,
      );

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), 'fresh');
      // Persisted, not just returned: the next call must not refresh again.
      expect(
        (await users.forgeToken(alice, ForgeHost.github))?.accessToken,
        'fresh',
      );
    });

    test('a credential that cannot be refreshed is dropped, not served',
        () async {
      // Serving it would fail every call with a 401 the UI cannot explain;
      // dropping it makes the row say "not connected" and offer a sign-in.
      final creds = build();
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        ProviderToken(
          accessToken: 'stale',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('a failed refresh drops the credential', () async {
      final creds = build();
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        ProviderToken(
          accessToken: 'stale',
          refreshToken: 'refresh-me',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      creds.refreshUserToken = (userId, forge, expired) async => null;

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });
  });

  group('connections', () {
    test('reports every supported forge, in order', () async {
      final connections = await build().connections(userId: alice);
      expect(connections.map((c) => c.forge).toList(), ForgeHost.supported);
      expect(connections.every((c) => !c.authenticated), isTrue);
    });

    test('never carries a token', () async {
      final creds = build();
      await creds.setToken(
        ForgeHost.github,
        'super-secret',
        userId: alice,
      );
      final json = (await creds.connections(userId: alice))
          .firstWhere((c) => c.forge == ForgeHost.github)
          .toJson()
          .toString();
      expect(json, isNot(contains('super-secret')));
    });

    test('one forge connecting leaves the others disconnected', () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'gl', userId: alice);
      final byForge = {
        for (final c in await creds.connections(userId: alice)) c.forge: c,
      };

      expect(byForge[ForgeHost.gitlab]!.authenticated, isTrue);
      expect(byForge[ForgeHost.github]!.authenticated, isFalse);
      expect(byForge[ForgeHost.bitbucket]!.authenticated, isFalse);
    });

    test('a stored account name is reported without a probe', () async {
      var probes = 0;
      final creds = build(
        viewerProbe: (forge, token) async {
          probes++;
          return 'probed';
        },
      );
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(
          accessToken: 't',
          accountLogin: 'octocat',
          source: ForgeCredentialSource.oauth,
        ),
      );

      final gh = (await creds.connections(
        userId: alice,
      )).firstWhere((c) => c.forge == ForgeHost.github);
      expect(gh.authenticated, isTrue);
      expect(gh.username, 'octocat');
      expect(gh.source, ForgeCredentialSource.oauth);
      expect(probes, 0);
    });

    test('the server lane reports the app as the source', () async {
      final apps = appSettingsWith(token: 'ghs_installation');
      await apps.save(ProviderApp.github, appId: '123', privateKeyPem: _testPrivateKeyPem);
      final creds = build(apps: apps);

      final gh = (await creds.connections()).firstWhere(
        (c) => c.forge == ForgeHost.github,
      );
      expect(gh.authenticated, isTrue);
      expect(gh.source, ForgeCredentialSource.app);
    });
  });

  group('testConnection', () {
    test('resolves the viewer and caches it', () async {
      var probes = 0;
      final creds = build(
        viewerProbe: (forge, token) async {
          probes++;
          return 'resolved-user';
        },
      );
      await creds.setToken(ForgeHost.gitlab, 'gl', userId: alice);

      final result = await creds.testConnection(
        ForgeHost.gitlab,
        userId: alice,
      );
      expect(result.authenticated, isTrue);
      expect(result.username, 'resolved-user');

      // The cached identity serves later reads rather than re-probing.
      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'resolved-user',
      );
      expect(probes, 1);
    });

    test('a rejected credential reports unauthenticated with a reason',
        () async {
      final creds = build(viewerProbe: (forge, token) async => null);
      await creds.setToken(ForgeHost.gitlab, 'bad', userId: alice);

      final result = await creds.testConnection(
        ForgeHost.gitlab,
        userId: alice,
      );
      expect(result.authenticated, isFalse);
      expect(result.error, contains('GitLab'));
    });

    test('changing a token invalidates the cached identity', () async {
      var next = 'first';
      final creds = build(viewerProbe: (forge, token) async => next);
      await creds.setToken(ForgeHost.gitlab, 'a', userId: alice);
      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'first',
      );

      next = 'second';
      await creds.setToken(ForgeHost.gitlab, 'b', userId: alice);
      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'second',
      );
    });

    test('one user\'s identity is not served to another', () async {
      final creds = build(
        viewerProbe: (forge, token) async =>
            token == 'alice-token' ? 'alice-gh' : 'bob-gh',
      );
      await creds.setToken(ForgeHost.gitlab, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.gitlab, 'bob-token', userId: bob);

      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'alice-gh',
      );
      expect(await creds.viewerLogin(ForgeHost.gitlab, userId: bob), 'bob-gh');
    });
  });

  group('clearing', () {
    test('an empty token clears rather than storing an empty credential',
        () async {
      final creds = build();
      await creds.setToken(ForgeHost.github, 'x', userId: alice);
      await creds.setToken(ForgeHost.github, '', userId: alice);
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
    });

    test('the revision bumps on every credential change', () async {
      final creds = build();
      final before = creds.revision;
      await creds.setToken(ForgeHost.github, 'x', userId: alice);
      expect(creds.revision, greaterThan(before));
    });

    test('storing without any user is refused', () async {
      // There is nobody to attach it to, and a server-wide fallback is the
      // model this replaced.
      final creds = build();
      expect(
        () => creds.setToken(ForgeHost.github, 'x'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
