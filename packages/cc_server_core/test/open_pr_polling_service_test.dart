import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

// ===========================================================================
// Fakes
// ===========================================================================

class FakeWorkspaceRepository implements WorkspaceRepository {
  FakeWorkspaceRepository({required this.workspaces, required this.reposByWs});

  final List<Workspace> workspaces;
  final Map<String, List<Repo>> reposByWs;

  @override
  Stream<List<Workspace>> watchAll() => Stream.value(workspaces);

  @override
  Future<List<Workspace>> getAll() async => workspaces;

  @override
  Future<Workspace?> getById(String id) async {
    for (final w in workspaces) {
      if (w.id == id) {
        return w;
      }
    }
    return null;
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(reposByWs[workspaceId] ?? const []);

  @override
  Future<String> upsert(Workspace workspace) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      throw UnimplementedError();

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      throw UnimplementedError();

  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      throw UnimplementedError();

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {}
}

class FakeOpenPrFetchPort implements OpenPrFetchPort {
  /// Scripted probe results per repo id.
  final Map<String, ({bool changed, String? etag})> probeResults = {};

  /// Scripted probe errors per repo id, thrown instead of answering.
  final Map<String, Object> probeErrors = {};

  /// Repo ids probed, in order (across sweeps).
  final List<String> probedRepoIds = [];

  /// Scripted group results (whatever `fetchGroups` should return next).
  List<OpenPrGroup> groups = [];

  /// Repo ids GitHub is pretending NOT to have answered for — the partial
  /// failure the batch query tolerates. Every other requested repo resolves.
  Set<String> unresolvedRepoIds = {};

  /// Scripted checks results per repo id.
  Map<String, Map<int, PrStatusOverlay>> checks = {};

  /// PR numbers that resolve as merged.
  final Set<int> mergedNumbers = {};

  int probeCalls = 0;
  int fetchGroupsCalls = 0;
  int fetchChecksCalls = 0;

  /// When set, `fetchGroups` parks on this gate — lets tests hold a sweep
  /// mid-flight.
  Completer<void>? fetchGroupsGate;

  @override
  Future<({bool changed, String? etag})> probeRepo(
    Repo repo,
    String? etag,
  ) async {
    probeCalls++;
    probedRepoIds.add(repo.id);
    final error = probeErrors[repo.id];
    if (error != null) {
      throw error;
    }
    return probeResults[repo.id] ?? (changed: false, etag: 'etag-1');
  }

  @override
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos) async {
    fetchGroupsCalls++;
    final gate = fetchGroupsGate;
    if (gate != null) {
      await gate.future;
    }
    return (
      groups: groups,
      resolvedRepoIds: {
        for (final r in repos)
          if (!unresolvedRepoIds.contains(r.id)) r.id,
      },
    );
  }

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos,
  ) async {
    fetchChecksCalls++;
    return checks;
  }

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber) async =>
      mergedNumbers.contains(prNumber);

  /// Scripted forge verdict for the readiness confirmation, per PR number.
  /// Absent = `unknown`, i.e. "not confirmed", which suppresses the edge.
  final Map<int, PrMergeableState> mergeStates = {};

  /// Scripted approver for the attribution fallback, per PR number.
  final Map<int, String> approvers = {};

  /// Scripted failing check, per PR number.
  final Map<int, ({String name, String? url})> failingChecks = {};

  int mergeStateCalls = 0;
  int latestApproverCalls = 0;
  int firstFailingCheckCalls = 0;

  @override
  Future<PrMergeableState> mergeState(Repo repo, int prNumber) async {
    mergeStateCalls++;
    return mergeStates[prNumber] ?? PrMergeableState.unknown;
  }

  @override
  Future<String?> latestApprover(Repo repo, int prNumber) async {
    latestApproverCalls++;
    return approvers[prNumber];
  }

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  ) async {
    firstFailingCheckCalls++;
    return failingChecks[prNumber];
  }
}

// ===========================================================================
// Helpers
// ===========================================================================

Repo _repo(String id) => Repo(
  id: id,
  name: id,
  path: '/tmp/$id',
  remoteOwner: 'o',
  remoteName: id,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

Workspace _workspace(String id) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

PullRequest _pr(
  int number, {
  String title = 'PR',
  String checks = 'none',
  String? headSha,
  String author = 'u',
  bool isDraft = false,
  PrReviewDecision reviewDecision = PrReviewDecision.none,
  PrMergeableState mergeableState = PrMergeableState.unrecognized,
  List<String> requestedReviewers = const [],
  List<String> requestedTeamSlugs = const [],
}) => PullRequest(
      id: number,
      number: number,
      title: '$title $number',
      body: '',
      state: PrState.open,
      isDraft: isDraft,
      author: PrUser(login: author, avatarUrl: ''),
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      repoFullName: 'o/r1',
      htmlUrl: '',
      externalId: 'n$number',
      headSha: headSha ?? 's$number',
      baseRef: 'main',
      headRef: 'f$number',
      requestedReviewers: [
        for (final r in requestedReviewers) PrUser(login: r, avatarUrl: ''),
      ],
      requestedTeamSlugs: requestedTeamSlugs,
      reviewDecision: reviewDecision,
      mergeableState: mergeableState,
      checksStatus: PrChecksStatus.values.firstWhere(
        (c) => c.name == checks,
        orElse: () => PrChecksStatus.none,
      ),
    );

/// A tiny wire mapper sufficient for snapshot diffing in tests (the real one
/// lives in the RPC catalog; the poller only relies on `number`, `title`,
/// `author`, `updated_at`, `head_sha`, `checks_status`, `review_decision` and
/// — for `openPrForHeadBranch` — `head_ref`).
Map<String, dynamic> _prToWire(PullRequest pr) => {
  'number': pr.number,
  'title': pr.title,
  'author': {'login': pr.author?.login ?? ''},
  'updated_at': pr.updatedAt?.toIso8601String(),
  'head_sha': pr.headSha,
  'head_ref': pr.headRef,
  'checks_status': pr.checksStatus.name,
  'review_decision': pr.reviewDecision.name,
  // The fields the author-facing transition detector reads.
  'state': pr.state.name,
  'is_draft': pr.isDraft,
  'mergeable_state': pr.mergeableState.name,
  'requested_reviewers': [
    for (final r in pr.requestedReviewers) {'login': r.login},
  ],
  'requested_team_slugs': pr.requestedTeamSlugs,
};

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  late WorkspaceDatabase db;
  late FakeOpenPrFetchPort port;
  late FakeWorkspaceRepository workspaces;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late PrChangeSignals signals;
  late DomainEventBus bus;
  late OpenPrPollingService poller;
  late DateTime now;

  final repo1 = _repo('r1');

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    db = dbs.of('ws1');
    port = FakeOpenPrFetchPort();
    workspaces = FakeWorkspaceRepository(
      workspaces: [_workspace('ws1')],
      reposByWs: {
        'ws1': [repo1],
      },
    );
    signals = PrChangeSignals();
    bus = DomainEventBus();
    now = DateTime(2026, 1, 1, 12);
    poller = OpenPrPollingService(
      fetchPort: port,
      workspaceRepository: workspaces,
      workspaceDbs: dbs,
      changeSignals: signals,
      prToWire: _prToWire,
      eventBus: bus,
      now: () => now,
    );
  });

  tearDown(() {
    poller.dispose();
    signals.dispose();
    bus.dispose();
  });

  Future<void> pump() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('first sweep is a baseline: snapshot persisted, no events', () async {
    final events = <ExternalPrDetected>[];
    final sub = bus.on<ExternalPrDetected>().listen(events.add);
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];

    await poller.refreshNow('ws1');
    await pump();

    final raw = await db.cacheDao.read(
      'ws1',
      OpenPrPollingService.cacheKind,
      OpenPrPollingService.cacheKey,
    );
    expect(raw, isNotNull);
    final snapshot = jsonDecode(raw!) as Map<String, dynamic>;
    expect(snapshot['authenticated'], isTrue);
    expect(snapshot['repos'] as List, hasLength(1));
    expect(events, isEmpty, reason: 'baseline must not notify');

    await sub.cancel();
  });

  test(
    'a new PR after baseline publishes ExternalPrDetected + a signal',
    () async {
      port.groups = [
        (repo: repo1, prs: [_pr(1)], hasMore: false),
      ];
      await poller.refreshNow('ws1');

      final events = <ExternalPrDetected>[];
      final sub = bus.on<ExternalPrDetected>().listen(events.add);
      final received = <PrChangeSignal>[];
      final sigSub = signals
          .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
          .listen(received.add);

      now = now.add(const Duration(minutes: 5));
      port.groups = [
        (repo: repo1, prs: [_pr(1), _pr(2)], hasMore: false),
      ];
      await poller.refreshNow('ws1');
      await pump();

      expect(events, hasLength(1));
      expect(events.single.prNumber, 2);
      expect(events.single.workspaceId, 'ws1');
      expect(received.map((s) => s.prNumber), contains(2));

      await sub.cancel();
      await sigSub.cancel();
    },
  );

  test('a vanished PR publishes PullRequestStatusChanged (merged)', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1), _pr(2)], hasMore: false),
    ];
    await poller.refreshNow('ws1');

    final events = <PullRequestStatusChanged>[];
    final sub = bus.on<PullRequestStatusChanged>().listen(events.add);

    now = now.add(const Duration(minutes: 5));
    port.mergedNumbers.add(2);
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    await poller.refreshNow('ws1');
    await pump();

    expect(events, hasLength(1));
    expect(events.single.status, 'merged');
    expect(events.single.prNumber, 2);
    expect(events.single.workspaceId, 'ws1');

    await sub.cancel();
  });

  group('PrHeadChanged', () {
    // The sweep is the only place that holds BOTH the old and the new commit,
    // which is exactly what a stale-review check needs — the cache nudge that
    // already fired here carries no payload and no listeners outside the UI.

    Future<List<PrHeadChanged>> sweepWith(
      String firstSha,
      String secondSha, {
      String title = 'PR',
    }) async {
      port.groups = [
        (repo: repo1, prs: [_pr(1, title: title, headSha: firstSha)],
         hasMore: false),
      ];
      await poller.refreshNow('ws1');

      final events = <PrHeadChanged>[];
      final sub = bus.on<PrHeadChanged>().listen(events.add);

      now = now.add(const Duration(minutes: 5));
      port.groups = [
        (repo: repo1, prs: [_pr(1, title: title, headSha: secondSha)],
         hasMore: false),
      ];
      await poller.refreshNow('ws1');
      await pump();
      await sub.cancel();
      return events;
    }

    test('a push carries both the old and the new commit', () async {
      final events = await sweepWith('aaa1111', 'bbb2222');

      expect(events, hasLength(1));
      final e = events.single;
      expect(e.workspaceId, 'ws1');
      expect(e.repoOwner, 'o');
      expect(e.repoName, 'r1');
      expect(e.prNumber, 1);
      expect(e.previousHeadSha, 'aaa1111');
      expect(e.headSha, 'bbb2222');
      expect(e.prTitle, contains('PR'));
    });

    test('a PR whose head did not move raises nothing', () async {
      // Titles, checks and review decisions all move without invalidating a
      // review. Only the commit does.
      final events = await sweepWith('aaa1111', 'aaa1111', title: 'Renamed');
      expect(events, isEmpty);
    });

    test('the baseline sweep raises nothing', () async {
      // A first sweep has no previous commit to compare against, so every
      // open PR would look like a fresh push.
      final events = <PrHeadChanged>[];
      final sub = bus.on<PrHeadChanged>().listen(events.add);
      port.groups = [
        (repo: repo1, prs: [_pr(1, headSha: 'aaa1111')], hasMore: false),
      ];
      await poller.refreshNow('ws1');
      await pump();
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('a newly-detected PR raises nothing', () async {
      // It is announced as ExternalPrDetected. Claiming its head "changed"
      // would be true of every PR the moment it is first seen.
      port.groups = [
        (repo: repo1, prs: [_pr(1, headSha: 'aaa1111')], hasMore: false),
      ];
      await poller.refreshNow('ws1');

      final events = <PrHeadChanged>[];
      final sub = bus.on<PrHeadChanged>().listen(events.add);
      now = now.add(const Duration(minutes: 5));
      port.groups = [
        (
          repo: repo1,
          prs: [_pr(1, headSha: 'aaa1111'), _pr(2, headSha: 'ccc3333')],
          hasMore: false,
        ),
      ];
      await poller.refreshNow('ws1');
      await pump();

      expect(events, isEmpty);
      await sub.cancel();
    });
  });

  test('an unchanged probe skips the full fetch', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    await poller.refreshNow('ws1');
    expect(port.fetchGroupsCalls, 1);

    // Non-forced pass with a 304 probe: no group fetch.
    now = now.add(const Duration(minutes: 5));
    port.probeResults[repo1.id] = (changed: false, etag: 'etag-2');
    await poller.pollSoon('ws1');
    expect(port.fetchGroupsCalls, 1);
  });

  test('a changed PR emits a targeted (non-checks) signal', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    await poller.refreshNow('ws1');

    final received = <PrChangeSignal>[];
    final sigSub = signals
        .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
        .listen(received.add);

    now = now.add(const Duration(minutes: 5));
    port.groups = [
      (repo: repo1, prs: [_pr(1, title: 'Renamed')], hasMore: false),
    ];
    await poller.refreshNow('ws1');
    await pump();

    expect(received, hasLength(1));
    expect(received.single.prNumber, 1);
    expect(received.single.checksOnly, isFalse);

    await sigSub.cancel();
  });

  test(
    'the checks pass updates the snapshot and emits checks-only signals',
    () async {
      port.groups = [
        (repo: repo1, prs: [_pr(1)], hasMore: false),
      ];
      await poller.refreshNow('ws1');

      // Register interest so pollSoon includes the checks pass.
      final watchSub = poller.watchOpenForWorkspace('ws1').listen((_) {});
      await pump();

      final received = <PrChangeSignal>[];
      final sigSub = signals
          .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
          .listen(received.add);

      now = now.add(const Duration(minutes: 5));
      port.probeResults[repo1.id] = (changed: false, etag: 'etag-2');
      port.checks = {
        repo1.id: {1: (checksRollup: 'FAILURE', reviewDecision: null)},
      };
      await poller.pollSoon('ws1');
      await pump();

      expect(port.fetchChecksCalls, 1);
      expect(received, hasLength(1));
      expect(received.single.checksOnly, isTrue);
      expect(received.single.prNumber, 1);

      final raw = await db.cacheDao.read(
        'ws1',
        OpenPrPollingService.cacheKind,
        OpenPrPollingService.cacheKey,
      );
      final snapshot = jsonDecode(raw!) as Map<String, dynamic>;
      final prs = ((snapshot['repos'] as List).single as Map)['prs'] as List;
      expect((prs.single as Map)['checks_status'], 'failing');

      await sigSub.cancel();
      await watchSub.cancel();
    },
  );

  test(
    'the checks pass carries review-decision moves as full signals',
    () async {
      port.groups = [
        (repo: repo1, prs: [_pr(1)], hasMore: false),
      ];
      await poller.refreshNow('ws1');

      final watchSub = poller.watchOpenForWorkspace('ws1').listen((_) {});
      await pump();

      final received = <PrChangeSignal>[];
      final sigSub = signals
          .watch(workspaceId: 'ws1', repoFullName: 'o/r1')
          .listen(received.add);

      now = now.add(const Duration(minutes: 5));
      port.probeResults[repo1.id] = (changed: false, etag: 'etag-2');
      port.checks = {
        repo1.id: {1: (checksRollup: null, reviewDecision: 'APPROVED')},
      };
      await poller.pollSoon('ws1');
      await pump();

      expect(received, hasLength(1));
      expect(
        received.single.checksOnly,
        isFalse,
        reason: 'a review-decision move is more than a checks refresh',
      );

      final raw = await db.cacheDao.read(
        'ws1',
        OpenPrPollingService.cacheKind,
        OpenPrPollingService.cacheKey,
      );
      final snapshot = jsonDecode(raw!) as Map<String, dynamic>;
      final prs = ((snapshot['repos'] as List).single as Map)['prs'] as List;
      expect((prs.single as Map)['review_decision'], 'approved');

      await sigSub.cancel();
      await watchSub.cancel();
    },
  );

  test('watchOpenForWorkspace pushes every persisted snapshot', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    await poller.refreshNow('ws1');

    final frames = <Map<String, dynamic>>[];
    final sub = poller.watchOpenForWorkspace('ws1').listen(frames.add);
    await pump();
    expect(frames, hasLength(1), reason: 'initial snapshot on subscribe');
    expect(
      frames.single['sweep_in_flight'],
      isFalse,
      reason: 'no sweep is running right after the seeded refresh',
    );

    now = now.add(const Duration(minutes: 5));
    port.groups = [
      (repo: repo1, prs: [_pr(1), _pr(2)], hasMore: false),
    ];
    await poller.refreshNow('ws1');
    await pump();

    expect(
      frames.length,
      greaterThanOrEqualTo(2),
      reason: 'sweep change pushes a new frame',
    );
    final prs = ((frames.last['repos'] as List).single as Map)['prs'] as List;
    expect(prs, hasLength(2));
    expect(
      frames.last['sweep_in_flight'],
      isFalse,
      reason: 'the flag settles once the sweep has landed',
    );

    await sub.cancel();
  });

  test('watch frames carry the live sweep-in-flight flag', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    await poller.refreshNow('ws1');

    final frames = <Map<String, dynamic>>[];
    final sub = poller.watchOpenForWorkspace('ws1').listen(frames.add);
    await pump();
    expect(
      frames.single['sweep_in_flight'],
      isFalse,
      reason: 'subscribe is throttled by the just-finished sweep — idle',
    );

    final gate = Completer<void>();
    port.fetchGroupsGate = gate;
    final refresh = poller.refreshNow('ws1');
    await pump();
    expect(
      frames.last['sweep_in_flight'],
      isTrue,
      reason:
          'the flag flips true while the sweep fetches — this is the signal '
          'the client refresh icon spins on',
    );

    port.fetchGroupsGate = null;
    gate.complete();
    await refresh;
    await pump();
    expect(frames.last['sweep_in_flight'], isFalse);

    await sub.cancel();
  });

  test('refreshNow during an in-flight sweep queues a full forced sweep '
      'and resolves only once it lands', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    final gate = Completer<void>();
    port.fetchGroupsGate = gate;
    final first = poller.refreshNow('ws1');
    await pump();
    expect(port.fetchGroupsCalls, 1, reason: 'first sweep is mid-fetch');

    var secondDone = false;
    final second = poller.refreshNow('ws1');
    unawaited(second.whenComplete(() => secondDone = true));
    await pump();
    expect(
      secondDone,
      isFalse,
      reason:
          'the refresh must not resolve while a sweep is still running — '
          'the client refresh spinner rides on this future',
    );

    port.fetchGroupsGate = null;
    gate.complete();
    await first;
    await second;
    expect(
      port.fetchGroupsCalls,
      2,
      reason: 'the queued forced refresh runs its own full sweep',
    );
    expect(secondDone, isTrue);
  });

  test('concurrent forced refreshes share one queued sweep', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    final gate = Completer<void>();
    port.fetchGroupsGate = gate;
    final first = poller.refreshNow('ws1');
    await pump();

    final second = poller.refreshNow('ws1');
    final third = poller.refreshNow('ws1');

    port.fetchGroupsGate = null;
    gate.complete();
    await Future.wait([first, second, third]);
    expect(
      port.fetchGroupsCalls,
      2,
      reason: 'one in-flight sweep + one shared queued forced sweep',
    );
  });

  test('a non-forced pass coalesces into the sweep in flight', () async {
    port.groups = [
      (repo: repo1, prs: [_pr(1)], hasMore: false),
    ];
    final gate = Completer<void>();
    port.fetchGroupsGate = gate;
    final first = poller.refreshNow('ws1');
    await pump();

    final soon = poller.pollSoon('ws1');

    port.fetchGroupsGate = null;
    gate.complete();
    await Future.wait([first, soon]);
    expect(port.fetchGroupsCalls, 1, reason: 'pollSoon never double-sweeps');
  });

  // A degraded GitHub answers the batch query with null repo aliases rather
  // than an error, which reads exactly like "every queue is empty". Persisting
  // that wiped the snapshot, emptied every client's inbox and published a
  // merged/closed event per PR — the outage bug these two tests pin.
  group('a GitHub that answers for nothing', () {
    test('keeps the previous snapshot instead of persisting an empty one', () async {
      port.groups = [
        (repo: repo1, prs: [_pr(1), _pr(2)], hasMore: false),
      ];
      await poller.refreshNow('ws1');

      final events = <PullRequestStatusChanged>[];
      final sub = bus.on<PullRequestStatusChanged>().listen(events.add);

      now = now.add(const Duration(minutes: 5));
      port.unresolvedRepoIds = {repo1.id};
      port.groups = [];
      await poller.refreshNow('ws1');
      await pump();

      final snapshot = await _readSnapshot(db);
      expect(
        snapshot['repos'] as List,
        hasLength(1),
        reason: 'the repo must survive a sweep GitHub never answered',
      );
      expect(
        _numbersOf(snapshot, 'o/r1'),
        [1, 2],
        reason: 'both PRs are still open — nothing was observed to change',
      );
      expect(
        events,
        isEmpty,
        reason: 'an unanswered repo must not read as merged/closed',
      );

      await sub.cancel();
    });

    test('a partial answer keeps the repos it did not cover', () async {
      final repo2 = _repo('r2');
      final twoRepos = FakeWorkspaceRepository(
        workspaces: [_workspace('ws1')],
        reposByWs: {
          'ws1': [repo1, repo2],
        },
      );
      final partialPoller = OpenPrPollingService(
        fetchPort: port,
        workspaceRepository: twoRepos,
        workspaceDbs: dbs,
        changeSignals: signals,
        prToWire: _prToWire,
        eventBus: bus,
        now: () => now,
      );
      addTearDown(partialPoller.dispose);

      port.groups = [
        (repo: repo1, prs: [_pr(1)], hasMore: false),
        (repo: repo2, prs: [_pr(2)], hasMore: false),
      ];
      await partialPoller.refreshNow('ws1');

      final events = <PullRequestStatusChanged>[];
      final sub = bus.on<PullRequestStatusChanged>().listen(events.add);

      // GitHub answers for r1 only; r2's alias errored.
      now = now.add(const Duration(minutes: 5));
      port.unresolvedRepoIds = {repo2.id};
      port.groups = [
        (repo: repo1, prs: [_pr(1), _pr(3)], hasMore: false),
      ];
      await partialPoller.refreshNow('ws1');
      await pump();

      final snapshot = await _readSnapshot(db);
      expect(
        _numbersOf(snapshot, 'o/r1'),
        [1, 3],
        reason: 'the answered repo takes the fresh page',
      );
      expect(
        _numbersOf(snapshot, 'o/r2'),
        [2],
        reason: 'the unanswered repo keeps its previous entry',
      );
      expect(
        events,
        isEmpty,
        reason: 'r2 was never observed, so it publishes nothing',
      );

      await sub.cancel();
    });
  });

  // GitHub answers 404 (not 403) for a repo the credential cannot see —
  // typically a GitHub App not installed on the repo's org. The poller must
  // classify that as an access problem: park the repo (slow retries instead of
  // a failing request + log line per minute), surface it in the snapshot for
  // the UI notice, and never read it as merged/closed.
  group('an inaccessible repo', () {
    const notFound = NetworkException(
      'Resource not found',
      statusCode: 404,
      code: 'not_found',
    );

    final repo2 = _repo('r2');
    late FakeWorkspaceRepository twoRepos;
    late OpenPrPollingService accessPoller;

    setUp(() {
      twoRepos = FakeWorkspaceRepository(
        workspaces: [_workspace('ws1')],
        reposByWs: {
          'ws1': [repo1, repo2],
        },
      );
      accessPoller = OpenPrPollingService(
        fetchPort: port,
        workspaceRepository: twoRepos,
        workspaceDbs: dbs,
        changeSignals: signals,
        prToWire: _prToWire,
        eventBus: bus,
        now: () => now,
      );
    });

    tearDown(() => accessPoller.dispose());

    /// Baseline both repos, then let r1's probes start failing with [error].
    Future<void> baselineThenFail(Object error) async {
      port.groups = [
        (repo: repo1, prs: [_pr(1)], hasMore: false),
        (repo: repo2, prs: [_pr(2)], hasMore: false),
      ];
      await accessPoller.refreshNow('ws1');
      port.probeErrors[repo1.id] = error;
    }

    /// Runs [n] non-forced sweeps, advancing the clock past the pollSoon gap.
    Future<void> sweeps(int n) async {
      for (var i = 0; i < n; i++) {
        now = now.add(const Duration(minutes: 1));
        await accessPoller.pollSoon('ws1');
      }
    }

    test('parks after the threshold and lands in the snapshot', () async {
      await baselineThenFail(notFound);

      final events = <PullRequestStatusChanged>[];
      final sub = bus.on<PullRequestStatusChanged>().listen(events.add);

      await sweeps(2);
      var snapshot = await _readSnapshot(db);
      expect(
        (snapshot['inaccessible_repos'] as List?) ?? const [],
        isEmpty,
        reason: 'below the threshold nothing is parked yet',
      );

      await sweeps(1);
      snapshot = await _readSnapshot(db);
      final parked = (snapshot['inaccessible_repos'] as List).cast<Map>();
      expect(parked, hasLength(1));
      expect(parked.single['repo_id'], repo1.id);
      expect(parked.single['reason'], 'not_found');
      expect(parked.single['since'], isNotNull);
      expect(
        _numbersOf(snapshot, 'o/r1'),
        [1],
        reason: 'the parked repo keeps its previous entries',
      );
      expect(
        events,
        isEmpty,
        reason: 'an unreachable repo must never read as merged/closed',
      );

      await sub.cancel();
    });

    test('a parked repo is probed on the slow cadence only', () async {
      await baselineThenFail(notFound);
      await sweeps(3);

      port.probedRepoIds.clear();
      await sweeps(2);
      expect(
        port.probedRepoIds,
        [repo2.id, repo2.id],
        reason: 'inside the retry interval only the healthy repo is probed',
      );

      port.probedRepoIds.clear();
      now = now.add(const Duration(minutes: 11));
      await accessPoller.pollSoon('ws1');
      expect(
        port.probedRepoIds,
        contains(repo1.id),
        reason: 'past the retry interval the parked repo gets one probe',
      );
    });

    test('a forced refresh re-probes and a success unparks', () async {
      await baselineThenFail(notFound);
      await sweeps(3);

      port.probeErrors.remove(repo1.id);
      now = now.add(const Duration(minutes: 1));
      await accessPoller.refreshNow('ws1');

      final snapshot = await _readSnapshot(db);
      expect(
        (snapshot['inaccessible_repos'] as List?) ?? const [],
        isEmpty,
        reason: 'a successful probe unparks immediately',
      );
      expect(_numbersOf(snapshot, 'o/r1'), [1]);
    });

    test('transient failures never park', () async {
      await baselineThenFail(
        const NetworkException('Timeout', code: 'timeout'),
      );
      await sweeps(5);

      final snapshot = await _readSnapshot(db);
      expect(
        (snapshot['inaccessible_repos'] as List?) ?? const [],
        isEmpty,
        reason: 'a timeout is GitHub being slow, not an access verdict',
      );
      port.probedRepoIds.clear();
      await sweeps(1);
      expect(
        port.probedRepoIds,
        contains(repo1.id),
        reason: 'the repo stays on the normal cadence',
      );
    });

    test('a restart keeps the repo parked (seeded from the snapshot)', () async {
      await baselineThenFail(notFound);
      await sweeps(3);
      accessPoller.dispose();

      // A fresh service over the same database: in-memory counters are gone,
      // but the persisted snapshot re-arms the parked state.
      final restarted = OpenPrPollingService(
        fetchPort: port,
        workspaceRepository: twoRepos,
        workspaceDbs: dbs,
        changeSignals: signals,
        prToWire: _prToWire,
        eventBus: bus,
        now: () => now,
      );
      addTearDown(restarted.dispose);

      now = now.add(const Duration(minutes: 1));
      await restarted.pollSoon('ws1');
      final snapshot = await _readSnapshot(db);
      final parked = (snapshot['inaccessible_repos'] as List).cast<Map>();
      expect(
        parked.map((e) => e['repo_id']),
        [repo1.id],
        reason: 'the parked state survives the restart',
      );
    });

    test('watchRepoAccessForWorkspace streams the parked list', () async {
      await baselineThenFail(notFound);
      await sweeps(3);

      final frames = <List<Map<String, dynamic>>>[];
      final sub = accessPoller
          .watchRepoAccessForWorkspace('ws1')
          .listen(frames.add);
      await pump();
      expect(frames, isNotEmpty);
      expect(frames.last.map((e) => e['repo_id']), [repo1.id]);

      // Must complete promptly — a watch that only tears down on the next
      // snapshot write would leak the drift subscription per subscriber.
      await sub.cancel().timeout(const Duration(seconds: 5));
    });
  });

  // The branch→PR lookup behind "did this conversation already open a PR?".
  // It reads the snapshot this service already sweeps, so the answer costs a
  // cache read rather than a forge call — which is what makes it affordable
  // from a space surface that stays open while someone works.
  group('openPrForHeadBranch', () {
    Future<Map<String, dynamic>?> lookup(
      String branch, {
      String repoFullName = 'o/r1',
    }) => poller.openPrForHeadBranch(
      workspaceId: 'ws1',
      repoFullName: repoFullName,
      branch: branch,
    );

    Future<void> sweepTwoPrs() async {
      port.groups = [
        (repo: repo1, prs: [_pr(1), _pr(2)], hasMore: false),
      ];
      await poller.refreshNow('ws1');
      await pump();
    }

    test('finds the open PR pushed from a branch', () async {
      await sweepTwoPrs();

      expect((await lookup('f2'))?['number'], 2);
      expect((await lookup('f1'))?['number'], 1);
    });

    test('a branch with no open PR reports null', () async {
      await sweepTwoPrs();

      expect(await lookup('conv/a6fdc05e'), isNull);
    });

    test('the match is exact — git ref names are case-sensitive', () async {
      await sweepTwoPrs();

      expect(await lookup('F1'), isNull);
    });

    test('an empty branch reports null without reading the cache', () async {
      await sweepTwoPrs();

      expect(await lookup(''), isNull);
    });

    test('a repo outside the snapshot reports null', () async {
      await sweepTwoPrs();

      expect(await lookup('f1', repoFullName: 'o/other'), isNull);
    });

    // A workspace the poller has not reached yet must report "no PR", not
    // block on a sweep: the caller is painting a sidebar, and the answer
    // arrives on the next sweep.
    test('an unswept workspace reports null rather than fetching', () async {
      expect(await lookup('f1'), isNull);
      expect(port.probedRepoIds, isEmpty);
    });
  });

  // =========================================================================
  // Author-facing lanes: merge readiness, review decisions, checks.
  // =========================================================================
  group('author-facing notifications', () {
    late OpenPrPollingService authored;
    late List<Object> events;
    late List<StreamSubscription<Object>> subs;

    /// A poller that knows who the operator is. The default one in `setUp`
    /// deliberately has no `viewerLoginFor`, which is what keeps every other
    /// test in this file free of these lanes.
    void buildPoller({String viewer = 'u'}) {
      authored = OpenPrPollingService(
        fetchPort: port,
        workspaceRepository: workspaces,
        workspaceDbs: dbs,
        changeSignals: signals,
        prToWire: _prToWire,
        eventBus: bus,
        viewerLoginFor: (_) async => viewer,
        forUserId: 'user-1',
        now: () => now,
      );
    }

    setUp(() {
      events = [];
      subs = [
        bus.on<PrMergeReadinessChanged>().listen(events.add),
        bus.on<PrReviewDecisionChanged>().listen(events.add),
        bus.on<PrChecksStatusChanged>().listen(events.add),
      ];
      buildPoller();
    });

    tearDown(() async {
      for (final s in subs) {
        await s.cancel();
      }
      authored.dispose();
    });

    /// Sweeps [prs], baselining on the first call.
    Future<void> sweep(List<PullRequest> prs) async {
      port.groups = [(repo: repo1, prs: prs, hasMore: false)];
      await authored.refreshNow('ws1');
      await pump();
    }

    test('the baseline sweep announces nothing', () async {
      await sweep([_pr(1, checks: 'failing')]);
      expect(events, isEmpty);
    });

    test('checks going red fires once, and not again on a no-op sweep',
        () async {
      await sweep([_pr(1, checks: 'passing')]);
      await sweep([_pr(1, checks: 'failing')]);
      expect(events.whereType<PrChecksStatusChanged>(), hasLength(1));
      expect(
        events.whereType<PrChecksStatusChanged>().single.failing,
        isTrue,
      );

      await sweep([_pr(1, checks: 'failing')]);
      expect(
        events.whereType<PrChecksStatusChanged>(),
        hasLength(1),
        reason: 'the snapshot IS the dedupe',
      );
    });

    test('a failure names the check from one targeted lookup', () async {
      port.failingChecks[1] = (name: 'build', url: 'https://ci/1');
      await sweep([_pr(1, checks: 'passing')]);
      await sweep([_pr(1, checks: 'failing')]);

      final event = events.whereType<PrChecksStatusChanged>().single;
      expect(event.failingCheckName, 'build');
      expect(port.firstFailingCheckCalls, 1);
    });

    test('failing to pending announces nothing', () async {
      await sweep([_pr(1, checks: 'failing')]);
      await sweep([_pr(1, checks: 'pending')]);
      expect(events.whereType<PrChecksStatusChanged>(), isEmpty);
    });

    test('failing to passing announces recovery', () async {
      await sweep([_pr(1, checks: 'failing')]);
      await sweep([_pr(1, checks: 'passing')]);
      final event = events.whereType<PrChecksStatusChanged>().single;
      expect(event.failing, isFalse);
    });

    test('an approval carries the approver and the remaining count', () async {
      await sweep([
        _pr(
          1,
          checks: 'passing',
          reviewDecision: PrReviewDecision.reviewRequired,
          requestedReviewers: ['octocat', 'hubot'],
        ),
      ]);
      await sweep([
        _pr(
          1,
          checks: 'passing',
          reviewDecision: PrReviewDecision.approved,
          requestedReviewers: ['hubot'],
        ),
      ]);

      final event = events.whereType<PrReviewDecisionChanged>().single;
      expect(event.decision, 'approved');
      expect(event.approverLogin, 'octocat');
      expect(event.reviewersRemaining, 1);
      expect(
        port.latestApproverCalls,
        0,
        reason: 'the diff named them, so no fetch was needed',
      );
    });

    test('an unattributable approval falls back to one targeted lookup',
        () async {
      port.approvers[1] = 'someone-else';
      await sweep([
        _pr(
          1,
          checks: 'passing',
          reviewDecision: PrReviewDecision.reviewRequired,
        ),
      ]);
      await sweep([
        _pr(1, checks: 'passing', reviewDecision: PrReviewDecision.approved),
      ]);

      final event = events.whereType<PrReviewDecisionChanged>().single;
      expect(event.approverLogin, 'someone-else');
      expect(port.latestApproverCalls, 1);
    });

    test('becoming ready is confirmed with the forge before announcing',
        () async {
      port.mergeStates[1] = PrMergeableState.clean;
      await sweep([
        _pr(
          1,
          checks: 'passing',
          reviewDecision: PrReviewDecision.reviewRequired,
        ),
      ]);
      await sweep([
        _pr(1, checks: 'passing', reviewDecision: PrReviewDecision.approved),
      ]);

      final ready = events
          .whereType<PrMergeReadinessChanged>()
          .where((e) => e.ready);
      expect(ready, hasLength(1));
      expect(port.mergeStateCalls, 1);
    });

    test('a forge that will not confirm suppresses the ready edge', () async {
      // `mergeStates` unset → the fake answers `unknown` → not confirmed.
      await sweep([
        _pr(
          1,
          checks: 'passing',
          reviewDecision: PrReviewDecision.reviewRequired,
        ),
      ]);
      await sweep([
        _pr(1, checks: 'passing', reviewDecision: PrReviewDecision.approved),
      ]);

      expect(
        events.whereType<PrMergeReadinessChanged>().where((e) => e.ready),
        isEmpty,
      );
      expect(port.mergeStateCalls, 1);
    });

    test('a rejected confirmation leaves the edge to re-attempt', () async {
      await sweep([
        _pr(
          1,
          checks: 'passing',
          reviewDecision: PrReviewDecision.reviewRequired,
        ),
      ]);
      await sweep([
        _pr(1, checks: 'passing', reviewDecision: PrReviewDecision.approved),
      ]);
      // Now the forge can answer.
      port.mergeStates[1] = PrMergeableState.clean;
      await sweep([
        _pr(1, checks: 'passing', reviewDecision: PrReviewDecision.approved),
      ]);

      expect(
        events.whereType<PrMergeReadinessChanged>().where((e) => e.ready),
        hasLength(1),
      );
    });

    test('a PR the operator did not author is never announced', () async {
      await sweep([_pr(1, author: 'someone-else', checks: 'passing')]);
      await sweep([_pr(1, author: 'someone-else', checks: 'failing')]);
      expect(events, isEmpty);
    });

    test('the author match is case-insensitive', () async {
      await sweep([_pr(1, author: 'U', checks: 'passing')]);
      await sweep([_pr(1, author: 'U', checks: 'failing')]);
      expect(events.whereType<PrChecksStatusChanged>(), hasLength(1));
    });

    test('no signed-in operator means silence, not guessing', () async {
      authored.dispose();
      buildPoller(viewer: '');
      await sweep([_pr(1, checks: 'passing')]);
      await sweep([_pr(1, checks: 'failing')]);
      expect(events, isEmpty);
    });

    test('every event carries for_user_id for client-side routing', () async {
      await sweep([_pr(1, checks: 'passing')]);
      await sweep([_pr(1, checks: 'failing')]);
      final event = events.whereType<PrChecksStatusChanged>().single;
      expect(event.forUserId, 'user-1');
    });

    group('an enrichment the sweep could not read', () {
      // `checks_status` and `review_decision` come from a second, much heavier
      // GraphQL pass that GitHub answers with 502/504 under load. An unread
      // answer decodes to the same `none` the forge sends when there is
      // genuinely nothing — which is exactly what a failed overlay produces
      // here.
      PullRequest unread(int number, {String? headSha}) =>
          _pr(number, headSha: headSha);

      test('does not re-announce an approval it already announced', () async {
        await sweep([
          _pr(
            1,
            checks: 'passing',
            reviewDecision: PrReviewDecision.reviewRequired,
          ),
        ]);
        await sweep([
          _pr(
            1,
            checks: 'failing',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);
        expect(events.whereType<PrReviewDecisionChanged>(), hasLength(1));
        expect(events.whereType<PrChecksStatusChanged>(), hasLength(1));

        // The overlay times out, then answers again — the flap that spammed
        // one approval every few minutes for as long as GitHub kept 504ing.
        await sweep([unread(1)]);
        await sweep([
          _pr(
            1,
            checks: 'failing',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);

        expect(
          events.whereType<PrReviewDecisionChanged>(),
          hasLength(1),
          reason: 'an unread decision is not a decision that changed',
        );
        expect(
          events.whereType<PrChecksStatusChanged>(),
          hasLength(1),
          reason: 'an unread rollup is not CI going red again',
        );
      });

      test('keeps the last known state in the snapshot', () async {
        await sweep([
          _pr(
            1,
            checks: 'failing',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);
        await sweep([unread(1)]);

        final pr = ((await _readSnapshot(db))['repos'] as List)
            .cast<Map<String, dynamic>>()
            .single['prs'] as List;
        expect((pr.single as Map)['checks_status'], 'failing');
        expect((pr.single as Map)['review_decision'], 'approved');
      });

      test('still lets the next real transition through', () async {
        await sweep([
          _pr(
            1,
            checks: 'failing',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);
        await sweep([unread(1)]);
        await sweep([
          _pr(
            1,
            checks: 'passing',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);

        final recovery = events.whereType<PrChecksStatusChanged>().where(
          (e) => !e.failing,
        );
        expect(
          recovery,
          hasLength(1),
          reason: 'the flap used to swallow the green build that followed',
        );
      });

      test('does not flip merge readiness either', () async {
        // The readiness lane reads the same two fields, so the unread sweep
        // used to make a red, approved pull request evaluate as READY: an
        // empty requested-reviewer set with no decision satisfies reviews, and
        // `none` checks are not failing. Restoring the real values then fired
        // "no longer mergeable" off a state the forge never reported.
        // `mergeStates` is unset, so the fake answers `unknown` — the
        // unconfirmed path that leaves `mergeable_state` unrecognized and the
        // bogus `ready` standing as the next sweep's `before`.
        await sweep([
          _pr(
            1,
            checks: 'passing',
            reviewDecision: PrReviewDecision.reviewRequired,
          ),
        ]);
        await sweep([
          _pr(
            1,
            checks: 'failing',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);
        await sweep([unread(1)]);
        await sweep([
          _pr(
            1,
            checks: 'failing',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);

        expect(
          events.whereType<PrMergeReadinessChanged>(),
          isEmpty,
          reason: 'nothing about this PR moved: it was blocked throughout',
        );
      });

      test('a new head re-arms the checks lane', () async {
        await sweep([_pr(1, checks: 'failing', headSha: 'sha-1')]);
        expect(events.whereType<PrChecksStatusChanged>(), isEmpty);

        // The author pushes. A commit with no rollup yet is a real `none`, so
        // the failure that follows on the NEW commit is news again.
        await sweep([unread(1, headSha: 'sha-2')]);
        await sweep([_pr(1, checks: 'failing', headSha: 'sha-2')]);

        expect(
          events.whereType<PrChecksStatusChanged>().where((e) => e.failing),
          hasLength(1),
        );
      });

      test('a new head does not re-announce the approval', () async {
        await sweep([
          _pr(
            1,
            headSha: 'sha-1',
            reviewDecision: PrReviewDecision.reviewRequired,
          ),
        ]);
        await sweep([
          _pr(
            1,
            headSha: 'sha-1',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);
        await sweep([unread(1, headSha: 'sha-2')]);
        await sweep([
          _pr(
            1,
            headSha: 'sha-2',
            reviewDecision: PrReviewDecision.approved,
          ),
        ]);

        expect(
          events.whereType<PrReviewDecisionChanged>(),
          hasLength(1),
          reason:
              'the forge reports REVIEW_REQUIRED on a dismissal, never null, '
              'so a null decision is always a failed read',
        );
      });
    });

    test('a green draft never reports ready', () async {
      port.mergeStates[1] = PrMergeableState.clean;
      await sweep([
        _pr(
          1,
          isDraft: true,
          checks: 'passing',
          reviewDecision: PrReviewDecision.reviewRequired,
        ),
      ]);
      await sweep([
        _pr(
          1,
          isDraft: true,
          checks: 'passing',
          reviewDecision: PrReviewDecision.approved,
        ),
      ]);

      expect(
        events.whereType<PrMergeReadinessChanged>().where((e) => e.ready),
        isEmpty,
      );
    });
  });
}

/// Reads the persisted snapshot for [db]'s workspace.
Future<Map<String, dynamic>> _readSnapshot(WorkspaceDatabase db) async {
  final raw = await db.cacheDao.read(
    'ws1',
    OpenPrPollingService.cacheKind,
    OpenPrPollingService.cacheKey,
  );
  return jsonDecode(raw!) as Map<String, dynamic>;
}

/// The PR numbers the snapshot holds for [repoFullName], in wire order.
List<int> _numbersOf(Map<String, dynamic> snapshot, String repoFullName) {
  for (final raw in snapshot['repos'] as List) {
    if (raw is Map && raw['repo_full_name'] == repoFullName) {
      return [
        for (final pr in raw['prs'] as List) (pr as Map)['number'] as int,
      ];
    }
  }
  return const [];
}
