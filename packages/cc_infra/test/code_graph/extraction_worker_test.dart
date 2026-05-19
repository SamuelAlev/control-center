import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_infra/src/code_graph/code_indexer.dart';
import 'package:cc_infra/src/code_graph/extraction_isolate.dart';
import 'package:cc_infra/src/code_graph/extraction_worker.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:test/test.dart';

/// The extraction worker replaced one throwaway `Isolate.run` PER FILE (each
/// re-resolving the tree-sitter dylibs and recompiling the whole `.scm`) with
/// ONE long-lived isolate per index run. That trade introduces exactly one new
/// failure mode the throwaway shape didn't have: a worker wedged inside a
/// native parse cannot serve the next file. These tests pin the reuse, the
/// lazy spawn and the kill-and-respawn recovery.
void main() {
  late Directory tmp;
  late _WorkerRepo repo;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('extraction_worker_');
    repo = _WorkerRepo();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Map<String, String> materialize(Iterable<String> paths) {
    final tree = <String, String>{};
    for (final path in paths) {
      File('${tmp.path}/$path')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('class S {}');
      tree[path] = 'hash-$path';
    }
    return tree;
  }

  DefaultCodeIndexer indexerWith({
    required Map<String, String> tree,
    required Future<ExtractionWorker> Function() workerFactory,
  }) => DefaultCodeIndexer(
    repository: repo,
    grammarManager: _StubGrammarManager(),
    queryLoader: (_) async => '(query)',
    walker: _StubWalker(tree, tmp.path),
    probe: const _NullProbe(),
    extractionWorkerFactory: workerFactory,
  );

  test('ONE worker serves every file of a run (not one per file)', () async {
    final factory = _CountingWorkerFactory();
    final tree = materialize(['a.dart', 'b.dart', 'c.dart']);

    final result = await indexerWith(
      tree: tree,
      workerFactory: factory.create,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    expect(result.filesIndexed, 3);
    expect(
      factory.spawned,
      1,
      reason: 'the whole point: dylibs + compiled queries are reused',
    );
    expect(factory.workers.single.extractCalls, 3);
    expect(
      factory.workers.single.disposed,
      isTrue,
      reason: 'a leaked worker holds native parser/query handles',
    );
  });

  test('a run with nothing to extract never spawns a worker', () async {
    final factory = _CountingWorkerFactory();
    // Every file's hash already matches what the partition holds.
    repo.knownHashes['a.dart'] = 'hash-a.dart';
    final tree = materialize(['a.dart']);

    final result = await indexerWith(
      tree: tree,
      workerFactory: factory.create,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    expect(result.filesSkipped, 1);
    expect(factory.spawned, 0, reason: 'the spawn is lazy, on first parse');
  });

  test('a wedged parse is killed and the NEXT file still extracts', () async {
    final factory = _CountingWorkerFactory(hangFirstExtract: true);
    final tree = materialize(['hangs.dart', 'after.dart']);

    final result = await indexerWith(
      tree: tree,
      workerFactory: factory.create,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    // The hung file failed, but the run continued on a FRESH worker — a
    // shared worker would otherwise be hostage to one pathological file.
    expect(factory.spawned, 2, reason: 'kill then respawn');
    expect(factory.workers.first.killed, isTrue);
    expect(result.filesIndexed, 1);
    expect(repo.ingestedPaths, ['after.dart']);
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('TreeSitterUnavailable from the worker fails the whole run', () async {
    final factory = _CountingWorkerFactory(unavailable: true);
    final tree = materialize(['a.dart']);

    await expectLater(
      indexerWith(
        tree: tree,
        workerFactory: factory.create,
      ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path),
      throwsA(isA<TreeSitterUnavailable>()),
      reason:
          'a broken install must fail loudly, not index everything to '
          'nothing',
    );
    expect(
      factory.workers.single.disposed,
      isTrue,
      reason: 'the finally must still release the worker',
    );
  });

  test('cancellation disposes the worker and keeps partial work', () async {
    final factory = _CountingWorkerFactory();
    final tree = materialize(['a.dart', 'b.dart', 'c.dart']);
    var calls = 0;

    final result = await indexerWith(tree: tree, workerFactory: factory.create)
        .indexRepo(
          workspaceId: 'ws1',
          repoId: 'repo1',
          repoPath: tmp.path,
          isCancelled: () => calls++ >= 2,
        );

    expect(factory.workers.single.disposed, isTrue);
    expect(result.filesIndexed, lessThan(3));
  });
}

/// A stand-in for [ExtractionWorker] that records reuse, hangs on demand and
/// distinguishes graceful dispose from a forced kill.
class _FakeWorker implements ExtractionWorker {
  _FakeWorker({this.hangFirstExtract = false, this.unavailable = false});

  final bool hangFirstExtract;
  final bool unavailable;
  int extractCalls = 0;
  bool disposed = false;
  bool killed = false;
  bool _dead = false;

  @override
  bool get isAlive => !_dead;

  @override
  Future<ExtractionResult> extract(ExtractionRequest request) async {
    extractCalls++;
    if (unavailable) {
      throw TreeSitterUnavailable('natives failed to load in the worker');
    }
    if (hangFirstExtract && extractCalls == 1) {
      // Never completes: the indexer's 30s timeout must fire and kill us.
      return Future.any([]);
    }
    return ExtractionResult(
      symbols: [
        CodeSymbol(
          id: 'sym:${request.filePath}',
          workspaceId: request.workspaceId,
          repoId: request.repoId,
          checkoutId: request.checkoutId,
          name: 'S',
          qualifiedName: 'S',
          kind: CodeSymbolKind.classKind,
          filePath: request.filePath,
          language: 'dart',
          startLine: 1,
          endLine: 2,
          signature: '',
        ),
      ],
      edges: const [],
    );
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    _dead = true;
  }

  @override
  Future<void> kill() async {
    killed = true;
    _dead = true;
  }
}

class _CountingWorkerFactory {
  _CountingWorkerFactory({
    this.hangFirstExtract = false,
    this.unavailable = false,
  });

  final bool hangFirstExtract;
  final bool unavailable;
  final List<_FakeWorker> workers = [];
  int get spawned => workers.length;

  Future<ExtractionWorker> create() async {
    // Only the FIRST worker hangs, so the respawn can make progress.
    final worker = _FakeWorker(
      hangFirstExtract: hangFirstExtract && workers.isEmpty,
      unavailable: unavailable,
    );
    workers.add(worker);
    return worker;
  }
}

class _NullProbe extends RepoStateProbe {
  const _NullProbe();

  @override
  Future<RepoStateFingerprint?> probe(String repoPath) async => null;
}

class _StubGrammarManager implements GrammarManager {
  @override
  Future<GrammarPaths?> install(
    String languageId, {
    GrammarSource? source,
    void Function(double progress, String phase)? onProgress,
    CancelToken? cancelToken,
  }) async => const GrammarPaths(runtimePath: '/rt', grammarPath: '/g');

  @override
  Future<List<String>> artifactStamps() async => const ['stamp'];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubWalker implements SourceFileWalker {
  _StubWalker(this.tree, this.root);

  final Map<String, String> tree;
  final String root;

  @override
  Future<List<HashedSourceFile>> walkAndHash(
    String rootPath, {
    Map<String, IndexedFileState> known = const {},
  }) async => [
    for (final entry in tree.entries)
      HashedSourceFile(
        absolutePath: '$root/${entry.key}',
        relativePath: entry.key,
        contentHash: entry.value,
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WorkerRepo implements CodeGraphRepository {
  final Map<String, String> knownHashes = {};
  final List<String> ingestedPaths = [];

  @override
  Future<Map<String, String>> fileHashes(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => const {};

  @override
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStates(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => {
    for (final e in knownHashes.entries)
      e.key: (contentHash: e.value, indexedAt: DateTime(2000)),
  };

  @override
  Future<void> ingestFiles(List<CodeFileIngest> files) async {
    for (final file in files) {
      ingestedPaths.add(file.filePath);
    }
  }

  @override
  Future<void> ingestFile({
    required String workspaceId,
    required String repoId,
    String? checkoutId,
    required String filePath,
    required String contentHash,
    required List<CodeSymbol> symbols,
    required List<CodeEdge> edges,
    String language = 'dart',
  }) async => ingestedPaths.add(filePath);

  @override
  Future<void> deleteFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async {}

  @override
  Future<int> resolvePendingReferences(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => 0;

  @override
  Future<int> countUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => 0;

  @override
  Future<int> pruneUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => 0;

  @override
  Future<CodeIndexCheckpointView> readCheckpoint(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => const CodeIndexCheckpointView(own: null, baseGeneration: 0);

  @override
  Future<void> writeCheckpoint(CodeIndexCheckpoint checkpoint) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
