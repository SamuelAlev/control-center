import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_server_core/src/notification_wire.dart';
import 'package:test/test.dart';

void main() {
  group('messageReceivedFrame', () {
    MessageReceived agentReply({String? conversationId}) => MessageReceived(
      spaceId: 'sp-1',
      messageId: 'm-1',
      senderName: 'Bot',
      contentPreview: 'done',
      isAgentMessage: true,
      workspaceId: 'ws-1',
      conversationId: conversationId,
      occurredAt: DateTime(2026),
    );

    // A space holds parallel conversations: without the conversation the
    // client can only deep-link to the space, which opens its standing one.
    test('carries the conversation the message was posted in', () {
      final frame = messageReceivedFrame(agentReply(conversationId: 'conv-2'));
      expect(frame!.params['space_id'], 'sp-1');
      expect(frame.params['conversation_id'], 'conv-2');
    });

    test('omits conversation_id when the publisher had none', () {
      final frame = messageReceivedFrame(agentReply());
      expect(frame!.params, isNot(contains('conversation_id')));
    });
  });

  group('agentAwaitingInputFrame', () {
    test('omits what the wait did not know', () {
      final frame = agentAwaitingInputFrame(
        AgentAwaitingInput(
          workspaceId: 'ws-1',
          kind: AgentInputKind.approval,
          summary: 'Push to main',
          occurredAt: DateTime(2026),
        ),
      );
      expect(frame.method, 'notifications/agent_awaiting_input');
      expect(frame.params, {
        'workspace_id': 'ws-1',
        'kind': 'approval',
        'summary': 'Push to main',
      });
    });
  });
}
