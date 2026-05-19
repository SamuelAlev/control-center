import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_mcp/src/tools/request_peer_review_tool.dart';
import 'package:test/test.dart';

class _FakeMessagingRepository implements MessagingRepository {
  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async =>
      null;

  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  // Captured sendMessage arguments.
  String? lastChannelId;
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
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    lastChannelId = channelId;
    lastContent = content;
    lastSenderId = senderId;
    lastSenderType = senderType;
    lastMessageType = messageType;
    lastMetadata = metadata;
    lastId = id;
    // Threading removed: the discussion link now rides message metadata.
    lastParentMessageId = metadata?['reviewNodeId'] as String?;
    sendMessageCallCount++;
    return '';
  }

  // ── Stubs for remaining methods ──

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);

  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => Stream.value([]);

  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => Stream.value([]);

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async => null;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async => const [];

  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String> repoIds = const [],
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
  }) async => throw UnimplementedError();

  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) async {}

  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}

  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      true;

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => [];

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {}

  @override
  Future<List<ChannelMessage>> searchInChannel(
    String workspaceId,
    String channelId,
    String query, {
    int limit = 20,
  }) async => const [];

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async => [];

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}

  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {}

  @override
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  ) async {}

  @override
  Future<void> clearChannelMessages(
    String workspaceId,
    String channelId,
  ) async {}

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) async {}

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String channelId,
  ) async => [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];
}

void main() {
  group('RequestPeerReviewTool', () {
    late _FakeMessagingRepository messaging;
    late RequestPeerReviewTool tool;

    setUp(() {
      messaging = _FakeMessagingRepository();
      tool = RequestPeerReviewTool(messaging: messaging);
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
          // Required, not optional: the channel row this tool writes into lives
          // in one workspace's database, so a call without a workspace names
          // nothing the server can find.
          'workspace_id',
          'channel_id',
          'node_message_id',
          'requester_id',
          'target_agent_id',
          'question',
        ]),
      );
    });

    // ── Validation: missing keys ──

    test('Missing channel_id → error', () async {
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
        contains('Missing or invalid argument: channel_id'),
      );
    });

    test('Missing node_message_id → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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

    test('channel_id as int → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'channel_id': 42,
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: channel_id'),
      );
    });

    test('node_message_id as int → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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

    test('channel_id as null → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'channel_id': null,
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Missing or invalid argument: channel_id'),
      );
    });

    test('node_message_id as null → error', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
      test('verify sendMessage called with correct channelId', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-reviews',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        expect(messaging.lastChannelId, 'ch-reviews');
      });

      test('verify content = @target_agent_id the question', () async {
        await tool.run({
          'workspace_id': 'ws-1',
          'channel_id': 'ch-1',
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
          'channel_id': 'ch-1',
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
          'channel_id': 'ch-1',
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
          'channel_id': 'ch-1',
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
          'channel_id': 'ch-1',
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
            'channel_id': 'ch-1',
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
          'channel_id': 'ch-1',
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
            'channel_id': 'ch-1',
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
          'channel_id': 'ch-1',
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

    test('Empty string channel_id → allowed (passed through)', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'channel_id': '',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'What do you think?',
      });
      expect(result.isError, isFalse);
      expect(messaging.lastChannelId, '');
    });

    test('Empty string question → allowed, content is @target ', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
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
        'channel_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': 'Can you double-check this?',
      });
      expect(messaging.sendMessageCallCount, 1);
    });
  });
}
