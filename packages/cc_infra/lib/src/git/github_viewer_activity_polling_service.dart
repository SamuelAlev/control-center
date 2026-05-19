import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show AppException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_infra/src/git/viewer_comment_fetch_port.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/github_graphql_client.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:cc_infra/src/network/models/github_viewer_activity.dart';
import 'package:meta/meta.dart';

/// Polls the server owner's own GitHub pull-request activity and turns it into
/// live updates:
///
///  - a review pending on the viewer publishes [PrReviewRequested] (→ OS/bell
///    notification on every connected client, one per linking workspace);
///  - an @-mention publishes [PrMentioned], once per PR;
///  - a merged PR the viewer was involved with publishes [ExternalPrMerged],
///    once per PR;
///  - every PR that moved publishes a [PrChangeSignal] and nudges the open-PR
///    poller, so the affected PR's detail streams and the list refresh within
///    seconds of the activity instead of at the next sweep. This is the one
///    lane that intentionally re-fires on every `updatedAt` bump, so it keys on
///    `repo#number|updatedAt`.
///
/// ## Why this is a search and not the notifications inbox
///
/// This lane used to read `GET /notifications`. **No GitHub App token can ever
/// read that endpoint** — not an installation token and not a user-to-server
/// one — because no App permission grants it; GitHub answers "Resource not
/// accessible by integration", forever. Signing in to Control Center mints a
/// GitHub App user token, so the inbox lane was permanently dead for every
/// install that had not additionally pasted a classic PAT carrying
/// `notifications` or `repo`. It failed as a warning every five minutes while
/// three notification types silently never fired.
///
/// `search` is reachable by every credential kind, so one code path now serves
/// an App token, an OAuth token and a PAT alike. There is deliberately **no
/// fallback to the inbox** when a PAT happens to be present: two lanes that can
/// disagree is worse than one that always works, and the disagreement would
/// only ever be visible to whoever configured the rarer credential.
///
/// ## What the search buys beyond reachability
///
/// Each lane is a server-side predicate, so the sweep is *cheaper* than the
/// inbox poll it replaced rather than merely equivalent:
///
///  - **Team review requests come for free and are no longer best-effort.**
///    `review-requested:@me` includes reviews requested of a team the viewer
///    belongs to (GitHub: "if the requested person is on a team that is
///    requested for review, then review requests for that team will also appear
///    in the search results"). In practice that is most of them. The old path
///    reproduced this by hand — resolve the viewer's login, list their org
///    teams, fetch each PR's `reviewRequests` and compare — which needed a
///    `read:org`-scoped credential and degraded to a cruder once-per-thread
///    rule whenever that lookup failed.
///  - **Membership *is* the pending bit.** GitHub drops a reviewer from
///    `review-requested:` results the moment they submit their review, so the
///    per-PR review-state probe is gone.
///  - **`is:merged` is the merge verification**, so the per-PR merge-state probe
///    is gone too.
///
/// The pending-review lane is therefore a **set**, not a stream of events, and
/// the transition table falls out of a set diff against the persisted set:
///
/// | in persisted set | in search result | result |
/// |---|---|---|
/// | no  | yes | notify (new/re-requested, or a draft became ready) |
/// | yes | yes | silent (still pending; a commit bump is not news) |
/// | yes | no  | silent (viewer reviewed, or the request was withdrawn) |
///
/// `draft:false` is what makes "draft became ready" a genuine transition: a
/// draft is simply absent from the set, so marking it ready is a no→yes edge.
/// This matters because GitHub itself withholds review-request notifications on
/// drafts, and CODEOWNERS auto-requests fire on every push to one.
///
/// ## Cost discipline
///
/// One HTTP request per sweep — four aliased searches, one rate-limit charge —
/// regardless of how many repos are linked. The searches are global and the
/// results are filtered against the repo→workspace index, which is the same
/// shape the inbox had. There is no `If-Modified-Since` equivalent for search,
/// so an idle sweep costs one request where the inbox could answer 304; against
/// that, the inbox path spent an extra round-trip *per interesting thread*
/// verifying what search now answers inline.
///
/// The first successful fetch is a **baseline**: with no persisted state,
/// everything currently outstanding is recorded without acting, so a first run
/// does not replay an operator's entire backlog as notifications. With a
/// persisted store the baseline is not suppressed at all — the persisted set
/// and the `updated:>` watermark together *are* the memory, so anything that
/// arrived while the server was down is caught up and delivered exactly once.
class GitHubViewerActivityPollingService {
  /// Creates a [GitHubViewerActivityPollingService].
  GitHubViewerActivityPollingService({
    required GitHubApiClient githubClient,
    required DomainEventBus eventBus,
    required PrChangeSignals changeSignals,
    required Future<List<String>> Function(String repoFullName)
    workspacesForRepo,
    void Function(String workspaceId)? onWorkspaceTouched,
    Future<bool> Function()? shouldPoll,
    Future<String> Function()? viewerLogin,
    ViewerCommentFetchPort? commentFetch,
    String? forUserId,
    this.minInterval = const Duration(seconds: 60),
    this.idleInterval = const Duration(minutes: 5),
    this.loadDedupeState,
    this.saveDedupeState,
    DateTime Function()? now,
  }) : _client = githubClient,
       _shouldPoll = shouldPoll,
       _eventBus = eventBus,
       _signals = changeSignals,
       _workspacesForRepo = workspacesForRepo,
       _onWorkspaceTouched = onWorkspaceTouched,
       _viewerLogin = viewerLogin,
       _commentFetch = commentFetch,
       _forUserId = forUserId,
       _now = now ?? DateTime.now;

  final GitHubApiClient _client;
  final DomainEventBus _eventBus;
  final PrChangeSignals _signals;

  /// Resolves the workspace ids that link `owner/name` (empty when the repo
  /// isn't linked anywhere — those PRs are ignored).
  final Future<List<String>> Function(String repoFullName) _workspacesForRepo;

  /// Optional freshness nudge (the open-PR poller's `pollSoon`).
  final void Function(String workspaceId)? _onWorkspaceTouched;

  /// The operator's own forge login, for matching `@mentions` in comment
  /// bodies. Null (or empty) disables the comment lane entirely — the coarse
  /// PR-level mention lane then behaves exactly as it did before.
  final Future<String> Function()? _viewerLogin;

  /// Reads comments for the comment lane. Null disables it, same as above.
  final ViewerCommentFetchPort? _commentFetch;

  /// The Control Center user the [_viewerLogin] credential belongs to, stamped
  /// on every event so the client can route it to the right principal.
  final String? _forUserId;

  /// Whether this pass should call GitHub at all.
  ///
  /// This reads the viewer's *own* activity, so it needs a signed-in human —
  /// and somewhere to route what comes back. A server that has booted with an
  /// app identity (or a bare `GITHUB_TOKEN`) but no signed-in owner, no
  /// workspace, or an unfinished onboarding has neither, and calling anyway
  /// burns a request a minute on a result nothing can consume. Null = always
  /// poll (the pre-gate behaviour, kept for tests).
  final Future<bool> Function()? _shouldPoll;

  /// Floor for the polling cadence.
  final Duration minInterval;

  /// Cadence while [_shouldPoll] says no, or after an auth failure. Slow on
  /// purpose: nothing here is urgent, and the condition it waits for (a human
  /// signing in, a first workspace) is measured in minutes, not seconds.
  final Duration idleInterval;

  /// Loads the persisted dedupe state (JSON), or null when none was saved.
  /// Absent (or null/unparseable/older-version result) = first-run-ever
  /// semantics: the baseline records everything silently.
  final Future<String?> Function()? loadDedupeState;

  /// Persists the dedupe state after each pass that changed it.
  final Future<void> Function(String state)? saveDedupeState;

  final DateTime Function() _now;

  /// Bound on each dedupe lane's memory.
  static const _seenCap = 512;

  /// The persisted-state format. Bumped from the inbox era: those entries were
  /// keyed by GitHub notification **thread id**, which has no meaning here, so a
  /// v1 store is discarded rather than misread as a populated dedupe set.
  ///
  /// v3 adds the comment lanes. A v2 store is likewise discarded rather than
  /// loaded partially: it holds no comment keys and no unresolved-thread set,
  /// so loading it would look like "every comment already seen" for the PR
  /// lanes while the comment lanes baseline — two different memories of the
  /// same sweep. Discarding costs one silent pass.
  static const _storeVersion = 3;

  /// Hard cap on PRs whose comments are fetched per sweep.
  ///
  /// Ten, not the bot poller's 25: this runs on the operator's PERSONAL rate
  /// limit and the candidate set is already narrowed to PRs that involve them
  /// and actually moved. A PR beyond the cap is picked up by the rotating
  /// cursor on a later sweep, and the coarse `mentions:@me` lane covers the
  /// mention in the meantime.
  static const _maxCommentSweeps = 10;

  /// How far back the sweep looks beyond its own watermark.
  ///
  /// GitHub's search index lags writes by seconds to a minute, so a window that
  /// abuts the previous sweep exactly drops whatever was still being indexed at
  /// the cut. Over-fetching costs nothing — every lane is deduped — while a
  /// miss is silent and permanent.
  static const _searchLagOverlap = Duration(minutes: 5);

  /// Hard cap on the `updated:>` window, however stale the watermark is.
  ///
  /// The watermark is only persisted periodically (see [_watermarkRefresh]), so
  /// on a long quiet stretch it can fall well behind. Without a clamp the
  /// window would keep widening until the lanes overflowed their single page
  /// and started dropping the newest results.
  static const _maxLookback = Duration(hours: 24);

  /// How often the watermark is persisted on an otherwise unchanged sweep.
  ///
  /// Writing it every pass would be a `global.db` write a minute to record that
  /// nothing happened; never writing it would let the window widen without
  /// bound. This is the compromise.
  static const _watermarkRefresh = Duration(minutes: 15);

  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  bool _baseline = true;

  /// Log-once latches: an idle server and a wrong credential are both standing
  /// conditions, and a per-pass line for either buries everything else.
  bool _loggedIdle = false;
  bool _loggedAuthFailure = false;

  /// Change-signal lane, keyed on `repo#number|updatedAt`: a PR is
  /// (re)processed whenever it updates, so an active PR refreshes on every
  /// commit/comment.
  final _seenChanges = _BoundedKeySet(_seenCap);

  /// Mention and merged dedupe lanes, keyed on `repo#number|mention` and
  /// `repo#number|state_change`. Persisted.
  final _notified = _BoundedKeySet(_seenCap);

  /// The PRs whose review is currently pending on the viewer, keyed
  /// `repo#number`. Persisted, so the transition semantics survive a restart.
  /// Holds only what is *currently* pending: an entry is removed when the PR
  /// leaves the search result, which keeps it self-cleaning.
  final _pendingReview = _BoundedKeySet(_seenCap);

  /// Comment-level dedupe, keyed `cm:<commentId>` (mention) and
  /// `cr:<commentId>` (reply in a thread the viewer is in). Comment ids are
  /// unique across the forge, so no repo qualifier is needed. Persisted.
  final _notifiedComments = _BoundedKeySet(_seenCap);

  /// Review threads the viewer participates in that are currently UNRESOLVED,
  /// keyed by GraphQL node id. Persisted, so the `false -> true` edge survives
  /// a restart. A thread that leaves this set has been resolved (or is no
  /// longer ours) and re-entering it re-arms the edge — correct, because a
  /// re-opened thread being resolved again is a second thing that happened.
  final _threadsUnresolved = _BoundedKeySet(_seenCap);

  /// Rotating cursor into the comment-sweep candidate list, so the PRs beyond
  /// [_maxCommentSweeps] are not starved forever behind the same head.
  int _commentCursor = 0;

  bool _storeLoaded = false;

  /// True when no store is wired, or the stored state was missing/unparseable/
  /// from an older format: the baseline then records silently.
  bool _firstRunEver = false;

  /// The `updated:>` anchor — the start of the last sweep whose state was
  /// persisted. Null until the first save.
  DateTime? _watermark;

  /// The watermark actually written to the store, so a refresh can be due
  /// without any other change.
  DateTime? _persistedWatermark;

  bool _dedupeDirty = false;
  Future<void>? _dedupeLoad;

  /// Starts the poll loop (immediate first poll). Idempotent.
  void start() {
    if (_running || _disposed) {
      return;
    }
    _running = true;
    _schedule(Duration.zero);
  }

  /// Stops the loop.
  void dispose() {
    _disposed = true;
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule(Duration delay) {
    if (_disposed || !_running) {
      return;
    }
    _timer = Timer(delay, () => unawaited(_poll()));
  }

  /// Runs exactly one poll pass without entering the timer loop.
  @visibleForTesting
  Future<void> pollOnce() => _poll();

  Future<void> _poll() async {
    if (_disposed) {
      return;
    }
    if (!await _ready()) {
      _schedule(idleInterval);
      return;
    }
    try {
      await _ensureDedupeLoaded();
      final sweepStart = _now().toUtc();
      final activity = await _client.graphql.searchViewerPullRequestActivity(
        since: _windowStart(sweepStart),
      );
      await _handle(activity, sweepStart);
      _loggedAuthFailure = false;
      _schedule(minInterval);
    } on Object catch (e) {
      // An auth failure is a STANDING condition, not a blip: the credential
      // answering is the wrong one (or has been revoked) and will still be
      // wrong in 120 seconds. Retrying at the fast cadence turns one
      // misconfiguration into a warning a minute forever, so it drops to the
      // idle cadence and says its piece once. Everything else keeps the old
      // twice-the-floor backoff, since a 5xx, a rate limit or a timeout really
      // can pass.
      if (e is AppException && e.code == 'auth_error') {
        if (!_loggedAuthFailure) {
          _loggedAuthFailure = true;
          CcInfraLog.warning(
            'github_activity: GitHub refused the viewer-activity search ($e). '
            'The server owner\'s GitHub credential is missing, expired or '
            'revoked — re-connect GitHub in Settings. Retrying every '
            '${idleInterval.inMinutes}m; this is logged once per outage.',
          );
        }
        _schedule(idleInterval);
        return;
      }
      CcInfraLog.warning('github_activity: poll failed: $e');
      // Back off to twice the floor on failure; the next success re-tightens.
      _schedule(minInterval * 2);
    }
  }

  /// The `updated:>` anchor for this sweep: the watermark less the index-lag
  /// overlap, clamped to [_maxLookback]. Null (the client's own default window)
  /// when there is no watermark yet.
  DateTime? _windowStart(DateTime sweepStart) {
    final mark = _watermark;
    if (mark == null) {
      return null;
    }
    final floor = sweepStart.subtract(_maxLookback);
    final start = mark.subtract(_searchLagOverlap);
    return start.isBefore(floor) ? floor : start;
  }

  /// The readiness gate, failing CLOSED: a gate that throws means we could not
  /// establish that polling is safe, which is not the same as knowing it is.
  Future<bool> _ready() async {
    final gate = _shouldPoll;
    if (gate == null) {
      return true;
    }
    bool ready;
    try {
      ready = await gate();
    } on Object catch (e) {
      CcInfraLog.warning('github_activity: readiness check failed: $e');
      ready = false;
    }
    if (ready) {
      _loggedIdle = false;
      return true;
    }
    if (!_loggedIdle) {
      _loggedIdle = true;
      CcInfraLog.info(
        'github_activity: idle — no signed-in GitHub user or no workspace yet, '
        'so there is no activity to read and nowhere to route it. Re-checking '
        'every ${idleInterval.inMinutes}m.',
      );
    }
    return false;
  }

  Future<void> _handle(
    GitHubViewerActivity activity,
    DateTime sweepStart,
  ) async {
    // On a first run ever there is no memory to diff against, so everything
    // outstanding would look new. Record it and stay quiet. With a store this
    // is NOT suppressed: the persisted set plus the watermark already say what
    // has been seen, so a restart catches up instead of replaying.
    final silent = _baseline && _firstRunEver;

    // One routing lookup per repo for the whole sweep, not one per PR: a busy
    // account's four lanes name the same handful of repos over and over.
    final routes = <String, List<String>>{};
    Future<List<String>> route(String repoFullName) async {
      final cached = routes[repoFullName];
      if (cached != null) {
        return cached;
      }
      List<String> resolved;
      try {
        resolved = await _workspacesForRepo(repoFullName);
      } on Object catch (e) {
        CcInfraLog.warning(
          'github_activity: workspace resolution failed for $repoFullName: $e',
        );
        resolved = const [];
      }
      return routes[repoFullName] = resolved;
    }

    await _handlePendingReviews(activity.reviewRequested, route, silent);

    // The comment lane runs BEFORE the coarse mention lane, and reports which
    // PRs it resolved a mention on. A mention that was pinned to a comment is
    // strictly better than the PR-level one — it names the file and line and
    // deep-links to the comment — so publishing both would be two pings for
    // one comment. A PR the cap or an error skipped is NOT in the set, so it
    // falls through to the coarse lane rather than being lost.
    final coveredByComments = await _handleComments(activity, route, silent);
    await _handleOnce(
      activity.mentioned.where((pr) => !coveredByComments.contains(pr.key)),
      route,
      silent,
      'mention',
      (pr, workspaceId) => PrMentioned(
        workspaceId: workspaceId,
        repoOwner: pr.owner,
        repoName: pr.name,
        prNumber: pr.number,
        prTitle: pr.title,
        occurredAt: _now(),
      ),
    );
    await _handleOnce(
      activity.merged,
      route,
      silent,
      'state_change',
      (pr, workspaceId) => ExternalPrMerged(
        workspaceId: workspaceId,
        repoOwner: pr.owner,
        repoName: pr.name,
        prNumber: pr.number,
        prTitle: pr.title,
        // Not filtered here the way a self-authored COMMENT is (see
        // `isViewer` in `_sweepPrComments`): that lane resolves a
        // `forUserId` and is addressed to one person, while this one reaches
        // the whole workspace. Suppressing the viewer's own merge server-side
        // would take it from every teammate too, so the merger travels on the
        // event and each client decides for itself.
        mergedByLogin: pr.mergedByLogin,
        occurredAt: _now(),
      ),
    );

    // Freshness nudges. Skipped on the baseline pass in every case (not just
    // first-run-ever): the open-PR poller runs its own sweep at boot, so a
    // burst of `pollSoon` here would only duplicate it.
    if (!_baseline) {
      for (final pr in activity.all) {
        final stamp = pr.updatedAt?.millisecondsSinceEpoch ?? 0;
        if (!_seenChanges.add('${pr.key}|$stamp')) {
          continue;
        }
        for (final workspaceId in await route(pr.repoFullName)) {
          _signals.notify(
            workspaceId: workspaceId,
            repoFullName: pr.repoFullName,
            prNumber: pr.number,
          );
          _onWorkspaceTouched?.call(workspaceId);
        }
      }
    }

    _baseline = false;
    await _saveDedupeState(sweepStart);
  }

  /// The pending-review set diff. See the transition table in the class doc.
  Future<void> _handlePendingReviews(
    List<GitHubViewerPr> pending,
    Future<List<String>> Function(String) route,
    bool silent,
  ) async {
    final present = <String>{};
    for (final pr in pending) {
      // An unlinked repo is skipped BEFORE the dedupe lane is touched, so
      // linking it later still delivers the request rather than finding it
      // already marked seen.
      final workspaceIds = await route(pr.repoFullName);
      if (workspaceIds.isEmpty) {
        continue;
      }
      present.add(pr.key);
      if (!_pendingReview.add(pr.key)) {
        // Already pending: a commit bump while the review is still outstanding
        // is not news.
        continue;
      }
      _dedupeDirty = true;
      if (silent) {
        continue;
      }
      for (final workspaceId in workspaceIds) {
        _eventBus.publish(
          PrReviewRequested(
            workspaceId: workspaceId,
            repoOwner: pr.owner,
            repoName: pr.name,
            prNumber: pr.number,
            prTitle: pr.title,
            occurredAt: _now(),
          ),
        );
      }
    }
    // Anything recorded as pending that the search no longer returns has been
    // reviewed, withdrawn, closed or turned back into a draft. Silent, and
    // dropped so the set stays the size of the real backlog.
    for (final key in _pendingReview.keys.toList()) {
      if (!present.contains(key) && _pendingReview.remove(key)) {
        _dedupeDirty = true;
      }
    }
  }

  /// The comment lane: per-comment mentions, replies in the viewer's threads
  /// and thread resolutions.
  ///
  /// Returns the `pr.key`s on which a mention was resolved down to a comment,
  /// so the caller can suppress the coarser PR-level mention for exactly those.
  ///
  /// Deliberately NOT hosted in the bot's conversation poller, which looks like
  /// the right home because it already reads every comment: that service runs
  /// on GitHub **App installation** tokens over a target set of "PRs mentioning
  /// the bot ∪ labelled ∪ having a review space", so it structurally cannot see
  /// a human mentioning the operator on a repo the app is not installed on.
  /// This service already holds the operator's own credential, the watermark,
  /// the bounded dedupe lanes and the repo→workspace routing.
  Future<Set<String>> _handleComments(
    GitHubViewerActivity activity,
    Future<List<String>> Function(String) route,
    bool silent,
  ) async {
    final fetch = _commentFetch;
    final loginResolver = _viewerLogin;
    if (fetch == null || loginResolver == null) {
      return const {};
    }
    String login;
    try {
      login = (await loginResolver()).trim();
    } on Object catch (e) {
      CcInfraLog.warning('github_activity: viewer login unavailable: $e');
      return const {};
    }
    if (login.isEmpty) {
      // No credential resolved yet. Publish nothing rather than guess: the
      // resolver re-runs every sweep, so this self-heals on sign-in.
      return const {};
    }

    // Candidates: everything GitHub already told us mentions the operator,
    // plus the PRs involving them that actually moved this sweep. The second
    // half reuses the same `repo#number|updatedAt` decision the freshness
    // nudge makes, so a quiet PR is never re-fetched.
    final candidates = <String, GitHubViewerPr>{};
    for (final pr in activity.mentioned) {
      candidates[pr.key] = pr;
    }
    for (final pr in activity.all) {
      final stamp = pr.updatedAt?.millisecondsSinceEpoch ?? 0;
      if (!_seenChanges.contains('${pr.key}|$stamp')) {
        candidates[pr.key] = pr;
      }
    }

    // Unlinked repos are dropped BEFORE any dedupe key is touched, so linking
    // the repo later still delivers rather than finding it already seen.
    final routed = <(GitHubViewerPr, List<String>)>[];
    for (final pr in candidates.values) {
      final workspaceIds = await route(pr.repoFullName);
      if (workspaceIds.isNotEmpty) {
        routed.add((pr, workspaceIds));
      }
    }
    if (routed.isEmpty) {
      return const {};
    }

    final targets = _rotatedCommentTargets(routed);
    if (routed.length > targets.length) {
      CcInfraLog.info(
        'github_activity: comment sweep capped at ${targets.length} of '
        '${routed.length} PRs; the rest rotate in next sweep',
      );
    }

    final covered = <String>{};
    for (final (pr, workspaceIds) in targets) {
      try {
        final resolved = await _sweepPrComments(
          pr,
          workspaceIds,
          login,
          fetch,
          silent: silent,
        );
        if (resolved) {
          covered.add(pr.key);
        }
      } on Object catch (e) {
        // One unreadable PR (deleted, permissions changed, transient 5xx) must
        // not take the sweep down. Not marking it covered is what lets the
        // coarse mention lane still deliver.
        CcInfraLog.warning(
          'github_activity: comment sweep failed for ${pr.key}: $e',
        );
      }
    }
    return covered;
  }

  /// The next [_maxCommentSweeps] candidates, advancing the rotating cursor so
  /// a backlog larger than the cap drains instead of starving behind one head.
  List<(GitHubViewerPr, List<String>)> _rotatedCommentTargets(
    List<(GitHubViewerPr, List<String>)> routed,
  ) {
    if (routed.length <= _maxCommentSweeps) {
      _commentCursor = 0;
      return routed;
    }
    final start = _commentCursor % routed.length;
    final picked = <(GitHubViewerPr, List<String>)>[];
    for (var i = 0; i < _maxCommentSweeps; i++) {
      picked.add(routed[(start + i) % routed.length]);
    }
    _commentCursor = (start + _maxCommentSweeps) % routed.length;
    return picked;
  }

  /// Reads one PR's comments and publishes whatever concerns the viewer.
  ///
  /// Returns whether a mention was found (and therefore the PR-level mention
  /// should be suppressed for this PR).
  Future<bool> _sweepPrComments(
    GitHubViewerPr pr,
    List<String> workspaceIds,
    String login,
    ViewerCommentFetchPort fetch, {
    required bool silent,
  }) async {
    final issueComments = await fetch.listIssueComments(
      pr.owner,
      pr.name,
      pr.number,
    );
    final reviewComments = await fetch.listReviewComments(
      pr.owner,
      pr.name,
      pr.number,
    );

    bool isViewer(String? candidate) =>
        candidate != null && candidate.toLowerCase() == login.toLowerCase();

    // Threads the viewer is in. Only fetched when they actually wrote an inline
    // comment on this PR — otherwise there is no thread of theirs to be in, and
    // the GraphQL call would be pure cost.
    final viewerWroteInline = reviewComments.any(
      (c) => isViewer(c.user?.login),
    );
    final threadMembers = viewerWroteInline
        ? threadCommentIdsAuthoredBy(
            [
              for (final c in reviewComments)
                (
                  id: c.id,
                  inReplyToId: c.inReplyToId,
                  authorLogin: c.user?.login,
                ),
            ],
            isViewer,
          )
        : const <int>{};

    final threads = viewerWroteInline
        ? await fetch.listReviewThreads(pr.owner, pr.name, pr.number)
        : const <GitHubReviewThread>[];
    final threadIdByComment = <int, String>{
      for (final t in threads)
        for (final id in t.commentIds) id: t.id,
    };

    var mentioned = false;

    Future<void> classify({
      required int id,
      required String body,
      required String? authorLogin,
      required bool isReviewComment,
      String? path,
      int? line,
    }) async {
      // Never notify someone about their own comment.
      if (isViewer(authorLogin)) {
        return;
      }
      final threadId = threadIdByComment[id];
      if (bodyMentions(body, login)) {
        mentioned = true;
        if (!_notifiedComments.add('cm:$id')) {
          return;
        }
        _dedupeDirty = true;
        if (silent) {
          return;
        }
        for (final workspaceId in workspaceIds) {
          _eventBus.publish(
            PrCommentMentioned(
              workspaceId: workspaceId,
              repoOwner: pr.owner,
              repoName: pr.name,
              prNumber: pr.number,
              prTitle: pr.title,
              commentId: id,
              authorLogin: authorLogin ?? '',
              bodyPreview: _preview(body),
              isReviewComment: isReviewComment,
              threadId: threadId,
              path: path,
              line: line,
              forUserId: _forUserId,
              occurredAt: _now(),
            ),
          );
        }
        return;
      }
      // A reply inside a thread the viewer wrote in. No mention needed —
      // having written there is the subscription.
      if (!isReviewComment || !threadMembers.contains(id)) {
        return;
      }
      if (!_notifiedComments.add('cr:$id')) {
        return;
      }
      _dedupeDirty = true;
      if (silent) {
        return;
      }
      for (final workspaceId in workspaceIds) {
        _eventBus.publish(
          PrThreadReplied(
            workspaceId: workspaceId,
            repoOwner: pr.owner,
            repoName: pr.name,
            prNumber: pr.number,
            prTitle: pr.title,
            commentId: id,
            authorLogin: authorLogin ?? '',
            bodyPreview: _preview(body),
            threadId: threadId,
            path: path,
            line: line,
            forUserId: _forUserId,
            occurredAt: _now(),
          ),
        );
      }
    }

    for (final c in issueComments) {
      await classify(
        id: c.id,
        body: c.body,
        authorLogin: c.user?.login,
        isReviewComment: false,
      );
    }
    for (final c in reviewComments) {
      await classify(
        id: c.id,
        body: c.body,
        authorLogin: c.user?.login,
        isReviewComment: true,
        path: c.path,
        line: c.line ?? c.originalLine ?? c.startLine,
      );
    }

    await _handleThreadResolutions(
      pr,
      workspaceIds,
      threads,
      threadMembers,
      reviewComments,
      silent: silent,
    );

    return mentioned;
  }

  /// The `unresolved -> resolved` edge on threads the viewer participates in.
  Future<void> _handleThreadResolutions(
    GitHubViewerPr pr,
    List<String> workspaceIds,
    List<GitHubReviewThread> threads,
    Set<int> threadMembers,
    List<GitHubReviewComment> reviewComments, {
    required bool silent,
  }) async {
    if (threads.isEmpty) {
      return;
    }
    final byId = {for (final c in reviewComments) c.id: c};
    for (final thread in threads) {
      final ours = thread.commentIds.any(threadMembers.contains);
      if (!ours) {
        continue;
      }
      if (!thread.isResolved) {
        if (_threadsUnresolved.add(thread.id)) {
          _dedupeDirty = true;
        }
        continue;
      }
      // Resolved. Only news if we were tracking it as unresolved — otherwise
      // it was already resolved when we first saw it, which is not an event.
      if (!_threadsUnresolved.remove(thread.id)) {
        continue;
      }
      _dedupeDirty = true;
      if (silent) {
        continue;
      }
      final rootId = thread.commentIds.isEmpty ? null : thread.commentIds.first;
      final root = rootId == null ? null : byId[rootId];
      for (final workspaceId in workspaceIds) {
        _eventBus.publish(
          PrThreadResolved(
            workspaceId: workspaceId,
            repoOwner: pr.owner,
            repoName: pr.name,
            prNumber: pr.number,
            prTitle: pr.title,
            threadId: thread.id,
            commentId: rootId,
            path: root?.path,
            line: root?.line ?? root?.originalLine ?? root?.startLine,
            forUserId: _forUserId,
            occurredAt: _now(),
          ),
        );
      }
    }
  }

  /// A one-line excerpt for a notification body.
  static String _preview(String body) {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= 120 ? flat : '${flat.substring(0, 119)}…';
  }

  /// A notify-once-per-PR lane (mentions, merges), keyed `repo#number|<lane>`.
  Future<void> _handleOnce(
    Iterable<GitHubViewerPr> prs,
    Future<List<String>> Function(String) route,
    bool silent,
    String lane,
    DomainEvent Function(GitHubViewerPr pr, String workspaceId) event,
  ) async {
    for (final pr in prs) {
      final workspaceIds = await route(pr.repoFullName);
      if (workspaceIds.isEmpty) {
        continue;
      }
      if (!_notified.add('${pr.key}|$lane')) {
        continue;
      }
      _dedupeDirty = true;
      if (silent) {
        continue;
      }
      for (final workspaceId in workspaceIds) {
        _eventBus.publish(event(pr, workspaceId));
      }
    }
  }

  /// Loads the persisted dedupe state exactly once (the first poll awaits it
  /// before fetching, so the baseline pass sees the watermark).
  Future<void> _ensureDedupeLoaded() => _dedupeLoad ??= _loadDedupeState()
      .whenComplete(() => _storeLoaded = true);

  Future<void> _loadDedupeState() async {
    final loader = loadDedupeState;
    if (loader == null) {
      _firstRunEver = true;
      return;
    }
    final raw = await loader();
    if (raw == null) {
      _firstRunEver = true;
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on Object catch (e) {
      CcInfraLog.warning('github_activity: dedupe state decode failed: $e');
      _firstRunEver = true;
      return;
    }
    if (decoded is! Map<String, dynamic> || decoded['v'] != _storeVersion) {
      // Includes the v1 (notification-thread-id) store: its keys cannot be
      // mapped onto PRs, so it is discarded and this run baselines silently.
      _firstRunEver = true;
      return;
    }
    _watermark = DateTime.tryParse(
      decoded['savedAt'] as String? ?? '',
    )?.toUtc();
    _persistedWatermark = _watermark;
    final prs = decoded['prs'];
    if (prs is Map<String, dynamic>) {
      for (final entry in prs.entries) {
        final flags = entry.value;
        if (flags is! Map<String, dynamic>) {
          continue;
        }
        if (flags['p'] == true) {
          _pendingReview.add(entry.key);
        }
        if (flags['m'] == true) {
          _notified.add('${entry.key}|mention');
        }
        if (flags['sc'] == true) {
          _notified.add('${entry.key}|state_change');
        }
      }
    }
    for (final key in (decoded['comments'] as List?) ?? const []) {
      if (key is String) {
        _notifiedComments.add(key);
      }
    }
    for (final id in (decoded['openThreads'] as List?) ?? const []) {
      if (id is String) {
        _threadsUnresolved.add(id);
      }
    }
  }

  Future<void> _saveDedupeState(DateTime sweepStart) async {
    final saver = saveDedupeState;
    // Never save before the store loaded: a partial in-memory state must not
    // clobber the persisted one.
    if (!_storeLoaded || saver == null) {
      return;
    }
    final mark = _persistedWatermark;
    final watermarkDue =
        mark == null || sweepStart.difference(mark) >= _watermarkRefresh;
    if (!_dedupeDirty && !watermarkDue) {
      return;
    }
    final prs = <String, Map<String, bool>>{};
    for (final key in _pendingReview.keys) {
      (prs[key] ??= <String, bool>{})['p'] = true;
    }
    for (final key in _notified.keys) {
      final sep = key.lastIndexOf('|');
      if (sep <= 0) {
        continue;
      }
      final flag = switch (key.substring(sep + 1)) {
        'mention' => 'm',
        'state_change' => 'sc',
        _ => null,
      };
      if (flag == null) {
        continue;
      }
      (prs[key.substring(0, sep)] ??= <String, bool>{})[flag] = true;
    }
    try {
      await saver(
        jsonEncode({
          'v': _storeVersion,
          // The sweep's START, never its end: anything that changed while the
          // request was in flight must fall inside the next window.
          'savedAt': sweepStart.toIso8601String(),
          'prs': prs,
          'comments': _notifiedComments.keys.toList(),
          'openThreads': _threadsUnresolved.keys.toList(),
        }),
      );
      _dedupeDirty = false;
      _watermark = sweepStart;
      _persistedWatermark = sweepStart;
    } on Object catch (e) {
      // Keep the dirty flag: the next pass retries.
      CcInfraLog.warning('github_activity: dedupe state save failed: $e');
    }
  }
}

/// A bounded FIFO key set: records keys, reports first-sight and evicts the
/// oldest entries beyond [_cap] so the dedupe memory stays flat.
class _BoundedKeySet {
  _BoundedKeySet(this._cap);

  final int _cap;
  final Queue<String> _order = Queue<String>();
  final Set<String> _set = <String>{};

  /// Records [key]; returns false when it was already present.
  bool add(String key) {
    if (!_set.add(key)) {
      return false;
    }
    _order.addLast(key);
    while (_order.length > _cap) {
      _set.remove(_order.removeFirst());
    }
    return true;
  }

  /// Drops [key]; returns whether it was present.
  bool remove(String key) {
    if (!_set.remove(key)) {
      return false;
    }
    _order.remove(key);
    return true;
  }

  /// Whether [key] was recorded.
  bool contains(String key) => _set.contains(key);

  /// The recorded keys, oldest first (for persistence).
  Iterable<String> get keys => _order;
}
