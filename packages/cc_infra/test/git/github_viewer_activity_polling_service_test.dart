import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _NullDio implements Dio {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGitHubGraphQLClient extends GitHubGraphQLClient {
  FakeGitHubGraphQLClient() : super(_NullDio());

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
  }) => GitHubViewerActivityPollingService(
    githubClient: client,
    eventBus: bus,
    changeSignals: signals,
    shouldPoll: shouldPoll,
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
}
