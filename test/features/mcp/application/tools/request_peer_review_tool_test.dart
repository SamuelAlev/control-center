import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/mcp/application/tools/request_peer_review_tool.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingRepository implements MessagingRepository {
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          Stream.value((messages: const <ChannelMessage>[], hasMore: false));

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
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? parentMessageId,
  }) async {
    lastChannelId = channelId;
    lastContent = content;
    lastSenderId = senderId;
    lastSenderType = senderType;
    lastMessageType = messageType;
    lastMetadata = metadata;
    lastId = id;
    lastParentMessageId = parentMessageId;
    sendMessageCallCount++;
    return '';
  }

  // ── Stubs for remaining methods ──

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      Stream.value([]);

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      Stream.value([]);

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();

  @override
  Future<ChannelMessage?> getMessageById(String messageId) async => null;

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async =>
      throw UnimplementedError();

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) async => throw UnimplementedError();

  @override
  Future<void> setChannelMode(
    String channelId,
    ConversationMode mode,
  ) async {}

  @override
  Future<void> addParticipant(String channelId, String agentId) async {}

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async =>
      [];

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async => [];

  @override
  Future<void> markCompacted(List<String> ids) async {}

  @override
  Future<void> deleteChannel(String channelId) async {}

  @override
  Future<void> updateChannelName(String channelId, String name) async {}

  @override
  Future<void> clearChannelMessages(String channelId) async {}

  @override
  Future<void> removeParticipant(String channelId, String agentId) async {}

  @override
  Future<void> updateMessageEmbedding(
    String messageId,
    Uint8List embedding,
  ) async {}

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String channelId,
  ) async => [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({
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

    test('inputSchema has type=object and requires all 5 fields', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        schema['required'],
        unorderedEquals([
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
          'channel_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-reviewer-42',
          'target_agent_id': 'agent-b',
          'question': 'What do you think?',
        });
        expect(messaging.lastSenderId, 'agent-reviewer-42');
      });

      test('verify metadata has peerReviewRequest=true, requester, target', () async {
        await tool.run({
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
      });

      test('verify reply_id is a non-empty string', () async {
        await tool.run({
          'channel_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'What do you think?',
        });
        expect(messaging.lastId, isNotNull);
        expect(messaging.lastId, isNotEmpty);
      });

      test('verify response JSON has reply_id, thread_root, target_agent_id', () async {
        final result = await tool.run({
          'channel_id': 'ch-1',
          'node_message_id': 'node-xyz',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'What do you think?',
        });
        expect(result.isError, isFalse);
        final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['reply_id'], isA<String>());
        expect(data['reply_id'], isNotEmpty);
        expect(data['thread_root'], 'node-xyz');
        expect(data['target_agent_id'], 'agent-b');
      });

      test('reply_id matches the id passed to sendMessage', () async {
        final result = await tool.run({
          'channel_id': 'ch-1',
          'node_message_id': 'node-1',
          'requester_id': 'agent-a',
          'target_agent_id': 'agent-b',
          'question': 'Can you double-check this?',
        });
        final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(data['reply_id'], messaging.lastId);
      });
    });

    // ── Edge cases ──

    test('Empty string channel_id → allowed (passed through)', () async {
      final result = await tool.run({
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
        'channel_id': 'ch-1',
        'node_message_id': 'node-1',
        'requester_id': 'agent-a',
        'target_agent_id': 'agent-b',
        'question': longQuestion,
      });
      expect(result.isError, isFalse);
      expect(messaging.lastContent, '@agent-b $longQuestion');
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['target_agent_id'], 'agent-b');
    });

    test('sendMessage called only once (no extra calls)', () async {
      await tool.run({
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
