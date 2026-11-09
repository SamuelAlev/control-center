import 'dart:async' show Completer;
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/messaging/agent_question_service.dart';
import 'package:test/test.dart';

/// Exercises [AgentQuestionService]. The service coordinates an in-process
/// [Completer] between an asking agent and
/// [AgentQuestionService.deliverAnswer]; a fake
/// [MessagingRepository] drives every branch (empty conversation, ask/answer
/// round trip, timeout, answered-message metadata persistence and the
/// best-effort persistence failure path).
void main() {
  const ws = 'ws-1';
  late _FakeMessagingRepository messaging;
  late AgentQuestionService service;

  setUp(() {
    messaging = _FakeMessagingRepository();
    service = AgentQuestionService(
      messaging,
      conversations: _FakeConversations(),
      timeout: const Duration(seconds: 1),
    );
  });

  AgentQuestionRequest request({
    String spaceId = 'c1',
    String conversationId = 'conv-side',
    String? askedByAgentId = 'agent-1',
    String? askedByName,
    List<AgentQuestionOption> options = const [],
    bool allowFreeText = false,
    bool multiSelect = false,
    String? context,
  }) {
    return AgentQuestionRequest(
      workspaceId: ws,
      spaceId: spaceId,
      conversationId: conversationId,
      question: 'Pick one',
      context: context,
      options: options,
      allowFreeText: allowFreeText,
      multiSelect: multiSelect,
      askedByAgentId: askedByAgentId,
      askedByName: askedByName,
    );
  }

  Message questionMessage(
    String id, {
    String conversationId = 'conv-side',
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id,
      spaceId: 'c1',
      conversationId: conversationId,
      senderId: 'agent-1',
      senderType: SenderType.agent,
      content: 'Pick one',
      messageType: MessageType.userQuestion,
      metadata: metadata,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('ask', () {
    test('refuses a request without a space (not a timeout)', () async {
      await expectLater(
        service.ask(request(spaceId: '')),
        throwsA(isA<ArgumentError>()),
      );
      expect(messaging.sentMessages, isEmpty);
    });

    test('does not post without a conversation id', () async {
      await expectLater(
        service.ask(request(conversationId: '')),
        throwsA(isA<ArgumentError>()),
      );
      expect(messaging.sentMessages, isEmpty);
    });

    test('rejects a conversation from another space or workspace', () async {
      await expectLater(
        service.ask(request(conversationId: 'conv-other-space')),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        service.ask(request(conversationId: 'conv-other-workspace')),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(messaging.sentMessages, isEmpty);
    });

    test(
      'same-space conversations keep separate questions and answers',
      () async {
        messaging.nextMessageId = 'm-standing';
        final standing = service.ask(request(conversationId: 'conv-standing'));
        await Future<void>.delayed(Duration.zero);
        messaging.nextMessageId = 'm-side';
        final side = service.ask(request(conversationId: 'conv-side'));
        await Future<void>.delayed(Duration.zero);

        expect(
          messaging.sentMessages.map((message) => message.conversationId),
          ['conv-standing', 'conv-side'],
        );
        await service.submitAnswer(
          ws,
          questionMessage('m-side'),
          const AgentQuestionAnswer(selectedLabels: ['side']),
        );
        expect((await side)?.selectedLabels, ['side']);
        expect(service.isPending('m-standing'), isTrue);
        await service.submitAnswer(
          ws,
          questionMessage('m-standing', conversationId: 'conv-standing'),
          const AgentQuestionAnswer(selectedLabels: ['standing']),
        );
        expect((await standing)?.selectedLabels, ['standing']);
      },
    );

    test('posts a user_question message with rich metadata', () async {
      messaging.nextMessageId = 'm-1';
      final future = service.ask(
        request(
          options: const [AgentQuestionOption(label: 'A', value: 'a')],
          allowFreeText: true,
          multiSelect: true,
          askedByName: 'QA Agent',
          context: 'need input',
        ),
      );
      // Let the post resolve; the future is still awaiting the answer.
      await Future<void>.delayed(Duration.zero);
      final sent = messaging.sentMessages.single;
      expect(sent.workspaceId, ws);
      expect(sent.spaceId, 'c1');
      expect(sent.conversationId, 'conv-side');
      expect(sent.messageType, 'user_question');
      expect(sent.content, 'Pick one');
      expect(sent.senderId, 'agent-1');
      expect(sent.metadata!['question'], 'Pick one');
      expect(sent.metadata!['context'], 'need input');
      expect(sent.metadata!['allowFreeText'], isTrue);
      expect(sent.metadata!['multiSelect'], isTrue);
      expect(sent.metadata!['askedByName'], 'QA Agent');
      expect(sent.metadata![kQuestionAnsweredKey], isFalse);
      final options = sent.metadata!['options'] as List;
      expect(options, hasLength(1));
      expect((options.first as Map)['value'], 'a');
      // Clean up the pending completer.
      await service.submitAnswer(
        ws,
        questionMessage('m-1'),
        const AgentQuestionAnswer(selectedLabels: ['a']),
      );
      await future;
    });

    test('resolves with the answer when submitAnswer is called', () async {
      messaging.nextMessageId = 'm-3';
      final future = service.ask(request());
      await Future<void>.delayed(Duration.zero);
      expect(service.isPending('m-3'), isTrue);
      const answer = AgentQuestionAnswer(
        selectedLabels: ['yes'],
        freeText: 'k',
      );
      await service.submitAnswer(ws, questionMessage('m-3'), answer);
      expect(await future, answer);
      expect(service.isPending('m-3'), isFalse);
    });

    test('returns null on timeout', () async {
      service = AgentQuestionService(
        messaging,
        conversations: _FakeConversations(),
        timeout: const Duration(milliseconds: 10),
      );
      messaging.nextMessageId = 'm-4';
      final result = await service.ask(request());
      expect(result, isNull);
      expect(service.isPending('m-4'), isFalse);
    });

    test('reports each posted question so the operator can be told', () async {
      final asked = <(AgentQuestionRequest, String)>[];
      final closed = <String>[];
      service = AgentQuestionService(
        messaging,
        conversations: _FakeConversations(),
        timeout: const Duration(milliseconds: 10),
        onAsked: (request, messageId) => asked.add((request, messageId)),
        onClosed: closed.add,
      );
      messaging.nextMessageId = 'm-reported';
      await service.ask(request());
      expect(asked.single.$1.question, 'Pick one');
      expect(asked.single.$2, 'm-reported');
      // Timed out unanswered: the wait still ends.
      expect(closed, ['m-reported']);

      // Nothing is posted without a space, so nothing is reported either.
      await expectLater(
        service.ask(request(spaceId: '')),
        throwsA(isA<ArgumentError>()),
      );
      expect(asked, hasLength(1));
      expect(closed, hasLength(1));
    });

    test('reports an answered question as closed', () async {
      final closed = <String>[];
      service = AgentQuestionService(
        messaging,
        conversations: _FakeConversations(),
        onClosed: closed.add,
      );
      messaging.nextMessageId = 'm-answered';
      final future = service.ask(request());
      await Future<void>.delayed(Duration.zero);
      expect(closed, isEmpty);

      await service.deliverAnswer(
        'm-answered',
        const AgentQuestionAnswer(),
        persist: () async => true,
      );
      await future;
      expect(closed, ['m-answered']);
    });

    test('closes the form when the asker stops waiting', () async {
      messaging.nextMessageId = 'm-abandoned';
      final abandoned = Completer<void>();
      final future = service.ask(request(), abandoned: abandoned.future);
      await Future<void>.delayed(Duration.zero);
      expect(service.isPending('m-abandoned'), isTrue);

      abandoned.complete();

      expect(await future, isNull);
      expect(service.isPending('m-abandoned'), isFalse);
      final closed = messaging.updatedMessages.single.metadata!;
      expect(closed[kQuestionAnsweredKey], isTrue);
      expect(closed[kQuestionExpiredKey], isTrue);
      // An answer arriving after the close does not reopen the wait.
      expect(
        await service.deliverAnswer(
          'm-abandoned',
          const AgentQuestionAnswer(),
          persist: () async => true,
        ),
        QuestionAnswerDelivery.notPending,
      );
    });

    test(
      'an answer before the asker gives up is not closed as expired',
      () async {
        messaging.nextMessageId = 'm-answered';
        final abandoned = Completer<void>();
        final future = service.ask(request(), abandoned: abandoned.future);
        await Future<void>.delayed(Duration.zero);
        await service.submitAnswer(
          ws,
          questionMessage('m-answered'),
          const AgentQuestionAnswer(selectedLabels: ['A']),
        );
        expect((await future)?.selectedLabels, ['A']);

        abandoned.complete();
        await Future<void>.delayed(Duration.zero);
        final update = messaging.updatedMessages.single.metadata!;
        expect(update[kQuestionExpiredKey], isNull);
      },
    );

    test('Duration.zero waits indefinitely (no timeout)', () async {
      service = AgentQuestionService(
        messaging,
        conversations: _FakeConversations(),
        timeout: Duration.zero,
      );
      messaging.nextMessageId = 'm-5';
      final future = service.ask(request());
      // Pump well past what a default timeout would have been.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.isPending('m-5'), isTrue);
      // Now answer it.
      await service.submitAnswer(
        ws,
        questionMessage('m-5'),
        const AgentQuestionAnswer(selectedLabels: ['x']),
      );
      expect((await future)?.selectedLabels, ['x']);
    });
  });

  group('submitAnswer', () {
    test('persists the answer into message metadata', () async {
      messaging.nextMessageId = 'm-6';
      final future = service.ask(request());
      await Future<void>.delayed(Duration.zero);
      await service.submitAnswer(
        ws,
        questionMessage('m-6', metadata: {'question': 'Pick one'}),
        const AgentQuestionAnswer(selectedLabels: ['a']),
      );
      await future;
      final update = messaging.updatedMessages.single;
      expect(update.workspaceId, ws);
      expect(update.metadata![kQuestionAnsweredKey], isTrue);
      expect(update.metadata![kQuestionAnswerKey], isNotNull);
      // Original metadata is preserved.
      expect(update.metadata!['question'], 'Pick one');
    });

    test('a failed write propagates and the agent gets no answer', () async {
      messaging.nextMessageId = 'm-7';
      messaging.throwOnUpdate = true;
      final future = service.ask(request());
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        service.submitAnswer(
          ws,
          questionMessage('m-7'),
          const AgentQuestionAnswer(selectedLabels: ['b']),
        ),
        throwsA(isA<StateError>()),
      );
      // Never "answered" on one side and timed out on the other.
      expect(await future, isNull);
    });

    test('writes nothing when the question is not pending', () async {
      expect(
        await service.submitAnswer(
          ws,
          questionMessage('m-8'),
          const AgentQuestionAnswer(),
        ),
        QuestionAnswerDelivery.notPending,
      );
      expect(messaging.updatedMessages, isEmpty);
    });
  });

  // The client/server seam: the human answers in a CLIENT over
  // `messaging.updateMessage`, which hands the answer to `deliverAnswer`.
  group('deliverAnswer', () {
    test('delivers a persisted answer to the waiting agent', () async {
      messaging.nextMessageId = 'm-100';
      final pending = service.ask(request());
      await Future<void>.delayed(Duration.zero);

      final outcome = await service.deliverAnswer(
        'm-100',
        const AgentQuestionAnswer(selectedLabels: ['Postgres']),
        persist: () async => true,
      );

      expect(outcome, QuestionAnswerDelivery.delivered);
      expect((await pending)?.selectedLabels, ['Postgres']);
      expect(service.isPending('m-100'), isFalse);
    });

    test('an id nobody is waiting on writes nothing', () async {
      var wrote = false;
      final outcome = await service.deliverAnswer(
        'never-asked',
        const AgentQuestionAnswer(),
        persist: () async => wrote = true,
      );
      expect(outcome, QuestionAnswerDelivery.notPending);
      expect(wrote, isFalse);
    });

    test('a refused write tells the agent there is no answer', () async {
      messaging.nextMessageId = 'm-101';
      final pending = service.ask(request());
      await Future<void>.delayed(Duration.zero);

      final outcome = await service.deliverAnswer(
        'm-101',
        const AgentQuestionAnswer(selectedLabels: ['x']),
        persist: () async => false,
      );

      expect(outcome, QuestionAnswerDelivery.notPersisted);
      expect(await pending, isNull);
    });

    test(
      'the timeout cannot win once an answer has claimed the waiter',
      () async {
        service = AgentQuestionService(
          messaging,
          conversations: _FakeConversations(),
          timeout: const Duration(milliseconds: 20),
        );
        messaging.nextMessageId = 'm-race';
        final pending = service.ask(request());
        await Future<void>.delayed(Duration.zero);

        // The write is slow: the timeout elapses while it is in flight.
        final outcome = service.deliverAnswer(
          'm-race',
          const AgentQuestionAnswer(selectedLabels: ['late but first']),
          persist: () async {
            await Future<void>.delayed(const Duration(milliseconds: 60));
            return true;
          },
        );

        expect(await outcome, QuestionAnswerDelivery.delivered);
        expect((await pending)?.selectedLabels, ['late but first']);
        // No expiry write followed the answer.
        expect(messaging.updatedMessages, isEmpty);
      },
    );

    test('an answer after the timeout is reported, not acknowledged', () async {
      final expired = <String>[];
      service = AgentQuestionService(
        messaging,
        conversations: _FakeConversations(),
        timeout: const Duration(milliseconds: 10),
        expireQuestion: (workspaceId, messageId) async {
          expired.add(messageId);
          return true;
        },
      );
      messaging.nextMessageId = 'm-late';
      expect(await service.ask(request()), isNull);
      expect(expired, ['m-late']);

      var wrote = false;
      expect(
        await service.deliverAnswer(
          'm-late',
          const AgentQuestionAnswer(selectedLabels: ['too late']),
          persist: () async => wrote = true,
        ),
        QuestionAnswerDelivery.notPending,
      );
      expect(wrote, isFalse);
    });

    test('a throwing onAsked does not strand the posted form', () async {
      service = AgentQuestionService(
        messaging,
        conversations: _FakeConversations(),
        timeout: const Duration(milliseconds: 10),
        onAsked: (request, messageId) => throw StateError('announce failed'),
      );
      messaging.nextMessageId = 'm-announce';
      expect(await service.ask(request()), isNull);
      expect(service.isPending('m-announce'), isFalse);
      expect(
        messaging.updatedMessages.single.metadata![kQuestionExpiredKey],
        isTrue,
      );
    });
  });
}

class _FakeConversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    if (workspaceId != 'ws-1' || conversationId == 'conv-other-workspace') {
      return null;
    }
    final spaceId = switch (conversationId) {
      'conv-side' || 'conv-standing' => 'c1',
      'conv-other-space' => 'other-space',
      _ => null,
    };
    if (spaceId == null) {
      return null;
    }
    return Conversation(
      id: conversationId,
      workspaceId: workspaceId,
      spaceId: spaceId,
      title: conversationId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SentMessage {
  _SentMessage({
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.metadata,
  });
  final String workspaceId;
  final String spaceId;
  final String conversationId;
  final String content;
  final String senderId;
  final String senderType;
  final String messageType;
  final Map<String, dynamic>? metadata;
}

class _UpdatedMessage {
  _UpdatedMessage(this.workspaceId, this.id, this.metadata);
  final String workspaceId;
  final String id;
  final Map<String, dynamic>? metadata;
}

class _FakeMessagingRepository implements MessagingRepository {
  String nextMessageId = 'msg-default';
  final List<_SentMessage> sentMessages = [];
  final List<_UpdatedMessage> updatedMessages = [];
  bool throwOnUpdate = false;

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
    sentMessages.add(
      _SentMessage(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId!,
        content: content,
        senderId: senderId,
        senderType: senderType,
        messageType: messageType,
        metadata: metadata,
      ),
    );
    return id ?? nextMessageId;
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    if (throwOnUpdate) {
      throw StateError('update failed');
    }
    updatedMessages.add(_UpdatedMessage(workspaceId, messageId, metadata));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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

// Unused import suppression: ensure dart:typed_data is referenced.
// ignore: unused_element
Uint8List? _unused;
