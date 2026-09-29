import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/observability/domain/goal_budget.dart';
import 'package:cc_server_core/src/demo/demo_observability.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 9, 29, 15, 30);

  test('a year of runs names the four demo models', () {
    final runs = buildDemoObservabilityRuns(now);
    final again = buildDemoObservabilityRuns(now);
    expect(
      runs.map((r) => '${r.id}:${r.cost.totalTokens}'),
      again.map((r) => '${r.id}:${r.cost.totalTokens}'),
      reason: 'the same clock must seed the same history',
    );

    final models = runs.map((r) => r.modelId).toSet();
    expect(models, kDemoObservabilityModels.toSet());

    final recent = runs.where(
      (r) => !r.startedAt.isBefore(now.subtract(const Duration(days: 30))),
    );
    expect(recent.map((r) => r.modelId).toSet(), models);

    final byModel = <String, int>{};
    for (final run in runs) {
      byModel.update(
        run.modelId,
        (v) => v + run.cost.totalTokens,
        ifAbsent: () => run.cost.totalTokens,
      );
    }
    for (final model in kDemoObservabilityModels) {
      expect(byModel[model], greaterThan(0), reason: model);
    }

    expect(
      runs.map((r) => r.id).toSet(),
      containsAll(['demo-run-0', 'demo-run-1', 'demo-run-2']),
    );
    expect(runs.where((r) => r.status == RunStatus.error), isNotEmpty);
    expect(runs.where((r) => r.status == RunStatus.running), isNotEmpty);

    final days = runs
        .map(
          (r) => DateTime(r.startedAt.year, r.startedAt.month, r.startedAt.day),
        )
        .toSet();
    expect(days, contains(DateTime(2026, 9, 29)));
    expect(days, contains(DateTime(2026, 9, 19)));
    expect(days.length, greaterThan(80));
    expect(days.length, lessThan(250));

    for (final run in runs) {
      expect(run.startedAt.isAfter(now), isFalse, reason: run.id);
      final completed = run.completedAt;
      if (run.status == RunStatus.running) {
        expect(completed, isNull);
        continue;
      }
      expect(completed, isNotNull);
      expect(completed!.isBefore(run.startedAt), isFalse);
      expect(run.cost.durationMs, greaterThan(0));
      expect(run.cost.totalTokens, greaterThan(0));
    }

    final goalStart = now.subtract(const Duration(days: 6));
    var goalTokens = 0;
    for (final run in runs) {
      if (run.startedAt.isBefore(goalStart)) {
        continue;
      }
      goalTokens += goalTokenDelta(
        input: run.cost.inputTokens,
        output: run.cost.outputTokens + run.cost.thoughtTokens,
        cacheWrite: run.cost.cachedWriteTokens,
      );
    }
    // The demo goal budget is 1.6M. This window should fill part of it
    // on the afternoon the fixture was tuned for, and stay under the cap
    // as the calendar shifts the older days.
    expect(goalTokens, inInclusiveRange(700000, 1500000));
  });

  test('eval seeds and fleet jobs are workspace-scoped and finished', () {
    const workspaceId = 'ws-1';
    final evals = buildDemoEvalSeeds(workspaceId, now);
    expect(evals, hasLength(2));
    expect(evals.expand((e) => e.runs).map((r) => r.passRate), contains(1));
    expect(
      evals.expand((e) => e.runs).map((r) => r.status),
      containsAll(['completed', 'failed']),
    );
    for (final seed in evals) {
      expect(seed.suite.workspaceId, workspaceId);
      for (final run in seed.runs) {
        expect(run.workspaceId, workspaceId);
        expect(run.suiteId, seed.suite.id);
      }
    }

    final jobs = buildDemoFleetJobs(workspaceId, now);
    expect(jobs, hasLength(4));
    expect(jobs.map((j) => j.job.id).toSet(), hasLength(4));
    for (final seed in jobs) {
      expect(seed.job.id, startsWith('$workspaceId:'));
      expect(seed.job.workspaceId, workspaceId);
    }
    final workers = buildDemoFleetWorkers(now);
    expect(workers.map((w) => w.name), [
      'helix-eval-a',
      'helix-eval-b',
      'helix-batch',
    ]);
  });
}
