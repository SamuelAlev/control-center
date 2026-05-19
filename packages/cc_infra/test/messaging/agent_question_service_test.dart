import 'dart:async' show Completer;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/messaging/agent_question_service.dart';
import 'package:test/test.dart';

/// Exercises [AgentQuestionService]. The service coordinates an in-process
/// [Completer] between an asking agent and the UI's
/// [AgentQuestionService.submitAnswer]; a fake
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
      timeout: const Duration(seconds: 1),
    );
  });

  AgentQuestionRequest request({
    String conversationId = 'c1',
    String? askedByAgentId = 'agent-1',
    String? askedByName,
    List<AgentQuestionOption> options = const [],
    bool allowFreeText = false,
    bool multiSelect = false,
    String? context,
  }) {
    return AgentQuestionRequest(
      workspaceId: ws,
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

  ChannelMessage questionMessage(String id, {Map<String, dynamic>? metadata}) {
    return ChannelMessage(
      id: id,
      channelId: 'c1',
      conversationId: 'c1',
      senderId: 'agent-1',
      senderType: ChannelSenderType.agent,
      content: 'Pick one',
      messageType: ChannelMessageType.userQuestion,
      metadata: metadata,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('ask', () {
    test('returns null when conversationId is empty', () async {
      expect(await service.ask(request(conversationId: '')), isNull);
      expect(messaging.sentMessages, isEmpty);
    });

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

    test('defaults senderId to "agent" when askedByAgentId is null', () async {
      messaging.nextMessageId = 'm-2';
      final future = service.ask(request(askedByAgentId: null));
      await Future<void>.delayed(Duration.zero);
      expect(messaging.sentMessages.single.senderId, 'agent');
      await service.submitAnswer(
        ws,
        questionMessage('m-2'),
        const AgentQuestionAnswer(),
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
        timeout: const Duration(milliseconds: 10),
      );
      messaging.nextMessageId = 'm-4';
      final result = await service.ask(request());
      expect(result, isNull);
      expect(service.isPending('m-4'), isFalse);
    });

    test('Duration.zero waits indefinitely (no timeout)', () async {
      service = AgentQuestionService(messaging, timeout: Duration.zero);
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

    test('still resolves the agent when persistence throws', () async {
      messaging.nextMessageId = 'm-7';
      messaging.throwOnUpdate = true;
      final future = service.ask(request());
      await Future<void>.delayed(Duration.zero);
      await service.submitAnswer(
        ws,
        questionMessage('m-7'),
        const AgentQuestionAnswer(selectedLabels: ['b']),
      );
      // The agent was unblocked even though persistence failed.
      expect((await future)?.selectedLabels, ['b']);
    });

    test('is a no-op when the question is not pending', () async {
      // No ask() opened a pending question; submitAnswer should not throw and
      // should still attempt to persist the metadata.
      await service.submitAnswer(
        ws,
        questionMessage('m-8'),
        const AgentQuestionAnswer(),
      );
      expect(messaging.updatedMessages, hasLength(1));
    });
  });
}

class _SentMessage {
  _SentMessage({
    required this.workspaceId,
    required this.channelId,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.metadata,
  });
  final String workspaceId;
  final String channelId;
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
    required String channelId,
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
        channelId: channelId,
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
}

// Unused import suppression: ensure dart:typed_data is referenced.
// ignore: unused_element
Uint8List? _unused;
