import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart'
    show MessageType, SenderType;
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart'
    as mention;
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:meta/meta.dart';

/// Starts the AI review pipeline for one pull request. The runtime's
/// `startPrReview` seam: idempotent, duplicate-guarded (`already_running`),
/// and it creates + provisions the PR's review space itself.
typedef StartAiReview =
    Future<Map<String, dynamic>> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
    });

/// Ensures a PR has its backing review space (checking the worktree out at
/// the PR head) and returns the space id, or null when it cannot. The
/// runtime's `ensureReviewSpaceFn` seam — the one implementation every PR
/// surface resolves the room through.
typedef EnsurePrReviewSpace =
    Future<String?> Function({
      required String workspaceId,
      required String repoFullName,
      required int prNumber,
      required String title,
    });

/// Resolves the agent that answers a question in a workspace that has no
/// review running yet (a fresh PR space holds an empty roster). The runtime
/// answers with the seeded coordinator agent.
typedef DefaultAnswererResolver = Future<String?> Function(String workspaceId);

/// What an inbound bot invocation asks for, once the mention is stripped.
enum GitHubBotCommand {
  /// Run the AI review pipeline for the PR.
  review,

  /// Answer a question in the PR's review space.
  question,
}

/// One inbound GitHub PR comment, normalized across the two comment lanes
/// (conversation timeline vs inline review thread) so the bridge handles
/// them identically.
class InboundGitHubPrComment {
  /// Creates an [InboundGitHubPrComment].
  const InboundGitHubPrComment({
    required this.id,
    required this.body,
    required this.authorLogin,
    required this.authorIsBot,
    required this.isReviewComment,
  });

  /// GitHub comment id (numeric, unique across both lanes).
  final int id;

  /// Raw markdown body.
  final String body;

  /// Author's login (`appslug[bot]` for app accounts).
  final String authorLogin;

  /// Whether the author is a bot account — ours or anyone else's.
  final bool authorIsBot;

  /// Whether this is an inline review comment (diff thread) rather than a
  /// conversation-timeline comment. Picks the lane replies post into.
  final bool isReviewComment;
}

/// The poller's view of the bridge: exactly the entry points discovery can
/// reach, plus the lifecycle of the outbound listener it owns. An interface
/// so the polling sweep is testable against a recording sink instead of the
/// whole bridge's dependency graph.
abstract interface class GitHubPrConversationSink {
  /// Handles one eligible inbound comment (see
  /// [GitHubPrConversationBridge.handleInboundComment]).
  Future<void> handleInboundComment({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String prTitle,
    required InboundGitHubPrComment comment,
    bool isBotThread,
  });

  /// Handles a PR carrying the review label (see
  /// [GitHubPrConversationBridge.handleLabeledPullRequest]).
  Future<void> handleLabeledPullRequest({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  });

  /// Stops the bridge's outbound listener (see
  /// [GitHubPrConversationBridge.stop]).
  Future<void> stop();
}

/// A pending outbound reply, recorded against the agent run it answers and
/// consumed when that run completes.
class _PendingReply {
  _PendingReply({
    required this.owner,
    required this.repo,
    required this.prNumber,
    required this.askerLogin,
    required this.isReviewThread,
    this.parentCommentId,
  });

  factory _PendingReply.fromJson(Map<String, dynamic> json) => _PendingReply(
    owner: json['owner'] as String? ?? '',
    repo: json['repo'] as String? ?? '',
    prNumber: (json['pr_number'] as num?)?.toInt() ?? 0,
    askerLogin: json['asker_login'] as String? ?? '',
    isReviewThread: json['kind'] == 'review',
    parentCommentId: (json['parent_comment_id'] as num?)?.toInt(),
  );

  final String owner;
  final String repo;
  final int prNumber;
  final String askerLogin;
  final bool isReviewThread;
  final int? parentCommentId;

  Map<String, dynamic> toJson() => {
    'v': 1,
    'owner': owner,
    'repo': repo,
    'pr_number': prNumber,
    'asker_login': askerLogin,
    'kind': isReviewThread ? 'review' : 'issue',
    if (parentCommentId != null) 'parent_comment_id': parentCommentId,
  };
}

/// Bridges GitHub PR conversations into Control Center's PR review spaces and
/// back.
///
/// A PR comment that @mentions the server's GitHub App bot (or replies inside
/// a thread the bot is part of) becomes a real turn in that PR's review
/// space, attributed to the member whose GitHub connection the author maps
/// to; the answering agent's completed turn is posted back on GitHub in the
/// lane it was asked in. A bare mention or `review` starts the AI review
/// pipeline instead.
///
/// ## The gates, in order
///
/// 1. **Loop guard** — anything authored by a bot account is dropped before
///    any other gate runs. Without it the bot's own answers would arrive as
///    new comments and re-trigger it forever.
/// 2. **Ack** — a 👀 reaction tells the human the comment was seen before any
///    slower work (space provisioning can take two minutes) produces output.
///    Best-effort: a failed reaction never blocks handling.
/// 3. **Membership** — a GitHub login is an unauthenticated external identity
///    until it maps to a writing member of the workspace whose repo was
///    addressed. Unmapped or read-only authors are told so, once, and their
///    words never enter the workspace.
///
/// ## Attribution
///
/// GitHub-side writes carry the SERVER's identity (the app) — nobody clicked
/// anything in a client. The in-space question carries the mapped member's
/// identity and the agent run executes on their behalf, so commits co-author
/// and tokens resolve as for any message they typed.
///
/// ## The outbound lane
///
/// The dispatch's run-log id doubles as the `agent_turn` message id and as
/// the key of a pending-reply row in the workspace's caches table. When that
/// run completes, the listener reads the turn's final text and posts it back
/// — in the review thread the question was asked in, or as a conversation
/// comment @-addressing the asker. One attempt, then the row is dropped: a
/// GitHub outage must not leave a queue of stale replies that fire long
/// after the conversation moved on. The answer itself is never lost — it
/// stays in the space.
class GitHubPrConversationBridge implements GitHubPrConversationSink {
  /// Creates a [GitHubPrConversationBridge]. Call [start] to arm the
  /// outbound listener.
  GitHubPrConversationBridge({
    required GitHubPrConversationGateway gateway,
    required GitHubLoginDirectory loginDirectory,
    required MessagingPort messaging,
    required MessagingRepository messagingRepository,
    required WorkspaceDatabaseManager workspaceDbs,
    required StartAiReview startReview,
    required EnsurePrReviewSpace ensureSpace,
    required DefaultAnswererResolver defaultAnswerer,
    required DomainEventBus eventBus,
    void Function(String message)? onWarning,
  }) : _gateway = gateway,
       _loginDirectory = loginDirectory,
       _messaging = messaging,
       _messagingRepository = messagingRepository,
       _workspaceDbs = workspaceDbs,
       _startReview = startReview,
       _ensureSpace = ensureSpace,
       _defaultAnswerer = defaultAnswerer,
       _eventBus = eventBus,
       _onWarning = onWarning;

  /// The caches kind holding a pending outbound reply, keyed by the agent
  /// run-log id (= the agent turn's message id).
  static const String pendingReplyCacheKind = 'github_pr_reply';

  final GitHubPrConversationGateway _gateway;
  final GitHubLoginDirectory _loginDirectory;
  final MessagingPort _messaging;
  final MessagingRepository _messagingRepository;
  final WorkspaceDatabaseManager _workspaceDbs;
  final StartAiReview _startReview;
  final EnsurePrReviewSpace _ensureSpace;
  final DefaultAnswererResolver _defaultAnswerer;
  final DomainEventBus _eventBus;
  final void Function(String message)? _onWarning;

  StreamSubscription<AgentRunCompleted>? _runSub;

  CacheDao _cache(String workspaceId) =>
      _workspaceDbs.of(workspaceId).cacheDao;

  /// The logins a comment may @mention to address the bot: the full GitHub
  /// App bot login (`<slug>[bot]`) and — because that is punishing to type and
  /// absent from GitHub's @ autocomplete — the bare slug. GitHub fixes the
  /// bot's real login; accepting the short form is OUR matcher's decision,
  /// made wherever the comment text is matched (polling, not GitHub's
  /// mention-resolution).
  ///
  /// The collision this invites is stated rather than smoothed: a HUMAN whose
  /// login equals the app's slug would be addressed by the same short form.
  /// Slug and user logins are visible to whoever registered the app, so the
  /// operator picks a distinctive slug or lives with the ambiguity.
  static List<String> acceptedMentionLogins(String botLogin) =>
      mention.acceptedMentionLogins(botLogin);

  /// Whether [body] @mentions the bot ([botLogin] or its bare slug).
  ///
  /// Case-insensitive (GitHub logins are) and boundary-aware: the lookahead
  /// rejects a longer login continuing at the same spot — including an
  /// opening `[`, so the bare slug does not match inside another bracketed
  /// account like `@app[bots]` — while allowing any other punctuation:
  /// `@app[bot]:`, `@app[bot]x`-rejects, `@app!` matches. `\b` cannot
  /// express this because the bracketed `[bot]` suffix ends in a non-word
  /// character.
  static bool mentionsBot(String body, String botLogin) =>
      mention.bodyMentions(body, botLogin);

  /// Strips the first @mention of the bot from [body].
  ///
  /// The full login is tried first so `@app[bot] question` strips to
  /// `question`, not `[bot] question`.
  static String stripMention(String body, String botLogin) =>
      mention.stripMention(body, botLogin);

  /// Classifies an invocation by its mention-stripped text: a bare mention
  /// (or `review`, ignoring trailing punctuation) asks for the review
  /// pipeline; anything else is a question for the space.
  @visibleForTesting
  static GitHubBotCommand parseCommand(String stripped) {
    final command = stripped.trim().toLowerCase();
    if (command.isEmpty ||
        command == 'review' ||
        command == 'review.' ||
        command == 'review!' ||
        command == 'review this pr') {
      return GitHubBotCommand.review;
    }
    return GitHubBotCommand.question;
  }

  /// Begins listening for completed agent runs (the outbound lane).
  void start() {
    _runSub ??= _eventBus.on<AgentRunCompleted>().listen(
      (event) => unawaited(_onRunCompleted(event)),
    );
  }

  /// Stops listening.
  @override
  Future<void> stop() async {
    await _runSub?.cancel();
    _runSub = null;
  }

  /// Handles one eligible inbound comment.
  ///
  /// [isBotThread] marks a review comment that replies inside a thread the
  /// bot already participates in — the interactive mode, which needs no
  /// mention to qualify (the poller decides eligibility; this re-checks the
  /// gates it owns).
  @override
  Future<void> handleInboundComment({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String prTitle,
    required InboundGitHubPrComment comment,
    bool isBotThread = false,
  }) async {
    // 1. Loop guard, before anything that costs a request or a row.
    if (comment.authorIsBot) {
      return;
    }
    final botLogin = await _gateway.botLogin();
    final mention = mentionsBot(comment.body, botLogin);
    if (!mention && !isBotThread) {
      return;
    }

    // 2. Acknowledge before the slow work.
    await _tryAcknowledge(owner, repo, comment);

    // 3. Membership gate.
    final actor = await _resolveActor(workspaceId, comment.authorLogin);
    if (actor.refusal != null) {
      await _reply(
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        body: actor.refusal!,
      );
      return;
    }
    final member = actor.member!;

    final question = mention
        ? stripMention(comment.body, botLogin)
        : comment.body.trim();
    // Only an explicit mention can ask for a review: a bare mention or
    // `review`. A thread reply that did not mention the bot is always a
    // question — treating it as a review request would re-run the pipeline
    // on every follow-up.
    if (mention && parseCommand(question) == GitHubBotCommand.review) {
      await _startReviewAndReport(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
      );
      return;
    }

    await _answerQuestion(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      prTitle: prTitle,
      comment: comment,
      member: member,
      question: question,
    );
  }

  /// Handles a PR that carries the review label — the reviewer-assignment
  /// stand-in, since a GitHub App cannot hold the native requested-reviewer
  /// slot. The poller dedupes per PR; there is no author to gate (a label
  /// carries none), exactly like the poll-driven PR events this mirrors.
  @override
  Future<void> handleLabeledPullRequest({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  }) async {
    await _startReviewAndReport(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      comment: null,
    );
  }

  // ── Inbound helpers ─────────────────────────────────────────────────────

  Future<void> _tryAcknowledge(
    String owner,
    String repo,
    InboundGitHubPrComment comment,
  ) async {
    try {
      if (comment.isReviewComment) {
        await _gateway.acknowledgeReviewComment(owner, repo, comment.id);
      } else {
        await _gateway.acknowledgeIssueComment(owner, repo, comment.id);
      }
    } on Object catch (e) {
      _onWarning?.call('github_pr_conversation: ack failed: $e');
    }
  }

  /// The membership ladder, mirroring the chat bridge's: fails closed and
  /// explains, so an unmapped author is told how to map and a read-only one
  /// is told why not. None of them proceed.
  Future<({WorkspaceMember? member, String? refusal})> _resolveActor(
    String workspaceId,
    String login,
  ) async {
    final member = await _loginDirectory.memberForLogin(workspaceId, login);
    if (member == null) {
      return (
        member: null,
        refusal:
            'I do not know who you are in Control Center yet. Sign in to '
            'GitHub from Settings → Accounts (or paste a token) so your '
            'account is linked, and make sure you are a member of the '
            'workspace that links this repository.',
      );
    }
    if (!member.role.canWrite) {
      return (
        member: null,
        refusal:
            'Your role in this workspace is read-only '
            '(${member.role.name}), so I cannot start work on your behalf.',
      );
    }
    return (member: member, refusal: null);
  }

  Future<void> _startReviewAndReport({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required InboundGitHubPrComment? comment,
  }) async {
    String body;
    try {
      final result = await _startReview(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
      );
      final status = result['status'] as String? ?? 'started';
      body = status == 'already_running'
          ? 'A review of this pull request is already running — its findings '
              'will appear in the review space in Control Center.'
          : 'Review started. The findings will appear in this pull request\'s '
              'review space in Control Center, where they can be published '
              'back here.';
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: review failed to start for '
        '$owner/$repo#$prNumber: $e',
      );
      body = 'I could not start the review ($e). The operator can see the '
          'failure in the server log.';
    }
    if (comment != null) {
      await _reply(
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        body: body,
      );
    }
  }

  Future<void> _answerQuestion({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String prTitle,
    required InboundGitHubPrComment comment,
    required WorkspaceMember member,
    required String question,
  }) async {
    final repoFullName = '$owner/$repo';
    String spaceId;
    try {
      spaceId =
          await _ensureSpace(
            workspaceId: workspaceId,
            repoFullName: repoFullName,
            prNumber: prNumber,
            title: prTitle,
          ) ??
          '';
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: space provisioning failed for '
        '$repoFullName#$prNumber: $e',
      );
      await _reply(
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        body: 'I could not prepare this pull request\'s workspace, so I '
            'cannot answer here yet.',
      );
      return;
    }
    if (spaceId.isEmpty) {
      await _reply(
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        body: 'I could not prepare this pull request\'s workspace, so I '
            'cannot answer here yet.',
      );
      return;
    }

    final answerer = await _resolveAnswerer(workspaceId, spaceId);
    if (answerer == null) {
      await _reply(
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        body: 'This workspace has no agent available to answer. Ask the '
            'operator to check the workspace\'s agents.',
      );
      return;
    }

    await _messaging.sendUserMessage(
      workspaceId,
      spaceId,
      question,
      senderUserId: member.userId,
      metadata: {
        'github': {
          'comment_id': comment.id,
          'repo': repoFullName,
          'pr_number': prNumber,
          'author_login': comment.authorLogin,
          'thread': comment.isReviewComment ? 'review' : 'issue',
        },
      },
    );

    String? runLogId;
    try {
      runLogId = await _messaging.dispatchAgent(
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentId: answerer,
        prompt: question,
        requestedByUserId: member.userId,
      );
    } on Object catch (e) {
      // The message is in the space; only the turn failed to start. Report
      // where the question was asked rather than letting the throw tear the
      // poller's per-PR error handling into looking like a sweep failure.
      _onWarning?.call(
        'github_pr_conversation: dispatch failed for '
        '$repoFullName#$prNumber: $e',
      );
      await _reply(
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        body: 'I could not start an agent on that. The question is in the '
            'review space; the operator can retry it there.',
      );
      return;
    }
    if (runLogId == null || runLogId.isEmpty) {
      _onWarning?.call(
        'github_pr_conversation: dispatch refused for '
        '$repoFullName#$prNumber',
      );
      await _reply(
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        body: 'I could not start an agent on that. The question is in the '
            'review space; the operator can retry it there.',
      );
      return;
    }

    // The dispatch spawned the run asynchronously, so it cannot have
    // completed before this returns — record the outbound reply now.
    final pending = _PendingReply(
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      askerLogin: comment.authorLogin,
      isReviewThread: comment.isReviewComment,
      parentCommentId: comment.isReviewComment ? comment.id : null,
    );
    await _cache(workspaceId).put(
      workspaceId,
      pendingReplyCacheKind,
      runLogId,
      jsonEncode(pending.toJson()),
    );
  }

  /// Who answers: the last agent that spoke in the space (the reviewer who
  /// filed findings, or the consolidator), else the workspace's default
  /// answerer — a fresh PR space holds an empty roster, so without the
  /// fallback a first question would land in a room nobody answers.
  Future<String?> _resolveAnswerer(String workspaceId, String spaceId) async {
    try {
      final participants = await _messagingRepository.getParticipants(
        workspaceId,
        spaceId,
      );
      final hasAgents = participants.any((p) => !p.isUser);
      if (!hasAgents) {
        final fallback = await _defaultAnswerer(workspaceId);
        if (fallback == null || fallback.isEmpty) {
          return null;
        }
        await _messaging.addAgentToSpace(
          workspaceId,
          spaceId,
          fallback,
          renameForGroup: false,
        );
        return fallback;
      }
    } on Object catch (e) {
      _onWarning?.call('github_pr_conversation: roster read failed: $e');
      return await _defaultAnswerer(workspaceId);
    }
    try {
      final messages = await _messagingRepository.getSpaceMessages(
        workspaceId,
        spaceId,
      );
      for (final message in messages.reversed) {
        if (message.senderType == SenderType.agent &&
            (message.messageType == MessageType.text ||
                message.messageType == MessageType.agentTurn)) {
          return message.senderId;
        }
      }
    } on Object catch (e) {
      _onWarning?.call('github_pr_conversation: history read failed: $e');
    }
    return await _defaultAnswerer(workspaceId);
  }

  // ── Outbound lane ───────────────────────────────────────────────────────

  Future<void> _onRunCompleted(AgentRunCompleted event) async {
    final workspaceId = event.workspaceId;
    final runId = event.runId;
    if (workspaceId == null ||
        workspaceId.isEmpty ||
        runId == null ||
        runId.isEmpty) {
      return;
    }
    final raw = await _cache(workspaceId).read(
      workspaceId,
      pendingReplyCacheKind,
      runId,
    );
    if (raw == null) {
      return;
    }
    // Consume first: whatever happens below, this run's reply fires once.
    await _cache(workspaceId).deleteEntry(
      workspaceId,
      pendingReplyCacheKind,
      runId,
    );
    _PendingReply pending;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      pending = _PendingReply.fromJson(decoded);
    } on FormatException {
      return;
    }

    final message = await _messagingRepository.getMessageById(
      workspaceId,
      runId,
    );
    final content = message?.content.trim() ?? '';
    if (content.isEmpty) {
      // The turn failed or produced nothing — the failure is visible in the
      // space; posting an empty answer on GitHub would be noise.
      return;
    }
    try {
      if (pending.isReviewThread && pending.parentCommentId != null) {
        await _gateway.replyInReviewThread(
          pending.owner,
          pending.repo,
          prNumber: pending.prNumber,
          parentCommentId: pending.parentCommentId!,
          body: content,
        );
      } else {
        await _gateway.postConversationComment(
          pending.owner,
          pending.repo,
          prNumber: pending.prNumber,
          body: pending.askerLogin.isEmpty
              ? content
              : '@${pending.askerLogin} $content',
        );
      }
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: posting the answer to '
        '${pending.owner}/${pending.repo}#${pending.prNumber} failed: $e. '
        'The answer itself is in the review space.',
      );
    }
  }

  // ── Shared ──────────────────────────────────────────────────────────────

  Future<void> _reply({
    required String owner,
    required String repo,
    required int prNumber,
    required InboundGitHubPrComment comment,
    required String body,
  }) async {
    try {
      if (comment.isReviewComment) {
        await _gateway.replyInReviewThread(
          owner,
          repo,
          prNumber: prNumber,
          parentCommentId: comment.id,
          body: body,
        );
      } else {
        await _gateway.postConversationComment(
          owner,
          repo,
          prNumber: prNumber,
          body: comment.authorLogin.isEmpty
              ? body
              : '@${comment.authorLogin} $body',
        );
      }
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: replying on $owner/$repo#$prNumber '
        'failed: $e',
      );
    }
  }
}
