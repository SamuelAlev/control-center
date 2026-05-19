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
import 'package:cc_mcp/src/tools/add_review_node_tool.dart';
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

  final List<Map<String, dynamic>> sentMessages = [];

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
    sentMessages.add({
      'channelId': channelId,
      'content': content,
      'senderId': senderId,
      'senderType': senderType,
      'messageType': messageType,
      'metadata': metadata,
      'id': id,
    });
    return '';
  }

  @override
  Stream<List<Channel>> watchChannels() => Stream.value([]);

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
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
    String? content,
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
  group('AddReviewNodeTool', () {
    late _FakeMessagingRepository repository;
    late AddReviewNodeTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = AddReviewNodeTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'add_review_node');
    });

    test('has valid inputSchema with priority and confidence required', () {
      final schema = tool.inputSchema;
      expect(
        schema['required'],
        containsAll([
          'channel_id',
          'sender_id',
          'node_type',
          'content',
          'priority',
          'confidence',
        ]),
      );
      final nodeType =
          (schema['properties'] as Map<String, dynamic>)['node_type']
              as Map<String, dynamic>;
      expect(nodeType['enum'], [
        'bug',
        'suggestion',
        'recommendation',
        'question',
        'ticket',
      ]);
      final priority =
          (schema['properties'] as Map<String, dynamic>)['priority']
              as Map<String, dynamic>;
      expect(priority['enum'], ['p0', 'p1', 'p2', 'p3']);
    });

    test('adds review node with required fields', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'Null pointer on line 42',
        'priority': 'p0',
        'confidence': 0.92,
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['node_type'], 'bug');
      expect(data['priority'], 'p0');
      expect(data['confidence'], 0.92);
      expect(data['status'], 'open');
    });

    test('includes priority and confidence in sent metadata', () async {
      await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'recommendation',
        'content': 'Use const',
        'priority': 'p3',
        'confidence': 0.7,
        'file_path': 'lib/main.dart',
        'line_number': 10,
      });

      expect(repository.sentMessages.length, 1);
      final msg = repository.sentMessages.first;
      expect(msg['messageType'], 'review_node');
      final meta = msg['metadata'] as Map<String, dynamic>;
      expect(meta['filePath'], 'lib/main.dart');
      expect(meta['lineNumber'], 10);
      expect(meta['priority'], 'p3');
      expect(meta['confidence'], 0.7);
      expect(meta.containsKey('severity'), isFalse);
    });

    test('rejects when priority is missing', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'confidence': 0.8,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('priority'));
    });

    test('rejects when priority is invalid', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'priority': 'p4',
        'confidence': 0.8,
      });
      expect(result.isError, isTrue);
    });

    test('rejects when confidence is missing', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'priority': 'p0',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('confidence'));
    });

    test('rejects when confidence is out of range', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'channel_id': 'ch-1',
        'sender_id': 'a-1',
        'node_type': 'bug',
        'content': 'oops',
        'priority': 'p0',
        'confidence': 1.5,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('range'));
    });
  });
}
