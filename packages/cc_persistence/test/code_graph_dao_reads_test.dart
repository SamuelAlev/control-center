import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Complements `code_graph_dao_test.dart` — covers the read / incremental-re-index
/// paths the FTS/traversal test does not exercise (by-name, by-files, unresolved
/// edges, embeddings, file index, deleteByRepo, getSymbolsWithoutEmbedding,
/// getResolvedEdgesBySourceFiles, getCallees/getCallers with custom kinds + limit).
void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await db
        .into(db.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'repo1', name: 'r', path: '/tmp/r'),
        );

    // Two files: a.dart holds foo (calls bar); b.dart holds bar.
    await db.codeGraphDao.upsertSymbols([
      CodeSymbolsTableCompanion.insert(
        id: 's_foo',
        workspaceId: 'ws1',
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
        workspaceId: 'ws1',
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
        workspaceId: 'ws1',
        repoId: 'repo1',
        path: 'a.dart',
        contentHash: 'hash-a',
        symbolCount: const Value(1),
      ),
    );
    await db.codeGraphDao.upsertEdges([
      CodeEdgesTableCompanion.insert(
        id: 'e1',
        workspaceId: 'ws1',
        repoId: 'repo1',
        sourceSymbolId: 's_foo',
        kind: CodeEdgeKind.calls.name,
        targetSymbolId: const Value('s_bar'),
        sourceFilePath: const Value('a.dart'),
      ),
      // An unresolved edge — targetSymbolId null, targetName set.
      CodeEdgesTableCompanion.insert(
        id: 'e2',
        workspaceId: 'ws1',
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
    test('getSymbolsByName is workspace + repo scoped', () async {
      final rows = await db.codeGraphDao.getSymbolsByName(
        'ws1',
        'repo1',
        'foo',
      );
      expect(rows, hasLength(1));
      expect(rows.first.id, 's_foo');

      // Other workspace / repo: empty.
      expect(
        await db.codeGraphDao.getSymbolsByName('ws2', 'repo1', 'foo'),
        isEmpty,
      );
      expect(
        await db.codeGraphDao.getSymbolsByName('ws1', 'other', 'foo'),
        isEmpty,
      );
    });

    test('watchSymbolsByRepo is workspace-scoped, ordered by path', () async {
      final rows = await db.codeGraphDao
          .watchSymbolsByRepo('ws1', 'repo1')
          .first;
      expect(rows.map((r) => r.filePath).toList(), ['a.dart', 'b.dart']);
    });

    test('getSymbolsByRepo returns all symbols in scope', () async {
      expect(
        (await db.codeGraphDao.getSymbolsByRepo('ws1', 'repo1')).length,
        2,
      );
      expect(await db.codeGraphDao.getSymbolsByRepo('ws2', 'repo1'), isEmpty);
    });

    test('getSymbolsByFiles returns symbols in the listed paths', () async {
      final rows = await db.codeGraphDao.getSymbolsByFiles('ws1', 'repo1', [
        'b.dart',
      ]);
      expect(rows.map((r) => r.id).toList(), ['s_bar']);
      // Empty file list short-circuits to an empty result.
      expect(
        await db.codeGraphDao.getSymbolsByFiles('ws1', 'repo1', const []),
        isEmpty,
      );
    });

    test('getResolvedEdgesBySourceFiles returns only resolved edges', () async {
      final edges = await db.codeGraphDao.getResolvedEdgesBySourceFiles(
        'ws1',
        'repo1',
        ['a.dart'],
      );
      expect(edges, hasLength(1));
      expect(edges.first.id, 'e1');
      expect(edges.first.targetSymbolId, 's_bar');
      // Empty list short-circuits.
      expect(
        await db.codeGraphDao.getResolvedEdgesBySourceFiles(
          'ws1',
          'repo1',
          const [],
        ),
        isEmpty,
      );
    });

    test(
      'getUnresolvedEdges returns edges with a null target symbol',
      () async {
        final edges = await db.codeGraphDao.getUnresolvedEdges('ws1', 'repo1');
        expect(edges, hasLength(1));
        expect(edges.first.id, 'e2');
        expect(edges.first.targetSymbolId, isNull);
        expect(edges.first.targetName, 'external.Thing');
      },
    );

    test(
      'setEdgeTarget binds a previously-unresolved edge in-workspace',
      () async {
        await db.codeGraphDao.setEdgeTarget('ws1', 'e2', 's_bar');
        final stillUnresolved = await db.codeGraphDao.getUnresolvedEdges(
          'ws1',
          'repo1',
        );
        expect(stillUnresolved, isEmpty);
      },
    );

    test('setEdgeTarget cannot rebind another workspace\'s edge', () async {
      await db.codeGraphDao.setEdgeTarget('ws2', 'e1', 's_foo');
      final callees = await db.codeGraphDao.getCallees('ws1', 's_foo');
      expect(callees.map((s) => s.id).toList(), ['s_bar']);
    });

    test(
      'getSymbolsWithoutEmbedding returns symbols missing an embedding',
      () async {
        final rows = await db.codeGraphDao.getSymbolsWithoutEmbedding(
          'ws1',
          'repo1',
        );
        expect(rows.length, 2); // both symbols have a null embedding
        expect(
          await db.codeGraphDao.getSymbolsWithoutEmbedding('ws2', 'repo1'),
          isEmpty,
        );
      },
    );

    test('getCallees/getCallers honour kind + limit filters', () async {
      // default kind = {calls}
      final callees = await db.codeGraphDao.getCallees('ws1', 's_foo');
      expect(callees.map((s) => s.id).toList(), ['s_bar']);

      // references kind yields nothing for foo (the references edge is unresolved).
      final refCallees = await db.codeGraphDao.getCallees(
        'ws1',
        's_foo',
        kinds: const {CodeEdgeKind.references},
      );
      expect(refCallees, isEmpty);

      // limit cap
      final limited = await db.codeGraphDao.getCallees(
        'ws1',
        's_foo',
        limit: 0,
      );
      expect(limited, isEmpty);

      final callers = await db.codeGraphDao.getCallers('ws1', 's_bar');
      expect(callers.map((s) => s.id).toList(), ['s_foo']);
    });
  });

  group('CodeGraphDao file index', () {
    test('getFile reads a single file entry', () async {
      final f = await db.codeGraphDao.getFile('ws1', 'repo1', 'a.dart');
      expect(f?.id, 'file-a');
      // foreign workspace / repo / path misses
      expect(await db.codeGraphDao.getFile('ws2', 'repo1', 'a.dart'), isNull);
      expect(await db.codeGraphDao.getFile('ws1', 'other', 'a.dart'), isNull);
      expect(await db.codeGraphDao.getFile('ws1', 'repo1', 'missing'), isNull);
    });

    test('getFiles returns all entries for a repo in the workspace', () async {
      expect((await db.codeGraphDao.getFiles('ws1', 'repo1')).length, 1);
      expect(await db.codeGraphDao.getFiles('ws2', 'repo1'), isEmpty);
    });

    test('upsertFile updates an existing entry in place', () async {
      await db.codeGraphDao.upsertFile(
        CodeFilesTableCompanion.insert(
          id: 'file-a',
          workspaceId: 'ws1',
          repoId: 'repo1',
          path: 'a.dart',
          contentHash: 'hash-a-2',
          symbolCount: const Value(5),
        ),
      );
      final f = await db.codeGraphDao.getFile('ws1', 'repo1', 'a.dart');
      expect(f?.contentHash, 'hash-a-2');
      expect(f?.symbolCount, 5);
    });
  });

  group('CodeGraphDao incremental re-index', () {
    test('deleteByFile removes a single file\'s symbols + edges', () async {
      await db.codeGraphDao.deleteByFile('ws1', 'repo1', 'a.dart');
      // foo is gone; bar (in b.dart) survives.
      expect(await db.codeGraphDao.getSymbolById('ws1', 's_foo'), isNull);
      expect(await db.codeGraphDao.getSymbolById('ws1', 's_bar'), isNotNull);
      // edges whose source lives in a.dart are gone.
      expect(await db.codeGraphDao.getUnresolvedEdges('ws1', 'repo1'), isEmpty);
      // the file index entry is gone too.
      expect(await db.codeGraphDao.getFile('ws1', 'repo1', 'a.dart'), isNull);
    });

    test(
      'deleteByFile is workspace-scoped — foreign workspace is a no-op',
      () async {
        await db.codeGraphDao.deleteByFile('ws2', 'repo1', 'a.dart');
        expect(await db.codeGraphDao.getSymbolById('ws1', 's_foo'), isNotNull);
      },
    );

    test('deleteByRepo clears the whole repo index in one workspace', () async {
      await db.codeGraphDao.deleteByRepo('ws1', 'repo1');
      expect(await db.codeGraphDao.getSymbolsByRepo('ws1', 'repo1'), isEmpty);
      expect(await db.codeGraphDao.getFiles('ws1', 'repo1'), isEmpty);
      expect(await db.codeGraphDao.getUnresolvedEdges('ws1', 'repo1'), isEmpty);
    });
  });
}
