import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/value_objects/code_edge_kind.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
    db = AppDatabase.forTesting(NativeDatabase.memory());
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
}
