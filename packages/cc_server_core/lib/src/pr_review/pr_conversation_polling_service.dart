import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart'
    show splitRepoFullName;
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart'
    show BotConversationCandidates, GitHubReviewComment, GitHubViewerPr;
import 'package:cc_server_core/src/forge/github_clients.dart' show GitHubLane;
import 'package:cc_server_core/src/forge/github_rate_budget.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:meta/meta.dart';

/// A PR that has a review-space association in a workspace — the set whose
/// threads the poller follows for interactive replies.
class AssociatedPullRequest {
  /// Creates an [AssociatedPullRequest].
  const AssociatedPullRequest({
    required this.workspaceId,
    required this.repoFullName,
    required this.prNumber,
  });

  /// The workspace whose review space backs this PR.
  final String workspaceId;

  /// `owner/name`.
  final String repoFullName;

  /// PR number.
  final int prNumber;

  /// The `owner` half of [repoFullName], or empty when malformed.
  String get owner => splitRepoFullName(repoFullName)?.owner ?? '';

  /// The `name` half of [repoFullName], or empty when malformed.
  String get name => splitRepoFullName(repoFullName)?.name ?? '';
}

/// One workspace's GitHub bot, which the conversation poller fans out over.
///
/// Credentials are strictly per workspace: two workspaces on the same App
/// still search and reply through their own gateways, bounded by their own
/// accountable humans. Workspaces without a GitHub lane are omitted.
class PrConversationAppIdentity {
  /// Creates a [PrConversationAppIdentity].
  const PrConversationAppIdentity({
    required this.workspaceId,
    required this.botLogin,
    required this.lane,
    required this.gateway,
  });

  /// The workspace this bot serves. Mentions route only into it.
  final String workspaceId;

  /// The App's actual bot login (`<slug>[bot]`), for loop detection; the
  /// invocation is @usectrl.
  final String botLogin;

  /// The workspace's lane: Connect sweeps on a slower, smaller budget.
  final GitHubLane lane;

  /// Gateway bound to this workspace.
  final GitHubPrConversationGateway gateway;
}

/// Polls GitHub for bot-invoked PR conversations and hands them to the bridge.
///
/// Replaces webhooks (no inbound URL required; Connect never sees PR
/// content): one search per workspace narrowed to its installations, diff
/// comments by id, follow
/// review-thread replies for PRs with a review space. Each workspace sweeps
/// on its own budget: own App lanes every [minInterval] over at most
/// [maxCommentSweeps] PRs; Connect (the accountable human's personal quota)
/// every [connectMinInterval] over at most [connectMaxCommentSweeps]. A
/// workspace whose [GitHubRateBudget] is low is skipped until it recovers.
///
/// Eligible comment ids are persisted per workspace before bridging
/// (at-most-once; a crash loses, never double-fires), except that one whose
/// author maps to no member yet is offered again on a few later sweeps; a comment several
/// workspaces see is offered to each, and the author's 👀 claim decides.
/// The first sweep with empty state records without acting (baseline); later
/// restarts catch up. Label search is presence, not events — one fire per
/// key; re-run via @mention.
class PrConversationPollingService {
  /// Creates a [PrConversationPollingService].
  PrConversationPollingService({
    required this._listIdentities,
    required this._bridge,
    required this._workspacesForRepo,
    required this._associatedPullRequests,
    this.minInterval = const Duration(seconds: 60),
    this.connectMinInterval = const Duration(seconds: 120),
    this.idleInterval = const Duration(minutes: 5),
    this.maxCommentSweeps = 25,
    this.connectMaxCommentSweeps = 10,
    this.rateBudget,
    this.loadDedupeState,
    this.saveDedupeState,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final GitHubPrConversationSink _bridge;
  final Future<List<String>> Function(String repoFullName) _workspacesForRepo;
  final Future<List<AssociatedPullRequest>> Function() _associatedPullRequests;

  /// The workspaces to poll, each with its own bot and gateway.
  final Future<List<PrConversationAppIdentity>> Function() _listIdentities;

  /// Floor for an own App lane's cadence.
  final Duration minInterval;

  /// Floor for a Connect lane's cadence: its requests spend a person's
  /// 5,000-an-hour quota.
  final Duration connectMinInterval;

  /// Cadence while no workspace has an app identity (no bot to converse as).
  final Duration idleInterval;

  /// Upper bound on PRs whose comments are fetched per sweep on an own App
  /// lane. The sweep must stay bounded however busy the repos get; over the
  /// cap, the sweep rotates (associations first — the interactive set).
  final int maxCommentSweeps;

  /// The same bound on a Connect lane.
  final int connectMaxCommentSweeps;

  /// Rate-limit readings; a workspace whose quota is low is not swept.
  final GitHubRateBudget? rateBudget;

  /// Loads the persisted dedupe state (JSON), or null when none was saved.
  final Future<String?> Function()? loadDedupeState;

  /// Persists the dedupe state after each pass that changed it.
  final Future<void> Function(String state)? saveDedupeState;

  final DateTime Function() _now;

  /// Bound on the dedupe memory (keys, FIFO-evicted).
  static const _seenCap = 2048;

  /// The persisted-state format. v2: per-workspace keys and watermarks.
  static const _storeVersion = 2;

  /// How far back the mention lane looks beyond its watermark: GitHub's
  /// search index lags writes by seconds to a minute.
  static const _searchLagOverlap = Duration(minutes: 5);

  /// Hard cap on the mention lane's `updated:>` window.
  static const _maxLookback = Duration(hours: 24);

  final _seen = _BoundedKeySet(_seenCap);

  /// How often an invocation whose author maps to no member yet has been
  /// offered, by seen key (see [_settle]).
  final Map<String, int> _authorRetries = {};

  /// Offers per invocation whose author is not (yet) a known member.
  static const _maxAuthorRetries = 3;
  Timer? _timer;
  bool _running = false;
  bool _disposed = false;

  /// Workspaces that already had their silent first-run sweep.
  final Set<String> _baselined = {};

  /// Rotation offset per workspace for the capped comment sweep (see
  /// [_rotatedTargets]).
  final Map<String, int> _sweepCursor = {};

  /// When each workspace's last sweep started, for its lane's floor.
  final Map<String, DateTime> _lastSweepAt = {};

  bool _storeLoaded = false;
  bool _firstRunEver = false;
  bool _dedupeDirty = false;
  Future<void>? _dedupeLoad;

  /// The mention lane's watermark per workspace (the start of its last
  /// sweep that was saved).
  final Map<String, DateTime> _watermarks = {};

  /// Log-once latch for the idle condition (no app identity).
  bool _loggedIdle = false;

  /// Log-once latch for a fully-suspended GitHub App.
  bool _loggedSuspended = false;

  /// Starts the poll loop (immediate first poll). Idempotent.
  void start() {
    if (_running || _disposed) {
      return;
    }
    _running = true;
    _schedule(Duration.zero);
  }

  /// Stops the loop and the bridge's outbound listener.
  Future<void> dispose() async {
    _disposed = true;
    _running = false;
    _timer?.cancel();
    _timer = null;
    await _bridge.stop();
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
    final List<PrConversationAppIdentity> identities;
    try {
      identities = await _listIdentities();
    } on Object catch (e) {
      CcHostLog.warning('pr_conversation: listing workspaces failed: $e');
      _schedule(minInterval * 2);
      return;
    }
    await _pollIdentities(identities);
  }

  Duration _floorFor(GitHubLane lane) =>
      lane == GitHubLane.connect ? connectMinInterval : minInterval;

  int _capFor(GitHubLane lane) =>
      lane == GitHubLane.connect ? connectMaxCommentSweeps : maxCommentSweeps;

  Future<void> _pollIdentities(
    List<PrConversationAppIdentity> identities,
  ) async {
    var anyBot = false;
    var anyLive = false;
    Duration? nextDelay;
    for (final identity in identities) {
      if (identity.botLogin.isEmpty) {
        continue;
      }
      anyBot = true;
      if (await identity.gateway.allInstallationsSuspended()) {
        continue;
      }
      anyLive = true;
      final workspaceId = identity.workspaceId;
      final floor = _floorFor(identity.lane);
      if (nextDelay == null || floor < nextDelay) {
        nextDelay = floor;
      }
      final now = _now();
      final last = _lastSweepAt[workspaceId];
      if (last != null && now.difference(last) < floor) {
        continue;
      }
      if (rateBudget?.backsOff(workspaceId, poller: 'pr_conversation') ??
          false) {
        continue;
      }
      _lastSweepAt[workspaceId] = now;
      try {
        await _ensureDedupeLoaded();
        final sweepStart = now.toUtc();
        final results = await identity.gateway.searchCandidates(
          since: _windowStart(workspaceId, sweepStart),
        );
        await _handleSweep(identity, results, sweepStart);
      } on Object catch (e) {
        CcHostLog.warning(
          'pr_conversation: poll failed for @${identity.botLogin} in '
          '$workspaceId: $e',
        );
      }
    }
    if (!anyBot) {
      _idleNoBot();
      return;
    }
    if (!anyLive) {
      _idleSuspended();
      return;
    }
    _loggedIdle = false;
    _loggedSuspended = false;
    _schedule(nextDelay ?? minInterval);
  }

  void _idleNoBot() {
    if (!_loggedIdle) {
      _loggedIdle = true;
      CcHostLog.info(
        'pr_conversation: idle — no workspace has a GitHub App identity, so '
        'there is no bot login to converse with. Re-checking every '
        '${idleInterval.inMinutes}m.',
      );
    }
    _schedule(idleInterval);
  }

  void _idleSuspended() {
    if (!_loggedSuspended) {
      _loggedSuspended = true;
      CcHostLog.info(
        'pr_conversation: idle — GitHub App installation(s) suspended. '
        'Resume the installation on GitHub. Re-checking every '
        '${idleInterval.inMinutes}m.',
      );
    }
    _schedule(idleInterval);
  }

  /// The `updated:>` anchor for [workspaceId]'s mention lane: its watermark
  /// less the index-lag overlap, clamped. Null (the gateway's own default
  /// window) before its first save.
  DateTime? _windowStart(String workspaceId, DateTime sweepStart) {
    final mark = _watermarks[workspaceId];
    if (mark == null) {
      return null;
    }
    final floor = sweepStart.subtract(_maxLookback);
    final start = mark.subtract(_searchLagOverlap);
    return start.isBefore(floor) ? floor : start;
  }

  Future<void> _handleSweep(
    PrConversationAppIdentity identity,
    BotConversationCandidates results,
    DateTime sweepStart,
  ) async {
    final workspaceId = identity.workspaceId;
    final gateway = identity.gateway;
    final silent = _firstRunEver && !_baselined.contains(workspaceId);
    final suspended = {
      for (final owner in await gateway.suspendedOwners()) owner.toLowerCase(),
    };

    // Every target is a PR of this workspace. The association set comes
    // first (the live conversations); search hits join when the workspace
    // links the repo, unless the PR's review space lives in another
    // workspace — a conversation continues where it already is.
    final targets = <String, _SweepTarget>{};
    final associatedElsewhere = <String>{};
    for (final associated in await _associatedPullRequests()) {
      if (associated.workspaceId != workspaceId) {
        associatedElsewhere.add(
          _prKey(associated.repoFullName, associated.prNumber),
        );
        continue;
      }
      if (associated.owner.isEmpty ||
          associated.name.isEmpty ||
          suspended.contains(associated.owner.toLowerCase())) {
        continue;
      }
      targets[_prKey(
        associated.repoFullName,
        associated.prNumber,
      )] = _SweepTarget(
        owner: associated.owner,
        repo: associated.name,
        prNumber: associated.prNumber,
        prTitle: '',
      );
    }

    Future<void> addCandidates(List<GitHubViewerPr> prs) async {
      for (final pr in prs) {
        final key = _prKey(pr.repoFullName, pr.number);
        if (targets.containsKey(key) ||
            associatedElsewhere.contains(key) ||
            suspended.contains(pr.owner.toLowerCase())) {
          continue;
        }
        var linked = false;
        try {
          linked = (await _workspacesForRepo(
            pr.repoFullName,
          )).contains(workspaceId);
        } on Object catch (e) {
          CcHostLog.warning(
            'pr_conversation: workspace resolution failed for '
            '${pr.repoFullName}: $e',
          );
        }
        if (!linked) {
          // Unlinked: skip BEFORE recording anything, so linking the repo
          // later still delivers the label/mention rather than finding it
          // already marked seen.
          continue;
        }
        targets[key] = _SweepTarget(
          owner: pr.owner,
          repo: pr.name,
          prNumber: pr.number,
          prTitle: pr.title,
        );
      }
    }

    // The mention and label lanes funnel into the same candidate set; a PR
    // hit by both is deduplicated.
    await addCandidates(results.mentioned);
    await addCandidates(results.labeled);

    // The label lane: presence-triggered, once per PR per workspace.
    for (final pr in results.labeled) {
      final target = targets[_prKey(pr.repoFullName, pr.number)];
      if (target == null) {
        continue;
      }
      final seenKey = 'lb:$workspaceId:${pr.key}';
      if (!_seen.add(seenKey)) {
        continue;
      }
      _dedupeDirty = true;
      if (silent) {
        continue;
      }
      try {
        _settle(
          seenKey,
          await _bridge.handleLabeledPullRequest(
            workspaceId: workspaceId,
            owner: target.owner,
            repo: target.repo,
            prNumber: target.prNumber,
          ),
        );
      } on Object catch (e) {
        CcHostLog.warning(
          'pr_conversation: label trigger failed for ${pr.key}: $e',
        );
      }
    }

    // The comment lane: mentions anywhere, thread replies on associated PRs.
    //
    // Over the cap, the sweep ROTATES rather than always truncating the tail:
    // insertion order puts associations first (the live conversations), so a
    // fixed cut would starve the same tail PRs on every sweep. The cursor
    // advances by the cap each pass, guaranteeing eventual coverage.
    final cap = _capFor(identity.lane);
    final ordered = _rotatedTargets(
      workspaceId,
      targets.values.toList(growable: false),
      cap,
    );
    var swept = 0;
    for (final target in ordered) {
      if (swept >= cap) {
        CcHostLog.warning(
          'pr_conversation: capped at $cap PRs this sweep in $workspaceId; '
          'remaining PRs are retried next sweep.',
        );
        break;
      }
      swept++;
      try {
        await _sweepPullRequestComments(identity, target, silent: silent);
      } on Object catch (e) {
        CcHostLog.warning(
          'pr_conversation: comment sweep failed for '
          '${target.owner}/${target.repo}#${target.prNumber}: $e',
        );
      }
    }

    _baselined.add(workspaceId);
    await _saveDedupeState(workspaceId, sweepStart);
  }

  static String _prKey(String repoFullName, int number) =>
      '${repoFullName.toLowerCase()}#$number';

  /// Orders the comment-sweep targets starting at [workspaceId]'s rotating
  /// cursor and advances the cursor by [cap], so a capped sweep covers a
  /// different slice each pass.
  List<_SweepTarget> _rotatedTargets(
    String workspaceId,
    List<_SweepTarget> targets,
    int cap,
  ) {
    if (targets.length <= cap) {
      // The cap cannot bite; no rotation needed (keeps association priority).
      return targets;
    }
    final cursor = (_sweepCursor[workspaceId] ?? 0) % targets.length;
    _sweepCursor[workspaceId] = (cursor + cap) % targets.length;
    return [...targets.sublist(cursor), ...targets.sublist(0, cursor)];
  }

  Future<void> _sweepPullRequestComments(
    PrConversationAppIdentity identity,
    _SweepTarget target, {
    required bool silent,
  }) async {
    final workspaceId = identity.workspaceId;
    final botLogin = identity.botLogin;
    final gateway = identity.gateway;
    final issueComments = await gateway.listIssueComments(
      target.owner,
      target.repo,
      target.prNumber,
    );
    final reviewComments = await gateway.listReviewComments(
      target.owner,
      target.repo,
      target.prNumber,
    );

    final botThreadMembers = botThreadCommentIds(reviewComments, botLogin);

    for (final comment in issueComments) {
      if (_isBot(comment.user?.login, botLogin) ||
          GitHubPrConversationBridge.isAutomatedReply(comment.body)) {
        continue;
      }
      final seenKey = 'ic:$workspaceId:${comment.id}';
      if (_seen.contains(seenKey)) {
        continue;
      }
      final mentions = GitHubPrConversationBridge.mentionsBot(
        comment.body,
        botLogin,
      );
      if (!mentions) {
        // Not addressed to us and not in a thread (issue comments have no
        // reply threads): other people's conversation. Not recorded as seen
        // either, so a later edit that adds a mention still fires.
        continue;
      }
      _seen.add(seenKey);
      _dedupeDirty = true;
      if (silent) {
        continue;
      }
      _settle(
        seenKey,
        await _bridge.handleInboundComment(
          workspaceId: workspaceId,
          owner: target.owner,
          repo: target.repo,
          prNumber: target.prNumber,
          prTitle: target.prTitle,
          comment: InboundGitHubPrComment(
            id: comment.id,
            body: comment.body,
            authorId: comment.user?.id ?? 0,
            authorLogin: comment.user?.login ?? '',
            isReviewComment: false,
          ),
        ),
      );
    }

    for (final comment in reviewComments) {
      if (_isBot(comment.user?.login, botLogin) ||
          GitHubPrConversationBridge.isAutomatedReply(comment.body)) {
        continue;
      }
      final seenKey = 'rc:$workspaceId:${comment.id}';
      if (_seen.contains(seenKey)) {
        continue;
      }
      final mentions = GitHubPrConversationBridge.mentionsBot(
        comment.body,
        botLogin,
      );
      final inBotThread = botThreadMembers.contains(comment.id);
      if (!mentions && !inBotThread) {
        continue;
      }
      _seen.add(seenKey);
      _dedupeDirty = true;
      if (silent) {
        continue;
      }
      _settle(
        seenKey,
        await _bridge.handleInboundComment(
          workspaceId: workspaceId,
          owner: target.owner,
          repo: target.repo,
          prNumber: target.prNumber,
          prTitle: target.prTitle,
          comment: InboundGitHubPrComment(
            id: comment.id,
            body: comment.body,
            authorId: comment.user?.id ?? 0,
            authorLogin: comment.user?.login ?? '',
            isReviewComment: true,
          ),
          isBotThread: inBotThread,
        ),
      );
    }
  }

  /// Records what the bridge did with the invocation under [seenKey]. An
  /// author no member is signed in as yet is offered again on the next
  /// sweeps (their sign-in may simply not have been seen), at most
  /// [_maxAuthorRetries] times; then the key stays seen for good.
  void _settle(String seenKey, GitHubInboundOutcome outcome) {
    if (outcome != GitHubInboundOutcome.authorUnknown) {
      _authorRetries.remove(seenKey);
      return;
    }
    final tries = (_authorRetries[seenKey] ?? 0) + 1;
    if (tries > _maxAuthorRetries) {
      _authorRetries.remove(seenKey);
      return;
    }
    _authorRetries[seenKey] = tries;
    _seen.remove(seenKey);
    _dedupeDirty = true;
  }

  /// The ids of review comments that belong to a thread our bot participates
  /// in — the interactive-follow-up set. A comment qualifies when any comment
  /// in its reply chain (itself included) was authored by the bot, or is one
  /// of our attributed replies (authored by the asking person on the Connect
  /// and user-token lanes).
  @visibleForTesting
  static Set<int> botThreadCommentIds(
    List<GitHubReviewComment> comments,
    String botLogin,
  ) => threadCommentIdsAuthoredBy(
    [
      for (final c in comments)
        (
          id: c.id,
          inReplyToId: c.inReplyToId,
          authorLogin: GitHubPrConversationBridge.isAutomatedReply(c.body)
              ? botLogin
              : c.user?.login,
        ),
    ],
    // Deliberately NOT an exact-login test, unlike the viewer lane: the broad
    // `[bot]` half is this lane's loop guard against OTHER bots' comments
    // invoking ours. Passing the predicate rather than a login is what lets
    // one walk serve both meanings.
    (login) => _isBot(login, botLogin),
  );

  /// Whether [login] is a bot account: ours specifically (the exact match) or
  /// any GitHub app bot (the `[bot]` suffix every app account carries). The
  /// broad half is the loop guard against OTHER bots' comments invoking ours.
  static bool _isBot(String? login, String botLogin) {
    if (login == null || login.isEmpty) {
      return false;
    }
    return login.toLowerCase() == botLogin.toLowerCase() ||
        login.endsWith('[bot]');
  }

  Future<void> _ensureDedupeLoaded() =>
      _dedupeLoad ??= _loadDedupeState().whenComplete(() {
        _storeLoaded = true;
      });

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
      CcHostLog.warning('pr_conversation: dedupe state decode failed: $e');
      _firstRunEver = true;
      return;
    }
    if (decoded is! Map<String, dynamic> || decoded['v'] != _storeVersion) {
      _firstRunEver = true;
      return;
    }
    final watermarks = decoded['watermarks'];
    if (watermarks is Map) {
      for (final MapEntry(:key, :value) in watermarks.entries) {
        final at = value is String ? DateTime.tryParse(value)?.toUtc() : null;
        if (key is String && at != null) {
          _watermarks[key] = at;
        }
      }
    }
    final seen = decoded['seen'];
    if (seen is List) {
      seen.whereType<String>().forEach(_seen.add);
    }
  }

  Future<void> _saveDedupeState(String workspaceId, DateTime sweepStart) async {
    final saver = saveDedupeState;
    if (!_storeLoaded || saver == null || !_dedupeDirty) {
      return;
    }
    // The sweep's START, never its end: anything that changed while the
    // requests were in flight must fall inside the next window.
    final watermarks = {..._watermarks, workspaceId: sweepStart};
    try {
      await saver(
        jsonEncode({
          'v': _storeVersion,
          'watermarks': {
            for (final MapEntry(:key, :value) in watermarks.entries)
              key: value.toIso8601String(),
          },
          'seen': _seen.keys.toList(growable: false),
        }),
      );
      _dedupeDirty = false;
      _watermarks[workspaceId] = sweepStart;
    } on Object catch (e) {
      // Keep the dirty flag: the next pass retries.
      CcHostLog.warning('pr_conversation: dedupe state save failed: $e');
    }
  }
}

/// One PR of the swept workspace this sweep will act on.
class _SweepTarget {
  _SweepTarget({
    required this.owner,
    required this.repo,
    required this.prNumber,
    required this.prTitle,
  });

  final String owner;
  final String repo;
  final int prNumber;
  final String prTitle;
}

/// A bounded FIFO key set: records keys and evicts the oldest beyond the cap
/// so the dedupe memory stays flat. (Same shape as the viewer-activity
/// poller's, which is private to that file.)
class _BoundedKeySet {
  _BoundedKeySet(int cap) : _cap = cap;

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

  /// Forgets [key], so it can be recorded again.
  void remove(String key) {
    if (_set.remove(key)) {
      _order.remove(key);
    }
  }

  /// Whether [key] was recorded.
  bool contains(String key) => _set.contains(key);

  /// The recorded keys, oldest first (for persistence).
  Iterable<String> get keys => _order;
}
