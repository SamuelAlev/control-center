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
import 'package:cc_mcp/src/tools/confirm_review_node_tool.dart';
import 'package:flutter_test/flutter_test.dart';

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

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      const Stream.empty();

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

  final Map<String, ChannelMessage> _messages = {};
  final List<Map<String, dynamic>> sentMessages = [];

  void setMessage(ChannelMessage msg) => _messages[msg.id] = msg;

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
  }) async => _messages.values.toList();

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
    String? content,
  }) async {
    final existing = _messages[messageId];
    if (existing != null && metadata != null) {
      _messages[messageId] = existing.copyWith(
        metadata: {...?existing.metadata, ...metadata},
      );
    }
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
    sentMessages.add({'channelId': channelId, 'content': content});
    return '';
  }

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
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => Stream.value([]);

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
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'node_message_id': 'nonexistent',
        'agent_id': 'a-1',
      });

      expect(result.isError, isTrue);
    });

    test('confirms review node', () async {
      repository.setMessage(
        ChannelMessage(
          id: 'msg-1',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'a-1',
          senderType: ChannelSenderType.agent,
          content: 'Bug found',
          messageType: ChannelMessageType.reviewNode,
          metadata: {'confirmedBy': <String>[], 'status': 'open'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-2',
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confirmed_by'], contains('a-2'));
      expect(data['confirmation_count'], 1);
    });

    test('moves to consensus_ready on first peer confirmation', () async {
      repository.setMessage(
        ChannelMessage(
          id: 'msg-1',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'a-1',
          senderType: ChannelSenderType.agent,
          content: 'Bug',
          messageType: ChannelMessageType.reviewNode,
          metadata: {'confirmedBy': <String>[], 'status': 'open'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-2',
      });

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['status'], 'consensus_ready');
    });

    test('refuses self-confirmation by the author', () async {
      repository.setMessage(
        ChannelMessage(
          id: 'msg-1',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'a-1',
          senderType: ChannelSenderType.agent,
          content: 'Bug',
          messageType: ChannelMessageType.reviewNode,
          metadata: {'confirmedBy': <String>[], 'status': 'open'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-1', // same as senderId
      });

      expect(result.isError, isTrue);
    });
  });
}
