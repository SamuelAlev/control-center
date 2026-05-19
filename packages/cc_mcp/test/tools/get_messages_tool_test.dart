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
import 'package:cc_mcp/src/tools/get_messages_tool.dart';
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

  final Map<String, List<Space>> _spacesByWs = {};

  void setSpaces(String workspaceId, List<Space> spaces) {
    _spacesByWs[workspaceId] = spaces;
  }

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value(_spacesByWs[workspaceId] ?? const []);

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async => throw UnimplementedError();

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      null;

  final Map<String, List<Message>> _messages = {};

  void setMessages(String spaceId, List<Message> msgs) {
    _messages[spaceId] = msgs;
  }

  Space _space(String id, String workspaceId) => Space(
    id: id,
    name: id,
    workspaceId: workspaceId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

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
  }) async => _messages[spaceId] ?? [];

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
    return '';
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
    String? content,
  }) async {}

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
  ) => Stream.value(_messages[spaceId] ?? []);

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
  group('GetMessagesTool', () {
    late _FakeMessagingRepository repository;
    late GetSpaceMessagesTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = GetSpaceMessagesTool(repository: repository);
      // ch-1 belongs to workspace ws-1 (the caller's workspace).
      repository.setSpaces('ws-1', [repository._space('ch-1', 'ws-1')]);
    });

    test('has correct name', () {
      expect(tool.name, 'get_messages');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['required'], ['workspace_id', 'space_id']);
    });

    test('rejects missing workspace_id', () async {
      final result = await tool.call({'space_id': 'ch-1'});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
    });

    test('rejects a space from a different workspace (isolation)', () async {
      // ch-2 lives in ws-2; a caller bound to ws-1 must NOT read it.
      repository.setMessages('ch-2', [
        Message(
          id: 'm-x',
          spaceId: 'ch-2',
          conversationId: 'ch-2',
          senderId: 'agent-9',
          senderType: SenderType.agent,
          content: 'secret',
          messageType: MessageType.text,
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-2',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('different workspace'));
    });

    test('returns empty list for space with no messages', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
      });

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['messages'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns messages for space', () async {
      repository.setMessages('ch-1', [
        Message(
          id: 'm-1',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'agent-1',
          senderType: SenderType.agent,
          content: 'Found a bug',
          messageType: MessageType.reviewNode,
          metadata: {'severity': 'high'},
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
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
          (i) => Message(
            id: 'm-$i',
            spaceId: 'ch-1',
            conversationId: 'ch-1',
            senderId: 'agent-1',
            senderType: SenderType.agent,
            content: 'Message $i',
            messageType: MessageType.text,
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'limit': 3,
      });

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
