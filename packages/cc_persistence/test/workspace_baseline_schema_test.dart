import 'dart:io';

import 'package:cc_persistence/database/daos/notification_feed_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Pins the shape of a fresh workspace database.
///
/// There is one shape: `onCreate` builds it and an older file is converged to
/// it (see `workspace_converge_test.dart`), so nothing here has an "after an
/// upgrade" twin.
void main() {
  group('workspace baseline schema', () {
    test('a fresh database carries the sandbox exec grants table', () async {
      final db = WorkspaceDatabase.forTesting(
        NativeDatabase.memory(),
        workspaceId: 'ws',
      );
      addTearDown(db.close);
      final columns = await db
          .customSelect('PRAGMA table_info(sandbox_exec_grants)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
      expect(
        columns,
        containsAll([
          'id',
          'workspace_id',
          'path',
          'decision',
          'created_by',
          'created_at',
        ]),
      );
    });

    test('a fresh database carries the v6 permissions batch', () async {
      final db = WorkspaceDatabase.forTesting(
        NativeDatabase.memory(),
        workspaceId: 'ws',
      );
      addTearDown(db.close);
      final routing = await db
          .customSelect('PRAGMA table_info(approval_routing_policies)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
      expect(
        routing,
        containsAll(['workspace_id', 'policy_json', 'updated_at']),
      );
      final guard = await db
          .customSelect('PRAGMA table_info(guard_decisions)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
      expect(
        guard,
        containsAll([
          'id',
          'workspace_id',
          'seq',
          'actor_type',
          'actor_id',
          'on_behalf_of_user_id',
          'surface',
          'action_name',
          'decision',
          'prev_hash',
          'entry_hash',
          'kind',
        ]),
      );
      final roles = await db
          .customSelect('PRAGMA table_info(workspace_roles)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
      expect(roles, containsAll(['id', 'workspace_id', 'name', 'base_preset']));
      final policies = await db
          .customSelect('PRAGMA table_info(action_policies)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
      expect(
        policies,
        containsAll(['constraint_json', 'expires_at', 'enforcement']),
      );
    });

    test('no table carries the redundant `_table` suffix', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name LIKE '%\\_table' ESCAPE '\\'",
          )
          .get();

      // A drift table class that does not override `tableName` is named after
      // its CLASS (`AgentsTable` → `agents_table`), so the suffix comes back by
      // omission on the next table anyone adds.
      expect(rows.map((r) => r.read<String>('name')), isEmpty);
    });

    test(
      'a fresh database carries the forge column and neutral repo names',
      () async {
        final db = createTestDatabase();
        addTearDown(db.close);

        final rows = await db.customSelect("PRAGMA table_info('repos')").get();
        final columns = rows.map((r) => r.read<String>('name')).toSet();

        // `onCreate` builds the CURRENT shape, so a fresh install must already
        // have the forge discriminator — and must NOT carry the GitHub-named
        // columns it replaced.
        expect(columns, containsAll(['forge', 'remote_owner', 'remote_name']));
        expect(columns, isNot(contains('github_owner')));
        expect(columns, isNot(contains('github_repo_name')));
      },
    );

    test('a fresh database names PR identity neutrally', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      for (final table in [
        'review_spaces',
        'review_cohorts',
        'api_contract_snapshots',
        'visual_diff_snapshots',
        'review_axis_results',
      ]) {
        final rows = await db.customSelect("PRAGMA table_info('$table')").get();
        final columns = rows.map((r) => r.read<String>('name')).toSet();
        expect(
          columns,
          contains('pr_external_id'),
          reason: '$table should carry the forge-neutral identity column',
        );
        expect(columns, isNot(contains('pr_node_id')), reason: table);
      }
    });

    test('a fresh database carries the workspace settings table', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'workspace_settings'",
          )
          .get();

      // `onCreate` must build the CURRENT shape — there is no migration chain
      // left to arrive at it by.
      expect(rows.map((r) => r.data['name'] as String), ['workspace_settings']);
    });

    test('a fresh database carries the skill sources table', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'skill_sources'",
          )
          .get();
      expect(rows.map((r) => r.data['name'] as String), ['skill_sources']);

      // Workspace-scoped by structure: the isolation invariant's column.
      final columns = await db
          .customSelect("PRAGMA table_info('skill_sources')")
          .get();
      expect(
        columns.map((r) => r.read<String>('name')),
        containsAll(<String>['id', 'workspace_id', 'owner', 'repo']),
      );

      // One row per (workspace, owner, repo): adding the same repository twice
      // must be impossible at the storage layer. (A UNIQUE constraint lands in
      // the CREATE TABLE sql — SQLite's auto-index rows carry a NULL sql.)
      final createSql = await db
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE type = 'table' "
            "AND name = 'skill_sources'",
          )
          .getSingle();
      expect(createSql.read<String>('sql'), contains('UNIQUE'));
    });

    test(
      'a fresh database carries the audit ip/country/details columns',
      () async {
        final db = createTestDatabase();
        addTearDown(db.close);

        final rows = await db
            .customSelect("PRAGMA table_info('user_activity')")
            .get();
        final columns = rows.map((r) => r.read<String>('name')).toSet();

        expect(columns, containsAll(<String>['ip', 'country_code', 'details']));
      },
    );

    test('a fresh database keys todos and goals by conversation', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      Future<Set<String>> columnsOf(String table) async =>
          (await db.customSelect("PRAGMA table_info('$table')").get())
              .map((r) => r.read<String>('name'))
              .toSet();

      final todos = await columnsOf('todos');
      expect(todos, contains('conversation_id'));
      expect(todos, isNot(contains('space_id')));

      final goals = await columnsOf('conversation_goals');
      expect(goals, contains('conversation_id'));
      expect(goals, isNot(contains('space_id')));
    });

    test('a fresh database carries the generic chat link tables', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE "
            "'chat_%' OR name LIKE 'slack_%'",
          )
          .get();

      // Both tables present under their generic names and nothing Slack-named:
      // `onCreate` must build the current shape, never a migrated-into one.
      expect(rows.map((r) => r.read<String>('name')), <String>[
        'chat_space_links',
        'chat_user_links',
      ]);
    });

    test('a fresh database carries the pipeline run bookkeeping', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      Future<Set<String>> columnsOf(String table) async =>
          (await db.customSelect("PRAGMA table_info('$table')").get())
              .map((r) => r.read<String>('name'))
              .toSet();

      // Each of these arrived as its own step before the squash: the
      // per-template concurrency cap, the rerun stamp that stops a retry
      // overwriting `started_at`, and the archive of superseded attempts.
      // Every step-run read maps `attemptHistory`, so a baseline missing it
      // fails the mapper, not just the write.
      expect(
        await columnsOf('pipeline_templates'),
        contains('max_parallel_runs'),
      );
      expect(await columnsOf('pipeline_runs'), contains('attempt_started_at'));
      // Which attempt of a run is current, so the page can say "Attempt 3".
      expect(await columnsOf('pipeline_runs'), contains('attempt_count'));
      expect(
        await columnsOf('pipeline_step_runs'),
        contains('attempt_history'),
      );

      final indexes =
          (await db
                  .customSelect(
                    "SELECT name, sql FROM sqlite_master WHERE type = 'index' "
                    "AND name IN ('uq_pipeline_runs_active_dedup', "
                    "'idx_pipeline_runs_template_status')",
                  )
                  .get())
              .map((r) => (r.read<String>('name'), r.read<String>('sql')));
      expect(indexes.map((i) => i.$1), hasLength(2));
      // The dedup index is PARTIAL and its `WHERE` enumerates the non-terminal
      // statuses. Leaving `queued` out would let a repeated trigger queue a
      // second copy of work already waiting.
      expect(
        indexes.firstWhere((i) => i.$1 == 'uq_pipeline_runs_active_dedup').$2,
        contains("'queued'"),
      );
    });

    test('a fresh database carries the space flags', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final columns =
          (await db.customSelect("PRAGMA table_info('spaces')").get())
              .map((r) => r.read<String>('name'))
              .toSet();

      // `no_repos` is the explicit empty repo selection ("no rows in
      // `space_repos`" already means "all workspace repos"); `archived_at` is
      // the soft hide. Both are mapped on every space read.
      expect(columns, containsAll(<String>['no_repos', 'archived_at']));
    });

    test('a fresh database carries the per-item notification states', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final columns =
          (await db
                  .customSelect("PRAGMA table_info('notification_item_states')")
                  .get())
              .map((r) => r.read<String>('name'))
              .toSet();
      expect(
        columns,
        containsAll(<String>[
          'workspace_id',
          'user_id',
          'item_id',
          'read_at',
          'dismissed_at',
        ]),
      );

      // The lookup key too: the panel reads this table by user on every
      // open, and the primary key (user_id, item_id) is what serves it; a
      // table created without it degrades to a scan no other test would
      // notice.
      final plan =
          (await db
                  .customSelect(
                    'EXPLAIN QUERY PLAN SELECT item_id, read_at '
                    'FROM notification_item_states WHERE user_id = ?',
                    variables: [Variable.withString('u')],
                  )
                  .get())
              .map((r) => r.read<String>('detail'))
              .join('\n');
      expect(plan, contains('sqlite_autoindex_notification_item_states_1'));
    });

    test('a fresh database carries none of the removed analytics tables', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN "
            "('agent_daily_stats', 'streaks', 'achievements', "
            "'agent_daily_stats_table', 'streaks_table', 'achievements_table')",
          )
          .get();

      expect(
        rows.map((r) => r.read<String>('name')),
        isEmpty,
        reason:
            'the analytics tables were removed from the baseline, so no database '
            'should ever create them',
      );
    });

    test('a fresh database carries the member profile overlay', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      Future<Set<String>> columnsOf(String table) async =>
          (await db.customSelect("PRAGMA table_info('$table')").get())
              .map((r) => r.read<String>('name'))
              .toSet();

      expect(
        await columnsOf('workspace_members'),
        containsAll(<String>[
          'display_name',
          'email',
          'git_author_name',
          'git_author_email',
        ]),
      );
      expect(await columnsOf('calendar_accounts'), contains('user_id'));
      final indexes =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'index' "
                    "AND name = 'uq_calendar_accounts_user_email'",
                  )
                  .get())
              .map((r) => r.read<String>('name'));
      expect(indexes, ['uq_calendar_accounts_user_email']);
    });

    test('a fresh database carries the space stack table', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'space_stack_entries'",
          )
          .get();
      expect(rows.map((r) => r.data['name'] as String), [
        'space_stack_entries',
      ]);

      final columns = await db
          .customSelect("PRAGMA table_info('space_stack_entries')")
          .get();
      expect(
        columns.map((r) => r.read<String>('name')),
        containsAll(<String>[
          'workspace_id',
          'space_id',
          'repo_id',
          'position',
          'branch',
          'base_branch',
          'pr_number',
          'pr_external_id',
          'rewritten',
        ]),
      );

      final createSql = await db
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE type = 'table' "
            "AND name = 'space_stack_entries'",
          )
          .getSingle();
      final sql = createSql.read<String>('sql');
      expect(sql, contains('UNIQUE'));
      // space_id stays a plain column: teardown reads the branch names after
      // the space row is gone, which a cascade would erase first.
      expect(sql, isNot(contains('REFERENCES spaces')));
    });

    test('fresh workspace carries indexed skill evaluation storage', () async {
      final db = createTestDatabase(workspaceId: 'ws');
      addTearDown(db.close);
      for (final (name, expected) in <(String, Set<String>)>[
        (
          'skill_eval_campaigns',
          {
            'id',
            'workspace_id',
            'skill_key',
            'status',
            'created_at',
            'payload_json',
          },
        ),
        (
          'skill_eval_attempts',
          {'id', 'workspace_id', 'campaign_id', 'ordinal', 'payload_json'},
        ),
        (
          'skill_eval_policies',
          {'workspace_id', 'skill_key', 'enabled', 'payload_json'},
        ),
      ]) {
        final columns = await db.customSelect('PRAGMA table_info($name)').get();
        expect(
          columns.map((r) => r.read<String>('name')),
          containsAll(expected),
        );
      }
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_skill_eval_%'",
          )
          .get();
      expect(
        indexes.map((r) => r.read<String>('name')),
        containsAll([
          'idx_skill_eval_campaigns_skill_created',
          'idx_skill_eval_campaigns_status',
          'idx_skill_eval_attempts_campaign',
        ]),
      );
    });

    test(
      'fresh workspace carries the durable file catalog and indexes',
      () async {
        final db = createTestDatabase(workspaceId: 'ws');
        addTearDown(db.close);
        final columns = await db
            .customSelect('PRAGMA table_info(catalog_files)')
            .get();
        expect(
          columns.map((row) => row.read<String>('name')),
          containsAll([
            'id',
            'workspace_id',
            'uploader_user_id',
            'creator_id',
            'name',
            'path',
            'media_type',
            'bytes',
            'source',
            'state',
            'owned_bytes',
            'created_at',
            'updated_at',
          ]),
        );
        final indexes = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name LIKE 'idx_catalog_files_%'",
            )
            .get();
        expect(
          indexes.map((row) => row.read<String>('name')),
          containsAll([
            'idx_catalog_files_lifecycle',
            'idx_catalog_files_path',
          ]),
        );
      },
    );

    test('a fresh database carries the environment tables', () async {
      final db = WorkspaceDatabase.forTesting(
        NativeDatabase.memory(),
        workspaceId: 'ws',
      );
      addTearDown(db.close);
      Future<Set<String>> columns(String table) => db
          .customSelect('PRAGMA table_info($table)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());

      expect(
        await columns('environment_definitions'),
        containsAll([
          'id',
          'name',
          'definition_json',
          'source_repo_id',
          'source_path',
          'approved_blob_hash',
          'overrides_json',
          'created_by',
          'created_at',
          'updated_at',
        ]),
      );
      expect(
        await columns('space_environments'),
        containsAll([
          'id',
          'space_id',
          'definition_id',
          'name',
          'status',
          'placement',
          'rig_id',
          'ports_json',
          'endpoints_json',
          'components_json',
          'options_json',
          'warnings_json',
          'last_error_json',
          'needs_recreate',
          'created_by',
          'created_at',
          'last_used_at',
        ]),
      );
      expect(
        await columns('environment_runs'),
        containsAll([
          'id',
          'workspace_id',
          'space_id',
          'environment_id',
          'definition_id',
          'repo_id',
          'kind',
          'label',
          'status',
          'started_at',
          'completed_at',
          'exit_code',
          'error',
          'output_text',
        ]),
      );
    });

    group('notification feed waits and pipeline step runs', () {
      late Directory dir;
      late File file;
      setUp(() async {
        dir = await Directory.systemTemp.createTemp('ws_baseline_');
        file = File('${dir.path}/ws.db');
      });
      tearDown(() => dir.delete(recursive: true));

      WorkspaceDatabase open() =>
          WorkspaceDatabase.forTesting(NativeDatabase(file), workspaceId: 'ws');

      Future<Set<String>> columnsOf(WorkspaceDatabase db, String table) async =>
          (await db.customSelect('PRAGMA table_info($table)').get())
              .map((r) => r.read<String>('name'))
              .toSet();

      Future<bool> hasIndex(WorkspaceDatabase db, String name) async =>
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'index' "
                    'AND name = ?',
                    variables: [Variable.withString(name)],
                  )
                  .get())
              .isNotEmpty;

      test(
        'a fresh database indexes the wait id and has no step branch index',
        () async {
          final db = open();
          addTearDown(db.close);
          expect(await hasIndex(db, 'idx_notification_feed_wait_id'), isTrue);
          expect(
            await columnsOf(db, 'pipeline_step_runs'),
            isNot(contains('branch_index')),
          );
        },
      );

      test('resolving a wait is an index probe, not a JSON scan', () async {
        final db = open();
        addTearDown(db.close);
        final plan = await db
            .customSelect(
              'EXPLAIN QUERY PLAN ${NotificationFeedDao.resolveAgentWaitSql}',
              variables: [
                Variable.withString('2026-11-09T00:00:00.000Z'),
                Variable.withString('ws'),
                Variable.withString(
                  NotificationFeedDao.agentAwaitingInputMethod,
                ),
                Variable.withString('wait-1'),
              ],
            )
            .get();
        final detail = plan.map((r) => r.read<String>('detail')).join('\n');
        expect(detail, contains('idx_notification_feed_wait_id'));
      });

      test(
        'a malformed feed frame is refused before the expression index',
        () async {
          final db = open();
          addTearDown(db.close);
          await expectLater(
            db.customStatement(
              'INSERT INTO notification_feed '
              '(id, workspace_id, method, params_json) '
              "VALUES ('n1', 'ws', ?, '{not json')",
              [NotificationFeedDao.agentAwaitingInputMethod],
            ),
            throwsA(isA<SqliteException>()),
          );
          expect(
            await db.notificationFeedDao.resolveAgentWait(
              'ws',
              'wait-1',
              DateTime.utc(2026, 11, 9),
            ),
            0,
          );
        },
      );
    });
  });
}
