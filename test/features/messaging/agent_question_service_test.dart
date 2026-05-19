import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/messaging/agent_question_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Workspace owning every conversation in this suite; it selects the database
/// the question messages are written into.
const String _workspaceId = 'ws-1';

/// Minimal in-memory [MessagingRepository] capturing sends + updates.
class _FakeMessagingRepo implements MessagingRepository {
  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;

  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <Message>[], hasMore: false));

  final List<Message> sent = [];
  final Map<String, Map<String, dynamic>?> updates = {};
  int _seq = 0;

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
    final mid = id ?? 'msg-${++_seq}';
    sent.add(
      Message(
        id: mid,
        spaceId: spaceId,
        conversationId: conversationId ?? spaceId,
        senderId: senderId,
        senderType: senderType == 'user' ? SenderType.user : SenderType.agent,
        content: content,
        messageType: messageType == 'user_question'
            ? MessageType.userQuestion
            : MessageType.text,
        metadata: metadata,
        createdAt: DateTime(2024),
      ),
    );
    return mid;
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
    updates[messageId] = metadata;
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

Future<Message> _awaitPosted(
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
    test(
      'posts a user_question form and resolves with the submitted answer',
      () async {
        final repo = _FakeMessagingRepo();
        final service = AgentQuestionService(repo);

        final future = service.ask(
          const AgentQuestionRequest(
            workspaceId: _workspaceId,
            spaceId: 'chan-1',
            question: 'Pick one',
            context: 'because',
            options: [
              AgentQuestionOption(label: 'A', description: 'first'),
              AgentQuestionOption(label: 'B'),
            ],
            allowFreeText: true,
            askedByAgentId: 'agent-9',
            askedByName: 'Ada',
          ),
        );

        final msg = await _awaitPosted(repo, service);
        expect(msg.messageType, MessageType.userQuestion);
        expect(msg.spaceId, 'chan-1');
        expect(msg.senderId, 'agent-9');
        expect(msg.senderType, SenderType.agent);
        expect(msg.metadata!['question'], 'Pick one');
        expect(msg.metadata!['allowFreeText'], true);
        expect(msg.metadata!['options'] as List, hasLength(2));

        await service.submitAnswer(
          _workspaceId,
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
      },
    );

    test('returns null without posting when conversationId is empty', () async {
      final repo = _FakeMessagingRepo();
      final service = AgentQuestionService(repo);
      final answer = await service.ask(
        const AgentQuestionRequest(
          workspaceId: _workspaceId,
          spaceId: '',
          question: 'orphan question',
        ),
      );
      expect(answer, isNull);
      expect(repo.sent, isEmpty);
    });

    test('resolves null when no answer arrives before the timeout', () async {
      final repo = _FakeMessagingRepo();
      final service = AgentQuestionService(
        repo,
        timeout: const Duration(milliseconds: 30),
      );
      final answer = await service.ask(
        const AgentQuestionRequest(
          workspaceId: _workspaceId,
          spaceId: 'chan-2',
          question: 'unanswered',
          options: [AgentQuestionOption(label: 'X')],
        ),
      );
      expect(answer, isNull);
    });

    test('submitAnswer for an unknown message id is a safe no-op', () async {
      final repo = _FakeMessagingRepo();
      final service = AgentQuestionService(repo);
      final ghost = Message(
        id: 'nope',
        spaceId: 'c',
        conversationId: 'c',
        senderId: 'a',
        senderType: SenderType.agent,
        content: 'q',
        messageType: MessageType.userQuestion,
        createdAt: DateTime(2024),
      );
      await service.submitAnswer(
        _workspaceId,
        ghost,
        const AgentQuestionAnswer(),
      );
      // Updating still happens (best-effort) but no completer to resolve.
      expect(repo.updates.containsKey('nope'), isTrue);
    });
  });
}
