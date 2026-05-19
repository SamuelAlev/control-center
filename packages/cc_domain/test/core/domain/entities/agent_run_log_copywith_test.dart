import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:test/test.dart';

/// Guards against copyWith field-omission — a class of bug invisible to
/// `dart analyze` (an omitted field silently takes its constructor default).
/// The subagent-cost rollup does `parent.copyWith(childCostCents: v)` on every
/// child completion, so any field copyWith forgets is silently reset on persist.
void main() {
  group('AgentRunLog.copyWith preservation', () {
    final base = AgentRunLog(
      id: 'r1',
      agentId: 'a1',
      workspaceId: 'ws-1',
      startedAt: DateTime(2025, 6, 1),
      status: RunStatus.running,
      cost: const RunCost(
        inputTokens: 10,
        outputTokens: 5,
        estimatedCostCents: 3,
      ),
      role: AgentRunRole.sub,
      childCostCents: 42,
      outputContractMode: OutputContractMode.permissive,
      expectedOutputSchema: const {'type': 'object'},
      lastOutputAt: DateTime(2025, 6, 1, 12),
    );

    test('a single-field copyWith preserves every other field', () {
      // Mirrors the propagator's write: bump only childCostCents.
      final next = base.copyWith(childCostCents: 99);

      expect(next.childCostCents, 99, reason: 'the changed field applies');
      // Everything else must survive — especially the contract mode, which a
      // forgotten copyWith line would silently reset to strict.
      expect(next.outputContractMode, OutputContractMode.permissive);
      expect(next.role, AgentRunRole.sub);
      expect(next.expectedOutputSchema, {'type': 'object'});
      expect(next.cost.inputTokens, 10);
      expect(next.cost.estimatedCostCents, 3);
      expect(next.lastOutputAt, DateTime(2025, 6, 1, 12));
      expect(next.status, RunStatus.running);
      expect(next.workspaceId, 'ws-1');
    });

    test('an explicit copyWith argument is honored', () {
      final next = base.copyWith(outputContractMode: OutputContractMode.strict);
      expect(next.outputContractMode, OutputContractMode.strict);
    });

    test('a no-op copyWith is equal to the original', () {
      expect(base.copyWith(), base);
    });
  });
}
