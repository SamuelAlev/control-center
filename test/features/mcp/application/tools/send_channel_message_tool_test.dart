import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_mcp/src/tools/send_channel_message_tool.dart';
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

  String? lastChannelId;
  String? lastContent;
  String? lastSenderId;

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
  String? pipelineRunId,
    }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateMessage(String messageId, {Map<String, dynamic>? metadata, String? content}) async {}

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async => [];

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
  Future<bool> channelExists(String channelId) async => true;

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
  group('SendChannelMessageTool', () {
    late _FakeMessagingRepository repository;
    late SendChannelMessageTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = SendChannelMessageTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'send_channel_message');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(
        schema['required'],
        containsAll(['channel_id', 'sender_id', 'content']),
      );
    });

    test('sends message to channel', () async {
      final result = await tool.call({
        'channel_id': 'ch-1',
        'sender_id': 'a-1',
        'content': 'Hello team',
      });

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['channel_id'], 'ch-1');
      expect(data['status'], 'sent');
      expect(repository.lastChannelId, 'ch-1');
      expect(repository.lastContent, 'Hello team');
      expect(repository.lastSenderId, 'a-1');
    });
  });
}
