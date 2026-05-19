import 'dart:async';
import 'dart:convert';

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

PullRequest _pr(int number, {String title = 'PR', String checks = 'none'}) =>
    PullRequest(
      id: number,
      number: number,
      title: '$title $number',
      body: '',
      state: PrState.open,
      isDraft: false,
      author: const PrUser(login: 'u', avatarUrl: ''),
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      repoFullName: 'o/r1',
      htmlUrl: '',
      externalId: 'n$number',
      headSha: 's$number',
      baseRef: 'main',
      headRef: 'f$number',
      checksStatus: PrChecksStatus.values.firstWhere(
        (c) => c.name == checks,
        orElse: () => PrChecksStatus.none,
      ),
    );

/// A tiny wire mapper sufficient for snapshot diffing in tests (the real one
/// lives in the RPC catalog; the poller only relies on `number`, `title`,
/// `author`, `updated_at`, `head_sha`, `checks_status` and `review_decision`).
Map<String, dynamic> _prToWire(PullRequest pr) => {
  'number': pr.number,
  'title': pr.title,
  'author': {'login': pr.author?.login ?? ''},
  'updated_at': pr.updatedAt?.toIso8601String(),
  'head_sha': pr.headSha,
  'checks_status': pr.checksStatus.name,
  'review_decision': pr.reviewDecision.name,
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
