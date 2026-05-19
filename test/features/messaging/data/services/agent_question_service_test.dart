
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/ports/agent_question_port.dart';
import 'package:control_center/features/messaging/data/services/agent_question_service.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake [MessagingRepository] supporting just `sendMessage` + `updateMessage`.
class _FakeMessagingRepo implements MessagingRepository {
  final Map<String, ChannelMessage> _messages = {};
  int _nextId = 1;

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
    final msgId = id ?? 'msg-${_nextId++}';
    _messages[msgId] = ChannelMessage(
      id: msgId,
      channelId: channelId,
      content: content,
      senderId: senderId,
      senderType: _parseSenderType(senderType),
      messageType: _parseMessageType(messageType),
      metadata: metadata,
      parentMessageId: parentMessageId,
      createdAt: DateTime.now(),
    );
    return msgId;
  }

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {
    final msg = _messages[messageId];
    if (msg != null) {
      _messages[messageId] = msg.copyWith(
        content: content ?? msg.content,
        metadata: metadata ?? msg.metadata,
      );
    }
  }

  ChannelMessage? getMessage(String id) => _messages[id];

  ChannelSenderType _parseSenderType(String t) =>
      t == 'agent' ? ChannelSenderType.agent : ChannelSenderType.user;

  ChannelMessageType _parseMessageType(String t) => switch (t) {
        'user_question' => ChannelMessageType.userQuestion,
        _ => ChannelMessageType.text,
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMessagingRepo messaging;
  late AgentQuestionService service;

  setUp(() {
    messaging = _FakeMessagingRepo();
    service = AgentQuestionService(messaging, timeout: const Duration(seconds: 2));
  });

  group('ask', () {
    test('returns null when conversationId is empty', () async {
      final answer = await service.ask(
        const AgentQuestionRequest(conversationId: '', question: 'What?'),
      );
      expect(answer, isNull);
    });

    test('posts a question message and awaits answer', () async {
      const request = AgentQuestionRequest(
        conversationId: 'ch-1',
        question: 'Approve?',
        options: [
          AgentQuestionOption(label: 'Yes', value: 'yes'),
          AgentQuestionOption(label: 'No', value: 'no'),
        ],
        askedByAgentId: 'agent-1',
      );

      final Future<AgentQuestionAnswer?> answerFuture = service.ask(request);

      // Give time for message to be posted
      await Future.delayed(const Duration(milliseconds: 10));

      // The message should have been sent
      final msgId = messaging._messages.keys.firstWhere(
        (k) => messaging._messages[k]!.senderId == 'agent-1',
      );

      final questionMsg = messaging._messages[msgId]!;
      expect(questionMsg.messageType, ChannelMessageType.userQuestion);
      expect(service.isPending(questionMsg.id), isTrue);

      // Submit an answer
      const answer = AgentQuestionAnswer(selectedLabels: ['Yes']);
      await service.submitAnswer(questionMsg, answer);

      final result = await answerFuture;
      expect(result, isNotNull);
      expect(result!.selectedLabels, ['Yes']);
      expect(service.isPending(questionMsg.id), isFalse);
    });

    test('returns null on timeout', () async {
      final shortService = AgentQuestionService(messaging,
          timeout: const Duration(milliseconds: 50));

      const request = AgentQuestionRequest(
        conversationId: 'ch-1',
        question: 'Timeout?',
        askedByAgentId: 'agent-1',
      );

      final answer = await shortService.ask(request);
      expect(answer, isNull);
    });

    test('Duration.zero waits indefinitely', () async {
      final foreverService = AgentQuestionService(messaging,
          timeout: Duration.zero);

      const request = AgentQuestionRequest(
        conversationId: 'ch-1',
        question: 'Wait forever',
        askedByAgentId: 'agent-1',
      );

      final Future<AgentQuestionAnswer?> answerFuture = foreverService.ask(request);

      // Submit answer immediately after ask (synchronously, not via Future.delayed)
      final msgIds = messaging._messages.keys
          .where((k) => messaging._messages[k]!.senderId == 'agent-1')
          .toList();
      if (msgIds.isNotEmpty) {
        await foreverService.submitAnswer(
          messaging._messages[msgIds.first]!,
          const AgentQuestionAnswer(selectedLabels: ['OK']),
        );
      }

      final answer = await answerFuture.timeout(
        const Duration(seconds: 5),
      );
      expect(answer, isNotNull);
      expect(answer!.selectedLabels, ['OK']);
    });
  });

  group('submitAnswer', () {
    test('marks message as answered in metadata', () async {
      const request = AgentQuestionRequest(
        conversationId: 'ch-1',
        question: 'Test',
        askedByAgentId: 'agent-1',
      );

      final Future<AgentQuestionAnswer?> answerFuture = service.ask(request);
      await Future.delayed(const Duration(milliseconds: 10));

      final msgId = messaging._messages.keys
          .firstWhere((k) => messaging._messages[k]!.senderId == 'agent-1');
      final questionMsg = messaging._messages[msgId]!;

      await service.submitAnswer(
        questionMsg,
        const AgentQuestionAnswer(freeText: 'my answer'),
      );
      await answerFuture;

      final updated = messaging._messages[msgId]!;
      expect(updated.metadata?[kQuestionAnsweredKey], isTrue);
      expect(updated.metadata?[kQuestionAnswerKey], isNotNull);
    });

    test('submitAnswer on non-pending message does nothing', () async {
      final msg = ChannelMessage(
        id: 'fake',
        channelId: 'ch-1',
        content: 'not a question',
        senderId: 'user',
        senderType: ChannelSenderType.user,
        messageType: ChannelMessageType.text,
        createdAt: DateTime.now(),
      );

      // Should not throw
      await service.submitAnswer(
        msg,
        const AgentQuestionAnswer(selectedLabels: ['x']),
      );
    });
  });

  group('isPending', () {
    test('returns false for unknown message id', () {
      expect(service.isPending('nonexistent'), isFalse);
    });
  });

  group('metadata forwarding', () {
    test('context is forwarded in message metadata', () async {
      const request = AgentQuestionRequest(
        conversationId: 'ch-1',
        question: 'Choose',
        context: 'This is why I need to know',
        askedByAgentId: 'agent-1',
      );

      final Future<AgentQuestionAnswer?> answerFuture = service.ask(request);
      await Future.delayed(const Duration(milliseconds: 10));

      final msgId = messaging._messages.keys
          .firstWhere((k) => messaging._messages[k]!.senderId == 'agent-1');
      final questionMsg = messaging._messages[msgId]!;
      expect(questionMsg.metadata?['context'], 'This is why I need to know');

      await service.submitAnswer(
        questionMsg,
        const AgentQuestionAnswer(selectedLabels: ['A']),
      );
      await answerFuture;
    });

    test('askedByName is forwarded in metadata', () async {
      const request = AgentQuestionRequest(
        conversationId: 'ch-1',
        question: 'Q',
        askedByAgentId: 'agent-1',
        askedByName: 'Codex',
      );

      final Future<AgentQuestionAnswer?> answerFuture = service.ask(request);
      await Future.delayed(const Duration(milliseconds: 10));

      final msgId = messaging._messages.keys
          .firstWhere((k) => messaging._messages[k]!.senderId == 'agent-1');
      final questionMsg = messaging._messages[msgId]!;
      expect(questionMsg.metadata?['askedByName'], 'Codex');

      await service.submitAnswer(
        questionMsg,
        const AgentQuestionAnswer(selectedLabels: ['OK']),
      );
      await answerFuture;
    });
  });
}
