import 'package:cc_domain/core/domain/services/cache_kind_registry.dart';
import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_takeover.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:test/test.dart';

import 'helpers/seed_agents.dart' as seed;
import 'helpers/seed_platform.dart';
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

  /// One execution per trigger: two executions of one trigger in the same
  /// slot are one row.
  Future<void> seedCronExecution(String workspaceId, String id, int daysAgo) =>
      seed.seedCronExecution(
        dbs.of(workspaceId),
        id,
        at: at(daysAgo),
        triggerId: 't-$id',
      );

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
    int rssArticlesKeptPerFeed = 200,
  }) => DatabaseRetentionService(
    workspaces: dbs,
    global: global,
    cronRetention: cronRetention ?? const Duration(days: 30),
    codeIndexRunsKept: codeIndexRunsKept,
    rssArticlesKeptPerFeed: rssArticlesKeptPerFeed,
    now: () => DateTime(2026, 6, 1),
  );

  /// Inserts a `caches` row without the store's declared-kind check, the way
  /// a row written before a kind moved to its own table is still on disk.
  Future<void> seedRawCache(String kind, String key, int daysAgo) => dbs
      .of('ws-1')
      .customInsert(
        'INSERT INTO caches (workspace_id, kind, key, payload, updated_at) '
        "VALUES ('ws-1', ?, ?, '{}', ?)",
        variables: [
          Variable(kind),
          Variable(key),
          Variable<DateTime>(at(daysAgo)),
        ],
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

  group('caches', () {
    test('ages out each declared kind past its own window', () async {
      final kind = CacheKindRegistry.declared.first;
      final window = kind.retention.inDays;
      await seedRawCache(kind.name, 'old', window + 1);
      await seedRawCache(kind.name, 'fresh', window - 1);

      expect(await service().runOnce(), 1);

      final db = dbs.of('ws-1');
      final rows = await db.select(db.cachesTable).get();
      expect(rows.map((r) => r.key), ['fresh']);
    });

    test('the schema refuses a kind nobody declared, so the sweep never '
        'meets one', () async {
      // Kinds that moved to tables of their own, or anything else: the
      // sweep cannot know they are refetchable, so they cannot be stored.
      for (final kind in [
        'takeover',
        EditorLayoutCacheKinds.space,
        'agent_pr_requester_v1',
      ]) {
        await expectLater(
          seedRawCache(kind, 'k', 400),
          throwsA(isA<SqliteException>()),
        );
      }
      final db = dbs.of('ws-1');
      expect(await db.select(db.cachesTable).get(), isEmpty);
    });

    test('a take-over held past the cache window keeps its gate', () async {
      final db = dbs.of('ws-1');
      await db
          .into(db.spacesTable)
          .insert(
            SpacesTableCompanion.insert(
              workspaceId: 'test-workspace',
              id: 'sp-1',
              name: 'General',
            ),
          );
      final takeovers = DaoSpaceTakeoverRepository(dbs);
      await takeovers.claim(
        'ws-1',
        SpaceTakeover(
          spaceId: 'sp-1',
          userId: 'u-1',
          displayName: 'Ada',
          since: at(400),
          pausedRunIds: const [],
          stoppedRunIds: const [],
        ),
      );

      await service().runOnce();

      expect((await takeovers.get('ws-1', 'sp-1'))?.userId, 'u-1');
    });
  });

  group('index_code runs', () {
    // The code-graph watcher publishes a run per background reindex, so this is
    // the one template that writes its own history fast enough to need a window.
    test('prunes finished index runs past the window', () async {
      await seedRun('idx-old', templateId: IndexCodeTemplate.id, daysAgo: 30);
      await seedRun('idx-new', templateId: IndexCodeTemplate.id, daysAgo: 1);

      expect(await service(codeIndexRunsKept: 1).runOnce(), 1);
      expect(await runIds(), ['idx-new']);
    });

    test("removes a pruned run's route and keeps the others", () async {
      await seedRun('idx-old', templateId: IndexCodeTemplate.id, daysAgo: 30);
      await seedRun('idx-new', templateId: IndexCodeTemplate.id, daysAgo: 1);
      final routes = global.workspaceRouteDao;
      await routes.put(WorkspaceRouteKind.pipelineRun, 'idx-old', 'ws-1');
      await routes.put(WorkspaceRouteKind.pipelineRun, 'idx-new', 'ws-1');

      await service(codeIndexRunsKept: 1).runOnce();

      expect(
        await routes.resolve(WorkspaceRouteKind.pipelineRun, 'idx-old'),
        isNull,
      );
      expect(
        await routes.resolve(WorkspaceRouteKind.pipelineRun, 'idx-new'),
        'ws-1',
      );
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

  test('runOnce leaves a deleted workspace alone', () async {
    // A deleted workspace has no database: the manager refuses to open its
    // id, so the sweep must not try (and must not recreate the file).
    await seedTestWorkspace(global, dbs, 'ws-gone');
    await seedCronExecution('ws-gone', 'old', 100);
    await global.workspaceRegistryDao.deleteWorkspace('ws-gone');
    final errors = <String>[];

    expect(
      await DatabaseRetentionService(
        workspaces: dbs,
        global: global,
        now: () => DateTime(2026, 6, 1),
        onError: errors.add,
      ).runOnce(),
      0,
    );
    expect(errors, isEmpty);
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
      global: global,
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
    expect(errors, hasLength(1));
    expect(errors.single, contains('workspace ws-1'));
  });

  group('agent_run_logs', () {
    Future<void> seedRunLog(
      String id, {
      required int daysAgo,
      String status = 'completed',
      String? ticketId,
      String? parentRunId,
      String? pipelineRunId,
    }) async {
      final db = dbs.of('ws-1');
      await seed.seedAgent(db, 'a-1');
      if (ticketId != null) {
        await seed.seedTicket(db, ticketId);
      }
      await db.customInsert(
        'INSERT INTO agent_run_logs (id, agent_id, workspace_id, status, '
        'started_at, completed_at, ticket_id, parent_run_id, '
        'pipeline_run_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable(id),
          const Variable('a-1'),
          const Variable('ws-1'),
          Variable(status),
          Variable<DateTime>(at(daysAgo)),
          Variable<DateTime>(status == 'running' ? null : at(daysAgo)),
          Variable<String>(ticketId),
          Variable<String>(parentRunId),
          Variable<String>(pipelineRunId),
        ],
      );
    }

    Future<List<String>> runLogIds() async {
      final rows = await dbs
          .of('ws-1')
          .customSelect('SELECT id FROM agent_run_logs ORDER BY id')
          .get();
      return [for (final row in rows) row.read<String>('id')];
    }

    test('prunes a finished run nothing points at, past the window', () async {
      await seedRunLog('old', daysAgo: 200);
      await seedRunLog('recent', daysAgo: 10);

      expect(await service().runOnce(), 1);
      expect(await runLogIds(), ['recent']);
    });

    test('never prunes a run that has not finished', () async {
      await seedRunLog('live', daysAgo: 400, status: 'running');

      await service().runOnce();
      expect(await runLogIds(), ['live']);
    });

    test("spares a ticket's latest run and prunes its older ones", () async {
      await seedRunLog('t-first', daysAgo: 300, ticketId: 't-1');
      await seedRunLog('t-latest', daysAgo: 200, ticketId: 't-1');

      await service().runOnce();
      expect(await runLogIds(), ['t-latest']);
    });

    test('spares a run an approval links', () async {
      await seedRunLog('approved', daysAgo: 300);
      await dbs
          .of('ws-1')
          .customStatement(
            'INSERT INTO approvals (id, workspace_id, title, '
            "linked_entity_type, linked_entity_id) VALUES ('ap-1', 'ws-1', "
            "'Ship it', 'agent_run', 'approved')",
          );

      await service().runOnce();
      expect(await runLogIds(), ['approved']);
    });

    test('spares the parent of a kept run and a run of a live pipeline '
        'run', () async {
      await seedRunLog('parent', daysAgo: 300);
      await seedRunLog('child', daysAgo: 1, parentRunId: 'parent');
      await seedRun('pr-1', templateId: 'review_pr', daysAgo: 300);
      await seedRunLog('step', daysAgo: 300, pipelineRunId: 'pr-1');
      // A step whose pipeline run was deleted: the key clears with it, and
      // nothing holds the step any more.
      await seedRun('pr-gone', templateId: 'review_pr', daysAgo: 300);
      await seedRunLog('orphan-step', daysAgo: 300, pipelineRunId: 'pr-gone');
      await dbs
          .of('ws-1')
          .customStatement("DELETE FROM pipeline_runs WHERE id = 'pr-gone'");

      await service().runOnce();
      expect(await runLogIds(), ['child', 'parent', 'step']);
    });

    test('spares a run an eval recording was made from', () async {
      await seedRunLog('recorded', daysAgo: 300);
      await dbs
          .of('ws-1')
          .customStatement(
            'INSERT INTO session_recordings (id, workspace_id, run_log_id, '
            "config_hash) VALUES ('rec-1', 'ws-1', 'recorded', 'h')",
          );

      await service().runOnce();
      expect(await runLogIds(), ['recorded']);
    });
  });

  group('global tables', () {
    setUp(() async {
      await seedRssFeed(global, 'f-1');
      await seedRssFeed(global, 'f-2');
    });

    Future<void> seedArticle(
      String id, {
      required int daysAgo,
      String feedId = 'f-1',
      bool saved = false,
    }) => global.customInsert(
      'INSERT INTO rss_articles (id, feed_id, guid, title, link, '
      'published_at, saved) VALUES (?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable(id),
        Variable(feedId),
        Variable(id),
        Variable(id),
        Variable('https://example.com/$id'),
        Variable<DateTime>(at(daysAgo)),
        Variable(saved),
      ],
    );

    Future<List<String>> ids(String table) async {
      final rows = await global
          .customSelect('SELECT id FROM $table ORDER BY id')
          .get();
      return [for (final row in rows) row.read<String>('id')];
    }

    test('rss_articles keeps each feed\'s newest, the recent and the saved '
        'ones', () async {
      await seedArticle('a-new', daysAgo: 5);
      await seedArticle('a-old-1', daysAgo: 100);
      await seedArticle('a-old-2', daysAgo: 120);
      await seedArticle('a-old-3', daysAgo: 140);
      await seedArticle('a-saved', daysAgo: 300, saved: true);
      await seedArticle('b-old', daysAgo: 400, feedId: 'f-2');

      await service(rssArticlesKeptPerFeed: 2).runOnce();

      // f-1's newest two survive (a-new by date, a-old-1 by count), f-2's
      // only article survives by count, saved survives regardless.
      expect(await ids('rss_articles'), [
        'a-new',
        'a-old-1',
        'a-saved',
        'b-old',
      ]);
    });

    Future<void> seedJob(String id, String status, int daysAgo) =>
        global.customInsert(
          'INSERT INTO jobs (id, workspace_id, kind, status, created_at, '
          'finished_at) VALUES (?, ?, ?, ?, ?, ?)',
          variables: [
            Variable(id),
            const Variable('ws-1'),
            const Variable('agentRun'),
            Variable(status),
            Variable<DateTime>(at(daysAgo)),
            Variable<DateTime>(
              const {'done', 'failed', 'cancelled'}.contains(status)
                  ? at(daysAgo)
                  : null,
            ),
          ],
        );

    Future<void> seedPlacement(String id, String jobId, int daysAgo) =>
        global.customInsert(
          'INSERT INTO placement_log (id, workspace_id, job_id, created_at) '
          'VALUES (?, ?, ?, ?)',
          variables: [
            Variable(id),
            const Variable('ws-1'),
            Variable(jobId),
            Variable<DateTime>(at(daysAgo)),
          ],
        );

    test('jobs and placement_log prune terminal work only', () async {
      await seedJob('done-old', 'done', 60);
      await seedJob('failed-new', 'failed', 5);
      await seedJob('running-old', 'running', 60);
      await seedJob('reaped-old', 'reaped', 60);
      await seedPlacement('p-done-old', 'done-old', 60);
      await seedPlacement('p-running-old', 'running-old', 60);
      await seedPlacement('p-failed-old', 'failed-new', 60);
      await seedPlacement('p-failed-new', 'failed-new', 5);

      await service().runOnce();

      expect(await ids('jobs'), ['failed-new', 'reaped-old', 'running-old']);
      // A decision about a pruned job goes with it, an old one about finished
      // work is history, and one about work still in flight explains it.
      expect(await ids('placement_log'), ['p-failed-new', 'p-running-old']);
    });

    Future<List<String>> plan(String sql, int parameters) async => [
      for (final row
          in await global
              .customSelect(
                'EXPLAIN QUERY PLAN $sql',
                variables: [for (var i = 0; i < parameters; i++) Variable(i)],
              )
              .get())
        row.read<String>('detail'),
    ];

    test('the rss_articles sweep ranks each feed through its index, never a '
        'sort of the table', () async {
      final steps = await plan(DatabaseRetentionService.rssArticlesSweepSql, 2);
      expect(
        steps,
        contains(
          contains('USING COVERING INDEX idx_rss_articles_feed_published'),
        ),
      );
      expect(steps, isNot(contains(contains('TEMP B-TREE'))));
    });
  });

  test(
    'the caches sweep reads only the rows of one kind past its cutoff',
    () async {
      final steps = [
        for (final row
            in await dbs
                .of('ws-1')
                .customSelect(
                  'EXPLAIN QUERY PLAN DELETE FROM caches '
                  'WHERE kind = ? AND updated_at < ?',
                  variables: [
                    const Variable('prDetail'),
                    Variable<DateTime>(at(0)),
                  ],
                )
                .get())
          row.read<String>('detail'),
      ];
      const search =
          'SEARCH caches USING INDEX idx_caches_kind_updated '
          '(kind=? AND updated_at<?)';
      expect(steps, [search]);
    },
  );
}
