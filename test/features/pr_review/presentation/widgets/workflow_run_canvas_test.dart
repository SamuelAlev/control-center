import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_run_canvas.dart';
import 'package:control_center/shared/widgets/graph_node_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('jobs remain selectable after pan, fit and a status refresh', (
    tester,
  ) async {
    final nodes = [
      for (var i = 0; i < 6; i++)
        WorkflowJobNode(
          id: 'job$i',
          name: 'Job $i',
          needs: i == 0 ? [] : ['job${i - 1}'],
        ),
    ];
    String? selected;
    Widget canvas({bool completed = false}) => testWrap(
      WorkflowRunCanvas(
        nodes: nodes,
        checkRunsByNodeId: completed
            ? {
                'job2': [_check('Job 2')],
              }
            : const {},
        selectedNodeId: selected,
        onSelect: (id) => selected = id,
      ),
      textDirection: TextDirection.rtl,
    );
    await tester.pumpWidget(canvas());
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text('Job 0'));
    await tester.dragFrom(const Offset(400, 500), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Job 0')).dx, lessThan(before.dx));
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is CcIconButton && widget.tooltip == 'Fit to view',
      ),
    );
    await tester.pumpAndSettle();
    final selectedCard = find.ancestor(
      of: find.text('Job 2'),
      matching: find.byType(GraphNodeCard),
    );
    final fitted = tester.getTopLeft(selectedCard);
    await tester.tap(find.text('Job 2'));
    expect(selected, 'job2');
    await tester.pumpWidget(canvas(completed: true));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(selectedCard), fitted);
    expect(
      tester.getTopLeft(find.text('Job 0')).dx,
      lessThan(tester.getTopLeft(find.text('Job 5')).dx),
    );
    await tester.tap(find.text('Job 5'));
    expect(selected, 'job5');
  });

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
