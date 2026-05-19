import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_infra/src/code_graph/code_indexer.dart';
import 'package:cc_infra/src/code_graph/code_indexer_fingerprint.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:test/test.dart';

/// The checkpoint short-circuit is what makes an unchanged repo near-free at
/// boot: a matching (headSha, digest, toolchain fingerprint, base
/// generation) means the run returns before reading a single file-state row
/// or walking the tree. These tests pin BOTH directions — a full match skips
/// everything, and every kind of mismatch (head, digest, toolchain, stale
/// base, forced run, unprobeable repo) falls through to a real run.
void main() {
  late _CheckpointRepo repo;
  late _CountingWalker walker;
  late Directory tmp;

  setUp(() {
    repo = _CheckpointRepo();
    tmp = Directory.systemTemp.createTempSync('code_indexer_cp_');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Map<String, String> materialize(Map<String, String> tree) {
    for (final path in tree.keys) {
      File('${tmp.path}/$path')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('class S {}');
    }
    return tree;
  }

  DefaultCodeIndexer indexer({
    required Map<String, String> tree,
    RepoStateFingerprint? fingerprint,
    List<String> stamps = const ['stamp-1'],
    bool failExtraction = false,
  }) {
    walker = _CountingWalker(materialize(tree), tmp.path);
    return DefaultCodeIndexer(
      repository: repo,
      grammarManager: _StampedGrammarManager(stamps),
      queryLoader: (_) async => '(query)',
      walker: walker,
      probe: _FakeProbe(fingerprint),
      extractor: (request) async {
        if (failExtraction) {
          throw StateError('boom');
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
      },
    );
  }

  const fp = RepoStateFingerprint(
    headSha: 'head-1',
    digest: 'digest-1',
    dirtyCount: 0,
  );

  Future<String> fingerprintFor(List<String> stamps) async {
    // Same computation the indexer performs, via the same helper.
    return codeIndexerFingerprintForTest(stamps);
  }

  CodeIndexCheckpoint checkpoint({
    String? checkoutId,
    String headSha = 'head-1',
    String digest = 'digest-1',
    required String toolchain,
    int generation = 3,
    int baseGeneration = 0,
  }) => CodeIndexCheckpoint(
    workspaceId: 'ws1',
    repoId: 'repo1',
    checkoutId: checkoutId,
    headSha: headSha,
    worktreeDigest: digest,
    indexerFingerprint: toolchain,
    generation: generation,
    baseGeneration: baseGeneration,
    indexedAt: DateTime(2025),
  );

  test('a full checkpoint match skips the whole run', () async {
    final toolchain = await fingerprintFor(const ['stamp-1']);
    repo.checkpoints['ws1|repo1|'] = checkpoint(toolchain: toolchain);

    final result = await indexer(
      tree: {'a.dart': 'h1'},
      fingerprint: fp,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    expect(result.checkpointSkipped, isTrue);
    expect(result.nativeAvailable, isTrue);
    expect(repo.fileStatesCalls, 0, reason: 'no file-state read on a skip');
    expect(walker.walkCalls, 0, reason: 'no walk on a skip');
    expect(repo.resolveCalls, 0, reason: 'no reference resolution on a skip');
    expect(repo.ingestedPaths, isEmpty);
  });

  test('a head change falls through to a full run', () async {
    final toolchain = await fingerprintFor(const ['stamp-1']);
    repo.checkpoints['ws1|repo1|'] = checkpoint(
      headSha: 'OTHER',
      toolchain: toolchain,
    );

    final result = await indexer(
      tree: {'a.dart': 'h1'},
      fingerprint: fp,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    expect(result.checkpointSkipped, isFalse);
    expect(repo.ingestedPaths, ['a.dart']);
  });

  test('a digest change falls through to a full run', () async {
    final toolchain = await fingerprintFor(const ['stamp-1']);
    repo.checkpoints['ws1|repo1|'] = checkpoint(
      digest: 'OTHER',
      toolchain: toolchain,
    );

    final result = await indexer(
      tree: {'a.dart': 'h1'},
      fingerprint: fp,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    expect(result.checkpointSkipped, isFalse);
    expect(repo.ingestedPaths, ['a.dart']);
  });

  test(
    'a toolchain fingerprint change (new .scm / grammar) invalidates',
    () async {
      final oldToolchain = await fingerprintFor(const ['OLD-stamp']);
      repo.checkpoints['ws1|repo1|'] = checkpoint(toolchain: oldToolchain);

      final result = await indexer(
        tree: {'a.dart': 'h1'},
        fingerprint: fp,
        stamps: const ['stamp-1'],
      ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

      expect(result.checkpointSkipped, isFalse);
      expect(repo.ingestedPaths, ['a.dart']);
    },
  );

  test(
    'a worktree with a matching digest but a re-indexed base re-runs',
    () async {
      final toolchain = await fingerprintFor(const ['stamp-1']);
      // The worktree indexed against base generation 3...
      repo.checkpoints['ws1|repo1|wt1'] = checkpoint(
        checkoutId: 'wt1',
        toolchain: toolchain,
        baseGeneration: 3,
      );
      // ...but the base has since moved to generation 4.
      repo.checkpoints['ws1|repo1|'] = checkpoint(
        toolchain: toolchain,
        generation: 4,
      );

      final result = await indexer(tree: {'a.dart': 'h1'}, fingerprint: fp)
          .indexRepo(
            workspaceId: 'ws1',
            repoId: 'repo1',
            repoPath: tmp.path,
            checkoutId: 'wt1',
          );

      expect(
        result.checkpointSkipped,
        isFalse,
        reason: 'a base re-index invalidates every worktree delta',
      );
    },
  );

  test(
    'a worktree with a matching digest AND matching base gen skips',
    () async {
      final toolchain = await fingerprintFor(const ['stamp-1']);
      repo.checkpoints['ws1|repo1|wt1'] = checkpoint(
        checkoutId: 'wt1',
        toolchain: toolchain,
        baseGeneration: 4,
      );
      repo.checkpoints['ws1|repo1|'] = checkpoint(
        toolchain: toolchain,
        generation: 4,
      );

      final result = await indexer(tree: {'a.dart': 'h1'}, fingerprint: fp)
          .indexRepo(
            workspaceId: 'ws1',
            repoId: 'repo1',
            repoPath: tmp.path,
            checkoutId: 'wt1',
          );

      expect(result.checkpointSkipped, isTrue);
    },
  );

  test('force: true bypasses a matching checkpoint', () async {
    final toolchain = await fingerprintFor(const ['stamp-1']);
    repo.checkpoints['ws1|repo1|'] = checkpoint(toolchain: toolchain);

    final result = await indexer(tree: {'a.dart': 'h1'}, fingerprint: fp)
        .indexRepo(
          workspaceId: 'ws1',
          repoId: 'repo1',
          repoPath: tmp.path,
          force: true,
        );

    expect(
      result.checkpointSkipped,
      isFalse,
      reason: 'a watcher event is proof; the digest is only a fingerprint',
    );
    expect(repo.ingestedPaths, ['a.dart']);
  });

  test('a null probe runs in full and writes NO checkpoint', () async {
    final result = await indexer(
      tree: {'a.dart': 'h1'},
      fingerprint: null,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    expect(result.checkpointSkipped, isFalse);
    expect(repo.ingestedPaths, ['a.dart']);
    expect(
      repo.checkpoints,
      isEmpty,
      reason: 'no fingerprint → nothing trustworthy to record',
    );
  });

  test('a clean run writes a checkpoint with the probed fingerprint', () async {
    final toolchain = await fingerprintFor(const ['stamp-1']);
    await indexer(
      tree: {'a.dart': 'h1'},
      fingerprint: fp,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    final written = repo.checkpoints['ws1|repo1|'];
    expect(written, isNotNull);
    expect(written!.headSha, 'head-1');
    expect(written.worktreeDigest, 'digest-1');
    expect(written.indexerFingerprint, toolchain);
    expect(written.generation, 1, reason: 'rows changed → generation bumps');
  });

  test(
    'a run with extraction failures writes NO checkpoint (stays retryable)',
    () async {
      await indexer(
        tree: {'a.dart': 'h1'},
        fingerprint: fp,
        failExtraction: true,
      ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

      expect(
        repo.checkpoints,
        isEmpty,
        reason:
            'a timed-out/failed file must be retried on the next run, '
            'not frozen out until its content changes',
      );
    },
  );

  test('a no-op run does NOT bump the generation', () async {
    final toolchain = await fingerprintFor(const ['stamp-1']);
    // Digest mismatch forces a run, but every file hash matches → 0 indexed.
    repo.checkpoints['ws1|repo1|'] = checkpoint(
      digest: 'STALE',
      toolchain: toolchain,
      generation: 7,
    );
    repo.hashesByCheckout[null] = {'a.dart': 'h1'};

    await indexer(
      tree: {'a.dart': 'h1'},
      fingerprint: fp,
    ).indexRepo(workspaceId: 'ws1', repoId: 'repo1', repoPath: tmp.path);

    final written = repo.checkpoints['ws1|repo1|'];
    expect(
      written!.generation,
      7,
      reason:
          'a base run that changed nothing must not force all '
          'worktrees to re-walk',
    );
    expect(written.worktreeDigest, 'digest-1', reason: 'digest refreshed');
  });
}

/// Exposes the production fingerprint computation to the tests without a
/// real GrammarManager: same helper, same inputs.
Future<String> codeIndexerFingerprintForTest(List<String> stamps) =>
    codeIndexerFingerprint(_StampedGrammarManager(stamps));

class _FakeProbe extends RepoStateProbe {
  const _FakeProbe(this.fingerprint);

  final RepoStateFingerprint? fingerprint;

  @override
  Future<RepoStateFingerprint?> probe(String repoPath) async => fingerprint;
}

class _StampedGrammarManager implements GrammarManager {
  _StampedGrammarManager(this.stamps);

  final List<String> stamps;

  @override
  Future<List<String>> artifactStamps() async => stamps;

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

class _CountingWalker implements SourceFileWalker {
  _CountingWalker(this.tree, this.root);

  final Map<String, String> tree;
  final String root;
  int walkCalls = 0;

  @override
  Future<List<HashedSourceFile>> walkAndHash(
    String rootPath, {
    Map<String, IndexedFileState> known = const {},
  }) async {
    walkCalls++;
    return [
      for (final entry in tree.entries)
        HashedSourceFile(
          absolutePath: '$root/${entry.key}',
          relativePath: entry.key,
          contentHash: entry.value,
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CheckpointRepo implements CodeGraphRepository {
  final Map<String?, Map<String, String>> hashesByCheckout = {};
  final Map<String, CodeIndexCheckpoint> checkpoints = {};
  final List<String> ingestedPaths = [];
  int fileStatesCalls = 0;
  int resolveCalls = 0;

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
  }) async {
    fileStatesCalls++;
    return {
      for (final e in (hashesByCheckout[checkoutId] ?? const {}).entries)
        e.key: (contentHash: e.value, indexedAt: DateTime(2000)),
    };
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
  Future<void> ingestFiles(List<CodeFileIngest> files) async {
    for (final file in files) {
      ingestedPaths.add(file.filePath);
    }
  }

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
  }) async {
    resolveCalls++;
    return 0;
  }

  @override
  Future<int> countUnresolvedEdges(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => 0;

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
