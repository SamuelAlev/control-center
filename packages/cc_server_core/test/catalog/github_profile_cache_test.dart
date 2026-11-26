import 'dart:async';

import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_server_core/src/catalog/github_profile_cache.dart';
import 'package:test/test.dart';

Repo _repo(String id, String owner, String name) => Repo(
  id: id,
  name: '$owner/$name',
  path: '/repos/$owner/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

GitHubProfileActivity _activity(int open) => GitHubProfileActivity(
  metrics: GitHubProfileMetrics(
    open: open,
    draft: 0,
    merged: 0,
    closed: 0,
    analyzedPullRequests: 0,
    resultsTruncated: false,
  ),
  repos: const [],
);

GitHubTeamProfile _team(String slug) => GitHubTeamProfile(
  organization: 'acme',
  slug: slug,
  name: slug,
  avatarUrl: '',
  url: '',
  members: [
    GitHubTeamMember(login: 'ada', name: 'Ada', avatarUrl: ''),
  ],
);

void main() {
  group('GitHubProfileCache', () {
    test('returns cached entry within TTL and reloads after expiry', () async {
      var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final cache = GitHubProfileCache(
        userProfileTtl: const Duration(minutes: 5),
        now: () => now,
      );
      var loads = 0;

      final first = await cache.getUserProfile(
        actingUserId: 'u1',
        login: 'Ada',
        load: () async {
          loads++;
          return {'login': 'ada', 'call': loads};
        },
      );
      now = now.add(const Duration(minutes: 4));
      final second = await cache.getUserProfile(
        actingUserId: 'u1',
        login: 'ada',
        load: () async {
          loads++;
          return {'login': 'ada', 'call': loads};
        },
      );
      expect(loads, 1);
      expect(second, same(first));

      now = now.add(const Duration(minutes: 2));
      final third = await cache.getUserProfile(
        actingUserId: 'u1',
        login: 'ada',
        load: () async {
          loads++;
          return {'login': 'ada', 'call': loads};
        },
      );
      expect(loads, 2);
      expect(third?['call'], 2);
    });

    test('coalesces concurrent calls for the same key', () async {
      final cache = GitHubProfileCache();
      final completer = Completer<GitHubTeamProfile?>();
      var loads = 0;

      final f1 = cache.getTeamProfile(
        actingUserId: 'u1',
        organization: 'acme',
        slug: 'core',
        load: () {
          loads++;
          return completer.future;
        },
      );
      final f2 = cache.getTeamProfile(
        actingUserId: 'u1',
        organization: 'ACME',
        slug: 'CORE',
        load: () {
          loads++;
          return completer.future;
        },
      );

      expect(loads, 1);
      completer.complete(_team('core'));
      final results = await Future.wait([f1, f2]);
      expect(results[0]?.slug, 'core');
      expect(results[1]?.slug, 'core');
    });

    test('force: true bypasses cache and overwrites stored value', () async {
      final cache = GitHubProfileCache();
      var loads = 0;

      final first = await cache.getProfileActivity(
        workspaceId: 'ws-1',
        actingUserId: 'u1',
        targetKey: 'user:ada',
        visibleRepos: [_repo('r1', 'acme', 'app')],
        load: () async => _activity(++loads),
      );
      final forced = await cache.getProfileActivity(
        workspaceId: 'ws-1',
        actingUserId: 'u1',
        targetKey: 'user:ada',
        visibleRepos: [_repo('r1', 'acme', 'app')],
        force: true,
        load: () async => _activity(++loads),
      );
      final after = await cache.getProfileActivity(
        workspaceId: 'ws-1',
        actingUserId: 'u1',
        targetKey: 'user:ada',
        visibleRepos: [_repo('r1', 'acme', 'app')],
        load: () async => _activity(++loads),
      );

      expect(loads, 2);
      expect(first.metrics.open, 1);
      expect(forced.metrics.open, 2);
      expect(after.metrics.open, 2);
    });

    test(
      'isolates entries by actingUserId, workspaceId, and visibleRepos',
      () async {
        final cache = GitHubProfileCache();
        var loads = 0;
        final repoA = _repo('r1', 'acme', 'app');
        final repoB = _repo('r2', 'acme', 'api');

        await cache.getProfileActivity(
          workspaceId: 'ws-1',
          actingUserId: 'u1',
          targetKey: 'user:ada',
          visibleRepos: [repoA],
          load: () async => _activity(++loads),
        );
        await cache.getProfileActivity(
          workspaceId: 'ws-1',
          actingUserId: 'u2',
          targetKey: 'user:ada',
          visibleRepos: [repoA],
          load: () async => _activity(++loads),
        );
        await cache.getProfileActivity(
          workspaceId: 'ws-2',
          actingUserId: 'u1',
          targetKey: 'user:ada',
          visibleRepos: [repoA],
          load: () async => _activity(++loads),
        );
        await cache.getProfileActivity(
          workspaceId: 'ws-1',
          actingUserId: 'u1',
          targetKey: 'user:ada',
          visibleRepos: [repoA, repoB],
          load: () async => _activity(++loads),
        );
        // Same repo set in a different order hits the existing entry.
        await cache.getProfileActivity(
          workspaceId: 'ws-1',
          actingUserId: 'u1',
          targetKey: 'user:ada',
          visibleRepos: [repoB, repoA],
          load: () async => _activity(++loads),
        );

        expect(loads, 4);
      },
    );

    test(
      'invalidateUser drops entries and stops pre-invalidation in-flight write',
      () async {
        final cache = GitHubProfileCache();
        final staleCompleter = Completer<GitHubProfileActivity>();
        var loads = 0;

        final staleFuture = cache.getProfileActivity(
          workspaceId: 'ws-1',
          actingUserId: 'u1',
          targetKey: 'user:ada',
          visibleRepos: [_repo('r1', 'acme', 'app')],
          load: () {
            loads++;
            return staleCompleter.future;
          },
        );

        cache.invalidateUser('u1', workspaceId: 'ws-1');
        staleCompleter.complete(_activity(1));
        await staleFuture;

        final fresh = await cache.getProfileActivity(
          workspaceId: 'ws-1',
          actingUserId: 'u1',
          targetKey: 'user:ada',
          visibleRepos: [_repo('r1', 'acme', 'app')],
          load: () async {
            loads++;
            return _activity(9);
          },
        );

        expect(loads, 2);
        expect(fresh.metrics.open, 9);
      },
    );

    test('does not cache errors or null profiles', () async {
      final cache = GitHubProfileCache();
      var errorLoads = 0;

      await expectLater(
        cache.getUserProfile(
          actingUserId: 'u1',
          login: 'ada',
          load: () async {
            errorLoads++;
            throw StateError('boom');
          },
        ),
        throwsStateError,
      );

      final nullResult = await cache.getUserProfile(
        actingUserId: 'u1',
        login: 'ada',
        load: () async {
          errorLoads++;
          return null;
        },
      );
      expect(nullResult, isNull);

      final realResult = await cache.getUserProfile(
        actingUserId: 'u1',
        login: 'ada',
        load: () async {
          errorLoads++;
          return {'login': 'ada'};
        },
      );
      expect(errorLoads, 3);
      expect(realResult?['login'], 'ada');
    });
  });
}
