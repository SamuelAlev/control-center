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
import 'package:cc_mcp/src/tools/submit_reviewer_verdict_tool.dart';
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

  // Spies
  String? lastSpaceId;
  String? lastContent;
  String? lastSenderId;
  String? lastSenderType;
  String? lastMessageType;
  Map<String, dynamic>? lastMetadata;
  String? lastId;

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
    lastSpaceId = spaceId;
    lastContent = content;
    lastSenderId = senderId;
    lastSenderType = senderType;
    lastMessageType = messageType;
    lastMetadata = metadata;
    lastId = id;
    return id ?? '';
  }

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

  @override
  Stream<List<Space>> watchSpaces() => Stream.value([]);

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
  group('SubmitReviewerVerdictTool', () {
    late _FakeMessagingRepository repository;
    late SubmitReviewerVerdictTool tool;

    setUp(() {
      repository = _FakeMessagingRepository();
      tool = SubmitReviewerVerdictTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'submit_reviewer_verdict');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        schema['required'],
        containsAll([
          'space_id',
          'reviewer_id',
          'verdict',
          'confidence',
          'explanation',
        ]),
      );
      final props = schema['properties'] as Map<String, dynamic>;
      expect((props['verdict'] as Map<String, dynamic>)['enum'], [
        'ship',
        'hold',
        'block',
      ]);
      expect((props['confidence'] as Map<String, dynamic>)['minimum'], 0);
      expect((props['confidence'] as Map<String, dynamic>)['maximum'], 1);
    });

    // --- Arg validation: space_id ---

    test('errors on missing space_id', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('space_id'));
    });

    test('errors on non-string space_id', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 42,
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('space_id'));
    });

    // --- Arg validation: reviewer_id ---

    test('errors on missing reviewer_id', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('reviewer_id'));
    });

    test('errors on non-string reviewer_id', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 99,
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('reviewer_id'));
    });

    // --- Arg validation: verdict ---

    test('errors on missing verdict', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('verdict'));
    });

    test('errors on non-string verdict', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': true,
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('verdict'));
    });

    test('errors on invalid verdict value', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'maybe',
        'confidence': 0.8,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('verdict'));
    });

    // --- Arg validation: confidence ---

    test('errors on missing confidence', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('confidence'));
    });

    test('errors on non-numeric confidence', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 'high',
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('confidence'));
    });

    test('errors on confidence below 0', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': -0.1,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('out of range'));
    });

    test('errors on confidence above 1', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 1.5,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('out of range'));
    });

    test('errors on NaN confidence', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': double.nan,
        'explanation': 'Looks good.',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('out of range'));
    });

    // --- Arg validation: explanation ---

    test('errors on missing explanation', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('explanation'));
    });

    test('errors on non-string explanation', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0.8,
        'explanation': 12345,
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('explanation'));
    });

    // --- Confidence boundary acceptance ---

    test('accepts confidence exactly 0.0', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'block',
        'confidence': 0.0,
        'explanation': 'Terrible.',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confidence'], 0.0);
    });

    test('accepts confidence exactly 1.0', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'hold',
        'confidence': 1.0,
        'explanation': 'Needs minor fix.',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confidence'], 1.0);
    });

    // --- Success: all verdict variants ---

    test('sends message and returns success for ship verdict', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'agent-7',
        'verdict': 'ship',
        'confidence': 0.95,
        'explanation': 'All checks pass, looks solid.',
      });
      expect(result.isError, isFalse);

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['space_id'], 'ch-1');
      expect(data['reviewer_id'], 'agent-7');
      expect(data['verdict'], 'ship');
      expect(data['confidence'], 0.95);
      expect(data['message_id'], isA<String>());
      expect(data['message_id'], isNotEmpty);

      // Verify message sent to repository
      expect(repository.lastSpaceId, 'ch-1');
      expect(repository.lastSenderId, 'agent-7');
      expect(repository.lastContent, 'All checks pass, looks solid.');
      expect(repository.lastSenderType, 'agent');
      expect(repository.lastMessageType, 'system');
      expect(repository.lastId, data['message_id']);
      expect(repository.lastMetadata, {
        'reviewerVerdict': true,
        'verdict': 'ship',
        'confidence': 0.95,
      });
    });

    test('sends message and returns success for hold verdict', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-2',
        'reviewer_id': 'agent-3',
        'verdict': 'hold',
        'confidence': 0.7,
        'explanation': 'Needs clarification on one point.',
      });
      expect(result.isError, isFalse);

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['verdict'], 'hold');
      expect(data['confidence'], 0.7);
      expect(repository.lastMetadata!['verdict'], 'hold');
      expect(repository.lastMetadata!['confidence'], 0.7);
    });

    test('sends message and returns success for block verdict', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-3',
        'reviewer_id': 'agent-9',
        'verdict': 'block',
        'confidence': 0.99,
        'explanation': 'Security vulnerability found.',
      });
      expect(result.isError, isFalse);

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['verdict'], 'block');
      expect(data['confidence'], 0.99);
      expect(repository.lastMetadata!['verdict'], 'block');
      expect(repository.lastMetadata!['confidence'], 0.99);
    });

    // --- Integer confidence ---

    test('accepts integer confidence', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'space_id': 'ch-1',
        'reviewer_id': 'r1',
        'verdict': 'ship',
        'confidence': 0, // int -> num -> toDouble() == 0.0
        'explanation': 'Perfect.',
      });
      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['confidence'], 0.0);
    });
  });
}
