import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/code_graph_dao.dart';
import 'package:control_center/core/domain/value_objects/code_edge_kind.dart';
import 'package:control_center/core/domain/value_objects/code_symbol_kind.dart';
import 'package:control_center/features/code_graph/data/repositories/dao_code_graph_repository.dart';
import 'package:control_center/features/code_graph/domain/entities/code_edge.dart';
import 'package:control_center/features/code_graph/domain/entities/code_symbol.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late CodeGraphDao dao;
  late DaoCodeGraphRepository repo;

  // Deterministic constants for the test workspace+repo.
  const wsId = 'ws-test';
  const repoId = 'repo-a';
  const filePath = 'src/main.dart';

  setUp(() async {
    db = createTestDatabase();
    dao = CodeGraphDao(db);
    repo = DaoCodeGraphRepository(dao);

    // Seed workspace + repo so foreign keys are satisfied.
    await db.into(db.workspacesTable).insert(
          const WorkspacesTableCompanion(
            id: Value(wsId),
            name: Value('Test Workspace'),
          ),
        );
    await db.into(db.reposTable).insert(
          const ReposTableCompanion(
            id: Value(repoId),
            name: Value('test/repo'),
            path: Value('/tmp/test-repo'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  CodeSymbol symbol({
    String name = 'myFunc',
    String qualifiedName = 'myFunc',
    CodeSymbolKind kind = CodeSymbolKind.function,
    int startLine = 10,
    int endLine = 20,
    String? parentName,
    String signature = '',
  }) {
    final id = codeSymbolId(wsId, repoId, filePath, qualifiedName);
    return CodeSymbol(
      id: id,
      workspaceId: wsId,
      repoId: repoId,
      kind: kind,
      name: name,
      qualifiedName: qualifiedName,
      filePath: filePath,
      language: 'dart',
      startLine: startLine,
      endLine: endLine,
      signature: signature,
      parentName: parentName,
    );
  }

  CodeEdge edge0({
    required String sourceSymbolId,
    required String targetName,
    CodeEdgeKind kind = CodeEdgeKind.calls,
  }) {
    final id = codeEdgeId(wsId, repoId, sourceSymbolId, targetName, kind.name);
    return CodeEdge(
      id: id,
      workspaceId: wsId,
      repoId: repoId,
      sourceSymbolId: sourceSymbolId,
      sourceFilePath: filePath,
      kind: kind,
      targetName: targetName,
    );
  }

  Future<void> ingest({
    List<CodeSymbol> symbols = const [],
    List<CodeEdge> edges = const [],
    String contentHash = 'abc123',
    String fp = filePath,
  }) =>
      repo.ingestFile(
        workspaceId: wsId,
        repoId: repoId,
        filePath: fp,
        contentHash: contentHash,
        symbols: symbols,
        edges: edges,
      );

  // --------------------------------------------------------------------------
  // ingestFile — CRUD for symbols, edges, and files
  // --------------------------------------------------------------------------

  group('ingestFile', () {
    test('persists symbols', () async {
      final s = symbol();
      await ingest(symbols: [s]);

      final got = await repo.getById(wsId, s.id);
      expect(got, isNotNull);
      expect(got!.id, s.id);
      expect(got.name, s.name);
      expect(got.kind, s.kind);
      expect(got.workspaceId, s.workspaceId);
      expect(got.repoId, s.repoId);
    });

    test('persists edges alongside symbols', () async {
      final s = symbol(name: 'main', qualifiedName: 'main');
      final e = edge0(sourceSymbolId: s.id, targetName: 'print');
      await ingest(symbols: [s], edges: [e]);

      // Edges are only retrievable via graph traversal.
      final callees = await repo.callees(wsId, s.id);
      expect(callees, isEmpty); // edge target is unresolved (no targetSymbolId)

      // But resolvePendingReferences should find it as unresolved.
      final resolved = await repo.resolvePendingReferences(wsId, repoId);
      expect(resolved, 0); // no matching target symbol
    });

    test('persists file entry', () async {
      await ingest(symbols: [symbol()], contentHash: 'hash-v1');

      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes[filePath], 'hash-v1');
    });

    test('re-ingest replaces prior symbols for the same file', () async {
      final s1 = symbol(name: 'old', qualifiedName: 'old');
      await ingest(symbols: [s1], contentHash: 'h1');

      final s2 = symbol(name: 'new', qualifiedName: 'new');
      await ingest(symbols: [s2], contentHash: 'h2');

      // old symbol should be gone
      final old = await repo.getById(wsId, s1.id);
      expect(old, isNull);
      // new symbol present
      final fresh = await repo.getById(wsId, s2.id);
      expect(fresh, isNotNull);
      expect(fresh!.name, 'new');
      // file hash updated
      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes[filePath], 'h2');
    });

    test('ingest with no symbols or edges does not throw', () async {
      await ingest(symbols: [], edges: [], contentHash: 'empty');
      // file entry still created
      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes[filePath], 'empty');
    });

    test('symbol with docstring is persisted', () async {
      final s = symbol(qualifiedName: 'withDoc').copyWith(
        docstring: 'Docs for this symbol.',
      );
      await ingest(symbols: [s]);

      final got = await repo.getById(wsId, s.id);
      expect(got!.docstring, 'Docs for this symbol.');
    });

    test('symbol with parentName is persisted', () async {
      final s = symbol(
        name: 'method',
        qualifiedName: 'MyClass.method',
        parentName: 'MyClass',
      );
      await ingest(symbols: [s]);

      final got = await repo.getById(wsId, s.id);
      expect(got!.parentName, 'MyClass');
    });
  });

  // --------------------------------------------------------------------------
  // getById
  // --------------------------------------------------------------------------

  group('getById', () {
    test('returns symbol when found', () async {
      final s = symbol();
      await ingest(symbols: [s]);

      final got = await repo.getById(wsId, s.id);
      expect(got, isNotNull);
      expect(got!.id, s.id);
    });

    test('returns null for unknown id', () async {
      final got = await repo.getById(wsId, 'nonexistent');
      expect(got, isNull);
    });

    test('returns null for wrong workspace', () async {
      final s = symbol();
      await ingest(symbols: [s]);
      // query with different workspace
      final got = await repo.getById('other-ws', s.id);
      expect(got, isNull);
    });
  });

  // --------------------------------------------------------------------------
  // getByName
  // --------------------------------------------------------------------------

  group('getByName', () {
    test('returns symbols matching exact name', () async {
      final s = symbol(name: 'myFunc', qualifiedName: 'myFunc');
      await ingest(symbols: [s]);

      final results = await repo.getByName(wsId, repoId, 'myFunc');
      expect(results.length, 1);
      expect(results.first.id, s.id);
    });

    test('returns empty for unmatched name', () async {
      await ingest(symbols: [symbol(name: 'myFunc', qualifiedName: 'myFunc')]);

      final results = await repo.getByName(wsId, repoId, 'otherName');
      expect(results, isEmpty);
    });

    test('respects limit parameter', () async {
      final symbols = List.generate(5, (i) {
        final qn = 'MyClass.method$i';
        return symbol(
          name: 'MyClass',
          qualifiedName: qn,
          kind: CodeSymbolKind.method,
          startLine: 10 + i,
          endLine: 20 + i,
        );
      });
      await ingest(symbols: symbols);

      final results = await repo.getByName(wsId, repoId, 'MyClass', limit: 3);
      expect(results.length, 3);
    });

    test('scoped to workspace+repo', () async {
      // Seed another workspace+repo.
      await db.into(db.workspacesTable).insert(
            const WorkspacesTableCompanion(
              id: Value('ws-2'),
              name: Value('WS 2'),
            ),
          );
      await db.into(db.reposTable).insert(
            const ReposTableCompanion(
              id: Value('repo-b'),
              name: Value('other/repo'),
              path: Value('/tmp/other'),
            ),
          );

      final sWs1 = symbol(name: 'target', qualifiedName: 'target');
      await ingest(symbols: [sWs1]);

      // Ingest same name in ws-2/repo-b with different file.
      final id2 = codeSymbolId('ws-2', 'repo-b', 'other.dart', 'target');
      await repo.ingestFile(
        workspaceId: 'ws-2',
        repoId: 'repo-b',
        filePath: 'other.dart',
        contentHash: 'xyz',
        symbols: [
          symbol(name: 'target', qualifiedName: 'target').copyWith(
            id: id2,
            workspaceId: 'ws-2',
            repoId: 'repo-b',
            filePath: 'other.dart',
          ),
        ],
        edges: [],
      );

      final ws1Results = await repo.getByName(wsId, repoId, 'target');
      expect(ws1Results.length, 1);
      expect(ws1Results.first.workspaceId, wsId);

      final ws2Results = await repo.getByName('ws-2', 'repo-b', 'target');
      expect(ws2Results.length, 1);
      expect(ws2Results.first.workspaceId, 'ws-2');
    });
  });

  // --------------------------------------------------------------------------
  // symbolsForRepo
  // --------------------------------------------------------------------------

  group('symbolsForRepo', () {
    test('returns all symbols for a repo', () async {
      final s1 = symbol(name: 'a', qualifiedName: 'a', startLine: 1, endLine: 3);
      final s2 = symbol(name: 'b', qualifiedName: 'b', startLine: 5, endLine: 7);
      await ingest(symbols: [s1, s2]);

      final results = await repo.symbolsForRepo(wsId, repoId);
      expect(results.length, 2);
    });

    test('returns empty when no symbols ingested', () async {
      final results = await repo.symbolsForRepo(wsId, repoId);
      expect(results, isEmpty);
    });
  });

  // --------------------------------------------------------------------------
  // search (FTS)
  // --------------------------------------------------------------------------

  group('search', () {
    test('finds symbols by name via FTS', () async {
      final s = symbol(name: 'initialize', qualifiedName: 'App.initialize');
      await ingest(symbols: [s]);

      final results = await repo.search(wsId, repoId, 'initialize');
      expect(results.length, 1);
      expect(results.first.id, s.id);
    });

    test('finds symbols by qualifiedName via FTS', () async {
      final s = symbol(name: 'init', qualifiedName: 'MyApp.initialize');
      await ingest(symbols: [s]);

      final results = await repo.search(wsId, repoId, 'initialize');
      expect(results.length, 1);
    });

    test('finds symbols by signature token via FTS', () async {
      final s = symbol(
        name: 'process',
        qualifiedName: 'Pipeline.process',
        signature: 'Future<void> process(PipelineInput input)',
      );
      await ingest(symbols: [s]);

      final results = await repo.search(wsId, repoId, 'PipelineInput');
      expect(results.length, 1);
    });

    test('returns empty when no match', () async {
      await ingest(symbols: [symbol(name: 'foo', qualifiedName: 'foo')]);

      final results = await repo.search(wsId, repoId, 'zzz_unknown_xyz');
      expect(results, isEmpty);
    });

    test('search is scoped to workspace+repo', () async {
      await ingest(symbols: [symbol(name: 'alpha', qualifiedName: 'alpha')]);

      // Same repo id, different workspace — should not match.
      final results = await repo.search('other-ws', repoId, 'alpha');
      expect(results, isEmpty);
    });
  });

  // --------------------------------------------------------------------------
  // callers / callees
  // --------------------------------------------------------------------------

  group('callers', () {
    test('returns callers of a symbol', () async {
      final caller = symbol(name: 'main', qualifiedName: 'main');
      final target = symbol(name: 'helper', qualifiedName: 'helper', startLine: 30, endLine: 35);
      // Edge where caller calls target, with target resolved.
      final edgeId = codeEdgeId(wsId, repoId, caller.id, target.id, CodeEdgeKind.calls.name);
      final edge = CodeEdge(
        id: edgeId,
        workspaceId: wsId,
        repoId: repoId,
        sourceSymbolId: caller.id,
        sourceFilePath: filePath,
        kind: CodeEdgeKind.calls,
        targetSymbolId: target.id,
      );
      await ingest(symbols: [caller, target], edges: [edge]);

      final callers = await repo.callers(wsId, target.id);
      expect(callers.length, 1);
      expect(callers.first.id, caller.id);
    });

    test('returns empty for symbol with no callers', () async {
      final s = symbol();
      await ingest(symbols: [s]);

      final callers = await repo.callers(wsId, s.id);
      expect(callers, isEmpty);
    });

    test('respects limit', () async {
      final target = symbol(name: 'target', qualifiedName: 'target');
      final edges = <CodeEdge>[];
      final symbols = <CodeSymbol>[target];
      for (var i = 0; i < 5; i++) {
        final caller = symbol(
          name: 'caller$i',
          qualifiedName: 'caller$i',
          startLine: 40 + i,
          endLine: 43 + i,
        );
        symbols.add(caller);
        final eId = codeEdgeId(wsId, repoId, caller.id, target.id, CodeEdgeKind.calls.name);
        edges.add(CodeEdge(
          id: eId,
          workspaceId: wsId,
          repoId: repoId,
          sourceSymbolId: caller.id,
          sourceFilePath: filePath,
          kind: CodeEdgeKind.calls,
          targetSymbolId: target.id,
        ));
      }
      await ingest(symbols: symbols, edges: edges);

      final callers = await repo.callers(wsId, target.id, limit: 2);
      expect(callers.length, 2);
    });
  });

  group('callees', () {
    test('returns callees of a symbol', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      final callee = symbol(name: 'helper', qualifiedName: 'helper', startLine: 30, endLine: 35);
      final edgeId = codeEdgeId(wsId, repoId, source.id, callee.id, CodeEdgeKind.calls.name);
      final edge = CodeEdge(
        id: edgeId,
        workspaceId: wsId,
        repoId: repoId,
        sourceSymbolId: source.id,
        sourceFilePath: filePath,
        kind: CodeEdgeKind.calls,
        targetSymbolId: callee.id,
      );
      await ingest(symbols: [source, callee], edges: [edge]);

      final callees = await repo.callees(wsId, source.id);
      expect(callees.length, 1);
      expect(callees.first.id, callee.id);
    });

    test('returns empty for symbol with no callees', () async {
      final s = symbol();
      await ingest(symbols: [s]);

      final callees = await repo.callees(wsId, s.id);
      expect(callees, isEmpty);
    });

    test('respects limit', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      final edges = <CodeEdge>[];
      final symbols = <CodeSymbol>[source];
      for (var i = 0; i < 5; i++) {
        final callee = symbol(
          name: 'callee$i',
          qualifiedName: 'callee$i',
          startLine: 40 + i,
          endLine: 43 + i,
        );
        symbols.add(callee);
        final eId = codeEdgeId(wsId, repoId, source.id, callee.id, CodeEdgeKind.calls.name);
        edges.add(CodeEdge(
          id: eId,
          workspaceId: wsId,
          repoId: repoId,
          sourceSymbolId: source.id,
          sourceFilePath: filePath,
          kind: CodeEdgeKind.calls,
          targetSymbolId: callee.id,
        ));
      }
      await ingest(symbols: symbols, edges: edges);

      final callees = await repo.callees(wsId, source.id, limit: 3);
      expect(callees.length, 3);
    });
  });

  // --------------------------------------------------------------------------
  // impactRadius
  // --------------------------------------------------------------------------

  group('impactRadius', () {
    test('returns subgraph with edge when caller calls target', () async {
      final target = symbol(name: 'target', qualifiedName: 'target');
      final caller = symbol(name: 'caller', qualifiedName: 'caller', startLine: 30, endLine: 35);
      final edgeId = codeEdgeId(wsId, repoId, caller.id, target.id, CodeEdgeKind.calls.name);
      final edge = CodeEdge(
        id: edgeId,
        workspaceId: wsId,
        repoId: repoId,
        sourceSymbolId: caller.id,
        sourceFilePath: filePath,
        kind: CodeEdgeKind.calls,
        targetSymbolId: target.id,
      );
      await ingest(symbols: [caller, target], edges: [edge]);

      final subgraph = await repo.impactRadius(wsId, target.id, depth: 2);
      expect(subgraph.isEmpty, isFalse);
      expect(subgraph.root, isNotNull);
      expect(subgraph.root!.id, target.id);
      expect(subgraph.nodes.length, 2);
      expect(subgraph.edges.length, 1);
      expect(subgraph.depthById[target.id], 0);
      expect(subgraph.depthById[caller.id], 1);
    });

    test('returns empty subgraph for unknown symbol', () async {
      final subgraph = await repo.impactRadius(wsId, 'nonexistent');
      expect(subgraph.isEmpty, isTrue);
      expect(subgraph.root, isNull);
    });

    test('multi-hop traversal', () async {
      // target ← directCaller ← indirectCaller
      final target = symbol(name: 'target', qualifiedName: 'target');
      final direct = symbol(name: 'direct', qualifiedName: 'direct', startLine: 30, endLine: 35);
      final indirect = symbol(name: 'indirect', qualifiedName: 'indirect', startLine: 40, endLine: 45);

      final e1Id = codeEdgeId(wsId, repoId, direct.id, target.id, CodeEdgeKind.calls.name);
      final e2Id = codeEdgeId(wsId, repoId, indirect.id, direct.id, CodeEdgeKind.calls.name);

      await ingest(
        symbols: [target, direct, indirect],
        edges: [
          CodeEdge(
            id: e1Id,
            workspaceId: wsId,
            repoId: repoId,
            sourceSymbolId: direct.id,
            sourceFilePath: filePath,
            kind: CodeEdgeKind.calls,
            targetSymbolId: target.id,
          ),
          CodeEdge(
            id: e2Id,
            workspaceId: wsId,
            repoId: repoId,
            sourceSymbolId: indirect.id,
            sourceFilePath: filePath,
            kind: CodeEdgeKind.calls,
            targetSymbolId: direct.id,
          ),
        ],
      );

      final subgraph = await repo.impactRadius(wsId, target.id, depth: 3);
      expect(subgraph.nodes.length, 3);
      expect(subgraph.depthById[target.id], 0);
      expect(subgraph.depthById[direct.id], 1);
      expect(subgraph.depthById[indirect.id], 2);
    });
  });

  // --------------------------------------------------------------------------
  // resolvePendingReferences
  // --------------------------------------------------------------------------

  group('resolvePendingReferences', () {
    test('resolves edges by qualified name', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      // Target symbol whose qualifiedName matches the edge's targetName.
      final target = symbol(
        name: 'helper',
        qualifiedName: 'helper',
        startLine: 30,
        endLine: 35,
      );
      // Edge with unresolved target (has targetName, no targetSymbolId).
      final edgeId = codeEdgeId(wsId, repoId, source.id, 'helper', CodeEdgeKind.calls.name);
      final edge = CodeEdge(
        id: edgeId,
        workspaceId: wsId,
        repoId: repoId,
        sourceSymbolId: source.id,
        sourceFilePath: filePath,
        kind: CodeEdgeKind.calls,
        targetName: 'helper',
      );
      await ingest(symbols: [source, target], edges: [edge]);

      final resolved = await repo.resolvePendingReferences(wsId, repoId);
      expect(resolved, 1);

      // The callee should now be visible.
      final callees = await repo.callees(wsId, source.id);
      expect(callees.length, 1);
      expect(callees.first.id, target.id);
    });

    test('returns zero when no unresolved edges', () async {
      final s = symbol();
      await ingest(symbols: [s]);

      final resolved = await repo.resolvePendingReferences(wsId, repoId);
      expect(resolved, 0);
    });
  });

  // --------------------------------------------------------------------------
  // fileHashes
  // --------------------------------------------------------------------------

  group('fileHashes', () {
    test('returns path→hash map', () async {
      await ingest(symbols: [symbol()], contentHash: 'sha256-abc');

      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes, {filePath: 'sha256-abc'});
    });

    test('returns empty map for unindexed repo', () async {
      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes, isEmpty);
    });

    test('scoped to workspace+repo', () async {
      await ingest(symbols: [symbol()], contentHash: 'h1');

      final hashes = await repo.fileHashes('other-ws', repoId);
      expect(hashes, isEmpty);
    });

    test('multiple files', () async {
      await ingest(symbols: [symbol()], contentHash: 'h1', fp: 'a.dart');
      await ingest(symbols: [symbol()], contentHash: 'h2', fp: 'b.dart');

      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes, {'a.dart': 'h1', 'b.dart': 'h2'});
    });
  });

  // --------------------------------------------------------------------------
  // deleteFiles
  // --------------------------------------------------------------------------

  group('deleteFiles', () {
    test('removes symbols and edges for deleted files', () async {
      final s = symbol();
      final t = symbol(name: 'target', qualifiedName: 'target', startLine: 30, endLine: 35);
      final edgeId = codeEdgeId(wsId, repoId, s.id, t.id, CodeEdgeKind.calls.name);
      final edge = CodeEdge(
        id: edgeId,
        workspaceId: wsId,
        repoId: repoId,
        sourceSymbolId: s.id,
        sourceFilePath: filePath,
        kind: CodeEdgeKind.calls,
        targetSymbolId: t.id,
      );
      await ingest(symbols: [s, t], edges: [edge]);

      await repo.deleteFiles(wsId, repoId, [filePath]);

      // Symbols gone.
      final sym = await repo.getById(wsId, s.id);
      expect(sym, isNull);
      // File entry gone.
      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes, isEmpty);
    });

    test('does not throw with empty list', () async {
      await repo.deleteFiles(wsId, repoId, []);
    });

    test('does not throw for nonexistent file', () async {
      await repo.deleteFiles(wsId, repoId, ['nonexistent.dart']);
    });

    test('only deletes targeted file, leaves others', () async {
      await ingest(symbols: [symbol(qualifiedName: 'a')], contentHash: 'h1', fp: 'a.dart');
      await ingest(symbols: [symbol(qualifiedName: 'b')], contentHash: 'h2', fp: 'b.dart');

      await repo.deleteFiles(wsId, repoId, ['a.dart']);

      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes, {'b.dart': 'h2'});
    });
  });

  // --------------------------------------------------------------------------
  // watchByRepo
  // --------------------------------------------------------------------------

  group('watchByRepo', () {
    test('emits current symbols on listen', () async {
      final s = symbol();
      await ingest(symbols: [s]);

      final stream = repo.watchByRepo(wsId, repoId);
      final emitted = await stream.first;

      expect(emitted.length, 1);
      expect(emitted.first.id, s.id);
    });

    test('emits empty when no symbols', () async {
      final stream = repo.watchByRepo(wsId, repoId);
      final emitted = await stream.first;

      expect(emitted, isEmpty);
    });
  });

  // --------------------------------------------------------------------------
  // Workspace + repo scoping integration
  // --------------------------------------------------------------------------

  group('workspace+repo scoping', () {
    setUp(() async {
      // Seed a second workspace and second repo.
      await db.into(db.workspacesTable).insert(
            const WorkspacesTableCompanion(id: Value('ws-2'), name: Value('WS2')),
          );
      await db.into(db.reposTable).insert(
            const ReposTableCompanion(
              id: Value('repo-b'),
              name: Value('other/repo'),
              path: Value('/tmp/repo-b'),
            ),
          );
    });

    test('symbolsForRepo isolates by workspace', () async {
      await ingest(symbols: [symbol(name: 'a', qualifiedName: 'a')]);
      // Ingest same name in ws-2/repo-a.
      final id2 = codeSymbolId('ws-2', repoId, filePath, 'a');
      await repo.ingestFile(
        workspaceId: 'ws-2',
        repoId: repoId,
        filePath: filePath,
        contentHash: 'h2',
        symbols: [
          symbol(name: 'a', qualifiedName: 'a').copyWith(
            id: id2,
            workspaceId: 'ws-2',
          ),
        ],
        edges: [],
      );

      final ws1Symbols = await repo.symbolsForRepo(wsId, repoId);
      expect(ws1Symbols.length, 1);
      expect(ws1Symbols.first.workspaceId, wsId);

      final ws2Symbols = await repo.symbolsForRepo('ws-2', repoId);
      expect(ws2Symbols.length, 1);
      expect(ws2Symbols.first.workspaceId, 'ws-2');
    });

    test('symbolsForRepo isolates by repo within workspace', () async {
      await ingest(symbols: [symbol(name: 'a', qualifiedName: 'a')]);
      // Ingest in ws-test/repo-b.
      final id2 = codeSymbolId(wsId, 'repo-b', filePath, 'a');
      await repo.ingestFile(
        workspaceId: wsId,
        repoId: 'repo-b',
        filePath: filePath,
        contentHash: 'h2',
        symbols: [
          symbol(name: 'a', qualifiedName: 'a').copyWith(
            id: id2,
            repoId: 'repo-b',
          ),
        ],
        edges: [],
      );

      final repoA = await repo.symbolsForRepo(wsId, repoId);
      expect(repoA.length, 1);
      expect(repoA.first.repoId, repoId);

      final repoB = await repo.symbolsForRepo(wsId, 'repo-b');
      expect(repoB.length, 1);
      expect(repoB.first.repoId, 'repo-b');
    });

    test('callers/callees scoped to workspace', () async {
      final target = symbol(name: 'target', qualifiedName: 'target');
      final caller = symbol(name: 'caller', qualifiedName: 'caller', startLine: 30, endLine: 35);
      final edgeId = codeEdgeId(wsId, repoId, caller.id, target.id, CodeEdgeKind.calls.name);
      final edge = CodeEdge(
        id: edgeId,
        workspaceId: wsId,
        repoId: repoId,
        sourceSymbolId: caller.id,
        sourceFilePath: filePath,
        kind: CodeEdgeKind.calls,
        targetSymbolId: target.id,
      );
      await ingest(symbols: [caller, target], edges: [edge]);

      // Same symbol id but queried with wrong workspace.
      final callersInOtherWs = await repo.callers('ws-2', target.id);
      expect(callersInOtherWs, isEmpty);
    });

    test('impactRadius scoped to workspace', () async {
      final target = symbol(name: 'target', qualifiedName: 'target');
      final caller = symbol(name: 'caller', qualifiedName: 'caller', startLine: 30, endLine: 35);
      final edgeId = codeEdgeId(wsId, repoId, caller.id, target.id, CodeEdgeKind.calls.name);
      final edge = CodeEdge(
        id: edgeId,
        workspaceId: wsId,
        repoId: repoId,
        sourceSymbolId: caller.id,
        sourceFilePath: filePath,
        kind: CodeEdgeKind.calls,
        targetSymbolId: target.id,
      );
      await ingest(symbols: [caller, target], edges: [edge]);

      final subgraph = await repo.impactRadius('ws-2', target.id);
      expect(subgraph.isEmpty, isTrue);
    });
  });

  // --------------------------------------------------------------------------
  // Edge cases
  // --------------------------------------------------------------------------

  group('edge cases', () {
    test('symbolsForRepo returns domain entities with correct fields', () async {
      final s = symbol(
        name: 'f',
        qualifiedName: 'm.f',
        kind: CodeSymbolKind.method,
        startLine: 42,
        endLine: 56,
      ).copyWith(docstring: 'Doc', parentName: 'm');
      await ingest(symbols: [s]);

      final results = await repo.symbolsForRepo(wsId, repoId);
      expect(results.length, 1);
      final dom = results.first;
      expect(dom.id, s.id);
      expect(dom.name, 'f');
      expect(dom.qualifiedName, 'm.f');
      expect(dom.kind, CodeSymbolKind.method);
      expect(dom.startLine, 42);
      expect(dom.endLine, 56);
      expect(dom.docstring, 'Doc');
      expect(dom.parentName, 'm');
      expect(dom.filePath, filePath);
      expect(dom.language, 'dart');
    });

    test('ingestFile with different files keeps them separate', () async {
      final s1 = symbol(qualifiedName: 'a');
      final s2Id = codeSymbolId(wsId, repoId, 'other.dart', 'b');
      final s2 = symbol(qualifiedName: 'b').copyWith(id: s2Id, filePath: 'other.dart');
      await ingest(symbols: [s1], fp: 'a.dart');
      await ingest(symbols: [s2], fp: 'other.dart');

      final all = await repo.symbolsForRepo(wsId, repoId);
      expect(all.length, 2);
    });
  });
}
