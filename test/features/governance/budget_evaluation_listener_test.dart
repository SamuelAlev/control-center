import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/governance/domain/services/budget_evaluation_listener.dart';
import 'package:cc_domain/features/governance/domain/services/budget_governance_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every [evaluateAgent] call; the listener under test should drive it
/// exactly once per completed run that carries a workspace.
class _SpyGovernance implements BudgetGovernanceService {
  final List<({String workspaceId, String agentId})> calls = [];

  @override
  Future<BudgetDecision> evaluateAgent({
    required String workspaceId,
    required String agentId,
  }) async {
    calls.add((workspaceId: workspaceId, agentId: agentId));
    return const BudgetDecision(
      outcome: BudgetOutcome.ok,
      spentMicros: 0,
      budgetMicros: 0,
    );
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late DomainEventBus bus;
  late _SpyGovernance governance;

  setUp(() {
    bus = DomainEventBus();
    governance = _SpyGovernance();
    BudgetEvaluationListener(eventBus: bus, governance: governance).start();
  });

  tearDown(() => bus.dispose());

  test('evaluates the agent when one of its runs settles', () async {
    bus.publish(
      AgentRunSettled(
        agentId: 'a1',
        workspaceId: 'ws1',
        spaceId: null,
        conversationId: 'c1',
        runId: 'r1',
        status: RunStatus.completed,
        endReason: RunEndReason.completed,
        costMicros: 0,
        limitResetsAt: null,
        wakeIds: const [],
        requestedByUserId: null,
        wakeReason: null,
        occurredAt: DateTime.utc(2026, 6, 30),
      ),
    );
    await _settle();

    expect(governance.calls, hasLength(1));
    expect(governance.calls.single.workspaceId, 'ws1');
    expect(governance.calls.single.agentId, 'a1');
  });

  test('ignores the pre-write completion event', () async {
    bus.publish(
      AgentRunCompleted(
        agentId: 'a2',
        workspaceId: 'ws1',
        conversationId: 'c2',
        occurredAt: DateTime.utc(2026, 6, 30),
      ),
    );
    await _settle();

    expect(governance.calls, isEmpty);
  });
}
