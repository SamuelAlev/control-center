import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart'
    show GitHubReviewComment, GitHubViewerPr;
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
  String get owner {
    final parts = repoFullName.split('/');
    return parts.length == 2 ? parts[0] : '';
  }

  /// The `name` half of [repoFullName], or empty when malformed.
  String get name {
    final parts = repoFullName.split('/');
    return parts.length == 2 ? parts[1] : '';
  }
}

/// Discovers, by polling, the GitHub PR conversations the server's bot is
/// being invoked on, and hands each one to the bridge.
///
/// GitHub's only push channel for a GitHub App is a webhook, which needs an
/// inbound URL this server deliberately does not require (it may run behind
/// NAT with no tunnel). Everything a webhook would deliver is also readable,
/// so this sweep IS the transport: one aliased search per installation finds
/// PRs mentioning the bot or carrying the review label, comment lists are
/// diffed by comment id, and review-thread replies are followed for PRs that
/// already have a review space. The cost is latency (one sweep interval) and
/// a bounded request budget, not reachability.
///
/// ## Exactly-once
///
/// Comment ids are unique across GitHub and are recorded (persisted, bounded,
/// FIFO-evicted) the moment a comment is classified as eligible, BEFORE the
/// bridge acts — a handler crash cannot double-fire it, and the worst case is
/// a lost comment, the same at-most-once trade every lane here makes.
///
/// ## The baseline pass
///
/// With no persisted state, the first sweep records everything currently
/// outstanding without acting: an operator who labeled twenty PRs before this
/// server ever ran must not come back to twenty running reviews. With state,
/// a restart catches up and delivers exactly what arrived while it was down.
///
/// ## The label lane is a set, not a stream
///
/// Search reports label PRESENCE, not label events, so a labeled PR triggers
/// once — ever, per persisted key. Removing and re-adding the label does not
/// re-fire (the sweep cannot see the removal); an @mention is the re-run path.
/// This mirrors the pending-review lane of the viewer-activity sweep, where
/// membership in the result set is itself the state.
class PrConversationPollingService {
  /// Creates a [PrConversationPollingService].
  PrConversationPollingService({
    required GitHubPrConversationGateway gateway,
    required GitHubPrConversationSink bridge,
    required Future<List<String>> Function(String repoFullName)
    workspacesForRepo,
    required Future<List<AssociatedPullRequest>> Function()
    associatedPullRequests,
    this.minInterval = const Duration(seconds: 60),
    this.idleInterval = const Duration(minutes: 5),
    this.maxCommentSweeps = 25,
    this.loadDedupeState,
    this.saveDedupeState,
    DateTime Function()? now,
  }) : _gateway = gateway,
       _bridge = bridge,
       _workspacesForRepo = workspacesForRepo,
       _associatedPullRequests = associatedPullRequests,
       _now = now ?? DateTime.now;

  final GitHubPrConversationGateway _gateway;
  final GitHubPrConversationSink _bridge;
  final Future<List<String>> Function(String repoFullName) _workspacesForRepo;
  final Future<List<AssociatedPullRequest>> Function()
  _associatedPullRequests;

  /// Floor for the polling cadence.
  final Duration minInterval;

  /// Cadence while the server has no app identity (no bot to converse as).
  final Duration idleInterval;

  /// Upper bound on PRs whose comments are fetched per sweep. The sweep must
  /// stay bounded however busy the repos get; over the cap, PRs are skipped
  /// this sweep (mentions first, then associations — the interactive set).
  final int maxCommentSweeps;

  /// Loads the persisted dedupe state (JSON), or null when none was saved.
  final Future<String?> Function()? loadDedupeState;

  /// Persists the dedupe state after each pass that changed it.
  final Future<void> Function(String state)? saveDedupeState;

  final DateTime Function() _now;

  /// Bound on the dedupe memory (keys, FIFO-evicted).
  static const _seenCap = 1024;

  /// The persisted-state format.
  static const _storeVersion = 1;

  /// How far back the mention lane looks beyond its watermark: GitHub's
  /// search index lags writes by seconds to a minute.
  static const _searchLagOverlap = Duration(minutes: 5);

  /// Hard cap on the mention lane's `updated:>` window.
  static const _maxLookback = Duration(hours: 24);

  final _seen = _BoundedKeySet(_seenCap);
  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  bool _baseline = true;

  /// Rotation offset for the capped comment sweep (see [_rotatedTargets]).
  int _sweepCursor = 0;
  bool _storeLoaded = false;
  bool _firstRunEver = false;
  bool _dedupeDirty = false;
  Future<void>? _dedupeLoad;
  DateTime? _watermark;

  /// Log-once latch for the idle condition (no app identity).
  bool _loggedIdle = false;

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
    final botLogin = await _gateway.botLogin();
    if (botLogin.isEmpty) {
      // No app identity: there is no bot login to mention and no bot account
      // our comments would come from. Re-check at the idle cadence so an app
      // configured later lights this up without a restart.
      if (!_loggedIdle) {
        _loggedIdle = true;
        CcHostLog.info(
          'pr_conversation: idle — no GitHub App identity, so there is no bot '
          'login to converse with. Re-checking every '
          '${idleInterval.inMinutes}m.',
        );
      }
      _schedule(idleInterval);
      return;
    }
    _loggedIdle = false;
    try {
      await _ensureDedupeLoaded();
      final sweepStart = _now().toUtc();
      final results = await _gateway.searchCandidates(
        since: _windowStart(sweepStart),
      );
      await _handleSweep(botLogin, results, sweepStart);
      _schedule(minInterval);
    } on Object catch (e) {
      CcHostLog.warning('pr_conversation: poll failed: $e');
      _schedule(minInterval * 2);
    }
  }

  /// The `updated:>` anchor for the mention lane: the watermark less the
  /// index-lag overlap, clamped. Null (the gateway's own default window)
  /// before the first save.
  DateTime? _windowStart(DateTime sweepStart) {
    final mark = _watermark;
    if (mark == null) {
      return null;
    }
    final floor = sweepStart.subtract(_maxLookback);
    final start = mark.subtract(_searchLagOverlap);
    return start.isBefore(floor) ? floor : start;
  }

  Future<void> _handleSweep(
    String botLogin,
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> shortMentioned,
      List<GitHubViewerPr> labeled,
    }) results,
    DateTime sweepStart,
  ) async {
    final silent = _baseline && _firstRunEver;

    // Route every search hit to the workspace that links its repo. The
    // association set wins over search routing for the same PR: a
    // conversation that already has a space continues in that space's
    // workspace, not in whichever workspace sorts first today.
    final targets = <String, _SweepTarget>{};
    for (final associated in await _associatedPullRequests()) {
      if (associated.owner.isEmpty || associated.name.isEmpty) {
        continue;
      }
      targets[associated.repoFullName.toLowerCase()] = _SweepTarget(
        owner: associated.owner,
        repo: associated.name,
        prNumber: associated.prNumber,
        prTitle: '',
        workspaceId: associated.workspaceId,
      );
    }

    Future<void> addCandidates(List<GitHubViewerPr> prs) async {
      for (final pr in prs) {
        final key = pr.repoFullName.toLowerCase();
        if (targets.containsKey(key)) {
          continue;
        }
        var workspaceIds = const <String>[];
        try {
          workspaceIds = await _workspacesForRepo(pr.repoFullName);
        } on Object catch (e) {
          CcHostLog.warning(
            'pr_conversation: workspace resolution failed for '
            '${pr.repoFullName}: $e',
          );
        }
        if (workspaceIds.isEmpty) {
          // Unlinked: skip BEFORE recording anything, so linking the repo
          // later still delivers the label/mention rather than finding it
          // already marked seen.
          continue;
        }
        final sorted = [...workspaceIds]..sort();
        targets[key] = _SweepTarget(
          owner: pr.owner,
          repo: pr.name,
          prNumber: pr.number,
          prTitle: pr.title,
          workspaceId: sorted.first,
        );
      }
    }

    // Both mention lanes (full login + bare slug) funnel into the same
    // candidate set; the targets map dedupes a PR hit by both.
    await addCandidates(results.mentioned);
    await addCandidates(results.shortMentioned);
    await addCandidates(results.labeled);

    // The label lane: presence-triggered, once per PR.
    for (final pr in results.labeled) {
      final target = targets[pr.repoFullName.toLowerCase()];
      if (target == null) {
        continue;
      }
      final key = 'lb:${pr.key}';
      if (!_seen.add(key)) {
        continue;
      }
      _dedupeDirty = true;
      if (silent) {
        continue;
      }
      try {
        await _bridge.handleLabeledPullRequest(
          workspaceId: target.workspaceId,
          owner: target.owner,
          repo: target.repo,
          prNumber: target.prNumber,
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
    final ordered = _rotatedTargets(targets.values.toList(growable: false));
    var swept = 0;
    for (final target in ordered) {
      if (swept >= maxCommentSweeps) {
        CcHostLog.warning(
          'pr_conversation: capped at $maxCommentSweeps PRs this sweep; '
          'remaining PRs are retried next sweep.',
        );
        break;
      }
      swept++;
      try {
        await _sweepPullRequestComments(botLogin, target);
      } on Object catch (e) {
        CcHostLog.warning(
          'pr_conversation: comment sweep failed for '
          '${target.owner}/${target.repo}#${target.prNumber}: $e',
        );
      }
    }

    _baseline = false;
    await _saveDedupeState(sweepStart);
  }

  /// Orders the comment-sweep targets starting at the rotating cursor and
  /// advances the cursor by the sweep cap, so a capped sweep covers a
  /// different slice each pass.
  List<_SweepTarget> _rotatedTargets(List<_SweepTarget> targets) {
    if (targets.length <= maxCommentSweeps) {
      // The cap cannot bite; no rotation needed (keeps association priority).
      return targets;
    }
    final cursor = _sweepCursor % targets.length;
    _sweepCursor = (_sweepCursor + maxCommentSweeps) % targets.length;
    return [
      ...targets.sublist(cursor),
      ...targets.sublist(0, cursor),
    ];
  }

  Future<void> _sweepPullRequestComments(
    String botLogin,
    _SweepTarget target,
  ) async {
    final issueComments = await _gateway.listIssueComments(
      target.owner,
      target.repo,
      target.prNumber,
    );
    final reviewComments = await _gateway.listReviewComments(
      target.owner,
      target.repo,
      target.prNumber,
    );

    final botThreadMembers = botThreadCommentIds(reviewComments, botLogin);

    for (final comment in issueComments) {
      if (_isBot(comment.user?.login, botLogin)) {
        continue;
      }
      final seenKey = 'c:${comment.id}';
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
      if (_baseline && _firstRunEver) {
        continue;
      }
      await _bridge.handleInboundComment(
        workspaceId: target.workspaceId,
        owner: target.owner,
        repo: target.repo,
        prNumber: target.prNumber,
        prTitle: target.prTitle,
        comment: InboundGitHubPrComment(
          id: comment.id,
          body: comment.body,
          authorLogin: comment.user?.login ?? '',
          authorIsBot: _isBot(comment.user?.login, botLogin),
          isReviewComment: false,
        ),
      );
    }

    for (final comment in reviewComments) {
      if (_isBot(comment.user?.login, botLogin)) {
        continue;
      }
      final seenKey = 'c:${comment.id}';
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
      if (_baseline && _firstRunEver) {
        continue;
      }
      await _bridge.handleInboundComment(
        workspaceId: target.workspaceId,
        owner: target.owner,
        repo: target.repo,
        prNumber: target.prNumber,
        prTitle: target.prTitle,
        comment: InboundGitHubPrComment(
          id: comment.id,
          body: comment.body,
          authorLogin: comment.user?.login ?? '',
          authorIsBot: _isBot(comment.user?.login, botLogin),
          isReviewComment: true,
        ),
        isBotThread: inBotThread,
      );
    }
  }

  /// The ids of review comments that belong to a thread our bot participates
  /// in — the interactive-follow-up set. A comment qualifies when any comment
  /// in its reply chain (itself included) was authored by the bot.
  @visibleForTesting
  static Set<int> botThreadCommentIds(
    List<GitHubReviewComment> comments,
    String botLogin,
  ) => threadCommentIdsAuthoredBy(
    [
      for (final c in comments)
        (id: c.id, inReplyToId: c.inReplyToId, authorLogin: c.user?.login),
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
    _watermark = DateTime.tryParse(
      decoded['savedAt'] as String? ?? '',
    )?.toUtc();
    final seen = decoded['seen'];
    if (seen is List) {
      for (final key in seen) {
        if (key is String) {
          _seen.add(key);
        }
      }
    }
  }

  Future<void> _saveDedupeState(DateTime sweepStart) async {
    final saver = saveDedupeState;
    if (!_storeLoaded || saver == null || !_dedupeDirty) {
      return;
    }
    try {
      await saver(
        jsonEncode({
          'v': _storeVersion,
          // The sweep's START, never its end: anything that changed while the
          // requests were in flight must fall inside the next window.
          'savedAt': sweepStart.toIso8601String(),
          'seen': _seen.keys.toList(growable: false),
        }),
      );
      _dedupeDirty = false;
      _watermark = sweepStart;
    } on Object catch (e) {
      // Keep the dirty flag: the next pass retries.
      CcHostLog.warning('pr_conversation: dedupe state save failed: $e');
    }
  }
}

/// One PR this sweep will act on, with the workspace that owns the
/// conversation.
class _SweepTarget {
  _SweepTarget({
    required this.owner,
    required this.repo,
    required this.prNumber,
    required this.prTitle,
    required this.workspaceId,
  });

  final String owner;
  final String repo;
  final int prNumber;
  final String prTitle;
  final String workspaceId;
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

  /// Whether [key] was recorded.
  bool contains(String key) => _set.contains(key);

  /// The recorded keys, oldest first (for persistence).
  Iterable<String> get keys => _order;
}
