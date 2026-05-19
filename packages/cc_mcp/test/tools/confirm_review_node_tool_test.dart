import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_mcp/src/tools/confirm_review_node_tool.dart';
import 'package:test/test.dart';

class _FakeMessagingRepository implements MessagingRepository {

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
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

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      null;

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

  final Map<String, Message> _messages = {};
  final List<Map<String, dynamic>> sentMessages = [];

  void setMessage(Message msg) => _messages[msg.id] = msg;

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
  }) async => _messages.values.toList();

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
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
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    sentMessages.add({'spaceId': spaceId, 'content': content});
    return '';
  }

  @override
  Stream<List<Space>> watchSpaces() => Stream.value([]);

  @override
  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    Mode mode,
  ) async {}

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
  }) async {
    throw UnimplementedError();
  }

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
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {}

  Future<void> updateSpaceType(String spaceId, String type) async {}

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {}

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {}

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async => true;

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => [];

  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => Stream.value([]);

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

  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];

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
        'space_id': 'ch-1',
        'node_message_id': 'nonexistent',
        'agent_id': 'a-1',
      });

      expect(result.isError, isTrue);
    });

    test('confirms review node', () async {
      repository.setMessage(
        Message(
          id: 'msg-1',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'a-1',
          senderType: SenderType.agent,
          content: 'Bug found',
          messageType: MessageType.reviewNode,
          metadata: {'confirmedBy': <String>[], 'status': 'open'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
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
        Message(
          id: 'msg-1',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'a-1',
          senderType: SenderType.agent,
          content: 'Bug',
          messageType: MessageType.reviewNode,
          metadata: {'confirmedBy': <String>[], 'status': 'open'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-2',
      });

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['status'], 'consensus_ready');
    });

    test('refuses self-confirmation by the author', () async {
      repository.setMessage(
        Message(
          id: 'msg-1',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'a-1',
          senderType: SenderType.agent,
          content: 'Bug',
          messageType: MessageType.reviewNode,
          metadata: {'confirmedBy': <String>[], 'status': 'open'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'a-1', // same as senderId
      });

      expect(result.isError, isTrue);
    });
  });
}
