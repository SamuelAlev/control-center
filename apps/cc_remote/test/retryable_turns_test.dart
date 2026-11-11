import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/retryable_turns.dart';
import 'package:flutter_test/flutter_test.dart';

MessageDto _message(
  String id, {
  String senderId = 'agent-1',
  String senderType = 'agent',
  String messageType = 'agent_turn',
  Object? metadata,
}) => MessageDto(
  id: id,
  content: '',
  senderId: senderId,
  senderType: senderType,
  messageType: messageType,
  metadata: metadata,
);

void main() {
  const failed = {'error': true};

  test("Retry is offered on an agent's newest turn, when it failed", () {
    expect(
      retryableTurnIds([
        _message('older-failure', metadata: failed),
        _message('newest-failure', metadata: failed),
        _message('other-agent', senderId: 'agent-2', metadata: failed),
      ]),
      {'newest-failure', 'other-agent'},
    );
  });

  test('not while the agent is working on a newer turn', () {
    expect(
      retryableTurnIds([
        _message('failure', metadata: failed),
        _message('working', metadata: const {'streamComplete': false}),
      ]),
      isEmpty,
    );
  });

  test('not once the failure was retried', () {
    expect(
      retryableTurnIds([
        _message('failure', metadata: const {'error': true, 'retried': true}),
      ]),
      isEmpty,
    );
  });

  test('what a person says after a failure replaces nothing', () {
    expect(
      retryableTurnIds([
        _message('failure', metadata: failed),
        _message(
          'reply',
          senderId: 'user-1',
          senderType: 'user',
          messageType: 'text',
        ),
      ]),
      {'failure'},
    );
  });
}
