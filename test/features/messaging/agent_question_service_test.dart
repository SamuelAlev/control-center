import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/ports/agent_question_port.dart';
import 'package:control_center/features/messaging/data/services/agent_question_service.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal in-memory [MessagingRepository] capturing sends + updates.
class _FakeMessagingRepo implements MessagingRepository {
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          Stream.value((messages: const <ChannelMessage>[], hasMore: false));

  final List<ChannelMessage> sent = [];
  final Map<String, Map<String, dynamic>?> updates = {};
  int _seq = 0;

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
    final mid = id ?? 'msg-${++_seq}';
    sent.add(ChannelMessage(
      id: mid,
      channelId: channelId,
      senderId: senderId,
      senderType: senderType == 'user'
          ? ChannelSenderType.user
          : ChannelSenderType.agent,
      content: content,
      messageType: messageType == 'user_question'
          ? ChannelMessageType.userQuestion
          : ChannelMessageType.text,
      metadata: metadata,
      createdAt: DateTime(2024),
    ));
    return mid;
  }

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {
    updates[messageId] = metadata;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Future<ChannelMessage> _awaitPosted(
  _FakeMessagingRepo repo,
  AgentQuestionService service,
) async {
  for (var i = 0; i < 200; i++) {
    if (repo.sent.isNotEmpty && service.isPending(repo.sent.last.id)) {
      return repo.sent.last;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError('question was never posted/registered');
}

void main() {
  group('AgentQuestionService', () {
    test('posts a user_question form and resolves with the submitted answer',
        () async {
      final repo = _FakeMessagingRepo();
      final service = AgentQuestionService(repo);

      final future = service.ask(const AgentQuestionRequest(
        conversationId: 'chan-1',
        question: 'Pick one',
        context: 'because',
        options: [
          AgentQuestionOption(label: 'A', description: 'first'),
          AgentQuestionOption(label: 'B'),
        ],
        allowFreeText: true,
        askedByAgentId: 'agent-9',
        askedByName: 'Ada',
      ));

      final msg = await _awaitPosted(repo, service);
      expect(msg.messageType, ChannelMessageType.userQuestion);
      expect(msg.channelId, 'chan-1');
      expect(msg.senderId, 'agent-9');
      expect(msg.senderType, ChannelSenderType.agent);
      expect(msg.metadata!['question'], 'Pick one');
      expect(msg.metadata!['allowFreeText'], true);
      expect(msg.metadata!['options'] as List, hasLength(2));

      await service.submitAnswer(
        msg,
        const AgentQuestionAnswer(selectedLabels: ['A'], freeText: 'extra'),
      );

      final answer = await future;
      expect(answer, isNotNull);
      expect(answer!.selectedLabels, ['A']);
      expect(answer.freeText, 'extra');

      // The question message was marked answered with the answer payload.
      final updated = repo.updates[msg.id]!;
      expect(updated['answered'], true);
      expect((updated['answer'] as Map)['selected'], ['A']);
      expect(service.isPending(msg.id), isFalse);
    });

    test('returns null without posting when conversationId is empty', () async {
      final repo = _FakeMessagingRepo();
      final service = AgentQuestionService(repo);
      final answer = await service.ask(const AgentQuestionRequest(
        conversationId: '',
        question: 'orphan question',
      ));
      expect(answer, isNull);
      expect(repo.sent, isEmpty);
    });

    test('resolves null when no answer arrives before the timeout', () async {
      final repo = _FakeMessagingRepo();
      final service =
          AgentQuestionService(repo, timeout: const Duration(milliseconds: 30));
      final answer = await service.ask(const AgentQuestionRequest(
        conversationId: 'chan-2',
        question: 'unanswered',
        options: [AgentQuestionOption(label: 'X')],
      ));
      expect(answer, isNull);
    });

    test('submitAnswer for an unknown message id is a safe no-op', () async {
      final repo = _FakeMessagingRepo();
      final service = AgentQuestionService(repo);
      final ghost = ChannelMessage(
        id: 'nope',
        channelId: 'c',
        senderId: 'a',
        senderType: ChannelSenderType.agent,
        content: 'q',
        messageType: ChannelMessageType.userQuestion,
        createdAt: DateTime(2024),
      );
      await service.submitAnswer(ghost, const AgentQuestionAnswer());
      // Updating still happens (best-effort) but no completer to resolve.
      expect(repo.updates.containsKey('nope'), isTrue);
    });
  });
}
