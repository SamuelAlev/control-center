import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/detect_pr_notifiable_transitions.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/evaluate_pr_merge_readiness.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/forge/github_rate_budget.dart';
import 'package:cc_server_core/src/pr_review/open_pr_fetch_port.dart';

export 'package:cc_server_core/src/pr_review/github_open_pr_fetch_adapter.dart';
export 'package:cc_server_core/src/pr_review/open_pr_fetch_port.dart';

part 'open_pr_poll_state.dart';

/// Polls open PRs per workspace (no webhook dependency) and pushes live updates.
///
/// Conditional list probes ([GitHubPrClient.probeOpenPullRequests]); fetch+diff+persist+events only on change.
/// Active watchers use [fastInterval] (+ checks every [checksEvery]); idle workspaces use [idleInterval].
/// While a workspace's GitHub [rateBudget] is low, the loop skips its GitHub
/// repositories (an explicit [refreshNow] still sweeps them).
class OpenPrPollingService {
  /// Creates an [OpenPrPollingService].
  OpenPrPollingService({
    required OpenPrFetchPort fetchPort,
    required WorkspaceRepository workspaceRepository,
    required WorkspaceDatabaseManager workspaceDbs,
    required PrChangeSignals changeSignals,
    required this._prToWire,
    this._eventBus,
    this._memberLoginsFor,
    this.fastInterval = const Duration(seconds: 60),
    this.idleInterval = const Duration(minutes: 2),
    this.checksEvery = 2,
    this.accessFailureThreshold = 3,
    this.inaccessibleRetryInterval = const Duration(minutes: 10),
    this.rateBudget,
    DateTime Function()? now,
  }) : _port = fetchPort,
       _workspaces = workspaceRepository,
       _dbs = workspaceDbs,
       _signals = changeSignals,
       _now = now ?? DateTime.now;

  /// Cache kind for the persisted per-workspace snapshot.
  static const cacheKind = 'openPrList';

  /// Cache key (single row per workspace) for the persisted snapshot.
  static const cacheKey = 'v1';

  /// Persisted exact-head history, separate from the open-list wire frame.
  static const branchHistoryCacheKind = 'branchPrHistory';

  /// Maximum age of a successfully resolved branch inventory.
  static const branchHistoryRefreshInterval = Duration(minutes: 5);

  /// Wait after a branch's first failed history lookup. Doubles per further
  /// failure, capped at [branchHistoryRefreshInterval] (which also covers
  /// GitHub's hourly rate-limit window resetting within a few minutes of a
  /// storm).
  static const branchHistoryRetryBase = Duration(seconds: 30);

  /// Minimum spacing between sweeps of one workspace triggered by
  /// subscription churn (`pollSoon` bursts), so re-navigating to the PR list
  /// doesn't hammer GitHub.
  static const _pollSoonMinGap = Duration(seconds: 15);

  final OpenPrFetchPort _port;
  final WorkspaceRepository _workspaces;
  final WorkspaceDatabaseManager _dbs;
  final PrChangeSignals _signals;

  /// The workspace members' own logins on a forge, keyed by Control Center
  /// user id (an empty login = that member has not connected the forge).
  ///
  /// The author-facing notifications (ready to merge, approved, checks failed)
  /// are gated on it: this poller sweeps EVERY open PR in every linked repo,
  /// so without the gate a busy monorepo announces strangers' work. A PR is
  /// announced only to the member whose login authored it, stamped with that
  /// member's user id. Null disables those lanes entirely.
  final MemberForgeLogins? _memberLoginsFor;

  /// Per-pass budget for the targeted confirmation/attribution fetches. Both
  /// are one REST call each on a transition edge; capping them keeps a sweep
  /// that happens to move twenty PRs at once from turning into twenty extra
  /// round trips. A skipped edge is not lost — the snapshot still holds the
  /// old value, so it is re-detected next sweep.
  static const _maxMergeConfirmsPerPass = 5;
  static const _maxApproverLookupsPerPass = 5;

  /// Merged/closed history kept for space-branch lookups: entries older than
  /// this are dropped on the next write.
  static const terminalRetention = Duration(days: 30);

  /// At most this many merged/closed entries per workspace (newest kept).
  static const maxTerminalEntries = 500;

  /// Repos probed concurrently per sweep.
  static const _probeConcurrency = 8;

  /// Pull requests that look ready but whose forge verdict could not be read
  /// yet, keyed `workspaceId|repoId|number`.
  ///
  /// The snapshot advances on every sweep, so once a PR has been recorded as
  /// approved-and-green the "became ready" EDGE is gone — a sweep that failed
  /// to confirm would silently never announce it. This set is what turns that
  /// into a deferral: the PR is re-confirmed on later sweeps until the forge
  /// answers, and is dropped the moment it stops looking ready.
  final Set<String> _pendingReadyConfirm = {};

  /// The snapshot cache lives in the polled workspace's own database file, so
  /// every sweep resolves it from the workspace it is sweeping.
  CacheDao _cache(String workspaceId) => _dbs.of(workspaceId).cacheDao;

  final Map<String, dynamic> Function(PullRequest pr) _prToWire;
  final DomainEventBus? _eventBus;
  final DateTime Function() _now;

  /// Sweep cadence for workspaces with at least one active list watcher.
  final Duration fastInterval;

  /// Sweep cadence for workspaces nobody is currently watching (keeps
  /// new-PR/merge notifications flowing at modest cost). Probes are
  /// ETag-conditional and GitHub 304s are rate-limit-free, so the idle floor
  /// costs almost nothing while keeping merge/status detection and
  /// `ExternalPrDetected` fresh.
  final Duration idleInterval;

  /// Run the checks-only pass every N fast ticks (CI state does not bump the
  /// list ETag, so it needs its own — pricier, GraphQL — poll).
  final int checksEvery;

  /// Consecutive access-denied probes (404/401/403) before a repo is parked.
  /// A single denial could be a GitHub blip; this many in a row means the
  /// credential genuinely cannot see the repo — most commonly a GitHub App not
  /// installed on the repo's org.
  final int accessFailureThreshold;

  /// How often a parked repo is re-probed. Its denial only clears when a human
  /// acts (installs the app, fixes access), so the fast cadence would burn a
  /// failing request per minute and spam the log for nothing. An explicit
  /// refresh always retries immediately.
  final Duration inaccessibleRetryInterval;

  /// GitHub rate-limit readings per workspace (see the class doc).
  final GitHubRateBudget? rateBudget;

  final Map<String, _WorkspacePollState> _states = {};

  final Map<String, Future<List<Map<String, dynamic>>?>> _historyInflight = {};
  Timer? _timer;
  bool _disposed = false;

  /// True while [_onTick] walks the workspaces. A tick that fires before the
  /// previous one finished is dropped: the walk awaits each sweep in turn, so
  /// a slow forge would otherwise stack ticks behind each other.
  bool _ticking = false;

  _WorkspacePollState _stateFor(String workspaceId) =>
      _states.putIfAbsent(workspaceId, _WorkspacePollState.new);

  /// Starts the periodic sweep loop (plus one immediate pass). Idempotent.
  void start() {
    if (_timer != null || _disposed) {
      return;
    }
    _timer = Timer.periodic(fastInterval, (_) => unawaited(_onTick()));
    unawaited(_onTick());
  }

  /// Stops the loop and completes open watch streams' interest bookkeeping.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    for (final st in _states.values) {
      unawaited(st.historyRefresh.close());
      unawaited(st.sweepingChanges.close());
    }
  }

  Future<void> _onTick() async {
    if (_disposed || _ticking) {
      return;
    }
    _ticking = true;
    try {
      final List<Workspace> workspaces;
      try {
        workspaces = await _workspaces.watchAll().first;
      } on Object catch (e) {
        CcHostLog.warning('open_pr_poll: workspace enumeration failed: $e');
        return;
      }
      for (final w in workspaces) {
        final workspaceId = w.id;
        final st = _stateFor(workspaceId);
        final watched = st.interest > 0;
        if (watched) {
          // Counted per workspace: a workspace that only just gained a watcher
          // gets its checks pass on its own cadence, not the global one.
          st.watchedTicks++;
          await _sweep(
            workspaceId,
            includeChecks: st.watchedTicks % checksEvery == 0,
            force: false,
          );
        } else {
          final last = st.lastSweepAt;
          if (last == null || _now().difference(last) >= idleInterval) {
            await _sweep(workspaceId, includeChecks: false, force: false);
          }
        }
      }
    } finally {
      _ticking = false;
    }
  }

  /// The live open-PR list for [workspaceId], in the `pr.listOpenForWorkspace`
  /// wire shape plus a `sweep_in_flight` flag. Registers watcher interest for
  /// the fast cadence, kicks an immediate freshness pass, then follows the
  /// persisted snapshot's Drift watch — every poller write pushes to every
  /// subscriber.
  ///
  /// Every emitted frame is tagged with the live sweep-in-flight flag and a
  /// flag transition re-emits the last frame: the persisted snapshot arrives
  /// instantly (or an authenticated-empty frame when no sweep ever landed), so
  /// without the flag the client would render stale/empty data with no loading
  /// signal while the real GitHub fetch is still running.
  Stream<Map<String, dynamic>> watchOpenForWorkspace(
    String workspaceId,
  ) async* {
    final st = _stateFor(workspaceId);
    final controller = StreamController<Map<String, dynamic>>();
    Map<String, dynamic>? lastFrame;
    var sweeping = st.inflight != null;
    String? lastEmitted;
    StreamSubscription<String?>? snapshotSub;
    StreamSubscription<bool>? sweepingSub;

    void emit() {
      final frame = lastFrame;
      if (frame == null) {
        return;
      }
      final tagged = <String, dynamic>{...frame, 'sweep_in_flight': sweeping};
      // Collapse back-to-back identical frames (a flag-transition re-emit can
      // race the cache watch's delivery of the same snapshot).
      final encoded = jsonEncode(tagged);
      if (encoded == lastEmitted) {
        return;
      }
      lastEmitted = encoded;
      controller.add(tagged);
    }

    // Interest is taken inside the try so whatever throws below (opening the
    // workspace's cache, say) still gives it back in the finally — a leaked
    // count would keep the workspace on the fast cadence forever.
    try {
      st.interest++;
      snapshotSub = _cache(workspaceId)
          .watch(workspaceId, cacheKind, cacheKey)
          .listen((raw) {
            final frame = _decodeSnapshotFrame(raw);
            if (frame == null) {
              return;
            }
            lastFrame = frame;
            emit();
          });
      sweepingSub = st.sweepingChanges.stream.listen((s) {
        sweeping = s;
        emit();
      });
      unawaited(pollSoon(workspaceId));
      // yield* (not `await for`): an async* generator only honors
      // cancellation at a yield point, so forwarding the merged stream
      // through yield* is what lets an unsubscribe tear this stream down
      // immediately instead of blocking until the next snapshot write.
      yield* controller.stream;
    } finally {
      await snapshotSub?.cancel();
      await sweepingSub?.cancel();
      unawaited(controller.close());
      st.interest--;
    }
  }

  /// Decodes one persisted snapshot row into a wire frame. A missing row (no
  /// sweep has landed yet) becomes an authenticated-empty frame so the
  /// client's loading state stays sane; a corrupt row is skipped (null) — the
  /// next sweep rewrites it.
  static Map<String, dynamic>? _decodeSnapshotFrame(String? raw) {
    if (raw == null) {
      return const <String, dynamic>{
        'authenticated': true,
        'repos': <Map<String, dynamic>>[],
      };
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        // Terminal history feeds only space-branch lookups and the baseline
        // set only the poller, never the open queue's client payload.
        parsed
          ..remove('terminal_prs')
          ..remove(_baselinedKey);
        return parsed;
      }
    } on Object {
      // Corrupt snapshot row — skip.
    }
    return null;
  }

  /// The inaccessible-repo list for [workspaceId], live — the lite feed for
  /// surfaces (repos settings) that need the access notice without dragging
  /// the whole open-PR payload along or registering list interest for the fast
  /// cadence. Follows the same persisted snapshot as [watchOpenForWorkspace];
  /// subscribing kicks one freshness pass so a just-opened settings page shows
  /// current state.
  Stream<List<Map<String, dynamic>>> watchRepoAccessForWorkspace(
    String workspaceId,
  ) async* {
    unawaited(pollSoon(workspaceId));
    final controller = StreamController<List<Map<String, dynamic>>>();
    String? lastEmitted;
    final snapshotSub = _cache(workspaceId)
        .watch(workspaceId, cacheKind, cacheKey)
        .listen((raw) {
          final frame = _decodeSnapshotFrame(raw);
          if (frame == null) {
            return;
          }
          final list = [
            for (final e in (frame['inaccessible_repos'] as List?) ?? const [])
              if (e is Map) e.cast<String, dynamic>(),
          ];
          final encoded = jsonEncode(list);
          if (encoded == lastEmitted) {
            return;
          }
          lastEmitted = encoded;
          controller.add(list);
        });
    try {
      // yield* (not `await for`), for the same reason as
      // [watchOpenForWorkspace]: an async* generator only honors cancellation
      // at a yield point, so an unsubscribe must not block until the next
      // snapshot write.
      yield* controller.stream;
    } finally {
      await snapshotSub.cancel();
      unawaited(controller.close());
    }
  }

  /// Ticks on persisted open-list changes and on the workspace's normal sweep
  /// cadence, including a 304: historical branches can acquire a PR entirely
  /// between open-list probes. No independent timer or per-space poller.
  Stream<void> watchSnapshotChanges(String workspaceId) async* {
    final st = _stateFor(workspaceId);
    final controller = StreamController<void>();
    final snapshotSub = _cache(workspaceId)
        .watch(workspaceId, cacheKind, cacheKey)
        .listen((_) => controller.add(null));
    final refreshSub = st.historyRefresh.stream.listen(
      (_) => controller.add(null),
    );
    try {
      unawaited(pollSoon(workspaceId));
      yield* controller.stream;
    } finally {
      await snapshotSub.cancel();
      await refreshSub.cancel();
      unawaited(controller.close());
    }
  }

  /// Requests a near-term freshness pass for [workspaceId] (subscribe, or an
  /// external hint like a GitHub notification). Throttled so bursts collapse.
  Future<void> pollSoon(String workspaceId) async {
    final st = _stateFor(workspaceId);
    final last = st.lastSweepAt;
    if (st.inflight != null ||
        (last != null && _now().difference(last) < _pollSoonMinGap)) {
      return;
    }
    await _sweep(workspaceId, includeChecks: st.interest > 0, force: false);
  }

  /// An explicit user refresh: sweep now, bypassing ETag short-circuits, with
  /// the checks pass included. The returned future resolves only once a full
  /// forced sweep has landed (fetched + persisted) — the client's refresh
  /// spinner rides on it.
  Future<void> refreshNow(String workspaceId) {
    // An explicit refresh retries failed branch lookups at once, like parked
    // repos.
    _stateFor(workspaceId).historyBackoff.clear();
    return _sweep(workspaceId, includeChecks: true, force: true);
  }

  /// The open pull request in [repoFullName] whose HEAD branch is [branch], as
  /// the same wire map the list ops emit — or null when no open PR is pushed
  /// from that branch.
  ///
  /// Answered entirely from the persisted per-workspace snapshot this service
  /// already sweeps, so "does this conversation's branch have a PR?" costs a
  /// cache read rather than a forge call. That is what makes it affordable to
  /// ask from a space surface, which is open for as long as someone is working.
  /// A workspace the poller has not swept yet simply reports null — the answer
  /// arrives on the next sweep rather than blocking on one.
  ///
  /// Ref names are case-sensitive on git's side, so the comparison is exact.
  Future<Map<String, dynamic>?> openPrForHeadBranch({
    required String workspaceId,
    required String repoFullName,
    required String branch,
  }) async {
    if (branch.isEmpty) {
      return null;
    }
    // The source-control poll asks this every few seconds for a branch with
    // no local upstream. The in-memory snapshot is the same map the sweep
    // just persisted; reading the cache row again would re-decode the whole
    // open-PR list on that cadence.
    final st = _stateFor(workspaceId);
    final snapshot = st.snapshotLoaded
        ? st.snapshot
        : await _readPersistedSnapshot(workspaceId);
    for (final wire in _prsByNumber(snapshot, repoFullName).values) {
      if (wire['head_ref'] == branch) {
        return wire;
      }
    }
    return null;
  }

  /// Complete branch history is fetched only for linked space head refs, then
  /// persisted per workspace/repo/branch. The existing workspace sweep ticks
  /// refresh it on a bounded cadence so a PR opened and merged between
  /// open-list sweeps is still discovered. A failed/incomplete lookup is never
  /// an empty answer: `complete` must gate "every PR merged".
  Future<({List<Map<String, dynamic>> prs, bool complete})> prsForHeadBranch({
    required String workspaceId,
    required Repo repo,
    required String branch,
  }) async {
    if (branch.isEmpty) {
      return (prs: <Map<String, dynamic>>[], complete: false);
    }
    final key = jsonEncode([repo.id, repo.fullName, branch]);
    final raw = await _cache(
      workspaceId,
    ).read(workspaceId, branchHistoryCacheKind, key);
    Map<String, dynamic>? history;
    try {
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded['repo_id'] == repo.id &&
          decoded['repo_full_name'] == repo.fullName &&
          decoded['branch'] == branch &&
          decoded['prs'] is List) {
        history = decoded;
      }
    } on Object {
      // Corrupt history cannot be evidence for "all merged".
    }
    final checkedAt = DateTime.tryParse(
      history?['checked_at'] as String? ?? '',
    );
    var complete =
        checkedAt != null &&
        _now().difference(checkedAt) < branchHistoryRefreshInterval;
    final backoff = _stateFor(workspaceId).historyBackoff[key];
    if (!complete && (backoff == null || !_now().isBefore(backoff.retryAt))) {
      final requestKey = jsonEncode([workspaceId, key]);
      final discovered = await (_historyInflight[requestKey] ??=
          _discoverBranchHistory(workspaceId, repo, branch, key).whenComplete(
            () {
              // Returning remove's Future would make this future await itself.
              _historyInflight.remove(requestKey);
            },
          ));
      if (discovered != null) {
        history = {
          'prs': discovered,
          'repo_id': repo.id,
          'repo_full_name': repo.fullName,
          'branch': branch,
          'checked_at': _now().toIso8601String(),
        };
        complete = true;
      }
    }
    final st = _stateFor(workspaceId);
    final snapshot = st.snapshotLoaded
        ? st.snapshot
        : await _readPersistedSnapshot(workspaceId);
    final byNumber = <int, Map<String, dynamic>>{};
    void include(Object? value) {
      if (value is! Map ||
          value['number'] is! num ||
          value['head_ref'] != branch) {
        return;
      }
      byNumber[(value['number'] as num).toInt()] = value
          .cast<String, dynamic>();
    }

    for (final pr in (history?['prs'] as List?) ?? const []) {
      include(pr);
    }
    for (final raw in (snapshot?['terminal_prs'] as List?) ?? const []) {
      if (raw is Map &&
          raw['repo_id'] == repo.id &&
          raw['repo_full_name'] == repo.fullName) {
        include(raw['pull_request']);
      }
    }
    for (final raw in (snapshot?['repos'] as List?) ?? const []) {
      if (raw is Map &&
          raw['repo_id'] == repo.id &&
          raw['repo_full_name'] == repo.fullName) {
        for (final pr in (raw['prs'] as List?) ?? const []) {
          include(pr);
        }
      }
    }
    final inaccessible = (snapshot?['inaccessible_repos'] as List?) ?? const [];
    return (
      prs: byNumber.values.toList(),
      complete:
          complete &&
          !inaccessible.any(
            (entry) => entry is Map && entry['repo_id'] == repo.id,
          ) &&
          !byNumber.values.any((pr) => pr['status_unconfirmed'] == true),
    );
  }

  /// Looks [branch] up and records the outcome: a success clears its backoff,
  /// a failure (null) pushes the next attempt out.
  Future<List<Map<String, dynamic>>?> _discoverBranchHistory(
    String workspaceId,
    Repo repo,
    String branch,
    String key,
  ) async {
    final found = await _fetchBranchHistory(workspaceId, repo, branch, key);
    final backoffs = _stateFor(workspaceId).historyBackoff;
    if (found != null) {
      backoffs.remove(key);
      return found;
    }
    final failures = (backoffs[key]?.failures ?? 0) + 1;
    final wait = branchHistoryRetryBase * (1 << (failures - 1).clamp(0, 10));
    backoffs[key] = _BranchHistoryBackoff(
      failures: failures,
      retryAt: _now().add(
        wait > branchHistoryRefreshInterval
            ? branchHistoryRefreshInterval
            : wait,
      ),
    );
    return null;
  }

  Future<List<Map<String, dynamic>>?> _fetchBranchHistory(
    String workspaceId,
    Repo repo,
    String branch,
    String key,
  ) async {
    final List<Map<String, dynamic>> wires;
    try {
      final prs = await _port.fetchBranchHistory(
        repo,
        branch,
        workspaceId: workspaceId,
      );
      if (prs == null) {
        return null;
      }
      wires = [
        for (final pr in prs)
          if (pr.headRef == branch) _prToWire(pr),
      ];
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: branch history lookup failed for ${repo.fullName}: $e',
      );
      return null;
    }
    // The forge answered: that answer stands even when caching it fails. The
    // next call re-fetches instead of reading a cached row, which is all a
    // failed write costs.
    try {
      await _cache(workspaceId).put(
        workspaceId,
        branchHistoryCacheKind,
        key,
        jsonEncode({
          'repo_id': repo.id,
          'repo_full_name': repo.fullName,
          'branch': branch,
          'checked_at': _now().toIso8601String(),
          'prs': wires,
        }),
      );
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: branch history persist failed for ${repo.fullName}: $e',
      );
    }
    return wires;
  }

  /// Runs (or joins) a sweep of [workspaceId]. Only one sweep runs per
  /// workspace at a time: a non-forced caller (tick, pollSoon) coalesces into
  /// the sweep already in flight, while a forced caller (refreshNow) queues a
  /// full forced sweep behind it — resolving early would stop the client's
  /// refresh spinner before the data it asked for ever landed.
  Future<void> _sweep(
    String workspaceId, {
    required bool includeChecks,
    required bool force,
  }) {
    if (_disposed) {
      return Future.value();
    }
    final st = _stateFor(workspaceId);
    final running = st.inflight;
    if (running == null) {
      // Guarded: dispose() closes the controller while a sweep can still be
      // completing behind it.
      if (!st.sweepingChanges.isClosed) {
        st.sweepingChanges.add(true);
      }
      final sweep =
          _runSweep(
            workspaceId,
            st,
            includeChecks: includeChecks,
            force: force,
          ).whenComplete(() {
            st.inflight = null;
            if (!st.sweepingChanges.isClosed) {
              st.sweepingChanges.add(false);
            }
          });
      st.inflight = sweep;
      return sweep;
    }
    if (!force) {
      return running;
    }
    // _runSweep never throws (it swallows its own errors), so chaining on the
    // in-flight future is safe. Concurrent forced refreshes share one queued
    // sweep.
    return st.queuedForced ??= running.then((_) {
      st.queuedForced = null;
      return _sweep(workspaceId, includeChecks: true, force: true);
    });
  }

  Future<void> _runSweep(
    String workspaceId,
    _WorkspacePollState st, {
    required bool includeChecks,
    required bool force,
  }) async {
    try {
      st.lastSweepAt = _now();
      final linked = await _workspaces
          .watchReposForWorkspace(workspaceId)
          .first;
      // A low GitHub quota pauses only this workspace's GitHub repositories
      // (an explicit refresh still runs); GitLab and Bitbucket have their own
      // limits. Paused repos are left out of the probe and the fetch, so —
      // like any unresolved repo — they keep their previous snapshot entries
      // and publish no events.
      final githubPaused =
          !force &&
          (rateBudget?.backsOff(workspaceId, poller: 'open_pr_poll') ?? false);
      final repos = [
        for (final r in linked)
          if (r.hasForgeRemote &&
              !(githubPaused && r.forge == ForgeHost.github))
            r,
      ];

      if (!st.snapshotLoaded) {
        st.snapshot = await _readPersistedSnapshot(workspaceId);
        st.snapshotLoaded = true;
        _seedAccessFromSnapshot(st);
      }

      // A repo unlinked from the workspace leaves the snapshot (its open PRs,
      // its merged/closed history, its baseline mark) on the next sweep, not
      // never.
      final linkedIds = {for (final r in linked) r.id};
      final pruned = _pruneUnlinked(st, linkedIds);
      if (repos.isEmpty) {
        if (pruned) {
          await _persistSnapshot(workspaceId, st.snapshot!);
        }
        return;
      }

      // Probe first even on forced/first sweeps. The probe's ETag is held,
      // not stored, until the fetch below has answered for the repo: storing
      // it up front would turn the next probe into a 304 for a list this
      // server never actually read, freezing the repo until it next changes.
      final changedIds = <String>{};
      final probedEtags = <String, String>{};
      var accessChanged = false;
      final toProbe = <Repo>[];
      for (final repo in repos) {
        final access = st.accessByRepoId[repo.id];
        // Parked repos are re-probed on the slow cadence only (or on an
        // explicit refresh): their denial is deterministic until a human
        // installs the app or fixes the access, and probing every tick burns a
        // failing request per minute and a log line with it.
        if (access != null && access.parked) {
          if (!force && !access.isRetryDue(_now(), inaccessibleRetryInterval)) {
            continue;
          }
          access.lastRetryAt = _now();
        }
        toProbe.add(repo);
      }
      for (var i = 0; i < toProbe.length; i += _probeConcurrency) {
        final chunk = toProbe.skip(i).take(_probeConcurrency);
        await Future.wait(
          chunk.map((repo) async {
            try {
              final probe = await _port.probeRepo(
                repo,
                force ? null : st.etagByRepoId[repo.id],
                workspaceId: workspaceId,
              );
              final etag = probe.etag;
              if (etag != null && etag.isNotEmpty) {
                probedEtags[repo.id] = etag;
              }
              if (probe.changed) {
                changedIds.add(repo.id);
              }
              if (_noteRepoAccessible(st, repo)) {
                accessChanged = true;
              }
            } on Object catch (e) {
              final reason = _accessFailureReason(e);
              if (reason == null) {
                // Transient (timeout, rate limit, 5xx): not an access signal.
                CcHostLog.warning(
                  'open_pr_poll: probe failed for ${repo.fullName}: $e',
                );
              } else if (_noteAccessFailure(st, repo, reason)) {
                accessChanged = true;
              } else if (!(st.accessByRepoId[repo.id]?.parked ?? false)) {
                // Below the parking threshold: still worth a log line. Once
                // parked, the state is surfaced in the UI instead of the log.
                CcHostLog.warning(
                  'open_pr_poll: probe failed for ${repo.fullName}: $e',
                );
              }
            }
          }),
        );
      }

      // Parked repos are excluded from fetches: their batch aliases can only
      // error, and their previous snapshot entries are carried over anyway.
      final fetchable = [
        for (final r in repos)
          if (!(st.accessByRepoId[r.id]?.parked ?? false)) r,
      ];
      // Only the repos whose list moved are re-read. A forced or first sweep
      // reads everything; otherwise one changed repo (or a forge with no
      // conditional requests, which always reports "changed") no longer drags
      // every other repo's heavy fetch along with it.
      final toFetch = [
        for (final r in fetchable)
          if (force || st.snapshot == null || changedIds.contains(r.id)) r,
      ];
      // A 304 confirms the ETag already held; it can be stored as-is.
      for (final r in fetchable) {
        final etag = probedEtags[r.id];
        if (etag != null && !changedIds.contains(r.id)) {
          st.etagByRepoId[r.id] = etag;
        }
      }

      var persisted = false;
      final fetchedIds = <String>{};
      if (toFetch.isNotEmpty) {
        final result = await _port.fetchGroups(
          toFetch,
          workspaceId: workspaceId,
        );
        final requested = {for (final r in toFetch) r.id};
        final resolvedIds = result.resolvedRepoIds.intersection(requested);
        // Now the list has been read, its ETag may advance. An unresolved
        // repo keeps the old one, so the next probe answers 200 and retries.
        for (final id in resolvedIds) {
          final etag = probedEtags[id];
          if (etag != null) {
            st.etagByRepoId[id] = etag;
          }
        }
        if (resolvedIds.isEmpty) {
          // The forges answered for nothing. The batch query tolerates
          // partial failure, so a service incident returns "no repos" exactly
          // like a workspace whose queues are all empty — and persisting that
          // would overwrite a good snapshot with an empty one, tell every
          // client the inbox is clear and publish a merged/closed event for
          // every PR that "vanished". Keep the last snapshot and try again
          // next tick.
          CcHostLog.warning(
            'open_pr_poll: the forges resolved 0 of ${toFetch.length} repos '
            'for $workspaceId — keeping the previous snapshot',
          );
        } else {
          fetchedIds.addAll(resolvedIds);
          final resolved = [
            for (final r in toFetch)
              if (resolvedIds.contains(r.id)) r,
          ];
          // A partial answer updates only the repos it covered: the
          // unresolved ones keep their previous entries rather than
          // disappearing, and the diff runs over the resolved repos alone so
          // they publish no events.
          final fresh = _snapshotFromGroups(
            [
              for (final g in result.groups)
                if (resolvedIds.contains(g.repo.id)) g,
            ],
            previous: st.snapshot,
            resolvedRepoIds: resolvedIds,
            inaccessible: _inaccessibleWire(st),
          );
          if (resolved.length < toFetch.length) {
            CcHostLog.warning(
              'open_pr_poll: the forges resolved ${resolved.length} of '
              '${toFetch.length} repos for $workspaceId — the rest keep their '
              'previous entries',
            );
          }
          await _diffAndPublish(
            workspaceId,
            resolved,
            st.snapshot,
            fresh,
            _SweepContext(),
          );
          st.snapshot = fresh;
          await _persistSnapshot(workspaceId, fresh);
          persisted = true;
        }
      }
      if (!persisted && (accessChanged || pruned)) {
        // Access transitions alone (a repo parked, or one recovering behind a
        // 304) still have to reach every client's notice.
        await _persistAccessOnly(workspaceId, st);
      }
      if (st.snapshot != null) {
        // Both run whatever the probes said: CI state never bumps a list
        // ETag, and a merged/closed lookup that failed must be retried even in
        // a workspace where some repo changes every sweep.
        final unfetched = [
          for (final r in fetchable)
            if (!fetchedIds.contains(r.id)) r,
        ];
        if (includeChecks && unfetched.isNotEmpty) {
          await _checksPass(workspaceId, unfetched, st, _SweepContext());
        }
        await _resolveUnknownTerminals(workspaceId, fetchable, st);
      }
    } on Object catch (e) {
      CcHostLog.warning('open_pr_poll: sweep failed for $workspaceId: $e');
    } finally {
      if (!st.historyRefresh.isClosed) {
        st.historyRefresh.add(null);
      }
    }
  }

  /// Drops every snapshot trace of repos no longer linked to the workspace.
  /// Returns whether anything was removed.
  bool _pruneUnlinked(_WorkspacePollState st, Set<String> linkedIds) {
    final snapshot = st.snapshot;
    if (snapshot == null) {
      return false;
    }
    bool keep(Object? raw) =>
        raw is! Map ||
        raw['repo_id'] is! String ||
        linkedIds.contains(raw['repo_id']);
    final repos = (snapshot['repos'] as List?) ?? const [];
    final terminal = (snapshot['terminal_prs'] as List?) ?? const [];
    final baselined = snapshot[_baselinedKey] as List?;
    final keptRepos = repos.where(keep).toList();
    final keptTerminal = terminal.where(keep).toList();
    final keptBaselined = baselined?.where(linkedIds.contains).toList();
    if (keptRepos.length == repos.length &&
        keptTerminal.length == terminal.length &&
        (baselined == null || keptBaselined!.length == baselined.length)) {
      return false;
    }
    st.snapshot = {
      ...snapshot,
      'repos': keptRepos,
      'terminal_prs': keptTerminal,
      _baselinedKey: ?keptBaselined,
    };
    return true;
  }

  /// The access-denial code carried by [error], or null when the failure is
  /// transient. GitHub answers a credential that cannot see a repo with 404
  /// (not 403) to avoid leaking its existence — for a registered repo that is
  /// an access problem, not a missing resource.
  static String? _accessFailureReason(Object error) {
    if (error is! NetworkException) {
      return null;
    }
    return switch (error.code) {
      'not_found' || 'auth_error' || 'installation_suspended' => error.code,
      _ => null,
    };
  }

  /// Records a successful probe of [repo]. Returns true when this recovered a
  /// parked repo (an access transition worth persisting).
  bool _noteRepoAccessible(_WorkspacePollState st, Repo repo) {
    final access = st.accessByRepoId.remove(repo.id);
    if (access == null || !access.parked) {
      return false;
    }
    CcHostLog.info('open_pr_poll: ${repo.fullName} is accessible again');
    return true;
  }

  /// Records an access-denied probe of [repo]. Returns true when this parked
  /// the repo (an access transition worth persisting).
  bool _noteAccessFailure(_WorkspacePollState st, Repo repo, String reason) {
    final access = st.accessByRepoId.putIfAbsent(
      repo.id,
      () => _RepoAccessState(repoFullName: repo.fullName),
    );
    access
      ..repoFullName = repo.fullName
      ..consecutiveFailures += 1
      ..reason = reason;
    final threshold = reason == 'installation_suspended'
        ? 1
        : accessFailureThreshold;
    if (access.parked || access.consecutiveFailures < threshold) {
      return false;
    }
    access
      ..parked = true
      ..since = _now()
      ..lastRetryAt = _now();
    CcHostLog.warning(
      'open_pr_poll: parking ${repo.fullName} — not accessible ($reason) '
      'after ${access.consecutiveFailures} consecutive probes; retrying every '
      '${inaccessibleRetryInterval.inMinutes}m. On GitHub, resume a suspended '
      'App installation, install the App on the owner, or make sure the '
      'workspace\'s accountable person can see the repo; on GitLab or '
      'Bitbucket, use a token that can.',
    );
    return true;
  }

  /// The parked repos in wire form, sorted for a stable frame encoding.
  List<Map<String, dynamic>> _inaccessibleWire(_WorkspacePollState st) {
    final entries = [
      for (final e in st.accessByRepoId.entries)
        if (e.value.parked)
          <String, dynamic>{
            'repo_id': e.key,
            'repo_full_name': e.value.repoFullName,
            'reason': e.value.reason,
            'since': e.value.since?.toIso8601String(),
          },
    ];
    entries.sort(
      (a, b) => (a['repo_full_name']! as String).compareTo(
        b['repo_full_name']! as String,
      ),
    );
    return entries;
  }

  /// Re-arms access bookkeeping from the persisted snapshot, so a restart
  /// keeps parked repos parked (and the notice visible) instead of silently
  /// re-hammering them until they re-earn the threshold.
  void _seedAccessFromSnapshot(_WorkspacePollState st) {
    for (final raw
        in (st.snapshot?['inaccessible_repos'] as List?) ?? const []) {
      if (raw is! Map) {
        continue;
      }
      final id = raw['repo_id'] as String?;
      final fullName = raw['repo_full_name'] as String?;
      if (id == null || fullName == null) {
        continue;
      }
      st.accessByRepoId[id] = _RepoAccessState(repoFullName: fullName)
        ..parked = true
        ..consecutiveFailures = accessFailureThreshold
        ..reason = raw['reason'] as String? ?? 'not_found'
        ..since = DateTime.tryParse(raw['since'] as String? ?? '');
    }
  }

  /// Rewrites only the snapshot's access list, leaving the PR entries as they
  /// are — the path for sweeps where nothing but accessibility moved.
  Future<void> _persistAccessOnly(
    String workspaceId,
    _WorkspacePollState st,
  ) async {
    final updated = <String, dynamic>{
      'authenticated': true,
      'repos': <dynamic>[],
      ...?st.snapshot,
      'inaccessible_repos': _inaccessibleWire(st),
    };
    st.snapshot = updated;
    await _persistSnapshot(workspaceId, updated);
  }

  /// Snapshot field listing the repo ids a fetch has answered for at least
  /// once. A repo outside it is on its first read: its open PRs are recorded
  /// without announcing them, exactly like the workspace's first sweep.
  static const _baselinedKey = 'baselined_repo_ids';

  /// The repo ids [snapshot] marks as baselined, or null for a snapshot
  /// persisted before the per-repo mark existed (every repo in it counts as
  /// baselined — the old workspace-level rule).
  static Set<String>? _baselinedIn(Map<String, dynamic>? snapshot) {
    final raw = snapshot?[_baselinedKey];
    return raw is List
        ? {
            for (final id in raw)
              if (id is String) id,
          }
        : null;
  }

  /// Builds the wire snapshot from [groups].
  ///
  /// When [previous] is given, any of its repo entries whose id is NOT in
  /// [resolvedRepoIds] is carried over verbatim: the forge did not answer for
  /// that repo this sweep, and dropping it would report an empty queue the
  /// fetch never actually observed.
  Map<String, dynamic> _snapshotFromGroups(
    List<OpenPrGroup> groups, {
    Map<String, dynamic>? previous,
    Set<String> resolvedRepoIds = const {},
    List<Map<String, dynamic>> inaccessible = const [],
  }) {
    final repos = <Map<String, dynamic>>[
      for (final g in groups) _repoWire(g, previous),
    ];
    for (final raw in (previous?['repos'] as List?) ?? const []) {
      if (raw is! Map) {
        continue;
      }
      final entry = raw.cast<String, dynamic>();
      final repoId = entry['repo_id'] as String?;
      if (repoId != null && !resolvedRepoIds.contains(repoId)) {
        repos.add(entry);
      }
    }
    final baselined = {...?_baselinedIn(previous), ...resolvedRepoIds};
    return {
      'authenticated': true,
      'repos': repos,
      'inaccessible_repos': inaccessible,
      'terminal_prs': [...?(previous?['terminal_prs'] as List?)],
      _baselinedKey: baselined.toList()..sort(),
    };
  }

  /// Bounds the merged/closed history: entries past [terminalRetention] go,
  /// then the oldest beyond [maxTerminalEntries]. An entry from before
  /// `recorded_at` existed counts as recorded now (it ages out from here).
  void _capTerminal(List<dynamic> terminal) {
    final now = _now();
    DateTime recordedAt(Object? raw) =>
        (raw is Map
            ? DateTime.tryParse(raw['recorded_at'] as String? ?? '')
            : null) ??
        now;
    terminal.removeWhere(
      (raw) => now.difference(recordedAt(raw)) > terminalRetention,
    );
    if (terminal.length > maxTerminalEntries) {
      // Appended in observation order, so the head is the oldest.
      terminal.removeRange(0, terminal.length - maxTerminalEntries);
    }
  }

  Future<Map<String, dynamic>?> _readPersistedSnapshot(
    String workspaceId,
  ) async {
    final raw = await _cache(
      workspaceId,
    ).read(workspaceId, cacheKind, cacheKey);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  Future<void> _persistSnapshot(
    String workspaceId,
    Map<String, dynamic> snapshot,
  ) => _cache(
    workspaceId,
  ).put(workspaceId, cacheKind, cacheKey, jsonEncode(snapshot));

  static Map<int, Map<String, dynamic>> _prsByNumber(
    Map<String, dynamic>? snapshot,
    String repoFullName,
  ) {
    if (snapshot == null) {
      return const {};
    }
    for (final raw in (snapshot['repos'] as List?) ?? const []) {
      if (raw is! Map || raw['repo_full_name'] != repoFullName) {
        continue;
      }
      return {
        for (final pr in (raw['prs'] as List?) ?? const [])
          if (pr is Map && pr['number'] is num)
            (pr['number'] as num).toInt(): pr.cast<String, dynamic>(),
      };
    }
    return const {};
  }

  /// One repo group's snapshot entry, with each pull request's enrichment
  /// reconciled against what [previous] knew (see [_carryEnrichmentForward]).
  Map<String, dynamic> _repoWire(
    OpenPrGroup group,
    Map<String, dynamic>? previous,
  ) {
    final before = _prsByNumber(previous, group.repo.fullName);
    return {
      'repo_id': group.repo.id,
      'repo_full_name': group.repo.fullName,
      'has_more': group.hasMore,
      'prs': [
        for (final pr in group.prs)
          _carryEnrichmentForward(_prToWire(pr), before[pr.number]),
      ],
    };
  }

  /// The wire value both enrichment fields decode a MISSING answer to — and
  /// also the value they carry when the forge genuinely has nothing to report.
  /// That collision is the whole reason [_carryEnrichmentForward] exists.
  static const String _unreadEnrichment = 'none';

  /// Merges fresh PR wire with the previous snapshot so unread enrichment is not persisted as forge truth.
  ///
  /// `checks_status` / `review_decision` come from a heavy GraphQL pass that often 502s; unread decodes to
  /// `none`, which used to overwrite real values and flap notifications. Carry `review_decision` when fresh
  /// is unread; carry `checks_status` only while `head_sha` is unchanged (a push may legitimately have no rollup).
  static Map<String, dynamic> _carryEnrichmentForward(
    Map<String, dynamic> fresh,
    Map<String, dynamic>? previous,
  ) {
    if (previous == null) {
      return fresh;
    }
    final carried = <String, dynamic>{};

    final decision = previous['review_decision'];
    if (fresh['review_decision'] == _unreadEnrichment &&
        decision is String &&
        decision != _unreadEnrichment) {
      carried['review_decision'] = decision;
    }

    final checks = previous['checks_status'];
    final head = fresh['head_sha'];
    if (fresh['checks_status'] == _unreadEnrichment &&
        checks is String &&
        checks != _unreadEnrichment &&
        head is String &&
        head.isNotEmpty &&
        head == previous['head_sha']) {
      carried['checks_status'] = checks;
    }

    return carried.isEmpty ? fresh : {...fresh, ...carried};
  }

  /// Fingerprint of a PR's non-check wire fields, for change classification.
  static String _nonChecksFingerprint(Map<String, dynamic> wire) {
    final copy = Map<String, dynamic>.of(wire)..remove('checks_status');
    return jsonEncode(copy);
  }

  /// Detects and publishes the author-facing transitions between two snapshots
  /// of one pull request.
  ///
  /// Returns the forge-confirmed `mergeable_state` name when a readiness edge
  /// was confirmed, else null. The caller folds it into the wire map it is
  /// about to persist, so the confirmation is part of THIS evaluation rather
  /// than producing a second, delayed edge on the next sweep.
  ///
  /// Called from both the full diff and the checks-only pass, so the two can
  /// never disagree about what counts as news.
  Future<String?> _publishTransitions(
    String workspaceId,
    Repo repo,
    int number,
    Map<String, dynamic> oldWire,
    Map<String, dynamic> newWire,
    _SweepContext ctx,
  ) async {
    final bus = _eventBus;
    final resolver = _memberLoginsFor;
    if (bus == null || resolver == null) {
      return null;
    }
    final author = ((newWire['author'] as Map?)?['login'] as String?) ?? '';
    // Silence beats telling someone a stranger's PR is theirs: a PR no
    // member authored (or one whose author has not connected the forge) is
    // never announced, and the logins are re-read next sweep, so this
    // self-heals on sign-in.
    final forUserId = await ctx.memberFor(
      repo.forge,
      author,
      () => resolver(workspaceId, repo.forge),
    );
    if (forUserId == null) {
      return null;
    }

    final before = PrNotifiableState.fromWire(oldWire);
    var after = PrNotifiableState.fromWire(newWire);
    String? confirmedState;

    final title = newWire['title'] as String? ?? '';
    final owner = repo.remoteOwner;
    final name = repo.remoteName;

    // ── The ready edge, handled outside the generic loop ──
    //
    // "Your PR is ready to merge" is the one message here that is expensive to
    // get wrong, so it is confirmed against the forge's own verdict before it
    // goes out. That needs two things the pure detector cannot express: a
    // round trip, and a RETRY — because the snapshot advances either way, so a
    // sweep that could not confirm would otherwise lose the edge forever
    // rather than deferring it.
    final readyKey = '$workspaceId|${repo.id}|$number';
    final wasReady = before.readiness.readiness == PrMergeReadiness.ready;
    final nowReady = after.readiness.readiness == PrMergeReadiness.ready;
    if (!nowReady) {
      _pendingReadyConfirm.remove(readyKey);
    } else if (!wasReady || _pendingReadyConfirm.contains(readyKey)) {
      final verdictMissing =
          after.mergeableState == PrMergeableState.unrecognized ||
          after.mergeableState == PrMergeableState.unknown;
      if (verdictMissing && ctx.mergeConfirms < _maxMergeConfirmsPerPass) {
        ctx.mergeConfirms++;
        final confirmed = await _port.mergeState(
          repo,
          number,
          workspaceId: workspaceId,
        );
        if (confirmed != PrMergeableState.unknown) {
          confirmedState = confirmed.name;
          after = PrNotifiableState.fromWire({
            ...newWire,
            'mergeable_state': confirmedState,
          });
        }
      }
      if (confirmedState != null &&
          after.readiness.readiness == PrMergeReadiness.ready) {
        _pendingReadyConfirm.remove(readyKey);
        bus.publish(
          PrMergeReadinessChanged(
            workspaceId: workspaceId,
            repoOwner: owner,
            repoName: name,
            prNumber: number,
            prTitle: title,
            ready: true,
            reason: PrBlockReason.none.name,
            forUserId: forUserId,
            occurredAt: _now(),
          ),
        );
      } else if (confirmedState == null) {
        // Unconfirmed (the forge answered `unknown`, or the per-pass budget
        // was spent). Defer rather than announce or drop.
        _pendingReadyConfirm.add(readyKey);
      } else {
        // The forge demoted it. Not ready after all; the loop below reports
        // the block if this is the edge into one.
        _pendingReadyConfirm.remove(readyKey);
      }
    }

    for (final transition in detectPrNotifiableTransitions(
      before: before,
      after: after,
    )) {
      switch (transition) {
        // Published above, after confirmation — never from the bare edge.
        case PrBecameReadyToMerge():
          break;
        case PrBecameBlocked(:final reason):
          bus.publish(
            PrMergeReadinessChanged(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: number,
              prTitle: title,
              ready: false,
              reason: reason.name,
              forUserId: forUserId,
              occurredAt: _now(),
            ),
          );
        case PrWasApproved(:final reviewersRemaining, :final approverLogin):
          // The diff names the approver for free on the full sweep. When it
          // cannot (an approval by someone never formally requested, two in
          // one tick, or the checks pass which does not refresh reviewers),
          // one targeted read puts a name on it — and failing that the
          // notification still goes out, unattributed.
          var approver = approverLogin;
          if (approver == null &&
              ctx.approverLookups < _maxApproverLookupsPerPass) {
            ctx.approverLookups++;
            approver = await _port.latestApprover(
              repo,
              number,
              workspaceId: workspaceId,
            );
          }
          bus.publish(
            PrReviewDecisionChanged(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: number,
              prTitle: title,
              decision: 'approved',
              reviewersRemaining: reviewersRemaining,
              approverLogin: approver,
              forUserId: forUserId,
              occurredAt: _now(),
            ),
          );
        case PrChangesRequested():
          bus.publish(
            PrReviewDecisionChanged(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: number,
              prTitle: title,
              decision: 'changesRequested',
              reviewersRemaining: after.reviewersRemaining,
              forUserId: forUserId,
              occurredAt: _now(),
            ),
          );
        case PrReviewDismissed():
          bus.publish(
            PrReviewDecisionChanged(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: number,
              prTitle: title,
              decision: 'dismissed',
              reviewersRemaining: after.reviewersRemaining,
              forUserId: forUserId,
              occurredAt: _now(),
            ),
          );
        case PrChecksFailed():
          final failing = await _firstFailingCheck(
            repo,
            number,
            workspaceId: workspaceId,
          );
          bus.publish(
            PrChecksStatusChanged(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: number,
              prTitle: title,
              failing: true,
              failingCheckName: failing?.name,
              failingCheckUrl: failing?.url,
              forUserId: forUserId,
              occurredAt: _now(),
            ),
          );
        case PrChecksRecovered():
          bus.publish(
            PrChecksStatusChanged(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: number,
              prTitle: title,
              failing: false,
              forUserId: forUserId,
              occurredAt: _now(),
            ),
          );
      }
    }
    return confirmedState;
  }

  /// Names the check that went red, so the notification says which one.
  ///
  /// Best-effort by design: the rollup already told us CI failed, and a name
  /// is an improvement on that message, not a precondition for sending it.
  Future<({String name, String? url})?> _firstFailingCheck(
    Repo repo,
    int number, {
    required String workspaceId,
  }) async {
    try {
      return await _port.firstFailingCheck(
        repo,
        number,
        workspaceId: workspaceId,
      );
    } on Object catch (e) {
      CcHostLog.warning('open_pr_poll: check-run lookup failed: $e');
      return null;
    }
  }

  Future<void> _diffAndPublish(
    String workspaceId,
    List<Repo> repos,
    Map<String, dynamic>? previous,
    Map<String, dynamic> fresh,
    _SweepContext ctx,
  ) async {
    // A repo's first read (the workspace's first sweep, or a repo linked
    // since) is a baseline — recorded without notifying, so neither a server
    // start nor linking a busy repo announces every pre-existing PR.
    final baselined = _baselinedIn(previous);
    final terminal = (fresh['terminal_prs'] as List).cast<dynamic>();
    for (final repo in repos) {
      final isBaseline =
          previous == null ||
          (baselined != null && !baselined.contains(repo.id));
      final before = _prsByNumber(previous, repo.fullName);
      final after = _prsByNumber(fresh, repo.fullName);
      // A reopened PR is open again; don't leave its previous merged/closed
      // record behind to become the answer after a later list transition.
      terminal.removeWhere(
        (raw) =>
            raw is Map &&
            raw['repo_id'] == repo.id &&
            raw['repo_full_name'] == repo.fullName &&
            after.containsKey(raw['number']),
      );
      if (isBaseline) {
        continue;
      }

      for (final entry in after.entries) {
        final old = before[entry.key];
        if (old == null) {
          // New open PR.
          final author = (entry.value['author'] as Map?)?['login'] as String?;
          _eventBus?.publish(
            ExternalPrDetected(
              repoOwner: repo.remoteOwner,
              repoName: repo.remoteName,
              prNumber: entry.key,
              prTitle: entry.value['title'] as String? ?? '',
              author: author ?? '',
              // Polling runs per workspace, so unlike the legacy global
              // poller the owning workspace IS attributable here.
              workspaceId: workspaceId,
              occurredAt: _now(),
            ),
          );
          _signals.notify(
            workspaceId: workspaceId,
            repoFullName: repo.fullName,
            prNumber: entry.key,
          );
          continue;
        }
        final checksMoved =
            old['checks_status'] != entry.value['checks_status'];
        final restMoved =
            _nonChecksFingerprint(old) != _nonChecksFingerprint(entry.value);
        if (restMoved) {
          _signals.notify(
            workspaceId: workspaceId,
            repoFullName: repo.fullName,
            prNumber: entry.key,
          );
          // The head moved: the author pushed. Published as its own event
          // because it is what makes an existing review stale, and the sweep
          // is the only place that holds both the old and the new commit.
          // The cache-revalidation nudge above cannot carry it — it has no
          // payload and no listeners outside the UI's SWR layer.
          final wasSha = old['head_sha'];
          final nowSha = entry.value['head_sha'];
          if (wasSha is String &&
              nowSha is String &&
              wasSha.isNotEmpty &&
              nowSha.isNotEmpty &&
              wasSha != nowSha) {
            _eventBus?.publish(
              PrHeadChanged(
                workspaceId: workspaceId,
                repoOwner: splitRepoFullName(repo.fullName)?.owner ?? '',
                repoName: splitRepoFullName(repo.fullName)?.name ?? '',
                prNumber: entry.key,
                prTitle: entry.value['title'] is String
                    ? entry.value['title'] as String
                    : '',
                previousHeadSha: wasSha,
                headSha: nowSha,
                occurredAt: _now(),
              ),
            );
          }
        } else if (checksMoved) {
          _signals.notify(
            workspaceId: workspaceId,
            repoFullName: repo.fullName,
            prNumber: entry.key,
            checksOnly: true,
          );
        }

        // The author-facing lanes. Runs whether or not the cheap fingerprints
        // moved: `readiness` folds in fields (draft, requested reviewers) that
        // `checks_status` alone does not cover, and the transition detector is
        // pure, so a no-op comparison costs nothing.
        final confirmed = await _publishTransitions(
          workspaceId,
          repo,
          entry.key,
          old,
          entry.value,
          ctx,
        );
        // A forge-confirmed mergeable state is folded back into the snapshot
        // being persisted, so the next sweep compares against the confirmed
        // value rather than re-deriving and re-confirming the same edge.
        if (confirmed != null) {
          entry.value['mergeable_state'] = confirmed;
        }
      }

      // Only the first page of a repo's open list is read. With more pages
      // behind it, a PR missing from this page may simply have been pushed
      // off it, so absence alone proves nothing: a lookup that cannot say
      // merged/closed records nothing rather than an unconfirmed terminal.
      final pageIsPartial = _hasMore(fresh, repo.fullName);
      for (final number in before.keys) {
        if (after.containsKey(number)) {
          continue;
        }
        // This previously observed PR left the open list. Retain its wire
        // identity (including head ref), but never turn a failed status
        // confirmation into a merge. Unknown can be retried on idle sweeps.
        bool? merged;
        try {
          merged = await _port.wasMerged(
            repo,
            number,
            workspaceId: workspaceId,
          );
        } on Object catch (e) {
          CcHostLog.warning('open_pr_poll: PR status lookup failed: $e');
        }
        if (merged == null && pageIsPartial) {
          continue;
        }
        final old = before[number]!;
        terminal.removeWhere(
          (raw) =>
              raw is Map &&
              raw['repo_id'] == repo.id &&
              raw['repo_full_name'] == repo.fullName &&
              raw['number'] == number,
        );
        terminal.add({
          'repo_id': repo.id,
          'repo_full_name': repo.fullName,
          'number': number,
          'recorded_at': _now().toIso8601String(),
          'pull_request': {
            ...old,
            'state': switch (merged) {
              true => 'merged',
              false => 'closed',
              null => old['state'] ?? 'open',
            },
            if (merged == null) 'status_unconfirmed': true,
          },
        });
        if (merged != null) {
          _eventBus?.publish(
            PullRequestStatusChanged(
              status: merged ? 'merged' : 'closed',
              workspaceId: workspaceId,
              repoFullName: repo.fullName,
              prNumber: number,
              occurredAt: _now(),
            ),
          );
        }
        _signals.notify(
          workspaceId: workspaceId,
          repoFullName: repo.fullName,
          prNumber: number,
        );
      }
    }
    _capTerminal(terminal);
  }

  /// Whether [snapshot]'s entry for [repoFullName] says more open PRs exist
  /// past the page that was read.
  static bool _hasMore(Map<String, dynamic> snapshot, String repoFullName) {
    for (final raw in (snapshot['repos'] as List?) ?? const []) {
      if (raw is Map && raw['repo_full_name'] == repoFullName) {
        return raw['has_more'] == true;
      }
    }
    return false;
  }

  /// Retry status lookups that failed on the transition sweep, without
  /// re-fetching the historical list or polling one request per space row.
  Future<void> _resolveUnknownTerminals(
    String workspaceId,
    List<Repo> repos,
    _WorkspacePollState st,
  ) async {
    final snapshot = st.snapshot;
    if (snapshot == null) {
      return;
    }
    final linked = {for (final repo in repos) repo.id: repo};
    final terminal = (snapshot['terminal_prs'] as List?) ?? const [];
    var attempts = 0;
    var changed = false;
    final updated = <dynamic>[];
    final confirmed = <({Repo repo, int number, bool merged})>[];
    for (final raw in terminal) {
      if (raw is! Map || raw['pull_request'] is! Map) {
        updated.add(raw);
        continue;
      }
      final pr = raw['pull_request'] as Map;
      final repo = linked[raw['repo_id']];
      final number = raw['number'];
      if (pr['status_unconfirmed'] != true ||
          repo == null ||
          repo.fullName != raw['repo_full_name'] ||
          number is! int ||
          attempts >= _maxMergeConfirmsPerPass) {
        updated.add(raw);
        continue;
      }
      attempts++;
      bool? merged;
      try {
        merged = await _port.wasMerged(repo, number, workspaceId: workspaceId);
      } on Object catch (e) {
        CcHostLog.warning('open_pr_poll: PR status retry failed: $e');
      }
      if (merged == null) {
        updated.add(raw);
        continue;
      }
      changed = true;
      confirmed.add((repo: repo, number: number, merged: merged));
      updated.add({
        ...raw,
        'pull_request': {...pr, 'state': merged ? 'merged' : 'closed'}
          ..remove('status_unconfirmed'),
      });
    }
    if (changed) {
      st.snapshot = {...snapshot, 'terminal_prs': updated};
      await _persistSnapshot(workspaceId, st.snapshot!);
      for (final result in confirmed) {
        _eventBus?.publish(
          PullRequestStatusChanged(
            status: result.merged ? 'merged' : 'closed',
            workspaceId: workspaceId,
            repoFullName: result.repo.fullName,
            prNumber: result.number,
            occurredAt: _now(),
          ),
        );
        _signals.notify(
          workspaceId: workspaceId,
          repoFullName: result.repo.fullName,
          prNumber: result.number,
        );
      }
    }
  }

  /// Checks-only pass: overlays fresh rollup states + review decisions onto
  /// the held snapshot, persisting + signaling only the PRs whose state
  /// actually moved. A checks-only move keeps the lighter `checksOnly` signal;
  /// a review-decision move sends the full signal (reviews change what the
  /// detail view shows, not just the checks pill).
  Future<void> _checksPass(
    String workspaceId,
    List<Repo> repos,
    _WorkspacePollState st,
    _SweepContext ctx,
  ) async {
    final Map<String, Map<int, PrStatusOverlay>> byRepoId;
    try {
      byRepoId = await _port.fetchChecks(repos, workspaceId: workspaceId);
    } on Object catch (e) {
      CcHostLog.warning('open_pr_poll: checks pass failed: $e');
      return;
    }
    final snapshot = st.snapshot;
    if (snapshot == null) {
      return;
    }
    final reposById = {for (final r in repos) r.id: r};
    final changed = <({String repoFullName, int prNumber, bool checksOnly})>[];
    final updatedRepos = <Map<String, dynamic>>[];
    for (final raw in (snapshot['repos'] as List?) ?? const []) {
      if (raw is! Map) {
        continue;
      }
      final repoWire = raw.cast<String, dynamic>();
      final repo = reposById[repoWire['repo_id']];
      final overlays = byRepoId[repoWire['repo_id']];
      if (overlays == null) {
        updatedRepos.add(repoWire);
        continue;
      }
      final updatedPrs = <Map<String, dynamic>>[];
      for (final pr in (repoWire['prs'] as List?) ?? const []) {
        if (pr is! Map) {
          continue;
        }
        final prWire = pr.cast<String, dynamic>();
        final number = (prWire['number'] as num?)?.toInt();
        final overlay = number == null ? null : overlays[number];
        if (number == null || overlay == null) {
          updatedPrs.add(prWire);
          continue;
        }
        // The same guard the full sweep applies. This pass IS the heavy query,
        // and GitHub answers it partially as well as not at all: a repo alias
        // can resolve while its `statusCheckRollup` field errors out, which
        // arrives here as a null rollup — "no checks", not "not read".
        final overlaid = _carryEnrichmentForward({
          ...prWire,
          'checks_status': prChecksStatusFromRollup(overlay.checksRollup).name,
          'review_decision': PrReviewDecision.fromString(
            overlay.reviewDecision,
          ).name,
        }, prWire);
        final nextChecks = overlaid['checks_status'];
        final nextDecision = overlaid['review_decision'];
        final checksMoved = prWire['checks_status'] != nextChecks;
        // A snapshot persisted before review decisions were carried has no
        // `review_decision` key — read that as `none` so the first pass after
        // an upgrade doesn't fire a full signal for every PR.
        final prevDecision =
            prWire['review_decision'] as String? ?? PrReviewDecision.none.name;
        final decisionMoved = prevDecision != nextDecision;
        if (checksMoved || decisionMoved) {
          changed.add((
            repoFullName: repoWire['repo_full_name'] as String? ?? '',
            prNumber: number,
            checksOnly: !decisionMoved,
          ));
          var next = overlaid;
          // The same author-facing detection the full sweep runs. This pass is
          // where "checks failed" and "approved" are usually first seen — it
          // runs between full fetches — so skipping it here would delay every
          // one of them by up to a full fetch cycle.
          if (repo != null) {
            final confirmed = await _publishTransitions(
              workspaceId,
              repo,
              number,
              prWire,
              next,
              ctx,
            );
            if (confirmed != null) {
              next = {...next, 'mergeable_state': confirmed};
            }
          }
          updatedPrs.add(next);
        } else {
          updatedPrs.add(prWire);
        }
      }
      updatedRepos.add({...repoWire, 'prs': updatedPrs});
    }
    if (changed.isEmpty) {
      return;
    }
    final updated = {...snapshot, 'repos': updatedRepos};
    st.snapshot = updated;
    await _persistSnapshot(workspaceId, updated);
    for (final c in changed) {
      _signals.notify(
        workspaceId: workspaceId,
        repoFullName: c.repoFullName,
        prNumber: c.prNumber,
        checksOnly: c.checksOnly,
      );
    }
  }
}
