import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

/// The v1→v2 step that adds the install-wide settings store to `global.db`.
///
/// **This is the first global migration the app has ever run.** `_migrationSteps`
/// was `const <MigrationStep>[]` until this change, so the whole `onUpgrade`
/// path is unexercised code — worth driving against a real populated database
/// rather than trusting that it works by symmetry with the workspace half.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
    dir = Directory.systemTemp.createTempSync('cc-global-settings-migration');
    file = File('${dir.path}/global.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Builds a database in the superseded v1 shape: the current schema with the
  /// settings table dropped and `user_version` wound back.
  Future<void> writeV1Database() async {
    final current = GlobalDatabase(NativeDatabase(file));
    // Genuine global data the migration must leave alone.
    await current
        .into(current.workspacesTable)
        .insert(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'Existing'),
        );
    await current.close();

    final raw = sqlite3.sqlite3.open(file.path);
    raw
      ..execute('DROP TABLE server_settings')
      ..execute('PRAGMA user_version = 1');
    raw.close();
  }

  test('adds server_settings and leaves existing data intact', () async {
    await writeV1Database();

    final migrated = GlobalDatabase(NativeDatabase(file));
    addTearDown(migrated.close);

    // Opening runs the migration.
    await migrated.serverSettingDao.setValue('sandbox_enabled', 'true');
    expect(await migrated.serverSettingDao.getValue('sandbox_enabled'), 'true');

    final workspaces = await migrated.select(migrated.workspacesTable).get();
    expect(
      workspaces.map((w) => w.id),
      ['ws-1'],
      reason: 'the 1→2 step is additive; it must not touch the registry',
    );
  });

  test('a v1 database reports the new schema version after opening', () async {
    await writeV1Database();

    final migrated = GlobalDatabase(NativeDatabase(file));
    addTearDown(migrated.close);
    await migrated.serverSettingDao.getAll();

    final raw = sqlite3.sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(raw.select('PRAGMA user_version').single['user_version'], 2);
  });

  test('a fresh database carries server_settings from onCreate', () async {
    final fresh = GlobalDatabase(NativeDatabase(file));
    addTearDown(fresh.close);

    // A fresh install never runs the 1→2 step, so `onCreate` must build the
    // CURRENT shape rather than the v1 shape plus a migration.
    await fresh.serverSettingDao.setValue('k', 'v');
    expect(await fresh.serverSettingDao.getValue('k'), 'v');
  });
}
