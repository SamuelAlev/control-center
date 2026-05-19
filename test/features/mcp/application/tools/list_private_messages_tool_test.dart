import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/mcp/application/tools/list_private_messages_tool.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingRepository implements MessagingRepository {
  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value(
        _channels.where((c) => c.workspaceId == workspaceId).toList(),
      );

  @override
  Future<ChannelMessage?> getMessageById(String messageId) async => null;

  final List<Channel> _channels = [];
  final Map<String, List<ChannelMessage>> _messages = {};

  void addDm(Channel channel, List<ChannelMessage> messages) {
    _channels.add(channel);
    _messages[channel.id] = messages;
  }

  @override
  Stream<List<Channel>> watchChannels() => Stream.value(_channels);

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      Stream.value([]);

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      Stream.value(_messages[channelId] ?? []);

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) => throw UnimplementedError();

  @override
  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> addParticipant(String channelId, String agentId) =>
      throw UnimplementedError();

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async =>
      [];

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
    return '';
  }

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async =>
      _messages[channelId] ?? [];

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
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding) async {}

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(String channelId) async => [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) async => [];
}

void main() {
  group('ListPrivateMessagesTool', () {
    late _FakeMessagingRepository repository;
    late ListPrivateMessagesTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = ListPrivateMessagesTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'list_private_messages');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('requires workspace_id', () async {
      final result = await tool.call({});
      expect(result.isError, isTrue);
    });

    test('returns empty when no DMs exist', () async {
      final result = await tool.call({'workspace_id': 'ws-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['messages'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns messages from DM channels only', () async {
      repository.addDm(
        Channel(
          id: 'dm-1',
          name: '',
          isDm: true,
          workspaceId: 'ws-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        [
          ChannelMessage(
            id: 'msg-1',
            channelId: 'dm-1',
            senderId: 'user',
            senderType: ChannelSenderType.user,
            content: 'Hello agent',
            messageType: ChannelMessageType.text,
            createdAt: DateTime.now(),
          ),
          ChannelMessage(
            id: 'msg-2',
            channelId: 'dm-1',
            senderId: 'agent-1',
            senderType: ChannelSenderType.agent,
            content: 'Hi there',
            messageType: ChannelMessageType.text,
            createdAt: DateTime.now(),
          ),
        ],
      );

      repository.addDm(
        Channel(
          id: 'group-1',
          name: 'Team Chat',
          isDm: false,
          workspaceId: 'ws-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        [
          ChannelMessage(
            id: 'msg-g1',
            channelId: 'group-1',
            senderId: 'user',
            senderType: ChannelSenderType.user,
            content: 'Group message',
            messageType: ChannelMessageType.text,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final result = await tool.call({'workspace_id': 'ws-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      final messages = (data['messages'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(messages.length, 2);
      expect(messages.any((m) => m['channel_id'] == 'dm-1'), isTrue);
      expect(messages.any((m) => m['channel_id'] == 'group-1'), isFalse);
    });

    test('respects limit parameter', () async {
      repository.addDm(
        Channel(
          id: 'dm-1',
          name: '',
          isDm: true,
          workspaceId: 'ws-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        [
          for (var i = 0; i < 10; i++)
            ChannelMessage(
              id: 'msg-$i',
              channelId: 'dm-1',
              senderId: 'user',
              senderType: ChannelSenderType.user,
              content: 'Message $i',
              messageType: ChannelMessageType.text,
              createdAt: DateTime.now(),
            ),
        ],
      );

      final result = await tool.call({'workspace_id': 'ws-1', 'limit': 3});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
