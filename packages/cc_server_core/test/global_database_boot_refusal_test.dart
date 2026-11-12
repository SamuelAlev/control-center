import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/server_boot_refusal.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';

/// A `global.db` the server cannot serve stops the boot with a refusal the
/// operator can act on, instead of failing the first request that reaches
/// it.
void main() {
  late Directory tmp;
  late String path;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('cc_global_refusal');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    path = globalDatabasePath(tmp.path);
    final fresh = GlobalDatabase.atDataDir(tmp.path);
    await fresh.workspaceRouteDao.setMeta('probe', 'x');
    await fresh.close();
  });

  tearDown(() => deleteDirBestEffort(tmp));

  Future<Object?> boot() async {
    final db = GlobalDatabase.atDataDir(tmp.path);
    try {
      await openGlobalDatabaseOrRefuse(db, path);
      return null;
    } on Object catch (e) {
      return e;
    } finally {
      try {
        await db.close();
      } on Object {
        // A refused file may not have opened.
      }
    }
  }

  void rewrite(void Function(sqlite3.Database raw) change) {
    final raw = sqlite3.sqlite3.open(path);
    try {
      change(raw);
      raw.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } finally {
      raw.close();
    }
  }

  test('a healthy file boots', () async {
    expect(await boot(), isNull);
  });

  test('a damaged file is refused as damaged', () async {
    late int page;
    late int pageSize;
    rewrite((raw) {
      page =
          raw
                  .select(
                    'SELECT rootpage FROM sqlite_master '
                    "WHERE type = 'table' AND name = 'workspaces'",
                  )
                  .single['rootpage']!
              as int;
      pageSize = raw.select('PRAGMA page_size').single.values.single! as int;
    });
    final file = File(path).openSync(mode: FileMode.append);
    try {
      file
        ..setPositionSync((page - 1) * pageSize)
        ..writeFromSync(List<int>.filled(pageSize, 0xff));
    } finally {
      file.closeSync();
    }

    final refusal = await boot();

    expect(refusal, isA<GlobalDatabaseDamaged>());
    expect((refusal! as ServerBootRefusal).message, contains(path));
  });

  test('a file that is not a database at all is refused as damaged', () async {
    for (final suffix in ['', '-wal', '-shm']) {
      final f = File('$path$suffix');
      if (f.existsSync()) {
        f.deleteSync();
      }
    }
    File(path).writeAsBytesSync(List<int>.filled(8192, 0x42));

    expect(await boot(), isA<GlobalDatabaseDamaged>());
  });

  test('a file from a newer build is refused as newer', () async {
    rewrite((raw) => raw.execute('PRAGMA user_version = 9999'));

    final refusal = await boot();

    expect(refusal, isA<GlobalDatabaseNewer>());
    expect((refusal! as GlobalDatabaseNewer).fileVersion, 9999);
  });

  test('another application\'s file is refused as foreign', () async {
    rewrite((raw) => raw.execute('PRAGMA application_id = 12345'));

    final refusal = await boot();

    expect(refusal, isA<GlobalDatabaseForeign>());
    expect((refusal! as GlobalDatabaseForeign).applicationId, 12345);
  });
}
