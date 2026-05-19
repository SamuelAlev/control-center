import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
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
      spentCents: 0,
      budgetCents: 0,
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

  test('evaluates the agent on a workspace-scoped run completion', () async {
    bus.publish(
      AgentRunCompleted(
        agentId: 'a1',
        workspaceId: 'ws1',
        conversationId: 'c1',
        occurredAt: DateTime.utc(2026, 6, 30),
      ),
    );
    await _settle();

    expect(governance.calls, hasLength(1));
    expect(governance.calls.single.workspaceId, 'ws1');
    expect(governance.calls.single.agentId, 'a1');
  });

  test(
    'skips a run completion with no workspace (cannot scope a budget)',
    () async {
      bus.publish(
        AgentRunCompleted(
          agentId: 'a2',
          workspaceId: null,
          conversationId: 'c2',
          occurredAt: DateTime.utc(2026, 6, 30),
        ),
      );
      await _settle();

      expect(governance.calls, isEmpty);
    },
  );
}
