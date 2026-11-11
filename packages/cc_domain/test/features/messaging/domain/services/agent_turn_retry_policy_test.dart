import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/services/agent_turn_retry_policy.dart';
import 'package:test/test.dart';

const _policy = AgentTurnRetryPolicy();

const _failed = {'error': true};
const _retried = {'error': true, 'retried': true};

RetryTurn _turn(String id, String agentId, [Object? metadata]) =>
    (id: id, agentId: agentId, metadata: metadata);

Message _message(
  String id, {
  String senderId = 'agent-1',
  SenderType senderType = SenderType.agent,
  MessageType messageType = MessageType.agentTurn,
  Map<String, dynamic>? metadata,
}) => Message(
  id: id,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  senderId: senderId,
  senderType: senderType,
  content: '',
  messageType: messageType,
  metadata: metadata,
  createdAt: DateTime(2026),
);

void main() {
  group('awaitsRetry', () {
    test('a failed turn does, until it is retried', () {
      expect(_policy.awaitsRetry(_failed), isTrue);
      expect(_policy.awaitsRetry(_retried), isFalse);
    });

    test('a turn that did not fail never does', () {
      expect(_policy.awaitsRetry(null), isFalse);
      expect(_policy.awaitsRetry(const <String, dynamic>{}), isFalse);
      expect(_policy.awaitsRetry(const {'error': false}), isFalse);
      // A wire value that is not a map (a lossy surface) is not a failure.
      expect(_policy.awaitsRetry('error'), isFalse);
    });
  });

  group('retryable', () {
    test("only an agent's newest turn, and only when it failed", () {
      expect(
        _policy.retryable([
          _turn('old-failure', 'agent-1', _failed),
          _turn('newer-failure', 'agent-1', _failed),
        ]),
        {'newer-failure'},
      );
    });

    test('a newer turn of any outcome replaces a failed one', () {
      // Still working, finished, or failed and retried: each is a newer turn.
      for (final newer in <Object?>[
        const {'streamComplete': false},
        const {'streamComplete': true},
        _retried,
        null,
      ]) {
        expect(
          _policy.retryable([
            _turn('failure', 'agent-1', _failed),
            _turn('newer', 'agent-1', newer),
          ]),
          isEmpty,
          reason: 'newer turn: $newer',
        );
      }
    });

    test('a retried turn cannot be retried again', () {
      expect(
        _policy.retryable([_turn('failure', 'agent-1', _retried)]),
        isEmpty,
      );
    });

    test("another agent's turn replaces nothing", () {
      expect(
        _policy.retryable([
          _turn('a-failure', 'agent-1', _failed),
          _turn('b-answer', 'agent-2', const {'streamComplete': true}),
          _turn('b-failure', 'agent-2', _failed),
        ]),
        {'a-failure', 'b-failure'},
      );
    });

    test('nothing to retry in an empty conversation', () {
      expect(_policy.retryable(const []), isEmpty);
    });
  });

  group('retryableIn', () {
    test('only agent turns count as turns', () {
      expect(
        _policy.retryableIn([
          _message('failure', metadata: _failed),
          // What a person says, a plan the agent posts and a system line are
          // not a newer turn from the agent.
          _message(
            'reply',
            senderId: 'user-1',
            senderType: SenderType.user,
            messageType: MessageType.text,
          ),
          _message('plan', messageType: MessageType.plan),
          _message(
            'notice',
            senderId: 'system',
            senderType: SenderType.system,
            messageType: MessageType.system,
            metadata: _failed,
          ),
        ]),
        {'failure'},
      );
    });

    test('the run answering a later message replaces the failure', () {
      expect(
        _policy.retryableIn([
          _message('failure', metadata: _failed),
          _message(
            'reply',
            senderId: 'user-1',
            senderType: SenderType.user,
            messageType: MessageType.text,
          ),
          _message('working', metadata: const {'streamComplete': false}),
        ]),
        isEmpty,
      );
    });
  });
}
