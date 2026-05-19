import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_run_canvas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareCheckRunNamesNaturally', () {
    test('numeric suffixes sort numerically, not lexically', () {
      final names = [
        'Job (3)',
        'Job (10)',
        'Job (1)',
        'Job (7)',
        'Job (4)',
        'Job (6)',
        'Job (9)',
        'Job (8)',
        'Job (2)',
        'Job (5)',
      ]..sort(compareCheckRunNamesNaturally);
      expect(names, [for (var i = 1; i <= 10; i++) 'Job ($i)']);
    });

    test('falls back to lexical order without digits', () {
      expect(compareCheckRunNamesNaturally('Job (a)', 'Job (b)'), isNegative);
      expect(compareCheckRunNamesNaturally('build', 'build'), 0);
    });
  });

  group('matchCheckRunsToGraphNodes', () {
    test('matrix children come back naturally sorted', () {
      final nodes = [WorkflowJobNode(id: 'matrix', name: 'Job')];
      final checks = [
        for (final i in [3, 10, 1, 7, 4, 6, 9, 8, 2, 5])
          CheckRun(
            name: 'Job ($i)',
            status: CheckRunStatus.completed,
            conclusion: CheckRunConclusion.success,
          ),
      ];
      final result = matchCheckRunsToGraphNodes(nodes, checks);
      expect(result.unmatched, isEmpty);
      expect(result.byNodeId['matrix']!.map((c) => c.name), [
        for (var i = 1; i <= 10; i++) 'Job ($i)',
      ]);
    });

    test('a templated job name matches its substituted check runs', () {
      final nodes = [
        WorkflowJobNode(id: 'lint-typecheck', name: 'Lint & Typecheck'),
        WorkflowJobNode(
          id: 'component-tests',
          name:
              'Component Tests '
              r'(shard ${{ matrix.shard }}/${{ strategy.job-total }})',
        ),
        WorkflowJobNode(
          id: 'rte-component-tests',
          name:
              'RTE Component Tests '
              r'(shard ${{ matrix.shard }}/${{ strategy.job-total }})',
        ),
      ];
      final checks = [
        _check('Lint & Typecheck'),
        for (var i = 1; i <= 4; i++) _check('Component Tests (shard $i/4)'),
        for (var i = 1; i <= 4; i++) _check('RTE Component Tests (shard $i/4)'),
      ];

      final result = matchCheckRunsToGraphNodes(nodes, checks);

      expect(result.unmatched, isEmpty);
      expect(result.byNodeId['lint-typecheck']!.map((c) => c.name), [
        'Lint & Typecheck',
      ]);
      expect(result.byNodeId['component-tests']!.map((c) => c.name), [
        for (var i = 1; i <= 4; i++) 'Component Tests (shard $i/4)',
      ]);
      expect(result.byNodeId['rte-component-tests']!.map((c) => c.name), [
        for (var i = 1; i <= 4; i++) 'RTE Component Tests (shard $i/4)',
      ]);
    });

    test('a template stays anchored and does not swallow a longer name', () {
      final nodes = [
        WorkflowJobNode(
          id: 'component-tests',
          name: r'Component Tests (shard ${{ matrix.shard }}/4)',
        ),
      ];

      final result = matchCheckRunsToGraphNodes(nodes, [
        _check('RTE Component Tests (shard 1/4)'),
      ]);

      expect(result.byNodeId, isEmpty);
      expect(result.unmatched.map((c) => c.name), [
        'RTE Component Tests (shard 1/4)',
      ]);
    });
  });
}

CheckRun _check(String name) => CheckRun(
  name: name,
  status: CheckRunStatus.completed,
  conclusion: CheckRunConclusion.success,
);
