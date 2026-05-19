import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late WorkspaceDatabase db;
  late CodeGraphDao dao;
  late DaoCodeGraphRepository repo;

  // Deterministic constants for the test workspace+repo.
  const wsId = 'ws-test';
  const repoId = 'repo-a';
  const filePath = 'src/main.dart';

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, wsId, name: 'Test Workspace');
    db = dbs.of(wsId);
    dao = db.codeGraphDao;
    repo = DaoCodeGraphRepository(dbs);

    // Seed the repo so the code-index foreign keys are satisfied. The workspace
    // itself is the database file, so there is no workspace row to insert here.
    await db
        .into(db.reposTable)
        .insert(
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
  }) => repo.ingestFile(
    workspaceId: wsId,
    repoId: repoId,
    filePath: fp,
    contentHash: contentHash,
    symbols: symbols,
    edges: edges,
  );

  // --------------------------------------------------------------------------
  // ingestFile — CRUD for symbols, edges and files
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
      final s = symbol(
        qualifiedName: 'withDoc',
      ).copyWith(docstring: 'Docs for this symbol.');
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
      await ingest(
        symbols: [symbol(name: 'myFunc', qualifiedName: 'myFunc')],
      );

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
      // A second workspace is a second DATABASE, so its repo row has to be
      // seeded there — the code-index FK to `repos` is now intra-file.
      await seedTestWorkspace(global, dbs, 'ws-2', name: 'Two');
      await dbs
          .of('ws-2')
          .into(dbs.of('ws-2').reposTable)
          .insert(
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
      final s1 = symbol(
        name: 'a',
        qualifiedName: 'a',
        startLine: 1,
        endLine: 3,
      );
      final s2 = symbol(
        name: 'b',
        qualifiedName: 'b',
        startLine: 5,
        endLine: 7,
      );
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
      await ingest(
        symbols: [symbol(name: 'foo', qualifiedName: 'foo')],
      );

      final results = await repo.search(wsId, repoId, 'zzz_unknown_xyz');
      expect(results, isEmpty);
    });

    test('search is scoped to workspace+repo', () async {
      await ingest(
        symbols: [symbol(name: 'alpha', qualifiedName: 'alpha')],
      );

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
      final target = symbol(
        name: 'helper',
        qualifiedName: 'helper',
        startLine: 30,
        endLine: 35,
      );
      // Edge where caller calls target, with target resolved.
      final edgeId = codeEdgeId(
        wsId,
        repoId,
        caller.id,
        target.id,
        CodeEdgeKind.calls.name,
      );
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
        final eId = codeEdgeId(
          wsId,
          repoId,
          caller.id,
          target.id,
          CodeEdgeKind.calls.name,
        );
        edges.add(
          CodeEdge(
            id: eId,
            workspaceId: wsId,
            repoId: repoId,
            sourceSymbolId: caller.id,
            sourceFilePath: filePath,
            kind: CodeEdgeKind.calls,
            targetSymbolId: target.id,
          ),
        );
      }
      await ingest(symbols: symbols, edges: edges);

      final callers = await repo.callers(wsId, target.id, limit: 2);
      expect(callers.length, 2);
    });
  });

  group('callees', () {
    test('returns callees of a symbol', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      final callee = symbol(
        name: 'helper',
        qualifiedName: 'helper',
        startLine: 30,
        endLine: 35,
      );
      final edgeId = codeEdgeId(
        wsId,
        repoId,
        source.id,
        callee.id,
        CodeEdgeKind.calls.name,
      );
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
        final eId = codeEdgeId(
          wsId,
          repoId,
          source.id,
          callee.id,
          CodeEdgeKind.calls.name,
        );
        edges.add(
          CodeEdge(
            id: eId,
            workspaceId: wsId,
            repoId: repoId,
            sourceSymbolId: source.id,
            sourceFilePath: filePath,
            kind: CodeEdgeKind.calls,
            targetSymbolId: callee.id,
          ),
        );
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
      final caller = symbol(
        name: 'caller',
        qualifiedName: 'caller',
        startLine: 30,
        endLine: 35,
      );
      final edgeId = codeEdgeId(
        wsId,
        repoId,
        caller.id,
        target.id,
        CodeEdgeKind.calls.name,
      );
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
      final direct = symbol(
        name: 'direct',
        qualifiedName: 'direct',
        startLine: 30,
        endLine: 35,
      );
      final indirect = symbol(
        name: 'indirect',
        qualifiedName: 'indirect',
        startLine: 40,
        endLine: 45,
      );

      final e1Id = codeEdgeId(
        wsId,
        repoId,
        direct.id,
        target.id,
        CodeEdgeKind.calls.name,
      );
      final e2Id = codeEdgeId(
        wsId,
        repoId,
        indirect.id,
        direct.id,
        CodeEdgeKind.calls.name,
      );

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
      final edgeId = codeEdgeId(
        wsId,
        repoId,
        source.id,
        'helper',
        CodeEdgeKind.calls.name,
      );
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
      final t = symbol(
        name: 'target',
        qualifiedName: 'target',
        startLine: 30,
        endLine: 35,
      );
      final edgeId = codeEdgeId(
        wsId,
        repoId,
        s.id,
        t.id,
        CodeEdgeKind.calls.name,
      );
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
      await ingest(
        symbols: [symbol(qualifiedName: 'a')],
        contentHash: 'h1',
        fp: 'a.dart',
      );
      await ingest(
        symbols: [symbol(qualifiedName: 'b')],
        contentHash: 'h2',
        fp: 'b.dart',
      );

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

      await db
          .into(db.reposTable)
          .insert(
            const ReposTableCompanion(
              id: Value('repo-b'),
              name: Value('other/repo'),
              path: Value('/tmp/repo-b'),
            ),
          );
    });

    test('symbolsForRepo isolates by workspace', () async {
      await ingest(
        symbols: [symbol(name: 'a', qualifiedName: 'a')],
      );
      // The other workspace is another database, so its repo row lives there.
      await seedTestWorkspace(global, dbs, 'ws-2', name: 'Two');
      final otherDb = dbs.of('ws-2');
      await otherDb
          .into(otherDb.reposTable)
          .insert(
            const ReposTableCompanion(
              id: Value(repoId),
              name: Value('acme/repo'),
              path: Value('/tmp/repo'),
            ),
          );
      final id2 = codeSymbolId('ws-2', repoId, filePath, 'a');
      await repo.ingestFile(
        workspaceId: 'ws-2',
        repoId: repoId,
        filePath: filePath,
        contentHash: 'h2',
        symbols: [
          symbol(
            name: 'a',
            qualifiedName: 'a',
          ).copyWith(id: id2, workspaceId: 'ws-2'),
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
      await ingest(
        symbols: [symbol(name: 'a', qualifiedName: 'a')],
      );
      // Ingest in ws-test/repo-b.
      final id2 = codeSymbolId(wsId, 'repo-b', filePath, 'a');
      await repo.ingestFile(
        workspaceId: wsId,
        repoId: 'repo-b',
        filePath: filePath,
        contentHash: 'h2',
        symbols: [
          symbol(
            name: 'a',
            qualifiedName: 'a',
          ).copyWith(id: id2, repoId: 'repo-b'),
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
      final caller = symbol(
        name: 'caller',
        qualifiedName: 'caller',
        startLine: 30,
        endLine: 35,
      );
      final edgeId = codeEdgeId(
        wsId,
        repoId,
        caller.id,
        target.id,
        CodeEdgeKind.calls.name,
      );
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
      final caller = symbol(
        name: 'caller',
        qualifiedName: 'caller',
        startLine: 30,
        endLine: 35,
      );
      final edgeId = codeEdgeId(
        wsId,
        repoId,
        caller.id,
        target.id,
        CodeEdgeKind.calls.name,
      );
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
    test(
      'symbolsForRepo returns domain entities with correct fields',
      () async {
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
      },
    );

    test('ingestFile with different files keeps them separate', () async {
      final s1 = symbol(qualifiedName: 'a');
      final s2Id = codeSymbolId(wsId, repoId, 'other.dart', 'b');
      final s2 = symbol(
        qualifiedName: 'b',
      ).copyWith(id: s2Id, filePath: 'other.dart');
      await ingest(symbols: [s1], fp: 'a.dart');
      await ingest(symbols: [s2], fp: 'other.dart');

      final all = await repo.symbolsForRepo(wsId, repoId);
      expect(all.length, 2);
    });
  });

  // --------------------------------------------------------------------------
  // ingestFiles — the batched (one-transaction) ingest path
  // --------------------------------------------------------------------------

  group('ingestFiles', () {
    CodeFileIngest fileIngest(String path, String qualifiedName, String hash) =>
        CodeFileIngest(
          workspaceId: wsId,
          repoId: repoId,
          checkoutId: null,
          filePath: path,
          contentHash: hash,
          symbols: [
            symbol(qualifiedName: qualifiedName).copyWith(
              id: codeSymbolId(wsId, repoId, path, qualifiedName),
              filePath: path,
            ),
          ],
          edges: const [],
        );

    test('a batch of three files leaves exactly those rows', () async {
      await repo.ingestFiles([
        fileIngest('a.dart', 'a', 'h1'),
        fileIngest('b.dart', 'b', 'h2'),
        fileIngest('c.dart', 'c', 'h3'),
      ]);

      final all = await repo.symbolsForRepo(wsId, repoId);
      expect(all.map((s) => s.filePath).toSet(), {
        'a.dart',
        'b.dart',
        'c.dart',
      });
      final hashes = await repo.fileHashes(wsId, repoId);
      expect(hashes, {'a.dart': 'h1', 'b.dart': 'h2', 'c.dart': 'h3'});
    });

    test(
      'a re-ingest inside a batch replaces the file\'s prior rows',
      () async {
        await repo.ingestFiles([fileIngest('a.dart', 'old', 'h1')]);
        await repo.ingestFiles([
          fileIngest('a.dart', 'renamed', 'h2'),
          fileIngest('b.dart', 'b', 'h3'),
        ]);

        final all = await repo.symbolsForRepo(wsId, repoId);
        expect(all.map((s) => s.qualifiedName).toSet(), {
          'renamed',
          'b',
        }, reason: 'the old extraction of a.dart must be replaced, not merged');
      },
    );

    test('an empty batch is a no-op', () async {
      await repo.ingestFiles(const []);
    });
  });

  // --------------------------------------------------------------------------
  // ingestFiles — embedding reuse
  //
  // Inference is by far the most expensive part of an index and it used to be
  // paid per SYMBOL PRESENT rather than per symbol CHANGED: rewriting a
  // generated file re-embedded every symbol in it. Measured on this repo, eight
  // `app_localizations*.dart` files hold ~30k symbols and `flutter gen-l10n`
  // rewrites all of them for one new ARB key, which turned an incremental
  // reindex into a 52-second run.
  // --------------------------------------------------------------------------

  group('ingestFiles embedding reuse', () {
    late _CountingEmbedder embedder;
    late DaoCodeGraphRepository embedRepo;

    setUp(() {
      embedder = _CountingEmbedder();
      embedRepo = DaoCodeGraphRepository(dbs, embeddingService: embedder);
    });

    CodeFileIngest ingestOf(
      String path,
      String hash,
      List<CodeSymbol> symbols,
    ) => CodeFileIngest(
      workspaceId: wsId,
      repoId: repoId,
      checkoutId: null,
      filePath: path,
      contentHash: hash,
      symbols: symbols,
      edges: const [],
    );

    CodeSymbol sym(String path, String qualifiedName, {String signature = ''}) =>
        symbol(qualifiedName: qualifiedName, signature: signature).copyWith(
          id: codeSymbolId(wsId, repoId, path, qualifiedName),
          filePath: path,
        );

    Future<List<int?>> embeddingLengths() async {
      final rows = await dao.getSymbolsByRepo(wsId, repoId);
      return [for (final row in rows) row.embedding?.length];
    }

    test('a first index embeds every symbol', () async {
      await embedRepo.ingestFiles([
        ingestOf('a.dart', 'h1', [sym('a.dart', 'a'), sym('a.dart', 'b')]),
      ]);

      expect(embedder.texts, hasLength(2));
      expect(await embeddingLengths(), everyElement(isNotNull));
    });

    test('re-indexing identical symbols embeds nothing', () async {
      final symbols = [sym('a.dart', 'a'), sym('a.dart', 'b')];
      await embedRepo.ingestFiles([ingestOf('a.dart', 'h1', symbols)]);
      embedder.texts.clear();

      // Same symbols, new file hash — exactly what a formatter or a codegen
      // rewrite produces.
      await embedRepo.ingestFiles([ingestOf('a.dart', 'h2', symbols)]);

      expect(embedder.texts, isEmpty);
      expect(
        await embeddingLengths(),
        everyElement(isNotNull),
        reason: 'the vectors must survive the re-ingest, not be nulled out',
      );
    });

    test('only the symbol whose embed text changed is re-embedded', () async {
      await embedRepo.ingestFiles([
        ingestOf('a.dart', 'h1', [
          sym('a.dart', 'a', signature: 'void a()'),
          sym('a.dart', 'b', signature: 'void b()'),
        ]),
      ]);
      embedder.texts.clear();

      await embedRepo.ingestFiles([
        ingestOf('a.dart', 'h2', [
          sym('a.dart', 'a', signature: 'void a()'),
          sym('a.dart', 'b', signature: 'void b(int x)'),
        ]),
      ]);

      expect(embedder.texts, hasLength(1));
      expect(embedder.texts.single, contains('void b(int x)'));
    });

    test('a moved symbol keeps its vector without re-embedding', () async {
      // Line numbers are not part of the embed text — inserting a line above a
      // symbol must not cost inference, which is the common case when a file is
      // edited at all.
      final before = symbol(
        qualifiedName: 'a',
      ).copyWith(id: codeSymbolId(wsId, repoId, 'a.dart', 'a'), filePath: 'a.dart', startLine: 1, endLine: 5);
      final after = before.copyWith(startLine: 40, endLine: 44);

      await embedRepo.ingestFiles([ingestOf('a.dart', 'h1', [before])]);
      embedder.texts.clear();
      await embedRepo.ingestFiles([ingestOf('a.dart', 'h2', [after])]);

      expect(embedder.texts, isEmpty);
      final rows = await dao.getSymbolsByRepo(wsId, repoId);
      expect(rows.single.startLine, 40);
      expect(rows.single.embedding, isNotNull);
    });

    test('a symbol the file no longer defines is deleted', () async {
      await embedRepo.ingestFiles([
        ingestOf('a.dart', 'h1', [sym('a.dart', 'a'), sym('a.dart', 'gone')]),
      ]);

      await embedRepo.ingestFiles([
        ingestOf('a.dart', 'h2', [sym('a.dart', 'a')]),
      ]);

      final all = await embedRepo.symbolsForRepo(wsId, repoId);
      expect(all.map((s) => s.qualifiedName), ['a']);
    });

    test('a row indexed with no embedder is embedded on the next run', () async {
      // The model downloads in the background, so a repo indexed before it was
      // ready holds vector-less rows. Those have nothing to reuse and must not
      // be mistaken for up to date.
      await repo.ingestFiles([
        ingestOf('a.dart', 'h1', [sym('a.dart', 'a')]),
      ]);
      expect(await embeddingLengths(), [null]);

      await embedRepo.ingestFiles([
        ingestOf('a.dart', 'h1', [sym('a.dart', 'a')]),
      ]);

      expect(embedder.texts, hasLength(1));
      expect(await embeddingLengths(), everyElement(isNotNull));
    });

    test('reuse is per checkout partition, never inherited from base', () async {
      await db
          .into(db.isolatedReposTable)
          .insert(
            IsolatedReposTableCompanion(
              id: const Value('wt-1'),
              workspaceId: const Value(wsId),
              repoId: const Value(repoId),
              channelId: const Value('ch-1'),
              path: const Value('/tmp/wt-1'),
              sourcePath: const Value('/tmp/test-repo'),
              branch: const Value('feature'),
              createdAt: Value(DateTime.now()),
            ),
          );
      await embedRepo.ingestFiles([
        ingestOf('a.dart', 'h1', [sym('a.dart', 'a')]),
      ]);
      embedder.texts.clear();

      // The same path in a worktree partition is a DIFFERENT row (the id hashes
      // the checkout in), so it has no stored vector of its own.
      await embedRepo.ingestFiles([
        CodeFileIngest(
          workspaceId: wsId,
          repoId: repoId,
          checkoutId: 'wt-1',
          filePath: 'a.dart',
          contentHash: 'h1',
          symbols: [
            symbol(qualifiedName: 'a').copyWith(
              id: codeSymbolId(wsId, repoId, 'a.dart', 'a', checkoutId: 'wt-1'),
              filePath: 'a.dart',
              checkoutId: 'wt-1',
            ),
          ],
          edges: const [],
        ),
      ]);

      expect(embedder.texts, hasLength(1));
    });
  });

  // --------------------------------------------------------------------------
  // deleteFiles — batched prune, IN-list chunking
  // --------------------------------------------------------------------------

  group('deleteFiles chunking', () {
    test(
      '600 paths (crosses the 400-per-statement chunk) all delete',
      () async {
        // Only a handful carry rows; the rest exercise the chunked IN lists.
        for (var i = 0; i < 5; i++) {
          final path = 'file_$i.dart';
          await repo.ingestFile(
            workspaceId: wsId,
            repoId: repoId,
            filePath: path,
            contentHash: 'h$i',
            symbols: [
              symbol(qualifiedName: 'q$i').copyWith(
                id: codeSymbolId(wsId, repoId, path, 'q$i'),
                filePath: path,
              ),
            ],
            edges: const [],
          );
        }
        final paths = [for (var i = 0; i < 600; i++) 'file_$i.dart'];

        await repo.deleteFiles(wsId, repoId, paths);

        expect(await repo.fileHashes(wsId, repoId), isEmpty);
        expect(await repo.symbolsForRepo(wsId, repoId), isEmpty);
      },
    );
  });

  // --------------------------------------------------------------------------
  // countUnresolvedEdges + the targeted resolve path
  // --------------------------------------------------------------------------

  group('countUnresolvedEdges', () {
    test('counts only unresolved edges in the partition', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      await ingest(
        symbols: [source],
        edges: [edge0(sourceSymbolId: source.id, targetName: 'nowhere')],
      );

      expect(await repo.countUnresolvedEdges(wsId, repoId), 1);
      expect(await repo.countUnresolvedEdges('other-ws', repoId), 0);
    });

    test('zero after resolution', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      final target = symbol(
        name: 'helper',
        qualifiedName: 'helper',
        startLine: 30,
        endLine: 35,
      );
      await ingest(
        symbols: [source, target],
        edges: [edge0(sourceSymbolId: source.id, targetName: 'helper')],
      );

      await repo.resolvePendingReferences(wsId, repoId);
      expect(await repo.countUnresolvedEdges(wsId, repoId), 0);
    });
  });

  group('resolvePendingReferences (targeted path semantics)', () {
    test('an AMBIGUOUS simple name stays unresolved', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      // Two symbols share the simple name 'dup' under different qualified
      // names: the targeted read still returns BOTH (it matches by name), so
      // the unique-simple-name rule is exactly as strict as the old
      // load-everything pass.
      final dup1 = symbol(name: 'dup', qualifiedName: 'a.dup');
      final dup2 = symbol(name: 'dup', qualifiedName: 'b.dup');
      await ingest(
        symbols: [source, dup1, dup2],
        edges: [edge0(sourceSymbolId: source.id, targetName: 'dup')],
      );

      final resolved = await repo.resolvePendingReferences(wsId, repoId);
      expect(resolved, 0);
      expect(await repo.countUnresolvedEdges(wsId, repoId), 1);
    });

    test('a UNIQUE simple name resolves', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      final target = symbol(name: 'only', qualifiedName: 'lib.only');
      await ingest(
        symbols: [source, target],
        edges: [edge0(sourceSymbolId: source.id, targetName: 'only')],
      );

      final resolved = await repo.resolvePendingReferences(wsId, repoId);
      expect(resolved, 1);
      final callees = await repo.callees(wsId, source.id);
      expect(callees.single.id, target.id);
    });

    test('a qualified-name match wins over the simple-name fallback', () async {
      final source = symbol(name: 'main', qualifiedName: 'main');
      final qualified = symbol(name: 'helper', qualifiedName: 'lib.helper');
      // A symbol whose SIMPLE name equals the target string, competing with
      // the exact qualified match.
      final simple = symbol(name: 'lib.helper', qualifiedName: 'other.x');
      await ingest(
        symbols: [source, qualified, simple],
        edges: [edge0(sourceSymbolId: source.id, targetName: 'lib.helper')],
      );

      await repo.resolvePendingReferences(wsId, repoId);
      final callees = await repo.callees(wsId, source.id);
      expect(callees.single.id, qualified.id);
    });

    test('never binds an edge to its own source (self-edge guard)', () async {
      final selfNamed = symbol(name: 'recurse', qualifiedName: 'recurse');
      await ingest(
        symbols: [selfNamed],
        edges: [edge0(sourceSymbolId: selfNamed.id, targetName: 'recurse')],
      );

      final resolved = await repo.resolvePendingReferences(wsId, repoId);
      expect(resolved, 0);
    });
  });

  // --------------------------------------------------------------------------
  // Index checkpoints
  // --------------------------------------------------------------------------

  group('checkpoints', () {
    CodeIndexCheckpoint cp({
      String workspaceId = wsId,
      String? checkoutId,
      String head = 'head-1',
      String digest = 'digest-1',
      int generation = 1,
      int baseGeneration = 0,
    }) => CodeIndexCheckpoint(
      workspaceId: workspaceId,
      repoId: repoId,
      checkoutId: checkoutId,
      headSha: head,
      worktreeDigest: digest,
      indexerFingerprint: 'toolchain-1',
      generation: generation,
      baseGeneration: baseGeneration,
      indexedAt: DateTime.utc(2025, 1, 1),
    );

    test('round-trips and upserts in place', () async {
      await repo.writeCheckpoint(cp());
      var view = await repo.readCheckpoint(wsId, repoId);
      expect(view.own, isNotNull);
      expect(view.own!.headSha, 'head-1');
      expect(view.baseGeneration, 1);

      await repo.writeCheckpoint(cp(head: 'head-2', generation: 2));
      view = await repo.readCheckpoint(wsId, repoId);
      expect(view.own!.headSha, 'head-2');
      expect(view.own!.generation, 2);
      expect(view.baseGeneration, 2);
    });

    test(
      'a worktree read returns its own row AND the base generation',
      () async {
        // Seed the worktree row the FK references.
        await db
            .into(db.isolatedReposTable)
            .insert(
              IsolatedReposTableCompanion(
                id: const Value('wt1'),
                workspaceId: const Value(wsId),
                channelId: const Value('ch1'),
                repoId: const Value(repoId),
                path: const Value('/tmp/wt1'),
                branch: const Value('pr-1'),
                sourcePath: const Value('/tmp/src'),
                createdAt: Value(DateTime.utc(2025)),
              ),
            );
        await repo.writeCheckpoint(cp(generation: 5));
        await repo.writeCheckpoint(
          cp(checkoutId: 'wt1', digest: 'wt-digest', baseGeneration: 5),
        );

        final view = await repo.readCheckpoint(wsId, repoId, checkoutId: 'wt1');
        expect(view.own!.checkoutId, 'wt1');
        expect(view.own!.worktreeDigest, 'wt-digest');
        expect(view.baseGeneration, 5);
      },
    );

    test('reads are workspace-scoped', () async {
      await repo.writeCheckpoint(cp());

      final foreign = await repo.readCheckpoint('other-ws', repoId);
      expect(
        foreign.own,
        isNull,
        reason: 'one workspace\'s checkpoint must not leak into another',
      );
      expect(foreign.baseGeneration, 0);
    });

    test(
      'deleteByRepo (repo unlink) takes the checkpoint with the rows',
      () async {
        // The unlink path wipes the index so a re-link reindexes fresh. A
        // surviving checkpoint would make that first run short-circuit as
        // "unchanged" — and serve an EMPTY graph until something in the repo
        // changed. Index state and its checkpoint must die together.
        await ingest(symbols: [symbol()], contentHash: 'h1');
        await repo.writeCheckpoint(cp());
        expect((await repo.readCheckpoint(wsId, repoId)).own, isNotNull);

        await dao.deleteByRepo(wsId, repoId);

        expect(await repo.symbolsForRepo(wsId, repoId), isEmpty);
        expect(await repo.fileHashes(wsId, repoId), isEmpty);
        final view = await repo.readCheckpoint(wsId, repoId);
        expect(
          view.own,
          isNull,
          reason: 'a stale checkpoint would freeze the graph empty',
        );
        expect(view.baseGeneration, 0);
      },
    );
  });
}

/// [EmbeddingPort] that records every text it was asked to embed, so a test can
/// assert on the inference a run DID NOT do.
class _CountingEmbedder implements EmbeddingPort {
  final List<String> texts = [];

  @override
  bool get isReady => true;

  @override
  int get dimension => 4;

  @override
  Future<Float32List> embed(String text) async {
    texts.add(text);
    return Float32List.fromList([1, 0, 0, 0]);
  }

  @override
  Future<List<Float32List>> embedAll(List<String> texts) async => [
    for (final text in texts) await embed(text),
  ];
}
