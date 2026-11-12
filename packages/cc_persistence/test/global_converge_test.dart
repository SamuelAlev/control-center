import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/src/vector_extension.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/schema_fixture.dart';

/// What happens to a global file that an earlier build wrote: it is
/// converged to the declared schema, like a workspace file (see
/// `workspace_converge_test.dart`).
void main() {
  late Directory tmp;
  late File file;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = Directory.systemTemp.createTempSync('cc_global_converge');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    file = File(globalDatabasePath(tmp.path));
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  GlobalDatabase open() {
    final db = GlobalDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    return db;
  }

  Future<int> pragma(GlobalDatabase db, String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).read<int>(name);

  void seed(sqlite3.Database db) {
    db
      ..execute("INSERT INTO server_meta VALUES ('install_id', 'install-1')")
      ..execute(
        'INSERT INTO workspaces (id, name, connect_mode) '
        "VALUES ('ws-1', 'Alpha', 'inherit')",
      )
      ..execute(
        'INSERT INTO users (id, handle, display_name, email_verified) '
        "VALUES ('u-1', 'sam', 'Sam', 1)",
      )
      ..execute(
        'INSERT INTO workspace_routes (kind, key_hash, workspace_id) '
        "VALUES ('invite_code', 'hash-1', 'ws-1')",
      )
      ..execute(
        'INSERT INTO invite_secure_routes (route_id, code_hash, workspace_id) '
        "VALUES ('route-1', 'hash-1', 'ws-1')",
      );
  }

  test('a v12 file converges to the schema of a fresh one and keeps its '
      'rows', () async {
    SchemaFixture.load('global_v12').writeTo(
      file.path,
      seed: (db) {
        seed(db);
        db.execute('CREATE TABLE IF NOT EXISTS _sqliteai_vector (key TEXT)');
      },
    );

    final db = open();

    expect(await db.schemaDifferences(), isEmpty);
    expect(
      await pragma(db, 'user_version'),
      GlobalDatabase.currentSchemaVersion,
    );
    expect(
      await pragma(db, 'application_id'),
      GlobalDatabase.fileApplicationId,
    );
    // Nothing here is vector-indexed, so the table the vector extension
    // left in older files goes too. Read from the report: once the
    // extension is loaded in a process it puts the table back on every
    // connection it opens, this one included.
    expect(db.lastConvergeReport!.droppedTables, contains('_sqliteai_vector'));
    final user = await db.userDao.getById('u-1');
    expect(user!.handle, 'sam');
    expect(user.emailVerified, isTrue);
    expect(await db.workspaceRegistryDao.getById('ws-1'), isNotNull);
    expect(
      await db.workspaceRouteDao.resolveSecureInvite('route-1'),
      isNotNull,
    );
    expect(
      (await db
              .customSelect(
                "SELECT value FROM server_meta WHERE key = 'install_id'",
              )
              .getSingle())
          .read<String>('value'),
      'install-1',
    );
  });

  test('a fresh file is at the current version, carries the global '
      'application id and matches the declared schema', () async {
    final db = open();

    expect(await db.schemaDifferences(), isEmpty);
    expect(
      await pragma(db, 'user_version'),
      GlobalDatabase.currentSchemaVersion,
    );
    expect(
      await pragma(db, 'application_id'),
      GlobalDatabase.fileApplicationId,
    );
    expect(db.lastConvergeReport, isNull);
  });

  test('two accounts that hold one sign-in identity: the newer one '
      'stays', () async {
    final fixture = SchemaFixture.load('global_v12');
    fixture.writeTo(
      file.path,
      seed: (db) {
        // The file of an install that lost its partial unique index.
        db
          ..execute('DROP INDEX idx_users_sso_subject')
          ..execute(
            'INSERT INTO users (id, handle, display_name, sso_issuer, '
            "sso_subject) VALUES ('u-old', 'old', 'Old', 'idp', 'subject-1'), "
            "('u-new', 'new', 'New', 'idp', 'subject-1'), "
            "('u-local', 'local', 'Local', NULL, NULL), "
            "('u-local-2', 'local2', 'Local 2', NULL, NULL)",
          );
      },
    );

    final db = open();

    expect(
      (await db.customSelect('SELECT id FROM users ORDER BY id').get()).map(
        (row) => row.read<String>('id'),
      ),
      ['u-local', 'u-local-2', 'u-new'],
    );
    expect(db.lastConvergeReport!.droppedRows, {'users': 1});
  });

  group('refusals', () {
    test('a file a newer build wrote is refused and left as it is', () async {
      final current = open();
      await current.customSelect('SELECT 1').get();
      await current.close();
      const newer = GlobalDatabase.currentSchemaVersion + 1;
      sqlite3.sqlite3.open(file.path)
        ..execute('PRAGMA user_version = $newer')
        ..close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<DatabaseNewerThanBinaryException>().having(
            (e) => e.database,
            'database',
            'global',
          ),
        ),
      );
      await db.close();
      final raw = sqlite3.sqlite3.open(file.path);
      addTearDown(raw.close);
      expect(raw.select('PRAGMA user_version').single.values.single, newer);
    });

    test('a workspace database put where the global one belongs is '
        'refused', () async {
      final workspace = WorkspaceDatabase.forTesting(NativeDatabase(file));
      await workspace.customSelect('SELECT 1').get();
      await workspace.close();

      final db = open();

      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(isA<ForeignDatabaseFileException>()),
      );
    });
  });

  group('through the server connection', () {
    test('a new file reclaims freed pages incrementally and journals in '
        'WAL', () async {
      final db = GlobalDatabase.atDataDir(tmp.path);
      addTearDown(db.close);

      expect(await pragma(db, 'auto_vacuum'), 2);
      expect(
        (await db.customSelect('PRAGMA journal_mode').getSingle()).data.values,
        ['wal'],
      );
    });

    test('an upgraded file is copied aside first, then switched to '
        'incremental reclaim', () async {
      SchemaFixture.load('global_v12').writeTo(file.path, seed: seed);

      final db = GlobalDatabase.atDataDir(tmp.path);
      addTearDown(db.close);

      expect(await pragma(db, 'auto_vacuum'), 2);
      final copy = Directory(
        globalUpgradeSnapshotDir(tmp.path),
      ).listSync().whereType<File>().single;
      expect(copy.uri.pathSegments.last, startsWith('v12.'));
      expect((await db.userDao.getById('u-1'))!.handle, 'sam');
    });

    test('snapshotDatabaseFile copies the file once the vector extension '
        'is loaded in the process', () async {
      final db = GlobalDatabase.atDataDir(tmp.path);
      addTearDown(db.close);
      await db.userDao.upsert(
        UsersTableCompanion.insert(id: 'u-1', handle: 'sam', displayName: 'S'),
      );
      // From here on every new connection in the process carries the
      // extension, the read-only one the copy uses included.
      ensureVectorExtensionRegistered();
      final copy = '${tmp.path}/copy.db';

      await snapshotDatabaseFile(source: file.path, destination: copy);

      final raw = sqlite3.sqlite3.open(copy);
      addTearDown(raw.close);
      expect(raw.select('SELECT handle FROM users').single['handle'], 'sam');
    });
  });
}
