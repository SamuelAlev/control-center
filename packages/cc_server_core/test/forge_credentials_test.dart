import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

/// A GitHub App user token as an own-app sign-in stores it.
ProviderToken _githubSignIn(
  String access, {
  String login = '',
  DateTime? expiresAt,
  String refresh = 'ghr_refresh',
}) => ProviderToken(
  accessToken: access,
  refreshToken: refresh,
  expiresAt: expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 8)),
  source: ForgeCredentialSource.oauth,
  accountLogin: login,
  appId: 'Iv1.app',
);

Workspace _workspace(String id, GithubAuthMode mode) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  githubAuthMode: mode,
);

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
    String? ownerUserId,
    Future<String?> Function(ForgeHost, String)? viewerProbe,
    Map<String, Workspace> workspaces = const {},
  }) => ForgeCredentials(
    env: (name) => env[name],
    users: users,
    serverOwnerUserId: ownerUserId == null ? null : () async => ownerUserId,
    viewerProbe: viewerProbe,
  )..workspaceLookup = (id) async => workspaces[id];

  group('GitHub is person-only', () {
    test("a member resolves their own sign-in, never another's", () async {
      final creds = build();
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_a'),
      );

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), 'ghu_a');
      expect(await creds.tokenFor(ForgeHost.github, userId: bob), isNull);
    });

    test('without a person there is no GitHub token at all', () async {
      // No App, server-owner or environment fallback: automation mints
      // one-repository tokens through GitHubClients instead.
      final creds = build(
        env: const {'GITHUB_TOKEN': 'ghp_host', 'GH_TOKEN': 'ghp_host'},
        ownerUserId: alice,
      );
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_a'),
      );

      expect(await creds.tokenFor(ForgeHost.github), isNull);
    });

    test('a pasted GitHub token is refused', () async {
      final creds = build();
      expect(
        () => creds.setToken(ForgeHost.github, 'ghp_pasted', userId: alice),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a stored credential that is not a GitHub App sign-in is cleared '
        'instead of served', () async {
      final creds = build();
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(
          accessToken: 'ghp_pasted',
          source: ForgeCredentialSource.settings,
        ),
      );

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('an OAuth-app token (no ghu_ prefix, no expiry) is not a '
        'sign-in', () async {
      final token = ProviderToken(
        accessToken: 'gho_oauth_app',
        refreshToken: 'r',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        source: ForgeCredentialSource.oauth,
        appId: 'Iv1.app',
      );
      expect(ForgeCredentials.isGitHubSignIn(token), isFalse);
      expect(ForgeCredentials.isGitHubSignIn(_githubSignIn('ghu_ok')), isTrue);
    });

    test('a workspace sign-in wins over the global one', () async {
      final creds = build(
        workspaces: {'ws': _workspace('ws', GithubAuthMode.inherit)},
      );
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_g'),
      );
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_ws'),
        workspaceId: 'ws',
      );

      expect(
        await creds.tokenFor(
          ForgeHost.github,
          userId: alice,
          workspaceId: 'ws',
        ),
        'ghu_ws',
      );
    });

    test('an inheriting workspace accepts the global sign-in', () async {
      final creds = build(
        workspaces: {'ws': _workspace('ws', GithubAuthMode.inherit)},
      );
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_g'),
      );

      expect(
        await creds.tokenFor(
          ForgeHost.github,
          userId: alice,
          workspaceId: 'ws',
        ),
        'ghu_g',
      );
    });

    test('a workspace on its own App accepts only a sign-in to it', () async {
      final creds = build(
        workspaces: {'ws': _workspace('ws', GithubAuthMode.app)},
      );
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_g'),
      );

      expect(
        await creds.tokenFor(
          ForgeHost.github,
          userId: alice,
          workspaceId: 'ws',
        ),
        isNull,
      );
      expect(
        await creds.storedCredential(
          ForgeHost.github,
          alice,
          workspaceId: 'ws',
        ),
        isNull,
      );
    });
  });

  group('GitLab and Bitbucket', () {
    test("a user's own pasted token resolves for them only", () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'gl-alice', userId: alice);

      expect(await creds.tokenFor(ForgeHost.gitlab, userId: alice), 'gl-alice');
      expect(await creds.tokenFor(ForgeHost.gitlab, userId: bob), isNull);
    });

    test("a user's lane never falls through to the environment", () async {
      final creds = build(env: const {'GITLAB_TOKEN': 'env'});
      expect(await creds.tokenFor(ForgeHost.gitlab, userId: alice), isNull);
    });

    test(
      "background work uses the owner's token, then the environment",
      () async {
        final creds = build(
          env: const {'GITLAB_TOKEN': 'env-gl'},
          ownerUserId: alice,
        );
        expect(await creds.tokenFor(ForgeHost.gitlab), 'env-gl');

        await creds.setToken(ForgeHost.gitlab, 'owner-gl', userId: alice);
        expect(await creds.tokenFor(ForgeHost.gitlab), 'owner-gl');
      },
    );

    test('each forge reads its own environment variables', () async {
      final creds = build(
        env: const {'GITLAB_TOKEN': 'gl', 'BITBUCKET_API_TOKEN': 'bb'},
      );
      expect(await creds.tokenFor(ForgeHost.gitlab), 'gl');
      expect(await creds.tokenFor(ForgeHost.bitbucket), 'bb');
    });

    test('the local pseudo-forge never resolves a credential', () async {
      final creds = build(env: const {'GITLAB_TOKEN': 'gl'});
      expect(await creds.tokenFor(ForgeHost.local), isNull);
      expect(await creds.tokenFor(ForgeHost.local, userId: alice), isNull);
    });

    test('clearing removes only that user\'s credential', () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'a', userId: alice);
      await creds.setToken(ForgeHost.gitlab, 'b', userId: bob);
      await creds.clearToken(ForgeHost.gitlab, userId: alice);

      expect(await creds.tokenFor(ForgeHost.gitlab, userId: alice), isNull);
      expect(await creds.tokenFor(ForgeHost.gitlab, userId: bob), 'b');
    });
  });

  group('expiry', () {
    ProviderToken expired() => _githubSignIn(
      'ghu_stale',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    );

    test('an expired sign-in is refreshed in place', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          Refreshed(_githubSignIn('ghu_fresh'));

      expect(
        await creds.tokenFor(ForgeHost.github, userId: alice),
        'ghu_fresh',
      );
      // Persisted, not just returned: the next call must not refresh again.
      expect(
        (await users.forgeToken(alice, ForgeHost.github))?.accessToken,
        'ghu_fresh',
      );
    });

    test('a refused refresh signs the person out', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          const RefreshRejected();

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('a transient refresh failure keeps the credential', () async {
      // A provider outage must never sign anybody out.
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          const RefreshUnavailable();

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNotNull);
    });

    test('concurrent callers share one refresh (refresh tokens are '
        'single-use)', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      var refreshes = 0;
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return Refreshed(_githubSignIn('ghu_fresh'));
      };

      final results = await Future.wait([
        creds.tokenFor(ForgeHost.github, userId: alice),
        creds.tokenFor(ForgeHost.github, userId: alice),
      ]);
      expect(results, ['ghu_fresh', 'ghu_fresh']);
      expect(refreshes, 1);
    });
  });

  group('refresh races', () {
    ProviderToken expired() => _githubSignIn(
      'ghu_stale',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    );

    test(
      'a refused refresh never clears a sign-in that landed meanwhile',
      () async {
        final creds = build();
        await users.setForgeToken(alice, ForgeHost.github, expired());
        creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async {
          await users.setForgeToken(
            alice,
            ForgeHost.github,
            _githubSignIn('ghu_newer', refresh: 'ghr_newer'),
          );
          return const RefreshRejected();
        };

        expect(
          await creds.tokenFor(ForgeHost.github, userId: alice),
          'ghu_newer',
        );
        expect(
          (await users.forgeToken(alice, ForgeHost.github))?.accessToken,
          'ghu_newer',
        );
      },
    );

    test(
      'a renewal of the older grant never overwrites a newer sign-in',
      () async {
        final creds = build();
        await users.setForgeToken(alice, ForgeHost.github, expired());
        creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async {
          await users.setForgeToken(
            alice,
            ForgeHost.github,
            _githubSignIn('ghu_newer', refresh: 'ghr_newer'),
          );
          return Refreshed(_githubSignIn('ghu_renewed'));
        };

        expect(
          await creds.tokenFor(ForgeHost.github, userId: alice),
          'ghu_newer',
        );
        expect(
          (await users.forgeToken(alice, ForgeHost.github))?.refreshToken,
          'ghr_newer',
        );
      },
    );

    test('a sign-out during the refresh stays signed out', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async {
        await users.clearForgeToken(alice, ForgeHost.github);
        return Refreshed(_githubSignIn('ghu_renewed'));
      };

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('a later caller reuses the renewal instead of spending the old '
        'refresh token again', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      final spent = <String>[];
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async {
        spent.add(stale.refreshToken);
        return Refreshed(_githubSignIn('ghu_fresh', refresh: 'ghr_next'));
      };

      expect(
        await creds.tokenFor(ForgeHost.github, userId: alice),
        'ghu_fresh',
      );
      expect(
        await creds.tokenFor(ForgeHost.github, userId: alice),
        'ghu_fresh',
      );
      expect(spent, ['ghr_refresh']);
    });
  });

  group('Connect seals', () {
    ProviderToken sealed({String installId = 'inst-1'}) => ProviderToken(
      seal: 'sealed-blob',
      sealInstallId: installId,
      connectOrigin: 'https://connect.example',
      source: ForgeCredentialSource.connect,
      accountLogin: 'octocat',
    );

    test('a seal minted for another install id reads as signed out', () async {
      final creds = build()..currentSealInstallId = (origin) async => 'inst-2';
      await users.setForgeToken(alice, ForgeHost.github, sealed());

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('a seal for a Connect this server no longer uses reads as signed '
        'out but survives switching back', () async {
      final creds = build()..currentSealInstallId = (origin) async => null;
      await users.setForgeToken(alice, ForgeHost.github, sealed());

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNotNull);
    });

    test('the access token of a seal lives in memory only', () async {
      final creds = build()..currentSealInstallId = (origin) async => 'inst-1';
      await users.setForgeToken(alice, ForgeHost.github, sealed());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          Refreshed(
            stale.copyWith(
              accessToken: 'ghu_live',
              expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
            ),
          );

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), 'ghu_live');
      final onDisk = await secrets.readFresh(
        UserCredentialsStore.forgeKey(ForgeHost.github, alice),
      );
      expect(onDisk, isNot(contains('ghu_live')));
    });

    test('a rotated seal the disk refuses is still served, not lost', () async {
      final creds = build()..currentSealInstallId = (origin) async => 'inst-1';
      await users.setForgeToken(alice, ForgeHost.github, sealed());
      var refreshes = 0;
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async {
        refreshes++;
        return Refreshed(
          stale.copyWith(
            seal: 'sealed-blob-2',
            accessToken: 'ghu_live',
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
          ),
        );
      };
      Process.runSync('chmod', ['500', dir.path]);
      try {
        expect(
          await creds.tokenFor(ForgeHost.github, userId: alice),
          'ghu_live',
        );
      } finally {
        Process.runSync('chmod', ['700', dir.path]);
      }
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), 'ghu_live');
      expect(refreshes, 1, reason: 'the spent parent is never sent again');

      // The next write saves it.
      await users.setForgeToken(bob, ForgeHost.github, sealed());
      final onDisk = await FileSecretsStore(
        dataDir: dir.path,
      ).readFresh(UserCredentialsStore.forgeKey(ForgeHost.github, alice));
      expect(onDisk, contains('sealed-blob-2'));
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
      await creds.setToken(ForgeHost.gitlab, 'super-secret', userId: alice);
      final json = (await creds.connections(
        userId: alice,
      )).firstWhere((c) => c.forge == ForgeHost.gitlab).toJson().toString();
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
        _githubSignIn('ghu_t', login: 'octocat'),
      );

      final gh = (await creds.connections(
        userId: alice,
      )).firstWhere((c) => c.forge == ForgeHost.github);
      expect(gh.authenticated, isTrue);
      expect(gh.username, 'octocat');
      expect(gh.source, ForgeCredentialSource.oauth);
      expect(probes, 0);
    });

    test('without a person GitHub reports disconnected', () async {
      final creds = build(env: const {'GITHUB_TOKEN': 'ghp_host'});
      final gh = (await creds.connections()).firstWhere(
        (c) => c.forge == ForgeHost.github,
      );
      expect(gh.authenticated, isFalse);
    });
  });

  group('setToken probes the new token', () {
    test('resolves the viewer and caches it', () async {
      var probes = 0;
      final creds = build(
        viewerProbe: (forge, token) async {
          probes++;
          return 'resolved-user';
        },
      );
      final result = await creds.setToken(
        ForgeHost.gitlab,
        'gl',
        userId: alice,
      );
      expect(result.authenticated, isTrue);
      expect(result.username, 'resolved-user');
      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'resolved-user',
      );
      expect(probes, 1);
    });

    test(
      'a rejected credential reports unauthenticated with a reason',
      () async {
        final creds = build(viewerProbe: (forge, token) async => null);
        final result = await creds.setToken(
          ForgeHost.gitlab,
          'bad',
          userId: alice,
        );
        expect(result.authenticated, isFalse);
        expect(result.error, contains('GitLab'));
      },
    );

    test('changing a token invalidates the cached identity', () async {
      var next = 'first';
      final creds = build(viewerProbe: (forge, token) async => next);
      await creds.setToken(ForgeHost.gitlab, 'a', userId: alice);
      expect(await creds.viewerLogin(ForgeHost.gitlab, userId: alice), 'first');

      next = 'second';
      await creds.setToken(ForgeHost.gitlab, 'b', userId: alice);
      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'second',
      );
    });

    test("one user's identity is not served to another", () async {
      final creds = build(
        viewerProbe: (forge, token) async =>
            token == 'alice-token' ? 'alice-gl' : 'bob-gl',
      );
      await creds.setToken(ForgeHost.gitlab, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.gitlab, 'bob-token', userId: bob);

      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'alice-gl',
      );
      expect(await creds.viewerLogin(ForgeHost.gitlab, userId: bob), 'bob-gl');
    });
  });

  group('clearing', () {
    test(
      'an empty token clears rather than storing an empty credential',
      () async {
        final creds = build();
        await creds.setToken(ForgeHost.gitlab, 'x', userId: alice);
        await creds.setToken(ForgeHost.gitlab, '', userId: alice);
        expect(await creds.tokenFor(ForgeHost.gitlab, userId: alice), isNull);
      },
    );

    test('every credential change is announced on changes', () async {
      final creds = build();
      final seen = <ForgeCredentialChange>[];
      creds.changes.listen(seen.add);
      await creds.setToken(ForgeHost.gitlab, 'x', userId: alice);
      await creds.clearToken(ForgeHost.gitlab, userId: alice);
      expect(seen, hasLength(2));
      expect(seen.first.forge, ForgeHost.gitlab);
      expect(seen.first.userId, alice);
      expect(seen.first.workspaceId, isNull);
    });

    test('storing without any user is refused', () async {
      final creds = build();
      expect(
        () => creds.setToken(ForgeHost.gitlab, 'x'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
