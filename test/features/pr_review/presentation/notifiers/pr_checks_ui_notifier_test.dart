import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

CheckRun _check({
  required String name,
  String? workflowName,
  int? workflowRunId,
  CheckRunConclusion? conclusion,
}) {
  return CheckRun(
    name: name,
    status: CheckRunStatus.completed,
    conclusion: conclusion,
    workflowName: workflowName,
    workflowRunId: workflowRunId,
  );
}

void main() {
  group('groupChecksByWorkflow', () {
    test('splits two runs of the same workflow name into separate groups', () {
      // A `pull_request` run and its merge-queue twin both report a
      // "Dependency validation" check; merging them doubled the node's job
      // count and broke the per-job log lookup.
      final groups = groupChecksByWorkflow([
        _check(
          name: 'Dependency validation',
          workflowName: 'CI',
          workflowRunId: 31489247039,
          conclusion: CheckRunConclusion.success,
        ),
        _check(
          name: 'Unit tests (1)',
          workflowName: 'CI',
          workflowRunId: 31489247039,
          conclusion: CheckRunConclusion.success,
        ),
        _check(
          name: 'Dependency validation',
          workflowName: 'CI',
          workflowRunId: 31489247040,
          conclusion: CheckRunConclusion.neutral,
        ),
      ]);

      expect(groups, hasLength(2));
      expect(groups[0].name, 'CI');
      expect(groups[0].runId, 31489247039);
      expect(groups[0].jobs.map((j) => j.name), [
        'Dependency validation',
        'Unit tests (1)',
      ]);
      expect(groups[1].runId, 31489247040);
      expect(groups[1].jobs.single.name, 'Dependency validation');
      expect(groups[0].key, isNot(groups[1].key));
    });

    test('checks without a run id group by workflow name', () {
      final groups = groupChecksByWorkflow([
        _check(name: 'build / lint', conclusion: CheckRunConclusion.success),
        _check(name: 'build / test', conclusion: CheckRunConclusion.success),
        _check(name: 'SonarCloud', conclusion: CheckRunConclusion.success),
      ]);

      expect(groups, hasLength(2));
      expect(groups[0].name, 'build');
      expect(groups[0].runId, isNull);
      expect(groups[0].jobs, hasLength(2));
      expect(groups[0].key, 'build');
      expect(groups[1].name, 'SonarCloud');
    });

    test('a run-scoped group does not absorb name-only checks', () {
      final groups = groupChecksByWorkflow([
        _check(
          name: 'Linting',
          workflowName: 'CI',
          workflowRunId: 42,
          conclusion: CheckRunConclusion.success,
        ),
        _check(
          name: 'Linting',
          workflowName: 'CI',
          conclusion: CheckRunConclusion.success,
        ),
      ]);

      // Same display name, but one check never resolved a run: it stays in
      // its own name-keyed group rather than leaking into the run's card.
      expect(groups, hasLength(2));
      expect(groups[0].runId, 42);
      expect(groups[1].runId, isNull);
    });
  });

  group('WorkflowGroup.key', () {
    test('is the name for external checks and name@runId for runs', () {
      const external = WorkflowGroup(name: 'SonarCloud', jobs: []);
      const run = WorkflowGroup(name: 'CI', runId: 7, jobs: []);
      expect(external.key, 'SonarCloud');
      expect(run.key, 'CI@7');
    });
  });
}
