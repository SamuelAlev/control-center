import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/mcp/application/tools/confirm_review_node_tool.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingRepository implements MessagingRepository {
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<ChannelMessage?> getMessageById(String messageId) async => null;

  final Map<String, ChannelMessage> _messages = {};
  final List<Map<String, dynamic>> sentMessages = [];

  void setMessage(ChannelMessage msg) => _messages[msg.id] = msg;

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async =>
      _messages.values.toList();

  @override
  Future<void> updateMessage(String messageId, {Map<String, dynamic>? metadata, String? content}) async {
    final existing = _messages[messageId];
    if (existing != null && metadata != null) {
      _messages[messageId] = existing.copyWith(
        metadata: {...?existing.metadata, ...metadata},
      );
    }
  }

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
    sentMessages.add({'channelId': channelId, 'content': content});
    return '';
  }

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);

  @override
  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      Stream.value([]);

  @override
  Future<void> markCompacted(List<String> ids) async {}

  @override
  Future<void> deleteChannel(String channelId) async {}

  Future<void> updateChannelType(String channelId, String type) async {}

  @override
  Future<void> updateChannelName(String channelId, String name) async {}

  @override
  Future<void> clearChannelMessages(String channelId) async {}

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addParticipant(String channelId, String agentId) async {}

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async => [];

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      Stream.value([]);

  @override
  Future<void> removeParticipant(String channelId, String agentId) async {}

  @override
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding) async {}

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(String channelId) async => [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) async => [];
}

void main() {
  group('ConfirmReviewNodeTool', () {
    late _FakeMessagingRepository repository;
    late ConfirmReviewNodeTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = ConfirmReviewNodeTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'confirm_review_node');
    });

    test('returns error when node not found', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'node_message_id': 'nonexistent',
        'agent_id': 'a-1',
      });

      expect(result.isError, isTrue);
    });

    test('confirms review node', () async {
      repository.setMessage(ChannelMessage(
        id: 'msg-1',
        channelId: 'ch-1',
        senderId: 'a-1',
        senderType: ChannelSenderType.agent,
        content: 'Bug found',
        messageType: ChannelMessageType.reviewNode,
        metadata: {'confirmedBy': <String>[], 'status': 'open'},
        createdAt: DateTime(2026, 1, 1),
      ));

      final result = await tool.call({
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-2',
      });

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confirmed_by'], contains('a-2'));
      expect(data['confirmation_count'], 1);
    });

    test('moves to consensus_ready on first peer confirmation', () async {
      repository.setMessage(ChannelMessage(
        id: 'msg-1',
        channelId: 'ch-1',
        senderId: 'a-1',
        senderType: ChannelSenderType.agent,
        content: 'Bug',
        messageType: ChannelMessageType.reviewNode,
        metadata: {'confirmedBy': <String>[], 'status': 'open'},
        createdAt: DateTime(2026, 1, 1),
      ));

      final result = await tool.call({
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-2',
      });

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['status'], 'consensus_ready');
    });

    test('refuses self-confirmation by the author', () async {
      repository.setMessage(ChannelMessage(
        id: 'msg-1',
        channelId: 'ch-1',
        senderId: 'a-1',
        senderType: ChannelSenderType.agent,
        content: 'Bug',
        messageType: ChannelMessageType.reviewNode,
        metadata: {'confirmedBy': <String>[], 'status': 'open'},
        createdAt: DateTime(2026, 1, 1),
      ));

      final result = await tool.call({
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-1', // same as senderId
      });

      expect(result.isError, isTrue);
    });
  });
}
