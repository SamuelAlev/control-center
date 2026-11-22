import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/request_peer_review_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

/// The kit the current test delivers through.
late PeerKit _kit;

class _FakeMessagingRepository implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}
  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      getMessages(workspaceId, spaceId);

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;

  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <Message>[], hasMore: false));

  // Captured sendMessage arguments.
  String? lastSpaceId;
  String? lastContent;
  String? lastSenderId;
  String? lastSenderType;
  String? lastMessageType;
  Map<String, dynamic>? lastMetadata;
  String? lastId;
  String? lastParentMessageId;

  int sendMessageCallCount = 0;

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    lastSpaceId = spaceId;
    lastContent = content;
    lastSenderId = senderId;
    lastSenderType = senderType;
    lastMessageType = messageType;
    lastMetadata = metadata;
    lastId = id;
    // Threading removed: the discussion link now rides message metadata.
    lastParentMessageId = metadata?['reviewNodeId'] as String?;
    sendMessageCallCount++;
    final messageId = id ?? 'm-$sendMessageCallCount';
    if (spaceId.isNotEmpty) {
      _kit.conversation('c-$spaceId', spaceId: spaceId, workspaceId: workspaceId);
      _kit.messages[messageId] = Message(
        id: messageId,
        spaceId: spaceId,
        conversationId: 'c-$spaceId',
        senderId: senderId,
        senderType: SenderType.agent,
        content: content,
        messageType: MessageType.text,
        createdAt: _kit.now,
      );
    }
    return messageId;
  }

  // ── Stubs for remaining methods ──

  @override
  Stream<List<Space>> watchSpaces() => Stream.value([]);

  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => Stream.value([]);

  @override
  Future<List<String>?> spaceRepoSelection(
    String workspaceId,
    String spaceId,
  ) async => null;

  @override
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  ) async => const {};

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) async {}

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => Stream.value([]);

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      _kit.messages[messageId];

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async => const [];

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) async => throw UnimplementedError();

  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    Mode mode,
  ) async {}

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}

  bool hasSpace = true;

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      hasSpace;

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => [];

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {}

  @override
  Future<List<Message>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit = 20,
  }) async => const [];

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => [];

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {}

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {}

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) async {}

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}

  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async => [];

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

void main() {
  group('RequestPeerReviewTool', () {
    late _FakeMessagingRepository messaging;
    late RequestPeerReviewTool tool;

    setUp(() async {
      _kit = PeerKit()
        ..agent('agent-a', 'Ada')
        ..agent('agent-b', 'reviewer')
        ..conversation('c-sp-a', spaceId: 'sp-a');
      messaging = _FakeMessagingRepository();
      tool = _InRun(
        agents: _OneAgent(),
        messaging: messaging,
        service: _openGate(),
        peerAsks: _kit.service,
        rateLimiter: PairRateLimiter(),
      );
      await _kit.start();
    });

    test('a review wakes the reviewer, then its answer wakes the '
        'requester', () async {
      _kit.run(
        'run-a',
        agentId: 'agent-a',
        conversationId: 'c-sp-a',
        requester: 'user-1',
      );
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'Is the retry bounded?',
      });
      expect(result.isError, isFalse);
      final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(body['status'], 'pending');
      final reviewer = _kit.dispatched.single;
      expect(reviewer.agentId, 'agent-b');
      expect(reviewer.conversationId, 'c-ch-1');
      expect(reviewer.wakeContext.wakeReason, WakeReason.peerMessage);
      expect(reviewer.requestedByUserId, isNull);
      final ask = _kit.asks.all('ws-1').single;
      expect(ask.kind, PeerAskKind.review);

      await _kit.finish('run-1', answer: 'Bounded at five tries.');
      await _kit.deliver();

      final requester = _kit.dispatched.last;
      expect(requester.agentId, 'agent-a');
      expect(requester.conversationId, 'c-sp-a');
      expect(requester.wakeContext.wakeReason, WakeReason.peerReply);
      expect(requester.requestedByUserId, 'user-1');
      expect(_kit.asks.all('ws-1').single.status, PeerAskStatus.answered);
    });

    test('missing or foreign space does not request review', () async {
      messaging.hasSpace = false;
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'foreign',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('different workspace'));
      expect(messaging.sendMessageCallCount, 0);
    });

    // ── Metadata ──

    test('name is request_peer_review', () {
      expect(tool.name, 'request_peer_review');
    });

    test('description is non-empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema requires the workspace alongside its 5 fields', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        schema['required'],
        unorderedEquals([
          // Required, not optional: the space row this tool writes into lives
          // in one workspace's database, so a call without a workspace names
          // nothing the server can find.
          'workspace_id',
          'space_id',
          'node_message_id',
          'requester_id',
          'target_agent_id',
          'question',
        ]),
      );
    });

    // ── Validation: missing keys ──

    test('Missing space_id → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: space_id'),
      );
    });

    test('Missing node_message_id → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: node_message_id'),
      );
    });

    test('Missing requester_id → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: requester_id'),
      );
    });

    test('Missing target_agent_id → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: target_agent_id'),
      );
    });

    test('Missing question → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: question'),
      );
    });

    // ── Validation: wrong type (int) ──

    test('space_id as int → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 42,
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: space_id'),
      );
    });

    test('node_message_id as int → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 42,
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: node_message_id'),
      );
    });

    test('requester_id as int → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 42,
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: requester_id'),
      );
    });

    test('target_agent_id as int → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 42,
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: target_agent_id'),
      );
    });

    test('question as int → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 42,
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: question'),
      );
    });

    // ── Validation: null value ──

    test('space_id as null → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': null,
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: space_id'),
      );
    });

    test('node_message_id as null → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': null,
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: node_message_id'),
      );
    });

    test('requester_id as null → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': null,
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: requester_id'),
      );
    });

    test('target_agent_id as null → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': null,
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: target_agent_id'),
      );
    });

    test('question as null → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': null,
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: question'),
      );
    });

    // ── Success: sendMessage arguments ──

    group('Success', () {
      test('verify sendMessage called with correct spaceId', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-reviews',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        expect(messaging.lastSpaceId, 'ch-reviews');
      });

      test('verify content = @target_agent_id the question', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        expect(messaging.lastContent, '@agent-b Can you double-check this?');
      });

      test('verify senderType = agent', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        expect(messaging.lastSenderType, 'agent');
      });

      test('verify messageType = text', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        expect(messaging.lastMessageType, 'text');
      });

      test('verify parentMessageId = node_message_id', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'node_message_id': 'node-abc-123',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        expect(messaging.lastParentMessageId, 'node-abc-123');
      });

      test('verify senderId = requester_id', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-reviewer-42',
          'target_agent_id': 'agent-b',
          'question': 'What do you think?',
        });
        expect(messaging.lastSenderId, 'agent-reviewer-42');
      });

      test(
        'verify metadata has peerReviewRequest=true, requester, target',
        () async {
          await tool.run({
            'workspace_id': 'ws-1',
            'space_id': 'ch-1',
            'node_message_id': 'node-1',
            'requester_id': 'agent-a',
            'target_agent_id': 'agent-b',
            'question': 'Can you double-check this?',
          });
          final metadata = messaging.lastMetadata;
          expect(metadata, isNotNull);
          expect(metadata!['peerReviewRequest'], isTrue);
          expect(metadata['requester'], 'agent-a');
          expect(metadata['target'], 'agent-b');
        },
      );

      test('verify reply_id is a non-empty string', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'What do you think?',
        });
        expect(messaging.lastId, isNotNull);
        expect(messaging.lastId, isNotEmpty);
      });

      test(
        'verify response JSON has reply_id, review_node_id, target_agent_id',
        () async {
          final result = await tool.run({
            'workspace_id': 'ws-1',
            'space_id': 'ch-1',
            'node_message_id': 'node-xyz',
            'requester_id': 'agent-a',
            'target_agent_id': 'agent-b',
            'question': 'What do you think?',
          });
          expect(result.isError, isFalse);
          final data =
              jsonDecode(result.content.first.text) as Map<String, dynamic>;
          expect(data['reply_id'], isA<String>());
          expect(data['reply_id'], isNotEmpty);
          expect(data['review_node_id'], 'node-xyz');
          expect(data['target_agent_id'], 'agent-b');
        },
      );

      test('reply_id matches the id passed to sendMessage', () async {
        final result = await tool.run({
          'workspace_id': 'ws-1',
          'space_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['reply_id'], messaging.lastId);
      });
    });

    // ── Edge cases ──

    test('Empty string space_id → posted, but nobody is woken', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': '',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('could not be read'));
      expect(messaging.lastSpaceId, '');
      expect(_kit.dispatched, isEmpty);
    });

    test('Empty string question → allowed, content is @target ', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': '',
      });
      expect(result.isError, isFalse);
      expect(messaging.lastContent, '@agent-b ');
    });

    test('Very long question (500 chars) → works', () async {
      final longQuestion = 'x' * 500;
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': longQuestion,
      });
      expect(result.isError, isFalse);
      expect(messaging.lastContent, '@agent-b $longQuestion');
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['target_agent_id'], 'agent-b');
    });

    test('sendMessage called only once (no extra calls)', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'Can you double-check this?',
      });
      expect(messaging.sendMessageCallCount, 1);
    });
  });
}

/// A gate that admits every hand-off: both agents act with approval, no
/// budget stop. Gate refusals are covered in `peer_tools_gate_test.dart`.
TicketWorkflowService _openGate() => TicketWorkflowService(
  repository: _NoTickets(),
  eventBus: DomainEventBus(),
  resolveEffectiveAutonomy:
      ({required workspaceId, required agentId, spaceId}) async =>
          AutonomyLevel.actWithApproval,
  resolveRemainingBudgetMicros:
      ({required workspaceId, required agentId}) async => null,
);

class _NoTickets implements TicketRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The tool as an agent run calls it: the requester's run `run-a` in
/// conversation `c-sp-a`, attested.
class _InRun extends RequestPeerReviewTool {
  _InRun({
    required super.agents,
    required super.messaging,
    required super.service,
    required super.peerAsks,
    required super.rateLimiter,
  });

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) {
    final requester = arguments['requester_id'];
    if (requester is! String || requester.isEmpty) {
      return super.run(arguments);
    }
    return callForRun(
      arguments,
      runScope(
        agentId: requester,
        runId: 'run-a',
        conversationId: 'c-sp-a',
        workspaceId: 'ws-1',
      ),
    );
  }
}

/// The review target every case names: `agent-b` of `ws-1`.
class _OneAgent implements AgentRepository {
  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => Stream.value([
    if (workspaceId == 'ws-1')
      Agent(
        id: 'agent-b',
        name: 'reviewer',
        title: 'Reviewer',
        agentMdPath: 'ws-1/agents/reviewer/AGENTS.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2025),
      ),
  ]);

  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      _kit.agents[id]?.workspaceId == workspaceId ? _kit.agents[id] : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
