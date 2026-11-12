import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/forge/github_clients.dart' show GitHubLane;
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import '../helpers/test_database.dart';

const _botLogin = 'cc-test[bot]';
const _workspaceId = 'ws1';
const _spaceId = 'space-1';

/// GitHub account ids of the test people.
const _octocatId = 101;
const _viewerId = 102;
const _strangerId = 999;

const _identity = GitHubConversationIdentity(
  botLogin: _botLogin,
  slug: 'cc-test',
  lane: GitHubLane.ownApp,
);

/// Records every GitHub call the bridge can make and scripts the gates.
class _FakeGateway implements GitHubPrConversationGateway {
  GitHubConversationIdentity? identityValue = _identity;
  bool canPost = true;
  GitHubReactionClaim claimResult = GitHubReactionClaim.claimed;
  Object? claimError;
  GitHubPrActor? labeller;

  final canPostChecks =
      <({String repo, String actingUserId, bool inReviewThread})>[];
  final claims = <({String kind, int id, String asUserId})>[];
  final conversationComments =
      <({int prNumber, String body, String actingUserId})>[];
  final reviewReplies =
      <({int prNumber, int parentId, String body, String actingUserId})>[];

  bool get touchedGitHub =>
      canPostChecks.isNotEmpty ||
      claims.isNotEmpty ||
      conversationComments.isNotEmpty ||
      reviewReplies.isNotEmpty;

  @override
  Future<GitHubConversationIdentity?> identity() async => identityValue;

  @override
  Future<bool> canPostAs(
    String owner,
    String repo, {
    required String actingUserId,
    required bool inReviewThread,
  }) async {
    canPostChecks.add((
      repo: '$owner/$repo',
      actingUserId: actingUserId,
      inReviewThread: inReviewThread,
    ));
    return canPost;
  }

  Future<GitHubReactionClaim> _claim(String kind, int id, String asUserId) {
    claims.add((kind: kind, id: id, asUserId: asUserId));
    final error = claimError;
    if (error != null) {
      return Future.error(error);
    }
    return Future.value(claimResult);
  }

  @override
  Future<GitHubReactionClaim> claimIssueComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  }) => _claim('issue_comment', commentId, asUserId);

  @override
  Future<GitHubReactionClaim> claimReviewComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  }) => _claim('review_comment', commentId, asUserId);

  @override
  Future<GitHubReactionClaim> claimPullRequest(
    String owner,
    String repo,
    int prNumber, {
    required String asUserId,
  }) => _claim('pull_request', prNumber, asUserId);

  @override
  Future<GitHubPrActor?> latestLabeler(
    String owner,
    String repo,
    int prNumber, {
    String label = kGithubPrReviewLabel,
  }) async => labeller;

  @override
  Future<void> postConversationComment(
    String owner,
    String repo, {
    required int prNumber,
    required String body,
    required String actingUserId,
  }) async {
    conversationComments.add((
      prNumber: prNumber,
      body: body,
      actingUserId: actingUserId,
    ));
  }

  @override
  Future<void> replyInReviewThread(
    String owner,
    String repo, {
    required int prNumber,
    required int parentCommentId,
    required String body,
    required String actingUserId,
  }) async {
    reviewReplies.add((
      prNumber: prNumber,
      parentId: parentCommentId,
      body: body,
      actingUserId: actingUserId,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMembershipRepository implements WorkspaceMembershipRepository {
  _FakeMembershipRepository(this.members);

  List<WorkspaceMember> members;

  @override
  Future<List<WorkspaceMember>> getForWorkspace(String workspaceId) async =>
      members.where((m) => m.workspaceId == workspaceId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessagingPort implements MessagingPort {
  final userMessages =
      <
        ({
          String spaceId,
          String content,
          String? senderUserId,
          Map<String, dynamic>? metadata,
        })
      >[];
  final addedAgents = <({String spaceId, String agentId})>[];
  final dispatches =
      <
        ({String spaceId, String agentId, String prompt, String? requestedBy})
      >[];
  String? dispatchRunId = 'run-1';
  Object? dispatchError;

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    userMessages.add((
      spaceId: spaceId,
      content: content,
      senderUserId: senderUserId,
      metadata: metadata,
    ));
  }

  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) async {
    addedAgents.add((spaceId: spaceId, agentId: agentId));
  }

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    dynamic wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    if (dispatchError != null) {
      throw dispatchError!;
    }
    dispatches.add((
      spaceId: spaceId,
      agentId: agentId,
      prompt: prompt,
      requestedBy: requestedByUserId,
    ));
    return dispatchRunId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
    String? requestedByUserId,
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
    String? requestedByUserId,
  }) async => const GuidedGoalStepResult();
}

class _FakeMessagingRepository implements MessagingRepository {
  List<SpaceParticipant> participants = const [];
  List<Message> spaceMessages = const [];
  final messagesById = <String, Message>{};

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => participants;

  @override
  Future<List<Message>> getSpaceMessages(
    String workspaceId,
    String spaceId,
  ) async => spaceMessages;

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      messagesById[messageId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

InboundGitHubPrComment _issueComment(
  int id,
  String body, {
  int authorId = _octocatId,
  String login = 'octocat',
}) => InboundGitHubPrComment(
  id: id,
  body: body,
  authorId: authorId,
  authorLogin: login,
  isReviewComment: false,
);

InboundGitHubPrComment _reviewComment(
  int id,
  String body, {
  int authorId = _octocatId,
  String login = 'octocat',
}) => InboundGitHubPrComment(
  id: id,
  body: body,
  authorId: authorId,
  authorLogin: login,
  isReviewComment: true,
);

Message _turnMessage(String id, String content) => Message(
  id: id,
  spaceId: _spaceId,
  conversationId: 'main',
  senderId: 'agent-9',
  senderType: SenderType.agent,
  content: content,
  messageType: MessageType.agentTurn,
  createdAt: DateTime(2026, 8, 26),
);

WorkspaceMember _member(String id, String userId, WorkspaceRole role) =>
    WorkspaceMember(
      id: id,
      workspaceId: _workspaceId,
      userId: userId,
      role: role,
      joinedAt: DateTime(2026, 1, 1),
    );

Future<Map<String, dynamic>?> _readPending(
  WorkspaceDatabaseManager dbs,
  String runId,
) async {
  final rows = await dbs
      .of(_workspaceId)
      .customSelect(
        'SELECT reply_json FROM pending_pr_replies WHERE run_log_id = ?',
        variables: [Variable(runId)],
      )
      .get();
  if (rows.isEmpty) {
    return null;
  }
  final decoded = jsonDecode(rows.single.read<String>('reply_json'));
  return decoded is Map<String, dynamic> ? decoded : null;
}

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _FakeGateway gateway;
  late _FakeMessagingPort messaging;
  late _FakeMessagingRepository messagingRepository;
  late _FakeMembershipRepository members;
  late GitHubLoginDirectory directory;
  late DomainEventBus eventBus;
  late GitHubPrConversationBridge bridge;
  final warnings = <String>[];
  final startedReviews =
      <
        ({
          String workspaceId,
          String owner,
          String repo,
          int prNumber,
          String userId,
        })
      >[];
  Object? startReviewError;
  String? ensuredSpaceId = _spaceId;
  Object? ensureSpaceError;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, _workspaceId);
    // A pending reply hangs off its run's row.
    final wsDb = dbs.of(_workspaceId);
    await wsDb.customStatement('PRAGMA foreign_keys = OFF');
    await wsDb.customStatement(
      "INSERT INTO agent_run_logs (id, agent_id, workspace_id) VALUES ('run-1', "
      "'agent-1', '$_workspaceId')",
    );
    await wsDb.customStatement('PRAGMA foreign_keys = ON');
    gateway = _FakeGateway();
    messaging = _FakeMessagingPort();
    messagingRepository = _FakeMessagingRepository();
    eventBus = DomainEventBus();
    warnings.clear();
    startedReviews.clear();
    startReviewError = null;
    ensuredSpaceId = _spaceId;
    ensureSpaceError = null;
    members = _FakeMembershipRepository([
      _member('m1', 'u1', WorkspaceRole.admin),
      _member('m2', 'u2', WorkspaceRole.viewer),
    ]);
    directory = GitHubLoginDirectory(
      members: members,
      credentials: (userId, workspaceId) async => switch (userId) {
        'u1' => const ProviderToken(
          accessToken: 't',
          accountId: '$_octocatId',
          accountLogin: 'octocat',
        ),
        'u2' => const ProviderToken(
          accessToken: 't',
          accountId: '$_viewerId',
          accountLogin: 'viewer',
        ),
        _ => null,
      },
    );
    bridge = GitHubPrConversationBridge(
      gatewayFor: (_) => gateway,
      loginDirectory: directory,
      messaging: messaging,
      messagingRepository: messagingRepository,
      pendingReplies: DaoPendingPrReplyRepository(dbs),
      startReview:
          ({
            required workspaceId,
            required owner,
            required repo,
            required prNumber,
            required userId,
          }) async {
            if (startReviewError != null) {
              throw startReviewError!;
            }
            startedReviews.add((
              workspaceId: workspaceId,
              owner: owner,
              repo: repo,
              prNumber: prNumber,
              userId: userId,
            ));
            return {'status': 'started', 'space_id': _spaceId};
          },
      ensureSpace:
          ({
            required workspaceId,
            required repoFullName,
            required prNumber,
            required title,
          }) async {
            if (ensureSpaceError != null) {
              throw ensureSpaceError!;
            }
            return ensuredSpaceId;
          },
      defaultAnswerer: (workspaceId) async => 'agent-ceo',
      eventBus: eventBus,
      onWarning: warnings.add,
    )..start();
  });

  tearDown(() async {
    await bridge.stop();
  });

  Future<void> inbound(
    InboundGitHubPrComment comment, {
    bool isBotThread = false,
  }) => bridge.handleInboundComment(
    workspaceId: _workspaceId,
    owner: 'acme',
    repo: 'app',
    prNumber: 7,
    prTitle: 'T',
    comment: comment,
    isBotThread: isBotThread,
  );

  Future<void> completeRun(String content) async {
    messagingRepository.messagesById['run-1'] = _turnMessage('run-1', content);
    eventBus.publish(
      AgentRunCompleted(
        agentId: 'agent-ceo',
        workspaceId: _workspaceId,
        conversationId: _spaceId,
        runId: 'run-1',
        occurredAt: DateTime(2026, 8, 26),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('mention matching', () {
    test('the dedicated account is the only mention', () {
      expect(GitHubPrConversationBridge.acceptedMentionLogins(_botLogin), [
        'usectrl',
      ]);
      expect(
        GitHubPrConversationBridge.mentionsBot('@USECTRL why?', _botLogin),
        isTrue,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('(@usectrl: go)', _botLogin),
        isTrue,
      );
      expect(
        GitHubPrConversationBridge.stripMention(
          '@usectrl why is this failing?',
          _botLogin,
        ),
        'why is this failing?',
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('@usectrl why?', ''),
        isFalse,
      );
    });

    test('the App bot login and its bare slug address nothing', () {
      expect(
        GitHubPrConversationBridge.mentionsBot('hey @CC-TEST[bot]!', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('hey @cc-test!', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.stripMention('@cc-test why?', _botLogin),
        '@cc-test why?',
      );
    });

    test('rejects longer logins and unaddressed text', () {
      expect(
        GitHubPrConversationBridge.mentionsBot('@usectrl[bot] why?', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('@usectrls hi', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('usectrl without at', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('@someone-else hi', _botLogin),
        isFalse,
      );
      expect(GitHubPrConversationBridge.mentionsBot('plain text', ''), isFalse);
    });

    test('classifies review vs question commands', () {
      expect(
        GitHubPrConversationBridge.parseCommand(''),
        GitHubBotCommand.review,
      );
      expect(
        GitHubPrConversationBridge.parseCommand('review'),
        GitHubBotCommand.review,
      );
      expect(
        GitHubPrConversationBridge.parseCommand(' REVIEW. '),
        GitHubBotCommand.review,
      );
      expect(
        GitHubPrConversationBridge.parseCommand('review this pr'),
        GitHubBotCommand.review,
      );
      expect(
        GitHubPrConversationBridge.parseCommand('why?'),
        GitHubBotCommand.question,
      );
    });
  });

  group('attribution', () {
    test('every automated reply names the asker up front', () {
      expect(
        GitHubPrConversationBridge.attributed('octocat', 'It works.'),
        '**Control Center** (for @octocat): It works.',
      );
      expect(
        GitHubPrConversationBridge.isAutomatedReply(
          '  **Control Center** (for @octocat): It works.',
        ),
        isTrue,
      );
      expect(
        GitHubPrConversationBridge.isAutomatedReply(
          'Quoting **Control Center** (for @octocat): …',
        ),
        isFalse,
      );
    });

    test('the reply pings no one; the asker prefix still names them', () {
      final text = GitHubPrConversationBridge.attributed(
        'octocat',
        'Ask @acme/security or @mallory; see `@keep` in code.',
      );
      expect(text, startsWith('**Control Center** (for @octocat): '));
      expect(text, isNot(contains('@acme/security')));
      expect(text, isNot(contains('@mallory')));
      expect(text, contains('`@keep`'));
      expect(GitHubPrConversationBridge.isAutomatedReply(text), isTrue);
    });
  });

  group('loop guard', () {
    test('a bot-authored comment is dropped before anything happens', () async {
      await inbound(_issueComment(1, '@usectrl review', login: _botLogin));
      await inbound(
        _issueComment(2, '@usectrl review', login: 'dependabot[bot]'),
      );

      expect(gateway.touchedGitHub, isFalse);
      expect(messaging.dispatches, isEmpty);
      expect(startedReviews, isEmpty);
    });

    test(
      'our own attributed reply is dropped even when a person authored it',
      () async {
        // Connect and user-token lanes post replies as the asking person, so
        // the author is a member and the body still mentions the bot.
        await inbound(
          _issueComment(
            3,
            '**Control Center** (for @octocat): ask @usectrl review again',
          ),
        );

        expect(gateway.touchedGitHub, isFalse);
        expect(startedReviews, isEmpty);
      },
    );

    test('a workspace with no GitHub identity does nothing', () async {
      gateway.identityValue = null;

      await inbound(_issueComment(4, '@usectrl review'));

      expect(gateway.touchedGitHub, isFalse);
      expect(startedReviews, isEmpty);
    });
  });

  group('author resolution by numeric id', () {
    test('a renamed login still maps through the unchanged id', () async {
      await inbound(_issueComment(5, '@usectrl review', login: 'octo-renamed'));

      expect(startedReviews.single.userId, 'u1');
      expect(
        gateway.conversationComments.single.body,
        startsWith('**Control Center** (for @octo-renamed): '),
      );
    });

    test(
      'a different account that took the member\'s old login is ignored',
      () async {
        await inbound(_issueComment(6, '@usectrl review', authorId: 424242));

        expect(gateway.touchedGitHub, isFalse);
        expect(startedReviews, isEmpty);
      },
    );

    test('a comment without an author id is ignored', () async {
      await inbound(_issueComment(7, '@usectrl review', authorId: 0));

      expect(gateway.touchedGitHub, isFalse);
    });
  });

  group('silent ignore', () {
    test('a stranger is ignored without a word on GitHub', () async {
      await inbound(
        _issueComment(
          21,
          '@usectrl what do you think?',
          authorId: _strangerId,
          login: 'stranger',
        ),
      );

      expect(gateway.touchedGitHub, isFalse);
      expect(messaging.userMessages, isEmpty);
      expect(messaging.dispatches, isEmpty);
    });

    test('a read-only member is ignored without a word on GitHub', () async {
      await inbound(
        _issueComment(
          23,
          '@usectrl review',
          authorId: _viewerId,
          login: 'viewer',
        ),
      );

      expect(gateway.touchedGitHub, isFalse);
      expect(startedReviews, isEmpty);
    });
  });

  group('claim', () {
    test('201: the member\'s own 👀 claims and the work proceeds', () async {
      await inbound(_issueComment(31, '@usectrl review'));

      expect(gateway.canPostChecks.single, (
        repo: 'acme/app',
        actingUserId: 'u1',
        inReviewThread: false,
      ));
      expect(gateway.claims.single, (
        kind: 'issue_comment',
        id: 31,
        asUserId: 'u1',
      ));
      expect(startedReviews, hasLength(1));
    });

    test('a review comment is claimed on the review comment', () async {
      await inbound(_reviewComment(32, '@usectrl why?'));

      expect(gateway.claims.single.kind, 'review_comment');
      expect(gateway.claims.single.id, 32);
      // Its claim and reply live in the review thread: that is what is
      // asked whether it may be posted.
      expect(gateway.canPostChecks.single.inReviewThread, isTrue);
    });

    test('200: another server of the author owns it, stop cleanly', () async {
      gateway.claimResult = GitHubReactionClaim.alreadyClaimed;

      await inbound(_issueComment(33, '@usectrl review'));
      await inbound(_issueComment(34, '@usectrl why?'));

      expect(gateway.claims, hasLength(2));
      expect(startedReviews, isEmpty);
      expect(messaging.userMessages, isEmpty);
      expect(gateway.conversationComments, isEmpty);
      expect(warnings, isEmpty, reason: 'losing a claim is not a failure');
    });

    test('a failed reaction stops: there is no fallback', () async {
      gateway.claimError = StateError('reaction refused');

      await inbound(_issueComment(35, '@usectrl review'));

      expect(startedReviews, isEmpty);
      expect(gateway.conversationComments, isEmpty);
      expect(warnings.single, contains('claiming'));
    });

    test('no bot token for the member: nothing is claimed', () async {
      gateway.canPost = false;

      await inbound(_issueComment(36, '@usectrl review'));

      expect(gateway.canPostChecks, hasLength(1));
      expect(gateway.claims, isEmpty);
      expect(startedReviews, isEmpty);
      expect(gateway.conversationComments, isEmpty);
    });
  });

  group('review command', () {
    test(
      'a bare mention starts the review as the member and replies',
      () async {
        await inbound(_issueComment(11, '@usectrl'));

        expect(startedReviews.single, (
          workspaceId: _workspaceId,
          owner: 'acme',
          repo: 'app',
          prNumber: 7,
          userId: 'u1',
        ));
        final reply = gateway.conversationComments.single;
        expect(reply.body, startsWith('**Control Center** (for @octocat): '));
        expect(reply.body, contains('Review started'));
        expect(reply.actingUserId, 'u1');
        expect(messaging.userMessages, isEmpty);
      },
    );

    test('an explicit review word in a thread replies in it', () async {
      await inbound(_reviewComment(12, '@usectrl review'));

      expect(startedReviews.single.prNumber, 7);
      final reply = gateway.reviewReplies.single;
      expect(reply.parentId, 12);
      expect(reply.actingUserId, 'u1');
      expect(reply.body, startsWith('**Control Center** (for @octocat): '));
      expect(gateway.conversationComments, isEmpty);
    });

    test('a failed start is reported, not swallowed', () async {
      startReviewError = StateError('no linked repo');

      await inbound(_issueComment(13, '@usectrl review'));

      expect(
        gateway.conversationComments.single.body,
        contains('could not start'),
      );
    });

    test(
      'a thread reply without a mention is a question, never a re-review',
      () async {
        await inbound(
          _reviewComment(15, 'what about the error handling?'),
          isBotThread: true,
        );

        expect(startedReviews, isEmpty);
        expect(messaging.dispatches, isNotEmpty);
      },
    );
  });

  group('label gate', () {
    Future<void> labeled() => bridge.handleLabeledPullRequest(
      workspaceId: _workspaceId,
      owner: 'acme',
      repo: 'app',
      prNumber: 9,
    );

    test(
      'a writing member with push claims the PR and the review runs as them',
      () async {
        gateway.labeller = const GitHubPrActor(
          accountId: _octocatId,
          login: 'octocat',
        );

        await labeled();

        expect(gateway.canPostChecks.single.actingUserId, 'u1');
        expect(gateway.claims.single, (
          kind: 'pull_request',
          id: 9,
          asUserId: 'u1',
        ));
        expect(startedReviews.single.userId, 'u1');
        expect(startedReviews.single.prNumber, 9);
        // A label has no comment to answer.
        expect(gateway.conversationComments, isEmpty);
      },
    );

    test('a labeller who is not a member is ignored', () async {
      gateway.labeller = const GitHubPrActor(
        accountId: _strangerId,
        login: 'stranger',
      );

      await labeled();

      expect(gateway.touchedGitHub, isFalse);
      expect(startedReviews, isEmpty);
    });

    test('a read-only labeller is ignored', () async {
      gateway.labeller = const GitHubPrActor(
        accountId: _viewerId,
        login: 'viewer',
      );

      await labeled();

      expect(gateway.touchedGitHub, isFalse);
      expect(startedReviews, isEmpty);
    });

    test('a labeller without push access is ignored', () async {
      gateway
        ..labeller = const GitHubPrActor(
          accountId: _octocatId,
          login: 'octocat',
        )
        ..canPost = false;

      await labeled();

      expect(gateway.claims, isEmpty);
      expect(startedReviews, isEmpty);
    });

    test('a label another server already claimed does not re-run', () async {
      gateway
        ..labeller = const GitHubPrActor(
          accountId: _octocatId,
          login: 'octocat',
        )
        ..claimResult = GitHubReactionClaim.alreadyClaimed;

      await labeled();

      expect(startedReviews, isEmpty);
    });

    test('no visible labeller: nothing happens', () async {
      await labeled();

      expect(gateway.touchedGitHub, isFalse);
      expect(startedReviews, isEmpty);
    });
  });

  group('question path', () {
    test(
      'posts the question as the member, dispatches to the last agent, and records the reply lane',
      () async {
        messagingRepository.participants = [
          SpaceParticipant(
            id: 'p1',
            spaceId: _spaceId,
            principalId: 'agent-9',
            participantType: PrincipalType.agent,
            role: 'agent',
            joinedAt: DateTime(2026, 1, 1),
          ),
        ];
        messagingRepository.spaceMessages = [_turnMessage('old', 'prior turn')];

        await bridge.handleInboundComment(
          workspaceId: _workspaceId,
          owner: 'acme',
          repo: 'app',
          prNumber: 7,
          prTitle: 'A title',
          comment: _issueComment(31, '@usectrl why does the flaky test fail?'),
        );

        final sent = messaging.userMessages.single;
        expect(sent.spaceId, _spaceId);
        expect(sent.content, 'why does the flaky test fail?');
        expect(sent.senderUserId, 'u1');
        final provenance = sent.metadata?['github'] as Map<String, dynamic>;
        expect(provenance['author_login'], 'octocat');
        expect(provenance['author_id'], _octocatId);
        expect(provenance['pr_number'], 7);
        // The last agent sender answers; nobody had to be added.
        expect(messaging.dispatches.single.agentId, 'agent-9');
        expect(messaging.dispatches.single.requestedBy, 'u1');
        expect(messaging.addedAgents, isEmpty);

        final pending = await _readPending(dbs, 'run-1');
        expect(pending?['v'], 2);
        expect(pending?['kind'], 'issue');
        expect(pending?['asker_login'], 'octocat');
        expect(pending?['asker_user_id'], 'u1');
        expect(pending?['asker_account_id'], _octocatId);
        expect(pending?['bot_login'], _botLogin);
        expect(pending?['app_slug'], 'cc-test');
        expect(pending?['lane'], 'own_app');
      },
    );

    test('@usectrl timeline question dispatches without the mention', () async {
      await inbound(_issueComment(32, '@usectrl what does this change?'));

      expect(gateway.claims.single.id, 32);
      expect(messaging.userMessages.single.content, 'what does this change?');
      expect(messaging.dispatches.single.prompt, 'what does this change?');
    });

    test(
      'a first question on a fresh PR space wakes the coordinator',
      () async {
        await inbound(_issueComment(33, '@usectrl what does this PR do?'));

        expect(messaging.addedAgents.single, (
          spaceId: _spaceId,
          agentId: 'agent-ceo',
        ));
        expect(messaging.dispatches.single.agentId, 'agent-ceo');
        expect(messaging.dispatches.single.prompt, 'what does this PR do?');
      },
    );

    test('a provisioning failure apologizes on the timeline', () async {
      ensureSpaceError = StateError('checkout failed');

      await inbound(_issueComment(34, '@usectrl what does this PR do?'));

      final reply = gateway.conversationComments.single;
      expect(reply.body, contains('could not prepare'));
      expect(reply.actingUserId, 'u1');
      expect(messaging.userMessages, isEmpty);
    });

    test('a refused dispatch is reported on the timeline', () async {
      messaging.dispatchError = StateError('agent gone');

      await inbound(_issueComment(35, '@usectrl what does this PR do?'));

      expect(messaging.userMessages, isNotEmpty);
      expect(
        gateway.conversationComments.single.body,
        contains('could not start an agent'),
      );
      expect(await _readPending(dbs, 'run-1'), isNull);
    });

    test('a thread follow-up records the review reply lane', () async {
      await inbound(
        _reviewComment(36, 'and the migration?'),
        isBotThread: true,
      );

      final pending = await _readPending(dbs, 'run-1');
      expect(pending?['kind'], 'review');
      expect(pending?['parent_comment_id'], 36);
    });
  });

  group('outbound lane', () {
    test(
      'a completed run posts the attributed answer bounded by the asker',
      () async {
        await inbound(_issueComment(41, '@usectrl what does this PR do?'));

        await completeRun('It adds the polling lane.');

        final reply = gateway.conversationComments.last;
        expect(
          reply.body,
          '**Control Center** (for @octocat): It adds the polling lane.',
        );
        expect(reply.actingUserId, 'u1');
        // The pending row is consumed exactly once.
        expect(await _readPending(dbs, 'run-1'), isNull);
      },
    );

    test('a completed thread run replies inside the review thread', () async {
      await inbound(
        _reviewComment(42, 'and the migration?'),
        isBotThread: true,
      );

      await completeRun('Handled in step 3.');

      final reply = gateway.reviewReplies.last;
      expect(reply.parentId, 42);
      expect(
        reply.body,
        '**Control Center** (for @octocat): Handled in step 3.',
      );
      expect(reply.actingUserId, 'u1');
    });

    test(
      'an empty completed turn posts nothing and still consumes the row',
      () async {
        await inbound(_issueComment(43, '@usectrl what does this PR do?'));
        final commentsBefore = gateway.conversationComments.length;

        await completeRun('  ');

        expect(gateway.conversationComments.length, commentsBefore);
        expect(await _readPending(dbs, 'run-1'), isNull);
      },
    );

    test('a run without a pending row is ignored', () async {
      messagingRepository.messagesById['other-run'] = _turnMessage(
        'other-run',
        'unrelated',
      );
      eventBus.publish(
        AgentRunCompleted(
          agentId: 'agent-9',
          workspaceId: _workspaceId,
          conversationId: _spaceId,
          runId: 'other-run',
          occurredAt: DateTime(2026, 8, 26),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(gateway.conversationComments, isEmpty);
      expect(gateway.reviewReplies, isEmpty);
    });

    test('a lane change between ask and reply drops the reply', () async {
      await inbound(_issueComment(44, '@usectrl what does this PR do?'));
      gateway.identityValue = const GitHubConversationIdentity(
        botLogin: _botLogin,
        slug: 'cc-test',
        lane: GitHubLane.connect,
      );

      await completeRun('It adds the polling lane.');

      expect(gateway.conversationComments, isEmpty);
      expect(warnings.single, contains('identity changed'));
      expect(await _readPending(dbs, 'run-1'), isNull);
    });

    test('a different bot between ask and reply drops the reply', () async {
      await inbound(_issueComment(45, '@usectrl what does this PR do?'));
      gateway.identityValue = const GitHubConversationIdentity(
        botLogin: 'other-app[bot]',
        slug: 'other-app',
        lane: GitHubLane.ownApp,
      );

      await completeRun('It adds the polling lane.');

      expect(gateway.conversationComments, isEmpty);
      expect(warnings.single, contains('identity changed'));
    });

    test('an asker who left the workspace gets no post-back', () async {
      await inbound(_issueComment(46, '@usectrl what does this PR do?'));
      members.members = [_member('m2', 'u2', WorkspaceRole.viewer)];
      directory.invalidate(_workspaceId);

      await completeRun('It adds the polling lane.');

      expect(gateway.conversationComments, isEmpty);
      expect(warnings.single, contains('no longer a writing member'));
    });

    test('a pending row from an older build is consumed silently', () async {
      await DaoPendingPrReplyRepository(dbs).save(_workspaceId, 'run-1', {
        'v': 1,
        'owner': 'acme',
        'repo': 'app',
        'pr_number': 7,
        'asker_login': 'octocat',
        'kind': 'issue',
      });

      await completeRun('It adds the polling lane.');

      expect(gateway.conversationComments, isEmpty);
      expect(await _readPending(dbs, 'run-1'), isNull);
    });
  });
}
