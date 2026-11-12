import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show GeneratedDatabase, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/schema_fixture.dart';

/// Money is stored in one unit, integer micro-dollars, in every table.
void main() {
  late Directory tmp;
  late File file;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = Directory.systemTemp.createTempSync('cc_money_micros');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    file = File('${tmp.path}/workspace.db');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  WorkspaceDatabase open() {
    final db = WorkspaceDatabase(
      NativeDatabase(file),
      workspaceId: 'ws',
      onWarn: (_, _) {},
    );
    addTearDown(db.close);
    return db;
  }

  Future<List<String>> centsColumns(GeneratedDatabase db) async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    return [
      for (final t in tables)
        for (final c
            in await db
                .customSelect(
                  "SELECT name FROM pragma_table_info('${t.read<String>('name')}')",
                )
                .get())
          if (c.read<String>('name').contains('cents'))
            '${t.read<String>('name')}.${c.read<String>('name')}',
    ];
  }

  test('a fresh workspace file has no cents column', () async {
    SchemaFixture.load('workspace_v29_a').writeTo(file.path);
    final db = open();
    expect(await centsColumns(db), isEmpty);
  });

  test('the global file has no cents column', () async {
    SchemaFixture.load('global_v12').writeTo(file.path);
    final db = GlobalDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    expect(await centsColumns(db), isEmpty);
  });

  test('an existing goal survives the unit change with the default cap and '
      'its spend counter restarted', () async {
    SchemaFixture.load('workspace_v29_a').writeTo(
      file.path,
      seed: (raw) => raw
        ..execute(
          'INSERT INTO spaces (id, name, workspace_id) '
          "VALUES ('s1', 'General', 'ws')",
        )
        ..execute(
          'INSERT INTO conversations (id, workspace_id, space_id) '
          "VALUES ('c1', 'ws', 's1')",
        )
        ..execute(
          'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
          "skills, monthly_budget_cents) VALUES ('a1', 'Coder', 'Coder', "
          "'/a.md', 'ws', '[]', 2500)",
        )
        ..execute(
          'INSERT INTO agent_goal_runs (id, workspace_id, space_id, '
          'conversation_id, agent_id, user_text, kind, cost_cap_cents, '
          "cost_cents) VALUES ('g1', 'ws', 's1', 'c1', 'a1', 'ship it', "
          "'goal', 1000, 400)",
        ),
    );
    final db = open();

    final row = await db
        .customSelect(
          'SELECT cost_cap_micros, cost_micros FROM agent_goal_runs '
          "WHERE id = 'g1'",
        )
        .getSingle();
    expect(row.read<int>('cost_cap_micros'), 50000000);
    expect(row.read<int>('cost_micros'), 0);
    // The agent stays; the monthly budget a person set in cents is not
    // carried over and reads as unlimited until it is set again.
    final agent = await db
        .customSelect(
          "SELECT monthly_budget_micros FROM agents WHERE id = 'a1'",
        )
        .getSingle();
    expect(agent.read<int>('monthly_budget_micros'), 0);
    expect(await centsColumns(db), isEmpty);
  });
}
