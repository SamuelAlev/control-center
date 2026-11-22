import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_server_core/src/notification_wire.dart';
import 'package:test/test.dart';

/// A schedule or watch run that finished cleanly (a quiet run) tells no one,
/// in the feed or as a push, unless its message mentions someone: a loop
/// every 20 minutes must not ping every 20 minutes.
void main() {
  MessageReceived reply({required bool quiet, List<Principal>? mentions}) =>
      MessageReceived(
        spaceId: 'sp-1',
        messageId: 'm-1',
        senderName: 'Bot',
        contentPreview: 'Checked the deploy: still green.',
        isAgentMessage: true,
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        occurredAt: DateTime.utc(2026, 11, 19),
        quietRun: quiet,
        mentions: mentions ?? const [],
      );

  test('a quiet run makes no frame', () {
    expect(messageReceivedFrame(reply(quiet: true)), isNull);
  });

  test('a quiet run that mentions a person still reaches them', () {
    final frame = messageReceivedFrame(
      reply(quiet: true, mentions: const [UserPrincipal('user-1')]),
    );
    expect(frame?.method, 'notifications/message_received');
  });

  test('any other run is announced as before', () {
    expect(
      messageReceivedFrame(reply(quiet: false))?.method,
      'notifications/message_received',
    );
  });
}
