import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show NeedsSignInException, ValidationException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_person_token_check.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

/// A GitHub App user token as an own-app sign-in stores it.
ProviderToken _githubSignIn(
  String access, {
  String login = 'octocat',
  DateTime? expiresAt,
  String refresh = 'ghr_refresh',
  String appId = 'Iv1.app',
}) => ProviderToken(
  accessToken: access,
  refreshToken: refresh,
  expiresAt: expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 8)),
  source: ForgeCredentialSource.oauth,
  accountLogin: login,
  accountId: '583231',
  appId: appId,
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
    ViewerProbe? viewerProbe,
    Set<String> slotOwners = const {},
  }) =>
      ForgeCredentials(
          users: users,
          viewerProbe: viewerProbe,
          // The forge answers for a pasted token as whoever the probe says
          // (anyone, without one); a Bitbucket access token is refused
          // before any forge is asked.
          personTokenCheck: (forge, token) async {
            if (forge == ForgeHost.bitbucket && !token.contains('@')) {
              return checkPersonForgeToken(forge, token);
            }
            final viewer = viewerProbe == null
                ? (login: 'person', id: '1')
                : await viewerProbe(forge, token);
            return viewer == null
                ? const PersonTokenRefused(
                    PersonTokenRefusal.rejected,
                    'GitLab does not accept this token.',
                  )
                : PersonTokenAccepted(viewer);
          },
        )
        ..workspaceOwnsSlot = (id) async => slotOwners.contains(id);

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
      final creds = build();
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_a'),
      );

      expect(await creds.tokenFor(ForgeHost.github), isNull);
      expect(
        await creds.tokenFor(ForgeHost.github, workspaceId: 'ws1'),
        isNull,
      );
    });

    test('a pasted GitHub token is refused', () async {
      final creds = build();
      expect(
        () => creds.setToken(ForgeHost.github, 'ghp_pasted', userId: alice),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a stored credential that is not a GitHub App sign-in is never '
        'served, and asks for a sign-in', () async {
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
      expect(
        (await creds.connection(ForgeHost.github, userId: alice)).status,
        ForgeConnectionStatus.needsSignIn,
      );
    });

    test('a sign-in that does not name its account is not a usable '
        'sign-in', () async {
      final creds = build();
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_anon').copyWith(accountId: ''),
      );
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(
        ForgeCredentials.isGitHubSignIn(_githubSignIn('ghu_x', login: '')),
        isFalse,
      );
    });

    test('a sign-in made with another App than the slot uses now is not '
        'served, and says so once', () async {
      var current = 'Iv1.app';
      final creds = build()
        ..currentGitHubClientId = ({workspaceId}) async => current;
      final changes = <String>[];
      creds.changes.listen((c) => changes.add(c.userId));
      await users.setForgeToken(alice, ForgeHost.github, _githubSignIn('ghu_a'));
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), 'ghu_a');

      current = 'Iv1.rotated';
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(changes, [alice], reason: 'announced once, not per read');
      expect(
        await users.forgeToken(alice, ForgeHost.github),
        isNotNull,
        reason: 'compared when resolved, never cleared on read',
      );
      expect(
        (await creds.connection(ForgeHost.github, userId: alice)).status,
        ForgeConnectionStatus.needsSignIn,
      );

      current = 'Iv1.app';
      expect(await creds.tokenFor(ForgeHost.github, userId: alice), 'ghu_a');
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

    test('a workspace that owns no slot never reads a grant left in '
        'it', () async {
      final creds = build();
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
        'ghu_g',
      );
      expect(
        (await creds.storedCredential(
          ForgeHost.github,
          alice,
          workspaceId: 'ws',
        ))?.workspaceId,
        isNull,
      );
    });

    test('a workspace sharing the global slot accepts the global '
        'sign-in', () async {
      final creds = build();
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

    test('a workspace that owns a slot accepts only a sign-in in its '
        'own slot', () async {
      final creds = build(slotOwners: {'ws'});
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

      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_w'),
        workspaceId: 'ws',
      );
      expect(
        await creds.tokenFor(
          ForgeHost.github,
          userId: alice,
          workspaceId: 'ws',
        ),
        'ghu_w',
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

    test('a person acting without their own token must connect one', () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'gl-alice', userId: alice);

      expect(
        await creds.requirePersonToken(ForgeHost.gitlab, alice),
        'gl-alice',
      );
      // Bob never borrows anyone else's token.
      for (final forge in [ForgeHost.gitlab, ForgeHost.bitbucket]) {
        await expectLater(
          creds.requirePersonToken(forge, bob, workspaceId: 'ws1'),
          throwsA(
            isA<NeedsSignInException>().having(
              (e) => e.lane,
              'lane',
              forge.wire,
            ),
          ),
        );
      }
    });

    test(
      'work with no person behind it never gets a person\'s token',
      () async {
        // GitLab/Bitbucket automation uses the repository's automation token
        // (ForgeAutomationTokens), never a member's, the owner's or the
        // environment's.
        final creds = build();
        await creds.setToken(ForgeHost.gitlab, 'alice-gl', userId: alice);
        await creds.setToken(
          ForgeHost.bitbucket,
          'alice@example.com:bb-token',
          userId: alice,
        );
        for (final forge in [ForgeHost.gitlab, ForgeHost.bitbucket]) {
          expect(await creds.tokenFor(forge, workspaceId: 'ws1'), isNull);
          expect(await creds.tokenFor(forge), isNull);
        }
      },
    );

    test('a Bitbucket access token is refused as a person\'s own', () async {
      final creds = build();
      await expectLater(
        creds.setToken(ForgeHost.bitbucket, 'ATCTT3xFfGN0bare', userId: alice),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('API token'),
          ),
        ),
      );
      expect(await users.forgeToken(alice, ForgeHost.bitbucket), isNull);
    });

    test('a Bitbucket API token stores who it belongs to', () async {
      final creds = build(
        viewerProbe: (forge, token) async => forge == ForgeHost.bitbucket
            ? (login: 'jdoe', id: '557057:abc')
            : null,
      );
      final result = await creds.setToken(
        ForgeHost.bitbucket,
        'jdoe@example.com:ATATT3x',
        userId: alice,
      );
      expect(result.status, ForgeConnectionStatus.connected);
      expect(result.username, 'jdoe');
      final stored = await users.forgeToken(alice, ForgeHost.bitbucket);
      expect(stored?.accountLogin, 'jdoe');
      expect(stored?.accountId, '557057:abc');
      expect(
        await creds.viewerLogin(ForgeHost.bitbucket, userId: alice),
        'jdoe',
      );
    });

    test('viewerAccount answers the Bitbucket nickname and account_id; a '
        'GitLab token stored without an id is probed for one', () async {
      var probes = 0;
      final creds = build(
        viewerProbe: (forge, token) async {
          probes++;
          return switch (forge) {
            ForgeHost.bitbucket => (login: 'jdoe', id: '557057:abc'),
            ForgeHost.gitlab => (login: 'gl-jdoe', id: '42'),
            _ => null,
          };
        },
      );
      await creds.setToken(
        ForgeHost.bitbucket,
        'jdoe@example.com:ATATT3x',
        userId: alice,
      );
      probes = 0;
      expect(await creds.viewerAccount(ForgeHost.bitbucket, userId: alice), (
        login: 'jdoe',
        id: '557057:abc',
      ));
      expect(probes, 0, reason: 'the stored credential carries both');
      await users.setForgeToken(
        alice,
        ForgeHost.gitlab,
        const ProviderToken(accessToken: 'glpat', accountLogin: 'gl-jdoe'),
      );
      expect(await creds.viewerAccount(ForgeHost.gitlab, userId: alice), (
        login: 'gl-jdoe',
        id: '42',
      ));
      expect(await creds.viewerAccount(ForgeHost.gitlab, userId: bob), isNull);
      expect(await creds.viewerAccount(ForgeHost.gitlab), isNull);
    });

    test('the local pseudo-forge never resolves a credential', () async {
      final creds = build();
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

    test('a lapse marker that cannot be written is logged without the '
        'error\'s text', () async {
      final lines = <String>[];
      final previousSink = CcHostLog.sink;
      CcHostLog.sink = (level, message, [error, stackTrace]) =>
          lines.add(message);
      addTearDown(() => CcHostLog.sink = previousSink);
      final failing = _FailingLapse(secrets);
      final creds = ForgeCredentials(users: failing);
      await failing.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          const RefreshRejected();

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(lines.join('\n'), contains('FileSystemException'));
      expect(lines.join('\n'), isNot(contains('ghu_leaked')));
      expect(lines.join('\n'), isNot(contains('/secret/path')));
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

    test('a renewed own-App pair whose write fails is kept, served and '
        'written on the next use', () async {
      final lines = <String>[];
      final previousSink = CcHostLog.sink;
      CcHostLog.sink = (level, message, [error, stackTrace]) =>
          lines.add(message);
      addTearDown(() => CcHostLog.sink = previousSink);
      final flaky = _FlakyWrites(secrets);
      final creds = ForgeCredentials(users: flaky);
      await flaky.setForgeToken(alice, ForgeHost.github, expired());
      var refreshes = 0;
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async {
        refreshes++;
        // GitHub spends the stored refresh token here: only the new pair
        // can ever be renewed again.
        return Refreshed(_githubSignIn('ghu_fresh', refresh: 'ghr_next'));
      };
      flaky.failNext = true;

      expect(
        await creds.tokenFor(ForgeHost.github, userId: alice),
        'ghu_fresh',
      );
      expect(
        (await flaky.forgeToken(alice, ForgeHost.github))?.refreshToken,
        'ghr_refresh',
        reason: 'the write failed',
      );
      expect(
        lines.where((l) => l.contains('"event":"grant.persist_failed"')),
        [contains('"kept_in_memory":true')],
      );
      expect(lines.join(), isNot(contains('ghr_next')));

      // The next use writes the kept pair instead of spending the dead one.
      expect(
        await creds.tokenFor(ForgeHost.github, userId: alice),
        'ghu_fresh',
      );
      expect(refreshes, 1);
      expect(
        (await flaky.forgeToken(alice, ForgeHost.github))?.refreshToken,
        'ghr_next',
      );
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
      accountId: '583231',
    );

    test('a seal minted for another install id reads as signed out', () async {
      final creds = build()
        ..currentSealInstallId = (origin, {workspaceId}) async => 'inst-2';
      await users.setForgeToken(alice, ForgeHost.github, sealed());

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('a seal for a Connect this server no longer uses reads as signed '
        'out but survives switching back', () async {
      final creds = build()
        ..currentSealInstallId = (origin, {workspaceId}) async => null;
      await users.setForgeToken(alice, ForgeHost.github, sealed());

      expect(await creds.tokenFor(ForgeHost.github, userId: alice), isNull);
      expect(await users.forgeToken(alice, ForgeHost.github), isNotNull);
    });

    test('the access token of a seal lives in memory only', () async {
      final creds = build()
        ..currentSealInstallId = (origin, {workspaceId}) async => 'inst-1';
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
      final creds = build()
        ..currentSealInstallId = (origin, {workspaceId}) async => 'inst-1';
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
      expect(connections.every((c) => !c.isUsable), isTrue);
      expect(
        connections.every(
          (c) => c.status == ForgeConnectionStatus.notConnected,
        ),
        isTrue,
      );
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

      expect(byForge[ForgeHost.gitlab]!.isUsable, isTrue);
      expect(byForge[ForgeHost.github]!.isUsable, isFalse);
      expect(byForge[ForgeHost.bitbucket]!.isUsable, isFalse);
    });

    test('a stored account name is reported without a probe', () async {
      var probes = 0;
      final creds = build(
        viewerProbe: (forge, token) async {
          probes++;
          return (login: 'probed', id: '1');
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
      expect(gh.status, ForgeConnectionStatus.connected);
      expect(gh.scope, ForgeCredentialScope.global);
      expect(gh.username, 'octocat');
      expect(gh.accountId, '583231');
      expect(gh.toJson()['account_id'], '583231');
      expect(gh.source, ForgeCredentialSource.oauth);
      expect(probes, 0);
    });

    test('without a person GitHub reports disconnected', () async {
      final creds = build();
      final gh = (await creds.connections()).firstWhere(
        (c) => c.forge == ForgeHost.github,
      );
      expect(gh.isUsable, isFalse);
    });
  });

  group('setToken probes the new token', () {
    test('resolves the viewer and caches it', () async {
      var probes = 0;
      final creds = build(
        viewerProbe: (forge, token) async {
          probes++;
          return (login: 'resolved-user', id: '7');
        },
      );
      final result = await creds.setToken(
        ForgeHost.gitlab,
        'gl',
        userId: alice,
      );
      expect(result.isUsable, isTrue);
      expect(result.username, 'resolved-user');
      expect(result.accountId, '7');
      expect(
        await creds.viewerLogin(ForgeHost.gitlab, userId: alice),
        'resolved-user',
      );
      expect(probes, 1);
    });

    test('a token the forge does not answer for is refused, never stored '
        'as connected', () async {
      final creds = build(viewerProbe: (forge, token) async => null);
      await expectLater(
        creds.setToken(ForgeHost.gitlab, 'bad', userId: alice),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'person_token.rejected',
          ),
        ),
      );
      expect(await users.forgeToken(alice, ForgeHost.gitlab), isNull);
    });

    test('changing a token invalidates the cached identity', () async {
      var next = 'first';
      final creds = build(
        viewerProbe: (forge, token) async => (login: next, id: next),
      );
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
        viewerProbe: (forge, token) async => token == 'alice-token'
            ? (login: 'alice-gl', id: '1')
            : (login: 'bob-gl', id: '2'),
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

  group('connection status', () {
    ProviderToken expired() => _githubSignIn(
      'ghu_stale',
      login: 'octocat',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    );
    ProviderToken sealed({String installId = 'inst-1'}) => ProviderToken(
      seal: 'sealed-blob',
      sealInstallId: installId,
      connectOrigin: 'https://connect.example',
      source: ForgeCredentialSource.connect,
      accountLogin: 'octocat',
      accountId: '583231',
    );

    Future<ForgeConnection> github(
      ForgeCredentials creds, {
      String? workspaceId,
    }) => creds.connection(
      ForgeHost.github,
      userId: alice,
      workspaceId: workspaceId,
    );

    test('a parked seal reads paused, keeping the account', () async {
      final creds = build()
        ..currentSealInstallId = (origin, {workspaceId}) async => null;
      await users.setForgeToken(alice, ForgeHost.github, sealed());

      final c = await github(creds);
      expect(c.status, ForgeConnectionStatus.paused);
      expect(c.isUsable, isFalse);
      expect(c.username, 'octocat');
      expect(c.accountId, '583231');
      expect(await users.forgeToken(alice, ForgeHost.github), isNotNull);
    });

    test('a refresh outage reads unreachable and keeps the grant', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          const RefreshUnavailable();

      final c = await github(creds);
      expect(c.status, ForgeConnectionStatus.unreachable);
      expect(c.username, 'octocat');
    });

    test('a refused refresh reads needs_sign_in until a new sign-in', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          const RefreshRejected();

      final lapsed = await github(creds);
      expect(lapsed.status, ForgeConnectionStatus.needsSignIn);
      expect(lapsed.username, 'octocat');
      expect(await users.forgeToken(alice, ForgeHost.github), isNull);
      // Still lapsed on the next read: the grant is gone, not forgotten.
      expect((await github(creds)).status, ForgeConnectionStatus.needsSignIn);

      await creds.storeSignIn(
        ForgeHost.github,
        alice,
        _githubSignIn('ghu_new', login: 'octocat'),
      );
      expect((await github(creds)).status, ForgeConnectionStatus.connected);
    });

    test('a seal for another install identity reads needs_sign_in', () async {
      final creds = build()
        ..currentSealInstallId = (origin, {workspaceId}) async => 'inst-2';
      await users.setForgeToken(alice, ForgeHost.github, sealed());

      expect((await github(creds)).status, ForgeConnectionStatus.needsSignIn);
    });

    test('disconnecting a lapsed sign-in reads not_connected', () async {
      final creds = build();
      await users.setForgeToken(alice, ForgeHost.github, expired());
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          const RefreshRejected();
      expect((await github(creds)).status, ForgeConnectionStatus.needsSignIn);

      await creds.clearToken(ForgeHost.github, userId: alice);
      expect((await github(creds)).status, ForgeConnectionStatus.notConnected);
    });

    test(
      'a lapsed sign-in still reads needs_sign_in after a restart',
      () async {
        final creds = build();
        await users.setForgeToken(alice, ForgeHost.github, expired());
        creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
            const RefreshRejected();
        expect((await github(creds)).status, ForgeConnectionStatus.needsSignIn);

        // A new process: fresh stores over the same secrets file.
        users = UserCredentialsStore(FileSecretsStore(dataDir: dir.path));
        final restarted = build();
        final after = await github(restarted);
        expect(after.status, ForgeConnectionStatus.needsSignIn);
        expect(after.username, 'octocat');

        await restarted.storeSignIn(
          ForgeHost.github,
          alice,
          _githubSignIn('ghu_new', login: 'octocat'),
        );
        expect(
          (await github(restarted)).status,
          ForgeConnectionStatus.connected,
        );
        await restarted.clearToken(ForgeHost.github, userId: alice);
        expect(
          (await github(restarted)).status,
          ForgeConnectionStatus.notConnected,
        );
      },
    );

    test('a workspace slot reset forgets its lapse markers', () async {
      final creds = build(slotOwners: {'own'});
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        expired(),
        workspaceId: 'own',
      );
      creds.refreshUserToken = (userId, forge, stale, {workspaceId}) async =>
          const RefreshRejected();
      expect(
        (await github(creds, workspaceId: 'own')).status,
        ForgeConnectionStatus.needsSignIn,
      );

      await creds.clearWorkspaceSlot(ForgeHost.github, 'own');
      expect(
        (await github(creds, workspaceId: 'own')).status,
        ForgeConnectionStatus.notConnected,
      );
    });

    test('scope follows the slot the workspace owns', () async {
      final creds = build(slotOwners: {'own'});
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_g', login: 'global'),
      );
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_w', login: 'slot'),
        workspaceId: 'own',
      );

      final shared = await github(creds, workspaceId: 'shared');
      expect(shared.scope, ForgeCredentialScope.global);
      expect(shared.username, 'global');
      final owned = await github(creds, workspaceId: 'own');
      expect(owned.scope, ForgeCredentialScope.workspace);
      expect(owned.username, 'slot');
    });

    test('the wire carries status and scope, never the old flags', () async {
      final json = const ForgeConnection(
        forge: ForgeHost.github,
        status: ForgeConnectionStatus.paused,
        scope: ForgeCredentialScope.workspace,
      ).toJson();
      expect(json['status'], 'paused');
      expect(json['scope'], 'workspace');
      expect(json.containsKey('authenticated'), isFalse);
      expect(json.containsKey('needs_sign_in'), isFalse);
    });
  });

  group('token forges: one credential per person, in every workspace', () {
    test('a pasted token is read in every workspace and never from a '
        'workspace slot', () async {
      final creds = build(slotOwners: {'own'});
      await creds.setToken(ForgeHost.gitlab, 'mine', userId: alice);
      for (final workspaceId in ['own', 'shared', null]) {
        expect(
          await creds.tokenFor(
            ForgeHost.gitlab,
            userId: alice,
            workspaceId: workspaceId,
          ),
          'mine',
          reason: '$workspaceId',
        );
        expect(
          (await creds.connection(
            ForgeHost.gitlab,
            userId: alice,
            workspaceId: workspaceId,
          )).scope,
          ForgeCredentialScope.global,
          reason: '$workspaceId',
        );
      }
      expect(await creds.slotFor(ForgeHost.gitlab, workspaceId: 'own'), isNull);
      expect(
        await creds.slotFor(ForgeHost.bitbucket, workspaceId: 'own'),
        isNull,
      );
      expect(
        await users.forgeToken(alice, ForgeHost.gitlab, workspaceId: 'own'),
        isNull,
      );
    });

    test('a token sitting in a workspace slot is not a credential', () async {
      final creds = build(slotOwners: {'ws'});
      await users.setForgeToken(
        alice,
        ForgeHost.gitlab,
        const ProviderToken(accessToken: 'stray'),
        workspaceId: 'ws',
      );
      expect(
        await creds.tokenFor(ForgeHost.gitlab, userId: alice, workspaceId: 'ws'),
        isNull,
      );
      expect(
        (await creds.connection(
          ForgeHost.gitlab,
          userId: alice,
          workspaceId: 'ws',
        )).status,
        ForgeConnectionStatus.notConnected,
      );
    });

    test('a new token replaces the one before it', () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'first', userId: alice);
      await creds.setToken(ForgeHost.gitlab, 'second', userId: alice);
      expect(
        await creds.tokenFor(ForgeHost.gitlab, userId: alice, workspaceId: 'ws'),
        'second',
      );
    });

    test('clearing from any workspace clears the one token', () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'mine', userId: alice);
      expect(
        await creds.clearToken(
          ForgeHost.gitlab,
          userId: alice,
          workspaceId: 'ws',
        ),
        ForgeCredentialScope.global,
      );
      expect(await creds.tokenFor(ForgeHost.gitlab, userId: alice), isNull);
      expect(
        await creds.clearToken(ForgeHost.gitlab, userId: alice),
        isNull,
      );
    });
  });

  group('workspace slot reset', () {
    test('clearing a workspace slot removes only that slot', () async {
      final creds = build(slotOwners: {'ws'});
      await users.setForgeToken(alice, ForgeHost.github, _githubSignIn('g'));
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_a'),
        workspaceId: 'ws',
      );
      await users.setForgeToken(
        bob,
        ForgeHost.github,
        _githubSignIn('ghu_b'),
        workspaceId: 'ws',
      );
      await users.setForgeToken(
        bob,
        ForgeHost.github,
        _githubSignIn('ghu_other'),
        workspaceId: 'ws-2',
      );
      final seen = <ForgeCredentialChange>[];
      creds.changes.listen(seen.add);

      final removed = await creds.clearWorkspaceSlot(ForgeHost.github, 'ws');
      expect(removed.map((r) => r.userId).toSet(), {alice, bob});
      expect(
        await users.forgeToken(alice, ForgeHost.github, workspaceId: 'ws'),
        isNull,
      );
      expect(await users.forgeToken(alice, ForgeHost.github), isNotNull);
      expect(
        await users.forgeToken(bob, ForgeHost.github, workspaceId: 'ws-2'),
        isNotNull,
      );
      expect(seen.map((c) => c.workspaceId).toSet(), {'ws'});
      expect(
        (await creds.connection(
          ForgeHost.github,
          userId: alice,
          workspaceId: 'ws',
        )).status,
        ForgeConnectionStatus.notConnected,
      );
    });

    test('a filter keeps the grants it rejects', () async {
      final creds = build(slotOwners: {'ws'});
      await users.setForgeToken(
        alice,
        ForgeHost.github,
        _githubSignIn('ghu_a'),
        workspaceId: 'ws',
      );
      final removed = await creds.clearWorkspaceSlot(
        ForgeHost.github,
        'ws',
        where: (token) => token.appId != 'Iv1.app',
      );
      expect(removed, isEmpty);
      expect(
        await users.forgeToken(alice, ForgeHost.github, workspaceId: 'ws'),
        isNotNull,
      );
    });
  });
}

/// A store whose next [setForgeToken] throws, once.
class _FlakyWrites extends UserCredentialsStore {
  _FlakyWrites(super.secrets);

  bool failNext = false;

  @override
  Future<void> setForgeToken(
    String userId,
    ForgeHost forge,
    ProviderToken token, {
    String? workspaceId,
  }) async {
    if (failNext) {
      failNext = false;
      throw const FileSystemException('disk full');
    }
    return super.setForgeToken(userId, forge, token, workspaceId: workspaceId);
  }
}

/// A store that cannot write the lapse marker, with an error whose text
/// carries a path and token-shaped text.
class _FailingLapse extends UserCredentialsStore {
  _FailingLapse(super.secrets);

  @override
  Future<void> markForgeLapsed(
    String userId,
    ForgeHost forge,
    String accountLogin, {
    String? workspaceId,
  }) async => throw const FileSystemException(
    'cannot write ghu_leaked',
    '/secret/path/credentials.json',
  );
}
