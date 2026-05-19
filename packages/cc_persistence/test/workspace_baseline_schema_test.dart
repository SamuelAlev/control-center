import 'dart:io';

import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Pins the per-workspace schema version and the fresh-install shape.
///
/// The current schema IS the baseline: `onCreate` builds exactly the current
/// table set and the migration chain is empty. That makes a fresh database the
/// ONLY description of the schema, so this file has to carry everything the
/// squashed chain used to prove on the way up — a column that survives only
/// because some old step added it would silently stop existing.
void main() {
  group('workspace baseline schema', () {

    // Regression: the first ship of skill_sources relied on the squashed
    // baseline alone, so a database file created before the table existed
    // answered "no such table: skill_sources" at runtime.
    test('an existing v1 database is migrated to carry skill sources', () async {
      final dir = await Directory.systemTemp.createTemp('ws_migration_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/ws.db');

      // Build a current database, then rewind it to "v1 without the table"
      // (DROP TABLE takes its index along) to fake a pre-skill-sources file.
      final setup = WorkspaceDatabase.forTesting(
        NativeDatabase(file),
        workspaceId: 'ws',
      );
      await setup.customStatement('DROP TABLE skill_sources');
      await setup.customStatement('PRAGMA user_version = 1');
      await setup.close();

      // Reopening runs the 1->2 step, which must create the table + index.
      final db = WorkspaceDatabase.forTesting(
        NativeDatabase(file),
        workspaceId: 'ws',
      );
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'skill_sources'",
          )
          .get();
      expect(rows, isNotEmpty);
      final index = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_skill_sources_workspace'",
          )
          .get();
      expect(index, isNotEmpty);
      expect(db.schemaVersion, WorkspaceDatabase.currentSchemaVersion);
    });

    test('reports the version the code says it is', () {
      final db = createTestDatabase();
      addTearDown(db.close);

      // Pinned against the constant rather than a literal: the constant is what
      // `/healthz` reports and what `onUpgrade` compares against, so the thing
      // worth guarding is that the two cannot drift apart. The literal just
      // meant this test had to be edited by whoever bumped it, which taught it
      // nothing.
      expect(db.schemaVersion, WorkspaceDatabase.currentSchemaVersion);
    });

    // Regression: the per-repo lifecycle scripts shipped as v4 (two nullable
    // `repos` columns + the `repo_script_runs` table). A workspace file from
    // v3 must be carried forward by the migration step, not seen as "no such
    // table/column" at the first script write.
    test('an existing v3 database is migrated to carry repo scripts', () async {
      final dir = await Directory.systemTemp.createTemp('ws_migration_v4_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/ws.db');

      // Build a current database, then rewind it to "v3 without the scripts"
      // (ALTER TABLE DROP COLUMN takes the indexes with the table drop) to
      // fake a pre-scripts file.
      final setup = WorkspaceDatabase.forTesting(
        NativeDatabase(file),
        workspaceId: 'ws',
      );
      await setup.customStatement('DROP TABLE repo_script_runs');
      await setup
          .customStatement('ALTER TABLE repos DROP COLUMN setup_script');
      await setup
          .customStatement('ALTER TABLE repos DROP COLUMN archive_script');
      await setup.customStatement('PRAGMA user_version = 3');
      await setup.close();

      final db = WorkspaceDatabase.forTesting(
        NativeDatabase(file),
        workspaceId: 'ws',
      );
      addTearDown(db.close);

      final table = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'repo_script_runs'",
          )
          .get();
      expect(table, isNotEmpty);
      final columns = await db
          .customSelect('PRAGMA table_info(repos)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
      expect(columns, containsAll(['setup_script', 'archive_script']));
      expect(db.schemaVersion, WorkspaceDatabase.currentSchemaVersion);
    });

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

    test(
      'an existing v4 database is migrated to carry sandbox exec grants',
      () async {
        final dir = await Directory.systemTemp.createTemp('ws_migration_v5_');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/ws.db');

        // Build a current database, then rewind it to "v4 without the grants"
        // to fake a pre-grants file.
        final setup = WorkspaceDatabase.forTesting(
          NativeDatabase(file),
          workspaceId: 'ws',
        );
        await setup.customStatement('DROP TABLE sandbox_exec_grants');
        await setup.customStatement('PRAGMA user_version = 4');
        await setup.close();

        final db = WorkspaceDatabase.forTesting(
          NativeDatabase(file),
          workspaceId: 'ws',
        );
        addTearDown(db.close);

        final table = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name = 'sandbox_exec_grants'",
            )
            .get();
        expect(table, isNotEmpty);
        // An absent row means "not asked yet", so a migrated file must start
        // empty rather than inheriting an implied allow.
        final rows = await db
            .customSelect('SELECT COUNT(*) AS n FROM sandbox_exec_grants')
            .get();
        expect(rows.single.read<int>('n'), 0);
        expect(db.schemaVersion, WorkspaceDatabase.currentSchemaVersion);
      },
    );

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
      expect(
        roles,
        containsAll(['id', 'workspace_id', 'name', 'base_preset']),
      );
      final policies = await db
          .customSelect('PRAGMA table_info(action_policies)')
          .get()
          .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
      expect(
        policies,
        containsAll(['constraint_json', 'expires_at', 'enforcement']),
      );
    });

    test(
      'an existing v5 database is migrated to carry the permissions batch',
      () async {
        final dir = await Directory.systemTemp.createTemp('ws_migration_v6_');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/ws.db');

        // Build a current database, then rewind it to "v5 without the batch"
        // to fake a pre-upgrade file.
        final setup = WorkspaceDatabase.forTesting(
          NativeDatabase(file),
          workspaceId: 'ws',
        );
        await setup.customStatement('DROP TABLE approval_routing_policies');
        await setup.customStatement('DROP TABLE guard_decisions');
        await setup.customStatement('DROP TABLE workspace_roles');
        await setup.customStatement(
          'ALTER TABLE action_policies DROP COLUMN constraint_json',
        );
        await setup.customStatement(
          'ALTER TABLE action_policies DROP COLUMN expires_at',
        );
        await setup.customStatement(
          'ALTER TABLE action_policies DROP COLUMN enforcement',
        );
        await setup.customStatement('PRAGMA user_version = 5');
        await setup.close();

        final db = WorkspaceDatabase.forTesting(
          NativeDatabase(file),
          workspaceId: 'ws',
        );
        addTearDown(db.close);

        for (final table in [
          'approval_routing_policies',
          'guard_decisions',
          'workspace_roles',
        ]) {
          final found = await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'table' "
                "AND name = '$table'",
              )
              .get();
          expect(found, isNotEmpty, reason: '$table missing after migration');
        }
        final policies = await db
            .customSelect('PRAGMA table_info(action_policies)')
            .get()
            .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
        expect(
          policies,
          containsAll(['constraint_json', 'expires_at', 'enforcement']),
        );
        expect(db.schemaVersion, WorkspaceDatabase.currentSchemaVersion);
      },
    );

    test(
      'an existing v6 database has its unresolved code edges deleted and the file compacted',
      () async {
        final dir = await Directory.systemTemp.createTemp('ws_migration_v7_');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/ws.db');

        // Build a current database carrying one unresolved and one bound
        // reference edge, then rewind it to v6. FK checks are off for the
        // fixture inserts only — the graph's repo row is irrelevant here.
        final setup = WorkspaceDatabase.forTesting(
          NativeDatabase(file),
          workspaceId: 'ws',
        );
        await setup.customStatement('PRAGMA foreign_keys = OFF');
        Future<void> insertEdge(
          String id,
          String? targetId,
          String? targetName,
        ) => setup.customStatement(
          'INSERT INTO code_edges (id, workspace_id, repo_id, '
          'source_symbol_id, source_file_path, kind, target_symbol_id, '
          'target_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            'ws',
            'repo',
            'sym-src',
            'lib/a.dart',
            'calls',
            targetId,
            targetName,
          ],
        );

        await insertEdge('edge-dead', null, 'react');
        await insertEdge('edge-live', 'sym-target', null);
        await setup.customStatement('PRAGMA user_version = 6');
        await setup.close();

        final db = WorkspaceDatabase.forTesting(
          NativeDatabase(file),
          workspaceId: 'ws',
        );
        addTearDown(db.close);

        final survivors = await db
            .customSelect('SELECT id FROM code_edges')
            .get()
            .then((rows) => rows.map((r) => r.read<String>('id')).toSet());
        expect(
          survivors,
          {'edge-live'},
          reason: 'unresolved edges are write-only rows; bound ones stay',
        );
        // The migration freed pages SQLite would otherwise keep as freelist
        // forever — the one-time VACUUM in beforeOpen must have returned them.
        final freelist = await db
            .customSelect('PRAGMA freelist_count')
            .getSingle()
            .then((row) => row.read<int>('freelist_count'));
        expect(freelist, 0, reason: 'the post-migration VACUUM must compact');
        final stamped = await db
            .customSelect('PRAGMA user_version')
            .getSingle()
            .then((row) => row.read<int>('user_version'));
        expect(stamped, WorkspaceDatabase.currentSchemaVersion);
      },
    );

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

    test('a fresh database carries the audit ip/country columns', () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect("PRAGMA table_info('user_activity')")
          .get();
      final columns = rows.map((r) => r.read<String>('name')).toSet();

      expect(columns, containsAll(<String>['ip', 'country_code']));
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
      expect(await columnsOf('pipeline_templates'), contains('max_parallel_runs'));
      expect(await columnsOf('pipeline_runs'), contains('attempt_started_at'));
      // Which attempt of a run is current, so the page can say "Attempt 3".
      expect(await columnsOf('pipeline_runs'), contains('attempt_count'));
      expect(await columnsOf('pipeline_step_runs'), contains('attempt_history'));

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
        indexes
            .firstWhere((i) => i.$1 == 'uq_pipeline_runs_active_dedup')
            .$2,
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

      // The lookup index too: the panel reads this table by (workspace, user)
      // on every open, and a table created without it degrades to a scan that
      // no other test would notice.
      final indexes =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'index' "
                    "AND name = 'idx_notification_item_states_user'",
                  )
                  .get())
              .map((r) => r.read<String>('name'));
      expect(indexes, ['idx_notification_item_states_user']);
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
  });
}
