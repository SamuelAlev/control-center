import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_estimator.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:test/test.dart';

const _estimator = PlanEstimator();

RunCost _cost({required int costCents, int? durationMs}) =>
    RunCost(estimatedCostCents: costCents, durationMs: durationMs);

void main() {
  group('PlanEstimator — honesty invariants', () {
    test('a role with no history gets sampleSize 0 and null ranges', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: const {},
      );
      final n1 = estimate.byNodeKey['n1']!;
      expect(n1.sampleSize, 0);
      expect(n1.hasHistory, isFalse);
      expect(n1.costCentsLow, isNull);
      expect(n1.costCentsHigh, isNull);
      expect(n1.durationMsLow, isNull);
      expect(n1.durationMsHigh, isNull);
      expect(estimate.totalCostCentsLow, isNull);
      expect(estimate.totalCostCentsHigh, isNull);
      expect(estimate.totalDurationMsLow, isNull);
      expect(estimate.totalDurationMsHigh, isNull);
      expect(estimate.isPartial, isFalse);
    });

    test('a single sample collapses low == high == the sample', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [_cost(costCents: 750, durationMs: 4200)],
        },
      );
      final n1 = estimate.byNodeKey['n1']!;
      expect(n1.sampleSize, 1);
      expect(n1.hasHistory, isTrue);
      expect(n1.costCentsLow, 750);
      expect(n1.costCentsHigh, 750);
      expect(n1.durationMsLow, 4200);
      expect(n1.durationMsHigh, 4200);
    });

    test('p25/p75 use nearest-rank over a known 5-sample list', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      // Sorted costs: [100, 200, 300, 400, 500]. n=5.
      // p25 rank = round(0.25 * 4) = 1 -> 200.
      // p75 rank = round(0.75 * 4) = 3 -> 400.
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [
            _cost(costCents: 500),
            _cost(costCents: 100),
            _cost(costCents: 400),
            _cost(costCents: 300),
            _cost(costCents: 200),
          ],
        },
      );
      final n1 = estimate.byNodeKey['n1']!;
      expect(n1.sampleSize, 5);
      expect(n1.costCentsLow, 200);
      expect(n1.costCentsHigh, 400);
    });

    test('p25/p75 nearest-rank over a known 2-sample list (clamped)', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      // Sorted costs: [100, 200]. n=2.
      // p25 rank = round(0.25 * 1) = 0 -> 100.
      // p75 rank = round(0.75 * 1) = 1 -> 200.
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [_cost(costCents: 200), _cost(costCents: 100)],
        },
      );
      final n1 = estimate.byNodeKey['n1']!;
      expect(n1.costCentsLow, 100);
      expect(n1.costCentsHigh, 200);
    });

    test('a node without provenance impact has null blast-radius fields', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: const {},
      );
      final n1 = estimate.byNodeKey['n1']!;
      expect(n1.blastRadiusFiles, isNull);
      expect(n1.blastRadiusSymbols, isNull);
    });

    test('a node with a NodeImpact gets populated blast-radius fields', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: const {},
        impactByNodeKey: const {'n1': NodeImpact(files: 7, symbols: 21)},
      );
      final n1 = estimate.byNodeKey['n1']!;
      expect(n1.blastRadiusFiles, 7);
      expect(n1.blastRadiusSymbols, 21);
    });
  });

  group('PlanEstimator — totals', () {
    test('totals sum ranges over estimable nodes only (isPartial=true)', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
          PlanNode(
            key: 'n2',
            title: 'N2',
            type: PlanNodeType.work,
            roleKey: 'r2',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [_cost(costCents: 100), _cost(costCents: 200)],
          // r2 has no history at all.
        },
      );
      expect(estimate.byNodeKey['n1']!.hasHistory, isTrue);
      expect(estimate.byNodeKey['n2']!.hasHistory, isFalse);
      // Only n1 contributes to the totals.
      expect(
        estimate.totalCostCentsLow,
        estimate.byNodeKey['n1']!.costCentsLow,
      );
      expect(
        estimate.totalCostCentsHigh,
        estimate.byNodeKey['n1']!.costCentsHigh,
      );
      expect(estimate.isPartial, isTrue);
    });

    test('all nodes with history: isPartial is false, totals sum both', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
          PlanNode(
            key: 'n2',
            title: 'N2',
            type: PlanNodeType.work,
            roleKey: 'r2',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [_cost(costCents: 100)],
          'r2': [_cost(costCents: 300)],
        },
      );
      expect(estimate.isPartial, isFalse);
      expect(estimate.totalCostCentsLow, 400);
      expect(estimate.totalCostCentsHigh, 400);
    });

    test('no nodes with history: isPartial is false and totals are null', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
          PlanNode(
            key: 'n2',
            title: 'N2',
            type: PlanNodeType.work,
            roleKey: 'r2',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: const {},
      );
      expect(estimate.isPartial, isFalse);
      expect(estimate.totalCostCentsLow, isNull);
      expect(estimate.totalCostCentsHigh, isNull);
    });
  });

  group('PlanEstimator — critical path', () {
    test('a diamond DAG uses the longest path, not the sum', () {
      // a -> b -> d
      // a -> c -> d
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'a',
            title: 'A',
            type: PlanNodeType.work,
            roleKey: 'ra',
          ),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            roleKey: 'rb',
            dependsOn: ['a'],
          ),
          PlanNode(
            key: 'c',
            title: 'C',
            type: PlanNodeType.work,
            roleKey: 'rc',
            dependsOn: ['a'],
          ),
          PlanNode(
            key: 'd',
            title: 'D',
            type: PlanNodeType.work,
            roleKey: 'rd',
            dependsOn: ['b', 'c'],
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          // low=rank0, high=rank1 for a 2-sample list.
          'ra': [
            _cost(costCents: 0, durationMs: 100),
            _cost(costCents: 0, durationMs: 120),
          ],
          'rb': [
            _cost(costCents: 0, durationMs: 200),
            _cost(costCents: 0, durationMs: 240),
          ],
          'rc': [
            _cost(costCents: 0, durationMs: 150),
            _cost(costCents: 0, durationMs: 170),
          ],
          'rd': [
            _cost(costCents: 0, durationMs: 50),
            _cost(costCents: 0, durationMs: 90),
          ],
        },
      );
      // low path: a(100)->b(200)->d(50) = 350 vs a(100)->c(150)->d(50) = 300.
      expect(estimate.totalDurationMsLow, 350);
      // high path: a(120)->b(240)->d(90) = 450 vs a(120)->c(170)->d(90) = 380.
      expect(estimate.totalDurationMsHigh, 450);
      // Emphatically NOT the naive sum of every node's duration.
      expect(estimate.totalDurationMsLow, isNot(100 + 200 + 150 + 50));
      expect(estimate.totalDurationMsHigh, isNot(120 + 240 + 170 + 90));
    });

    test('returns null duration bounds when no node has a duration sample', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'a',
            title: 'A',
            type: PlanNodeType.work,
            roleKey: 'ra',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'ra': [_cost(costCents: 500)], // no durationMs
        },
      );
      expect(estimate.totalDurationMsLow, isNull);
      expect(estimate.totalDurationMsHigh, isNull);
    });
  });

  group('PlanEstimate.exceedsBudget', () {
    test('true when the estimated high total exceeds the ceiling', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [_cost(costCents: 1000)],
        },
        budgetCeilingCents: 500,
      );
      expect(estimate.totalCostCentsHigh, 1000);
      expect(estimate.exceedsBudget, isTrue);
    });

    test('false when the estimated high total is at or under the ceiling', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [_cost(costCents: 500)],
        },
        budgetCeilingCents: 500,
      );
      expect(estimate.exceedsBudget, isFalse);
    });

    test('a null ceiling never exceeds, no matter the total', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: {
          'r1': [_cost(costCents: 1000000)],
        },
      );
      expect(estimate.budgetCeilingCents, isNull);
      expect(estimate.exceedsBudget, isFalse);
    });

    test('a null total (no history) never exceeds even with a ceiling', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'n1',
            title: 'N1',
            type: PlanNodeType.work,
            roleKey: 'r1',
          ),
        ],
      );
      final estimate = _estimator.estimate(
        graph: graph,
        historyByRoleKey: const {},
        budgetCeilingCents: 1,
      );
      expect(estimate.totalCostCentsHigh, isNull);
      expect(estimate.exceedsBudget, isFalse);
    });
  });
}
