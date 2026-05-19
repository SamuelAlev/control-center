import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  CodeSymbolsTableCompanion symbol(
    String id,
    String name,
    String qualifiedName,
  ) => CodeSymbolsTableCompanion.insert(
    id: id,
    workspaceId: 'ws1',
    repoId: 'repo1',
    kind: 'method',
    name: name,
    qualifiedName: qualifiedName,
    filePath: 'a.dart',
    language: 'dart',
    startLine: 1,
    endLine: 2,
  );

  setUp(() async {
    db = createTestDatabase();
    await db.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: 'ws1', name: 'w'),
    );
    await db.repoDao.upsertRepo(
      ReposTableCompanion.insert(id: 'repo1', name: 'r', path: '/tmp/r'),
    );
    await db.codeGraphDao.upsertSymbols([
      symbol('s_foo', 'foo', 'A.foo'),
      symbol('s_bar', 'bar', 'A.bar'),
    ]);
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
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  group('CodeGraphDao', () {
    test('FTS search finds a symbol by name', () async {
      final hits = await db.codeGraphDao.searchFts('ws1', 'repo1', 'foo');
      expect(hits.map((s) => s.id), contains('s_foo'));
    });

    test('FTS search is scoped to the workspace', () async {
      final hits = await db.codeGraphDao.searchFts('other_ws', 'repo1', 'foo');
      expect(hits, isEmpty);
    });

    test('getCallees returns outgoing call targets', () async {
      final callees = await db.codeGraphDao.getCallees('ws1', 's_foo');
      expect(callees.map((s) => s.id), ['s_bar']);
    });

    test('getCallers returns incoming callers', () async {
      final callers = await db.codeGraphDao.getCallers('ws1', 's_bar');
      expect(callers.map((s) => s.id), ['s_foo']);
    });

    test('graph traversal is scoped to the workspace', () async {
      expect(await db.codeGraphDao.getCallees('other_ws', 's_foo'), isEmpty);
      expect(await db.codeGraphDao.getCallers('other_ws', 's_bar'), isEmpty);
    });

    test('getImpactRadius walks reverse dependencies with depth', () async {
      final impact = await db.codeGraphDao.getImpactRadius('ws1', 's_bar');
      expect(impact.depthById['s_bar'], 0);
      expect(impact.depthById['s_foo'], 1);
      expect(impact.nodes.length, 2);
    });

    test('deleteByFile removes a file\'s symbols and edges', () async {
      await db.codeGraphDao.deleteByFile('ws1', 'repo1', 'a.dart');
      final remaining = await db.codeGraphDao.getSymbolsByRepo('ws1', 'repo1');
      expect(remaining, isEmpty);
      final callees = await db.codeGraphDao.getCallees('ws1', 's_foo');
      expect(callees, isEmpty);
    });
  });

  group('CodeGraphDao workspace isolation', () {
    // A second workspace sharing the same repo, with a symbol whose name and
    // qualified name collide with ws1's 'foo'. The FTS index must not leak it
    // across the workspace boundary.
    setUp(() async {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws2', name: 'w2'),
      );
      await db.codeGraphDao.upsertSymbols([
        CodeSymbolsTableCompanion.insert(
          id: 's_foo_ws2',
          workspaceId: 'ws2',
          repoId: 'repo1',
          kind: 'method',
          name: 'foo',
          qualifiedName: 'A.foo',
          filePath: 'a.dart',
          language: 'dart',
          startLine: 1,
          endLine: 2,
        ),
      ]);
    });

    test('FTS search never returns a colliding symbol from another workspace',
        () async {
      final ws1Hits = await db.codeGraphDao.searchFts('ws1', 'repo1', 'foo');
      expect(ws1Hits.map((s) => s.id), contains('s_foo'));
      expect(ws1Hits.map((s) => s.id), isNot(contains('s_foo_ws2')));

      final ws2Hits = await db.codeGraphDao.searchFts('ws2', 'repo1', 'foo');
      expect(ws2Hits.map((s) => s.id), ['s_foo_ws2']);
    });

    test('getSymbolById is scoped to the workspace', () async {
      expect(await db.codeGraphDao.getSymbolById('ws1', 's_foo'), isNotNull);
      // ws2 owns a different repo checkout and must not resolve ws1's symbol id.
      expect(await db.codeGraphDao.getSymbolById('ws2', 's_foo'), isNull);
    });

    test('setEdgeTarget cannot rebind another workspace\'s edge', () async {
      // ws2 tries to repoint ws1's edge 'e1' — the workspace-scoped WHERE makes
      // it a no-op, so ws1's call graph is unchanged.
      await db.codeGraphDao.setEdgeTarget('ws2', 'e1', 's_foo_ws2');
      final callees = await db.codeGraphDao.getCallees('ws1', 's_foo');
      expect(callees.map((s) => s.id), ['s_bar']);
    });
  });
}
