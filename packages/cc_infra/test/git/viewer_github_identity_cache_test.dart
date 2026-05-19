import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _NullDio implements Dio {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeContentClient extends GitHubContentClient {
  _FakeContentClient() : super(_NullDio());

  /// The viewer served on the next call; null answers "no viewer".
  GitHubUser? viewer = const GitHubUser(login: 'viewer', avatarUrl: '');

  /// The teams served on the next call.
  List<({String org, String slug})> viewerTeams = [];

  /// When set, the next call throws it instead of answering.
  Object? failure;

  int userCalls = 0;
  int teamCalls = 0;

  @override
  Future<GitHubUser?> getAuthenticatedUser({CancelToken? cancelToken}) async {
    userCalls++;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return viewer;
  }

  @override
  Future<List<({String org, String slug})>> listViewerTeams({
    CancelToken? cancelToken,
  }) async {
    teamCalls++;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return viewerTeams;
  }
}

void main() {
  late _FakeContentClient content;
  late DateTime now;
  late ViewerGitHubIdentityCache cache;

  setUp(() {
    content = _FakeContentClient();
    now = DateTime(2026, 8, 17, 12);
    cache = ViewerGitHubIdentityCache(
      content,
      retryAfter: const Duration(minutes: 1),
      now: () => now,
    );
  });

  group('user', () {
    test('caches a success for the process lifetime', () async {
      expect((await cache.user())?.login, 'viewer');
      expect((await cache.user())?.login, 'viewer');
      expect(content.userCalls, 1, reason: 'a hit never refetches');
    });

    test('coalesces concurrent callers onto one request', () async {
      final results = await Future.wait([cache.user(), cache.user()]);

      expect(results.map((u) => u?.login), ['viewer', 'viewer']);
      expect(content.userCalls, 1);
    });

    // The regression that emptied the inbox: a single GitHub 503 used to latch
    // the lookup off for the whole server process, so `github.currentUser`
    // answered null — successfully — until a restart, and every inbox
    // classified against an empty login came back "all caught up".
    test('retries a failure once the cool-down elapses', () async {
      content.failure = StateError('503');
      expect(await cache.user(), isNull);
      expect(content.userCalls, 1);

      // Inside the window: answered from the cool-down, no request.
      now = now.add(const Duration(seconds: 30));
      expect(await cache.user(), isNull);
      expect(content.userCalls, 1, reason: 'the cool-down bounds the retry');

      // Past the window, with GitHub healthy again.
      now = now.add(const Duration(seconds: 31));
      content.failure = null;
      expect((await cache.user())?.login, 'viewer');
      expect(content.userCalls, 2);

      // And the recovered identity is cached like any other success.
      expect((await cache.user())?.login, 'viewer');
      expect(content.userCalls, 2);
    });

    test('retries a token-less "no viewer" answer too', () async {
      content.viewer = null;
      expect(await cache.user(), isNull);

      now = now.add(const Duration(minutes: 2));
      content.viewer = const GitHubUser(login: 'late', avatarUrl: '');
      expect(
        (await cache.user())?.login,
        'late',
        reason: 'a token added after boot must not need a restart',
      );
    });

    test('an empty login is not accepted as an identity', () async {
      content.viewer = const GitHubUser(login: '', avatarUrl: '');
      expect(await cache.user(), isNull);
    });
  });

  group('teams', () {
    test('caches an empty membership as a success', () async {
      expect(await cache.teams(), isEmpty);
      expect(await cache.teams(), isEmpty);
      expect(
        content.teamCalls,
        1,
        reason: 'belonging to no team is an answer, not a failure',
      );
    });

    test('lower-cases orgs and slugs', () async {
      content.viewerTeams = [
        (org: 'Google', slug: 'Google-Cloud-A'),
        (org: 'Google', slug: 'Google-Cloud-B'),
      ];

      expect(await cache.teams(), {
        'google': {'google-cloud-a', 'google-cloud-b'},
      });
    });

    test('retries a failure once the cool-down elapses', () async {
      content.failure = StateError('503');
      expect(await cache.teams(), isNull);
      expect(content.teamCalls, 1);

      now = now.add(const Duration(seconds: 30));
      expect(await cache.teams(), isNull);
      expect(content.teamCalls, 1);

      now = now.add(const Duration(seconds: 31));
      content.failure = null;
      content.viewerTeams = [(org: 'acme', slug: 'core')];
      expect(await cache.teams(), {
        'acme': {'core'},
      });
    });
  });
}
