import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

/// The v4→v5 step that adds the workspace-scoped settings store.
///
/// A fresh database gets the table from `onCreate` (covered by
/// `workspace_baseline_schema_test.dart`); this exercises the path a machine
/// that already has a v4 file takes, and asserts the migration is additive —
/// existing workspace data must survive untouched.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
    dir = Directory.systemTemp.createTempSync('cc-workspace-settings-migration');
    file = File('${dir.path}/workspace.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Builds a database in the superseded v4 shape: the current schema with the
  /// settings table dropped and `user_version` wound back — byte-for-byte what
  /// a machine on the previous release has.
  Future<void> writeV4Database() async {
    final current = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'w-1',
    );
    // A row of ordinary workspace data, so the migration can be shown not to
    // disturb anything it does not own.
    await current
        .into(current.channelsTable)
        .insert(
          ChannelsTableCompanion.insert(
            id: 'chan-1',
            name: 'Existing channel',
            workspaceId: const Value('w-1'),
          ),
        );
    await current.close();

    final raw = sqlite3.sqlite3.open(file.path);
    raw
      ..execute('DROP TABLE workspace_settings')
      ..execute('PRAGMA user_version = 4');
    raw.close();
  }

  test('adds workspace_settings and leaves existing data intact', () async {
    await writeV4Database();

    final migrated = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'w-1',
    );
    addTearDown(migrated.close);

    // Opening runs the migration.
    await migrated.workspaceSettingDao.setValue('w-1', 'branch_template', 'x');
    expect(
      await migrated.workspaceSettingDao.getValue('w-1', 'branch_template'),
      'x',
    );

    final channels = await migrated.select(migrated.channelsTable).get();
    expect(
      channels.map((c) => c.id),
      ['chan-1'],
      reason: 'the 4→5 step is additive; it must not touch existing rows',
    );
  });

  test('a v4 database reports the new schema version after opening', () async {
    await writeV4Database();

    final migrated = WorkspaceDatabase.forTesting(
      NativeDatabase(file),
      workspaceId: 'w-1',
    );
    addTearDown(migrated.close);
    await migrated.workspaceSettingDao.getForWorkspace('w-1');

    final raw = sqlite3.sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(raw.select('PRAGMA user_version').single['user_version'], 5);
  });
}
