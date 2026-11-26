import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Never touches the network: the fake below overrides every method under
/// test, so this client only satisfies the constructor.
class _NullRhttpClient implements RhttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGitHubGraphQLClient extends GitHubGraphQLClient {
  FakeGitHubGraphQLClient() : super(_NullRhttpClient());

  /// The sweep served to the poller; replaced by tests between polls.
  GitHubViewerActivity activity = const GitHubViewerActivity();

  /// How many times the search was actually run. The readiness gate exists to
  /// keep this at zero, so counting is the only way to assert it.
  int searchCalls = 0;

  /// The `since` each call received, so the watermark can be asserted.
  final List<DateTime?> sinceArgs = [];

  /// Thrown instead of serving [activity], to stand in for GitHub's answer.
  Object? throwOnSearch;

  @override
  Future<GitHubViewerActivity> searchViewerPullRequestActivity({
    DateTime? since,
    CancelToken? cancelToken,
  }) async {
    searchCalls++;
    sinceArgs.add(since);
    final failure = throwOnSearch;
    if (failure != null) {
      throw failure;
    }
    return activity;
  }
}

class FakeGitHubApiClient implements GitHubApiClient {
  FakeGitHubApiClient(this.graphql);

  @override
  final FakeGitHubGraphQLClient graphql;

  @override
  GitHubContentClient get content => throw UnimplementedError();

  @override
  GitHubPrClient get pr => throw UnimplementedError();
}

/// In-memory stand-in for the persisted dedupe store.
class MemDedupeStore {
  String? stored;
  int saves = 0;

  Future<String?> load() async => stored;

  Future<void> save(String state) async {
    saves++;
    stored = state;
  }
}

class FakeViewerCommentFetchPort implements ViewerCommentFetchPort {
  final Map<String, List<GitHubIssueComment>> issueComments = {};
  final Map<String, List<GitHubReviewComment>> reviewComments = {};
  final Map<String, List<GitHubReviewThread>> reviewThreads = {};

  static String _key(String owner, String repo, int number) =>
      '$owner/$repo#$number';

  void setIssueComments(
    String owner,
    String repo,
    int number,
    List<GitHubIssueComment> comments,
  ) => issueComments[_key(owner, repo, number)] = comments;

  void setReviewComments(
    String owner,
    String repo,
    int number,
    List<GitHubReviewComment> comments,
  ) => reviewComments[_key(owner, repo, number)] = comments;

  void setReviewThreads(
    String owner,
    String repo,
    int number,
    List<GitHubReviewThread> threads,
  ) => reviewThreads[_key(owner, repo, number)] = threads;

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int number,
  ) async => issueComments[_key(owner, repo, number)] ?? const [];

  @override
  Future<List<GitHubReviewComment>> listReviewComments(
    String owner,
    String repo,
    int number,
  ) async => reviewComments[_key(owner, repo, number)] ?? const [];

  @override
  Future<List<GitHubReviewThread>> listReviewThreads(
    String owner,
    String repo,
    int number,
  ) async => reviewThreads[_key(owner, repo, number)] ?? const [];
}

GitHubViewerPr _pr({
  String repo = 'o/r1',
  int number = 7,
  String title = 'Fix things',
  DateTime? updatedAt,
  String? mergedByLogin,
}) => GitHubViewerPr(
  repoFullName: repo,
  number: number,
  title: title,
  updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1),
  mergedByLogin: mergedByLogin,
);

void main() {
  late FakeGitHubGraphQLClient graphql;
  late FakeGitHubApiClient client;
  late DomainEventBus bus;
  late PrChangeSignals signals;
  late List<String> touched;
  late DateTime clock;
  late GitHubViewerActivityPollingService service;

  GitHubViewerActivityPollingService buildService({
    MemDedupeStore? store,
    Future<bool> Function()? shouldPoll,
    Set<String> linkedRepos = const {'o/r1'},
    String? viewerLogin,
    ViewerCommentFetchPort? commentFetch,
    String? forUserId,
  }) => GitHubViewerActivityPollingService(
    githubClient: client,
    eventBus: bus,
    changeSignals: signals,
    shouldPoll: shouldPoll,
    viewerLogin: viewerLogin == null ? null : () async => viewerLogin,
    commentFetch: commentFetch,
    forUserId: forUserId,
    workspacesForRepo: (repoFullName) async =>
        linkedRepos.contains(repoFullName) ? ['ws1'] : const [],
    onWorkspaceTouched: touched.add,
    loadDedupeState: store?.load,
    saveDedupeState: store?.save,
    now: () => clock,
  );

  setUp(() {
    graphql = FakeGitHubGraphQLClient();
    client = FakeGitHubApiClient(graphql);
    bus = DomainEventBus();
    signals = PrChangeSignals();
    touched = [];
    clock = DateTime.utc(2026, 1, 1, 12);
    service = buildService();
  });

  tearDown(() {
    service.dispose();
    signals.dispose();
    bus.dispose();
  });

  Future<void> pump() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('pending-review set', () {
    test('the first poll is a baseline — the backlog never notifies', () async {
      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7), _pr(number: 8)],
      );
      await service.pollOnce();
      await pump();

      expect(events, isEmpty);
      expect(touched, isEmpty, reason: 'no freshness nudges on the baseline');
      await sub.cancel();
    });

    test(
      'a newly pending review notifies, with a signal and a nudge',
      () async {
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 7)],
        );
        await service.pollOnce();

        final events = <PrReviewRequested>[];
        final sub = bus.on<PrReviewRequested>().listen(events.add);
        final received = <PrChangeSignal>[];
        final sigSub = signals
            .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
            .listen(received.add);

        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 7), _pr(number: 9)],
        );
        await service.pollOnce();
        await pump();

        expect(events, hasLength(1), reason: 'only the new one is news');
        expect(events.single.workspaceId, 'ws1');
        expect(events.single.repoOwner, 'o');
        expect(events.single.repoName, 'r1');
        expect(events.single.prNumber, 9);
        expect(received.map((s) => s.prNumber), containsAll([7, 9]));
        expect(touched, contains('ws1'));
        await sub.cancel();
        await sigSub.cancel();
      },
    );

    test('staying pending across sweeps is silent', () async {
      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7)],
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      // Three more sweeps with the same PR still outstanding, each with a
      // fresh `updatedAt` (a commit bump).
      for (var i = 1; i <= 3; i++) {
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [
            _pr(number: 7, updatedAt: DateTime.utc(2026, 1, i)),
          ],
        );
        await service.pollOnce();
      }
      await pump();

      expect(events, isEmpty);
      await sub.cancel();
    });

    test(
      'leaving the pending set is silent, and a re-request notifies again',
      () async {
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 7)],
        );
        await service.pollOnce();

        final events = <PrReviewRequested>[];
        final sub = bus.on<PrReviewRequested>().listen(events.add);

        // Reviewed: GitHub drops it from `review-requested:`.
        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();
        expect(
          events,
          isEmpty,
          reason: 'having reviewed is not a notification',
        );

        // Re-requested later.
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 7)],
        );
        await service.pollOnce();
        await pump();

        expect(events.map((e) => e.prNumber), [7]);
        await sub.cancel();
      },
    );

    test('a draft marked ready is a genuine transition', () async {
      // `draft:false` means a draft is simply absent from the lane.
      graphql.activity = const GitHubViewerActivity();
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 12, title: 'Was a draft')],
      );
      await service.pollOnce();
      await pump();

      expect(events, hasLength(1));
      expect(events.single.prNumber, 12);
      expect(events.single.prTitle, 'Was a draft');
      await sub.cancel();
    });
  });

  group('mention and merge lanes', () {
    test('a mention notifies exactly once per PR', () async {
      graphql.activity = const GitHubViewerActivity();
      await service.pollOnce();

      final events = <PrMentioned>[];
      final sub = bus.on<PrMentioned>().listen(events.add);

      for (var i = 0; i < 3; i++) {
        graphql.activity = GitHubViewerActivity(mentioned: [_pr(number: 4)]);
        await service.pollOnce();
      }
      await pump();

      expect(events, hasLength(1));
      expect(events.single.prNumber, 4);
      await sub.cancel();
    });

    test('a merged PR notifies exactly once per PR', () async {
      graphql.activity = const GitHubViewerActivity();
      await service.pollOnce();

      final events = <ExternalPrMerged>[];
      final sub = bus.on<ExternalPrMerged>().listen(events.add);

      for (var i = 0; i < 3; i++) {
        graphql.activity = GitHubViewerActivity(merged: [_pr(number: 5)]);
        await service.pollOnce();
      }
      await pump();

      expect(events, hasLength(1));
      expect(events.single.prNumber, 5);
      await sub.cancel();
    });

    test('a merge carries who merged it, unfiltered', () async {
      // The merger rides the event so each CLIENT can drop its own operator's
      // merge. It is deliberately not filtered here: this event reaches every
      // member of the workspace, and one member's merge is news to the rest.
      graphql.activity = const GitHubViewerActivity();
      await service.pollOnce();

      final events = <ExternalPrMerged>[];
      final sub = bus.on<ExternalPrMerged>().listen(events.add);

      graphql.activity = GitHubViewerActivity(
        merged: [_pr(number: 6, mergedByLogin: 'octocat')],
      );
      await service.pollOnce();
      await pump();

      expect(events, hasLength(1));
      expect(events.single.mergedByLogin, 'octocat');
      await sub.cancel();
    });
  });

  group('workspace routing', () {
    test('an unlinked repo notifies nothing and records nothing', () async {
      graphql.activity = const GitHubViewerActivity();
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(repo: 'o/unlinked', number: 3)],
      );
      await service.pollOnce();
      await pump();

      expect(events, isEmpty);
      await sub.cancel();
    });

    test('linking the repo later still delivers the pending review', () async {
      // Nothing linked yet: the PR must NOT be recorded as already seen.
      service.dispose();
      var linked = <String>{};
      service = GitHubViewerActivityPollingService(
        githubClient: client,
        eventBus: bus,
        changeSignals: signals,
        workspacesForRepo: (repo) async =>
            linked.contains(repo) ? ['ws1'] : const [],
        onWorkspaceTouched: touched.add,
        now: () => clock,
      );

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(repo: 'o/late', number: 3)],
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      linked = {'o/late'};
      await service.pollOnce();
      await pump();

      expect(events.map((e) => e.prNumber), [3]);
      await sub.cancel();
    });
  });

  group('freshness signals', () {
    test('re-fire on every updatedAt bump but not on a repeat', () async {
      graphql.activity = const GitHubViewerActivity();
      await service.pollOnce();

      final received = <PrChangeSignal>[];
      final sigSub = signals
          .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
          .listen(received.add);

      final first = _pr(number: 7, updatedAt: DateTime.utc(2026, 1, 2));
      graphql.activity = GitHubViewerActivity(updated: [first]);
      await service.pollOnce();
      // Same updatedAt — already seen, no second signal.
      await service.pollOnce();
      // Bumped.
      graphql.activity = GitHubViewerActivity(
        updated: [_pr(number: 7, updatedAt: DateTime.utc(2026, 1, 3))],
      );
      await service.pollOnce();
      await pump();

      expect(received, hasLength(2));
      await sigSub.cancel();
    });
  });

  group('readiness gate', () {
    test('does not call GitHub while the gate says no', () async {
      service.dispose();
      service = buildService(shouldPoll: () async => false);

      await service.pollOnce();
      await pump();

      expect(graphql.searchCalls, 0);
    });

    test('fails closed when the gate throws', () async {
      service.dispose();
      service = buildService(
        shouldPoll: () async => throw StateError('db down'),
      );

      await service.pollOnce();
      await pump();

      expect(graphql.searchCalls, 0);
    });
  });

  group('failure handling', () {
    test('an auth failure is swallowed and recovers on the next pass', () async {
      graphql.throwOnSearch = const NetworkException(
        'Authentication failed',
        code: 'auth_error',
      );
      await service.pollOnce();
      await pump();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      // The failed pass must not have consumed the baseline: this is still the
      // first successful sweep, so it records silently.
      graphql.throwOnSearch = null;
      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7)],
      );
      await service.pollOnce();
      await pump();
      expect(
        events,
        isEmpty,
        reason: 'the first SUCCESSFUL pass is the baseline',
      );

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7), _pr(number: 8)],
      );
      await service.pollOnce();
      await pump();
      expect(events.map((e) => e.prNumber), [8]);
      await sub.cancel();
    });

    test('a generic failure is swallowed', () async {
      graphql.throwOnSearch = StateError('boom');
      await service.pollOnce();
      await pump();
      expect(graphql.searchCalls, 1);
    });
  });

  group('persistence', () {
    test('a restart does not re-notify a still-pending review', () async {
      final store = MemDedupeStore();
      service.dispose();
      service = buildService(store: store);

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7)],
      );
      await service.pollOnce();
      await pump();
      expect(store.stored, isNotNull);

      // Restart against the same store.
      service.dispose();
      service = buildService(store: store);

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);
      await service.pollOnce();
      await pump();

      expect(events, isEmpty);
      await sub.cancel();
    });

    test(
      'a review that arrived while the server was down is caught up once',
      () async {
        final store = MemDedupeStore();
        service.dispose();
        service = buildService(store: store);
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 7)],
        );
        await service.pollOnce();
        await pump();

        service.dispose();
        service = buildService(store: store);

        final events = <PrReviewRequested>[];
        final sub = bus.on<PrReviewRequested>().listen(events.add);

        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 7), _pr(number: 8)],
        );
        await service.pollOnce();
        await pump();
        expect(events.map((e) => e.prNumber), [8]);

        // And exactly once — a further sweep is silent.
        await service.pollOnce();
        await pump();
        expect(events.map((e) => e.prNumber), [8]);
        await sub.cancel();
      },
    );

    test(
      'a v1 (notification-thread) store is discarded, not misread',
      () async {
        final store = MemDedupeStore()
          ..stored = jsonEncode({
            'v': 1,
            'savedAt': DateTime.utc(2026, 1, 1, 11).toIso8601String(),
            'threads': {
              '9876543210': {'p': true},
            },
          });
        service.dispose();
        service = buildService(store: store);

        final events = <PrReviewRequested>[];
        final sub = bus.on<PrReviewRequested>().listen(events.add);

        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 7)],
        );
        await service.pollOnce();
        await pump();

        expect(
          events,
          isEmpty,
          reason: 'a discarded store means first-run-ever: baseline silently',
        );
        expect(graphql.sinceArgs.single, isNull, reason: 'no watermark to use');
        await sub.cancel();
      },
    );

    test('the persisted watermark anchors the next window', () async {
      final store = MemDedupeStore();
      service.dispose();
      service = buildService(store: store);

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7)],
      );
      await service.pollOnce();
      await pump();
      expect(graphql.sinceArgs.first, isNull);

      clock = clock.add(const Duration(minutes: 1));
      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7), _pr(number: 8)],
      );
      await service.pollOnce();
      await pump();

      // The first sweep's START, less the search-index overlap.
      expect(
        graphql.sinceArgs.last,
        DateTime.utc(2026, 1, 1, 12).subtract(const Duration(minutes: 5)),
      );
    });

    test('the window is clamped when the watermark is stale', () async {
      final store = MemDedupeStore();
      service.dispose();
      service = buildService(store: store);

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7)],
      );
      await service.pollOnce();
      await pump();

      // A long quiet stretch: the watermark is only refreshed periodically.
      clock = clock.add(const Duration(days: 9));
      await service.pollOnce();
      await pump();

      expect(
        graphql.sinceArgs.last,
        clock.subtract(const Duration(hours: 24)),
        reason: 'never look back further than the hard cap',
      );
    });

    test('an unchanged sweep does not rewrite the store', () async {
      final store = MemDedupeStore();
      service.dispose();
      service = buildService(store: store);

      graphql.activity = GitHubViewerActivity(
        reviewRequested: [_pr(number: 7)],
      );
      await service.pollOnce();
      await pump();
      final afterFirst = store.saves;

      clock = clock.add(const Duration(minutes: 1));
      await service.pollOnce();
      await pump();

      expect(
        store.saves,
        afterFirst,
        reason: 'nothing changed, nothing written',
      );

      // ...until the watermark refresh falls due.
      clock = clock.add(const Duration(minutes: 20));
      await service.pollOnce();
      await pump();
      expect(store.saves, greaterThan(afterFirst));
    });
  });

  group('comment lane', () {
    GitHubUser user(String login) =>
        GitHubUser(login: login, avatarUrl: '');

    GitHubReviewComment reviewComment({
      required int id,
      required String login,
      required String body,
      int? inReplyToId,
      String path = 'lib/a.dart',
      int? line = 1,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) => GitHubReviewComment(
      id: id,
      body: body,
      path: path,
      diffHunk: '@@ -1,1 +1,1 @@',
      line: line,
      inReplyToId: inReplyToId,
      user: user(login),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    GitHubIssueComment issueComment({
      required int id,
      required String login,
      required String body,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) => GitHubIssueComment(
      id: id,
      body: body,
      user: user(login),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test(
      'commit push on an old PR does not replay a historical thread reply',
      () async {
        final store = MemDedupeStore();
        final fetch = FakeViewerCommentFetchPort();
        clock = DateTime.utc(2026, 11, 25, 12);
        service.dispose();
        service = buildService(
          store: store,
          linkedRepos: const {'Frontify/ffy-cli'},
          viewerLogin: 'SamuelAlev',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        // Baseline runs without the old quiet PR.
        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();
        final afterBaseline = store.saves;

        final replied = <PrThreadReplied>[];
        final sub = bus.on<PrThreadReplied>().listen(replied.add);

        // Eight days later in comment time, a commit push bumps the PR's
        // updatedAt so GitHub returns it in `activity.updated`.
        clock = clock.add(const Duration(minutes: 1));
        fetch.setReviewComments('Frontify', 'ffy-cli', 482, [
          reviewComment(
            id: 4597663715,
            login: 'SamuelAlev',
            body: 'We had a clean solution',
            path: 'src/features/env/loopback.ts',
            line: 1,
            createdAt: DateTime.utc(2026, 11, 17, 9, 31, 1),
            updatedAt: DateTime.utc(2026, 11, 17, 9, 31, 4),
          ),
          reviewComment(
            id: 4597775539,
            inReplyToId: 4597663715,
            login: 'jcosta33',
            body: 'had some issues, tried to have the agent check',
            path: 'src/features/env/loopback.ts',
            line: 1,
            createdAt: DateTime.utc(2026, 11, 17, 9, 42, 1),
            updatedAt: DateTime.utc(2026, 11, 17, 9, 42, 2),
          ),
        ]);
        fetch.setReviewThreads('Frontify', 'ffy-cli', 482, const [
          GitHubReviewThread(
            id: 'PRRT_482',
            isResolved: true,
            isOutdated: true,
            commentIds: [4597663715, 4597775539],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [
            _pr(
              repo: 'Frontify/ffy-cli',
              number: 482,
              updatedAt: DateTime.utc(2026, 11, 25, 11, 46, 2),
            ),
          ],
        );

        await service.pollOnce();
        await pump();

        expect(replied, isEmpty);
        expect(
          store.saves,
          afterBaseline,
          reason: 'stale replies must not dirty the dedupe store',
        );
        await sub.cancel();
      },
    );

    test(
      'fresh reply in viewer thread notifies once and ignores subsequent pushes',
      () async {
        final store = MemDedupeStore();
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();

        final replied = <PrThreadReplied>[];
        final sub = bus.on<PrThreadReplied>().listen(replied.add);

        clock = clock.add(const Duration(minutes: 1));
        final replyTime = clock.subtract(const Duration(seconds: 15));
        fetch.setReviewComments('o', 'r1', 7, [
          reviewComment(
            id: 200,
            login: 'viewer',
            body: 'Please rename this',
            path: 'lib/a.dart',
            line: 42,
            createdAt: clock.subtract(const Duration(days: 3)),
            updatedAt: clock.subtract(const Duration(days: 3)),
          ),
          reviewComment(
            id: 201,
            inReplyToId: 200,
            login: 'teammate',
            body: 'Done in the latest commit',
            path: 'lib/a.dart',
            line: 42,
            createdAt: replyTime,
            updatedAt: replyTime,
          ),
        ]);
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_200',
            isResolved: false,
            isOutdated: false,
            commentIds: [200, 201],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: replyTime)],
        );
        await service.pollOnce();
        await pump();

        expect(replied, hasLength(1));
        expect(replied.single.commentId, 201);
        expect(replied.single.authorLogin, 'teammate');
        expect(replied.single.path, 'lib/a.dart');
        expect(replied.single.line, 42);
        expect(replied.single.threadId, 'PRRT_200');
        expect(replied.single.forUserId, 'u1');

        // A later commit push bumps PR updatedAt without changing the comment.
        clock = clock.add(const Duration(minutes: 1));
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();

        expect(replied, hasLength(1));
        await sub.cancel();
      },
    );

    test(
      'pending review submitted after long drafting notifies using updatedAt',
      () async {
        final store = MemDedupeStore();
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        final baselineAt = clock;
        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();

        final replied = <PrThreadReplied>[];
        final sub = bus.on<PrThreadReplied>().listen(replied.add);

        clock = clock.add(const Duration(minutes: 10));
        final submittedAt = clock.subtract(const Duration(seconds: 20));
        // Drafted an hour before the baseline watermark, submitted now.
        final draftedAt = baselineAt.subtract(const Duration(hours: 1));
        fetch.setReviewComments('o', 'r1', 7, [
          reviewComment(
            id: 210,
            login: 'viewer',
            body: 'Question here',
            createdAt: baselineAt.subtract(const Duration(days: 2)),
            updatedAt: baselineAt.subtract(const Duration(days: 2)),
          ),
          reviewComment(
            id: 211,
            inReplyToId: 210,
            login: 'teammate',
            body: 'Submitted reply',
            createdAt: draftedAt,
            updatedAt: submittedAt,
          ),
        ]);
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_210',
            isResolved: false,
            isOutdated: false,
            commentIds: [210, 211],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: submittedAt)],
        );

        await service.pollOnce();
        await pump();

        expect(replied.map((e) => e.commentId), [211]);
        await sub.cancel();
      },
    );

    test(
      'historical @mention on PR woken by commit push emits neither comment nor coarse mention',
      () async {
        final store = MemDedupeStore();
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();

        final commentMentions = <PrCommentMentioned>[];
        final coarseMentions = <PrMentioned>[];
        final sub1 = bus.on<PrCommentMentioned>().listen(commentMentions.add);
        final sub2 = bus.on<PrMentioned>().listen(coarseMentions.add);

        clock = clock.add(const Duration(minutes: 1));
        final oldAt = clock.subtract(const Duration(days: 8));
        fetch.setIssueComments('o', 'r1', 7, [
          issueComment(
            id: 300,
            login: 'teammate',
            body: 'cc @viewer from last week',
            createdAt: oldAt,
            updatedAt: oldAt,
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          mentioned: [_pr(number: 7, updatedAt: clock)],
          updated: [_pr(number: 7, updatedAt: clock)],
        );

        await service.pollOnce();
        await pump();

        expect(commentMentions, isEmpty);
        expect(coarseMentions, isEmpty);
        await sub1.cancel();
        await sub2.cancel();
      },
    );

    test(
      'old comment edited to add @mention notifies once and suppresses coarse mention',
      () async {
        final store = MemDedupeStore();
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();

        final commentMentions = <PrCommentMentioned>[];
        final coarseMentions = <PrMentioned>[];
        final sub1 = bus.on<PrCommentMentioned>().listen(commentMentions.add);
        final sub2 = bus.on<PrMentioned>().listen(coarseMentions.add);

        clock = clock.add(const Duration(minutes: 1));
        final editedAt = clock.subtract(const Duration(seconds: 10));
        fetch.setIssueComments('o', 'r1', 7, [
          issueComment(
            id: 310,
            login: 'teammate',
            body: 'Actually @viewer could you take a look?',
            createdAt: clock.subtract(const Duration(days: 8)),
            updatedAt: editedAt,
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          mentioned: [_pr(number: 7, updatedAt: editedAt)],
          updated: [_pr(number: 7, updatedAt: editedAt)],
        );

        await service.pollOnce();
        await pump();

        expect(commentMentions, hasLength(1));
        expect(commentMentions.single.commentId, 310);
        expect(commentMentions.single.isReviewComment, isFalse);
        expect(commentMentions.single.authorLogin, 'teammate');
        expect(commentMentions.single.forUserId, 'u1');
        expect(coarseMentions, isEmpty);

        // Next sweep does not re-notify.
        clock = clock.add(const Duration(minutes: 1));
        await service.pollOnce();
        await pump();
        expect(commentMentions, hasLength(1));
        expect(coarseMentions, isEmpty);

        await sub1.cancel();
        await sub2.cancel();
      },
    );

    test(
      'restart catch-up notifies in-window replies and skips historical ones',
      () async {
        final store = MemDedupeStore()
          ..stored = jsonEncode({
            'v': 3,
            'savedAt': clock
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'prs': <String, dynamic>{},
            'comments': <String>[],
            'openThreads': <String>[],
          });
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        final replied = <PrThreadReplied>[];
        final sub = bus.on<PrThreadReplied>().listen(replied.add);

        final inWindow = clock.subtract(const Duration(hours: 1));
        fetch.setReviewComments('o', 'r1', 7, [
          reviewComment(
            id: 400,
            login: 'viewer',
            body: 'Root comment',
            createdAt: clock.subtract(const Duration(days: 9)),
            updatedAt: clock.subtract(const Duration(days: 9)),
          ),
          reviewComment(
            id: 401,
            inReplyToId: 400,
            login: 'teammate',
            body: 'Old reply',
            createdAt: clock.subtract(const Duration(days: 8)),
            updatedAt: clock.subtract(const Duration(days: 8)),
          ),
          reviewComment(
            id: 402,
            inReplyToId: 400,
            login: 'teammate',
            body: 'Missed during downtime',
            createdAt: inWindow,
            updatedAt: inWindow,
          ),
        ]);
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_400',
            isResolved: false,
            isOutdated: false,
            commentIds: [400, 401, 402],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: inWindow)],
        );

        await service.pollOnce();
        await pump();

        expect(replied.map((e) => e.commentId), [402]);
        await sub.cancel();
      },
    );

    test(
      'evicted historical comment id is not re-notified on a commit push',
      () async {
        final store = MemDedupeStore()
          ..stored = jsonEncode({
            'v': 3,
            'savedAt': clock
                .subtract(const Duration(minutes: 10))
                .toIso8601String(),
            'prs': <String, dynamic>{},
            // cr:501 has aged out of the 512-entry FIFO.
            'comments': <String>['cr:999'],
            'openThreads': <String>[],
          });
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        final replied = <PrThreadReplied>[];
        final sub = bus.on<PrThreadReplied>().listen(replied.add);

        final oldAt = clock.subtract(const Duration(days: 8));
        fetch.setReviewComments('o', 'r1', 7, [
          reviewComment(
            id: 500,
            login: 'viewer',
            body: 'Root comment',
            createdAt: oldAt,
            updatedAt: oldAt,
          ),
          reviewComment(
            id: 501,
            inReplyToId: 500,
            login: 'teammate',
            body: 'Old reply',
            createdAt: oldAt,
            updatedAt: oldAt,
          ),
        ]);
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_500',
            isResolved: true,
            isOutdated: true,
            commentIds: [500, 501],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );

        await service.pollOnce();
        await pump();

        expect(replied, isEmpty);
        final decoded = jsonDecode(store.stored!) as Map<String, dynamic>;
        expect(decoded['comments'], ['cr:999']);
        await sub.cancel();
      },
    );

    test(
      'suppresses thread resolved by viewer but clears tracking if reopened',
      () async {
        final store = MemDedupeStore();
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();

        final resolved = <PrThreadResolved>[];
        final sub = bus.on<PrThreadResolved>().listen(resolved.add);

        // 1. Thread starts unresolved.
        clock = clock.add(const Duration(minutes: 1));
        fetch.setReviewComments('o', 'r1', 7, [
          reviewComment(
            id: 600,
            login: 'viewer',
            body: 'Please check this',
            path: 'lib/a.dart',
            line: 10,
            createdAt: clock,
            updatedAt: clock,
          ),
        ]);
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_600',
            isResolved: false,
            isOutdated: false,
            commentIds: [600],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();
        expect(resolved, isEmpty);

        // 2. Viewer resolves it themselves (different casing) — suppressed, and
        // tracking is cleared from openThreads.
        clock = clock.add(const Duration(minutes: 1));
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_600',
            isResolved: true,
            isOutdated: false,
            resolvedByLogin: 'Viewer',
            commentIds: [600],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();
        expect(resolved, isEmpty);
        final decodedAfterSelfResolve =
            jsonDecode(store.stored!) as Map<String, dynamic>;
        expect(decodedAfterSelfResolve['openThreads'], isEmpty);

        // 3. Thread is reopened.
        clock = clock.add(const Duration(minutes: 1));
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_600',
            isResolved: false,
            isOutdated: false,
            commentIds: [600],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();
        expect(resolved, isEmpty);

        // 4. Teammate resolves it — emits PrThreadResolved with resolvedByLogin.
        clock = clock.add(const Duration(minutes: 1));
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_600',
            isResolved: true,
            isOutdated: false,
            resolvedByLogin: 'teammate',
            commentIds: [600],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();
        expect(resolved, hasLength(1));
        expect(resolved.single.threadId, 'PRRT_600');
        expect(resolved.single.resolvedByLogin, 'teammate');
        await sub.cancel();
      },
    );

    test(
      'notifies when thread is resolved with null resolvedByLogin',
      () async {
        final store = MemDedupeStore();
        final fetch = FakeViewerCommentFetchPort();
        service.dispose();
        service = buildService(
          store: store,
          viewerLogin: 'viewer',
          commentFetch: fetch,
          forUserId: 'u1',
        );

        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        await pump();

        final resolved = <PrThreadResolved>[];
        final sub = bus.on<PrThreadResolved>().listen(resolved.add);

        clock = clock.add(const Duration(minutes: 1));
        fetch.setReviewComments('o', 'r1', 7, [
          reviewComment(
            id: 610,
            login: 'viewer',
            body: 'Question here',
            path: 'lib/b.dart',
            line: 20,
            createdAt: clock,
            updatedAt: clock,
          ),
        ]);
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_610',
            isResolved: false,
            isOutdated: false,
            commentIds: [610],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();

        clock = clock.add(const Duration(minutes: 1));
        fetch.setReviewThreads('o', 'r1', 7, const [
          GitHubReviewThread(
            id: 'PRRT_610',
            isResolved: true,
            isOutdated: false,
            resolvedByLogin: null,
            commentIds: [610],
          ),
        ]);
        graphql.activity = GitHubViewerActivity(
          updated: [_pr(number: 7, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();

        expect(resolved, hasLength(1));
        expect(resolved.single.threadId, 'PRRT_610');
        expect(resolved.single.resolvedByLogin, isNull);
        await sub.cancel();
      },
    );
  });

  group('pre-notification surgical sync', () {
    test(
      'awaits onPrsActive BEFORE publishing PrReviewRequested and '
      'ExternalPrMerged',
      () async {
        final log = <String>[];
        var syncedBeforeEvent = false;
        service.dispose();
        service = GitHubViewerActivityPollingService(
          githubClient: client,
          eventBus: bus,
          changeSignals: signals,
          workspacesForRepo: (repo) async =>
              repo == 'o/r1' ? ['ws1'] : const [],
          onWorkspaceTouched: touched.add,
          onPrsActive: (workspaceId, targets) async {
            log.add(
              'sync:$workspaceId:${targets.map((t) => '${t.repoFullName}#${t.number}:${t.merged}').join(',')}',
            );
            await Future<void>.delayed(const Duration(milliseconds: 10));
            syncedBeforeEvent = true;
          },
          now: () => clock,
        );

        // Baseline pass: silent, no sync.
        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();
        expect(log, isEmpty);

        var sawSyncOnReview = false;
        var sawSyncOnMerge = false;
        final sub1 = bus.on<PrReviewRequested>().listen((e) {
          sawSyncOnReview = syncedBeforeEvent;
          log.add('event:review:${e.prNumber}');
        });
        final sub2 = bus.on<ExternalPrMerged>().listen((e) {
          sawSyncOnMerge = syncedBeforeEvent;
          log.add('event:merged:${e.prNumber}');
        });
        addTearDown(() async {
          await sub1.cancel();
          await sub2.cancel();
        });

        clock = clock.add(const Duration(minutes: 1));
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 10, updatedAt: clock)],
          merged: [_pr(number: 20, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();

        expect(sawSyncOnReview, isTrue);
        expect(sawSyncOnMerge, isTrue);
        expect(log.first, startsWith('sync:ws1:'));
        expect(log.first, contains('o/r1#10:false'));
        expect(log.first, contains('o/r1#20:true'));
        expect(log.indexOf('event:review:10'), greaterThan(0));
        expect(log.indexOf('event:merged:20'), greaterThan(0));
      },
    );

    test(
      'catch-up after restart with persisted store awaits onPrsActive before '
      'publishing',
      () async {
        final store = MemDedupeStore()
          ..stored = jsonEncode({
            'v': 3,
            'savedAt': clock.toIso8601String(),
            'prs': <String, dynamic>{},
          });
        final log = <String>[];
        service.dispose();
        service = GitHubViewerActivityPollingService(
          githubClient: client,
          eventBus: bus,
          changeSignals: signals,
          workspacesForRepo: (repo) async =>
              repo == 'o/r1' ? ['ws1'] : const [],
          onPrsActive: (workspaceId, targets) async {
            log.add('sync:${targets.map((t) => t.number).toList()}');
          },
          loadDedupeState: store.load,
          saveDedupeState: store.save,
          now: () => clock,
        );

        final sub = bus.on<PrReviewRequested>().listen((e) {
          log.add('event:${e.prNumber}');
        });
        addTearDown(sub.cancel);

        clock = clock.add(const Duration(minutes: 2));
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 55, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();

        expect(log, ['sync:[55]', 'event:55']);
      },
    );

    test(
      'still publishes notification when onPrsActive fails or times out',
      () async {
        service.dispose();
        service = GitHubViewerActivityPollingService(
          githubClient: client,
          eventBus: bus,
          changeSignals: signals,
          workspacesForRepo: (repo) async =>
              repo == 'o/r1' ? ['ws1'] : const [],
          syncTimeout: const Duration(milliseconds: 20),
          onPrsActive: (_, _) async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          },
          now: () => clock,
        );

        graphql.activity = const GitHubViewerActivity();
        await service.pollOnce();

        final events = <PrReviewRequested>[];
        final sub = bus.on<PrReviewRequested>().listen(events.add);
        addTearDown(sub.cancel);

        clock = clock.add(const Duration(minutes: 1));
        graphql.activity = GitHubViewerActivity(
          reviewRequested: [_pr(number: 77, updatedAt: clock)],
        );
        await service.pollOnce();
        await pump();

        expect(events.map((e) => e.prNumber), [77]);
      },
    );
  });
}
