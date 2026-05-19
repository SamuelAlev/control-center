import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_infra/src/code_graph/code_indexer.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:test/test.dart';

/// A worktree partition stores only its DELTA against the linked checkout.
///
/// Measured on a real database, 88% of the files a worktree indexed were
/// byte-identical to the linked checkout, so a full per-worktree graph
/// duplicated ~350k symbols and their embeddings across 78 partitions for no
/// new information. These tests pin that the indexer leaves identical files to
/// the base partition, still indexes everything for the linked checkout, and
/// evicts a file from the delta once it matches base again.
void main() {
  late _FakeRepo repo;
  late Directory tmp;

  /// Materializes [tree]'s paths on disk — the indexer reads each changed
  /// file's source to extract from it, so the files must really exist.
  Map<String, String> materialize(Map<String, String> tree) {
    for (final path in tree.keys) {
      File('${tmp.path}/$path')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('class S {}');
    }
    return tree;
  }

  DefaultCodeIndexer indexerOver(Map<String, String> tree) =>
      DefaultCodeIndexer(
        repository: repo,
        grammarManager: _FakeGrammarManager(),
        queryLoader: (_) async => '(query)',
        walker: _FakeWalker(materialize(tree), tmp.path),
        extractor: (request) async => ExtractionResult(
          symbols: [
            CodeSymbol(
              id: 'sym:${request.checkoutId ?? 'base'}:${request.filePath}',
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
        ),
      );

  setUp(() {
    repo = _FakeRepo();
    tmp = Directory.systemTemp.createTempSync('code_indexer_delta_');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test(
    'a worktree skips files byte-identical to the linked checkout',
    () async {
      repo.hashesByCheckout[null] = {
        'same.dart': 'hash-same',
        'changed.dart': 'hash-old',
      };
      final result =
          await indexerOver({
            'same.dart':
                'hash-same', // identical to base → base's rows serve it
            'changed.dart': 'hash-new', // diverged → the worktree owns it
            'only_here.dart':
                'hash-new-file', // absent from base → worktree owns it
          }).indexRepo(
            workspaceId: 'ws1',
            repoId: 'repo1',
            repoPath: '/wt',
            checkoutId: 'wt1',
          );

      expect(repo.ingestedPaths, ['changed.dart', 'only_here.dart']);
      expect(result.filesIndexed, 2);
      // The inherited file counts as skipped work, not as indexed.
      expect(result.filesSkipped, 1);
    },
  );

  test('the linked checkout still indexes everything', () async {
    final result = await indexerOver({
      'a.dart': 'h1',
      'b.dart': 'h2',
    }).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: '/linked');

    expect(repo.ingestedPaths, ['a.dart', 'b.dart']);
    expect(result.filesIndexed, 2);
  });

  test('a file that becomes identical to base again leaves the delta', () async {
    repo.hashesByCheckout[null] = {'f.dart': 'hash-base'};
    // The worktree previously diverged on f.dart, so it owns a row for it.
    repo.hashesByCheckout['wt1'] = {'f.dart': 'hash-worktree'};

    // Now the worktree's copy matches base again (reverted, or base caught up).
    final result = await indexerOver({'f.dart': 'hash-base'}).indexRepo(
      workspaceId: 'ws1',
      repoId: 'repo1',
      repoPath: '/wt',
      checkoutId: 'wt1',
    );

    expect(repo.ingestedPaths, isEmpty);
    expect(repo.deleted, hasLength(1));
    expect(repo.deleted.single.$3, [
      'f.dart',
    ], reason: 'a stale delta row would keep shadowing the base copy');
    expect(repo.deleted.single.$4, 'wt1');
    expect(result.removedFiles, 1);
  });

  test('an unchanged worktree indexes nothing at all', () async {
    repo.hashesByCheckout[null] = {'a.dart': 'h1', 'b.dart': 'h2'};
    final result = await indexerOver({'a.dart': 'h1', 'b.dart': 'h2'})
        .indexRepo(
          workspaceId: 'ws1',
          repoId: 'repo1',
          repoPath: '/wt',
          checkoutId: 'wt1',
        );

    expect(repo.ingestedPaths, isEmpty);
    expect(result.filesIndexed, 0);
    expect(result.filesSkipped, 2);
  });
}

class _FakeWalker implements SourceFileWalker {
  _FakeWalker(this.tree, this.root);

  /// relativePath → content hash.
  final Map<String, String> tree;

  /// Where [tree]'s files actually live on disk.
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

class _FakeGrammarManager implements GrammarManager {
  @override
  Future<GrammarPaths?> install(
    String languageId, {
    GrammarSource? source,
    void Function(double progress, String phase)? onProgress,
    CancelToken? cancelToken,
  }) async => const GrammarPaths(runtimePath: '/rt', grammarPath: '/g');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepo implements CodeGraphRepository {
  /// checkoutId (null = linked) → path → hash already in that partition.
  final Map<String?, Map<String, String>> hashesByCheckout = {};
  final List<String> ingestedPaths = [];
  final List<(String, String, List<String>, String?)> deleted = [];

  @override
  Future<Map<String, String>> fileHashes(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => hashesByCheckout[checkoutId] ?? const {};

  @override
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStates(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => {
    for (final e in (hashesByCheckout[checkoutId] ?? const {}).entries)
      // Indexed in the distant past, so the walker's mtime fast-path never
      // short-circuits here and these tests exercise real hashing.
      e.key: (contentHash: e.value, indexedAt: DateTime(2000)),
  };

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
  Future<void> ingestFiles(List<CodeFileIngest> files) async {
    for (final file in files) {
      await ingestFile(
        workspaceId: file.workspaceId,
        repoId: file.repoId,
        checkoutId: file.checkoutId,
        filePath: file.filePath,
        contentHash: file.contentHash,
        symbols: file.symbols,
        edges: file.edges,
        language: file.language,
      );
    }
  }

  @override
  Future<void> deleteFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async => deleted.add((workspaceId, repoId, filePaths, checkoutId));

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

  final Map<String, CodeIndexCheckpoint> checkpoints = {};

  @override
  Future<CodeIndexCheckpointView> readCheckpoint(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    final own = checkpoints['$workspaceId|$repoId|${checkoutId ?? ''}'];
    final base = checkpoints['$workspaceId|$repoId|'];
    return CodeIndexCheckpointView(
      own: own,
      baseGeneration: base?.generation ?? 0,
    );
  }

  @override
  Future<void> writeCheckpoint(CodeIndexCheckpoint checkpoint) async {
    checkpoints['${checkpoint.workspaceId}|${checkpoint.repoId}|'
            '${checkpoint.checkoutId ?? ''}'] =
        checkpoint;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
