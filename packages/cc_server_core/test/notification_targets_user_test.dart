import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_server_core/src/notification_wire.dart';
import 'package:test/test.dart';

/// The one "who is notified" rule. Clients render what the server forwards;
/// every routing case lives here rather than in three client copies.
void main() {
  const reply = <String, dynamic>{
    'workspace_id': 'ws-1',
    'space_id': 'sp-1',
    'message_id': 'm-1',
    'sender_name': 'Bot',
    'content_preview': 'done',
    'is_agent_message': true,
  };
  bool targets(String method, Map<String, dynamic> p, String user) =>
      notificationTargetsUser(method, p, user);
  const message = 'notifications/message_received';

  test("someone else's requested run is not mine; a mention always is", () {
    final theirs = {...reply, 'requested_by_user_id': 'other'};
    expect(targets(message, theirs, 'me'), isFalse);
    expect(
      targets(message, {
        ...theirs,
        'mentions': ['user:me'],
      }, 'me'),
      isTrue,
    );
    expect(targets(message, reply, 'me'), isTrue);
  });

  test('my own message never pings me, even when I mention myself', () {
    expect(
      targets(message, {
        ...reply,
        'is_agent_message': false,
        'sender_user_id': 'me',
        'mentions': ['user:me'],
      }, 'me'),
      isFalse,
    );
  });

  test('an un-mentioned human message pings nobody', () {
    expect(
      targets(message, {
        ...reply,
        'is_agent_message': false,
        'sender_user_id': 'grace',
      }, 'me'),
      isFalse,
    );
  });

  test('agent-only spaces are silent unless they mention me', () {
    final frame = messageReceivedFrame(
      MessageReceived(
        spaceId: 'peer',
        messageId: 'm-2',
        senderName: 'Reviewer',
        contentPreview: 'replying to ask_agent',
        isAgentMessage: true,
        workspaceId: 'ws-1',
        inAgentOnlySpace: true,
        occurredAt: DateTime.utc(2026),
      ),
    )!;
    expect(frame.params['agent_only_space'], isTrue);
    expect(targets(frame.method, frame.params, 'me'), isFalse);
    expect(
      targets(frame.method, {
        ...frame.params,
        'mentions': ['user:me'],
      }, 'me'),
      isTrue,
    );
  });

  test('directed frames reach only their recipient', () {
    const p = {'workspace_id': 'ws-1', 'for_user_id': 'user-2'};
    expect(targets('notifications/pr_ready_to_merge', p, 'user-1'), isFalse);
    expect(targets('notifications/pr_ready_to_merge', p, 'user-2'), isTrue);
    expect(
      targets('notifications/pr_ready_to_merge', const {
        'workspace_id': 'ws-1',
      }, 'user-1'),
      isTrue,
    );
  });

  test('a human ticket assignment pings only the assignee', () {
    const p = {
      'workspace_id': 'ws-1',
      'assignee_type': 'user',
      'assigned_agent_id': 'teammate',
    };
    expect(targets('notifications/ticket_assigned', p, 'me'), isFalse);
    expect(targets('notifications/ticket_assigned', p, 'teammate'), isTrue);
  });

  test('a rig take-over is not reported back to whoever took it', () {
    const p = {'workspace_id': 'ws-1', 'held': true, 'controller': 'user:me'};
    expect(targets('notifications/rig_control_changed', p, 'me'), isFalse);
    expect(targets('notifications/rig_control_changed', p, 'other'), isTrue);
    expect(
      targets('notifications/rig_control_changed', const {
        'workspace_id': 'ws-1',
        'held': false,
      }, 'me'),
      isTrue,
    );
  });
}
