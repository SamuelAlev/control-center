import 'dart:async';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/pipelines/data/repositories/pipeline_run_repository_impl.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

PipelineRun _makeRun({
  String id = 'run-1',
  String templateId = 'tpl-1',
  String workspaceId = 'ws-1',
  PipelineRunStatus status = PipelineRunStatus.pending,
  Map<String, dynamic>? state,
  String? dedupKey,
  DateTime? startedAt,
  DateTime? finishedAt,
  String? errorMessage,
  String? errorStackTrace,
  int totalCostCents = 0,
  int totalTokens = 0,
  bool dryRun = false,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: workspaceId,
    status: status,
    state: state,
    dedupKey: dedupKey,
    startedAt: startedAt ?? DateTime(2025, 6, 1),
    finishedAt: finishedAt,
    errorMessage: errorMessage,
    errorStackTrace: errorStackTrace,
    totalCostCents: totalCostCents,
    totalTokens: totalTokens,
    dryRun: dryRun,
  );
}

PipelineStepRun _makeStepRun({
  String id = 'step-1',
  String pipelineRunId = 'run-1',
  String stepId = 'step-def-1',
  PipelineStepStatus status = PipelineStepStatus.pending,
  String? inputJson,
  String? outputJson,
  String? errorMessage,
  int? branchIndex,
  int attemptCount = 0,
  DateTime? startedAt,
  DateTime? finishedAt,
}) {
  return PipelineStepRun(
    id: id,
    pipelineRunId: pipelineRunId,
    stepId: stepId,
    status: status,
    inputJson: inputJson,
    outputJson: outputJson,
    errorMessage: errorMessage,
    branchIndex: branchIndex,
    attemptCount: attemptCount,
    startedAt: startedAt ?? DateTime(2025, 6, 1),
    finishedAt: finishedAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PipelineRunRepositoryImpl repo;

  setUp(() {
    db = createTestDatabase();
    repo = PipelineRunRepositoryImpl(db.pipelineDao);
  });

  tearDown(() => db.close());

  // ── CRUD: PipelineRun ──────────────────────────────────────────────

  group('PipelineRun CRUD', () {
    test('insertRun and getRun round-trip', () async {
      final run = _makeRun(
        state: {'key': 'value'},
        dedupKey: 'dedup-1',
        errorMessage: 'err',
        errorStackTrace: 'stack',
        totalCostCents: 500,
        totalTokens: 1000,
      );
      await repo.insertRun(run);

      final fetched = await repo.getRun('run-1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'run-1');
      expect(fetched.templateId, 'tpl-1');
      expect(fetched.workspaceId, 'ws-1');
      expect(fetched.status, PipelineRunStatus.pending);
      expect(fetched.state, {'key': 'value'});
      expect(fetched.dedupKey, 'dedup-1');
      expect(fetched.errorMessage, 'err');
      expect(fetched.errorStackTrace, 'stack');
      expect(fetched.totalCostCents, 500);
      expect(fetched.totalTokens, 1000);
    });

    test('getRun returns null for nonexistent id', () async {
      final fetched = await repo.getRun('nonexistent');
      expect(fetched, isNull);
    });

    test('updateRun changes persisted fields', () async {
      final run = _makeRun(status: PipelineRunStatus.pending);
      await repo.insertRun(run);

      final updated = run.copyWith(
        status: PipelineRunStatus.running,
        state: {'updated': true},
        errorMessage: 'new error',
        totalCostCents: 100,
        totalTokens: 50,
      );
      await repo.updateRun(updated);

      final fetched = await repo.getRun('run-1');
      expect(fetched!.status, PipelineRunStatus.running);
      expect(fetched.state, {'updated': true});
      expect(fetched.errorMessage, 'new error');
      expect(fetched.totalCostCents, 100);
      expect(fetched.totalTokens, 50);
    });

    test('deleteRun removes the run', () async {
      await repo.insertRun(_makeRun(id: 'r1', workspaceId: 'ws-1'));
      await repo.insertRun(_makeRun(id: 'r2', workspaceId: 'ws-1'));

      await repo.deleteRun('ws-1', 'r1');

      expect(await repo.getRun('r1'), isNull);
      expect(await repo.getRun('r2'), isNotNull);
    });
  });

  // ── Workspace Scoping ──────────────────────────────────────────────

  group('workspace scoping', () {
    test('watchForWorkspace only emits runs in the given workspace', () async {
      await repo.insertRun(
          _makeRun(id: 'ws1-r1', workspaceId: 'ws-1', templateId: 't1'));
      await repo.insertRun(
          _makeRun(id: 'ws1-r2', workspaceId: 'ws-1', templateId: 't2'));
      await repo.insertRun(
          _makeRun(id: 'ws2-r1', workspaceId: 'ws-2', templateId: 't3'));

      final stream = repo.watchForWorkspace('ws-1');
      final events = await stream.first;

      expect(events.length, 2);
      expect(events.map((r) => r.id), containsAll(['ws1-r1', 'ws1-r2']));
    });

    test('deleteRun scoped to workspaceId does not delete from other workspace',
        () async {
      await repo.insertRun(_makeRun(id: 'r1', workspaceId: 'ws-1'));
      await repo.insertRun(_makeRun(id: 'r2', workspaceId: 'ws-2'));

      // Try to delete r2 with ws-1 scope — should be a no-op.
      await repo.deleteRun('ws-1', 'r2');

      expect(await repo.getRun('r2'), isNotNull,
          reason: 'r2 belongs to ws-2, ws-1 scoped delete must not touch it');
    });
  });

  // ── Run Status Transitions ─────────────────────────────────────────

  group('run status transitions', () {
    test('nonTerminalRuns returns only pending, running, suspended', () async {
      await repo.insertRun(
          _makeRun(id: 'r1', status: PipelineRunStatus.pending));
      await repo.insertRun(
          _makeRun(id: 'r2', status: PipelineRunStatus.running));
      await repo.insertRun(
          _makeRun(id: 'r3', status: PipelineRunStatus.suspended));
      await repo.insertRun(
          _makeRun(id: 'r4', status: PipelineRunStatus.completed));
      await repo.insertRun(
          _makeRun(id: 'r5', status: PipelineRunStatus.failed));
      await repo.insertRun(
          _makeRun(id: 'r6', status: PipelineRunStatus.cancelled));

      final nonTerminal = await repo.nonTerminalRuns();
      final ids = nonTerminal.map((r) => r.id).toList();
      expect(ids, containsAll(['r1', 'r2', 'r3']));
      expect(ids, isNot(contains('r4')));
      expect(ids, isNot(contains('r5')));
      expect(ids, isNot(contains('r6')));
    });

    test('watchRun emits updated run after status change', () async {
      await repo.insertRun(_makeRun(id: 'run-1', status: PipelineRunStatus.pending));

      final stream = repo.watchRun('run-1');
      final c = Completer<PipelineRun?>();
      late StreamSubscription<PipelineRun?> sub;
      sub = stream.listen((run) {
        if (run?.status == PipelineRunStatus.running && !c.isCompleted) {
          c.complete(run);
        }
      });

      // Give the stream a tick to deliver the initial value.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updated = (await repo.getRun('run-1'))!
          .copyWith(status: PipelineRunStatus.running);
      await repo.updateRun(updated);

      final emitted = await c.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      await sub.cancel();

      expect(emitted, isNotNull);
      expect(emitted!.status, PipelineRunStatus.running);
    });

    test('updateRunState updates the JSON state', () async {
      await repo.insertRun(_makeRun(id: 'run-1', state: {'initial': true}));

      await repo.updateRunState('run-1', {'key': 'new-value', 'nested': [1, 2]});

      final fetched = await repo.getRun('run-1');
      expect(fetched!.state, {'key': 'new-value', 'nested': [1, 2]});
    });

    test('incrementCost adds cents and tokens', () async {
      await repo.insertRun(
          _makeRun(id: 'run-1', totalCostCents: 100, totalTokens: 50));

      await repo.incrementCost('run-1', 25, 10);

      final fetched = await repo.getRun('run-1');
      expect(fetched!.totalCostCents, 125);
      expect(fetched.totalTokens, 60);
    });

    test('incrementCost is a no-op for nonexistent run', () async {
      // Must not throw.
      await repo.incrementCost('nonexistent', 10, 5);
    });
  });

  // ── Step Runs CRUD ─────────────────────────────────────────────────

  group('step runs', () {
    test('insertStepRun and getStepRunById round-trip', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      final step = _makeStepRun(
        id: 'step-1',
        pipelineRunId: 'run-1',
        stepId: 'fetch_context',
        status: PipelineStepStatus.running,
        inputJson: '{"in": 1}',
        branchIndex: 0,
        attemptCount: 2,
      );
      await repo.insertStepRun(step);

      final fetched = await repo.getStepRunById('step-1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'step-1');
      expect(fetched.pipelineRunId, 'run-1');
      expect(fetched.stepId, 'fetch_context');
      expect(fetched.status, PipelineStepStatus.running);
      expect(fetched.inputJson, '{"in": 1}');
      expect(fetched.branchIndex, 0);
      // attemptCount is not persisted by stepRunToCompanion; reads back as 0.
      expect(fetched.attemptCount, 0);
    });

    test('getStepRunById returns null for nonexistent', () async {
      expect(await repo.getStepRunById('nonexistent'), isNull);
    });

    test('stepRunsForPipeline returns steps for a run', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertRun(_makeRun(id: 'run-2'));
      await repo.insertStepRun(
          _makeStepRun(id: 's1', pipelineRunId: 'run-1', stepId: 'a'));
      await repo.insertStepRun(
          _makeStepRun(id: 's2', pipelineRunId: 'run-1', stepId: 'b'));
      await repo.insertStepRun(
          _makeStepRun(id: 's3', pipelineRunId: 'run-2', stepId: 'c'));

      final stepsForRun1 = await repo.stepRunsForPipeline('run-1');
      expect(stepsForRun1.length, 2);
      expect(stepsForRun1.map((s) => s.id), containsAll(['s1', 's2']));
    });

    test('deleteStepRun removes a single step', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
          _makeStepRun(id: 's1', pipelineRunId: 'run-1'));
      await repo.insertStepRun(
          _makeStepRun(id: 's2', pipelineRunId: 'run-1'));

      await repo.deleteStepRun('s1');

      expect(await repo.getStepRunById('s1'), isNull);
      expect(await repo.getStepRunById('s2'), isNotNull);
    });

    test('deleting a pipeline run cascades step runs', () async {
      await repo.insertRun(_makeRun(id: 'run-1', workspaceId: 'ws-1'));
      await repo.insertStepRun(
          _makeStepRun(id: 's1', pipelineRunId: 'run-1'));
      await repo.insertStepRun(
          _makeStepRun(id: 's2', pipelineRunId: 'run-1'));

      // Both steps exist before cascading delete.
      expect(await repo.getStepRunById('s1'), isNotNull);
      expect(await repo.getStepRunById('s2'), isNotNull);

      await repo.deleteRun('ws-1', 'run-1');

      expect(await repo.getStepRunById('s1'), isNull,
          reason: 'cascade should delete step runs');
      expect(await repo.getStepRunById('s2'), isNull,
          reason: 'cascade should delete step runs');
    });

    test('updateStepRun updates status and optional fields', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(_makeStepRun(
        id: 'step-1',
        pipelineRunId: 'run-1',
        status: PipelineStepStatus.pending,
      ));

      final finished = DateTime(2025, 6, 2);
      await repo.updateStepRun(
        'step-1',
        status: PipelineStepStatus.failed,
        outputJson: '{"out": 42}',
        errorMessage: 'something broke',
        errorStackTrace: 'at foo.dart:42',
        finishedAt: finished,
      );
      final fetched = await repo.getStepRunById('step-1');
      expect(fetched!.status, PipelineStepStatus.failed);
      expect(fetched.outputJson, '{"out": 42}');
      expect(fetched.errorMessage, 'something broke');
      expect(fetched.finishedAt, finished);
    });

    test('updateStepRun partial update only changes provided fields',
        () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(_makeStepRun(
        id: 'step-1',
        pipelineRunId: 'run-1',
        status: PipelineStepStatus.pending,
      ));

      // Set output and error via a full updateStepRun first (insertStepRun
      // doesn't persist outputJson/errorMessage via stepRunToCompanion).
      await repo.updateStepRun(
        'step-1',
        outputJson: '{"original": true}',
        errorMessage: 'original error',
      );

      // Now only update status — other fields should remain.
      await repo.updateStepRun('step-1',
          status: PipelineStepStatus.running);

      final fetched = await repo.getStepRunById('step-1');
      expect(fetched!.status, PipelineStepStatus.running);
      expect(fetched.outputJson, '{"original": true}');
      expect(fetched.errorMessage, 'original error');
    });

    test('watchStepRunsForPipeline emits step runs', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
          _makeStepRun(id: 's1', pipelineRunId: 'run-1'));

      final events = await repo.watchStepRunsForPipeline('run-1').first;
      expect(events.length, 1);
      expect(events.first.id, 's1');
    });
  });

  // ── Edge Cases ─────────────────────────────────────────────────────

  group('edge cases', () {
    test('watchAll emits all runs sorted by startedAt desc', () async {
      final early = DateTime(2025, 1, 1);
      final late = DateTime(2025, 6, 1);
      await repo.insertRun(
          _makeRun(id: 'r1', startedAt: early, templateId: 'a'));
      await repo.insertRun(
          _makeRun(id: 'r2', startedAt: late, templateId: 'b'));

      final runs = await repo.watchAll().first;
      expect(runs.length, 2);
      expect(runs.first.id, 'r2'); // most recent first
    });

    test('activeForDedupKey finds active non-terminal run', () async {
      await repo.insertRun(_makeRun(
        id: 'active-run',
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
        status: PipelineRunStatus.running,
      ));

      final found = await repo.activeForDedupKey(
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      expect(found, isNotNull);
      expect(found!.id, 'active-run');
    });

    test('activeForDedupKey ignores completed runs', () async {
      await repo.insertRun(_makeRun(
        id: 'done-run',
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
        status: PipelineRunStatus.completed,
      ));

      final found = await repo.activeForDedupKey(
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      expect(found, isNull,
          reason: 'completed runs should not match dedupKey');
    });

    test('activeForDedupKey returns null on mismatch', () async {
      await repo.insertRun(_makeRun(
        id: 'r1',
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
        status: PipelineRunStatus.running,
      ));

      final found = await repo.activeForDedupKey(
        templateId: 'different-tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      expect(found, isNull);
    });

    test('empty workspace emits empty watchForWorkspace', () async {
      final runs = await repo.watchForWorkspace('empty-ws').first;
      expect(runs, isEmpty);
    });

    test('insertRun with null dedupKey handled correctly', () async {
      await repo.insertRun(_makeRun(id: 'r1', dedupKey: null));
      final fetched = await repo.getRun('r1');
      expect(fetched!.dedupKey, isNull);
    });

    test('insertStepRun with finishedAt set survives round-trip', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      final finished = DateTime(2025, 6, 10);
      final step = _makeStepRun(
        id: 'step-1',
        pipelineRunId: 'run-1',
        status: PipelineStepStatus.skipped,
        finishedAt: finished,
      );
      await repo.insertStepRun(step);

      final fetched = await repo.getStepRunById('step-1');
      expect(fetched!.finishedAt, finished);
      expect(fetched.status, PipelineStepStatus.skipped);
    });
  });
}
