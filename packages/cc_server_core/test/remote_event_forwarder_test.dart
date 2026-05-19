import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/remote_event_forwarder.dart';
import 'package:test/test.dart';

/// Unit coverage for [RemoteEventForwarder]'s membership gate: a notification
/// whose `workspace_id` names a workspace the session user does NOT belong to
/// must never reach the wire, member workspaces must flow and a membership
/// change must invalidate the cached verdict within one event round-trip.
void main() {
  group('RemoteEventForwarder membership gate', () {
    late DomainEventBus bus;
    late _FakeChannel channel;

    setUp(() {
      bus = DomainEventBus();
      channel = _FakeChannel();
    });

    tearDown(() {
      bus.dispose();
    });

    RemoteEventForwarder forwarder({
      required Future<bool> Function(String workspaceId) isMember,
    }) {
      final f = RemoteEventForwarder(
        eventBus: bus,
        channel: channel,
        deviceId: 'phone-1',
        userId: 'user-1',
        isMember: isMember,
      );
      f.start();
      addTearDown(f.dispose);
      return f;
    }

    MessageReceived agentMessage(String workspaceId) => MessageReceived(
      channelId: 'c1',
      messageId: 'm1',
      senderName: 'CEO',
      contentPreview: 'hi',
      isAgentMessage: true,
      workspaceId: workspaceId,
      occurredAt: DateTime(2026),
    );

    test('events for a non-member workspace are dropped', () async {
      forwarder(isMember: (_) async => false);
      bus.publish(agentMessage('ws-theirs'));
      bus.publish(
        TicketStatusChanged(
          ticketId: 't1',
          from: 'backlog',
          to: 'doing',
          workspaceId: 'ws-theirs',
          occurredAt: DateTime(2026),
        ),
      );
      await pumpEventQueue(times: 10);
      expect(channel.sent, isEmpty);
    });

    test('events for a member workspace are forwarded', () async {
      forwarder(isMember: (ws) async => ws == 'ws-mine');
      bus.publish(agentMessage('ws-mine'));
      await pumpEventQueue(times: 10);
      expect(channel.sent, hasLength(1));
      expect(channel.sent.single['method'], 'notifications/message_received');
    });

    test('frames without a workspace id pass through (user-targeted)',
        () async {
      forwarder(isMember: (_) async => false);
      // A human mention with no resolved workspace: no workspace_id in the
      // frame — user-targeted, matches the pre-gate behavior.
      bus.publish(
        MessageReceived(
          channelId: 'c1',
          messageId: 'm2',
          senderName: 'Sam',
          contentPreview: 'ping',
          isAgentMessage: false,
          workspaceId: null,
          mentions: const [UserPrincipal('user-1')],
          occurredAt: DateTime(2026),
        ),
      );
      await pumpEventQueue(times: 10);
      expect(channel.sent, hasLength(1));
    });

    test('a membership removal invalidates the cached verdict', () async {
      var member = true;
      forwarder(isMember: (_) async => member);

      bus.publish(agentMessage('ws-x'));
      await pumpEventQueue(times: 10);
      expect(channel.sent, hasLength(1));

      // Revoked: the cache entry must be dropped by the event and the next
      // check (now false) must suppress the notification.
      member = false;
      bus.publish(
        WorkspaceMemberRemoved(
          workspaceId: 'ws-x',
          userId: 'user-1',
          occurredAt: DateTime(2026),
        ),
      );
      await pumpEventQueue(times: 10);
      bus.publish(agentMessage('ws-x'));
      await pumpEventQueue(times: 10);
      expect(channel.sent, hasLength(1));
    });

    test('verdicts are cached per workspace (one check per workspace)',
        () async {
      var checks = 0;
      forwarder(
        isMember: (_) async {
          checks++;
          return true;
        },
      );
      bus.publish(agentMessage('ws-x'));
      bus.publish(agentMessage('ws-x'));
      await pumpEventQueue(times: 10);
      expect(checks, 1);
      expect(channel.sent, hasLength(2));
    });

    test('AgentRunCompleted for a non-member workspace is dropped', () async {
      forwarder(isMember: (_) async => false);
      bus.publish(
        AgentRunCompleted(
          agentId: 'a1',
          workspaceId: 'ws-theirs',
          conversationId: 'conv1',
          occurredAt: DateTime(2026),
        ),
      );
      await pumpEventQueue(times: 10);
      expect(channel.sent, isEmpty);
    });
  });
}

class _FakeChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> sent = [];

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => const Stream.empty();

  @override
  bool get isOpen => true;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    sent.add(frame);
  }

  @override
  Future<void> close() async {
    await _incoming.close();
  }
}
