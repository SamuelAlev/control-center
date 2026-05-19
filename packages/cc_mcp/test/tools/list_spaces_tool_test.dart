import 'dart:async';
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
import 'package:cc_mcp/src/tools/list_spaces_tool.dart';
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
      Stream.value(_spaces.where((c) => c.workspaceId == workspaceId).toList());

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

  final List<Space> _spaces = [];
  final _controller = StreamController<List<Space>>.broadcast();

  void addSpace(Space c) {
    _spaces.add(c);
    _controller.add(List.unmodifiable(_spaces));
  }

  @override
  Stream<List<Space>> watchSpaces() {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_spaces)));
    return _controller.stream;
  }

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
    SpaceKind kind = SpaceKind.topic,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind origin = SpaceKind.topic,
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
  }) async => [];

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

  void dispose() => _controller.close();

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
  group('ListSpacesTool', () {
    late _FakeMessagingRepository repository;
    late ListSpacesTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = ListSpacesTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'list_spaces');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        ((schema['properties'] as Map<String, dynamic>)['workspace_id']
            as Map<String, dynamic>)['type'],
        'string',
      );
    });

    test('requires workspace_id', () async {
      final result = await tool.call({});
      expect(result.isError, isTrue);
    });

    test('returns empty list when no spaces', () async {
      final result = await tool.call({'workspace_id': 'ws-1'});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['spaces'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns the workspace\'s spaces', () async {
      repository.addSpace(
        Space(
          id: 'ch-1',
          name: 'review-1',
          workspaceId: 'ws-1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(
        ((data['spaces'] as List<dynamic>)[0] as Map<String, dynamic>)['name'],
        'review-1',
      );
    });

    test('filters by workspace_id', () async {
      repository.addSpace(
        Space(
          id: 'ch-1',
          name: 'review-1',
          workspaceId: 'ws-1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      repository.addSpace(
        Space(
          id: 'ch-2',
          name: 'review-2',
          workspaceId: 'ws-2',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(
        ((data['spaces'] as List<dynamic>)[0] as Map<String, dynamic>)['id'],
        'ch-1',
      );
    });

    test('respects limit', () async {
      for (var i = 0; i < 10; i++) {
        repository.addSpace(
          Space(
            id: 'ch-$i',
            name: 'space-$i',
            workspaceId: 'ws-1',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
      }

      final result = await tool.call({'workspace_id': 'ws-1', 'limit': 3});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
