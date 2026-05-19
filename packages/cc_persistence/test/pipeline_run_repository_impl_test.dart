import 'dart:async';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

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
  String? triggerEventType,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: workspaceId,
    status: status,
    state: state,
    dedupKey: dedupKey,
    triggerEventType: triggerEventType,
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

/// Counts how often a run id is resolved against `global.db`, so the route
/// cache can be pinned by behaviour rather than by inspecting a private field.
class _CountingRouteDao extends WorkspaceRouteDao {
  _CountingRouteDao(super.db);

  int resolves = 0;

  @override
  Future<String?> resolve(WorkspaceRouteKind kind, String keyHash) {
    resolves++;
    return super.resolve(kind, keyHash);
  }
}

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late PipelineRunRepositoryImpl repo;
  late _CountingRouteDao routes;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in ['ws', 'ws-1', 'ws-2']) {
      await seedTestWorkspace(global, dbs, ws);
    }
    // The route DAO is global: a run id must resolve to its workspace before
    // any workspace file is opened (deep links, worker callbacks).
    routes = _CountingRouteDao(global);
    repo = PipelineRunRepositoryImpl(dbs, routes);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

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

    test('a rerun records its attempt without losing the original start', () async {
      final run = _makeRun(startedAt: DateTime(2025, 6, 1, 9));
      await repo.insertRun(run);
      expect(
        (await repo.getRun('run-1'))!.attemptStartedAt,
        isNull,
        reason: 'a run on its first attempt has nothing to disambiguate',
      );

      final rerunAt = DateTime(2025, 6, 1, 17, 45);
      await repo.updateRun(
        run.copyWith(
          status: PipelineRunStatus.running,
          attemptStartedAt: rerunAt,
        ),
      );

      final fetched = await repo.getRun('run-1');
      expect(fetched!.startedAt, DateTime(2025, 6, 1, 9));
      expect(fetched.attemptStartedAt, rerunAt);
      expect(fetched.currentAttemptStartedAt, rerunAt);
      expect(fetched.wasRestarted, isTrue);
    });

    test('updateRun changes the lifecycle fields', () async {
      final run = _makeRun(status: PipelineRunStatus.pending);
      await repo.insertRun(run);

      await repo.updateRun(
        run.copyWith(
          status: PipelineRunStatus.running,
          errorMessage: 'new error',
        ),
      );

      final fetched = await repo.getRun('run-1');
      expect(fetched!.status, PipelineRunStatus.running);
      expect(fetched.errorMessage, 'new error');
    });

    // A terminal transition is built from a snapshot the caller read some
    // awaits ago, and the state merges and cost rollups that land in between
    // are NOT its to speak for. A whole-row write reverts them: a run completes
    // with the cost of its last agent missing, and a fan-out branch's output
    // vanishes because a sibling failed.
    test('updateRun leaves state and cost to their own writers', () async {
      await repo.insertRun(
        _makeRun(state: {'from': 'insert'}, totalCostCents: 7, totalTokens: 3),
      );
      final stale = (await repo.getRun('run-1'))!;

      // Both land after `stale` was read, exactly as they do in a live run.
      await repo.updateRunState('run-1', {'from': 'a parallel branch'});
      await repo.incrementCost('run-1', 40, 400);

      await repo.updateRun(
        stale.copyWith(
          status: PipelineRunStatus.completed,
          finishedAt: DateTime(2025, 6, 2),
        ),
      );

      final fetched = (await repo.getRun('run-1'))!;
      expect(fetched.status, PipelineRunStatus.completed);
      expect(fetched.state, {'from': 'a parallel branch'});
      expect(fetched.totalCostCents, 47);
      expect(fetched.totalTokens, 403);
    });

    // A run's workspace never changes, so re-asking global.db for it on every
    // id-only read is pure overhead — and the engine performs six to ten of
    // them per step, against a server with ONE shared database connection.
    test('an id-only read resolves the run\'s workspace once', () async {
      await repo.insertRun(_makeRun());
      final afterInsert = routes.resolves;

      for (var i = 0; i < 5; i++) {
        await repo.getRun('run-1');
        await repo.stepRunsForPipeline('run-1');
      }

      expect(
        routes.resolves,
        afterInsert,
        reason:
            'insertRun already knows the workspace; nothing after it should '
            'have to look the route up again.',
      );
    });

    test('a run with no route is not remembered as missing', () async {
      // The route is written just after the run row. A reader that raced the
      // insert must not remember "this run does not exist" for the life of the
      // process.
      expect(await repo.getRun('run-later'), isNull);

      await repo.insertRun(_makeRun(id: 'run-later'));

      expect((await repo.getRun('run-later'))?.id, 'run-later');
    });

    test('a deleted run drops its cached route', () async {
      await repo.insertRun(_makeRun(workspaceId: 'ws-1'));
      await repo.deleteRun('ws-1', 'run-1');

      expect(await repo.getRun('run-1'), isNull);
    });

    test('incrementCost composes across interleaved callers', () async {
      await repo.insertRun(_makeRun(totalCostCents: 0, totalTokens: 0));

      // Every agent of a fan-out completes at once: each rollup must add to the
      // row as it stands, not to the total it read before the others wrote.
      await Future.wait([
        for (var i = 0; i < 8; i++) repo.incrementCost('run-1', 5, 50),
      ]);

      final fetched = (await repo.getRun('run-1'))!;
      expect(fetched.totalCostCents, 40);
      expect(fetched.totalTokens, 400);
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
        _makeRun(id: 'ws1-r1', workspaceId: 'ws-1', templateId: 't1'),
      );
      await repo.insertRun(
        _makeRun(id: 'ws1-r2', workspaceId: 'ws-1', templateId: 't2'),
      );
      await repo.insertRun(
        _makeRun(id: 'ws2-r1', workspaceId: 'ws-2', templateId: 't3'),
      );

      final stream = repo.watchForWorkspace('ws-1');
      final events = await stream.first;

      expect(events.length, 2);
      expect(events.map((r) => r.id), containsAll(['ws1-r1', 'ws1-r2']));
    });

    test(
      'deleteRun scoped to workspaceId does not delete from other workspace',
      () async {
        await repo.insertRun(_makeRun(id: 'r1', workspaceId: 'ws-1'));
        await repo.insertRun(_makeRun(id: 'r2', workspaceId: 'ws-2'));

        // Try to delete r2 with ws-1 scope — should be a no-op.
        await repo.deleteRun('ws-1', 'r2');

        expect(
          await repo.getRun('r2'),
          isNotNull,
          reason: 'r2 belongs to ws-2, ws-1 scoped delete must not touch it',
        );
      },
    );
  });

  // ── Run Status Transitions ─────────────────────────────────────────

  group('run status transitions', () {
    test('nonTerminalRuns returns only pending, running, suspended', () async {
      await repo.insertRun(
        _makeRun(id: 'r1', status: PipelineRunStatus.pending),
      );
      await repo.insertRun(
        _makeRun(id: 'r2', status: PipelineRunStatus.running),
      );
      await repo.insertRun(
        _makeRun(id: 'r3', status: PipelineRunStatus.suspended),
      );
      await repo.insertRun(
        _makeRun(id: 'r4', status: PipelineRunStatus.completed),
      );
      await repo.insertRun(
        _makeRun(id: 'r5', status: PipelineRunStatus.failed),
      );
      await repo.insertRun(
        _makeRun(id: 'r6', status: PipelineRunStatus.cancelled),
      );

      final nonTerminal = await repo.nonTerminalRuns();
      final ids = nonTerminal.map((r) => r.id).toList();
      expect(ids, containsAll(['r1', 'r2', 'r3']));
      expect(ids, isNot(contains('r4')));
      expect(ids, isNot(contains('r5')));
      expect(ids, isNot(contains('r6')));
    });

    test('watchRun emits updated run after status change', () async {
      await repo.insertRun(
        _makeRun(id: 'run-1', status: PipelineRunStatus.pending),
      );

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

      final updated = (await repo.getRun(
        'run-1',
      ))!.copyWith(status: PipelineRunStatus.running);
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

      await repo.updateRunState('run-1', {
        'key': 'new-value',
        'nested': [1, 2],
      });

      final fetched = await repo.getRun('run-1');
      expect(fetched!.state, {
        'key': 'new-value',
        'nested': [1, 2],
      });
    });

    test('incrementCost adds cents and tokens', () async {
      await repo.insertRun(
        _makeRun(id: 'run-1', totalCostCents: 100, totalTokens: 50),
      );

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

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
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
      expect(await repo.getStepRunById('ws-1', 'nonexistent'), isNull);
    });

    test('stepRunsForPipeline returns steps for a run', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertRun(_makeRun(id: 'run-2'));
      await repo.insertStepRun(
        _makeStepRun(id: 's1', pipelineRunId: 'run-1', stepId: 'a'),
      );
      await repo.insertStepRun(
        _makeStepRun(id: 's2', pipelineRunId: 'run-1', stepId: 'b'),
      );
      await repo.insertStepRun(
        _makeStepRun(id: 's3', pipelineRunId: 'run-2', stepId: 'c'),
      );

      final stepsForRun1 = await repo.stepRunsForPipeline('run-1');
      expect(stepsForRun1.length, 2);
      expect(stepsForRun1.map((s) => s.id), containsAll(['s1', 's2']));
    });

    test('deleteStepRun removes a single step', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(_makeStepRun(id: 's1', pipelineRunId: 'run-1'));
      await repo.insertStepRun(_makeStepRun(id: 's2', pipelineRunId: 'run-1'));

      await repo.deleteStepRun('ws-1', 's1');

      expect(await repo.getStepRunById('ws-1', 's1'), isNull);
      expect(await repo.getStepRunById('ws-1', 's2'), isNotNull);
    });

    test('deleting a pipeline run cascades step runs', () async {
      await repo.insertRun(_makeRun(id: 'run-1', workspaceId: 'ws-1'));
      await repo.insertStepRun(_makeStepRun(id: 's1', pipelineRunId: 'run-1'));
      await repo.insertStepRun(_makeStepRun(id: 's2', pipelineRunId: 'run-1'));

      // Both steps exist before cascading delete.
      expect(await repo.getStepRunById('ws-1', 's1'), isNotNull);
      expect(await repo.getStepRunById('ws-1', 's2'), isNotNull);

      await repo.deleteRun('ws-1', 'run-1');

      expect(
        await repo.getStepRunById('ws-1', 's1'),
        isNull,
        reason: 'cascade should delete step runs',
      );
      expect(
        await repo.getStepRunById('ws-1', 's2'),
        isNull,
        reason: 'cascade should delete step runs',
      );
    });

    test('updateStepRun updates status and optional fields', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.pending,
        ),
      );

      final finished = DateTime(2025, 6, 2);
      await repo.updateStepRun(
        'ws-1',
        'step-1',
        status: PipelineStepStatus.failed,
        outputJson: '{"out": 42}',
        errorMessage: 'something broke',
        errorStackTrace: 'at foo.dart:42',
        finishedAt: finished,
      );
      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.status, PipelineStepStatus.failed);
      expect(fetched.outputJson, '{"out": 42}');
      expect(fetched.errorMessage, 'something broke');
      expect(fetched.finishedAt, finished);
    });

    test('updateStepRun partial update only changes provided fields', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.pending,
        ),
      );

      // Set output and error via a full updateStepRun first (insertStepRun
      // doesn't persist outputJson/errorMessage via stepRunToCompanion).
      await repo.updateStepRun(
        'ws-1',
        'step-1',
        outputJson: '{"original": true}',
        errorMessage: 'original error',
      );

      // Now only update status — other fields should remain.
      await repo.updateStepRun(
        'ws-1',
        'step-1',
        status: PipelineStepStatus.running,
      );

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.status, PipelineStepStatus.running);
      expect(fetched.outputJson, '{"original": true}');
      expect(fetched.errorMessage, 'original error');
    });

    test('restartStepRun re-opens the row and clears the last attempt', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.running,
        ),
      );
      await repo.updateStepRun(
        'ws-1',
        'step-1',
        status: PipelineStepStatus.failed,
        outputJson: '{"partial": true}',
        spaceId: 'space-9',
        errorMessage: 'boom',
        errorStackTrace: 'at foo.dart:1',
        finishedAt: DateTime(2025, 6, 2),
      );

      final restartedAt = DateTime(2025, 6, 3, 10, 30);
      await repo.restartStepRun('ws-1', 'step-1', startedAt: restartedAt);

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.status, PipelineStepStatus.running);
      expect(
        fetched.startedAt,
        restartedAt,
        reason: 'the step must report the attempt now in flight',
      );
      expect(fetched.finishedAt, isNull);
      expect(fetched.errorMessage, isNull);
      expect(fetched.outputJson, isNull);
      expect(
        fetched.spaceId,
        'space-9',
        reason: 'the next attempt continues in the room this one opened',
      );
    });

    test('restartStepRun archives the superseded attempt', () async {
      // The Retry button re-opens the same row; the failure it is retrying
      // must survive on the row, or a flake has no trail to follow.
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.running,
          startedAt: DateTime(2025, 6, 1, 9),
        ),
      );
      await repo.updateStepRun(
        'ws-1',
        'step-1',
        status: PipelineStepStatus.failed,
        errorMessage: 'boom',
        errorStackTrace: 'at foo.dart:1',
        finishedAt: DateTime(2025, 6, 1, 9, 4),
      );

      await repo.restartStepRun(
        'ws-1',
        'step-1',
        startedAt: DateTime(2025, 6, 1, 10),
      );

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.priorAttempts, hasLength(1));
      final archived = fetched.priorAttempts.single;
      expect(archived.status, PipelineStepStatus.failed);
      expect(archived.startedAt, DateTime(2025, 6, 1, 9));
      expect(archived.finishedAt, DateTime(2025, 6, 1, 9, 4));
      expect(archived.errorMessage, 'boom');
      expect(archived.errorStackTrace, 'at foo.dart:1');
    });

    test('restartStepRun accumulates attempts across retries', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.running,
          startedAt: DateTime(2025, 6, 1, 9),
        ),
      );

      for (var i = 0; i < 2; i++) {
        await repo.updateStepRun(
          'ws-1',
          'step-1',
          status: PipelineStepStatus.failed,
          errorMessage: 'failure #$i',
          finishedAt: DateTime(2025, 6, 1, 10, i),
        );
        await repo.restartStepRun(
          'ws-1',
          'step-1',
          startedAt: DateTime(2025, 6, 1, 11, i),
        );
      }

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.priorAttempts, hasLength(2));
      expect(
        fetched.priorAttempts.map((a) => a.errorMessage).toList(),
        ['failure #0', 'failure #1'],
        reason: 'oldest first, so attempt numbers stay stable across retries',
      );
    });

    test('restartStepRun archives an interrupted attempt as unsettled', () async {
      // Crash-resume re-fires a step whose row still reads `running`: the
      // archived try keeps that open state (no finishedAt) so the UI can call
      // it interrupted rather than inventing an outcome.
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.running,
          startedAt: DateTime(2025, 6, 1, 9),
        ),
      );

      await repo.restartStepRun(
        'ws-1',
        'step-1',
        startedAt: DateTime(2025, 6, 1, 10),
      );

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.priorAttempts, hasLength(1));
      expect(fetched.priorAttempts.single.status, PipelineStepStatus.running);
      expect(fetched.priorAttempts.single.finishedAt, isNull);
      expect(fetched.priorAttempts.single.wasInterrupted, isTrue);
    });

    test('restartStepRun archives nothing for a row that never fired', () async {
      // A `pending` row re-fired by a resume has no attempt to remember —
      // archiving it would invent a try that only ever waited in queue.
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.pending,
        ),
      );

      await repo.restartStepRun(
        'ws-1',
        'step-1',
        startedAt: DateTime(2025, 6, 1, 10),
      );

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.priorAttempts, isEmpty);
    });

    test('restartStepRun caps the archive, dropping the oldest tries', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(
        _makeStepRun(
          id: 'step-1',
          pipelineRunId: 'run-1',
          status: PipelineStepStatus.running,
          startedAt: DateTime(2025, 6, 1, 9),
        ),
      );

      for (var i = 0; i < 21; i++) {
        await repo.updateStepRun(
          'ws-1',
          'step-1',
          status: PipelineStepStatus.failed,
          errorMessage: 'failure #$i',
          finishedAt: DateTime(2025, 6, 1, 10, i),
        );
        await repo.restartStepRun(
          'ws-1',
          'step-1',
          startedAt: DateTime(2025, 6, 1, 11, i),
        );
      }

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.priorAttempts, hasLength(20));
      expect(
        fetched.priorAttempts.first.errorMessage,
        'failure #1',
        reason: 'a flake retried forever must not grow the row without limit',
      );
      expect(fetched.priorAttempts.last.errorMessage, 'failure #20');
    });

    test('watchStepRunsForPipeline emits step runs', () async {
      await repo.insertRun(_makeRun(id: 'run-1'));
      await repo.insertStepRun(_makeStepRun(id: 's1', pipelineRunId: 'run-1'));

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
        _makeRun(id: 'r1', startedAt: early, templateId: 'a'),
      );
      await repo.insertRun(
        _makeRun(id: 'r2', startedAt: late, templateId: 'b'),
      );

      final runs = await repo.watchAll().first;
      expect(runs.length, 2);
      expect(runs.first.id, 'r2'); // most recent first
    });

    test('activeForDedupKey finds active non-terminal run', () async {
      await repo.insertRun(
        _makeRun(
          id: 'active-run',
          templateId: 'tpl',
          workspaceId: 'ws',
          dedupKey: 'key-1',
          status: PipelineRunStatus.running,
        ),
      );

      final found = await repo.activeForDedupKey(
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      expect(found, isNotNull);
      expect(found!.id, 'active-run');
    });

    test('activeForDedupKey ignores completed runs', () async {
      await repo.insertRun(
        _makeRun(
          id: 'done-run',
          templateId: 'tpl',
          workspaceId: 'ws',
          dedupKey: 'key-1',
          status: PipelineRunStatus.completed,
        ),
      );

      final found = await repo.activeForDedupKey(
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      expect(found, isNull, reason: 'completed runs should not match dedupKey');
    });

    test('activeForDedupKey returns null on mismatch', () async {
      await repo.insertRun(
        _makeRun(
          id: 'r1',
          templateId: 'tpl',
          workspaceId: 'ws',
          dedupKey: 'key-1',
          status: PipelineRunStatus.running,
        ),
      );

      final found = await repo.activeForDedupKey(
        templateId: 'different-tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      expect(found, isNull);
    });

    test('a queued run still blocks a duplicate dedup key', () async {
      // A queued run has not finished — treating it as gone would let the same
      // trigger queue a second copy of work already waiting.
      await repo.insertRun(
        _makeRun(
          id: 'queued-run',
          templateId: 'tpl',
          workspaceId: 'ws',
          dedupKey: 'key-1',
          status: PipelineRunStatus.queued,
        ),
      );

      final found = await repo.activeForDedupKey(
        templateId: 'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      expect(found, isNotNull);
      expect(found!.id, 'queued-run');
    });

    test('nonTerminalRuns includes queued runs', () async {
      await repo.insertRun(
        _makeRun(id: 'q', status: PipelineRunStatus.queued),
      );
      await repo.insertRun(
        _makeRun(id: 'done', status: PipelineRunStatus.completed),
      );

      final rows = await repo.nonTerminalRuns();
      expect(rows.map((r) => r.id), ['q']);
    });

    group('run concurrency accounting', () {
      test('counts only the runs holding a slot', () async {
        for (final (id, status) in <(String, PipelineRunStatus)>[
          ('pending', PipelineRunStatus.pending),
          ('running', PipelineRunStatus.running),
          ('suspended', PipelineRunStatus.suspended),
          ('queued', PipelineRunStatus.queued),
          ('completed', PipelineRunStatus.completed),
          ('failed', PipelineRunStatus.failed),
          ('cancelled', PipelineRunStatus.cancelled),
        ]) {
          await repo.insertRun(
            _makeRun(
              id: id,
              templateId: 'tpl',
              workspaceId: 'ws',
              status: status,
            ),
          );
        }

        expect(
          await repo.activeRunCountForTemplate(
            workspaceId: 'ws',
            templateId: 'tpl',
          ),
          3,
          reason: 'pending + running + suspended; queued waits for a slot',
        );
      });

      test('scopes the count to one template and one workspace', () async {
        await repo.insertRun(
          _makeRun(
            id: 'mine',
            templateId: 'tpl',
            workspaceId: 'ws',
            status: PipelineRunStatus.running,
          ),
        );
        await repo.insertRun(
          _makeRun(
            id: 'other-template',
            templateId: 'other',
            workspaceId: 'ws',
            status: PipelineRunStatus.running,
          ),
        );
        await repo.insertRun(
          _makeRun(
            id: 'other-workspace',
            templateId: 'tpl',
            workspaceId: 'ws-2',
            status: PipelineRunStatus.running,
          ),
        );

        expect(
          await repo.activeRunCountForTemplate(
            workspaceId: 'ws',
            templateId: 'tpl',
          ),
          1,
        );
      });

      test('excludes the named trigger event types, keeping nulls', () async {
        await repo.insertRun(
          _makeRun(
            id: 'engine-run',
            templateId: 'tpl',
            workspaceId: 'ws',
            status: PipelineRunStatus.running,
          ),
        );
        await repo.insertRun(
          _makeRun(
            id: 'projection',
            templateId: 'tpl',
            workspaceId: 'ws',
            status: PipelineRunStatus.running,
            triggerEventType: 'CodeGraphWatch',
          ),
        );

        expect(
          await repo.activeRunCountForTemplate(
            workspaceId: 'ws',
            templateId: 'tpl',
            excludeTriggerEventTypes: const {'CodeGraphWatch'},
          ),
          1,
          reason:
              'a run with no trigger event type must still count — SQL NOT IN '
              'over a null column yields null, not true',
        );
      });

      test('nextQueuedRunForTemplate returns the oldest waiting run', () async {
        await repo.insertRun(
          _makeRun(
            id: 'newer',
            templateId: 'tpl',
            workspaceId: 'ws',
            status: PipelineRunStatus.queued,
            startedAt: DateTime(2025, 6, 2),
          ),
        );
        await repo.insertRun(
          _makeRun(
            id: 'older',
            templateId: 'tpl',
            workspaceId: 'ws',
            status: PipelineRunStatus.queued,
            startedAt: DateTime(2025, 6, 1),
          ),
        );
        await repo.insertRun(
          _makeRun(
            id: 'running',
            templateId: 'tpl',
            workspaceId: 'ws',
            status: PipelineRunStatus.running,
            startedAt: DateTime(2025, 5, 1),
          ),
        );

        final next = await repo.nextQueuedRunForTemplate(
          workspaceId: 'ws',
          templateId: 'tpl',
        );
        expect(next!.id, 'older');
      });

      // `startedAt` is stored as a unix timestamp in SECONDS, so a burst of
      // runs created together — adding six repos at once fires six `index_code`
      // runs — all carry the same value and cannot be ordered by it. The queue
      // still has to drain in the order the runs arrived.
      test('drains a same-second burst in insert order', () async {
        final stamp = DateTime(2025, 6, 1, 12, 30, 45);
        final added = ['auto-ci', 'brand-sdk', 'ffy-cli', 'fondue', 'web-app'];
        for (final id in added) {
          await repo.insertRun(
            _makeRun(
              id: id,
              templateId: 'index_code',
              workspaceId: 'ws',
              status: PipelineRunStatus.queued,
              startedAt: stamp,
            ),
          );
        }

        // Admit them one at a time, exactly as `_admitNext` does at each
        // terminal transition.
        final drained = <String>[];
        while (true) {
          final next = await repo.nextQueuedRunForTemplate(
            workspaceId: 'ws',
            templateId: 'index_code',
          );
          if (next == null) {
            break;
          }
          drained.add(next.id);
          await repo.updateRun(
            next.copyWith(status: PipelineRunStatus.completed),
          );
        }

        expect(drained, added);
      });

      test('same-second burst lists newest first, next-to-run last', () async {
        final stamp = DateTime(2025, 6, 1, 12, 30, 45);
        final added = ['auto-ci', 'brand-sdk', 'ffy-cli'];
        for (final id in added) {
          await repo.insertRun(
            _makeRun(
              id: id,
              templateId: 'index_code',
              workspaceId: 'ws',
              status: PipelineRunStatus.queued,
              startedAt: stamp,
            ),
          );
        }

        // The runs table reads queue position off this ordering: within a
        // template's queued rows the LAST one listed is the next admitted.
        final listed = await repo.watchForWorkspace('ws').first;
        expect(listed.map((r) => r.id), added.reversed);
      });

      test('nextQueuedRunForTemplate is null when nothing waits', () async {
        await repo.insertRun(
          _makeRun(
            id: 'running',
            templateId: 'tpl',
            workspaceId: 'ws',
            status: PipelineRunStatus.running,
          ),
        );
        expect(
          await repo.nextQueuedRunForTemplate(
            workspaceId: 'ws',
            templateId: 'tpl',
          ),
          isNull,
        );
      });
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

      final fetched = await repo.getStepRunById('ws-1', 'step-1');
      expect(fetched!.finishedAt, finished);
      expect(fetched.status, PipelineStepStatus.skipped);
    });
  });
}
