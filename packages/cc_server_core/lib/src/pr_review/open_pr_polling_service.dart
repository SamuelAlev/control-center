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

/// One repo's enriched open-PR group (checks already overlaid), matching the
/// catalog's `OpenPrListFetcher` result shape.
typedef OpenPrGroup = ({Repo repo, List<PullRequest> prs, bool hasMore});

/// One fetch's result: the enriched groups plus the ids of the repos GitHub
/// actually answered for.
///
/// The two are NOT the same set — a repo with no open pull requests resolves
/// successfully and contributes no group — and the difference is load-bearing.
/// The batch query tolerates partial failure (an errored repo alias comes back
/// null and is skipped), so "no groups" is ambiguous on its own: it means
/// either an empty queue or a GitHub that answered for nothing. Reporting the
/// resolved ids lets the poller tell those apart instead of persisting an
/// outage as an empty inbox.
typedef OpenPrFetchResult = ({
  List<OpenPrGroup> groups,
  Set<String> resolvedRepoIds,
});

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

  /// The full enriched open-PR groups (first page per repo, checks overlaid),
  /// with the ids of the repos GitHub actually answered for.
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos);

  /// The check-rollup + review-decision overlay per repo id, per PR number,
  /// for the first page of open PRs — the cheap status-only pass between full
  /// fetches.
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(List<Repo> repos);

  /// Whether a PR that vanished from the open list was merged (true), closed
  /// unmerged (false), or couldn't be resolved (null).
  Future<bool?> wasMerged(Repo repo, int prNumber);

  /// The forge's own mergeable verdict for ONE pull request.
  ///
  /// Deliberately not part of the list query: `mergeStateStatus` forces the
  /// forge to compute mergeability per PR and caused HTTP 504s across a
  /// 20-repo batch. This is the targeted escape hatch, called only on a
  /// readiness transition and capped per pass, so "ready to merge" is
  /// confirmed by the forge rather than guessed from a check rollup.
  ///
  /// [PrMergeableState.unknown] is a legitimate answer (the forge computes it
  /// lazily too) and means "not confirmed" — never "not mergeable".
  Future<PrMergeableState> mergeState(Repo repo, int prNumber);

  /// The login of the most recent approving review, or null when it cannot be
  /// determined. Used only to put a name on an approval whose reviewer could
  /// not be read off the requested-reviewer diff.
  Future<String?> latestApprover(Repo repo, int prNumber);

  /// The first failing check on a pull request, so a "checks failed"
  /// notification can name it. Null when none can be read — the rollup already
  /// said CI failed, so the name is an improvement on the message, never a
  /// precondition for sending it.
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  );
}

/// Production [OpenPrFetchPort] over the server's gh-authenticated
/// [GitHubApiClient]. The group fetch mirrors what `pr.listOpenForWorkspace`
/// serves: the batched GraphQL list query plus a best-effort checks overlay.
///
/// The client is resolved **per repo owner**, not held once. The server's
/// no-caller GitHub credential is a token for whichever app installation
/// answered first, and GitHub answers such a token with 404 for every repo
/// under an owner the app is not installed on — so a workspace mixing owners
/// must ask about each owner's repos with a credential that covers *that*
/// owner. Batch calls are grouped by owner accordingly, and one owner's
/// failure is isolated to its own repos (they resolve nothing and keep their
/// previous snapshot entries) rather than emptying the sweep.
class GitHubOpenPrFetchAdapter implements OpenPrFetchPort {
  /// Creates a [GitHubOpenPrFetchAdapter] resolving a client per repo owner.
  GitHubOpenPrFetchAdapter(this._clientForOwner);

  final GitHubApiClient Function(String owner) _clientForOwner;

  static List<({String owner, String name})> _specs(List<Repo> repos) => [
    for (final r in repos) (owner: r.remoteOwner, name: r.remoteName),
  ];

  /// Groups [repos] by owner (case-insensitively — GitHub logins are), keeping
  /// each group's original casing for the API calls.
  static Map<String, List<Repo>> _byOwner(List<Repo> repos) {
    final grouped = <String, List<Repo>>{};
    for (final repo in repos) {
      (grouped[repo.remoteOwner.toLowerCase()] ??= []).add(repo);
    }
    return grouped;
  }

  @override
  Future<({bool changed, String? etag})> probeRepo(
    Repo repo,
    String? etag,
  ) async {
    final probe = await _clientForOwner(
      repo.remoteOwner,
    ).pr.probeOpenPullRequests(repo.remoteOwner, repo.remoteName, etag: etag);
    return (changed: probe.changed, etag: probe.etag);
  }

  @override
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos) async {
    final groups = <OpenPrGroup>[];
    final resolved = <String>{};

    await Future.wait(
      _byOwner(repos).values.map((ownerRepos) async {
        final client = _clientForOwner(ownerRepos.first.remoteOwner);
        final specs = _specs(ownerRepos);
        final GitHubPrBatchResult batch;
        try {
          batch = await client.graphql.fetchOpenPullRequestsBatch(specs);
        } on Object catch (e) {
          // Contribute nothing for this owner: its repos stay unresolved, so
          // the poller keeps their previous entries. Every other owner's
          // results still land.
          CcHostLog.warning(
            'open_pr_poll: GitHub fetch failed for '
            '${ownerRepos.first.remoteOwner} (${ownerRepos.length} repo(s)): '
            '$e',
          );
          return;
        }
        var checks = <int, Map<int, GitHubPrStatusOverlay>>{};
        try {
          checks = await client.graphql.fetchOpenPullRequestsChecks(specs);
        } on Object catch (e) {
          // Checks are best-effort for RENDERING — the rows still list. They
          // are not best-effort for NOTIFYING: an unread rollup decodes to the
          // same `none` as "this PR has no checks", so the poller carries the
          // previous value forward rather than persisting the gap (see
          // `_carryEnrichmentForward`). Logged because this failure used to be
          // completely silent while being the trigger for repeat
          // notifications.
          CcHostLog.warning(
            'open_pr_poll: checks overlay failed for '
            '${ownerRepos.first.remoteOwner} (${ownerRepos.length} repo(s)) — '
            'keeping the previous checks/review state: $e',
          );
        }
        for (var i = 0; i < ownerRepos.length; i++) {
          final repo = ownerRepos[i];
          final repoResult = batch.byIndex[i];
          if (repoResult == null) {
            continue;
          }
          // Present in the batch = GitHub answered for this repo. Recorded
          // BEFORE the empty-group skip below, so a repo with a genuinely
          // empty queue still counts as resolved.
          resolved.add(repo.id);
          final repoChecks = checks[i];
          final prs = <PullRequest>[];
          for (final node in repoResult.nodes) {
            final number = (node['number'] as num?)?.toInt() ?? 0;
            final title = node['title'] as String? ?? '';
            if (number <= 0 || title.isEmpty) {
              continue;
            }
            var pr = pullRequestFromGraphQlNode(
              node,
              repoFullName: repo.fullName,
            );
            final overlay = repoChecks?[pr.number];
            if (overlay != null) {
              pr = pr.copyWith(
                checksStatus: prChecksStatusFromRollup(overlay.checksRollup),
                reviewDecision: PrReviewDecision.fromString(
                  overlay.reviewDecision,
                ),
              );
            }
            prs.add(pr);
          }
          if (prs.isEmpty) {
            continue;
          }
          groups.add((repo: repo, prs: prs, hasMore: repoResult.hasMore));
        }
      }),
    );

    return (groups: groups, resolvedRepoIds: resolved);
  }

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos,
  ) async {
    final merged = <String, Map<int, PrStatusOverlay>>{};

    await Future.wait(
      _byOwner(repos).values.map((ownerRepos) async {
        final Map<int, Map<int, GitHubPrStatusOverlay>> byIndex;
        try {
          byIndex = await _clientForOwner(
            ownerRepos.first.remoteOwner,
          ).graphql.fetchOpenPullRequestsChecks(_specs(ownerRepos));
        } on Object catch (e) {
          CcHostLog.warning(
            'open_pr_poll: GitHub checks pass failed for '
            '${ownerRepos.first.remoteOwner}: $e',
          );
          return;
        }
        for (var i = 0; i < ownerRepos.length; i++) {
          final overlays = byIndex[i];
          if (overlays == null) {
            continue;
          }
          merged[ownerRepos[i].id] = {
            for (final e in overlays.entries)
              e.key: (
                checksRollup: e.value.checksRollup,
                reviewDecision: e.value.reviewDecision,
              ),
          };
        }
      }),
    );

    return merged;
  }

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber) async {
    try {
      final gh = await _clientForOwner(
        repo.remoteOwner,
      ).pr.getPullRequest(repo.remoteOwner, repo.remoteName, prNumber);
      if (gh == null) {
        return null;
      }
      return gh.mergedAt != null;
    } on Object {
      return null;
    }
  }

  @override
  Future<PrMergeableState> mergeState(Repo repo, int prNumber) async {
    try {
      final gh = await _clientForOwner(
        repo.remoteOwner,
      ).pr.getPullRequest(repo.remoteOwner, repo.remoteName, prNumber);
      if (gh == null || gh.mergeableState.isEmpty) {
        return PrMergeableState.unknown;
      }
      return PrMergeableState.fromString(gh.mergeableState);
    } on Object {
      // Not confirmed. The caller leaves the snapshot alone, so the edge is
      // re-attempted next sweep rather than announced on a failed read.
      return PrMergeableState.unknown;
    }
  }

  @override
  Future<String?> latestApprover(Repo repo, int prNumber) async {
    try {
      final reviews = await _clientForOwner(
        repo.remoteOwner,
      ).pr.listPullRequestReviews(repo.remoteOwner, repo.remoteName, prNumber);
      GitHubReview? newest;
      for (final review in reviews) {
        if (review.state != GitHubReviewState.approved) {
          continue;
        }
        final at = review.submittedAt;
        final best = newest?.submittedAt;
        if (newest == null ||
            (at != null && (best == null || at.isAfter(best)))) {
          newest = review;
        }
      }
      final login = newest?.user?.login;
      return (login == null || login.isEmpty) ? null : login;
    } on Object {
      return null;
    }
  }

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  ) async {
    try {
      final gh = await _clientForOwner(
        repo.remoteOwner,
      ).pr.getPullRequest(repo.remoteOwner, repo.remoteName, prNumber);
      final sha = gh?.headSha;
      if (sha == null || sha.isEmpty) {
        return null;
      }
      final runs = await _clientForOwner(
        repo.remoteOwner,
      ).pr.listCheckRuns(repo.remoteOwner, repo.remoteName, sha);
      for (final run in runs) {
        if (run.isFailing) {
          return (name: run.name, url: run.htmlUrl);
        }
      }
      return null;
    } on Object {
      return null;
    }
  }
}

/// One repo's access bookkeeping: consecutive access-denied probe failures
/// and the parked ("inaccessible") state they escalate into.
class _RepoAccessState {
  _RepoAccessState({required this.repoFullName});

  /// The repo's `owner/name` at the last observation, for the wire entry.
  String repoFullName;

  /// Consecutive access-denied probe failures. Reset by any successful probe.
  int consecutiveFailures = 0;

  /// Whether the repo is parked: probed on the slow retry cadence only and
  /// excluded from fetches, because its denial is deterministic until a human
  /// installs the app there or fixes the token.
  bool parked = false;

  /// The `NetworkException.code` that parked it (`not_found` / `auth_error`).
  String reason = '';

  /// When the repo was parked.
  DateTime? since;

  /// Last slow-cadence retry, so parked repos are probed sparsely.
  DateTime? lastRetryAt;

  bool isRetryDue(DateTime now, Duration interval) =>
      lastRetryAt == null || now.difference(lastRetryAt!) >= interval;
}

/// Per-workspace poller state.
class _WorkspacePollState {
  /// Active `pr.watchOpenForWorkspace` subscriptions (fast cadence when > 0).
  int interest = 0;

  /// Last conditional-request ETag per repo id.
  final Map<String, String> etagByRepoId = {};

  /// Access bookkeeping per repo id. A repo is present here once a probe has
  /// been denied; it leaves the map the moment a probe succeeds again.
  final Map<String, _RepoAccessState> accessByRepoId = {};

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
    Future<String> Function(ForgeHost forge)? viewerLoginFor,
    String? forUserId,
    this.fastInterval = const Duration(seconds: 60),
    this.idleInterval = const Duration(minutes: 2),
    this.checksEvery = 2,
    this.accessFailureThreshold = 3,
    this.inaccessibleRetryInterval = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _port = fetchPort,
       _workspaces = workspaceRepository,
       _dbs = workspaceDbs,
       _signals = changeSignals,
       _prToWire = prToWire,
       _eventBus = eventBus,
       _viewerLoginFor = viewerLoginFor,
       _forUserId = forUserId,
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

  /// Resolves the operator's own login on a forge.
  ///
  /// The author-facing notifications (ready to merge, approved, checks failed)
  /// are gated on it: this poller sweeps EVERY open PR in every linked repo,
  /// so without the gate a busy monorepo announces strangers' work. Null
  /// disables those lanes entirely — the poller's pre-existing behaviour.
  final Future<String> Function(ForgeHost forge)? _viewerLoginFor;

  /// The Control Center user [_viewerLoginFor] resolves for, stamped on every
  /// author-facing event so the client can route it to the right principal.
  final String? _forUserId;

  /// Per-pass budget for the targeted confirmation/attribution fetches. Both
  /// are one REST call each on a transition edge; capping them keeps a sweep
  /// that happens to move twenty PRs at once from turning into twenty extra
  /// round trips. A skipped edge is not lost — the snapshot still holds the
  /// old value, so it is re-detected next sweep.
  static const _maxMergeConfirmsPerPass = 5;
  static const _maxApproverLookupsPerPass = 5;

  int _mergeConfirms = 0;
  int _approverLookups = 0;

  /// Viewer logins resolved once per pass, keyed by forge.
  final Map<ForgeHost, String> _viewerLoginCache = {};

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
  /// acts (installs the app, fixes a token), so the fast cadence would burn a
  /// failing request per minute and spam the log for nothing. An explicit
  /// refresh always retries immediately.
  final Duration inaccessibleRetryInterval;

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
  /// Every emitted frame is tagged with the live sweep-in-flight flag and a
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

    final snapshotSub = _cache(workspaceId)
        .watch(workspaceId, cacheKind, cacheKey)
        .listen((raw) {
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
    final snapshot = await _readPersistedSnapshot(workspaceId);
    for (final wire in _prsByNumber(snapshot, repoFullName).values) {
      if (wire['head_ref'] == branch) {
        return wire;
      }
    }
    return null;
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
      final repos = [
        for (final r in linked)
          if (r.hasForgeRemote) r,
      ];
      if (repos.isEmpty) {
        return;
      }

      if (!st.snapshotLoaded) {
        st.snapshot = await _readPersistedSnapshot(workspaceId);
        st.snapshotLoaded = true;
        _seedAccessFromSnapshot(st);
      }

      // Probe first even on forced/first sweeps: the ETag captured *before*
      // the full fetch guarantees at-least-once change detection (anything
      // that lands after the probe re-triggers a 200 next tick). A probe
      // without a prior ETag (first tick, post-restart) always answers 200 —
      // that over-approximates "changed" once and the snapshot diff below
      // dedupes it into zero published events.
      var listChanged = force || st.snapshot == null;
      var accessChanged = false;
      for (final repo in repos) {
        final access = st.accessByRepoId[repo.id];
        // Parked repos are re-probed on the slow cadence only (or on an
        // explicit refresh): their denial is deterministic until a human
        // installs the app or fixes the token, and probing every tick burns a
        // failing request per minute and a log line with it.
        if (access != null && access.parked) {
          if (!force && !access.isRetryDue(_now(), inaccessibleRetryInterval)) {
            continue;
          }
          access.lastRetryAt = _now();
        }
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
      }

      // Parked repos are excluded from fetches: their batch aliases can only
      // error, and their previous snapshot entries are carried over anyway.
      final fetchable = [
        for (final r in repos)
          if (!(st.accessByRepoId[r.id]?.parked ?? false)) r,
      ];

      if (listChanged && fetchable.isNotEmpty) {
        final result = await _port.fetchGroups(fetchable);
        // GitHub answered for nothing. The batch query tolerates partial
        // failure, so a service incident returns "no repos" exactly like a
        // workspace whose queues are all empty — and persisting that would
        // overwrite a good snapshot with an empty one, tell every client the
        // inbox is clear and publish a merged/closed event for every PR that
        // "vanished". Keep the last snapshot and try again next tick.
        if (result.resolvedRepoIds.isEmpty) {
          CcHostLog.warning(
            'open_pr_poll: GitHub resolved 0 of ${fetchable.length} repos for '
            '$workspaceId — keeping the previous snapshot',
          );
          if (accessChanged) {
            await _persistAccessOnly(workspaceId, st);
          }
          return;
        }
        final resolved = [
          for (final r in fetchable)
            if (result.resolvedRepoIds.contains(r.id)) r,
        ];
        // A partial answer updates only the repos it covered: the unresolved
        // ones keep their previous entries rather than disappearing, and the
        // diff runs over the resolved repos alone so they publish no events.
        final fresh = _snapshotFromGroups(
          result.groups,
          previous: st.snapshot,
          resolvedRepoIds: result.resolvedRepoIds,
          inaccessible: _inaccessibleWire(st),
        );
        if (resolved.length < fetchable.length) {
          CcHostLog.warning(
            'open_pr_poll: GitHub resolved ${resolved.length} of '
            '${fetchable.length} repos for $workspaceId — the rest keep their '
            'previous entries',
          );
        }
        await _diffAndPublish(workspaceId, resolved, st.snapshot, fresh);
        st.snapshot = fresh;
        await _persistSnapshot(workspaceId, fresh);
      } else if (accessChanged) {
        // Access transitions alone (a repo parked, or one recovering behind a
        // 304) still have to reach every client's notice.
        await _persistAccessOnly(workspaceId, st);
      } else if (!listChanged && includeChecks && st.snapshot != null) {
        await _checksPass(workspaceId, fetchable, st);
      }
    } on Object catch (e) {
      CcHostLog.warning('open_pr_poll: sweep failed for $workspaceId: $e');
    }
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
      'not_found' || 'auth_error' => error.code,
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
    if (access.parked || access.consecutiveFailures < accessFailureThreshold) {
      return false;
    }
    access
      ..parked = true
      ..since = _now()
      ..lastRetryAt = _now();
    CcHostLog.warning(
      'open_pr_poll: parking ${repo.fullName} — not accessible ($reason) '
      'after ${access.consecutiveFailures} consecutive probes; retrying every '
      '${inaccessibleRetryInterval.inMinutes}m. If the repo lives in an org, '
      "the server's GitHub App or token may not have access there.",
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

  /// Builds the wire snapshot from [groups].
  ///
  /// When [previous] is given, any of its repo entries whose id is NOT in
  /// [resolvedRepoIds] is carried over verbatim: GitHub did not answer for
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
    return {
      'authenticated': true,
      'repos': repos,
      'inaccessible_repos': inaccessible,
    };
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
      'github_owner': group.repo.remoteOwner,
      'github_repo_name': group.repo.remoteName,
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

  /// Merges one pull request's freshly fetched wire map with what the previous
  /// snapshot knew, so an enrichment this sweep could not read is never
  /// persisted as if the forge had answered it.
  ///
  /// `checks_status` and `review_decision` do not come from the open-PR list
  /// query. They are a second, far heavier GraphQL pass (`statusCheckRollup`
  /// across every open PR of every repo), and it is the one GitHub answers
  /// with 502/504 under load — several times an hour on a busy org. Both
  /// fields decode an unread answer to `none`, which is indistinguishable from
  /// "this PR has no checks / no review decision", so a failed pass used to
  /// overwrite `failing`/`approved` with `none` and the next successful pass
  /// re-detected the very same edge and announced it as news.
  ///
  /// Only the recovery is notifiable — a downgrade to `none` deliberately is
  /// not — so the flap was silent in one direction and a notification in the
  /// other: ONE approval, re-announced every few minutes for as long as the
  /// heavy query kept timing out. It loses notifications too, in the same
  /// stroke: `failing -> none -> passing` is not a recovery, so the green
  /// build that followed a fix went unannounced.
  ///
  /// `review_decision` is carried unconditionally: the forge reports
  /// `REVIEW_REQUIRED` when an approval is dismissed and never drops back to
  /// null while a pull request is open, so `none` after a known decision is
  /// always a failed read. `checks_status` is carried only while the head
  /// commit is unchanged — a push legitimately lands on a commit that has no
  /// rollup yet, and re-arming there is what keeps the next real failure on
  /// the new commit newsworthy.
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

  /// Resolves the operator's login on [forge], once per pass.
  ///
  /// Empty means "no credential yet" and suppresses every author-facing lane.
  /// Silence beats telling someone a stranger's PR is theirs, and the resolver
  /// re-runs on the next pass, so this self-heals on sign-in.
  Future<String> _viewerLogin(ForgeHost forge) async {
    final resolver = _viewerLoginFor;
    if (resolver == null) {
      return '';
    }
    final cached = _viewerLoginCache[forge];
    if (cached != null) {
      return cached;
    }
    String login;
    try {
      login = (await resolver(forge)).trim();
    } on Object catch (e) {
      CcHostLog.warning('open_pr_poll: viewer login unavailable: $e');
      login = '';
    }
    return _viewerLoginCache[forge] = login;
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
  ) async {
    final bus = _eventBus;
    if (bus == null) {
      return null;
    }
    final viewer = await _viewerLogin(repo.forge);
    if (viewer.isEmpty) {
      return null;
    }
    final author = ((newWire['author'] as Map?)?['login'] as String?) ?? '';
    if (author.toLowerCase() != viewer.toLowerCase()) {
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
      if (verdictMissing && _mergeConfirms < _maxMergeConfirmsPerPass) {
        _mergeConfirms++;
        final confirmed = await _port.mergeState(repo, number);
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
            forUserId: _forUserId,
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
              forUserId: _forUserId,
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
              _approverLookups < _maxApproverLookupsPerPass) {
            _approverLookups++;
            approver = await _port.latestApprover(repo, number);
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
              forUserId: _forUserId,
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
              forUserId: _forUserId,
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
              forUserId: _forUserId,
              occurredAt: _now(),
            ),
          );
        case PrChecksFailed():
          final failing = await _firstFailingCheck(repo, number);
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
              forUserId: _forUserId,
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
              forUserId: _forUserId,
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
    int number,
  ) async {
    try {
      return await _port.firstFailingCheck(repo, number);
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
  ) async {
    // First-ever sweep for this workspace: baseline only — recording without
    // notifying, so server start doesn't spam events for pre-existing PRs.
    final isBaseline = previous == null;
    _mergeConfirms = 0;
    _approverLookups = 0;
    _viewerLoginCache.clear();
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
                repoOwner: repo.fullName.split('/').first,
                repoName: repo.fullName.split('/').skip(1).join('/'),
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
        );
        // A forge-confirmed mergeable state is folded back into the snapshot
        // being persisted, so the next sweep compares against the confirmed
        // value rather than re-deriving and re-confirming the same edge.
        if (confirmed != null) {
          entry.value['mergeable_state'] = confirmed;
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
    _mergeConfirms = 0;
    _approverLookups = 0;
    _viewerLoginCache.clear();
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
