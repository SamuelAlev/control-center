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
import 'package:cc_mcp/src/tools/get_channel_messages_tool.dart';
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

  final Map<String, List<Channel>> _channelsByWs = {};

  void setChannels(String workspaceId, List<Channel> channels) {
    _channelsByWs[workspaceId] = channels;
  }

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value(_channelsByWs[workspaceId] ?? const []);

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async => throw UnimplementedError();

  @override
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async => null;

  final Map<String, List<ChannelMessage>> _messages = {};

  void setMessages(String channelId, List<ChannelMessage> msgs) {
    _messages[channelId] = msgs;
  }

  Channel _channel(String id, String workspaceId) => Channel(
    id: id,
    name: id,
    workspaceId: workspaceId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

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
  }) async => _messages[channelId] ?? [];

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);

  @override
  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) async {}

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
  }) async {
    throw UnimplementedError();
  }

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
    return '';
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
    String? content,
  }) async {}

  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => Stream.value(_messages[channelId] ?? []);

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}

  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {}

  Future<void> updateChannelType(String channelId, String type) async {}

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
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => Stream.value([]);

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
  group('GetChannelMessagesTool', () {
    late _FakeMessagingRepository repository;
    late GetChannelMessagesTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = GetChannelMessagesTool(repository: repository);
      // ch-1 belongs to workspace ws-1 (the caller's workspace).
      repository.setChannels('ws-1', [repository._channel('ch-1', 'ws-1')]);
    });

    test('has correct name', () {
      expect(tool.name, 'get_channel_messages');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['required'], ['workspace_id', 'channel_id']);
    });

    test('rejects missing workspace_id', () async {
      final result = await tool.call({'channel_id': 'ch-1'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
    });

    test('rejects a channel from a different workspace (isolation)', () async {
      // ch-2 lives in ws-2; a caller bound to ws-1 must NOT read it.
      repository.setMessages('ch-2', [
        ChannelMessage(
          id: 'm-x',
          channelId: 'ch-2',
          conversationId: 'ch-2',
          senderId: 'agent-9',
          senderType: ChannelSenderType.agent,
          content: 'secret',
          messageType: ChannelMessageType.text,
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-2',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('different workspace'));
    });

    test('returns empty list for channel with no messages', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
      });

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['messages'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns messages for channel', () async {
      repository.setMessages('ch-1', [
        ChannelMessage(
          id: 'm-1',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: 'Found a bug',
          messageType: ChannelMessageType.reviewNode,
          metadata: {'severity': 'high'},
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
      });

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(
        ((data['messages'] as List<dynamic>)[0]
            as Map<String, dynamic>)['content'],
        'Found a bug',
      );
      expect(
        ((data['messages'] as List<dynamic>)[0]
            as Map<String, dynamic>)['sender_id'],
        'agent-1',
      );
    });

    test('respects limit', () async {
      repository.setMessages(
        'ch-1',
        List.generate(
          10,
          (i) => ChannelMessage(
            id: 'm-$i',
            channelId: 'ch-1',
            conversationId: 'ch-1',
            senderId: 'agent-1',
            senderType: ChannelSenderType.agent,
            content: 'Message $i',
            messageType: ChannelMessageType.text,
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'limit': 3,
      });

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
