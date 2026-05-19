import 'dart:convert';

import 'package:cc_domain/core/domain/entities/github_user.dart';
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

class FakeGitHubContentClient extends GitHubContentClient {
  FakeGitHubContentClient() : super(_NullDio());

  /// The next page to serve; replaced by tests between polls.
  GitHubNotificationsPage page = const GitHubNotificationsPage(
    threads: [],
    notModified: false,
  );

  String? lastIfModifiedSince;

  @override
  Future<GitHubNotificationsPage> listNotifications({
    String? ifModifiedSince,
    CancelToken? cancelToken,
  }) async {
    lastIfModifiedSince = ifModifiedSince;
    return page;
  }

  /// The viewer identity served to `_ensureIdentity`.
  GitHubUser? viewer = const GitHubUser(login: 'viewer', avatarUrl: '');

  /// The viewer's teams served to `_ensureIdentity`.
  List<({String org, String slug})> viewerTeams = [];

  @override
  Future<GitHubUser?> getAuthenticatedUser({CancelToken? cancelToken}) async =>
      viewer;

  @override
  Future<List<({String org, String slug})>> listViewerTeams({
    CancelToken? cancelToken,
  }) async => viewerTeams;
}

class FakeGitHubGraphQLClient extends GitHubGraphQLClient {
  FakeGitHubGraphQLClient() : super(_NullDio());

  /// The review state served to the per-PR checks (default: the viewer's
  /// review pending on an open PR).
  GitHubPrReviewState reviewState = const GitHubPrReviewState(
    pendingUsers: [
      GitHubPendingUserRequest(
        login: 'viewer',
        avatarUrl: '',
        asCodeOwner: false,
      ),
    ],
    prState: 'OPEN',
  );

  /// When set, `getPullRequestReviewState` throws it (verification outage).
  Object? reviewStateError;

  @override
  Future<GitHubPrReviewState> getPullRequestReviewState({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    final error = reviewStateError;
    if (error != null) {
      throw error;
    }
    return reviewState;
  }
}

class FakeGitHubApiClient implements GitHubApiClient {
  FakeGitHubApiClient(this.content, this.graphql);

  @override
  final FakeGitHubContentClient content;

  @override
  final FakeGitHubGraphQLClient graphql;

  @override
  GitHubPrClient get pr => throw UnimplementedError();
}

/// In-memory stand-in for the persisted dedupe store.
class MemDedupeStore {
  String? stored;

  Future<String?> load() async => stored;

  Future<void> save(String state) async => stored = state;
}

GitHubNotificationThread _thread({
  required String id,
  String reason = 'review_requested',
  String repo = 'o/r1',
  String type = 'PullRequest',
  int prNumber = 7,
  DateTime? updatedAt,
}) => GitHubNotificationThread(
  id: id,
  reason: reason,
  repoFullName: repo,
  subjectTitle: 'Fix things',
  subjectType: type,
  subjectUrl: '/repos/$repo/pulls/$prNumber',
  updatedAt: updatedAt ?? DateTime(2026, 1, 1),
);

void main() {
  late FakeGitHubContentClient content;
  late FakeGitHubGraphQLClient graphql;
  late FakeGitHubApiClient client;
  late DomainEventBus bus;
  late PrChangeSignals signals;
  late List<String> touched;
  late GitHubNotificationPollingService service;

  GitHubNotificationPollingService buildService({MemDedupeStore? store}) =>
      GitHubNotificationPollingService(
        githubClient: client,
        eventBus: bus,
        changeSignals: signals,
        workspacesForRepo: (repoFullName) async =>
            repoFullName == 'o/r1' ? ['ws1'] : const [],
        onWorkspaceTouched: touched.add,
        loadDedupeState: store?.load,
        saveDedupeState: store?.save,
        now: () => DateTime(2026, 1, 1, 12),
      );

  setUp(() {
    content = FakeGitHubContentClient();
    graphql = FakeGitHubGraphQLClient();
    client = FakeGitHubApiClient(content, graphql);
    bus = DomainEventBus();
    signals = PrChangeSignals();
    touched = [];
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

  test(
    'the first poll is a baseline — existing threads never notify',
    () async {
      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      content.page = GitHubNotificationsPage(
        threads: [_thread(id: '1')],
        notModified: false,
        lastModified: 'Mon, 01 Jan 2026 11:00:00 GMT',
      );
      await service.pollOnce();
      await pump();

      expect(events, isEmpty);
      expect(touched, isEmpty);
      await sub.cancel();
    },
  );

  test(
    'a new review request publishes PrReviewRequested + signal + nudge',
    () async {
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: '1')],
        notModified: false,
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);
      final received = <PrChangeSignal>[];
      final sigSub = signals
          .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
          .listen(received.add);

      content.page = GitHubNotificationsPage(
        threads: [_thread(id: '2', prNumber: 9)],
        notModified: false,
      );
      await service.pollOnce();
      await pump();

      expect(events, hasLength(1));
      expect(events.single.workspaceId, 'ws1');
      expect(events.single.repoOwner, 'o');
      expect(events.single.repoName, 'r1');
      expect(events.single.prNumber, 9);
      expect(received.map((s) => s.prNumber), [9]);
      expect(touched, ['ws1']);

      await sub.cancel();
      await sigSub.cancel();
    },
  );

  test('a new mention publishes PrMentioned + signal + nudge', () async {
    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await service.pollOnce();

    final events = <PrMentioned>[];
    final sub = bus.on<PrMentioned>().listen(events.add);
    final received = <PrChangeSignal>[];
    final sigSub = signals
        .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
        .listen(received.add);

    content.page = GitHubNotificationsPage(
      threads: [_thread(id: '8', reason: 'mention', prNumber: 11)],
      notModified: false,
    );
    await service.pollOnce();
    await pump();

    expect(events, hasLength(1));
    expect(events.single.workspaceId, 'ws1');
    expect(events.single.repoOwner, 'o');
    expect(events.single.repoName, 'r1');
    expect(events.single.prNumber, 11);
    expect(events.single.prTitle, 'Fix things');
    expect(received.map((s) => s.prNumber), [11]);
    expect(touched, ['ws1']);

    await sub.cancel();
    await sigSub.cancel();
  });

  test('a comment reason refreshes the PR but publishes no event', () async {
    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await service.pollOnce();

    final events = <PrReviewRequested>[];
    final sub = bus.on<PrReviewRequested>().listen(events.add);
    final received = <PrChangeSignal>[];
    final sigSub = signals
        .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
        .listen(received.add);

    content.page = GitHubNotificationsPage(
      threads: [_thread(id: '3', reason: 'comment', prNumber: 4)],
      notModified: false,
    );
    await service.pollOnce();
    await pump();

    expect(events, isEmpty);
    expect(received.map((s) => s.prNumber), [4]);
    expect(touched, ['ws1']);

    await sub.cancel();
    await sigSub.cancel();
  });

  test(
    'threads are deduped by id+updatedAt and filtered to linked repos',
    () async {
      content.page = const GitHubNotificationsPage(
        threads: [],
        notModified: false,
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      final thread = _thread(id: '5');
      content.page = GitHubNotificationsPage(
        threads: [
          thread,
          _thread(id: '6', repo: 'x/unlinked'),
          _thread(id: '7', type: 'Issue'),
        ],
        notModified: false,
      );
      await service.pollOnce();
      // The unchanged thread re-appearing must not re-notify.
      content.page = GitHubNotificationsPage(
        threads: [thread],
        notModified: false,
      );
      await service.pollOnce();
      await pump();

      expect(events, hasLength(1));
      expect(events.single.prNumber, 7);

      await sub.cancel();
    },
  );

  test(
    'the same review request re-signals on new activity but notifies once',
    () async {
      // Baseline.
      content.page = const GitHubNotificationsPage(
        threads: [],
        notModified: false,
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);
      final received = <PrChangeSignal>[];
      final sigSub = signals
          .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
          .listen(received.add);

      // The review is requested once...
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime(2026, 1, 2))],
        notModified: false,
      );
      await service.pollOnce();
      // ...then the author pushes twice, bumping `updatedAt` each time while
      // GitHub keeps the thread's reason at review_requested.
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime(2026, 1, 2, 1))],
        notModified: false,
      );
      await service.pollOnce();
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime(2026, 1, 2, 2))],
        notModified: false,
      );
      await service.pollOnce();
      await pump();

      // The bell is pinged exactly once...
      expect(events, hasLength(1));
      // ...but every bump still refreshes the PR.
      expect(received, hasLength(3));

      await sub.cancel();
      await sigSub.cancel();
    },
  );

  test(
    'the baseline suppresses a pre-restart request even after a later bump',
    () async {
      // A review request already surfaced before the (simulated) restart is part
      // of the first poll's baseline.
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime(2026, 1, 2))],
        notModified: false,
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);
      final received = <PrChangeSignal>[];
      final sigSub = signals
          .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
          .listen(received.add);

      // A later commit bumps `updatedAt` on the same still-review_requested
      // thread. The PR refreshes, but the request is not replayed to the bell.
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime(2026, 1, 2, 1))],
        notModified: false,
      );
      await service.pollOnce();
      await pump();

      expect(events, isEmpty);
      expect(received, hasLength(1));

      await sub.cancel();
      await sigSub.cancel();
    },
  );

  test('If-Modified-Since carries the previous Last-Modified', () async {
    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
      lastModified: 'stamp-1',
    );
    await service.pollOnce();
    expect(content.lastIfModifiedSince, isNull);

    await service.pollOnce();
    expect(content.lastIfModifiedSince, 'stamp-1');
  });

  test("a commit bump after the viewer's review never re-notifies, across a "
      'restart', () async {
    final store = MemDedupeStore();
    final events = <PrReviewRequested>[];
    final sub = bus.on<PrReviewRequested>().listen(events.add);

    // Service A: baseline empty, then a genuine pending request → one event.
    final serviceA = buildService(store: store);
    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await serviceA.pollOnce();
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2))],
      notModified: false,
    );
    await serviceA.pollOnce();
    await pump();
    expect(events, hasLength(1));
    expect(store.stored, isNotNull);
    serviceA.dispose();

    // Service B (a restart over the SAME store): the baseline page is empty
    // (the thread was read on GitHub), then two commit bumps arrive with
    // the viewer no longer pending — the PR-16230 shape: someone else and
    // an unrelated team are requested, the viewer already approved.
    graphql.reviewState = const GitHubPrReviewState(
      pendingUsers: [
        GitHubPendingUserRequest(
          login: 'someone-else',
          avatarUrl: '',
          asCodeOwner: false,
        ),
      ],
      pendingTeams: [
        GitHubPendingTeamRequest(
          name: 'Unrelated',
          slug: 'unrelated-team',
          asCodeOwner: false,
        ),
      ],
      prState: 'OPEN',
    );
    final serviceB = buildService(store: store);
    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await serviceB.pollOnce();

    final received = <PrChangeSignal>[];
    final sigSub = signals
        .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
        .listen(received.add);

    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 1))],
      notModified: false,
    );
    await serviceB.pollOnce();
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 2))],
      notModified: false,
    );
    await serviceB.pollOnce();
    await pump();

    // Zero new events across both bumps (still just the one from A)...
    expect(events, hasLength(1));
    // ...but the change signal still fires per bump.
    expect(received, hasLength(2));

    serviceB.dispose();
    await sub.cancel();
    await sigSub.cancel();
  });

  test('a genuine re-request notifies again', () async {
    final store = MemDedupeStore()
      // Pre-seed: the thread was previously seen as not-pending.
      ..stored = jsonEncode({
        'v': 1,
        'savedAt': '2026-01-01T12:00:00.000Z',
        'threads': {
          'pr': {'p': false},
        },
      });
    final stored = buildService(store: store);

    final events = <PrReviewRequested>[];
    final sub = bus.on<PrReviewRequested>().listen(events.add);

    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await stored.pollOnce();

    // The review is re-requested (default reviewState: viewer pending)...
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2))],
      notModified: false,
    );
    await stored.pollOnce();
    // ...then a commit bumps the thread while it stays pending.
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 1))],
      notModified: false,
    );
    await stored.pollOnce();
    await pump();

    expect(events, hasLength(1));

    stored.dispose();
    await sub.cancel();
  });

  test(
    'catch-up at startup notifies for requests that arrived while down',
    () async {
      final store = MemDedupeStore()
        ..stored = jsonEncode({
          'v': 1,
          'savedAt': '2026-01-02T12:00:00.000Z',
          'threads': <String, Object?>{},
        });
      final stored = buildService(store: store);

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      // The very first (baseline) poll surfaces a thread updated after the
      // watermark: it arrived while the server was down.
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 13))],
        notModified: false,
      );
      await stored.pollOnce();
      await pump();

      expect(events, hasLength(1));
      expect(events.single.workspaceId, 'ws1');

      stored.dispose();
      await sub.cancel();
    },
  );

  test('catch-up does not replay already-recorded threads', () async {
    final store = MemDedupeStore()
      ..stored = jsonEncode({
        'v': 1,
        'savedAt': '2026-01-02T12:00:00.000Z',
        'threads': {
          'pr': {'p': true},
        },
      });
    final stored = buildService(store: store);

    final events = <PrReviewRequested>[];
    final sub = bus.on<PrReviewRequested>().listen(events.add);

    // Older than the watermark: recorded silently during the baseline.
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 11))],
      notModified: false,
    );
    await stored.pollOnce();
    await pump();

    expect(events, isEmpty);

    stored.dispose();
    await sub.cancel();
  });

  test('verification failure falls back to once per id+reason', () async {
    graphql.reviewStateError = Exception('graphql down');

    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await service.pollOnce();

    final events = <PrReviewRequested>[];
    final sub = bus.on<PrReviewRequested>().listen(events.add);

    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2))],
      notModified: false,
    );
    await service.pollOnce();
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 1))],
      notModified: false,
    );
    await service.pollOnce();
    await pump();

    expect(events, hasLength(1));

    await sub.cancel();
  });

  test(
    'a GraphQL flake after a classified request does not re-notify on a push',
    () async {
      content.page = const GitHubNotificationsPage(
        threads: [],
        notModified: false,
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2))],
        notModified: false,
      );
      await service.pollOnce();
      await pump();
      expect(events, hasLength(1));

      graphql.reviewStateError = Exception('graphql down');
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 1))],
        notModified: false,
      );
      await service.pollOnce();
      await pump();

      expect(events, hasLength(1));

      await sub.cancel();
    },
  );

  test('a draft PR never notifies, even when CODEOWNERS requested the viewer '
      'on a push', () async {
    graphql.reviewState = const GitHubPrReviewState(
      pendingUsers: [
        GitHubPendingUserRequest(
          login: 'viewer',
          avatarUrl: '',
          asCodeOwner: true,
        ),
      ],
      prState: 'OPEN',
      isDraft: true,
    );

    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await service.pollOnce();

    final events = <PrReviewRequested>[];
    final sub = bus.on<PrReviewRequested>().listen(events.add);
    final received = <PrChangeSignal>[];
    final sigSub = signals
        .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
        .listen(received.add);

    // First sight: GitHub opened a review_requested thread because the
    // push matched CODEOWNERS. The PR is still a draft.
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2))],
      notModified: false,
    );
    await service.pollOnce();
    // A later commit bumps the same thread.
    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 1))],
      notModified: false,
    );
    await service.pollOnce();
    await pump();

    expect(events, isEmpty);
    expect(received, hasLength(2));

    await sub.cancel();
    await sigSub.cancel();
  });

  test(
    'marking a draft ready notifies once, then later pushes stay silent',
    () async {
      graphql.reviewState = const GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'viewer',
            avatarUrl: '',
            asCodeOwner: true,
          ),
        ],
        prState: 'OPEN',
        isDraft: true,
      );

      content.page = const GitHubNotificationsPage(
        threads: [],
        notModified: false,
      );
      await service.pollOnce();

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2))],
        notModified: false,
      );
      await service.pollOnce();
      await pump();
      expect(events, isEmpty);

      graphql.reviewState = const GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'viewer',
            avatarUrl: '',
            asCodeOwner: true,
          ),
        ],
        prState: 'OPEN',
      );
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 1))],
        notModified: false,
      );
      await service.pollOnce();
      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 2))],
        notModified: false,
      );
      await service.pollOnce();
      await pump();

      expect(events, hasLength(1));
      expect(events.single.prNumber, 7);

      await sub.cancel();
    },
  );

  test(
    'catch-up at startup does not notify for a draft that moved while down',
    () async {
      graphql.reviewState = const GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'viewer',
            avatarUrl: '',
            asCodeOwner: true,
          ),
        ],
        prState: 'OPEN',
        isDraft: true,
      );
      final store = MemDedupeStore()
        ..stored = jsonEncode({
          'v': 1,
          'savedAt': '2026-01-02T12:00:00.000Z',
          'threads': <String, Object?>{},
        });
      final stored = buildService(store: store);

      final events = <PrReviewRequested>[];
      final sub = bus.on<PrReviewRequested>().listen(events.add);

      content.page = GitHubNotificationsPage(
        threads: [_thread(id: 'pr', updatedAt: DateTime.utc(2026, 1, 2, 13))],
        notModified: false,
      );
      await stored.pollOnce();
      await pump();

      expect(events, isEmpty);

      stored.dispose();
      await sub.cancel();
    },
  );

  test('a pending team the viewer belongs to notifies once', () async {
    content.viewerTeams = [(org: 'o', slug: 'frontend-platform')];
    graphql.reviewState = const GitHubPrReviewState(
      pendingTeams: [
        GitHubPendingTeamRequest(
          name: 'Frontend Platform',
          slug: 'frontend-platform',
          asCodeOwner: false,
        ),
      ],
      prState: 'OPEN',
    );

    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await service.pollOnce();

    final events = <PrReviewRequested>[];
    final sub = bus.on<PrReviewRequested>().listen(events.add);

    content.page = GitHubNotificationsPage(
      threads: [_thread(id: 'team-pr', prNumber: 16347)],
      notModified: false,
    );
    await service.pollOnce();
    await pump();

    expect(events, hasLength(1));
    expect(events.single.prNumber, 16347);

    await sub.cancel();
  });

  test('state_change notifies only on MERGED, once', () async {
    content.page = const GitHubNotificationsPage(
      threads: [],
      notModified: false,
    );
    await service.pollOnce();

    final events = <ExternalPrMerged>[];
    final sub = bus.on<ExternalPrMerged>().listen(events.add);

    // Closed without merge → nothing.
    graphql.reviewState = const GitHubPrReviewState(prState: 'CLOSED');
    content.page = GitHubNotificationsPage(
      threads: [
        _thread(
          id: 'st',
          reason: 'state_change',
          prNumber: 21,
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      notModified: false,
    );
    await service.pollOnce();
    await pump();
    expect(events, isEmpty);

    // Merged → exactly one event with the thread's fields.
    graphql.reviewState = const GitHubPrReviewState(prState: 'MERGED');
    content.page = GitHubNotificationsPage(
      threads: [
        _thread(
          id: 'st',
          reason: 'state_change',
          prNumber: 21,
          updatedAt: DateTime.utc(2026, 1, 2, 1),
        ),
      ],
      notModified: false,
    );
    await service.pollOnce();
    await pump();
    expect(events, hasLength(1));
    expect(events.single.workspaceId, 'ws1');
    expect(events.single.repoOwner, 'o');
    expect(events.single.repoName, 'r1');
    expect(events.single.prNumber, 21);
    expect(events.single.prTitle, 'Fix things');

    // A later bump does not re-fire.
    content.page = GitHubNotificationsPage(
      threads: [
        _thread(
          id: 'st',
          reason: 'state_change',
          prNumber: 21,
          updatedAt: DateTime.utc(2026, 1, 2, 2),
        ),
      ],
      notModified: false,
    );
    await service.pollOnce();
    await pump();
    expect(events, hasLength(1));

    await sub.cancel();
  });

  test('merged-while-down is caught up at launch', () async {
    final store = MemDedupeStore()
      ..stored = jsonEncode({
        'v': 1,
        'savedAt': '2026-01-02T12:00:00.000Z',
        'threads': <String, Object?>{},
      });
    final stored = buildService(store: store);
    graphql.reviewState = const GitHubPrReviewState(prState: 'MERGED');

    final events = <ExternalPrMerged>[];
    final sub = bus.on<ExternalPrMerged>().listen(events.add);

    // The baseline poll surfaces a state_change thread updated after the
    // watermark: the merge happened while the server was down.
    content.page = GitHubNotificationsPage(
      threads: [
        _thread(
          id: 'st',
          reason: 'state_change',
          prNumber: 21,
          updatedAt: DateTime.utc(2026, 1, 2, 13),
        ),
      ],
      notModified: false,
    );
    await stored.pollOnce();
    await pump();

    expect(events, hasLength(1));
    expect(events.single.prNumber, 21);

    stored.dispose();
    await sub.cancel();
  });
}
