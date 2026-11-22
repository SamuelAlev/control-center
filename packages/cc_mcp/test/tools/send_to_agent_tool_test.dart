import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_mcp/src/tools/peer_tool_caller.dart';
import 'package:cc_mcp/src/tools/send_to_agent_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

/// `send_to_agent` posts the message in the pair's DM space and wakes the
/// recipient through the wake queue; its receipt says what became of it.
void main() {
  late PeerKit kit;
  late KitMessaging messaging;
  late SendToAgentTool tool;

  setUp(() async {
    kit = PeerKit();
    messaging = KitMessaging(kit);
    kit
      ..agent('agent-a', 'Ada')
      ..agent('agent-b', 'Bo');
    messaging.space('sp-a', agentIds: ['agent-a']);
    kit.run('run-a', agentId: 'agent-a', conversationId: 'c-sp-a');
    tool = SendToAgentTool(
      agents: KitAgents(kit),
      messaging: messaging,
      rateLimiter: PairRateLimiter(),
      service: openGate(),
      peerAsks: kit.service,
    );
    await kit.start();
  });

  Future<Map<String, dynamic>> send(String message) async {
    final result = await tool.callForRun({
      'workspace_id': PeerKit.ws,
      'to_agent_id': 'agent-b',
      'from_agent_id': 'agent-a',
      'message': message,
    }, runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'));
    expect(result.isError, isFalse, reason: result.content.first.text);
    return jsonDecode(result.content.first.text) as Map<String, dynamic>;
  }

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'to_agent_id': 'agent-b',
      'message': 'hello',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('wakes the recipient as a bot run and checks out no repos', () async {
    final body = await send('Please look at the cast.');
    expect(body['recipient_agent_id'], 'agent-b');
    expect(body['delivery_status'], 'woken');
    final run = kit.dispatched.single;
    expect(run.agentId, 'agent-b');
    expect(run.wakeContext.wakeReason, WakeReason.peerMessage);
    expect(run.requestedByUserId, isNull);
    expect(run.mentionChain, ['agent-a']);
    expect(messaging.createdWithRepoIds, isEmpty);
  });

  test('a recipient busy for a person in that conversation: '
      'queued_behind_run, never pushed into the person\'s run', () async {
    await send('first');
    kit.sessions.add(
      KitSession(
        agentId: 'agent-b',
        conversationId: 'c-dm-2',
        runLogId: 'run-person',
        requestedByUserId: 'user-1',
      ),
    );
    final body = await send('second');
    expect(body['delivery_status'], 'queued_behind_run');
    expect(body['delivery_kind'], isNotNull);
    expect(kit.sessions.single.steeringQueue.isEmpty, isTrue);
  });

  test(
    'a peer message starting with /goal or /loop stays plain text',
    () async {
      await send('/goal ship the release');
      await send('/loop 5m check the build');
      final wakes = kit.wakes.all(PeerKit.ws);
      expect(wakes.map((w) => w.payload), [
        '/goal ship the release',
        '/loop 5m check the build',
      ]);
      // The run's turn input is the fixed wake sentence, never the text.
      expect(kit.dispatched.first.prompt, wakeTurnInput);
      expect(kit.dispatched.map((r) => r.wakeContext.wakeReason).toSet(), {
        WakeReason.peerMessage,
      });
    },
  );

  test('messaging an agent that is waiting on you is refused first', () async {
    await kit.asks.insert(
      PeerAsk(
        id: 'ask-b',
        workspaceId: PeerKit.ws,
        askerAgentId: 'agent-b',
        askerConversationId: 'c-sp-b',
        askerSpaceId: 'sp-b',
        recipientAgentId: 'agent-a',
        questionHash: 'h',
        createdAt: kit.now,
        expiresAt: kit.now.add(const Duration(hours: 24)),
      ),
    );
    final result = await tool.callForRun({
      'workspace_id': PeerKit.ws,
      'to_agent_id': 'agent-b',
      'from_agent_id': 'agent-a',
      'message': 'Ping',
    }, runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'));
    expect(result.isError, isTrue);
    expect(refusalField(result, 'kind'), PeerAskRefusals.cycle);
    expect(messaging.posted, isEmpty);
    expect(kit.dispatched, isEmpty);
  });

  test('a read-only run may not message', () async {
    kit.service.readOnlyRunOf = (conversation, run) => run == 'run-a';
    final result = await tool.callForRun({
      'workspace_id': PeerKit.ws,
      'to_agent_id': 'agent-b',
      'from_agent_id': 'agent-a',
      'message': 'Ping',
    }, runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'));
    expect(result.isError, isTrue);
    expect(refusalField(result, 'kind'), PeerAskRefusals.readOnlyRun);
    expect(messaging.posted, isEmpty);
  });

  test('the receipt mapping', () {
    expect(peerDeliveryStatus(const WakeStarted('r')), (
      status: 'woken',
      kind: null,
    ));
    expect(peerDeliveryStatus(const WakePushed('r')), (
      status: 'woken',
      kind: null,
    ));
    expect(peerDeliveryStatus(const WakeWaiting('live_run_other_person')), (
      status: 'queued_behind_run',
      kind: 'live_run_other_person',
    ));
    expect(peerDeliveryStatus(const WakeSkipped('agent_deleted')), (
      status: 'refused',
      kind: 'agent_deleted',
    ));
    expect(peerDeliveryStatus(const WakeDuplicate()), (
      status: 'refused',
      kind: 'duplicate',
    ));
  });

  test('the description ends with the peer guidance', () {
    expect(tool.description, endsWith(peerMessageGuidance));
  });
}
