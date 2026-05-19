import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

const _botLogin = 'cc-test[bot]';
const _workspaceId = 'ws1';
const _spaceId = 'space-1';

/// Records every GitHub write the bridge can make; `failAcks` makes the
/// reaction calls throw, exercising the ack-is-best-effort rule.
class _FakeGateway implements GitHubPrConversationGateway {
  _FakeGateway({this.failAcks = false});

  final bool failAcks;
  final ackedIssueComments = <int>[];
  final ackedReviewComments = <int>[];
  final conversationComments = <({int prNumber, String body})>[];
  final reviewReplies = <({int prNumber, int parentId, String body})>[];

  @override
  Future<String> botLogin() async => _botLogin;

  @override
  Future<void> acknowledgeIssueComment(
    String owner,
    String repo,
    int commentId,
  ) async {
    if (failAcks) {
      throw StateError('ack unavailable');
    }
    ackedIssueComments.add(commentId);
  }

  @override
  Future<void> acknowledgeReviewComment(
    String owner,
    String repo,
    int commentId,
  ) async {
    if (failAcks) {
      throw StateError('ack unavailable');
    }
    ackedReviewComments.add(commentId);
  }

  @override
  Future<void> postConversationComment(
    String owner,
    String repo, {
    required int prNumber,
    required String body,
  }) async {
    conversationComments.add((prNumber: prNumber, body: body));
  }

  @override
  Future<void> replyInReviewThread(
    String owner,
    String repo, {
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {
    reviewReplies.add((
      prNumber: prNumber,
      parentId: parentCommentId,
      body: body,
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

class _FakeCredentialsStore implements UserCredentialsStore {
  _FakeCredentialsStore(this.tokens);

  final Map<String, ProviderToken?> tokens;

  @override
  Future<ProviderToken?> forgeToken(String userId, ForgeHost forge) async =>
      tokens[userId];

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
        ({
          String spaceId,
          String agentId,
          String prompt,
          String? requestedBy,
        })
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
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
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
  String login = 'octocat',
  bool bot = false,
}) => InboundGitHubPrComment(
  id: id,
  body: body,
  authorLogin: login,
  authorIsBot: bot,
  isReviewComment: false,
);

InboundGitHubPrComment _reviewComment(
  int id,
  String body, {
  String login = 'octocat',
  bool bot = false,
}) => InboundGitHubPrComment(
  id: id,
  body: body,
  authorLogin: login,
  authorIsBot: bot,
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

Future<Map<String, dynamic>?> _readPending(
  WorkspaceDatabaseManager dbs,
  String runId,
) async {
  final raw = await dbs.of(_workspaceId).cacheDao.read(
    _workspaceId,
    GitHubPrConversationBridge.pendingReplyCacheKind,
    runId,
  );
  if (raw == null) {
    return null;
  }
  final decoded = jsonDecode(raw);
  return decoded is Map<String, dynamic> ? decoded : null;
}

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _FakeGateway gateway;
  late _FakeMessagingPort messaging;
  late _FakeMessagingRepository messagingRepository;
  late DomainEventBus eventBus;
  late GitHubPrConversationBridge bridge;
  final startedReviews =
      <({String workspaceId, String owner, String repo, int prNumber})>[];
  Object? startReviewError;
  String? ensuredSpaceId = _spaceId;
  Object? ensureSpaceError;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, _workspaceId);
    gateway = _FakeGateway();
    messaging = _FakeMessagingPort();
    messagingRepository = _FakeMessagingRepository();
    eventBus = DomainEventBus();
    startedReviews.clear();
    startReviewError = null;
    ensuredSpaceId = _spaceId;
    ensureSpaceError = null;
    bridge = GitHubPrConversationBridge(
      gateway: gateway,
      loginDirectory: GitHubLoginDirectory(
        members: _FakeMembershipRepository([
          WorkspaceMember(
            id: 'm1',
            workspaceId: _workspaceId,
            userId: 'u1',
            role: WorkspaceRole.admin,
            joinedAt: DateTime(2026, 1, 1),
          ),
          WorkspaceMember(
            id: 'm2',
            workspaceId: _workspaceId,
            userId: 'u2',
            role: WorkspaceRole.viewer,
            joinedAt: DateTime(2026, 1, 2),
          ),
        ]),
        credentials: _FakeCredentialsStore({
          'u1': const ProviderToken(accessToken: 't', accountLogin: 'octocat'),
          'u2': const ProviderToken(accessToken: 't', accountLogin: 'viewer'),
        }),
      ),
      messaging: messaging,
      messagingRepository: messagingRepository,
      workspaceDbs: dbs,
      startReview:
          ({
            required workspaceId,
            required owner,
            required repo,
            required prNumber,
          }) async {
            if (startReviewError != null) {
              throw startReviewError!;
            }
            startedReviews.add((
              workspaceId: workspaceId,
              owner: owner,
              repo: repo,
              prNumber: prNumber,
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
    )..start();
  });

  tearDown(() async {
    await bridge.stop();
  });

  group('mention matching', () {
    test('matches the exact bot login, case-insensitively', () {
      expect(
        GitHubPrConversationBridge.mentionsBot(
          'hey @CC-TEST[bot]!',
          _botLogin,
        ),
        isTrue,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot(
          '(@cc-test[bot]: go)',
          _botLogin,
        ),
        isTrue,
      );
    });

    test('matches the bare slug — the [bot] suffix is optional to type', () {
      expect(
        GitHubPrConversationBridge.mentionsBot('hey @cc-test!', _botLogin),
        isTrue,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('@CC-TEST: why?', _botLogin),
        isTrue,
      );
    });

    test('strips a bare-slug mention cleanly, and a full one entirely', () {
      expect(
        GitHubPrConversationBridge.stripMention('@cc-test why?', _botLogin),
        'why?',
      );
      // The full login is preferred for stripping so the bracket suffix
      // never survives into the question text.
      expect(
        GitHubPrConversationBridge.stripMention(
          '@cc-test[bot] why?',
          _botLogin,
        ),
        'why?',
      );
    });

    test('rejects longer logins and unaddressed text', () {
      expect(
        GitHubPrConversationBridge.mentionsBot('@cc-test[bots] hi', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('@cc-tests hi', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot(
          'cc-test[bot] without at',
          _botLogin,
        ),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('@someone-else hi', _botLogin),
        isFalse,
      );
      expect(
        GitHubPrConversationBridge.mentionsBot('plain text', ''),
        isFalse,
      );
    });

    test('strips the mention for the command text', () {
      expect(
        GitHubPrConversationBridge.stripMention(
          '@cc-test[bot] why is this failing?',
          _botLogin,
        ),
        'why is this failing?',
      );
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

  group('loop guard', () {
    test('a bot-authored comment is dropped before anything happens', () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(1, '@$_botLogin review', bot: true),
      );

      expect(gateway.ackedIssueComments, isEmpty);
      expect(messaging.dispatches, isEmpty);
      expect(gateway.conversationComments, isEmpty);
      expect(startedReviews, isEmpty);
    });
  });

  group('review command', () {
    test('a bare mention starts the review and replies on the timeline',
        () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(11, '@$_botLogin'),
      );

      expect(startedReviews.single,
          (workspaceId: _workspaceId, owner: 'acme', repo: 'app', prNumber: 7));
      expect(gateway.ackedIssueComments, [11]);
      expect(
        gateway.conversationComments.single.body,
        contains('Review started'),
      );
      expect(gateway.conversationComments.single.body, contains('@octocat'));
      expect(messaging.userMessages, isEmpty);
    });

    test('an explicit review word behaves the same', () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _reviewComment(12, '@$_botLogin review'),
      );

      expect(startedReviews.single.prNumber, 7);
      // A review-comment mention replies in its thread, not on the timeline.
      expect(gateway.reviewReplies.single.parentId, 12);
      expect(gateway.conversationComments, isEmpty);
    });

    test('a failed start is reported, not swallowed', () async {
      startReviewError = StateError('no linked repo');

      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(13, '@$_botLogin review'),
      );

      expect(
        gateway.conversationComments.single.body,
        contains('could not start'),
      );
    });

    test('a failed ack does not block handling', () async {
      gateway = _FakeGateway(failAcks: true);
      final resilient = GitHubPrConversationBridge(
        gateway: gateway,
        loginDirectory: GitHubLoginDirectory(
          members: _FakeMembershipRepository(const []),
          credentials: _FakeCredentialsStore(const {}),
        ),
        messaging: messaging,
        messagingRepository: messagingRepository,
        workspaceDbs: dbs,
        startReview:
            ({
              required workspaceId,
              required owner,
              required repo,
              required prNumber,
            }) async {
          startedReviews.add((
            workspaceId: workspaceId,
            owner: owner,
            repo: repo,
            prNumber: prNumber,
          ));
          return {'status': 'started'};
        },
        ensureSpace:
            ({
              required workspaceId,
              required repoFullName,
              required prNumber,
              required title,
            }) async => ensuredSpaceId,
        defaultAnswerer: (workspaceId) async => 'agent-ceo',
        eventBus: eventBus,
      );

      // No member is connected → the gate refuses, but the ack failure did
      // not stop the comment from being processed at all.
      await resilient.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(14, '@$_botLogin review'),
      );

      expect(gateway.conversationComments.single.body,
          contains('do not know who you are'));
    });

    test('a thread reply without a mention is a question, never a re-review',
        () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _reviewComment(15, 'what about the error handling?'),
        isBotThread: true,
      );

      expect(startedReviews, isEmpty);
      expect(messaging.dispatches, isNotEmpty);
    });
  });

  group('membership gate', () {
    test('an unmapped login is refused and nothing enters the workspace',
        () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(
          21,
          '@$_botLogin what do you think?',
          login: 'stranger',
        ),
      );

      expect(
        gateway.conversationComments.single.body,
        contains('do not know who you are'),
      );
      expect(messaging.userMessages, isEmpty);
      expect(messaging.dispatches, isEmpty);
    });

    test('a read-only member is refused with the role named', () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(23, '@$_botLogin review', login: 'viewer'),
      );

      expect(gateway.conversationComments.single.body, contains('read-only'));
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
        comment: _issueComment(31, '@$_botLogin why does the flaky test fail?'),
      );

      final sent = messaging.userMessages.single;
      expect(sent.spaceId, _spaceId);
      expect(sent.content, 'why does the flaky test fail?');
      expect(sent.senderUserId, 'u1');
      final provenance = sent.metadata?['github'] as Map<String, dynamic>;
      expect(provenance['author_login'], 'octocat');
      expect(provenance['pr_number'], 7);
      // The last agent sender answers; nobody had to be added.
      expect(messaging.dispatches.single.agentId, 'agent-9');
      expect(messaging.dispatches.single.requestedBy, 'u1');
      expect(messaging.addedAgents, isEmpty);

      final pending = await _readPending(dbs, 'run-1');
      expect(pending, isNotNull);
      expect(pending?['kind'], 'issue');
      expect(pending?['asker_login'], 'octocat');
    });

    test('a first question on a fresh PR space wakes the coordinator',
        () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(33, '@$_botLogin what does this PR do?'),
      );

      expect(messaging.addedAgents.single, (spaceId: _spaceId, agentId: 'agent-ceo'));
      expect(messaging.dispatches.single.agentId, 'agent-ceo');
      expect(messaging.dispatches.single.prompt, 'what does this PR do?');
    });

    test('a provisioning failure apologizes on the timeline', () async {
      ensureSpaceError = StateError('checkout failed');

      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(34, '@$_botLogin what does this PR do?'),
      );

      expect(
        gateway.conversationComments.single.body,
        contains('could not prepare'),
      );
      expect(messaging.userMessages, isEmpty);
    });

    test('a refused dispatch is reported on the timeline', () async {
      messaging.dispatchError = StateError('agent gone');

      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(35, '@$_botLogin what does this PR do?'),
      );

      expect(messaging.userMessages, isNotEmpty);
      expect(
        gateway.conversationComments.single.body,
        contains('could not start an agent'),
      );
      expect(await _readPending(dbs, 'run-1'), isNull);
    });

    test('a thread follow-up records the review reply lane', () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _reviewComment(36, 'and the migration?'),
        isBotThread: true,
      );

      final pending = await _readPending(dbs, 'run-1');
      expect(pending?['kind'], 'review');
      expect(pending?['parent_comment_id'], 36);
    });
  });

  group('outbound lane', () {
    test('a completed run posts the answer on the timeline, @-addressed',
        () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(41, '@$_botLogin what does this PR do?'),
      );

      messagingRepository.messagesById['run-1'] = _turnMessage(
        'run-1',
        'It adds the polling lane.',
      );
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

      expect(gateway.conversationComments.last.body,
          '@octocat It adds the polling lane.');
      // The pending row is consumed exactly once.
      expect(await _readPending(dbs, 'run-1'), isNull);
    });

    test('a completed thread run replies inside the review thread', () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _reviewComment(42, 'and the migration?'),
        isBotThread: true,
      );

      messagingRepository.messagesById['run-1'] = _turnMessage(
        'run-1',
        'Handled in step 3.',
      );
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

      final reply = gateway.reviewReplies.last;
      expect(reply.parentId, 42);
      expect(reply.body, 'Handled in step 3.');
    });

    test('an empty completed turn posts nothing and still consumes the row',
        () async {
      await bridge.handleInboundComment(
        workspaceId: _workspaceId,
        owner: 'acme',
        repo: 'app',
        prNumber: 7,
        prTitle: 'T',
        comment: _issueComment(43, '@$_botLogin what does this PR do?'),
      );
      final commentsBefore = gateway.conversationComments.length;

      messagingRepository.messagesById['run-1'] = _turnMessage('run-1', '  ');
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

      expect(gateway.conversationComments.length, commentsBefore);
      expect(await _readPending(dbs, 'run-1'), isNull);
    });

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
  });
}
