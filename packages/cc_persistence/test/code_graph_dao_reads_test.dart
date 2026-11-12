import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Complements `code_graph_dao_test.dart` — covers the read / incremental-re-index
/// paths the FTS/traversal test does not exercise (by-name, by-files, unresolved
/// edges, embeddings, file index, deleteByRepo, getSymbolsWithoutEmbedding,
/// getResolvedEdgesBySourceFiles, getCallees/getCallers with custom kinds + limit).
void main() {
  late CodeIndexDatabase db;

  setUp(() async {
    db = createTestCodeIndexDatabase();

    // Two files: a.dart holds foo (calls bar); b.dart holds bar.
    await db.codeGraphDao.upsertSymbols([
      CodeSymbolsTableCompanion.insert(
        id: 's_foo',
        repoId: 'repo1',
        kind: 'method',
        name: 'foo',
        qualifiedName: 'A.foo',
        filePath: 'a.dart',
        language: 'dart',
        startLine: 1,
        endLine: 2,
      ),
      CodeSymbolsTableCompanion.insert(
        id: 's_bar',
        repoId: 'repo1',
        kind: 'method',
        name: 'bar',
        qualifiedName: 'A.bar',
        filePath: 'b.dart',
        language: 'dart',
        startLine: 3,
        endLine: 4,
      ),
    ]);
    await db.codeGraphDao.upsertFile(
      CodeFilesTableCompanion.insert(
        id: 'file-a',
        repoId: 'repo1',
        path: 'a.dart',
        contentHash: 'hash-a',
        symbolCount: const Value(1),
      ),
    );
    await db.codeGraphDao.upsertEdges([
      CodeEdgesTableCompanion.insert(
        id: 'e1',
        repoId: 'repo1',
        sourceSymbolId: 's_foo',
        kind: CodeEdgeKind.calls.name,
        targetSymbolId: const Value('s_bar'),
        sourceFilePath: const Value('a.dart'),
      ),
      // An unresolved edge — targetSymbolId null, targetName set.
      CodeEdgesTableCompanion.insert(
        id: 'e2',
        repoId: 'repo1',
        sourceSymbolId: 's_foo',
        kind: CodeEdgeKind.references.name,
        targetName: const Value('external.Thing'),
        sourceFilePath: const Value('a.dart'),
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  group('CodeGraphDao reads', () {
    test('getSymbolsByName is repo scoped', () async {
      final rows = await db.codeGraphDao.getSymbolsByName('repo1', 'foo');
      expect(rows, hasLength(1));
      expect(rows.first.id, 's_foo');

      // Other repo: empty.
      expect(await db.codeGraphDao.getSymbolsByName('other', 'foo'), isEmpty);
    });

    test('watchSymbolsByRepo is repo-scoped, ordered by path', () async {
      final rows = await db.codeGraphDao.watchSymbolsByRepo('repo1').first;
      expect(rows.map((r) => r.filePath).toList(), ['a.dart', 'b.dart']);
    });

    test('getSymbolsByRepo returns all symbols in scope', () async {
      expect((await db.codeGraphDao.getSymbolsByRepo('repo1')).length, 2);
    });

    test('getSymbolsByFiles returns symbols in the listed paths', () async {
      final rows = await db.codeGraphDao.getSymbolsByFiles('repo1', ['b.dart']);
      expect(rows.map((r) => r.id).toList(), ['s_bar']);
      // Empty file list short-circuits to an empty result.
      expect(
        await db.codeGraphDao.getSymbolsByFiles('repo1', const []),
        isEmpty,
      );
    });

    test('getResolvedEdgesBySourceFiles returns only resolved edges', () async {
      final edges = await db.codeGraphDao.getResolvedEdgesBySourceFiles(
        'repo1',
        ['a.dart'],
      );
      expect(edges, hasLength(1));
      expect(edges.first.id, 'e1');
      expect(edges.first.targetSymbolId, 's_bar');
      // Empty list short-circuits.
      expect(
        await db.codeGraphDao.getResolvedEdgesBySourceFiles('repo1', const []),
        isEmpty,
      );
    });

    test(
      'getUnresolvedEdges returns edges with a null target symbol',
      () async {
        final edges = await db.codeGraphDao.getUnresolvedEdges('repo1');
        expect(edges, hasLength(1));
        expect(edges.first.id, 'e2');
        expect(edges.first.targetSymbolId, isNull);
        expect(edges.first.targetName, 'external.Thing');
      },
    );

    test('setEdgeTarget binds a previously-unresolved edge', () async {
      await db.codeGraphDao.setEdgeTarget('e2', 's_bar');
      final stillUnresolved = await db.codeGraphDao.getUnresolvedEdges('repo1');
      expect(stillUnresolved, isEmpty);
    });

    test(
      'getSymbolsWithoutEmbedding returns the symbols with no vector row',
      () async {
        // Neither symbol has a vector yet.
        expect(
          await db.codeGraphDao.getSymbolsWithoutEmbedding(),
          hasLength(2),
        );

        await db.codeGraphDao.putEmbeddings({'s_foo': Uint8List(384 * 4)});
        final rows = await db.codeGraphDao.getSymbolsWithoutEmbedding();
        expect(rows.map((s) => s.id), ['s_bar']);
      },
    );

    test('getCallees/getCallers honour kind + limit filters', () async {
      // default kind = {calls}
      final callees = await db.codeGraphDao.getCallees('s_foo');
      expect(callees.map((s) => s.id).toList(), ['s_bar']);

      // references kind yields nothing for foo (the references edge is unresolved).
      final refCallees = await db.codeGraphDao.getCallees(
        's_foo',
        kinds: const {CodeEdgeKind.references},
      );
      expect(refCallees, isEmpty);

      // limit cap
      final limited = await db.codeGraphDao.getCallees('s_foo', limit: 0);
      expect(limited, isEmpty);

      final callers = await db.codeGraphDao.getCallers('s_bar');
      expect(callers.map((s) => s.id).toList(), ['s_foo']);
    });
  });

  group('CodeGraphDao file index', () {
    test('getFile reads a single file entry', () async {
      final f = await db.codeGraphDao.getFile('repo1', 'a.dart');
      expect(f?.id, 'file-a');
      // foreign repo / path misses
      expect(await db.codeGraphDao.getFile('other', 'a.dart'), isNull);
      expect(await db.codeGraphDao.getFile('repo1', 'missing'), isNull);
    });

    test('getFiles returns all entries for a repo', () async {
      expect((await db.codeGraphDao.getFiles('repo1')).length, 1);
    });

    test('upsertFile updates an existing entry in place', () async {
      await db.codeGraphDao.upsertFile(
        CodeFilesTableCompanion.insert(
          id: 'file-a',
          repoId: 'repo1',
          path: 'a.dart',
          contentHash: 'hash-a-2',
          symbolCount: const Value(5),
        ),
      );
      final f = await db.codeGraphDao.getFile('repo1', 'a.dart');
      expect(f?.contentHash, 'hash-a-2');
      expect(f?.symbolCount, 5);
    });
  });

  group('CodeGraphDao incremental re-index', () {
    test('deleteByFile removes a single file\'s symbols + edges', () async {
      await db.codeGraphDao.deleteByFile('repo1', 'a.dart');
      // foo is gone; bar (in b.dart) survives.
      expect(await db.codeGraphDao.getSymbolById('s_foo'), isNull);
      expect(await db.codeGraphDao.getSymbolById('s_bar'), isNotNull);
      // edges whose source lives in a.dart are gone.
      expect(await db.codeGraphDao.getUnresolvedEdges('repo1'), isEmpty);
      // the file index entry is gone too.
      expect(await db.codeGraphDao.getFile('repo1', 'a.dart'), isNull);
    });

    test('deleteByRepo clears the whole repo index', () async {
      await db.codeGraphDao.deleteByRepo('repo1');
      expect(await db.codeGraphDao.getSymbolsByRepo('repo1'), isEmpty);
      expect(await db.codeGraphDao.getFiles('repo1'), isEmpty);
      expect(await db.codeGraphDao.getUnresolvedEdges('repo1'), isEmpty);
    });
  });
}
