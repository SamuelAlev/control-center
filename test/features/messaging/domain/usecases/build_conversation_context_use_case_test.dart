import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:flutter_test/flutter_test.dart';

Message _msg({
  required String id,
  required String senderId,
  required String content,
  MessageType type = MessageType.text,
  SenderType senderType = SenderType.user,
  bool compacted = false,
  Map<String, dynamic>? metadata,
  DateTime? createdAt,
}) => Message(
  id: id,
  spaceId: 'ch1',
  conversationId: 'c-main',
  senderId: senderId,
  senderType: senderType,
  content: content,
  messageType: type,
  metadata: metadata,
  compacted: compacted,
  createdAt: createdAt ?? DateTime(2026, 5, 21, 14, 0),
);

class _FakeMessagingRepository implements MessagingRepository {
  _FakeMessagingRepository(this._messages, [this._embedded = const []]);

  // The steering queue's row writes: unused by the context builder under
  // test; present to satisfy the interface.
  @override
  Future<String> insertSteeringMessage({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required String senderId,
    required Map<String, dynamic> metadata,
    String? id,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteSteeringMessage(String workspaceId, String messageId) =>
      throw UnimplementedError();

  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}
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

  /// Reads scoped to any other workspace see nothing: the workspace selects the
  /// database file, so a space id alone never reaches this history.
  static const workspaceId = 'ws-1';

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
  final List<Message> _messages;
  final List<EmbeddedMessage> _embedded;

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
  }) async => workspaceId == _FakeMessagingRepository.workspaceId
      ? _messages
      : const [];

  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async => workspaceId == _FakeMessagingRepository.workspaceId
      ? _embedded
      : const [];

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}

  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];

  @override
  Stream<List<Space>> watchSpaces() => const Stream.empty();

  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => const Stream.empty();

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
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) => throw UnimplementedError();

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
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {}

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {}

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {}

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) async {}

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

class _FakeEmbeddingPort implements EmbeddingPort {
  _FakeEmbeddingPort(this._vec) : isReady = true;
  final Float32List _vec;
  @override
  bool isReady;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async => _vec;

  @override
  Future<List<Float32List>> embedAll(List<String> texts) async => [
    for (final text in texts) await embed(text),
  ];
}

class _NotReadyEmbeddingPort implements EmbeddingPort {
  @override
  bool get isReady => false;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async => Float32List(384);

  @override
  Future<List<Float32List>> embedAll(List<String> texts) async => [
    for (final text in texts) await embed(text),
  ];
}

class _FakeConversationRepository implements ConversationRepository {
  _FakeConversationRepository(this._byId);

  final Map<String, Conversation> _byId;

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => _byId[conversationId];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// A messaging fake that serves history per conversation id (the thread is
/// empty; the parent stream holds the anchor message).
class _ThreadAwareMessagingRepository extends _FakeMessagingRepository {
  _ThreadAwareMessagingRepository(
    this._byConversation,
    this._anchor, [
    List<EmbeddedMessage> embedded = const [],
  ]) : super(const [], embedded);

  final Map<String, List<Message>> _byConversation;
  final Message _anchor;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => _byConversation[conversationId] ?? const [];

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      messageId == _anchor.id ? _anchor : null;
}

void main() {
  group('buildConversationContextPure', () {
    test('returns empty string when all lists are empty', () {
      final result = buildConversationContextPure(
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        messages: [],
        verbatimWindow: [],
        summaries: [],
        semanticHits: [],
      );
      expect(result, isEmpty);
    });

    test('renders verbatim window in chronological order', () {
      final msgs = [
        _msg(id: '1', senderId: 'user', content: 'Hello'),
        _msg(
          id: '2',
          senderId: 'a1',
          content: 'Hi there',
          senderType: SenderType.agent,
        ),
      ];

      final result = buildConversationContextPure(
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        messages: msgs,
        verbatimWindow: msgs,
        summaries: [],
        semanticHits: [],
      );

      expect(result, contains('## Conversation History'));
      expect(result, contains('### Recent messages'));
      expect(result, contains('[user ·'));
      expect(result, contains('Hello'));
      expect(result, contains('Hi there'));
    });

    test('uses "you" for self agent messages', () {
      final msgs = [
        _msg(
          id: '1',
          senderId: 'a1',
          content: 'My response',
          senderType: SenderType.agent,
        ),
      ];

      final result = buildConversationContextPure(
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        messages: msgs,
        verbatimWindow: msgs,
        summaries: [],
        semanticHits: [],
      );

      expect(result, contains('[you ·'));
      expect(result, isNot(contains('[Claude ·')));
    });

    test('uses agent name for other agent messages', () {
      final msgs = [
        _msg(
          id: '1',
          senderId: 'a2',
          content: 'Other agent',
          senderType: SenderType.agent,
        ),
      ];

      final result = buildConversationContextPure(
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        messages: msgs,
        verbatimWindow: msgs,
        summaries: [],
        semanticHits: [],
      );

      expect(result, contains('[Claude ·'));
    });

    test('includes summaries section', () {
      final summary = _msg(
        id: 's1',
        senderId: 'system',
        content: '## Summary of earlier chat',
        type: MessageType.system,
        senderType: SenderType.agent,
        metadata: {'compacted': true},
      );

      final result = buildConversationContextPure(
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        messages: [summary],
        verbatimWindow: [],
        summaries: [summary],
        semanticHits: [],
      );

      expect(result, contains('### Earlier (summary)'));
      expect(result, contains('Summary of earlier chat'));
    });

    test('includes semantic hits section', () {
      final hit = _msg(
        id: 'h1',
        senderId: 'user',
        content: 'Old relevant message',
      );

      final result = buildConversationContextPure(
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        messages: [hit],
        verbatimWindow: [],
        summaries: [],
        semanticHits: [hit],
      );

      expect(result, contains('### Possibly relevant earlier messages'));
      expect(result, contains('Old relevant message'));
    });

    test('renders all three sections together', () {
      final summary = _msg(
        id: 's1',
        senderId: 'system',
        content: 'Summary text',
        type: MessageType.system,
        senderType: SenderType.agent,
        metadata: {'compacted': true},
      );
      final hit = _msg(id: 'h1', senderId: 'user', content: 'Relevant old');
      final recent = _msg(id: 'r1', senderId: 'user', content: 'Recent msg');

      final result = buildConversationContextPure(
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        messages: [summary, hit, recent],
        verbatimWindow: [recent],
        summaries: [summary],
        semanticHits: [hit],
      );

      expect(result, contains('### Earlier (summary)'));
      expect(result, contains('### Possibly relevant earlier messages'));
      expect(result, contains('### Recent messages'));
    });
  });

  group('BuildConversationContextUseCase', () {
    test('returns empty for empty space', () async {
      final repo = _FakeMessagingRepository([]);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'hello',
        characterBudget: 100000,
      );
      expect(result, isEmpty);
    });

    test('returns all messages verbatim when under budget', () async {
      final msgs = [
        _msg(id: '1', senderId: 'user', content: 'Hello'),
        _msg(
          id: '2',
          senderId: 'a1',
          content: 'Hi',
          senderType: SenderType.agent,
        ),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'hello',
        characterBudget: 100000,
      );
      expect(result, contains('Hello'));
      expect(result, contains('Hi'));
      expect(result, contains('[you ·'));
    });

    test('respects character budget for verbatim window', () async {
      final msgs = [
        _msg(id: '1', senderId: 'user', content: 'A' * 50),
        _msg(id: '2', senderId: 'user', content: 'B' * 50),
        _msg(id: '3', senderId: 'user', content: 'C' * 50),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 100,
      );

      expect(result, isNot(contains('A' * 50)));
      expect(result, contains('B' * 50));
      expect(result, contains('C' * 50));
    });

    test('always includes summaries regardless of budget', () async {
      final summary = _msg(
        id: 's1',
        senderId: 'system',
        content: 'Summary here',
        type: MessageType.system,
        senderType: SenderType.agent,
        metadata: {'compacted': true},
      );
      final bigMsg = _msg(id: '2', senderId: 'user', content: 'X' * 200);

      final repo = _FakeMessagingRepository([summary, bigMsg]);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 10,
      );

      expect(result, contains('### Earlier (summary)'));
      expect(result, contains('Summary here'));
    });

    test('includes agent turn content in the verbatim window', () async {
      final msgs = [
        _msg(
          id: '1',
          senderId: 'a1',
          content: 'My final answer',
          type: MessageType.agentTurn,
          senderType: SenderType.agent,
        ),
        _msg(id: '2', senderId: 'user', content: 'Hello'),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 100000,
      );

      expect(result, contains('My final answer'));
      expect(result, contains('Hello'));
    });

    test('degrades gracefully when embedding port is not ready', () async {
      final msgs = [_msg(id: '1', senderId: 'user', content: 'Hello')];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
        embeddingPort: _NotReadyEmbeddingPort(),
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'hello',
        characterBudget: 100000,
      );
      expect(result, contains('Hello'));
      expect(result, isNot(contains('Possibly relevant')));
    });

    test('pulls semantic hits from embedded archive', () async {
      final oldMsg = _msg(
        id: 'old1',
        senderId: 'user',
        content: 'My name is Sam',
        createdAt: DateTime(2026, 5, 1),
      );
      final recentMsg = _msg(
        id: 'new1',
        senderId: 'user',
        content: 'What is my name?',
        createdAt: DateTime(2026, 5, 21),
      );

      final queryVec = Float32List(384);
      queryVec[0] = 1.0;

      final oldVec = Float32List(384);
      oldVec[0] = 0.95;

      final embedded = [
        EmbeddedMessage(
          message: oldMsg,
          embedding: Uint8List.view(oldVec.buffer),
        ),
      ];

      final repo = _FakeMessagingRepository([oldMsg, recentMsg], embedded);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
        embeddingPort: _FakeEmbeddingPort(queryVec),
      );

      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'What is my name?',
        characterBudget: 5,
      );

      expect(result, contains('Possibly relevant'));
      expect(result, contains('My name is Sam'));
    });

    test('skips compacted messages from verbatim window', () async {
      final msgs = [
        _msg(id: '1', senderId: 'user', content: 'Old', compacted: true),
        _msg(id: '2', senderId: 'user', content: 'New'),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 100000,
      );

      expect(result, isNot(contains('Old')));
      expect(result, contains('New'));
    });

    test('skips system messages that are not compaction summaries', () async {
      final msgs = [
        _msg(
          id: '1',
          senderId: 'system',
          content: 'Agent joined',
          type: MessageType.system,
          senderType: SenderType.agent,
        ),
        _msg(id: '2', senderId: 'user', content: 'Hello'),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 100000,
      );

      expect(result, isNot(contains('Agent joined')));
      expect(result, contains('Hello'));
    });
  });

  group('thread anchoring', () {
    test(
      'a fresh thread seeds with the anchor line first, parent history absent',
      () async {
        final anchor = _msg(
          id: 'p1',
          senderId: 'agent-x',
          content: 'do the thing',
          senderType: SenderType.agent,
          metadata: const {'agentName': 'Scout'},
        );
        final parentConv = Conversation(
          id: 'c-main',
          workspaceId: 'ws-1',
          spaceId: 'ch1',
          title: 'Main chat',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
        final threadConv = Conversation(
          id: 't1',
          workspaceId: 'ws-1',
          spaceId: 'ch1',
          title: 'Fix it',
          anchorMessageId: 'p1',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
        final repo = _ThreadAwareMessagingRepository({
          'c-main': [anchor],
          't1': const <Message>[],
        }, anchor);
        final useCase = BuildConversationContextUseCase(
          messagingRepository: repo,
          conversationRepository: _FakeConversationRepository({
            'c-main': parentConv,
            't1': threadConv,
          }),
        );

        final result = await useCase.execute(
          workspaceId: 'ws-1',
          spaceId: 'ch1',
          selfAgentId: 'a1',
          selfAgentName: 'Claude',
          taskDescription: 'fix',
          characterBudget: 100000,
          conversationId: 't1',
        );

        // Named, not id'd: "Replying to agent-x" tells the model nothing
        // about who it is answering.
        expect(result, 'Replying to Scout in "Main chat": do the thing');
      },
    );

    test('semantic retrieval never reaches into the parent stream', () async {
      final anchor = _msg(
        id: 'p1',
        senderId: 'agent-x',
        content: 'do the thing',
        senderType: SenderType.agent,
        metadata: const {'agentName': 'Scout'},
      );
      // A message in the PARENT conversation, embedded and a near-perfect
      // match for the task description. Embeddings are stored per space, so
      // an unscoped semantic read would surface it inside the thread — which
      // is exactly the parent history the anchor seed exists to replace.
      final parentArchive = Message(
        id: 'p0',
        spaceId: 'ch1',
        conversationId: 'c-main',
        senderId: 'user',
        senderType: SenderType.user,
        content: 'PARENT SECRET',
        messageType: MessageType.text,
        createdAt: DateTime(2026, 5, 21, 13),
      );
      final parentConv = Conversation(
        id: 'c-main',
        workspaceId: 'ws-1',
        spaceId: 'ch1',
        title: 'Main chat',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final threadConv = Conversation(
        id: 't1',
        workspaceId: 'ws-1',
        spaceId: 'ch1',
        title: 'Fix it',
        anchorMessageId: 'p1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final queryVec = Float32List(384);
      queryVec[0] = 1.0;
      final archiveVec = Float32List(384);
      archiveVec[0] = 0.99;

      final repo = _ThreadAwareMessagingRepository(
        {
          'c-main': [anchor, parentArchive],
          't1': const <Message>[],
        },
        anchor,
        [
          EmbeddedMessage(
            message: parentArchive,
            embedding: Uint8List.view(archiveVec.buffer),
          ),
        ],
      );
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
        conversationRepository: _FakeConversationRepository({
          'c-main': parentConv,
          't1': threadConv,
        }),
        embeddingPort: _FakeEmbeddingPort(queryVec),
      );

      final result = await useCase.execute(
        workspaceId: _FakeMessagingRepository.workspaceId,
        spaceId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'do the thing',
        characterBudget: 100000,
        conversationId: 't1',
      );

      expect(result, isNot(contains('PARENT SECRET')));
      expect(result, contains('Replying to Scout'));
    });
  });
}
