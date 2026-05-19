import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// One repo's enriched open-PR group (checks already overlaid), matching the
/// catalog's `OpenPrListFetcher` result shape.
typedef OpenPrGroup = ({Repo repo, List<PullRequest> prs, bool hasMore});

/// One PR's slice of the checks-pass enrichment: the raw check-rollup state
/// string plus the raw `reviewDecision` string (both null when absent).
typedef PrStatusOverlay = ({String? checksRollup, String? reviewDecision});

/// The GitHub fetch surface the open-PR poller runs on. Kept as a thin port so
/// tests drive the poller with an in-memory fake; the production adapter wraps
/// the server's gh-authenticated `GitHubApiClient`.
abstract interface class OpenPrFetchPort {
  /// Conditional (ETag) probe of [repo]'s open-PR list. `changed: false` means
  /// GitHub answered 304 — free against the rate limit — and the list is
  /// byte-identical since [etag].
  Future<({bool changed, String? etag})> probeRepo(Repo repo, String? etag);

  /// The full enriched open-PR groups (first page per repo, checks overlaid).
  Future<List<OpenPrGroup>> fetchGroups(List<Repo> repos);

  /// The check-rollup + review-decision overlay per repo id, per PR number,
  /// for the first page of open PRs — the cheap status-only pass between full
  /// fetches.
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(List<Repo> repos);

  /// Whether a PR that vanished from the open list was merged (true), closed
  /// unmerged (false), or couldn't be resolved (null).
  Future<bool?> wasMerged(Repo repo, int prNumber);
}

/// Production [OpenPrFetchPort] over the server's gh-authenticated
/// [GitHubApiClient]. The group fetch mirrors what `pr.listOpenForWorkspace`
/// serves: the batched GraphQL list query plus a best-effort checks overlay.
class GitHubOpenPrFetchAdapter implements OpenPrFetchPort {
  /// Creates a [GitHubOpenPrFetchAdapter] over `client`.
  GitHubOpenPrFetchAdapter(this._client);

  final GitHubApiClient _client;

  static List<({String owner, String name})> _specs(List<Repo> repos) => [
    for (final r in repos) (owner: r.githubOwner, name: r.githubRepoName),
  ];

  @override
  Future<({bool changed, String? etag})> probeRepo(
    Repo repo,
    String? etag,
  ) async {
    final probe = await _client.pr.probeOpenPullRequests(
      repo.githubOwner,
      repo.githubRepoName,
      etag: etag,
    );
    return (changed: probe.changed, etag: probe.etag);
  }

  @override
  Future<List<OpenPrGroup>> fetchGroups(List<Repo> repos) async {
    final specs = _specs(repos);
    final batch = await _client.graphql.fetchOpenPullRequestsBatch(specs);
    var checks = <int, Map<int, GitHubPrStatusOverlay>>{};
    try {
      checks = await _client.graphql.fetchOpenPullRequestsChecks(specs);
    } on Object {
      // Checks are best-effort; rows keep checksStatus.none on failure.
    }
    final groups = <OpenPrGroup>[];
    for (var i = 0; i < repos.length; i++) {
      final repo = repos[i];
      final repoResult = batch.byIndex[i];
      if (repoResult == null) {
        continue;
      }
      final repoChecks = checks[i];
      final prs = <PullRequest>[];
      for (final node in repoResult.nodes) {
        final number = (node['number'] as num?)?.toInt() ?? 0;
        final title = node['title'] as String? ?? '';
        if (number <= 0 || title.isEmpty) {
          continue;
        }
        var pr = pullRequestFromGraphQlNode(node, repoFullName: repo.fullName);
        final overlay = repoChecks?[pr.number];
        if (overlay != null) {
          pr = pr.copyWith(
            checksStatus: prChecksStatusFromRollup(overlay.checksRollup),
            reviewDecision: PrReviewDecision.fromString(overlay.reviewDecision),
          );
        }
        prs.add(pr);
      }
      if (prs.isEmpty) {
        continue;
      }
      groups.add((repo: repo, prs: prs, hasMore: repoResult.hasMore));
    }
    return groups;
  }

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos,
  ) async {
    final byIndex = await _client.graphql.fetchOpenPullRequestsChecks(
      _specs(repos),
    );
    return {
      for (var i = 0; i < repos.length; i++)
        if (byIndex[i] != null)
          repos[i].id: {
            for (final e in byIndex[i]!.entries)
              e.key: (
                checksRollup: e.value.checksRollup,
                reviewDecision: e.value.reviewDecision,
              ),
          },
    };
  }

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber) async {
    try {
      final gh = await _client.pr.getPullRequest(
        repo.githubOwner,
        repo.githubRepoName,
        prNumber,
      );
      if (gh == null) {
        return null;
      }
      return gh.mergedAt != null;
    } on Object {
      return null;
    }
  }
}

/// Per-workspace poller state.
class _WorkspacePollState {
  /// Active `pr.watchOpenForWorkspace` subscriptions (fast cadence when > 0).
  int interest = 0;

  /// Last conditional-request ETag per repo id.
  final Map<String, String> etagByRepoId = {};

  /// The current snapshot in wire form (`{'authenticated', 'repos'}`), or null
  /// before the first successful sweep.
  Map<String, dynamic>? snapshot;

  /// Whether the persisted snapshot was already loaded from the cache table.
  bool snapshotLoaded = false;

  /// The sweep currently running for this workspace, or null when idle.
  /// Non-forced callers coalesce into it; forced callers chain behind it.
  Future<void>? inflight;

  /// A forced sweep already queued behind [inflight]. Concurrent forced
  /// refreshes share this one future instead of piling up sweeps.
  Future<void>? queuedForced;

  /// Broadcast of sweep in-flight transitions (`true` on start, `false` on
  /// completion). `watchOpenForWorkspace` merges these into its stream so a
  /// client's refresh affordance can reflect the sweep that a subscribe (or a
  /// background tick) kicked — otherwise the slow GitHub fetch is invisible
  /// behind the instantly-pushed persisted snapshot.
  // Closed in OpenPrPollingService.dispose.
  // ignore: close_sinks
  final StreamController<bool> sweepingChanges =
      StreamController<bool>.broadcast();

  DateTime? lastSweepAt;
}

/// Polls GitHub for every workspace's open pull requests and turns changes
/// into live updates — the "smart polling" freshness driver behind the PR
/// surfaces (webhooks are deliberately not relied on: this server may run with
/// no public URL at all).
///
/// Design:
///  - **Cheap change detection.** Each sweep probes every linked repo's open-PR
///    list with a conditional request ([GitHubPrClient.probeOpenPullRequests]);
///    GitHub's 304 answers are rate-limit-free, so the fast cadence costs
///    almost nothing while nothing changes.
///  - **Fetch on change only.** A changed probe (or an explicit refresh) runs
///    the enriched GraphQL batch, diffs the new snapshot against the previous
///    one, persists it to the `caches` table (whose Drift watch feeds
///    `pr.watchOpenForWorkspace` — that's the push to every connected client),
///    emits [ExternalPrDetected] / [PullRequestStatusChanged] domain events,
///    and publishes [PrChangeSignal]s so open PR-detail streams re-validate.
///  - **Interest-scaled cadence.** Workspaces with active list watchers sweep
///    every [fastInterval] (plus a checks-only pass every [checksEvery] ticks —
///    CI state doesn't move list ETags); workspaces nobody is watching fall
///    back to [idleInterval] so notifications stay fresh without UI-grade cost.
class OpenPrPollingService {
  /// Creates an [OpenPrPollingService].
  OpenPrPollingService({
    required OpenPrFetchPort fetchPort,
    required WorkspaceRepository workspaceRepository,
    required WorkspaceDatabaseManager workspaceDbs,
    required PrChangeSignals changeSignals,
    required Map<String, dynamic> Function(PullRequest pr) prToWire,
    DomainEventBus? eventBus,
    this.fastInterval = const Duration(seconds: 60),
    this.idleInterval = const Duration(minutes: 2),
    this.checksEvery = 2,
    DateTime Function()? now,
  }) : _port = fetchPort,
       _workspaces = workspaceRepository,
       _dbs = workspaceDbs,
       _signals = changeSignals,
       _prToWire = prToWire,
       _eventBus = eventBus,
       _now = now ?? DateTime.now;

  /// Cache kind for the persisted per-workspace snapshot.
  static const cacheKind = 'openPrList';

  /// Cache key (single row per workspace) for the persisted snapshot.
  static const cacheKey = 'v1';

  /// Minimum spacing between sweeps of one workspace triggered by
  /// subscription churn (`pollSoon` bursts), so re-navigating to the PR list
  /// doesn't hammer GitHub.
  static const _pollSoonMinGap = Duration(seconds: 15);

  final OpenPrFetchPort _port;
  final WorkspaceRepository _workspaces;
  final WorkspaceDatabaseManager _dbs;
  final PrChangeSignals _signals;

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

  final Map<String, _WorkspacePollState> _states = {};
  Timer? _timer;
  int _tick = 0;
  bool _disposed = false;

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
      unawaited(st.sweepingChanges.close());
    }
  }

  Future<void> _onTick() async {
    if (_disposed) {
      return;
    }
    _tick++;
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
        await _sweep(
          workspaceId,
          includeChecks: _tick % checksEvery == 0,
          force: false,
        );
      } else {
        final last = st.lastSweepAt;
        if (last == null || _now().difference(last) >= idleInterval) {
          await _sweep(workspaceId, includeChecks: false, force: false);
        }
      }
    }
  }

  /// The live open-PR list for [workspaceId], in the `pr.listOpenForWorkspace`
  /// wire shape plus a `sweep_in_flight` flag. Registers watcher interest for
  /// the fast cadence, kicks an immediate freshness pass, then follows the
  /// persisted snapshot's Drift watch — every poller write pushes to every
  /// subscriber.
  ///
  /// Every emitted frame is tagged with the live sweep-in-flight flag, and a
  /// flag transition re-emits the last frame: the persisted snapshot arrives
  /// instantly (or an authenticated-empty frame when no sweep ever landed), so
  /// without the flag the client would render stale/empty data with no loading
  /// signal while the real GitHub fetch is still running.
  Stream<Map<String, dynamic>> watchOpenForWorkspace(
    String workspaceId,
  ) async* {
    final st = _stateFor(workspaceId);
    st.interest++;
    final controller = StreamController<Map<String, dynamic>>();
    Map<String, dynamic>? lastFrame;
    var sweeping = st.inflight != null;
    String? lastEmitted;

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

    final snapshotSub = _cache(
      workspaceId,
    ).watch(workspaceId, cacheKind, cacheKey).listen((raw) {
      final frame = _decodeSnapshotFrame(raw);
      if (frame == null) {
        return;
      }
      lastFrame = frame;
      emit();
    });
    final sweepingSub = st.sweepingChanges.stream.listen((s) {
      sweeping = s;
      emit();
    });
    try {
      unawaited(pollSoon(workspaceId));
      // yield* (not `await for`): an async* generator only honors
      // cancellation at a yield point, so forwarding the merged stream
      // through yield* is what lets an unsubscribe tear this stream down
      // immediately instead of blocking until the next snapshot write.
      yield* controller.stream;
    } finally {
      await snapshotSub.cancel();
      await sweepingSub.cancel();
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
        return parsed;
      }
    } on Object {
      // Corrupt snapshot row — skip.
    }
    return null;
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
  Future<void> refreshNow(String workspaceId) =>
      _sweep(workspaceId, includeChecks: true, force: true);

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
      final sweep = _runSweep(
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
      final repos = [
        for (final r in linked)
          if (r.hasGitHubRemote) r,
      ];
      if (repos.isEmpty) {
        return;
      }

      if (!st.snapshotLoaded) {
        st.snapshot = await _readPersistedSnapshot(workspaceId);
        st.snapshotLoaded = true;
      }

      // Probe first even on forced/first sweeps: the ETag captured *before*
      // the full fetch guarantees at-least-once change detection (anything
      // that lands after the probe re-triggers a 200 next tick). A probe
      // without a prior ETag (first tick, post-restart) always answers 200 —
      // that over-approximates "changed" once, and the snapshot diff below
      // dedupes it into zero published events.
      var listChanged = force || st.snapshot == null;
      for (final repo in repos) {
        try {
          final probe = await _port.probeRepo(
            repo,
            force ? null : st.etagByRepoId[repo.id],
          );
          final etag = probe.etag;
          if (etag != null && etag.isNotEmpty) {
            st.etagByRepoId[repo.id] = etag;
          }
          if (probe.changed) {
            listChanged = true;
          }
        } on Object catch (e) {
          CcHostLog.warning(
            'open_pr_poll: probe failed for ${repo.fullName}: $e',
          );
        }
      }

      if (listChanged) {
        final groups = await _port.fetchGroups(repos);
        final fresh = _snapshotFromGroups(groups);
        await _diffAndPublish(workspaceId, repos, st.snapshot, fresh);
        st.snapshot = fresh;
        await _persistSnapshot(workspaceId, fresh);
      } else if (includeChecks && st.snapshot != null) {
        await _checksPass(workspaceId, repos, st);
      }
    } on Object catch (e) {
      CcHostLog.warning('open_pr_poll: sweep failed for $workspaceId: $e');
    }
  }

  Map<String, dynamic> _snapshotFromGroups(List<OpenPrGroup> groups) => {
    'authenticated': true,
    'repos': [
      for (final g in groups)
        {
          'repo_id': g.repo.id,
          'repo_full_name': g.repo.fullName,
          'github_owner': g.repo.githubOwner,
          'github_repo_name': g.repo.githubRepoName,
          'has_more': g.hasMore,
          'prs': [for (final pr in g.prs) _prToWire(pr)],
        },
    ],
  };

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

  /// Fingerprint of a PR's non-check wire fields, for change classification.
  static String _nonChecksFingerprint(Map<String, dynamic> wire) {
    final copy = Map<String, dynamic>.of(wire)..remove('checks_status');
    return jsonEncode(copy);
  }

  Future<void> _diffAndPublish(
    String workspaceId,
    List<Repo> repos,
    Map<String, dynamic>? previous,
    Map<String, dynamic> fresh,
  ) async {
    // First-ever sweep for this workspace: baseline only — recording without
    // notifying, so server start doesn't spam events for pre-existing PRs.
    final isBaseline = previous == null;
    for (final repo in repos) {
      final before = _prsByNumber(previous, repo.fullName);
      final after = _prsByNumber(fresh, repo.fullName);
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
              repoOwner: repo.githubOwner,
              repoName: repo.githubRepoName,
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
        } else if (checksMoved) {
          _signals.notify(
            workspaceId: workspaceId,
            repoFullName: repo.fullName,
            prNumber: entry.key,
            checksOnly: true,
          );
        }
      }

      for (final number in before.keys) {
        if (after.containsKey(number)) {
          continue;
        }
        // The PR left the open list: merged or closed.
        final merged = await _port.wasMerged(repo, number);
        _eventBus?.publish(
          PullRequestStatusChanged(
            status: merged == true ? 'merged' : 'closed',
            workspaceId: workspaceId,
            repoFullName: repo.fullName,
            prNumber: number,
            occurredAt: _now(),
          ),
        );
        _signals.notify(
          workspaceId: workspaceId,
          repoFullName: repo.fullName,
          prNumber: number,
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
  ) async {
    final Map<String, Map<int, PrStatusOverlay>> byRepoId;
    try {
      byRepoId = await _port.fetchChecks(repos);
    } on Object catch (e) {
      CcHostLog.warning('open_pr_poll: checks pass failed: $e');
      return;
    }
    final snapshot = st.snapshot;
    if (snapshot == null) {
      return;
    }
    final changed = <({String repoFullName, int prNumber, bool checksOnly})>[];
    final updatedRepos = <Map<String, dynamic>>[];
    for (final raw in (snapshot['repos'] as List?) ?? const []) {
      if (raw is! Map) {
        continue;
      }
      final repoWire = raw.cast<String, dynamic>();
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
        final nextChecks = prChecksStatusFromRollup(overlay.checksRollup).name;
        final nextDecision = PrReviewDecision.fromString(
          overlay.reviewDecision,
        ).name;
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
          updatedPrs.add({
            ...prWire,
            'checks_status': nextChecks,
            'review_decision': nextDecision,
          });
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
