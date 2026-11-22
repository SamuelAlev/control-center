import 'dart:io';
import 'dart:typed_data';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/src/vector_extension.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/schema_fixture.dart';

/// What happens to a workspace file that an earlier build wrote.
///
/// There is no ladder of steps to test one by one. A file of any earlier
/// version is converged to the declared schema, so the tests start from the
/// schemas installs really hold (`test/fixtures/schema`) and check the one
/// property that matters: the file ends up exactly as a fresh one, with its
/// rows.
void main() {
  late Directory tmp;
  late File file;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = Directory.systemTemp.createTempSync('cc_ws_converge');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    file = File('${tmp.path}/workspace.db');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  final warnings = <String>[];
  setUp(warnings.clear);

  WorkspaceDatabase open({String? snapshots}) {
    final db = WorkspaceDatabase(
      NativeDatabase(file),
      workspaceId: 'ws',
      upgradeSnapshotDirectory: snapshots,
      onWarn: (tag, message) => warnings.add('$tag: $message'),
    );
    addTearDown(db.close);
    return db;
  }

  Future<int> pragma(WorkspaceDatabase db, String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).read<int>(name);

  Future<List<Object?>> column(WorkspaceDatabase db, String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data.values.first,
  ];

  /// The rows a real file would hold, written the way the old build wrote
  /// them (the fixture's own triggers feed its full-text indexes).
  void seed(sqlite3.Database db) {
    db
      ..execute(
        'INSERT INTO workspace_meta (id, workspace_id, install_id, '
        "created_with_schema_version) VALUES (0, 'ws', 'install-1', 1)",
      )
      ..execute(
        'INSERT INTO spaces (id, name, workspace_id) '
        "VALUES ('s1', 'General', 'ws')",
      )
      ..execute(
        'INSERT INTO conversations (id, workspace_id, space_id) '
        "VALUES ('c1', 'ws', 's1')",
      )
      ..execute(
        'INSERT INTO conversation_messages '
        '(id, space_id, conversation_id, sender_id, sender_type, content) '
        "VALUES ('m1', 's1', 'c1', 'u1', 'user', 'the heron landed'), "
        "('m2', 's1', 'c1', 'u1', 'user', 'a second message')",
      )
      ..execute(
        'INSERT INTO memory_facts (id, workspace_id, domain, topic, content) '
        "VALUES ('f1', 'ws', 'ops', 'birds', 'herons fish at dawn')",
      )
      ..execute(
        'INSERT INTO catalog_events '
        '(id, workspace_id, component_id, kind, occurred_at) '
        "VALUES ('e1', 'ws', 'comp', 'deploy', 0)",
      );
  }

  for (final name in [
    'workspace_v29_a',
    'workspace_v29_b',
    'workspace_v29_c',
  ]) {
    test('$name converges to the schema of a fresh file and keeps its '
        'rows', () async {
      SchemaFixture.load(name).writeTo(file.path, seed: seed);

      final db = open();

      expect(await db.schemaDifferences(), isEmpty);
      expect(
        await pragma(db, 'user_version'),
        WorkspaceDatabase.currentSchemaVersion,
      );
      expect(
        await pragma(db, 'application_id'),
        WorkspaceDatabase.fileApplicationId,
      );
      expect(await pragma(db, 'foreign_keys'), 1);
      expect(await column(db, 'PRAGMA foreign_key_check'), isEmpty);

      expect(await column(db, 'SELECT name FROM spaces'), ['General']);
      expect(
        await column(db, 'SELECT id FROM conversation_messages ORDER BY id'),
        ['m1', 'm2'],
      );
      expect(await column(db, 'SELECT install_id FROM workspace_meta'), [
        'install-1',
      ]);

      // The tables no table class declares any more are gone, and the log
      // says so.
      final report = db.lastConvergeReport!;
      expect(report.droppedTables, contains('catalog_events'));
      expect(
        await column(
          db,
          "SELECT name FROM sqlite_master WHERE name LIKE 'catalog_%' "
          "AND type = 'table' AND name != 'catalog_files'",
        ),
        isEmpty,
      );
      expect(
        warnings.single,
        allOf(
          startsWith('SchemaConverge: workspace ws v29 -> v'),
          contains('catalog_events'),
        ),
      );
    });
  }

  test('search still finds what the file held, and keeps following '
      'writes', () async {
    SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);

    final db = open();

    Future<List<Object?>> messagesMatching(String term) => column(
      db,
      'SELECT m.id FROM conversation_messages_fts f '
      'JOIN conversation_messages m ON m.rowid = f.rowid '
      "WHERE conversation_messages_fts MATCH '$term'",
    );

    expect(await messagesMatching('heron'), ['m1']);
    expect(
      await column(
        db,
        'SELECT m.id FROM memory_facts_fts f '
        'JOIN memory_facts m ON m.rowid = f.rowid '
        "WHERE memory_facts_fts MATCH 'herons'",
      ),
      ['f1'],
    );

    // The sync triggers were dropped with every other trigger and installed
    // again on open: an edit and a delete both reach the index.
    await db.customStatement(
      "UPDATE conversation_messages SET content = 'the egret left' "
      "WHERE id = 'm1'",
    );
    await db.customStatement(
      "DELETE FROM conversation_messages WHERE id = 'm2'",
    );
    expect(await messagesMatching('heron'), isEmpty);
    expect(await messagesMatching('egret'), ['m1']);
    expect(await messagesMatching('second'), isEmpty);
    // An external-content index checks itself against its content table.
    await db.customStatement(
      'INSERT INTO conversation_messages_fts(conversation_messages_fts, rank) '
      "VALUES ('integrity-check', 1)",
    );
  });

  test('a converged file opens again without converging', () async {
    SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);
    final first = open();
    await first.customSelect('SELECT 1').get();
    expect(first.lastConvergeReport, isNotNull);
    await first.close();
    warnings.clear();

    final second = open();

    expect(await second.schemaDifferences(), isEmpty);
    expect(second.lastConvergeReport, isNull);
    expect(warnings, isEmpty);
  });

  group('from schema 34', () {
    // `workspace_v34` is the declared schema of the build that introduced
    // code mode, read from a fresh file of that build: every install reached
    // 34 by converging to exactly that schema.
    void seed34(sqlite3.Database db) {
      db
        ..execute(
          'PRAGMA application_id = ${WorkspaceDatabase.fileApplicationId}',
        )
        ..execute(
          'INSERT INTO workspace_meta (id, workspace_id, install_id, '
          "created_with_schema_version) VALUES (0, 'ws', 'install-1', 34)",
        )
        ..execute(
          'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
          "skills, code_mode) VALUES ('a1', 'Builder', 'Engineer', "
          "'/agents/builder.md', 'ws', 'dart', 'hybrid')",
        )
        ..execute(
          'INSERT INTO workspace_settings (workspace_id, key, value) VALUES '
          "('ws', 'code_mode', 'only'), "
          "('ws', 'code_mode_limits', '{}'), "
          "('ws', 'branch_template', 'feat/{slug}')",
        );
    }

    test('loses the agent override and the code mode setting, and keeps '
        'everything else', () async {
      SchemaFixture.load('workspace_v34').writeTo(file.path, seed: seed34);

      final db = open();

      expect(await db.schemaDifferences(), isEmpty);
      expect(
        await pragma(db, 'user_version'),
        WorkspaceDatabase.currentSchemaVersion,
      );
      expect(await column(db, 'PRAGMA foreign_key_check'), isEmpty);
      expect(
        await column(db, "SELECT name FROM pragma_table_info('agents')"),
        isNot(contains('code_mode')),
      );
      expect(await column(db, 'SELECT name FROM agents'), ['Builder']);
      expect(
        await column(db, 'SELECT key FROM workspace_settings ORDER BY key'),
        ['branch_template', 'code_mode_limits'],
      );
      expect(
        warnings,
        contains(
          'SchemaConverge: workspace ws v34: dropped the retired '
          'setting code_mode',
        ),
      );
      expect(
        await column(
          db,
          "SELECT name FROM pragma_table_info('code_execution_calls') "
          "WHERE name LIKE 'site_%' ORDER BY cid",
        ),
        ['site_line', 'site_column'],
      );
    });

    test('the copy taken before the upgrade still holds both', () async {
      SchemaFixture.load('workspace_v34').writeTo(file.path, seed: seed34);
      final snapshots = Directory('${tmp.path}/pre_upgrade');

      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      final copy = snapshots.listSync().whereType<File>().single;
      final raw = sqlite3.sqlite3.open(copy.path);
      addTearDown(raw.close);
      expect(raw.select('SELECT code_mode FROM agents').single.values, [
        'hybrid',
      ]);
      expect(
        raw
            .select(
              "SELECT value FROM workspace_settings WHERE key = 'code_mode'",
            )
            .single
            .values,
        ['only'],
      );
    });

    test('only an upgrade from before 35 drops the setting', () async {
      final fresh = open();
      await fresh.customStatement(
        'INSERT INTO workspace_settings (workspace_id, key, value) '
        "VALUES ('ws', 'code_mode', 'hybrid')",
      );
      await fresh.close();

      final reopened = open();
      expect(await column(reopened, 'SELECT key FROM workspace_settings'), [
        'code_mode',
      ]);
      expect(reopened.lastConvergeReport, isNull);
    });
  });

  group('from schema 35', () {
    // `workspace_v35` is the declared schema of the build before the long
    // running work tables, read from a fresh file of that build. Agent a1
    // holds three active goals (two created in the same second, so the id
    // breaks the tie), a paused one and a paused loop; agent a2 holds one
    // active goal; agent a3 one active loop; agent a4 an active goal and a
    // newer active loop.
    void seed35(sqlite3.Database db) {
      db
        ..execute(
          'PRAGMA application_id = ${WorkspaceDatabase.fileApplicationId}',
        )
        ..execute(
          'INSERT INTO workspace_meta (id, workspace_id, install_id, '
          "created_with_schema_version) VALUES (0, 'ws', 'install-1', 35)",
        )
        ..execute(
          'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
          "skills) VALUES ('a1', 'Builder', 'Engineer', '/a1.md', 'ws', ''), "
          "('a2', 'Checker', 'Reviewer', '/a2.md', 'ws', ''), "
          "('a3', 'Looper', 'Engineer', '/a3.md', 'ws', ''), "
          "('a4', 'Mixed', 'Engineer', '/a4.md', 'ws', '')",
        )
        ..execute(
          "INSERT INTO spaces (id, name, workspace_id) VALUES ('s1', 'G', 'ws')",
        )
        ..execute(
          'INSERT INTO conversations (id, workspace_id, space_id) '
          "VALUES ('c1', 'ws', 's1')",
        )
        ..execute(
          'INSERT INTO agent_goal_runs (id, workspace_id, space_id, '
          'conversation_id, agent_id, user_text, kind, status, created_at, '
          'updated_at) VALUES '
          "('g-old', 'ws', 's1', 'c1', 'a1', 'first', 'goal', 'active', "
          '1000, 1000), '
          "('g-tie-b', 'ws', 's1', 'c1', 'a1', 'third', 'goal', 'active', "
          '2000, 2000), '
          "('g-tie-a', 'ws', 's1', 'c1', 'a1', 'second', 'goal', 'active', "
          '2000, 2000), '
          "('g-paused', 'ws', 's1', 'c1', 'a1', 'paused', 'goal', 'paused', "
          '3000, 3000), '
          "('g-solo', 'ws', 's1', 'c1', 'a2', 'solo', 'goal', 'active', "
          '500, 500), '
          "('l-paused', 'ws', 's1', 'c1', 'a1', 'tidy', 'loop', 'paused', "
          '3500, 3500), '
          "('l-solo', 'ws', 's1', 'c1', 'a3', 'poll', 'loop', 'active', "
          '600, 600), '
          "('g-mixed', 'ws', 's1', 'c1', 'a4', 'ship', 'goal', 'active', "
          '3500, 3500), '
          "('l-mixed', 'ws', 's1', 'c1', 'a4', 'watch', 'loop', 'active', "
          '4000, 4000)',
        )
        ..execute(
          'INSERT INTO tickets (id, workspace_id, title, status) '
          "VALUES ('t1', 'ws', 'Fix it', 'open')",
        );
    }

    Future<Map<String, String>> statuses(WorkspaceDatabase db) async => {
      for (final row
          in await db
              .customSelect('SELECT id, status FROM agent_goal_runs')
              .get())
        row.read<String>('id'): row.read<String>('status'),
    };

    test('ends every running loop, then keeps each agent\'s newest active '
        'goal and cancels the others instead of dropping them', () async {
      SchemaFixture.load('workspace_v35').writeTo(file.path, seed: seed35);

      final db = open();

      expect(await db.schemaDifferences(), isEmpty);
      expect(
        await pragma(db, 'user_version'),
        WorkspaceDatabase.currentSchemaVersion,
      );
      expect(await column(db, 'PRAGMA foreign_key_check'), isEmpty);
      expect(await statuses(db), {
        'g-old': 'cancelled',
        'g-tie-a': 'cancelled',
        'g-tie-b': 'active',
        'g-paused': 'paused',
        'g-solo': 'active',
        'l-paused': 'cancelled',
        'l-solo': 'cancelled',
        // The loop is ended first, so the agent's goal is the one it keeps.
        'g-mixed': 'active',
        'l-mixed': 'cancelled',
      });
      expect(
        await column(
          db,
          "SELECT DISTINCT summary FROM agent_goal_runs WHERE id LIKE 'l-%'",
        ),
        [WorkspaceDatabase.loopEndedByUpgradeSummary],
      );
      expect(
        await column(
          db,
          "SELECT summary FROM agent_goal_runs WHERE id = 'g-old'",
        ),
        [null],
      );
      expect(db.lastConvergeReport!.droppedRows, isEmpty);
      expect(
        warnings,
        allOf(
          contains(
            'SchemaConverge: workspace ws: cancelled 3 running loops (a loop '
            'is now a schedule)',
          ),
          contains(
            'SchemaConverge: workspace ws: cancelled 2 active goals that were '
            "not their agent's newest (one active goal per agent)",
          ),
        ),
      );
      expect(
        await column(
          db,
          "SELECT name FROM pragma_table_info('agent_goal_runs')",
        ),
        allOf(
          isNot(contains('kind')),
          containsAll([
            'hold',
            'contract',
            'last_activity_digest',
            'start_ref',
            'pipeline_run_id',
            'pipeline_step_id',
            'progress_marks',
          ]),
        ),
      );
      expect(
        await column(db, "SELECT name FROM pragma_table_info('wake_rules')"),
        containsAll(['root_rule_id', 'note_edited_by_user_id']),
      );
      expect(
        await column(
          db,
          "SELECT name FROM pragma_index_list('wake_rules') "
          "WHERE name = 'idx_wake_rules_root_rule'",
        ),
        ['idx_wake_rules_root_rule'],
      );
      expect(
        await column(
          db,
          "SELECT name FROM pragma_table_info('agent_run_logs')",
        ),
        containsAll([
          'end_reason',
          'wake_ids',
          'requested_by_user_id',
          'wake_reason',
        ]),
      );
      expect(
        await column(db, "SELECT name FROM pragma_table_info('peer_asks')"),
        containsAll([
          'promised_at',
          'blocked_noticed_at',
          'stall_noticed_run_id',
        ]),
      );
      // The new columns read their defaults on the old rows.
      expect(
        await column(
          db,
          "SELECT unattended FROM agent_goal_runs WHERE id = 'g-solo'",
        ),
        ['wait'],
      );
      expect(
        await column(
          db,
          'SELECT last_activity_digest FROM agent_goal_runs '
          "WHERE id = 'g-solo'",
        ),
        [null],
      );
      // A goal started before its start commits were recorded has none.
      expect(
        await column(
          db,
          "SELECT start_ref FROM agent_goal_runs WHERE id = 'g-solo'",
        ),
        [null],
      );
      // A goal from before is no pipeline step's and has seen no marks.
      expect(
        await column(
          db,
          'SELECT coalesce(pipeline_run_id, pipeline_step_id, progress_marks) '
          'FROM agent_goal_runs '
          "WHERE id = 'g-solo'",
        ),
        [null],
      );
      expect(await column(db, 'SELECT wake_ids FROM agent_run_logs'), isEmpty);
      expect(
        await column(
          db,
          "SELECT delegated_from_conversation_id FROM tickets WHERE id = 't1'",
        ),
        [null],
      );
      for (final table in [
        'agent_wakes',
        'wake_rules',
        'peer_asks',
        'improvement_proposals',
      ]) {
        expect(await column(db, 'SELECT count(*) FROM $table'), [0]);
      }
    });

    test('the index then refuses a second active goal', () async {
      SchemaFixture.load('workspace_v35').writeTo(file.path, seed: seed35);

      final db = open();
      await db.customSelect('SELECT 1').get();

      await expectLater(
        db.customStatement(
          "UPDATE agent_goal_runs SET status = 'active' WHERE id = 'g-old'",
        ),
        throwsA(anything),
      );
    });

    test('the copy taken before the upgrade holds every goal as it '
        'was', () async {
      SchemaFixture.load('workspace_v35').writeTo(file.path, seed: seed35);
      final snapshots = Directory('${tmp.path}/pre_upgrade');

      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      final copy = snapshots.listSync().whereType<File>().single;
      final raw = sqlite3.sqlite3.open(copy.path);
      addTearDown(raw.close);
      expect(
        raw
            .select(
              "SELECT count(*) AS n FROM agent_goal_runs WHERE status = 'active'",
            )
            .single['n'],
        7,
      );
      expect(
        raw
            .select(
              "SELECT count(*) AS n FROM agent_goal_runs WHERE kind = 'loop'",
            )
            .single['n'],
        3,
      );
    });

    test('a file converged outside an upgrade (import) gets the same '
        'fix', () async {
      final db = open();
      await db.customSelect('SELECT 1').get();
      await db.customStatement('DROP INDEX uq_agent_goal_runs_active_agent');
      await db.customStatement(
        'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
        "skills) VALUES ('a1', 'Builder', 'Engineer', '/a1.md', 'ws', '')",
      );
      await db.customStatement(
        "INSERT INTO spaces (id, name, workspace_id) VALUES ('s1', 'G', 'ws')",
      );
      await db.customStatement(
        'INSERT INTO conversations (id, workspace_id, space_id) '
        "VALUES ('c1', 'ws', 's1')",
      );
      await db.customStatement(
        'INSERT INTO agent_goal_runs (id, workspace_id, space_id, '
        'conversation_id, agent_id, user_text, created_at, updated_at) VALUES '
        "('g1', 'ws', 's1', 'c1', 'a1', 'one', 10, 10), "
        "('g2', 'ws', 's1', 'c1', 'a1', 'two', 20, 20)",
      );

      final report = await db.convergeSchema();

      expect(report.droppedRows, isEmpty);
      expect(await statuses(db), {'g1': 'cancelled', 'g2': 'active'});
      expect(
        await column(
          db,
          'SELECT name FROM sqlite_master WHERE name = '
          "'uq_agent_goal_runs_active_agent'",
        ),
        ['uq_agent_goal_runs_active_agent'],
      );
    });

    test('a file without duplicates is left untouched', () async {
      final db = open();
      await db.customSelect('SELECT 1').get();
      await db.convergeSchema();
      expect(warnings.where((w) => w.contains('cancelled')), isEmpty);
    });
  });

  group('from schema 37', () {
    // `workspace_v37` is the declared schema of 37, read from a fresh file
    // of that build: 38 changed only `improvement_proposals.campaign_state`,
    // whose check gained `staging`.
    void seed37(sqlite3.Database db) {
      db
        ..execute(
          'PRAGMA application_id = ${WorkspaceDatabase.fileApplicationId}',
        )
        ..execute(
          'INSERT INTO workspace_meta (id, workspace_id, install_id, '
          "created_with_schema_version) VALUES (0, 'ws', 'install-1', 37)",
        )
        ..execute(
          'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
          "skills) VALUES ('a1', 'Builder', 'Engineer', '/a1.md', 'ws', '')",
        )
        ..execute(
          "INSERT INTO spaces (id, name, workspace_id) VALUES ('s1', 'G', 'ws')",
        )
        ..execute(
          'INSERT INTO conversations (id, workspace_id, space_id) '
          "VALUES ('c1', 'ws', 's1')",
        )
        ..execute(
          'INSERT INTO improvement_proposals (id, workspace_id, agent_id, '
          'space_id, conversation_id, kind, scope, scope_ref_id, operation, '
          'target_ref, change, evidence, expected, status, before_text, '
          'after_text, applied_ref, candidate_revision_id, campaign_id, '
          'campaign_state, decided_by_user_id, decided_at, created_at, '
          'expires_at) VALUES '
          "('p-run', 'ws', 'a1', 's1', 'c1', 'skill_edit', 'workspace', "
          "'lint', 'replace', 'Run the linter.', 'Run the linter with "
          "--fix.', '{\"runs\": [\"r1\"]}', 'Fewer lint loops.', 'proposed', "
          "NULL, NULL, NULL, 'rev-abc', 'camp-1', 'running', NULL, NULL, "
          '1000, 2593000), '
          "('p-done', 'ws', 'a1', 's1', 'c1', 'memory_fact', 'agent', NULL, "
          "'add', NULL, 'Run make gen first.', '{}', 'Green builds.', "
          "'accepted', NULL, 'Run make gen first.', 'memory_fact:refine-p', "
          "NULL, NULL, 'none', 'user-1', 2000, 1500, 2593500)",
        );
    }

    List<Map<String, Object?>> rows(String path) {
      final raw = sqlite3.sqlite3.open(path);
      try {
        return [
          for (final row in raw.select(
            'SELECT * FROM improvement_proposals ORDER BY id',
          ))
            Map.of(row),
        ];
      } finally {
        raw.close();
      }
    }

    test('converges to the fresh schema, keeps every proposal as it was, '
        'and then takes a staging claim', () async {
      SchemaFixture.load('workspace_v37').writeTo(file.path, seed: seed37);
      final before = rows(file.path);
      expect(before, hasLength(2));
      // The 37 check refuses the new state.
      final raw = sqlite3.sqlite3.open(file.path);
      expect(
        () => raw.execute(
          "UPDATE improvement_proposals SET campaign_state = 'staging' "
          "WHERE id = 'p-done'",
        ),
        throwsA(isA<sqlite3.SqliteException>()),
      );
      raw.close();

      final db = open();
      expect(await db.schemaDifferences(), isEmpty);
      expect(
        await pragma(db, 'user_version'),
        WorkspaceDatabase.currentSchemaVersion,
      );
      expect(await column(db, 'PRAGMA foreign_key_check'), isEmpty);
      await db.close();
      expect(rows(file.path), before);

      final again = open();
      await again.customStatement(
        "UPDATE improvement_proposals SET campaign_state = 'staging' "
        "WHERE id = 'p-run'",
      );
      expect(
        await column(
          again,
          "SELECT campaign_state FROM improvement_proposals WHERE id = 'p-run'",
        ),
        ['staging'],
      );
    });
  });

  group('from schema 39', () {
    // `workspace_v39` is the declared schema of 39, read from a fresh file
    // of that build: 40 adds `agent_run_logs.started_by_run_id`.
    void seed39(sqlite3.Database db) {
      db
        ..execute(
          'PRAGMA application_id = ${WorkspaceDatabase.fileApplicationId}',
        )
        ..execute(
          'INSERT INTO workspace_meta (id, workspace_id, install_id, '
          "created_with_schema_version) VALUES (0, 'ws', 'install-1', 39)",
        )
        ..execute(
          'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
          "skills) VALUES ('a1', 'Builder', 'Engineer', '/a1.md', 'ws', '')",
        )
        ..execute(
          'INSERT INTO agent_run_logs (id, agent_id, workspace_id, '
          'started_at, status, wake_ids, wake_reason) VALUES '
          "('run-1', 'a1', 'ws', 1000, 'completed', '[]', 'assignment'), "
          "('run-2', 'a1', 'ws', 2000, 'running', '[\"wk-1\"]', 'schedule')",
        );
    }

    List<Map<String, Object?>> rows(String path) {
      final raw = sqlite3.sqlite3.open(path);
      try {
        return [
          for (final row in raw.select(
            'SELECT * FROM agent_run_logs ORDER BY id',
          ))
            Map.of(row),
        ];
      } finally {
        raw.close();
      }
    }

    test('converges to the fresh schema, keeps every run as it was with no '
        'starter, and then records one', () async {
      SchemaFixture.load('workspace_v39').writeTo(file.path, seed: seed39);
      final before = rows(file.path);
      expect(before, hasLength(2));
      expect(before.first.containsKey('started_by_run_id'), isFalse);
      final snapshots = Directory('${tmp.path}/pre_upgrade');

      final db = open(snapshots: snapshots.path);
      expect(await db.schemaDifferences(), isEmpty);
      expect(
        await pragma(db, 'user_version'),
        WorkspaceDatabase.currentSchemaVersion,
      );
      expect(await column(db, 'PRAGMA foreign_key_check'), isEmpty);
      await db.close();
      final after = rows(file.path);
      expect([
        for (final row in after) {...row}..remove('started_by_run_id'),
      ], before);
      expect(after.map((row) => row['started_by_run_id']), [null, null]);
      // The copy taken before the upgrade is the 39 file.
      final copy = snapshots.listSync().whereType<File>().single;
      expect(rows(copy.path), before);

      final again = open();
      await again.customStatement(
        "UPDATE agent_run_logs SET started_by_run_id = 'run-2' "
        "WHERE id = 'run-1'",
      );
      expect(
        await column(
          again,
          "SELECT started_by_run_id FROM agent_run_logs WHERE id = 'run-1'",
        ),
        ['run-2'],
      );
    });
  });

  test('a fresh file is at the current version, carries the workspace '
      'application id and matches the declared schema', () async {
    final db = open();

    expect(await db.schemaDifferences(), isEmpty);
    expect(
      await pragma(db, 'user_version'),
      WorkspaceDatabase.currentSchemaVersion,
    );
    expect(
      await pragma(db, 'application_id'),
      WorkspaceDatabase.fileApplicationId,
    );
    expect(db.lastConvergeReport, isNull);
  });

  group('convergeSchema on a file somebody else prepared', () {
    test('removes what the schema does not declare and restores what it '
        'does', () async {
      final db = open();
      await db.customSelect('SELECT 1').get();
      await db.customStatement('CREATE TABLE planted (id TEXT)');
      await db.customStatement(
        'CREATE TRIGGER planted_spy AFTER INSERT ON spaces BEGIN '
        'INSERT INTO planted VALUES (new.id); END',
      );
      await db.customStatement('CREATE VIEW planted_view AS SELECT 1');
      // Any declared index will do: which ones exist is the tables'
      // business, not this test's.
      final declaredIndex =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'index' "
                    'AND sql IS NOT NULL ORDER BY name LIMIT 1',
                  )
                  .getSingle())
              .read<String>('name');
      await db.customStatement('DROP INDEX "$declaredIndex"');
      await db.customStatement(
        'ALTER TABLE spaces ADD COLUMN planted_column TEXT',
      );
      expect(await db.schemaDifferences(), isNotEmpty);

      await db.convergeSchema();
      await db.close();

      // The full-text triggers come back when the file opens.
      final reopened = open();
      expect(await reopened.schemaDifferences(), isEmpty);
    });
  });

  group('refusals', () {
    test('a file a newer build wrote is refused and left as it is', () async {
      final current = open();
      await current.customSelect('SELECT 1').get();
      await current.close();
      const newer = WorkspaceDatabase.currentSchemaVersion + 1;
      sqlite3.sqlite3.open(file.path)
        ..execute('ALTER TABLE spaces ADD COLUMN from_the_future TEXT')
        ..execute('PRAGMA user_version = $newer')
        ..close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<DatabaseNewerThanBinaryException>()
              .having((e) => e.fileVersion, 'fileVersion', newer)
              .having(
                (e) => e.binaryVersion,
                'binaryVersion',
                WorkspaceDatabase.currentSchemaVersion,
              )
              .having((e) => e.database, 'database', 'workspace ws'),
        ),
      );
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      addTearDown(raw.close);
      expect(raw.select('PRAGMA user_version').single.values.single, newer);
      expect(
        raw.select('PRAGMA table_info(spaces)').map((r) => r['name']),
        contains('from_the_future'),
      );
    });

    test('a global database put where a workspace belongs is '
        'refused', () async {
      final global = GlobalDatabase.forTesting(NativeDatabase(file));
      await global.customSelect('SELECT 1').get();
      await global.close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<ForeignDatabaseFileException>().having(
            (e) => e.applicationId,
            'applicationId',
            GlobalDatabase.fileApplicationId,
          ),
        ),
      );
    });

    test('an unrelated SQLite file is refused, not emptied', () async {
      sqlite3.sqlite3.open(file.path)
        ..execute('CREATE TABLE recipes (id TEXT PRIMARY KEY)')
        ..execute("INSERT INTO recipes VALUES ('soup')")
        ..execute('PRAGMA user_version = 4')
        ..close();

      final db = open(snapshots: '${tmp.path}/pre_upgrade');

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(isA<ForeignDatabaseFileException>()),
      );
      await db.close();

      final raw = sqlite3.sqlite3.open(file.path);
      addTearDown(raw.close);
      expect(raw.select('SELECT id FROM recipes').single['id'], 'soup');
      expect(Directory('${tmp.path}/pre_upgrade').existsSync(), isFalse);
    });

    test('a current-version file without the application id is '
        'refused', () async {
      final current = open();
      await current.customSelect('SELECT 1').get();
      await current.close();
      sqlite3.sqlite3.open(file.path)
        ..execute('PRAGMA application_id = 0')
        ..close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(isA<ForeignDatabaseFileException>()),
      );
    });
  });

  group('the copy taken before an upgrade', () {
    late Directory snapshots;

    setUp(() => snapshots = Directory('${tmp.path}/pre_upgrade'));

    List<File> copies() =>
        snapshots.listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('holds the file as it was', () async {
      SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);

      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      final copy = copies().single;
      expect(
        copy.uri.pathSegments.last,
        matches(RegExp(r'^v29\.\d{8}T\d{6}Z\.db$')),
      );
      final raw = sqlite3.sqlite3.open(copy.path);
      addTearDown(raw.close);
      expect(raw.select('PRAGMA user_version').single.values.single, 29);
      // Still the old shape, old tables and all.
      expect(raw.select('SELECT id FROM catalog_events').single['id'], 'e1');
      expect(raw.select('PRAGMA quick_check').single.values.single, 'ok');
    });

    test('is one of the two newest kept', () async {
      snapshots.createSync();
      final old = DateTime.utc(2026);
      for (final (index, name) in [
        'v27.a.db',
        'v28.b.db',
        'v28.c.db',
      ].indexed) {
        File('${snapshots.path}/$name')
          ..writeAsStringSync('old copy')
          ..setLastModifiedSync(old.add(Duration(days: index)));
      }
      SchemaFixture.load('workspace_v29_a').writeTo(file.path, seed: seed);

      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      final names = copies().map((f) => f.uri.pathSegments.last).toList();
      expect(names, hasLength(2));
      expect(names.first, startsWith('v28.c'));
      expect(names.last, startsWith('v29.'));
    });

    test('is not taken when nothing is upgraded', () async {
      final db = open(snapshots: snapshots.path);
      await db.customSelect('SELECT 1').get();

      expect(snapshots.existsSync(), isFalse);
    });
  });

  group('through the server connection', () {
    WorkspaceDatabase openServer() {
      final db = WorkspaceDatabase(
        openWorkspaceDatabase(dataDir: tmp.path, workspaceId: 'ws'),
        workspaceId: 'ws',
        upgradeSnapshotDirectory: workspaceUpgradeSnapshotDir(tmp.path, 'ws'),
      );
      addTearDown(db.close);
      return db;
    }

    Float32List vector(double tilt) => Float32List(384)
      ..[0] = 1
      ..[1] = tilt;

    Future<void> addFact(WorkspaceDatabase db, String id, double tilt) =>
        db.transaction(() async {
          await db.memoryFactDao.upsert(
            MemoryFactsTableCompanion.insert(
              id: id,
              workspaceId: 'ws',
              domain: 'ops',
              topic: id,
              content: 'fact $id',
            ),
          );
          await db.memoryFactDao.putEmbedding(
            id,
            vector(tilt).buffer.asUint8List(),
          );
        });

    test('a new file reclaims freed pages incrementally and journals in '
        'WAL', () async {
      final db = openServer();

      expect(await pragma(db, 'auto_vacuum'), 2);
      expect(await column(db, 'PRAGMA journal_mode'), ['wal']);
      expect(await db.schemaDifferences(), isEmpty);
    });

    test('an upgraded file is switched to incremental reclaim, and search '
        'survives the rewrite', () async {
      final path = workspaceDatabasePath(tmp.path, 'ws');
      Directory(workspaceDirPath(tmp.path, 'ws')).createSync();
      SchemaFixture.load('workspace_v29_a').writeTo(
        path,
        seed: (raw) {
          seed(raw);
          // Rowids that a rewrite would be free to renumber: the full-text
          // index addresses rows by them.
          raw
            ..execute(
              'INSERT INTO conversation_messages (rowid, id, space_id, '
              'conversation_id, sender_id, sender_type, content) '
              "VALUES (9000, 'far', 's1', 'c1', 'u1', 'user', 'kingfisher')",
            )
            ..execute("DELETE FROM conversation_messages WHERE id = 'm2'");
        },
      );

      final db = openServer();

      expect(await pragma(db, 'auto_vacuum'), 2);
      expect(db.fileWasRewritten, isTrue);
      expect(
        await column(
          db,
          'SELECT m.id FROM conversation_messages_fts f '
          'JOIN conversation_messages m ON m.rowid = f.rowid '
          "WHERE conversation_messages_fts MATCH 'kingfisher'",
        ),
        ['far'],
      );
      await db.customStatement(
        'INSERT INTO conversation_messages_fts(conversation_messages_fts, rank) '
        "VALUES ('integrity-check', 1)",
      );
      expect(await db.schemaDifferences(), isEmpty);
    });

    test('vector search works on whichever connection serves the '
        'read', () async {
      final db = openServer();
      await addFact(db, 'near', 0);
      await addFact(db, 'far', 1);

      // Reads rotate over the pool, so a handful of them reaches every
      // reader as well as the writer.
      for (var i = 0; i < 6; i++) {
        final hits = await db.memoryFactDao.searchVector(
          'ws',
          vector(0),
          limit: 1,
        );
        expect(hits.map((fact) => fact.id), ['near']);
      }
    });

    test('vector search works on a file that already existed', () async {
      final first = openServer();
      await addFact(first, 'near', 0);
      await first.close();

      final db = openServer();

      for (var i = 0; i < 6; i++) {
        final hits = await db.memoryFactDao.searchVector(
          'ws',
          vector(0),
          limit: 1,
        );
        expect(hits.map((fact) => fact.id), ['near']);
      }
    });

    test('a read sees the write before it, inside a transaction and '
        'out', () async {
      final db = openServer();

      for (var i = 0; i < 6; i++) {
        await addFact(db, 'fact-$i', 0);
        expect(await db.memoryFactDao.getById('ws', 'fact-$i'), isNotNull);
      }
      await db.transaction(() async {
        await addFact(db, 'in-transaction', 0);
        expect(
          await db.memoryFactDao.getById('ws', 'in-transaction'),
          isNotNull,
        );
      });
    });

    test('snapshotDatabaseFile copies a live file without its '
        'connection', () async {
      final db = openServer();
      await addFact(db, 'kept', 0);
      final copy = '${tmp.path}/copy.db';

      await snapshotDatabaseFile(
        source: workspaceDatabasePath(tmp.path, 'ws'),
        destination: copy,
      );

      final raw = sqlite3.sqlite3.open(copy);
      addTearDown(raw.close);
      expect(raw.select('SELECT id FROM memory_facts').single['id'], 'kept');
      expect(
        raw.select('PRAGMA application_id').single.values.single,
        WorkspaceDatabase.fileApplicationId,
      );
    });

    test('snapshotDatabaseFile copies a file the vector extension has not '
        'opened yet', () async {
      // Every connection of this process loads the extension from here on.
      ensureVectorExtensionRegistered();
      final source = '${tmp.path}/plain.db';
      // A file as a process without the extension leaves it: the
      // extension's own table is not in it.
      sqlite3.sqlite3.open(source)
        ..execute('CREATE TABLE notes (body TEXT)')
        ..execute("INSERT INTO notes VALUES ('kept')")
        ..execute('DROP TABLE IF EXISTS "$vectorExtensionTable"')
        ..close();
      final copy = '${tmp.path}/plain-copy.db';

      await snapshotDatabaseFile(source: source, destination: copy);

      final raw = sqlite3.sqlite3.open(copy);
      addTearDown(raw.close);
      expect(raw.select('SELECT body FROM notes').single['body'], 'kept');
    });

    test('snapshotDatabaseFile does not create a missing source', () async {
      final source = '${tmp.path}/absent.db';

      await expectLater(
        snapshotDatabaseFile(
          source: source,
          destination: '${tmp.path}/absent-copy.db',
        ),
        throwsA(anything),
      );
      expect(File(source).existsSync(), isFalse);
    });
  });
}
