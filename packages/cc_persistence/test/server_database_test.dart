import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

class _Schema extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

void main() {
  test(
    'openGlobalDatabase opens a pure-Dart sqlite connection and round-trips',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_persistence_test');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final exec = openGlobalDatabase(dataDir: tmp.path);
      await exec.ensureOpen(_Schema());
      await exec.runCustom(
        'CREATE TABLE t (id TEXT PRIMARY KEY, v TEXT NOT NULL);',
        const [],
      );
      await exec.runInsert('INSERT INTO t (id, v) VALUES (?, ?);', ['a', 'b']);
      final rows = await exec.runSelect('SELECT v FROM t;', const []);
      expect(rows.single['v'], 'b');
      await exec.close();

      // The file was created under the supplied data dir (no path_provider), at
      // the well-known global filename, so a desktop-spawned local server opens
      // the same global database the desktop created.
      expect(File(globalDatabasePath(tmp.path)).existsSync(), isTrue);
      expect(
        globalDatabasePath(tmp.path),
        '${tmp.path}${Platform.pathSeparator}$globalDatabaseFileName',
      );
    },
  );

  test('openGlobalDatabase creates the data dir if missing', () async {
    final base = Directory.systemTemp.createTempSync('cc_persistence_mkdir');
    addTearDown(() => base.deleteSync(recursive: true));
    final nested = '${base.path}${Platform.pathSeparator}nested';

    final exec = openGlobalDatabase(dataDir: nested);
    await exec.ensureOpen(_Schema());
    await exec.close();

    expect(Directory(nested).existsSync(), isTrue);
  });

  test(
    'openWorkspaceDatabase puts one file per workspace under workspaces/',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_persistence_ws');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final exec = openWorkspaceDatabase(dataDir: tmp.path, workspaceId: 'w-1');
      await exec.ensureOpen(_Schema());
      await exec.runCustom(
        'CREATE TABLE t (id TEXT PRIMARY KEY, v TEXT NOT NULL);',
        const [],
      );
      await exec.runInsert('INSERT INTO t (id, v) VALUES (?, ?);', ['a', 'b']);
      expect(
        (await exec.runSelect('SELECT v FROM t;', const [])).single['v'],
        'b',
      );
      await exec.close();

      // The workspace got its OWN directory, created on demand, holding a
      // `workspace.db` — that per-directory split IS the isolation boundary, and
      // giving each workspace a folder means anything else it owns on disk can sit
      // beside its database and be removed with it.
      expect(Directory(workspaceDirPath(tmp.path, 'w-1')).existsSync(), isTrue);
      expect(
        workspaceDirPath(tmp.path, 'w-1'),
        '${tmp.path}${Platform.pathSeparator}w-1',
      );
      expect(File(workspaceDatabasePath(tmp.path, 'w-1')).existsSync(), isTrue);
      expect(
        workspaceDatabasePath(tmp.path, 'w-1'),
        '${tmp.path}${Platform.pathSeparator}w-1'
        '${Platform.pathSeparator}$workspaceDatabaseFileName',
      );
    },
  );

  test('two workspaces get two independent files', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_persistence_ws2');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final a = openWorkspaceDatabase(dataDir: tmp.path, workspaceId: 'w-1');
    await a.ensureOpen(_Schema());
    await a.runCustom('CREATE TABLE t (id TEXT PRIMARY KEY);', const []);
    await a.runInsert('INSERT INTO t (id) VALUES (?);', ['only-in-w1']);
    await a.close();

    final b = openWorkspaceDatabase(dataDir: tmp.path, workspaceId: 'w-2');
    await b.ensureOpen(_Schema());
    await b.runCustom('CREATE TABLE t (id TEXT PRIMARY KEY);', const []);
    // w-1's row is simply not in w-2's file — no WHERE clause involved.
    expect(await b.runSelect('SELECT id FROM t;', const []), isEmpty);
    await b.close();

    expect(File(workspaceDatabasePath(tmp.path, 'w-1')).existsSync(), isTrue);
    expect(File(workspaceDatabasePath(tmp.path, 'w-2')).existsSync(), isTrue);
  });
}
