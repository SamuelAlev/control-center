import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

ChannelMessage _msg({
  required String id,
  required String senderId,
  required String content,
  ChannelMessageType type = ChannelMessageType.text,
  ChannelSenderType senderType = ChannelSenderType.user,
  bool compacted = false,
  Map<String, dynamic>? metadata,
  DateTime? createdAt,
}) =>
    ChannelMessage(
      id: id,
      channelId: 'ch1',
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
  final List<ChannelMessage> _messages;
  final List<EmbeddedChannelMessage> _embedded;

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async => _messages;

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String channelId,
  ) async =>
      _embedded;

  @override
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding) async {}

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) async => [];

  @override
  Stream<List<Channel>> watchChannels() => const Stream.empty();

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      const Stream.empty();

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async => throw UnimplementedError();

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
  Future<void> addParticipant(String channelId, String agentId) async {}

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async => [];

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
  Future<void> markCompacted(List<String> ids) async {}

  @override
  Future<void> deleteChannel(String channelId) async {}

  @override
  Future<void> updateChannelName(String channelId, String name) async {}

  @override
  Future<void> clearChannelMessages(String channelId) async {}

  @override
  Future<void> removeParticipant(String channelId, String agentId) async {}
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
}

class _NotReadyEmbeddingPort implements EmbeddingPort {
  @override
  bool get isReady => false;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async => Float32List(384);
}

void main() {
  group('buildConversationContextPure', () {
    test('returns empty string when all lists are empty', () {
      final result = buildConversationContextPure(
        channelId: 'ch1',
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
        _msg(id: '2', senderId: 'a1', content: 'Hi there', senderType: ChannelSenderType.agent),
      ];

      final result = buildConversationContextPure(
        channelId: 'ch1',
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
        _msg(id: '1', senderId: 'a1', content: 'My response', senderType: ChannelSenderType.agent),
      ];

      final result = buildConversationContextPure(
        channelId: 'ch1',
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
        _msg(id: '1', senderId: 'a2', content: 'Other agent', senderType: ChannelSenderType.agent),
      ];

      final result = buildConversationContextPure(
        channelId: 'ch1',
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
        type: ChannelMessageType.system,
        senderType: ChannelSenderType.agent,
        metadata: {'compacted': true},
      );

      final result = buildConversationContextPure(
        channelId: 'ch1',
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
      final hit = _msg(id: 'h1', senderId: 'user', content: 'Old relevant message');

      final result = buildConversationContextPure(
        channelId: 'ch1',
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
        type: ChannelMessageType.system,
        senderType: ChannelSenderType.agent,
        metadata: {'compacted': true},
      );
      final hit = _msg(id: 'h1', senderId: 'user', content: 'Relevant old');
      final recent = _msg(id: 'r1', senderId: 'user', content: 'Recent msg');

      final result = buildConversationContextPure(
        channelId: 'ch1',
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
    test('returns empty for empty channel', () async {
      final repo = _FakeMessagingRepository([]);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        channelId: 'ch1',
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
        _msg(id: '2', senderId: 'a1', content: 'Hi', senderType: ChannelSenderType.agent),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        channelId: 'ch1',
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
        channelId: 'ch1',
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
        type: ChannelMessageType.system,
        senderType: ChannelSenderType.agent,
        metadata: {'compacted': true},
      );
      final bigMsg = _msg(id: '2', senderId: 'user', content: 'X' * 200);

      final repo = _FakeMessagingRepository([summary, bigMsg]);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        channelId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 10,
      );

      expect(result, contains('### Earlier (summary)'));
      expect(result, contains('Summary here'));
    });

    test('excludes thinking messages', () async {
      final msgs = [
        _msg(id: '1', senderId: 'a1', content: 'Thinking...', type: ChannelMessageType.thinking, senderType: ChannelSenderType.agent),
        _msg(id: '2', senderId: 'user', content: 'Hello'),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        channelId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 100000,
      );

      expect(result, isNot(contains('Thinking...')));
      expect(result, contains('Hello'));
    });

    test('degrades gracefully when embedding port is not ready', () async {
      final msgs = [
        _msg(id: '1', senderId: 'user', content: 'Hello'),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
        embeddingPort: _NotReadyEmbeddingPort(),
      );
      final result = await useCase.execute(
        channelId: 'ch1',
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
        EmbeddedChannelMessage(
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
        channelId: 'ch1',
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
        channelId: 'ch1',
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
        _msg(id: '1', senderId: 'system', content: 'Agent joined', type: ChannelMessageType.system, senderType: ChannelSenderType.agent),
        _msg(id: '2', senderId: 'user', content: 'Hello'),
      ];
      final repo = _FakeMessagingRepository(msgs);
      final useCase = BuildConversationContextUseCase(
        messagingRepository: repo,
      );
      final result = await useCase.execute(
        channelId: 'ch1',
        selfAgentId: 'a1',
        selfAgentName: 'Claude',
        taskDescription: 'test',
        characterBudget: 100000,
      );

      expect(result, isNot(contains('Agent joined')));
      expect(result, contains('Hello'));
    });
  });
}
