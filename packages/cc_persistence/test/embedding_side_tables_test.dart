import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/windows_safe_delete.dart';

/// Records the SQL of every read, so a test can say which tables and
/// columns a DAO method touched.
class _CaptureReads extends QueryInterceptor {
  final List<String> reads = [];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    reads.add(statement);
    return executor.runSelect(statement, args);
  }
}

/// A 384-d vector on axis 0, tilted toward axis 1 by [tilt]; its distance
/// from the query `vec(0)` grows with [tilt].
Float32List vec(double tilt) => Float32List(384)
  ..[0] = 1
  ..[1] = tilt;

Uint8List bytes(double tilt) => vec(tilt).buffer.asUint8List();

MemoryFactsTableCompanion fact(
  String id, {
  String content = 'deployment runbook',
  String? supersededBy,
}) => MemoryFactsTableCompanion.insert(
  id: id,
  workspaceId: 'ws',
  domain: 'ops',
  topic: 'deploy',
  content: '$content $id',
  supersededBy: Value(supersededBy),
);

CodeSymbolsTableCompanion symbol(
  String id, {
  String repoId = 'repo1',
  String? checkoutId,
  String filePath = 'lib/a.dart',
  String? docstring,
}) => CodeSymbolsTableCompanion.insert(
  id: id,
  repoId: repoId,
  checkoutId: Value(checkoutId),
  kind: 'method',
  name: id,
  qualifiedName: 'Heron.$id',
  filePath: filePath,
  language: 'dart',
  startLine: 1,
  endLine: 2,
  docstring: Value(docstring),
);

/// EXPLAIN QUERY PLAN details of [sql] run with [args].
Future<List<String>> plan(
  GeneratedDatabase db,
  String sql,
  List<Object> args,
) async => [
  for (final row
      in await db
          .customSelect(
            'EXPLAIN QUERY PLAN $sql',
            variables: [for (final a in args) Variable(a)],
          )
          .get())
    row.read<String>('detail'),
];

/// Counts the rows of [table] inserted or updated after this call, with
/// temporary triggers on the (single) connection of an in-memory database.
Future<Future<int> Function()> countWrites(
  GeneratedDatabase db,
  String table,
) async {
  await db.customStatement(
    'CREATE TEMP TABLE IF NOT EXISTS row_writes (tbl TEXT)',
  );
  for (final kind in ['INSERT', 'UPDATE']) {
    await db.customStatement(
      'CREATE TEMP TRIGGER IF NOT EXISTS count_${table}_$kind '
      "AFTER $kind ON $table BEGIN INSERT INTO row_writes VALUES ('$table'); "
      'END',
    );
  }
  return () async =>
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM row_writes WHERE tbl = ?',
                variables: [Variable.withString(table)],
              )
              .getSingle())
          .read<int>('n');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('on files opened by the server connection', () {
    late Directory tmp;
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('cc_vectors');
      sqlite3.sqlite3.tempDirectory = tmp.path;
      global = GlobalDatabase.atDataDir(tmp.path);
      dbs = WorkspaceDatabaseManager(dataDir: tmp.path, global: global);
      await DaoWorkspaceRepository(global.workspaceRegistryDao, dbs).upsert(
        Workspace(
          id: 'ws',
          name: 'ws',
          createdAt: DateTime(2026, 5, 18),
          updatedAt: DateTime(2026, 5, 18),
        ),
      );
    });

    tearDown(() async {
      await dbs.closeAll();
      await global.close();
      await deleteDirBestEffort(tmp);
    });

    /// A second data dir holding a snapshot copy of [source] under the
    /// workspace's own file name, so the server connection opens it.
    Future<String> copyDir() async {
      final dir = '${tmp.path}${Platform.pathSeparator}copy';
      Directory(workspaceDirPath(dir, 'ws')).createSync(recursive: true);
      return dir;
    }

    group('memory facts', () {
      Future<void> seed(WorkspaceDatabase db) async {
        final dao = db.memoryFactDao;
        for (final (id, tilt) in [
          ('f-far', 0.9),
          ('f-near', 0.1),
          ('f-mid', 0.5),
        ]) {
          await dao.upsert(
            fact(id, content: id == 'f-far' ? 'kingfisher' : 'runbook'),
          );
          await dao.putEmbedding(id, bytes(tilt));
        }
        // Nearest of all, but superseded: never returned.
        await dao.upsert(fact('f-old', supersededBy: 'f-near'));
        await dao.putEmbedding('f-old', bytes(0));
        // No vector: absent from the vector voice, present through FTS.
        await dao.upsert(fact('f-bare', content: 'kingfisher'));
      }

      Future<void> expectSearches(WorkspaceDatabase db) async {
        final dao = db.memoryFactDao;
        expect((await dao.searchVector('ws', vec(0))).map((f) => f.id), [
          'f-near',
          'f-mid',
          'f-far',
        ]);
        // FTS ranks f-far and f-bare; the vector voice ranks f-far third.
        final hybrid = await dao.searchHybrid('ws', 'kingfisher', vec(0));
        expect(hybrid.first.id, 'f-far');
        expect(hybrid.map((f) => f.id).toSet(), {
          'f-far',
          'f-bare',
          'f-near',
          'f-mid',
        });
      }

      test('vector and hybrid search find the same facts after a reopen, a '
          'VACUUM and a snapshot copy', () async {
        await seed(dbs.of('ws'));
        await expectSearches(dbs.of('ws'));

        await dbs.close('ws');
        await expectSearches(dbs.of('ws'));

        await dbs.of('ws').customStatement('VACUUM');
        await expectSearches(dbs.of('ws'));

        final copy = await copyDir();
        await dbs.snapshotTo('ws', workspaceDatabasePath(copy, 'ws'));
        final snapshot = WorkspaceDatabase(
          openWorkspaceDatabase(dataDir: copy, workspaceId: 'ws'),
          workspaceId: 'ws',
        );
        addTearDown(snapshot.close);
        await expectSearches(snapshot);
      });
    });

    group('code symbols', () {
      Future<void> seed(CodeIndexDatabase db) async {
        final dao = db.codeGraphDao;
        await dao.upsertSymbols([
          symbol('far', docstring: 'kingfisher'),
          symbol('near'),
          symbol('mid'),
          symbol('bare', docstring: 'kingfisher'),
          // Nearest of all, but another repo's.
          symbol('other', repoId: 'repo2'),
        ]);
        await dao.putEmbeddings({
          'far': bytes(0.9),
          'near': bytes(0.1),
          'mid': bytes(0.5),
          'other': bytes(0),
        });
      }

      Future<void> expectSearches(CodeIndexDatabase db) async {
        final dao = db.codeGraphDao;
        expect((await dao.searchVector('repo1', vec(0))).map((s) => s.id), [
          'near',
          'mid',
          'far',
        ]);
        final hybrid = await dao.searchHybrid('repo1', 'kingfisher', vec(0));
        expect(hybrid.first.id, 'far');
        expect(hybrid.map((s) => s.id).toSet(), {'far', 'bare', 'near', 'mid'});
      }

      test('vector and hybrid search find the same symbols after a reopen, a '
          'VACUUM and a snapshot copy', () async {
        await seed(dbs.codeIndexOf('ws'));
        await expectSearches(dbs.codeIndexOf('ws'));

        await dbs.close('ws');
        await expectSearches(dbs.codeIndexOf('ws'));

        await dbs.codeIndexOf('ws').customStatement('VACUUM');
        await expectSearches(dbs.codeIndexOf('ws'));

        final copy = await copyDir();
        await dbs.codeIndexOf('ws').customSelect('SELECT 1').get();
        await snapshotDatabaseFile(
          source: codeIndexDatabasePath(tmp.path, 'ws'),
          destination: codeIndexDatabasePath(copy, 'ws'),
        );
        final snapshot = CodeIndexDatabase(
          openCodeIndexDatabase(dataDir: copy, workspaceId: 'ws'),
          workspaceId: 'ws',
        );
        addTearDown(snapshot.close);
        await expectSearches(snapshot);
      });
    });
  });

  group('memory fact vectors', () {
    late _CaptureReads capture;
    late WorkspaceDatabase db;

    setUp(() {
      capture = _CaptureReads();
      db = WorkspaceDatabase.forTesting(
        NativeDatabase.memory().interceptWith(capture),
        workspaceId: 'ws',
      );
    });

    tearDown(() => db.close());

    Future<List<String>> vectorIds() async => [
      for (final row
          in await db
              .customSelect(
                'SELECT fact_id FROM memory_fact_embeddings ORDER BY fact_id',
              )
              .get())
        row.read<String>('fact_id'),
    ];

    test('"not embedded yet" is "no side row", found through the side '
        "table's primary key", () async {
      final dao = db.memoryFactDao;
      await dao.upsert(fact('f-1'));
      await dao.upsert(fact('f-2'));
      await dao.upsert(fact('f-3', supersededBy: 'f-1'));
      await dao.putEmbedding('f-2', bytes(0));

      final pending = await dao.getActiveWithoutEmbedding('ws');
      expect(pending.map((f) => f.id), ['f-1']);

      final details = await plan(db, MemoryFactDao.withoutEmbeddingSql, [
        'ws',
        10,
      ]);
      expect(
        details,
        contains(
          matches(
            'SEARCH e USING (COVERING )?INDEX '
            r'sqlite_autoindex_memory_fact_embeddings_1 \(fact_id=\?\)',
          ),
        ),
      );
      expect(details.where((d) => d.contains('SCAN e')), isEmpty);
    });

    test('writing a vector leaves the fact row and its full-text index '
        'alone', () async {
      final dao = db.memoryFactDao;
      await dao.upsert(fact('f-1'));
      await dao.upsert(fact('f-2'));
      final before = await dao.getById('ws', 'f-1');
      final factWrites = await countWrites(db, 'memory_facts');

      await dao.putEmbedding('f-1', bytes(0.1));
      await dao.putEmbedding('f-1', bytes(0.2));
      final f2 = (await dao.getById('ws', 'f-2'))!;
      expect(
        await dao.putBackfilledEmbeddings([
          (
            factId: 'f-2',
            topic: f2.topic,
            content: f2.content,
            embedding: bytes(0.3),
          ),
        ]),
        1,
      );

      // `memory_facts_au` fires on an UPDATE of the fact row; none ran.
      expect(await factWrites(), 0);
      expect(await dao.getById('ws', 'f-1'), before);
      expect(await vectorIds(), ['f-1', 'f-2']);
    });

    test('a backfilled vector is stored only for a fact that still has the '
        'text it was computed from and no vector yet', () async {
      final dao = db.memoryFactDao;
      await dao.upsert(fact('kept'));
      await dao.upsert(fact('changed'));
      await dao.upsert(fact('embedded'));
      await dao.putEmbedding('embedded', bytes(0.7));

      final stored = await dao.putBackfilledEmbeddings([
        (
          factId: 'kept',
          topic: 'deploy',
          content: 'deployment runbook kept',
          embedding: bytes(0.1),
        ),
        (
          factId: 'changed',
          topic: 'deploy',
          content: 'what it said before',
          embedding: bytes(0.1),
        ),
        (
          factId: 'gone',
          topic: 'deploy',
          content: 'deployment runbook gone',
          embedding: bytes(0.1),
        ),
        (
          factId: 'embedded',
          topic: 'deploy',
          content: 'deployment runbook embedded',
          embedding: bytes(0.1),
        ),
      ]);

      expect(stored, 1);
      expect(await vectorIds(), ['embedded', 'kept']);
      final embedded = await db
          .customSelect(
            'SELECT embedding FROM memory_fact_embeddings '
            "WHERE fact_id = 'embedded'",
          )
          .getSingle();
      expect(embedded.read<Uint8List>('embedding'), bytes(0.7));
    });

    test('a vector is dropped when its text changes and kept when it does '
        'not', () async {
      final dao = db.memoryFactDao;
      await dao.upsert(fact('f-1'));
      await dao.putEmbedding('f-1', bytes(0.1));

      await dao.dropEmbeddingUnlessText(
        'f-1',
        topic: 'deploy',
        content: 'deployment runbook f-1',
      );
      expect(await vectorIds(), ['f-1']);

      await dao.dropEmbeddingUnlessText(
        'f-1',
        topic: 'deploy',
        content: 'something else',
      );
      expect(await vectorIds(), isEmpty);
    });

    test('deleting a fact deletes its vector', () async {
      final dao = db.memoryFactDao;
      await dao.upsert(fact('f-1'));
      await dao.upsert(fact('f-2'));
      await dao.putEmbedding('f-1', bytes(0.1));
      await dao.putEmbedding('f-2', bytes(0.2));

      await dao.deleteById('ws', 'f-1');

      expect(await vectorIds(), ['f-2']);
    });

    test('fact reads read no vector', () async {
      final dao = db.memoryFactDao;
      await dao.upsert(fact('f-1'));
      await dao.putEmbedding('f-1', bytes(0.1));
      capture.reads.clear();

      await dao.getByWorkspace('ws');
      await dao.watchByWorkspace('ws').first;
      await dao.watchActiveByWorkspace('ws').first;
      await dao.getById('ws', 'f-1');
      await dao.getActiveByTopic('ws', 'deploy');
      await dao.getActiveByWorkspace('ws');
      await dao.getActiveByIds('ws', ['f-1']);
      await dao.getByAuthor('ws', 'agent-1');
      await dao.recentActive('ws');
      await dao.searchFts('ws', 'runbook');

      expect(capture.reads, isNotEmpty);
      expect(capture.reads.where((sql) => sql.contains('embedding')), isEmpty);
    });
  });

  group('code symbol vectors', () {
    late _CaptureReads capture;
    late CodeIndexDatabase db;

    setUp(() {
      capture = _CaptureReads();
      db = CodeIndexDatabase.forTesting(
        NativeDatabase.memory().interceptWith(capture),
        workspaceId: 'ws',
      );
    });

    tearDown(() => db.close());

    Future<List<String>> vectorIds() async => [
      for (final row
          in await db
              .customSelect(
                'SELECT symbol_id FROM code_symbol_embeddings ORDER BY symbol_id',
              )
              .get())
        row.read<String>('symbol_id'),
    ];

    Future<void> seedEmbedded(List<CodeSymbolsTableCompanion> rows) async {
      await db.codeGraphDao.upsertSymbols(rows);
      await db.codeGraphDao.putEmbeddings({
        for (final row in rows) row.id.value: bytes(0.1),
      });
    }

    test('"not embedded yet" is "no side row", found through the side '
        "table's primary key", () async {
      await db.codeGraphDao.upsertSymbols([
        symbol('a'),
        symbol('b', repoId: 'repo2', checkoutId: 'wt'),
        symbol('c'),
      ]);
      await db.codeGraphDao.putEmbeddings({'c': bytes(0.1)});

      final pending = await db.codeGraphDao.getSymbolsWithoutEmbedding();
      expect(pending.map((s) => s.id).toSet(), {'a', 'b'});

      final details = await plan(db, CodeGraphDao.withoutEmbeddingSql, [10]);
      expect(
        details,
        contains(
          matches(
            'SEARCH e USING (COVERING )?INDEX '
            r'sqlite_autoindex_code_symbol_embeddings_1 \(symbol_id=\?\)',
          ),
        ),
      );
      expect(details.where((d) => d.contains('SCAN e')), isEmpty);
    });

    test('writing a vector leaves the symbol row and its full-text index '
        'alone', () async {
      await db.codeGraphDao.upsertSymbols([symbol('a'), symbol('b')]);
      final before = await db.codeGraphDao.getSymbolById('a');
      final symbolWrites = await countWrites(db, 'code_symbols');

      await db.codeGraphDao.putEmbeddings({'a': bytes(0.1)});
      final b = (await db.codeGraphDao.getSymbolById('b'))!;
      expect(
        await db.codeGraphDao.putBackfilledEmbeddings([
          (symbol: b, embedding: bytes(0.2)),
        ]),
        1,
      );

      // `code_symbols_au` fires on an UPDATE of the symbol row; none ran.
      expect(await symbolWrites(), 0);
      expect(await db.codeGraphDao.getSymbolById('a'), before);
      expect(await vectorIds(), ['a', 'b']);
    });

    test('a backfilled vector is stored only for a symbol that still has '
        'the text it was computed from and no vector yet', () async {
      await db.codeGraphDao.upsertSymbols([
        symbol('kept'),
        symbol('changed'),
        symbol('gone'),
        symbol('embedded'),
      ]);
      final read = {
        for (final s in await db.codeGraphDao.getSymbolsWithoutEmbedding())
          s.id: s,
      };
      await db.codeGraphDao.putEmbeddings({'embedded': bytes(0.7)});
      await db.codeGraphDao.upsertSymbols([
        symbol('changed', docstring: 'now documented'),
      ]);
      await db.codeGraphDao.deleteSymbolsByIds(['gone']);

      final stored = await db.codeGraphDao.putBackfilledEmbeddings([
        for (final id in ['kept', 'changed', 'gone', 'embedded'])
          (symbol: read[id]!, embedding: bytes(0.1)),
      ]);

      expect(stored, 1);
      expect(await vectorIds(), ['embedded', 'kept']);
    });

    test('every delete of symbols deletes their vectors', () async {
      final dao = db.codeGraphDao;
      await seedEmbedded([
        symbol('file', filePath: 'lib/file.dart'),
        symbol('batch', filePath: 'lib/batch.dart'),
        symbol('byId', filePath: 'lib/by_id.dart'),
        symbol('wt', checkoutId: 'wt-1'),
        symbol('repo2', repoId: 'repo2'),
        symbol('kept', filePath: 'lib/kept.dart'),
      ]);

      await dao.deleteByFile('repo1', 'lib/file.dart');
      expect(await vectorIds(), isNot(contains('file')));

      await dao.deleteFilesBatch('repo1', ['lib/batch.dart']);
      expect(await vectorIds(), isNot(contains('batch')));

      await dao.deleteSymbolsByIds(['byId']);
      expect(await vectorIds(), isNot(contains('byId')));

      await dao.deleteByCheckout('repo1', 'wt-1');
      expect(await vectorIds(), isNot(contains('wt')));

      await dao.deleteByRepo('repo2');
      expect(await vectorIds(), ['kept']);
    });

    test('deleteEmbeddings drops the vectors and keeps the symbols', () async {
      await seedEmbedded([symbol('a'), symbol('b')]);

      await db.codeGraphDao.deleteEmbeddings(['a']);

      expect(await vectorIds(), ['b']);
      expect(await db.codeGraphDao.getSymbolById('a'), isNotNull);
    });

    test('symbol reads read no vector', () async {
      final dao = db.codeGraphDao;
      await seedEmbedded([symbol('a'), symbol('b')]);
      await dao.upsertEdges([
        CodeEdgesTableCompanion.insert(
          id: 'e1',
          repoId: 'repo1',
          sourceSymbolId: 'a',
          sourceFilePath: const Value('lib/a.dart'),
          targetSymbolId: const Value('b'),
          kind: 'calls',
        ),
      ]);
      capture.reads.clear();

      await dao.getSymbolById('a');
      await dao.getSymbolsByName('repo1', 'a');
      await dao.watchSymbolsByRepo('repo1').first;
      await dao.getSymbolsByRepo('repo1');
      await dao.getSymbolsByFiles('repo1', ['lib/a.dart']);
      await dao.getSymbolNameIndex('repo1', {'a'});
      await dao.searchFts('repo1', 'a');
      await dao.getCallees('a');
      await dao.getCallers('b');
      await dao.getImpactRadius('a');

      expect(capture.reads, isNotEmpty);
      expect(capture.reads.where((sql) => sql.contains('embedding')), isEmpty);
    });
  });
}
