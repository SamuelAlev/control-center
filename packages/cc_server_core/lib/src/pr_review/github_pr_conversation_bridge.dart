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
import 'package:cc_server_core/src/forge/github_clients.dart' show GitHubLane;
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:meta/meta.dart';

/// Starts the AI review pipeline for one pull request as [userId] (the
/// accountable human: the member who asked or labelled). The runtime's
/// `startPrReview` seam: idempotent, duplicate-guarded (`already_running`),
/// and it creates + provisions the PR's review space itself.
typedef StartAiReview =
    Future<Map<String, dynamic>> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
      required String userId,
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
    required this.authorId,
    required this.authorLogin,
    required this.isReviewComment,
  });

  /// GitHub comment id (numeric, unique across both lanes).
  final int id;

  /// Raw markdown body.
  final String body;

  /// The author's immutable numeric GitHub user id (`user.id`); 0 when the
  /// payload carried none. The author is matched on this, never on the login.
  final int authorId;

  /// Author's login (`appslug[bot]` for app accounts). Display only.
  final String authorLogin;

  /// Whether this is an inline review comment (diff thread) rather than a
  /// conversation-timeline comment. Picks the lane replies post into.
  final bool isReviewComment;
}

/// What the bridge did with one inbound invocation.
enum GitHubInboundOutcome {
  /// Acted on, or deliberately ignored (a stranger to the bot, a read-only
  /// member, a claim another server won). Never offered again.
  done,

  /// The author's GitHub account maps to no member signed in here yet. A
  /// sign-in may simply not have been seen; the poller offers it again on a
  /// later sweep (a bounded number of times).
  authorUnknown,
}

/// The poller's view of the bridge: exactly the entry points discovery can
/// reach, plus the lifecycle of the outbound listener it owns. An interface
/// so the polling sweep is testable against a recording sink instead of the
/// whole bridge's dependency graph.
abstract interface class GitHubPrConversationSink {
  /// Handles one eligible inbound comment (see
  /// [GitHubPrConversationBridge.handleInboundComment]).
  Future<GitHubInboundOutcome> handleInboundComment({
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
  Future<GitHubInboundOutcome> handleLabeledPullRequest({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  });

  /// Stops the bridge's outbound listener (see
  /// [GitHubPrConversationBridge.stop]).
  Future<void> stop();
}

/// The member a conversation is on behalf of: who asked, as Control Center
/// and GitHub know them.
final class _Asker {
  const _Asker({
    required this.userId,
    required this.accountId,
    required this.login,
  });

  final String userId;
  final int accountId;
  final String login;
}

/// A pending outbound reply, recorded against the agent run it answers and
/// consumed when that run completes.
///
/// It carries who asked (to bound the post and to attribute it) and which
/// bot the question reached (so a reply after a lane or App change does not
/// post as a different identity).
class _PendingReply {
  _PendingReply({
    required this.owner,
    required this.repo,
    required this.prNumber,
    required this.asker,
    required this.identity,
    required this.isReviewThread,
    this.parentCommentId,
  });

  static const int _version = 2;

  /// Null for anything this build did not write.
  static _PendingReply? fromJson(Map<String, dynamic> json) {
    if (json['v'] != _version) {
      return null;
    }
    final userId = json['asker_user_id'];
    final accountId = json['asker_account_id'];
    final botLogin = json['bot_login'];
    final lane = GitHubLane.values
        .where((l) => l.wire == json['lane'])
        .firstOrNull;
    if (userId is! String ||
        userId.isEmpty ||
        accountId is! int ||
        botLogin is! String ||
        botLogin.isEmpty ||
        lane == null) {
      return null;
    }
    return _PendingReply(
      owner: json['owner'] as String? ?? '',
      repo: json['repo'] as String? ?? '',
      prNumber: (json['pr_number'] as num?)?.toInt() ?? 0,
      asker: _Asker(
        userId: userId,
        accountId: accountId,
        login: json['asker_login'] as String? ?? '',
      ),
      identity: GitHubConversationIdentity(
        botLogin: botLogin,
        slug: json['app_slug'] as String? ?? '',
        lane: lane,
      ),
      isReviewThread: json['kind'] == 'review',
      parentCommentId: (json['parent_comment_id'] as num?)?.toInt(),
    );
  }

  final String owner;
  final String repo;
  final int prNumber;
  final _Asker asker;
  final GitHubConversationIdentity identity;
  final bool isReviewThread;
  final int? parentCommentId;

  Map<String, dynamic> toJson() => {
    'v': _version,
    'owner': owner,
    'repo': repo,
    'pr_number': prNumber,
    'asker_user_id': asker.userId,
    'asker_account_id': asker.accountId,
    'asker_login': asker.login,
    'bot_login': identity.botLogin,
    'app_slug': identity.slug,
    'lane': identity.lane.wire,
    'kind': isReviewThread ? 'review' : 'issue',
    if (parentCommentId != null) 'parent_comment_id': parentCommentId,
  };
}

/// Bridges GitHub PR conversations into PR review spaces and back.
///
/// @mention (or a reply in a bot thread) → a space turn attributed to the
/// member who signed in to GitHub as that author; a bare mention/`review`
/// starts the AI review pipeline; the agent's reply posts back on GitHub.
///
/// Order, per comment: loop guard (bots and our own attributed replies) →
/// author resolved by numeric GitHub id to a writing member, else ignored
/// silently (nothing is posted) → the server confirms it can mint a `bot`
/// token bounded by that member → the claim: the member's own 👀 reaction,
/// where 201 means this server owns the work and 200 means another server of
/// theirs already does → work. A label runs the same gate on the labeller.
///
/// Every reply rides the workspace's gateway with a `bot` token bounded by
/// the asking member and starts with [attributed]'s prefix. Outbound: the
/// run-log id keys a pending-reply cache row; one post-back attempt, then
/// drop (the answer stays in the space).
class GitHubPrConversationBridge implements GitHubPrConversationSink {
  /// Creates a [GitHubPrConversationBridge]. Call [start] to arm the
  /// outbound listener.
  GitHubPrConversationBridge({
    required this._gatewayFor,
    required this._loginDirectory,
    required this._messaging,
    required this._messagingRepository,
    required this._workspaceDbs,
    required this._startReview,
    required this._ensureSpace,
    required this._defaultAnswerer,
    required this._eventBus,
    this._onWarning,
  });

  /// The caches kind holding a pending outbound reply, keyed by the agent
  /// run-log id (= the agent turn's message id).
  static const String pendingReplyCacheKind = 'github_pr_reply';

  /// How every automated reply begins, before the asker's login. In the
  /// Connect and user-token lanes a reply is authored by the asking person,
  /// not a `[bot]` account, so this prefix is also the loop guard.
  static const String attributionLead = '**Control Center** (for @';

  /// The gateway of one workspace: its bot, its tokens. A reply always
  /// rides the workspace the question arrived in.
  final GitHubPrConversationGateway Function(String workspaceId) _gatewayFor;
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

  CacheDao _cache(String workspaceId) => _workspaceDbs.of(workspaceId).cacheDao;

  /// The dedicated account is the default PR-conversation mention. The
  /// installed App's full bot login and bare slug remain compatible aliases;
  /// neither changes the identity used to post replies or guard bot loops.
  static List<String> acceptedMentionLogins(String botLogin) => botLogin.isEmpty
      ? const []
      : [
          mention.githubPrConversationMentionLogin,
          ...mention.acceptedMentionLogins(botLogin),
        ];

  /// Whether [body] addresses the PR conversation bridge.
  static bool mentionsBot(String body, String botLogin) =>
      acceptedMentionLogins(
        botLogin,
      ).any((login) => mention.mentionPattern(login).hasMatch(body));

  /// Strips the first recognized invocation mention from [body].
  static String stripMention(String body, String botLogin) {
    for (final login in acceptedMentionLogins(botLogin)) {
      final pattern = mention.mentionPattern(login);
      if (pattern.hasMatch(body)) {
        return body.replaceFirst(pattern, '').trim();
      }
    }
    return body.trim();
  }

  /// [body] as an automated reply on behalf of [login].
  static String attributed(String login, String body) =>
      '$attributionLead$login): $body';

  /// Whether [body] is one of our automated replies.
  static bool isAutomatedReply(String body) =>
      body.trimLeft().startsWith(attributionLead);

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
  Future<GitHubInboundOutcome> handleInboundComment({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String prTitle,
    required InboundGitHubPrComment comment,
    bool isBotThread = false,
  }) async {
    // 1. Loop guard, before anything that costs a request or a row: any
    // GitHub App account (ours or another bot) and our own attributed
    // replies, which on Connect are authored by a person.
    if (comment.authorLogin.toLowerCase().endsWith('[bot]') ||
        isAutomatedReply(comment.body)) {
      return GitHubInboundOutcome.done;
    }
    final gateway = _gatewayFor(workspaceId);
    final identity = await gateway.identity();
    if (identity == null) {
      return GitHubInboundOutcome.done;
    }
    final mention = mentionsBot(comment.body, identity.botLogin);
    if (!mention && !isBotThread) {
      return GitHubInboundOutcome.done;
    }

    // 2. Membership, by numeric id. Strangers and read-only members are
    // ignored silently: answering them would announce the bot to anyone.
    final actor = await _resolveActor(workspaceId, comment.authorId);
    final member = actor.member;
    if (member == null) {
      return actor.known
          ? GitHubInboundOutcome.done
          : GitHubInboundOutcome.authorUnknown;
    }

    // 3. The claim, as that member.
    final claimed = await _claim(
      gateway,
      owner: owner,
      repo: repo,
      userId: member.userId,
      what: 'comment ${comment.id} on $owner/$repo#$prNumber',
      react: () => comment.isReviewComment
          ? gateway.claimReviewComment(
              owner,
              repo,
              comment.id,
              asUserId: member.userId,
            )
          : gateway.claimIssueComment(
              owner,
              repo,
              comment.id,
              asUserId: member.userId,
            ),
    );
    if (!claimed) {
      return GitHubInboundOutcome.done;
    }
    final asker = _Asker(
      userId: member.userId,
      accountId: comment.authorId,
      login: comment.authorLogin,
    );

    final question = mention
        ? stripMention(comment.body, identity.botLogin)
        : comment.body.trim();
    // Only an explicit mention can ask for a review: a bare mention or
    // `review`. A thread reply that did not mention the bot is always a
    // question — treating it as a review request would re-run the pipeline
    // on every follow-up.
    if (mention && parseCommand(question) == GitHubBotCommand.review) {
      final body = await _startReviewAndDescribe(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        userId: member.userId,
      );
      await _replyTo(
        gateway,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        comment: comment,
        asker: asker,
        body: body,
      );
      return GitHubInboundOutcome.done;
    }

    await _answerQuestion(
      gateway,
      identity: identity,
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      prTitle: prTitle,
      comment: comment,
      asker: asker,
      question: question,
    );
    return GitHubInboundOutcome.done;
  }

  /// Handles a PR that carries the review label — the reviewer-assignment
  /// stand-in, since a GitHub App cannot hold the native requested-reviewer
  /// slot. The poller dedupes per PR.
  ///
  /// The label is gated exactly like a mention: the labeller (latest
  /// `labeled` event, by numeric id) must be a writing member who can push
  /// to the repository, and claims the PR with their own 👀. The review runs
  /// with the labeller as its accountable human. Nothing is posted.
  @override
  Future<GitHubInboundOutcome> handleLabeledPullRequest({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  }) async {
    final gateway = _gatewayFor(workspaceId);
    if (await gateway.identity() == null) {
      return GitHubInboundOutcome.done;
    }
    final GitHubPrActor? labeller;
    try {
      labeller = await gateway.latestLabeler(owner, repo, prNumber);
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: reading who labelled '
        '$owner/$repo#$prNumber failed: $e',
      );
      return GitHubInboundOutcome.done;
    }
    if (labeller == null) {
      return GitHubInboundOutcome.done;
    }
    final actor = await _resolveActor(workspaceId, labeller.accountId);
    final member = actor.member;
    if (member == null) {
      return actor.known
          ? GitHubInboundOutcome.done
          : GitHubInboundOutcome.authorUnknown;
    }
    final claimed = await _claim(
      gateway,
      owner: owner,
      repo: repo,
      userId: member.userId,
      what: 'label on $owner/$repo#$prNumber',
      react: () => gateway.claimPullRequest(
        owner,
        repo,
        prNumber,
        asUserId: member.userId,
      ),
    );
    if (!claimed) {
      return GitHubInboundOutcome.done;
    }
    await _startReviewAndDescribe(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      userId: member.userId,
    );
    return GitHubInboundOutcome.done;
  }

  // ── Inbound helpers ─────────────────────────────────────────────────────

  /// The writing member who signed in to GitHub as [accountId]. `known` is
  /// false when the account maps to no member at all (perhaps a sign-in not
  /// seen yet), true for a member who may not write.
  Future<({WorkspaceMember? member, bool known})> _resolveActor(
    String workspaceId,
    int accountId,
  ) async {
    final member = await _loginDirectory.memberForAccountId(
      workspaceId,
      accountId,
    );
    if (member == null) {
      return (member: null, known: false);
    }
    return (member: member.role.canWrite ? member : null, known: true);
  }

  /// Whether this server owns the work: it can reply bounded by [userId],
  /// and [react] left that person's 👀 (201). A 200 (already reacted:
  /// another server of theirs) or any failure means stop.
  Future<bool> _claim(
    GitHubPrConversationGateway gateway, {
    required String owner,
    required String repo,
    required String userId,
    required String what,
    required Future<GitHubReactionClaim> Function() react,
  }) async {
    if (!await gateway.canPostAs(owner, repo, actingUserId: userId)) {
      return false;
    }
    try {
      return await react() == GitHubReactionClaim.claimed;
    } on Object catch (e) {
      _onWarning?.call('github_pr_conversation: claiming $what failed: $e');
      return false;
    }
  }

  /// Starts the review as [userId] and returns the reply that describes the
  /// outcome.
  Future<String> _startReviewAndDescribe({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String userId,
  }) async {
    try {
      final result = await _startReview(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        userId: userId,
      );
      final status = result['status'] as String? ?? 'started';
      return status == 'already_running'
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
      return 'I could not start the review ($e). The operator can see the '
          'failure in the server log.';
    }
  }

  Future<void> _answerQuestion(
    GitHubPrConversationGateway gateway, {
    required GitHubConversationIdentity identity,
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String prTitle,
    required InboundGitHubPrComment comment,
    required _Asker asker,
    required String question,
  }) async {
    Future<void> reply(String body) => _replyTo(
      gateway,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      comment: comment,
      asker: asker,
      body: body,
    );

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
      spaceId = '';
    }
    if (spaceId.isEmpty) {
      await reply(
        'I could not prepare this pull request\'s workspace, so I cannot '
        'answer here yet.',
      );
      return;
    }

    final answerer = await _resolveAnswerer(workspaceId, spaceId);
    if (answerer == null) {
      await reply(
        'This workspace has no agent available to answer. Ask the operator '
        'to check the workspace\'s agents.',
      );
      return;
    }

    await _messaging.sendUserMessage(
      workspaceId,
      spaceId,
      question,
      senderUserId: asker.userId,
      metadata: {
        'github': {
          'comment_id': comment.id,
          'repo': repoFullName,
          'pr_number': prNumber,
          'author_id': comment.authorId,
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
        requestedByUserId: asker.userId,
      );
    } on Object catch (e) {
      // The message is in the space; only the turn failed to start. Report
      // where the question was asked rather than letting the throw tear the
      // poller's per-PR error handling into looking like a sweep failure.
      _onWarning?.call(
        'github_pr_conversation: dispatch failed for '
        '$repoFullName#$prNumber: $e',
      );
    }
    if (runLogId == null || runLogId.isEmpty) {
      _onWarning?.call(
        'github_pr_conversation: no agent turn started for '
        '$repoFullName#$prNumber',
      );
      await reply(
        'I could not start an agent on that. The question is in the review '
        'space; the operator can retry it there.',
      );
      return;
    }

    // The run id exists only once dispatch returns, and a run that fails
    // fast can complete before the row below is written. [_onRunCompleted]
    // keeps such completions briefly in [_unclaimedCompletions]; one found
    // for this run after the write is replayed so the reply is not lost.
    final pending = _PendingReply(
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      asker: asker,
      identity: identity,
      isReviewThread: comment.isReviewComment,
      parentCommentId: comment.isReviewComment ? comment.id : null,
    );
    await _cache(workspaceId).put(
      workspaceId,
      pendingReplyCacheKind,
      runLogId,
      jsonEncode(pending.toJson()),
    );
    final early = _unclaimedCompletions[runLogId];
    if (early != null) {
      await _consumeSerialized(early.event, workspaceId, runLogId);
    }
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

  /// Completions that arrived before any pending-reply row named them, by
  /// run id, kept for [_unclaimedTtl] (a question's row is written right
  /// after its dispatch returns).
  final Map<String, ({AgentRunCompleted event, DateTime at})>
  _unclaimedCompletions = {};

  /// The consumption in flight per run id: a replayed completion queues
  /// behind the live one, and the row is deleted before posting, so a reply
  /// never posts twice.
  final Map<String, Future<void>> _consuming = {};

  static const Duration _unclaimedTtl = Duration(minutes: 2);
  static const int _maxUnclaimed = 256;

  Future<void> _onRunCompleted(AgentRunCompleted event) {
    final workspaceId = event.workspaceId;
    final runId = event.runId;
    if (workspaceId == null ||
        workspaceId.isEmpty ||
        runId == null ||
        runId.isEmpty) {
      return Future.value();
    }
    // Before any await: a question whose row lands after this point finds
    // the completion here and replays it.
    _rememberUnclaimed(event, runId);
    return _consumeSerialized(event, workspaceId, runId);
  }

  Future<void> _consumeSerialized(
    AgentRunCompleted event,
    String workspaceId,
    String runId,
  ) {
    final previous = _consuming[runId] ?? Future<void>.value();
    late final Future<void> next;
    next = previous.then((_) async {
      try {
        await _consumeCompletion(event, workspaceId, runId);
      } on Object catch (e) {
        _onWarning?.call(
          'github_pr_conversation: handling completed run $runId failed: $e',
        );
      } finally {
        if (identical(_consuming[runId], next)) {
          unawaited(_consuming.remove(runId));
        }
      }
    });
    _consuming[runId] = next;
    return next;
  }

  void _rememberUnclaimed(AgentRunCompleted event, String runId) {
    final now = DateTime.now();
    _unclaimedCompletions
      ..removeWhere((_, v) => now.difference(v.at) > _unclaimedTtl)
      ..[runId] = (event: event, at: now);
    while (_unclaimedCompletions.length > _maxUnclaimed) {
      _unclaimedCompletions.remove(_unclaimedCompletions.keys.first);
    }
  }

  Future<void> _consumeCompletion(
    AgentRunCompleted event,
    String workspaceId,
    String runId,
  ) async {
    final raw = await _cache(
      workspaceId,
    ).read(workspaceId, pendingReplyCacheKind, runId);
    if (raw == null) {
      return;
    }
    _unclaimedCompletions.remove(runId);
    // Consume first: whatever happens below, this run's reply fires once.
    await _cache(
      workspaceId,
    ).deleteEntry(workspaceId, pendingReplyCacheKind, runId);
    _PendingReply? pending;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        pending = _PendingReply.fromJson(decoded);
      }
    } on FormatException {
      pending = null;
    }
    if (pending == null) {
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
    final where = '${pending.owner}/${pending.repo}#${pending.prNumber}';

    // The reply must leave as the identity the question reached. A lane or
    // App change in between would post as someone the asker never addressed.
    final gateway = _gatewayFor(workspaceId);
    final current = await gateway.identity();
    if (current == null || !current.sameAs(pending.identity)) {
      _onWarning?.call(
        'github_pr_conversation: not posting the answer to $where — the '
        'workspace\'s GitHub identity changed since the question '
        '(${pending.identity.botLogin} on ${pending.identity.lane.wire}, now '
        '${current == null ? 'none' : '${current.botLogin} on '
                  '${current.lane.wire}'}). The answer is in the review '
        'space.',
      );
      return;
    }
    // And on behalf of the same person, who must still be a writing member
    // signed in as that GitHub account.
    final member = (await _resolveActor(
      workspaceId,
      pending.asker.accountId,
    )).member;
    if (member == null || member.userId != pending.asker.userId) {
      _onWarning?.call(
        'github_pr_conversation: not posting the answer to $where — the '
        'asker is no longer a writing member signed in as that GitHub '
        'account. The answer is in the review space.',
      );
      return;
    }
    try {
      await _post(
        gateway,
        owner: pending.owner,
        repo: pending.repo,
        prNumber: pending.prNumber,
        reviewThreadParentId: pending.isReviewThread
            ? pending.parentCommentId
            : null,
        asker: pending.asker,
        body: content,
      );
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: posting the answer to $where failed: $e. '
        'The answer itself is in the review space.',
      );
    }
  }

  // ── Shared ──────────────────────────────────────────────────────────────

  /// Replies to [comment] in its own lane; a failure is logged, not thrown.
  Future<void> _replyTo(
    GitHubPrConversationGateway gateway, {
    required String owner,
    required String repo,
    required int prNumber,
    required InboundGitHubPrComment comment,
    required _Asker asker,
    required String body,
  }) async {
    try {
      await _post(
        gateway,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        reviewThreadParentId: comment.isReviewComment ? comment.id : null,
        asker: asker,
        body: body,
      );
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: replying on $owner/$repo#$prNumber '
        'failed: $e',
      );
    }
  }

  /// Posts an attributed automated reply bounded by [asker]: inside the
  /// review thread rooted at [reviewThreadParentId], else on the timeline.
  Future<void> _post(
    GitHubPrConversationGateway gateway, {
    required String owner,
    required String repo,
    required int prNumber,
    required int? reviewThreadParentId,
    required _Asker asker,
    required String body,
  }) async {
    final text = attributed(asker.login, body);
    if (reviewThreadParentId != null) {
      await gateway.replyInReviewThread(
        owner,
        repo,
        prNumber: prNumber,
        parentCommentId: reviewThreadParentId,
        body: text,
        actingUserId: asker.userId,
      );
    } else {
      await gateway.postConversationComment(
        owner,
        repo,
        prNumber: prNumber,
        body: text,
        actingUserId: asker.userId,
      );
    }
  }
}
