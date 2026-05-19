import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:control_center/features/pr_review/presentation/utils/workflow_matrix_names.dart';
import 'package:flutter_test/flutter_test.dart';

const String _shardedName =
    'Component Tests '
    r'(shard ${{ matrix.shard }}/${{ strategy.job-total }})';

CheckRun _check(String name) => CheckRun(
  name: name,
  status: CheckRunStatus.completed,
  conclusion: CheckRunConclusion.success,
);

void main() {
  group('MatrixNameTemplate', () {
    test('captures the substituted region of a sharded name', () {
      final template = MatrixNameTemplate.parse(_shardedName)!;
      expect(template.variationOf('Component Tests (shard 1/4)'), '1/4');
      expect(template.variationOf('Component Tests (shard 12/16)'), '12/16');
    });

    test('is null for a literal job name', () {
      expect(MatrixNameTemplate.parse('Lint & Typecheck'), isNull);
    });

    test('rejects names from other jobs', () {
      final template = MatrixNameTemplate.parse(_shardedName)!;
      expect(template.variationOf('RTE Component Tests (shard 1/4)'), isNull);
      expect(template.variationOf('Component Tests (shard 1/4) extra'), isNull);
      expect(template.variationOf('Component Tests (shard /4)'), isNull);
    });

    test('escapes regex metacharacters in the literal parts', () {
      final template = MatrixNameTemplate.parse(
        r'Build [x86] ${{ matrix.os }}',
      )!;
      expect(template.variationOf('Build [x86] ubuntu'), 'ubuntu');
      expect(template.variationOf('Build ax86 ubuntu'), isNull);
    });
  });

  group('workflowNodeTitle', () {
    String matrixLabel(String jobId) => 'Matrix: $jobId';

    test('a templated node with several runs is labelled by its job id', () {
      final node = WorkflowJobNode(id: 'component-tests', name: _shardedName);
      final title = workflowNodeTitle(node, [
        _check('Component Tests (shard 1/4)'),
        _check('Component Tests (shard 2/4)'),
      ], matrixLabel: matrixLabel);
      expect(title, 'Matrix: component-tests');
    });

    test('a single variation shows its resolved name', () {
      final node = WorkflowJobNode(id: 'component-tests', name: _shardedName);
      final title = workflowNodeTitle(node, [
        _check('Component Tests (shard 1/1)'),
      ], matrixLabel: matrixLabel);
      expect(title, 'Component Tests (shard 1/1)');
    });

    test('a literal node keeps its authored name', () {
      final node = WorkflowJobNode(id: 'lint', name: 'Lint & Typecheck');
      final title = workflowNodeTitle(node, [
        _check('Lint & Typecheck'),
      ], matrixLabel: matrixLabel);
      expect(title, 'Lint & Typecheck');
    });
  });

  group('matrixVariationLabel', () {
    test('shortens a templated child to its substitution', () {
      expect(
        matrixVariationLabel(_shardedName, 'Component Tests (shard 3/4)'),
        '3/4',
      );
    });

    test('strips the suffix GitHub appends to a literal job name', () {
      expect(
        matrixVariationLabel('Job', 'Job (ubuntu-latest)'),
        'ubuntu-latest',
      );
    });

    test('falls back to the full name when neither form applies', () {
      expect(matrixVariationLabel('Job', 'Something else'), 'Something else');
      expect(matrixVariationLabel('Job', 'Job ()'), 'Job ()');
    });
  });
}
