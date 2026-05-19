import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_infra/src/git/viewer_github_identity_cache.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/models/github_notification_thread.dart';
import 'package:meta/meta.dart';

/// Polls the server user's GitHub notification inbox (`GET /notifications`)
/// and turns PR-related threads into live updates:
///
///  - `review_requested` threads publish [PrReviewRequested] (→ OS/bell
///    notification on every connected client, one per linking workspace) —
///    but only when the viewer's review is *currently pending on a non-draft
///    PR*, verified against the PR's live review state (GraphQL
///    `reviewRequests` + `isDraft`, compared to the viewer's login and
///    teams). GitHub keeps a thread's `reason` at `review_requested` while
///    ANY requested reviewer is outstanding and bumps its `updatedAt` on
///    every intervening commit — including CODEOWNERS auto-requests on a
///    push to a draft, which GitHub itself withholds until the PR is marked
///    ready. The reason alone would re-announce the same request on every
///    push and on every server restart. "Pending" here is therefore the
///    *actionable* bit (`pending && !isDraft`); a draft is recorded as not
///    pending so converting it to ready later is a false→true transition.
///    The per-thread transition table:
///
///    | prev pending | now pending | result |
///    |---|---|---|
///    | false | true  | notify (genuine new/re-request / draft became ready) |
///    | true  | true  | silent (commit bump while still pending) |
///    | any   | false | silent (viewer already reviewed / still a draft) |
///    | unknown (check failed) | — | legacy: once per `id\|reason` and
///      only when this thread has never been classified |
///
///  - `mention` threads publish [PrMentioned], once per thread
///    (`id|mention`);
///  - `state_change` threads publish [ExternalPrMerged], only after the live
///    PR state verifies MERGED (closed-without-merge and reopen never
///    notify), once per thread (`id|state_change`);
///  - every PR thread on a linked repo publishes a [PrChangeSignal] and nudges
///    the open-PR poller, so the affected PR's detail streams and the list
///    refresh within seconds of the activity instead of at the next sweep.
///    This is the one lane that intentionally re-fires on every `updatedAt`
///    bump, so it keys on `id|updatedAt`.
///
/// Cost discipline: the poll presents `If-Modified-Since`, so an unchanged
/// inbox answers 304 — free against the rate limit — and the cadence honors
/// GitHub's `X-Poll-Interval` (never below [minInterval]). The first
/// successful fetch is a **baseline**: existing unread threads are recorded
/// without acting, so a server restart doesn't replay old notifications —
/// except when a persisted dedupe store (see [loadDedupeState]) hands back a
/// `savedAt` watermark: threads updated *after* it arrived while the server
/// was down and are processed (verified, deduped) exactly once at startup.
/// The dedupe state itself (`_pendingReview` + `_notified`) is persisted via
/// [saveDedupeState] after every pass that changed it, so the transition
/// semantics above survive a restart.
class GitHubNotificationPollingService {
  /// Creates a [GitHubNotificationPollingService].
  GitHubNotificationPollingService({
    required GitHubApiClient githubClient,
    required DomainEventBus eventBus,
    required PrChangeSignals changeSignals,
    required Future<List<String>> Function(String repoFullName)
    workspacesForRepo,
    void Function(String workspaceId)? onWorkspaceTouched,
    ViewerGitHubIdentityCache? identityCache,
    this.minInterval = const Duration(seconds: 60),
    this.loadDedupeState,
    this.saveDedupeState,
    DateTime Function()? now,
  }) : _client = githubClient,
       _eventBus = eventBus,
       _signals = changeSignals,
       _workspacesForRepo = workspacesForRepo,
       _onWorkspaceTouched = onWorkspaceTouched,
       _identity =
           identityCache ?? ViewerGitHubIdentityCache(githubClient.content),
       _now = now ?? DateTime.now;

  final GitHubApiClient _client;
  final DomainEventBus _eventBus;
  final PrChangeSignals _signals;
  final ViewerGitHubIdentityCache _identity;

  /// Resolves the workspace ids that link `owner/name` (empty when the repo
  /// isn't linked anywhere — those threads are ignored).
  final Future<List<String>> Function(String repoFullName) _workspacesForRepo;

  /// Optional freshness nudge (the open-PR poller's `pollSoon`).
  final void Function(String workspaceId)? _onWorkspaceTouched;

  /// Floor for the polling cadence; raised by GitHub's `X-Poll-Interval`.
  final Duration minInterval;

  /// Loads the persisted dedupe state (JSON), or null when none was saved.
  /// Absent (or null/unparseable result) = first-run-ever semantics: the
  /// baseline records every thread silently.
  final Future<String?> Function()? loadDedupeState;

  /// Persists the dedupe state after each pass that changed it.
  final Future<void> Function(String state)? saveDedupeState;

  final DateTime Function() _now;

  /// Bound on each dedupe lane's memory.
  static const _seenCap = 512;

  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  bool _baseline = true;
  String? _lastModified;

  /// Change-signal lane, keyed on `id|updatedAt`: a thread is (re)processed
  /// whenever it updates, so an active PR refreshes on every commit/comment.
  final _seenChanges = _BoundedSeen(_seenCap);

  /// Notification lane, keyed on `id|reason`: the mention and state_change
  /// dedupe lanes, plus the review-requested legacy fallback (used only when
  /// the live review-state check cannot run).
  final _notified = _BoundedSeen(_seenCap);

  /// Review-requested lane: threadId → whether the viewer's review is
  /// *actionably* pending (requested on a non-draft PR). Bounded FIFO, same
  /// cap as [_BoundedSeen]. Persisted, so the transition semantics survive a
  /// restart.
  final _pendingReview = _BoundedBoolMap(_seenCap);

  bool _storeLoaded = false;

  /// True when no store is wired, or the stored state was missing/
  /// unparseable: the baseline then records silently (legacy semantics).
  bool _firstRunEver = false;

  /// The persisted watermark: threads updated after this arrived while the
  /// server was down and are caught up once during the baseline pass.
  DateTime? _storeSavedAt;

  bool _dedupeDirty = false;
  Future<void>? _dedupeLoad;

  String? _viewerLoginCache;

  /// The viewer's teams, lower-case org → lower-case slugs.
  Map<String, Set<String>>? _viewerTeamsCache;

  /// Set after the first identity failure: identity lookups are not retried
  /// for the life of the process (the review-state lane degrades to legacy).
  bool _identityUnavailable = false;

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
    try {
      await _ensureDedupeLoaded();
      final page = await _client.content.listNotifications(
        ifModifiedSince: _lastModified,
      );
      if (!page.notModified) {
        _lastModified = page.lastModified ?? _lastModified;
        await _handleThreads(page.threads);
      }
      final requested = page.pollIntervalSeconds ?? minInterval.inSeconds;
      _schedule(Duration(seconds: math.max(minInterval.inSeconds, requested)));
    } on Object catch (e) {
      CcInfraLog.warning('github_notifications: poll failed: $e');
      // Back off to twice the floor on failure; the next success re-tightens.
      _schedule(minInterval * 2);
    }
  }

  Future<void> _handleThreads(List<GitHubNotificationThread> threads) async {
    for (final thread in threads) {
      if (thread.subjectType != 'PullRequest') {
        continue;
      }
      final changeKey =
          '${thread.id}|${thread.updatedAt?.millisecondsSinceEpoch ?? 0}';
      if (!_seenChanges.add(changeKey)) {
        continue;
      }
      if (_baseline) {
        // Catch-up: with a persisted watermark, a thread updated after it
        // arrived while the server was down — fall through and process it
        // exactly like a non-baseline thread, exactly once. Anything older
        // (or first-run-ever) is recorded silently so it never replays.
        final catchUp =
            !_firstRunEver &&
            _storeSavedAt != null &&
            thread.updatedAt != null &&
            thread.updatedAt!.isAfter(_storeSavedAt!);
        if (!catchUp) {
          // Only fill entries we don't already have.
          switch (thread.reason) {
            case 'review_requested':
              if (!_pendingReview.containsKey(thread.id)) {
                // Assume pending: suppress the first bump.
                _pendingReview[thread.id] = true;
              }
            case 'mention':
              _notified.add('${thread.id}|mention');
            case 'state_change':
              _notified.add('${thread.id}|state_change');
          }
          _dedupeDirty = true;
          continue;
        }
      }
      final prNumber = thread.pullRequestNumber;
      if (prNumber == null || thread.repoFullName.isEmpty) {
        continue;
      }
      final List<String> workspaceIds;
      try {
        workspaceIds = await _workspacesForRepo(thread.repoFullName);
      } on Object catch (e) {
        CcInfraLog.warning(
          'github_notifications: workspace resolution failed for '
          '${thread.repoFullName}: $e',
        );
        continue;
      }
      if (workspaceIds.isEmpty) {
        continue;
      }
      // The change signal fires on every update, but the notification lanes
      // gate once per thread (before the per-workspace fan-out) so every
      // linking workspace is notified together on the qualifying transition
      // and none is re-notified on a later `updatedAt` bump.
      final slash = thread.repoFullName.indexOf('/');
      final owner = slash > 0 ? thread.repoFullName.substring(0, slash) : '';
      final name = slash > 0 ? thread.repoFullName.substring(slash + 1) : '';
      var shouldNotify = false;
      switch (thread.reason) {
        case 'review_requested':
          final pending = await _reviewPendingForViewer(owner, name, prNumber);
          if (pending == null) {
            // Live state unknown. Never re-announce a thread we already
            // classified (a commit bump must not fall through to legacy
            // just because GraphQL flaked). Brand-new threads still use
            // the once-per-`id|reason` fallback.
            shouldNotify =
                !_pendingReview.containsKey(thread.id) &&
                _notified.add('${thread.id}|review_requested');
          } else {
            final prev = _pendingReview[thread.id] ?? false;
            shouldNotify = pending && !prev;
            if (_pendingReview[thread.id] != pending) {
              _dedupeDirty = true;
            }
            _pendingReview[thread.id] = pending;
          }
        case 'mention':
          shouldNotify = _notified.add('${thread.id}|mention');
        case 'state_change':
          if (!_notified.contains('${thread.id}|state_change') &&
              await _wasMerged(owner, name, prNumber)) {
            shouldNotify = true;
            _notified.add('${thread.id}|state_change');
          }
      }
      if (shouldNotify) {
        _dedupeDirty = true;
      }
      for (final workspaceId in workspaceIds) {
        _signals.notify(
          workspaceId: workspaceId,
          repoFullName: thread.repoFullName,
          prNumber: prNumber,
        );
        _onWorkspaceTouched?.call(workspaceId);
        if (!shouldNotify) {
          continue;
        }
        if (thread.reason == 'review_requested') {
          _eventBus.publish(
            PrReviewRequested(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: prNumber,
              prTitle: thread.subjectTitle,
              occurredAt: _now(),
            ),
          );
        } else if (thread.reason == 'mention') {
          _eventBus.publish(
            PrMentioned(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: prNumber,
              prTitle: thread.subjectTitle,
              occurredAt: _now(),
            ),
          );
        } else if (thread.reason == 'state_change') {
          _eventBus.publish(
            ExternalPrMerged(
              workspaceId: workspaceId,
              repoOwner: owner,
              repoName: name,
              prNumber: prNumber,
              prTitle: thread.subjectTitle,
              occurredAt: _now(),
            ),
          );
        }
      }
    }
    unawaited(_saveDedupeState());
    _baseline = false;
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
      CcInfraLog.warning(
        'github_notifications: dedupe state decode failed: $e',
      );
      _firstRunEver = true;
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      _firstRunEver = true;
      return;
    }
    _storeSavedAt = DateTime.tryParse(
      decoded['savedAt'] as String? ?? '',
    )?.toUtc();
    final threads = decoded['threads'];
    if (threads is Map<String, dynamic>) {
      for (final entry in threads.entries) {
        final flags = entry.value;
        if (flags is! Map<String, dynamic>) {
          continue;
        }
        final pending = flags['p'];
        if (pending is bool) {
          _pendingReview[entry.key] = pending;
        }
        if (flags['m'] == true) {
          _notified.add('${entry.key}|mention');
        }
        if (flags['sc'] == true) {
          _notified.add('${entry.key}|state_change');
        }
        if (flags['rr'] == true) {
          _notified.add('${entry.key}|review_requested');
        }
      }
    }
  }

  Future<void> _saveDedupeState() async {
    final saver = saveDedupeState;
    // Never save before the store loaded: a partial in-memory state must not
    // clobber the persisted one.
    if (!_storeLoaded || !_dedupeDirty || saver == null) {
      return;
    }
    final threads = <String, Map<String, bool>>{};
    for (final entry in _pendingReview.entries) {
      (threads[entry.key] ??= <String, bool>{})['p'] = entry.value;
    }
    for (final key in _notified.keys) {
      final sep = key.lastIndexOf('|');
      if (sep <= 0) {
        continue;
      }
      final flag = switch (key.substring(sep + 1)) {
        'mention' => 'm',
        'state_change' => 'sc',
        'review_requested' => 'rr',
        _ => null,
      };
      if (flag == null) {
        continue;
      }
      (threads[key.substring(0, sep)] ??= <String, bool>{})[flag] = true;
    }
    try {
      await saver(
        jsonEncode({
          'v': 1,
          'savedAt': _now().toUtc().toIso8601String(),
          'threads': threads,
        }),
      );
      _dedupeDirty = false;
    } on Object catch (e) {
      // Keep the dirty flag: the next pass retries.
      CcInfraLog.warning('github_notifications: dedupe state save failed: $e');
    }
  }

  /// Resolves (and caches) the viewer's login + teams. False = unavailable
  /// for the life of this process; the review-requested lane then degrades
  /// to the legacy once-per-`id|reason` behaviour.
  Future<bool> _ensureIdentity() async {
    if (_identityUnavailable) {
      return false;
    }
    if (_viewerLoginCache != null && _viewerTeamsCache != null) {
      return true;
    }
    final user = await _identity.user();
    final login = user?.login ?? '';
    if (login.isEmpty) {
      _identityUnavailable = true;
      CcInfraLog.warning(
        'github_notifications: viewer identity unavailable: empty viewer login',
      );
      return false;
    }
    final teams = await _identity.teams();
    if (teams == null) {
      _identityUnavailable = true;
      CcInfraLog.warning(
        'github_notifications: viewer identity unavailable: teams lookup failed',
      );
      return false;
    }
    _viewerLoginCache = login;
    _viewerTeamsCache = teams;
    return true;
  }

  /// Whether the viewer's review is *actionably* pending on this PR: requested
  /// directly or via one of their teams, **and** the PR is not a draft.
  /// Drafts return false so a later ready-for-review is a false→true
  /// transition rather than a silent true→true bump. Null = could not
  /// determine (network/identity failure) — the caller falls back to legacy
  /// once-per-`id|reason` behaviour only for unclassified threads.
  Future<bool?> _reviewPendingForViewer(
    String owner,
    String name,
    int prNumber,
  ) async {
    if (!await _ensureIdentity()) {
      return null;
    }
    try {
      final state = await _client.graphql.getPullRequestReviewState(
        owner: owner,
        repo: name,
        number: prNumber,
      );
      if (state.isDraft) {
        return false;
      }
      final login = _viewerLoginCache!.toLowerCase();
      if (state.pendingUsers.any((u) => u.login.toLowerCase() == login)) {
        return true;
      }
      final mine = _viewerTeamsCache![owner.toLowerCase()] ?? const <String>{};
      return state.pendingTeams.any((t) => mine.contains(t.slug.toLowerCase()));
    } on Object catch (e) {
      CcInfraLog.warning(
        'github_notifications: review-state check failed for '
        '$owner/$name#$prNumber: $e',
      );
      return null;
    }
  }

  /// Whether this PR is MERGED (for `state_change` threads). False on error —
  /// the miss is logged and retried on the thread's next bump.
  Future<bool> _wasMerged(String owner, String name, int prNumber) async {
    try {
      final state = await _client.graphql.getPullRequestReviewState(
        owner: owner,
        repo: name,
        number: prNumber,
      );
      return state.prState == 'MERGED';
    } on Object catch (e) {
      CcInfraLog.warning(
        'github_notifications: merge-state check failed for '
        '$owner/$name#$prNumber: $e',
      );
      return false;
    }
  }
}

/// A bounded FIFO set: records keys, reports first-sight and evicts the oldest
/// entries beyond [_cap] so the dedupe memory stays flat.
class _BoundedSeen {
  _BoundedSeen(this._cap);

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

  /// Whether [key] was recorded.
  bool contains(String key) => _set.contains(key);

  /// The recorded keys, oldest first (for persistence).
  Iterable<String> get keys => _order;
}

/// A bounded FIFO map with the same eviction semantics as [_BoundedSeen]:
/// writing an existing key moves it to the back and the oldest entries are
/// evicted beyond [_cap].
class _BoundedBoolMap {
  _BoundedBoolMap(this._cap);

  final int _cap;
  final Queue<String> _order = Queue<String>();
  final Map<String, bool> _map = <String, bool>{};

  /// The value for [key], or null when absent.
  bool? operator [](String key) => _map[key];

  /// Writes [key] → [value], moving the key to the back of the FIFO.
  void operator []=(String key, bool value) {
    if (_map.containsKey(key)) {
      _order.remove(key);
    }
    _map[key] = value;
    _order.addLast(key);
    while (_order.length > _cap) {
      _map.remove(_order.removeFirst());
    }
  }

  /// Whether [key] has a recorded value.
  bool containsKey(String key) => _map.containsKey(key);

  /// The recorded entries, oldest first (for persistence).
  Iterable<MapEntry<String, bool>> get entries => _map.entries;
}
