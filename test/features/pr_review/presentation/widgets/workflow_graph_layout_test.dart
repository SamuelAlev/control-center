import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nodeWidth = 180.0;
  const nodeHeight = 68.0;

  group('WorkflowGraphLayout.compute', () {
    test('returns an empty map for no jobs', () {
      expect(
        WorkflowGraphLayout.compute(
          const [],
          nodeWidth: nodeWidth,
          nodeHeight: nodeHeight,
        ),
        isEmpty,
      );
    });

    test('diamond graph lays out in three columns by needs depth', () {
      final jobs = [
        WorkflowJobNode(id: 'root', name: 'Root'),
        WorkflowJobNode(id: 'left', name: 'Left', needs: const ['root']),
        WorkflowJobNode(id: 'right', name: 'Right', needs: const ['root']),
        WorkflowJobNode(
          id: 'join',
          name: 'Join',
          needs: const ['left', 'right'],
        ),
      ];
      final positions = WorkflowGraphLayout.compute(
        jobs,
        nodeWidth: nodeWidth,
        nodeHeight: nodeHeight,
      );
      const colPitch = nodeWidth + WorkflowGraphLayout.columnGap;
      expect(positions['root']!.dx, 0);
      expect(positions['left']!.dx, colPitch);
      expect(positions['right']!.dx, colPitch);
      expect(positions['join']!.dx, colPitch * 2);
      // Siblings in one column stack on different rows.
      expect(positions['left']!.dy, isNot(positions['right']!.dy));
    });

    test('chain of needs lays out strictly left to right', () {
      final jobs = [
        WorkflowJobNode(id: 'a', name: 'A'),
        WorkflowJobNode(id: 'b', name: 'B', needs: const ['a']),
        WorkflowJobNode(id: 'c', name: 'C', needs: const ['b']),
        WorkflowJobNode(id: 'd', name: 'D', needs: const ['c']),
      ];
      final positions = WorkflowGraphLayout.compute(
        jobs,
        nodeWidth: nodeWidth,
        nodeHeight: nodeHeight,
      );
      expect(positions['a']!.dx, lessThan(positions['b']!.dx));
      expect(positions['b']!.dx, lessThan(positions['c']!.dx));
      expect(positions['c']!.dx, lessThan(positions['d']!.dx));
    });

    test('ignores needs that reference missing jobs or self', () {
      final jobs = [
        WorkflowJobNode(id: 'a', name: 'A', needs: const ['ghost', 'a']),
        WorkflowJobNode(id: 'b', name: 'B', needs: const ['a']),
      ];
      final positions = WorkflowGraphLayout.compute(
        jobs,
        nodeWidth: nodeWidth,
        nodeHeight: nodeHeight,
      );
      // 'a' has no real predecessors → column 0; 'b' follows it.
      expect(positions['a']!.dx, 0);
      expect(positions['b']!.dx, greaterThan(0));
    });

    test('a needs cycle terminates instead of looping forever', () {
      final jobs = [
        WorkflowJobNode(id: 'a', name: 'A', needs: const ['b']),
        WorkflowJobNode(id: 'b', name: 'B', needs: const ['a']),
      ];
      final positions = WorkflowGraphLayout.compute(
        jobs,
        nodeWidth: nodeWidth,
        nodeHeight: nodeHeight,
      );
      expect(positions, hasLength(2));
    });
  });
}
