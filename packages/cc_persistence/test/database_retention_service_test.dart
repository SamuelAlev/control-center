import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// [DatabaseRetentionService] prunes the append-only history tables.
///
/// After the split a sweep is no longer one `DELETE` per table — it is a
/// sequential visit to EVERY workspace's database file (via
/// `CrossWorkspaceQueries.forEachWorkspace`), including workspaces nobody opened
/// this session and soft-deleted ones whose files are still on disk. That
/// per-workspace fan-out is the behaviour most worth pinning: a sweep that only
/// visited the open workspaces would silently let the others grow forever.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  DateTime at(int daysAgo) =>
      DateTime(2026, 6, 1).subtract(Duration(days: daysAgo));

  Future<void> seedCronExecution(
    String workspaceId,
    String id,
    int daysAgo,
  ) async {
    final db = dbs.of(workspaceId);
    await db
        .into(db.cronExecutionsTable)
        .insert(
          CronExecutionsTableCompanion(
            id: Value(id),
            workspaceId: Value(workspaceId),
            triggerId: const Value('t-1'),
            plannedAt: Value(at(daysAgo)),
            createdAt: Value(at(daysAgo)),
          ),
        );
  }

  Future<void> seedRun(
    String id, {
    required String templateId,
    required int daysAgo,
    bool finished = true,
  }) async {
    final db = dbs.of('ws-1');
    await db
        .into(db.pipelineRunsTable)
        .insert(
          PipelineRunsTableCompanion(
            id: Value(id),
            templateId: Value(templateId),
            workspaceId: const Value('ws-1'),
            status: Value(finished ? 'completed' : 'running'),
            startedAt: Value(at(daysAgo)),
            finishedAt: finished ? Value(at(daysAgo)) : const Value.absent(),
          ),
        );
  }

  Future<List<String>> runIds() async {
    final db = dbs.of('ws-1');
    final rows = await db.select(db.pipelineRunsTable).get();
    return rows.map((r) => r.id).toList()..sort();
  }

  DatabaseRetentionService service({
    Duration? cronRetention,
    int codeIndexRunsKept = 50,
  }) => DatabaseRetentionService(
    workspaces: dbs,
    cronRetention: cronRetention ?? const Duration(days: 30),
    codeIndexRunsKept: codeIndexRunsKept,
    now: () => DateTime(2026, 6, 1),
  );

  test('runOnce prunes only rows older than each retention window', () async {
    await seedCronExecution('ws-1', 'cron-old', 100);
    await seedCronExecution('ws-1', 'cron-new', 1);

    final deleted = await service().runOnce();
    expect(deleted, 1); // only cron-old (100 days) exceeds the 30-day window

    final db = dbs.of('ws-1');
    final remaining = await db.select(db.cronExecutionsTable).get();
    expect(remaining.map((r) => r.id), ['cron-new']);
  });

  test(
    'runOnce prunes write_ledger rows past the idempotency window',
    () async {
      // PRD 19 §3: the idempotency ledger is kept only long enough to outlive
      // plausible retries (default 7 days).
      final db = dbs.of('ws-1');
      await db
          .into(db.writeLedgerTable)
          .insert(
            WriteLedgerTableCompanion(
              workspaceId: const Value('ws-1'),
              idempotencyKey: const Value('old'),
              opName: const Value('tickets.update'),
              resultJson: const Value('{"ok":true}'),
              createdAt: Value(at(30)),
            ),
          );
      await db
          .into(db.writeLedgerTable)
          .insert(
            WriteLedgerTableCompanion(
              workspaceId: const Value('ws-1'),
              idempotencyKey: const Value('fresh'),
              opName: const Value('tickets.update'),
              resultJson: const Value('{"ok":true}'),
              createdAt: Value(at(1)),
            ),
          );

      final deleted = await service().runOnce();
      expect(deleted, 1); // only the 30-day-old row exceeds the 7-day window

      final remaining = await db.select(db.writeLedgerTable).get();
      expect(remaining.map((r) => r.idempotencyKey), ['fresh']);
    },
  );

  group('index_code runs', () {
    // The code-graph watcher publishes a run per background reindex, so this is
    // the one template that writes its own history fast enough to need a window.
    test('prunes finished index runs past the window', () async {
      await seedRun('idx-old', templateId: IndexCodeTemplate.id, daysAgo: 30);
      await seedRun('idx-new', templateId: IndexCodeTemplate.id, daysAgo: 1);

      expect(await service(codeIndexRunsKept: 1).runOnce(), 1);
      expect(await runIds(), ['idx-new']);
    });

    test('never touches a run of another template', () async {
      // Every other template's history is the operator's — a run they started
      // by hand must still be there a year later.
      await seedRun('review-old', templateId: 'review_pr', daysAgo: 400);

      expect(await service(codeIndexRunsKept: 0).runOnce(), 0);
      expect(await runIds(), ['review-old']);
    });

    test('never touches a run that has not finished', () async {
      // An unfinished row may be a live index in flight; deleting it would take
      // the pipeline page's progress out from under the operator.
      await seedRun(
        'idx-live',
        templateId: IndexCodeTemplate.id,
        daysAgo: 30,
        finished: false,
      );

      expect(await service(codeIndexRunsKept: 0).runOnce(), 0);
      expect(await runIds(), ['idx-live']);
    });

    test('keeps the most recent runs regardless of age', () async {
      // A workspace nobody has touched in a month should still show its last
      // indexes rather than an empty history.
      for (var i = 0; i < 4; i++) {
        await seedRun(
          'idx-$i',
          templateId: IndexCodeTemplate.id,
          daysAgo: 100 + i,
        );
      }

      expect(await service(codeIndexRunsKept: 2).runOnce(), 2);
      expect(await runIds(), ['idx-0', 'idx-1']);
    });
  });

  test('runOnce is a no-op when nothing is stale', () async {
    await seedCronExecution('ws-1', 'cron-new', 2);

    expect(await service().runOnce(), 0);
    final db = dbs.of('ws-1');
    expect(await db.select(db.cronExecutionsTable).get(), hasLength(1));
  });

  test(
    'runOnce sweeps every registered workspace, not just the open ones',
    () async {
      await seedTestWorkspace(global, dbs, 'ws-2');
      await seedTestWorkspace(global, dbs, 'ws-3');
      await seedCronExecution('ws-1', 'old-1', 100);
      await seedCronExecution('ws-2', 'old-2', 100);
      await seedCronExecution('ws-3', 'keep-3', 1);

      final deleted = await service().runOnce();

      expect(
        deleted,
        2,
        reason:
            'the stale row in ws-2 is in its own file; a sweep that only visited '
            'the workspace in front of it would let the others grow forever',
      );
      for (final (ws, remaining) in [
        ('ws-1', <String>[]),
        ('ws-2', <String>[]),
        ('ws-3', <String>['keep-3']),
      ]) {
        final db = dbs.of(ws);
        final rows = await db.select(db.cronExecutionsTable).get();
        expect(rows.map((r) => r.id), remaining);
      }
    },
  );

  test('runOnce still sweeps a soft-deleted workspace', () async {
    await seedTestWorkspace(global, dbs, 'ws-gone');
    await seedCronExecution('ws-gone', 'old', 100);
    await global.workspaceRegistryDao.deleteWorkspace('ws-gone');

    expect(
      await service().runOnce(),
      1,
      reason:
          "a soft-deleted workspace's file is still on disk, so it still needs "
          'pruning',
    );
  });

  test('one failing workspace does not abort the sweep', () async {
    await seedTestWorkspace(global, dbs, 'ws-2');
    await seedCronExecution('ws-1', 'old-1', 100);
    await seedCronExecution('ws-2', 'old-2', 100);
    // Close ws-1 out from under the sweep so its visit fails.
    await dbs.of('ws-1').close();

    final errors = <String>[];
    final deleted = await DatabaseRetentionService(
      workspaces: dbs,
      now: () => DateTime(2026, 6, 1),
      onError: errors.add,
    ).runOnce();

    expect(
      deleted,
      1,
      reason:
          'ws-2 was still pruned — one bad workspace file must not blank the '
          'sweep for the others',
    );
    expect(errors, isNotEmpty);
    // NOTE: the reported messages name the TABLE, not the workspace, because
    // `_prune` catches per table and so never reaches `forEachWorkspace`'s
    // `onError` (which is the callback that knows the workspace id). A single
    // unreadable workspace therefore surfaces as N table-level errors with no
    // way to tell which workspace they came from.
    expect(errors.first, contains('retention prune of'));
    expect(
      errors.any((e) => e.contains('activity_log')),
      isTrue,
      reason: 'the first table visited is the one that reports the failure',
    );
  });
}
