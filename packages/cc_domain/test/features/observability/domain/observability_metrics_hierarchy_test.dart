import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/observability_metrics.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:test/test.dart';

/// Builds an [AgentRunLog] with just the fields the calculator reads.
AgentRunLog _run({
  String id = 'r',
  String? parentRunId,
  RunStatus status = RunStatus.completed,
  int costMicros = 0,
  int estimatedCostCents = 0,
  int childCostMicros = 0,
  RunVerification? verification,
}) => AgentRunLog(
  id: id,
  agentId: 'a',
  startedAt: DateTime(2026, 1, 1),
  status: status,
  parentRunId: parentRunId,
  childCostMicros: childCostMicros,
  verification: verification,
  cost: RunCost(estimatedCostCents: estimatedCostCents, costMicros: costMicros),
);

void main() {
  const calc = ObservabilityMetricsCalculator();

  // ---- cost hierarchy: self vs inclusive ----

  group('cost hierarchy', () {
    test('parent and child both present: self cost sums once, inclusive folds '
        'the rollup without double counting', () {
      const parentSelfMicros = 100;
      const childSelfMicros = 5000;
      final m = calc.compute([
        _run(
          id: 'parent',
          costMicros: parentSelfMicros,
          childCostMicros: childSelfMicros,
        ),
        _run(id: 'child', parentRunId: 'parent', costMicros: childSelfMicros),
      ]);

      expect(m.totalCostMicros, parentSelfMicros + childSelfMicros);
      // A child present in the set is already inside its parent's rollup, so
      // inclusive must not add it a second time.
      expect(m.inclusiveCostMicros, m.totalCostMicros);
      // Deliberately wrong sum: adding the rollup ON TOP of the child row.
      const doubleCounted =
          parentSelfMicros + childSelfMicros + childSelfMicros;
      expect(doubleCounted, isNot(m.totalCostMicros));
      expect(doubleCounted, isNot(m.inclusiveCostMicros));
    });

    test(
      'child missing from the set: inclusive adds the parent rollup while self '
      'cost does not',
      () {
        const parentSelfMicros = 250000;
        const childRollupMicros = 750000;
        final m = calc.compute([
          _run(
            id: 'parent',
            costMicros: parentSelfMicros,
            childCostMicros: childRollupMicros,
          ),
        ]);

        expect(m.totalCostMicros, parentSelfMicros);
        expect(m.inclusiveCostMicros, parentSelfMicros + childRollupMicros);
        expect(m.inclusiveCostMicros, greaterThan(m.totalCostMicros));
      },
    );

    test('active parent with no rollup yet: inclusive equals self cost, and '
        'activeRuns is what says the rollup has not landed', () {
      final m = calc.compute([
        _run(
          id: 'parent',
          status: RunStatus.running,
          costMicros: 4000,
          childCostMicros: 0,
        ),
      ]);

      // The equality means "nothing propagated yet", NOT "delegated nothing".
      expect(m.inclusiveCostMicros, m.totalCostMicros);
      expect(m.activeRuns, 1);
      expect(m.activeRuns, greaterThan(0));
    });
  });

  // ---- sub-cent cost precision ----

  group('sub-cent cost precision', () {
    test('two 7-micro runs stay exact in micros and round to zero cents', () {
      final m = calc.compute([
        _run(id: 'a', costMicros: 7),
        _run(id: 'b', costMicros: 7),
      ]);

      expect(m.totalCostMicros, 14);
      expect(m.totalCostCents, 0);
    });

    test('200 runs of 7 micros still round to zero cents', () {
      final m = calc.compute([
        for (var i = 0; i < 200; i++) _run(id: 'r$i', costMicros: 7),
      ]);

      expect(m.totalCostMicros, 1400);
      expect(m.totalCostCents, 0);
    });

    test(
      'a half-dollar run plus two 7-micro runs keeps sub-cent remainder',
      () {
        final m = calc.compute([
          _run(id: 'big', costMicros: 500000),
          _run(id: 'a', costMicros: 7),
          _run(id: 'b', costMicros: 7),
        ]);

        expect(m.totalCostMicros, 500014);
        expect(m.totalCostCents, 50);
      },
    );
  });

  // ---- verified vs completed ----

  group('verified vs completed', () {
    test(
      'completed runs count as successes; only a passed verifier is a verified '
      'success',
      () {
        final m = calc.compute([
          _run(
            id: 'verified',
            verification: const RunVerification(
              status: VerificationStatus.passed,
              verifier: 'behavioral',
            ),
          ),
          _run(
            id: 'rejected',
            verification: const RunVerification(
              status: VerificationStatus.failed,
              verifier: 'behavioral',
            ),
          ),
          _run(id: 'unchecked'),
        ]);

        expect(m.successfulRuns, 3);
        expect(m.verifiedSuccessfulRuns, 1);
        expect(m.verifiedSuccessRate, closeTo(1 / 3, 1e-12));
        expect(m.successRate, 1.0);
        expect(m.successRate, greaterThan(m.verifiedSuccessRate));
      },
    );
  });
}
