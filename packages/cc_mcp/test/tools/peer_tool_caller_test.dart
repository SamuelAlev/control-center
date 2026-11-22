import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/peer_tool_caller.dart';
import 'package:test/test.dart';

import '../../../cc_infra/test/dispatch/peer_test_kit.dart';

/// `PeerCaller` reads who calls a peer tool from the call's trusted parts
/// only: the forced identity argument, the attested run and its
/// conversation. A scope that is not a run's grant names no run, and a
/// read-only run (a review) is refused before it can wake anyone.
void main() {
  const attested = McpCallScope(
    workspaceId: 'ws-1',
    agentId: 'agent-a',
    conversationId: 'c-scope',
    runLogId: 'run-a',
    attested: true,
  );
  const headersOnly = McpCallScope(
    workspaceId: 'ws-1',
    agentId: 'agent-a',
    conversationId: 'c-scope',
    runLogId: 'run-a',
  );

  group('PeerCaller.of', () {
    test('an attested run: agent from the forced argument, run and '
        'conversation from the grant', () {
      final caller = PeerCaller.of(
        {'from_agent_id': 'agent-a'},
        const McpCallContext(scope: attested),
        agentKey: 'from_agent_id',
      );
      expect(caller.agentId, 'agent-a');
      expect(caller.runId, 'run-a');
      expect(caller.conversationId, 'c-scope');
    });

    test('reads the agent from the named key only', () {
      final caller = PeerCaller.of(
        {'agent_id': 'agent-x', 'requester_id': 'agent-a'},
        const McpCallContext(scope: attested),
        agentKey: 'requester_id',
      );
      expect(caller.agentId, 'agent-a');
    });

    test('an empty or non-string identity argument is no agent', () {
      for (final value in <Object?>['', 42, null]) {
        final caller = PeerCaller.of(
          {'from_agent_id': value},
          const McpCallContext(scope: attested),
          agentKey: 'from_agent_id',
        );
        expect(caller.agentId, isNull, reason: 'value $value');
      }
    });

    test('a scope from headers the caller wrote names no run and no '
        'conversation', () {
      final caller = PeerCaller.of(
        {'from_agent_id': 'agent-a'},
        const McpCallContext(scope: headersOnly),
        agentKey: 'from_agent_id',
      );
      expect(caller.agentId, 'agent-a');
      expect(caller.runId, isNull);
      expect(caller.conversationId, isNull);
    });

    test('a person\'s own client (no scope) has no run', () {
      final caller = PeerCaller.of(
        {'from_agent_id': 'agent-a'},
        const McpCallContext(),
        agentKey: 'from_agent_id',
      );
      expect(caller.runId, isNull);
      expect(caller.conversationId, isNull);
    });

    test('the forced caller conversation wins over the grant\'s', () {
      final caller = PeerCaller.of(
        {
          'from_agent_id': 'agent-a',
          McpCallScope.callerConversationKey: 'c-forced',
        },
        const McpCallContext(scope: attested),
        agentKey: 'from_agent_id',
      );
      expect(caller.conversationId, 'c-forced');
    });

    test('an empty caller conversation falls back to the grant', () {
      final caller = PeerCaller.of(
        {'from_agent_id': 'agent-a', McpCallScope.callerConversationKey: ''},
        const McpCallContext(scope: attested),
        agentKey: 'from_agent_id',
      );
      expect(caller.conversationId, 'c-scope');
    });
  });

  group('readOnlyRefusal', () {
    late PeerKit kit;
    final asked = <(String?, String)>[];

    setUp(() {
      asked.clear();
      kit = PeerKit();
      kit.service.readOnlyRunOf = (conversationId, runId) {
        asked.add((conversationId, runId));
        return runId == 'run-review';
      };
    });

    PeerCaller callerOf(String runId) => PeerCaller.of(
      {'from_agent_id': 'agent-a'},
      McpCallContext(
        scope: McpCallScope(
          workspaceId: 'ws-1',
          agentId: 'agent-a',
          conversationId: 'c-1',
          runLogId: runId,
          attested: true,
        ),
      ),
      agentKey: 'from_agent_id',
    );

    test('a read-only run is refused with the read_only_run kind', () {
      final refusal = callerOf('run-review').readOnlyRefusal(kit.service);
      expect(refusal, isNotNull);
      expect(refusal!.kind, PeerAskRefusals.readOnlyRun);
      expect(refusal.message, contains('read-only'));
      expect(asked.single, ('c-1', 'run-review'));
    });

    test('a writing run is not refused', () {
      expect(callerOf('run-a').readOnlyRefusal(kit.service), isNull);
      expect(asked.single, ('c-1', 'run-a'));
    });

    test('a caller with no attested run is not asked about and not '
        'refused', () {
      final caller = PeerCaller.of(
        {'from_agent_id': 'agent-a'},
        const McpCallContext(scope: headersOnly),
        agentKey: 'from_agent_id',
      );
      expect(caller.readOnlyRefusal(kit.service), isNull);
      expect(asked, isEmpty);
    });
  });

  test('peerDeliveryStatus maps every wake receipt', () {
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
}
