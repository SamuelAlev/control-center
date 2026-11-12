import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart'
    show DatabaseConnectionUser, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/schema_fixture.dart';
import 'helpers/test_database.dart';
import 'helpers/windows_safe_delete.dart';

/// A workspace's code index lives in `code_index.db` beside `workspace.db`:
/// derived data in a file of its own, replaced rather than repaired, and
/// opened and closed together with the workspace's database.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_code_index');
    sqlite3.sqlite3.tempDirectory = tmp.path;
  });
  tearDown(() => deleteDirBestEffort(tmp));

  Future<List<Object?>> column(DatabaseConnectionUser db, String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data.values.first,
  ];

  /// A 384-d vector on axis 0, tilted toward axis 1 by [tilt].
  Float32List vec(double tilt) => Float32List(384)
    ..[0] = 1
    ..[1] = tilt;

  CodeSymbolsTableCompanion symbol(
    String id, {
    String repoId = 'repo1',
    String? checkoutId,
  }) => CodeSymbolsTableCompanion.insert(
    id: id,
    repoId: repoId,
    checkoutId: Value(checkoutId),
    kind: 'method',
    name: id,
    qualifiedName: 'Heron.$id',
    filePath: 'lib/$id.dart',
    language: 'dart',
    startLine: 1,
    endLine: 2,
  );

  /// The vector of a symbol tilted by [tilt] from the query `vec(0)`.
  Uint8List vector(double tilt) => vec(tilt).buffer.asUint8List();

  group('the workspace file', () {
    test('a fresh one holds no code index object', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      expect(
        await column(
          db,
          "SELECT name FROM sqlite_master WHERE name GLOB 'code_*' "
          "OR tbl_name GLOB 'code_*'",
        ),
        isEmpty,
      );
    });

    test('a v29 file loses its code tables when it converges', () async {
      final file = File('${tmp.path}/workspace.db');
      SchemaFixture.load('workspace_v29_a').writeTo(
        file.path,
        seed: (raw) => raw
          ..execute(
            'INSERT INTO workspace_meta (id, workspace_id, install_id, '
            "created_with_schema_version) VALUES (0, 'ws', 'install-1', 1)",
          )
          ..execute(
            'INSERT INTO code_symbols (id, workspace_id, repo_id, kind, name, '
            'qualified_name, file_path, language, start_line, end_line) '
            "VALUES ('s1', 'ws', 'r1', 'method', 'fly', 'Heron.fly', "
            "'lib/heron.dart', 'dart', 1, 2)",
          ),
      );
      final db = WorkspaceDatabase(NativeDatabase(file), workspaceId: 'ws');
      addTearDown(db.close);

      expect(await db.schemaDifferences(), isEmpty);
      expect(
        await column(
          db,
          "SELECT name FROM sqlite_master WHERE name GLOB 'code_*' "
          "OR tbl_name GLOB 'code_*'",
        ),
        isEmpty,
      );
      expect(
        db.lastConvergeReport!.droppedTables,
        containsAll([
          'code_symbols',
          'code_edges',
          'code_files',
          'code_index_checkpoints',
        ]),
      );
    });
  });

  group('a code index file', () {
    test('opened by the server connection has the declared schema and '
        'searches on every connection', () async {
      final db = CodeIndexDatabase(
        openCodeIndexDatabase(dataDir: tmp.path, workspaceId: 'w-1'),
        workspaceId: 'w-1',
      );
      addTearDown(db.close);
      await db.codeGraphDao.upsertSymbols([
        symbol('fly'),
        symbol('wade'),
        symbol('perch', repoId: 'repo2'),
      ]);
      await db.codeGraphDao.putEmbeddings({
        'fly': vector(0.5),
        'wade': vector(0),
        'perch': vector(0),
      });

      expect(File(codeIndexDatabasePath(tmp.path, 'w-1')).existsSync(), isTrue);
      expect(await db.schemaDifferences(), isEmpty);
      expect(await column(db, 'PRAGMA application_id'), [
        CodeIndexDatabase.fileApplicationId,
      ]);
      expect(await column(db, 'PRAGMA user_version'), [
        CodeIndexDatabase.currentSchemaVersion,
      ]);
      expect(await column(db, 'PRAGMA synchronous'), [0]);

      // Several at once, so reads land on the pooled reader as well as on
      // the writer: each needs its own vector context.
      final fts = await Future.wait([
        for (var i = 0; i < 6; i++) db.codeGraphDao.searchFts('repo1', 'fly'),
      ]);
      for (final hits in fts) {
        expect(hits.map((s) => s.id), ['fly']);
      }
      final knn = await Future.wait([
        for (var i = 0; i < 6; i++)
          db.codeGraphDao.searchVector('repo1', vec(0), limit: 2),
      ]);
      for (final hits in knn) {
        expect(hits.map((s) => s.id), ['wade', 'fly']);
      }
    });
  });

  group('the manager', () {
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;
    final warnings = <String>[];

    WorkspaceDatabaseManager manager() => WorkspaceDatabaseManager(
      dataDir: tmp.path,
      global: global,
      onWarn: (tag, message) => warnings.add('$tag: $message'),
    );

    setUp(() {
      warnings.clear();
      global = createTestGlobalDatabase();
      dbs = manager();
    });
    tearDown(() async {
      await dbs.closeAll();
      await global.close();
    });

    /// Writes a symbol to `w-1`'s code index and a repo to its database, then
    /// closes both, as a process exiting would.
    Future<void> populate() async {
      await dbs.codeIndexOf('w-1').codeGraphDao.upsertSymbols([symbol('fly')]);
      await dbs
          .of('w-1')
          .repoDao
          .upsertRepo(
            ReposTableCompanion.insert(id: 'repo1', name: 'r', path: '/r'),
          );
      await dbs.close('w-1');
    }

    /// A new process: nothing remembers having checked either file.
    Future<void> restart() async {
      await dbs.closeAll();
      dbs = manager();
    }

    Future<void> expectReplacedAndWorkspaceWritable() async {
      final index = dbs.codeIndexOf('w-1');
      expect(await index.codeGraphDao.searchFts('repo1', 'fly'), isEmpty);
      expect(await index.schemaDifferences(), isEmpty);
      // The new file takes writes and serves them.
      await index.codeGraphDao.upsertSymbols([symbol('fly')]);
      expect(
        (await index.codeGraphDao.searchFts('repo1', 'fly')).map((s) => s.id),
        ['fly'],
      );
      expect(
        warnings.where((w) => w.contains('code index of workspace w-1')),
        hasLength(1),
      );

      // The workspace's own file is untouched and writable.
      final db = dbs.of('w-1');
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: 'repo2', name: 's', path: '/s'),
      );
      expect((await db.repoDao.getAll()).map((r) => r.id), {'repo1', 'repo2'});
      expect(dbs.integrityFailure('w-1'), isNull);
    }

    test('replaces a damaged code index with an empty one', () async {
      await populate();
      final path = dbs.codeIndexPathFor('w-1');
      final raw = sqlite3.sqlite3.open(path);
      final page =
          raw
                  .select(
                    'SELECT rootpage FROM sqlite_master '
                    "WHERE type = 'table' AND name = 'code_symbols'",
                  )
                  .single['rootpage']!
              as int;
      final pageSize =
          raw.select('PRAGMA page_size').single.values.single! as int;
      raw
        ..execute('PRAGMA wal_checkpoint(TRUNCATE)')
        ..close();
      final file = File(path).openSync(mode: FileMode.append);
      try {
        file
          ..setPositionSync((page - 1) * pageSize)
          ..writeFromSync(List<int>.filled(pageSize, 0xff));
      } finally {
        file.closeSync();
      }
      await restart();

      await expectReplacedAndWorkspaceWritable();
    });

    test('replaces a code index written by a newer build', () async {
      await populate();
      sqlite3.sqlite3.open(dbs.codeIndexPathFor('w-1'))
        ..execute('PRAGMA user_version = 99')
        ..close();
      await restart();

      await expectReplacedAndWorkspaceWritable();
    });

    test('replaces a file that is not a code index', () async {
      await populate();
      sqlite3.sqlite3.open(dbs.codeIndexPathFor('w-1'))
        ..execute('PRAGMA application_id = 7')
        ..close();
      await restart();

      await expectReplacedAndWorkspaceWritable();
    });

    test('replaces a file that is not a database at all', () async {
      await populate();
      for (final suffix in ['-wal', '-shm']) {
        final sidecar = File('${dbs.codeIndexPathFor('w-1')}$suffix');
        if (sidecar.existsSync()) {
          sidecar.deleteSync();
        }
      }
      File(
        dbs.codeIndexPathFor('w-1'),
      ).writeAsBytesSync(List<int>.filled(8192, 0x42));
      await restart();

      await expectReplacedAndWorkspaceWritable();
    });

    test('dropAndClose removes both files', () async {
      await dbs.codeIndexOf('w-1').customSelect('SELECT 1').get();
      await dbs.create('w-1');
      expect(File(dbs.codeIndexPathFor('w-1')).existsSync(), isTrue);

      await dbs.dropAndClose('w-1');

      expect(dbs.openCodeIndexIds, isEmpty);
      expect(dbs.openIds, isEmpty);
      expect(File(dbs.codeIndexPathFor('w-1')).existsSync(), isFalse);
      expect(File(dbs.pathFor('w-1')).existsSync(), isFalse);
    });

    test('opening one file does not open the other', () async {
      await dbs.codeIndexOf('w-1').customSelect('SELECT 1').get();
      expect(dbs.openIds, isEmpty);
      expect(File(dbs.pathFor('w-1')).existsSync(), isFalse);

      await dbs.create('w-2');
      expect(dbs.openCodeIndexIds, ['w-1']);
      expect(File(dbs.codeIndexPathFor('w-2')).existsSync(), isFalse);
    });

    test('refuses a deleted workspace', () {
      dbs.markDeleted('w-1');
      expect(
        () => dbs.codeIndexOf('w-1'),
        throwsA(isA<DeletedWorkspaceException>()),
      );
      expect(() => dbs.codeIndexOf('../x'), throwsArgumentError);
    });
  });

  group('the pair lease', () {
    late _Clock clock;
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;

    setUp(() {
      clock = _Clock();
      global = createTestGlobalDatabase();
      dbs = WorkspaceDatabaseManager(
        dataDir: tmp.path,
        global: global,
        executorFactory: (_) => NativeDatabase.memory(),
        idleAfter: const Duration(seconds: 45),
        clock: () => clock.now,
      );
    });
    tearDown(() async {
      await dbs.closeAll();
      await global.close();
    });

    Future<void> touchBoth() async {
      await dbs.of('ws').customSelect('SELECT 1').get();
      await dbs.codeIndexOf('ws').customSelect('SELECT 1').get();
    }

    test('idle closing closes both files', () async {
      await touchBoth();
      clock.advance(const Duration(seconds: 46));
      await dbs.evictIdle();

      expect(dbs.openIds, isEmpty);
      expect(dbs.openCodeIndexIds, isEmpty);
    });

    test('activity on the code index alone keeps the pair open', () async {
      await touchBoth();
      clock.advance(const Duration(seconds: 40));
      await dbs.codeIndexOf('ws').customSelect('SELECT 1').get();
      clock.advance(const Duration(seconds: 10));
      await dbs.evictIdle();

      expect(dbs.openIds, ['ws']);
      expect(dbs.openCodeIndexIds, ['ws']);

      clock.advance(const Duration(seconds: 46));
      await dbs.evictIdle();
      expect(dbs.openIds, isEmpty);
      expect(dbs.openCodeIndexIds, isEmpty);
    });

    test('a live watch on the code index keeps the pair open', () async {
      await touchBoth();
      final index = dbs.codeIndexOf('ws');
      final subscription = index.codeGraphDao
          .watchSymbolsByRepo('repo1')
          .listen((_) {});
      await index.codeGraphDao.watchSymbolsByRepo('repo1').first;
      clock.advance(const Duration(hours: 1));
      await dbs.evictIdle();
      expect(dbs.openIds, ['ws']);
      expect(dbs.openCodeIndexIds, ['ws']);

      await subscription.cancel();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      clock.advance(const Duration(hours: 1));
      await dbs.evictIdle();
      expect(dbs.openCodeIndexIds, isEmpty);
    });

    test('codeIndexOf during eviction reclaims the same pair', () async {
      await touchBoth();
      final db = dbs.of('ws');
      final index = dbs.codeIndexOf('ws');
      clock.advance(const Duration(seconds: 46));

      final evicting = dbs.evictIdle();
      expect(identical(dbs.codeIndexOf('ws'), index), isTrue);
      await evicting;

      expect(identical(dbs.of('ws'), db), isTrue);
      expect(await index.customSelect('SELECT 1').get(), isNotEmpty);
      expect(await db.customSelect('SELECT 1').get(), isNotEmpty);
    });

    test('a fan-out closes the database it opened and leaves the code '
        'index in use', () async {
      final index = dbs.codeIndexOf('ws');
      await index.codeGraphDao.upsertSymbols([symbol('fly')]);

      await dbs.useTransiently('ws', (db) => db.repoDao.getAll());

      expect(dbs.openIds, isEmpty);
      expect(identical(dbs.codeIndexOf('ws'), index), isTrue);
      expect(await index.codeGraphDao.getSymbolsByRepo('repo1'), hasLength(1));
    });
  });

  group('removing a repo or a worktree', () {
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;

    setUp(() async {
      global = createTestGlobalDatabase();
      dbs = createTestWorkspaceDatabases(global: global);
      final db = dbs.of('ws');
      for (final id in ['repo1', 'repo2']) {
        await db.repoDao.upsertRepo(
          ReposTableCompanion.insert(id: id, name: id, path: '/$id'),
        );
      }
      await db.isolatedRepoDao.upsert(
        IsolatedReposTableCompanion.insert(
          id: 'wt1',
          workspaceId: 'ws',
          spaceId: 's1',
          repoId: 'repo1',
          path: '/wt1',
          branch: 'pr-1',
          sourcePath: '/repo1',
        ),
      );
      final dao = dbs.codeIndexOf('ws').codeGraphDao;
      for (final (repo, checkout) in [
        ('repo1', null),
        ('repo1', 'wt1'),
        ('repo2', null),
      ]) {
        final tag = '$repo-${checkout ?? 'linked'}';
        await dao.upsertSymbols([
          symbol('s-$tag', repoId: repo, checkoutId: checkout),
        ]);
        await dao.putEmbeddings({'s-$tag': vector(0)});
        await dao.upsertEdges([
          CodeEdgesTableCompanion.insert(
            id: 'e-$tag',
            repoId: repo,
            checkoutId: Value(checkout),
            sourceSymbolId: 's-$tag',
            kind: 'calls',
            targetName: const Value('elsewhere'),
          ),
        ]);
        await dao.upsertFile(
          CodeFilesTableCompanion.insert(
            id: 'f-$tag',
            repoId: repo,
            checkoutId: Value(checkout),
            path: 'lib/a.dart',
            contentHash: 'h',
          ),
        );
        await dao.upsertCheckpoint(
          CodeIndexCheckpointsTableCompanion.insert(
            id: 'c-$tag',
            repoId: repo,
            checkoutId: Value(checkout),
            headSha: 'head',
            worktreeDigest: 'digest',
            indexerFingerprint: 'fp',
          ),
        );
      }
    });
    tearDown(() async {
      await dbs.closeAll();
      await global.close();
    });

    Future<Map<String, List<Object?>>> index() async {
      final db = dbs.codeIndexOf('ws');
      return {
        for (final table in const [
          'code_symbols',
          'code_edges',
          'code_files',
          'code_index_checkpoints',
        ])
          table: await column(db, 'SELECT id FROM $table ORDER BY id'),
        'code_symbol_embeddings': await column(
          db,
          'SELECT symbol_id FROM code_symbol_embeddings ORDER BY symbol_id',
        ),
      };
    }

    Map<String, List<String>> only(List<String> tags) => {
      'code_symbols': [for (final t in tags) 's-$t'],
      'code_symbol_embeddings': [for (final t in tags) 's-$t'],
      'code_edges': [for (final t in tags) 'e-$t'],
      'code_files': [for (final t in tags) 'f-$t'],
      'code_index_checkpoints': [for (final t in tags) 'c-$t'],
    };

    test('deleting a repo deletes its whole index', () async {
      await DaoRepoRepository(dbs).delete('ws', 'repo1');

      expect(await index(), only(['repo2-linked']));
      expect(await dbs.of('ws').repoDao.exists('repo1'), isFalse);
    });

    test(
      'unlinking a repo from the workspace deletes its whole index',
      () async {
        await DaoWorkspaceRepository(
          global.workspaceRegistryDao,
          dbs,
        ).unlinkRepoFromWorkspace('ws', 'repo1');

        expect(await index(), only(['repo2-linked']));
      },
    );

    test(
      'deleting a worktree deletes its partition and nothing else',
      () async {
        await DaoIsolatedRepoRepository(dbs).deleteById('ws', 'wt1');

        expect(await index(), only(['repo1-linked', 'repo2-linked']));
        expect(
          await dbs.of('ws').isolatedRepoDao.findById('ws', 'wt1'),
          isNull,
        );
      },
    );
  });
}

class _Clock {
  DateTime now = DateTime.utc(2026, 1, 1);

  void advance(Duration by) {
    now = now.add(by);
  }
}
