import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

PlanNode _n(String key, {List<String> deps = const []}) =>
    PlanNode(key: key, title: key, type: PlanNodeType.work, dependsOn: deps);

void main() {
  group('PlanGraphLayout', () {
    test('is deterministic — same graph yields identical offsets', () {
      final graph = PlanGraph(
        nodes: [
          _n('a'),
          _n('b', deps: ['a']),
          _n('c', deps: ['a']),
          _n('d', deps: ['b', 'c']),
        ],
      );
      final first = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      final second = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      expect(first, second);
    });

    test('places nodes in longest-path columns (left to right)', () {
      final graph = PlanGraph(
        nodes: [
          _n('a'),
          _n('b', deps: ['a']),
          _n('c', deps: ['b']),
        ],
      );
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      expect(pos['a']!.dx, 0);
      expect(pos['b']!.dx, greaterThan(pos['a']!.dx));
      expect(pos['c']!.dx, greaterThan(pos['b']!.dx));
    });

    test('stacks siblings in the same column at distinct rows', () {
      final graph = PlanGraph(
        nodes: [
          _n('a'),
          _n('b', deps: ['a']),
          _n('c', deps: ['a']),
        ],
      );
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      // b and c share a column (same x) but different rows (different y).
      expect(pos['b']!.dx, pos['c']!.dx);
      expect(pos['b']!.dy, isNot(pos['c']!.dy));
    });

    test('does not loop on a cyclic graph (defensive)', () {
      final graph = PlanGraph(
        nodes: [
          _n('a', deps: ['b']),
          _n('b', deps: ['a']),
        ],
      );
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      expect(pos.length, 2);
    });

    test('empty graph yields no positions', () {
      final pos = PlanGraphLayout.compute(
        const PlanGraph(nodes: []),
        nodeWidth: 200,
        nodeHeight: 90,
      );
      expect(pos, isEmpty);
    });

    test('wraps an over-wide rank into lanes instead of one tall column', () {
      // The edgeless plan: 30 independent roots. Unwrapped this is a
      // one-node-wide, 30-node-tall ribbon.
      final graph = PlanGraph(nodes: [for (var i = 0; i < 30; i++) _n('n$i')]);
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );

      final byLane = <double, int>{};
      for (final p in pos.values) {
        byLane[p.dx] = (byLane[p.dx] ?? 0) + 1;
      }
      expect(byLane.length, 5, reason: '30 nodes over a cap of 6 → 5 lanes');
      expect(
        byLane.values,
        everyElement(lessThanOrEqualTo(PlanGraphLayout.defaultMaxRowsPerRank)),
      );
      // Every node keeps a distinct slot: no two share a position.
      expect(pos.values.toSet().length, 30);
    });

    test('balances lanes rather than leaving a stub lane', () {
      final graph = PlanGraph(nodes: [for (var i = 0; i < 7; i++) _n('n$i')]);
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      final byLane = <double, int>{};
      for (final p in pos.values) {
        byLane[p.dx] = (byLane[p.dx] ?? 0) + 1;
      }
      // 7 over a cap of 6 splits 4/3, not 6/1.
      expect(byLane.values.toList()..sort(), [3, 4]);
    });

    test('a wrapped rank pushes later ranks clear of its lanes', () {
      final graph = PlanGraph(
        nodes: [
          for (var i = 0; i < 7; i++) _n('root$i'),
          _n('child', deps: ['root0']),
        ],
      );
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      final widestRoot = [
        for (var i = 0; i < 7; i++) pos['root$i']!.dx,
      ].reduce((a, b) => a > b ? a : b);
      expect(pos['child']!.dx, greaterThan(widestRoot));
    });

    test('honours a caller-supplied row cap', () {
      final graph = PlanGraph(nodes: [for (var i = 0; i < 4; i++) _n('n$i')]);
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
        maxRowsPerRank: 2,
      );
      expect(pos.values.map((p) => p.dx).toSet().length, 2);
    });

    test('a cap below 1 is clamped, not divided by zero', () {
      final graph = PlanGraph(nodes: [_n('a'), _n('b')]);
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
        maxRowsPerRank: 0,
      );
      // One row per lane: two nodes, two lanes.
      expect(pos.values.map((p) => p.dx).toSet().length, 2);
    });

    test('wrapping leaves an ordinary DAG unwrapped', () {
      final graph = PlanGraph(
        nodes: [
          _n('a'),
          _n('b', deps: ['a']),
          _n('c', deps: ['a']),
          _n('d', deps: ['b', 'c']),
        ],
      );
      final pos = PlanGraphLayout.compute(
        graph,
        nodeWidth: 200,
        nodeHeight: 90,
      );
      // Three ranks, three lanes: a | b,c | d.
      expect(pos.values.map((p) => p.dx).toSet().length, 3);
      expect(pos['b']!.dx, pos['c']!.dx);
      // d sits centred between its two predecessors.
      expect(pos['d']!.dy, (pos['b']!.dy + pos['c']!.dy) / 2);
    });
  });
}
