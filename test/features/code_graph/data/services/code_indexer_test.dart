import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_file_ingest.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_index_checkpoint.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_subgraph.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_infra/src/code_graph/code_extractor.dart'
    show ExtractionResult;
import 'package:cc_infra/src/code_graph/code_indexer.dart';
import 'package:cc_infra/src/code_graph/extraction_isolate.dart'
    show ExtractionRequest;
import 'package:cc_natives/cc_natives.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Stub/fake implementations
// ---------------------------------------------------------------------------

class StubCodeGraphRepository implements CodeGraphRepository {
  StubCodeGraphRepository({
    Map<String, String>? fileHashes,
    List<StubIngestCall>? ingestCalls,
    List<StubDeleteCall>? deleteCalls,
    this._resolvePendingReferences = 0,
  }) : _fileHashes = fileHashes ?? const {},
       _ingestCalls = ingestCalls ?? [],
       _deleteCalls = deleteCalls ?? [];

  final Map<String, String> _fileHashes;
  final List<StubIngestCall> _ingestCalls;
  final List<StubDeleteCall> _deleteCalls;
  final int _resolvePendingReferences;

  @override
  Future<Map<String, String>> fileHashes(
    String ws,
    String repo, {
    String? checkoutId,
  }) async => Map.of(_fileHashes);

  @override
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStates(
    String ws,
    String repo, {
    String? checkoutId,
  }) async => {
    // Indexed in the distant past so the walker's mtime fast-path never
    // short-circuits and these tests exercise real hashing.
    for (final e in _fileHashes.entries)
      e.key: (contentHash: e.value, indexedAt: DateTime(2000)),
  };

  @override
  Future<bool> hasIndexedFiles(
    String ws,
    String repo, {
    String? checkoutId,
  }) async => _fileHashes.isNotEmpty;

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
  }) async {
    _ingestCalls.add(
      StubIngestCall(
        workspaceId: workspaceId,
        repoId: repoId,
        filePath: filePath,
        contentHash: contentHash,
        language: language,
      ),
    );
  }

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
  }) async {
    _deleteCalls.add(
      StubDeleteCall(
        workspaceId: workspaceId,
        repoId: repoId,
        filePaths: List.of(filePaths),
      ),
    );
  }

  @override
  Future<int> resolvePendingReferences(
    String ws,
    String repo, {
    String? checkoutId,
  }) async => _resolvePendingReferences;

  @override
  Future<int> countUnresolvedEdges(
    String ws,
    String repo, {
    String? checkoutId,
  }) async => _resolvePendingReferences;

  @override
  Future<CodeIndexCheckpointView> readCheckpoint(
    String ws,
    String repo, {
    String? checkoutId,
  }) async => const CodeIndexCheckpointView(own: null, baseGeneration: 0);

  @override
  Future<void> writeCheckpoint(CodeIndexCheckpoint checkpoint) async {}

  // Unused by code_indexer.
  @override
  Future<List<CodeSymbol>> search(
    String w,
    String r,
    String q, {
    Float32List? queryEmbedding,
    String? checkoutId,
  }) async => const [];
  @override
  Future<List<CodeSymbol>> callers(
    String w,
    String s, {
    int? limit,
    String? checkoutId,
  }) async => const [];
  @override
  Future<List<CodeSymbol>> callees(
    String w,
    String s, {
    int? limit,
    String? checkoutId,
  }) async => const [];
  @override
  Future<CodeSubgraph> impactRadius(
    String w,
    String s, {
    int depth = 2,
    String? checkoutId,
  }) async => const CodeSubgraph.empty();
  @override
  Future<CodeSymbol?> getById(String w, String id) async => null;
  @override
  Future<List<CodeSymbol>> getByName(
    String w,
    String r,
    String n, {
    int limit = 50,
    String? checkoutId,
  }) async => const [];
  @override
  Future<List<CodeSymbol>> symbolsForRepo(
    String w,
    String r, {
    String? checkoutId,
  }) async => const [];
  @override
  Stream<List<CodeSymbol>> watchByRepo(
    String w,
    String r, {
    String? checkoutId,
  }) => const Stream.empty();
}

class StubIngestCall {
  const StubIngestCall({
    required this.workspaceId,
    required this.repoId,
    required this.filePath,
    required this.contentHash,
    this.language,
  });
  final String workspaceId;
  final String repoId;
  final String filePath;
  final String contentHash;
  final String? language;
}

class StubDeleteCall {
  const StubDeleteCall({
    required this.workspaceId,
    required this.repoId,
    required this.filePaths,
  });
  final String workspaceId;
  final String repoId;
  final List<String> filePaths;
}

class StubGrammarManager implements GrammarManager {
  StubGrammarManager({Map<String, GrammarPaths?>? installResults})
    : _installResults = installResults ?? const {};

  final Map<String, GrammarPaths?> _installResults;

  @override
  Future<GrammarPaths?> install(
    String languageId, {
    GrammarSource? source,
    void Function(double, String)? onProgress,
    CancelToken? cancelToken,
  }) async => _installResults[languageId];

  @override
  Future<GrammarPaths?> resolve(String languageId) async => null;

  @override
  Future<String?> loadQuery(String queryId) async => null;

  @override
  Future<List<String>> artifactStamps() async => const [];

  @override
  Future<void> uninstall() async {}
}

class StubSourceFileWalker implements SourceFileWalker {
  StubSourceFileWalker({
    List<SourceFile>? walkResult,
    Map<String, String>? hashes,
    this.maxEntries = 50000,
  }) : _walkResult = walkResult ?? const [],
       _hashes = hashes ?? const {};

  final List<SourceFile> _walkResult;
  final Map<String, String> _hashes;

  @override
  final int maxEntries;

  @override
  Future<List<SourceFile>> walk(String rootPath) async => _walkResult;

  @override
  Future<String> hashFile(String absolutePath) async =>
      _hashes[absolutePath] ?? 'unknown-hash';

  @override
  Future<List<HashedSourceFile>> walkAndHash(
    String rootPath, {
    Map<String, IndexedFileState> known = const {},
  }) async => [
    for (final file in await walk(rootPath))
      HashedSourceFile(
        absolutePath: file.absolutePath,
        relativePath: file.relativePath,
        contentHash: await hashFile(file.absolutePath),
      ),
  ];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _wsId = 'ws1';
const _repoId = 'r1';
final _dumpRepoPath = Directory.systemTemp
    .createTempSync('code_idx_dummy_')
    .path;

/// Creates a temp directory populated with [files] (relative path → content).
Directory _createTempRepo(Map<String, String> files) {
  final dir = Directory.systemTemp.createTempSync('code_idx_test_');
  for (final entry in files.entries) {
    final f = File('${dir.path}/${entry.key}');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(entry.value);
  }
  return dir;
}

/// A canned source file fixture rooted at [basePath].
SourceFile _file(String basePath, String relativePath) => SourceFile(
  absolutePath: '$basePath/$relativePath',
  relativePath: relativePath,
);

/// Canned grammar path fixture.
const _grammarPaths = GrammarPaths(
  runtimePath: '/tmp/grammars/libtree-sitter.dylib',
  grammarPath: '/tmp/grammars/libtree-sitter-dart.dylib',
);

Future<String> _fakeQueryLoader(String queryId) async =>
    ';;; ($queryId-query)\n';

/// Stub extractor: production parses in a worker isolate with real tree-sitter
/// natives (and THROWS TreeSitterUnavailable when they can't load); tests
/// exercise the indexing flow itself, so each file just extracts to nothing.
Future<ExtractionResult> _stubExtractor(ExtractionRequest request) async =>
    const ExtractionResult.empty();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ---- Edge case: empty repo ----
  test('empty walk returns empty result with nativeAvailable=true', () async {
    final walker = StubSourceFileWalker(walkResult: []);
    final repo = StubCodeGraphRepository();
    final grammars = StubGrammarManager();

    final result = await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: _fakeQueryLoader,
      extractor: _stubExtractor,
    ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: _dumpRepoPath);

    expect(result.filesIndexed, 0);
    expect(result.filesSkipped, 0);
    expect(result.symbols, 0);
    expect(result.edges, 0);
    expect(result.removedFiles, 0);
    expect(result.resolvedReferences, 0);
    expect(result.nativeAvailable, isTrue);
    expect(result.skippedReason, isNull);
  });

  // ---- Edge case: all files have unrecognized extensions ----
  test('unindexable files produce nothing but nativeAvailable=true', () async {
    final walker = StubSourceFileWalker(
      walkResult: [
        _file(_dumpRepoPath, 'README.md'),
        _file(_dumpRepoPath, 'image.png'),
        _file(_dumpRepoPath, 'Makefile'),
      ],
    );
    final repo = StubCodeGraphRepository();
    final grammars = StubGrammarManager();

    final result = await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: _fakeQueryLoader,
      extractor: _stubExtractor,
    ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: _dumpRepoPath);

    expect(result.filesIndexed, 0);
    expect(result.nativeAvailable, isTrue);
  });

  // ---- Edge case: all files have matching content hashes ----
  test('unchanged files are skipped (hash match)', () async {
    final files = [
      _file(_dumpRepoPath, 'lib/a.dart'),
      _file(_dumpRepoPath, 'lib/b.dart'),
    ];
    final walker = StubSourceFileWalker(
      walkResult: files,
      hashes: {
        files[0].absolutePath: 'hash_a',
        files[1].absolutePath: 'hash_b',
      },
    );
    final grammars = StubGrammarManager(
      installResults: {'dart': _grammarPaths},
    );
    final repo = StubCodeGraphRepository(
      fileHashes: {'lib/a.dart': 'hash_a', 'lib/b.dart': 'hash_b'},
    );

    final progressEvents = <CodeIndexProgress>[];
    final result = await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: _fakeQueryLoader,
      extractor: _stubExtractor,
    ).indexRepo(
      workspaceId: _wsId,
      repoId: _repoId,
      repoPath: _dumpRepoPath,
      onProgress: progressEvents.add,
    );

    expect(result.filesIndexed, 0);
    expect(result.filesSkipped, 2);
    expect(result.symbols, 0);
    expect(result.edges, 0);
    // Silence is the "this run has no work" signal the watcher's reporter keys
    // off: it publishes a pipeline run on the first progress event, so a run
    // that indexes nothing must leave no row behind.
    expect(progressEvents, isEmpty);
  });

  // ---- Edge case: no grammar natives available at all ----
  test(
    'throws when no language has installable natives (broken install)',
    () async {
      final walker = StubSourceFileWalker(
        walkResult: [
          _file(_dumpRepoPath, 'lib/a.dart'),
          _file(_dumpRepoPath, 'src/b.ts'),
        ],
      );
      final grammars = StubGrammarManager(
        installResults: {'dart': null, 'typescript': null},
      );
      final repo = StubCodeGraphRepository();

      await expectLater(
        DefaultCodeIndexer(
          repository: repo,
          grammarManager: grammars,
          walker: walker,
          queryLoader: _fakeQueryLoader,
          extractor: _stubExtractor,
        ).indexRepo(
          workspaceId: _wsId,
          repoId: _repoId,
          repoPath: _dumpRepoPath,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('dart'), contains('typescript')),
          ),
        ),
      );
    },
  );

  // ---- Edge case: mixed — some languages install, some don't ----
  test('a MISSING grammar for one language fails the whole run', () async {
    // Every recognised language ships a grammar, so a resolvable-language /
    // missing-dylib combination is a broken install — not a language to skip.
    // Indexing on would write a graph that silently omits those files, and
    // "search found nothing" is indistinguishable from "there is nothing".
    // The failure names the language and the remediation.
    final repoDir = _createTempRepo({'lib/a.dart': 'void main() {}'});
    final repoPath = repoDir.path;
    addTearDown(() => repoDir.deleteSync(recursive: true));

    final dartFile = _file(repoPath, 'lib/a.dart');
    final tsFile = _file(repoPath, 'src/b.ts');
    final walker = StubSourceFileWalker(
      walkResult: [dartFile, tsFile],
      hashes: {dartFile.absolutePath: 'hash_a'},
    );
    final grammars = StubGrammarManager(
      installResults: {'dart': _grammarPaths, 'typescript': null},
    );
    final repo = StubCodeGraphRepository();

    await expectLater(
      DefaultCodeIndexer(
        repository: repo,
        grammarManager: grammars,
        walker: walker,
        queryLoader: _fakeQueryLoader,
        extractor: _stubExtractor,
      ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: repoPath),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('typescript'), contains('build_tree_sitter.sh')),
        ),
      ),
    );
  });

  // ---- Cancellation ----
  test(
    'cancellation stops indexing early and returns partial result',
    () async {
      final repoDir = _createTempRepo({
        'lib/a.dart': 'void main() {}',
        'lib/b.dart': 'void b() {}',
        'lib/c.dart': 'void c() {}',
      });
      final repoPath = repoDir.path;
      addTearDown(() => repoDir.deleteSync(recursive: true));

      final files = [
        _file(repoPath, 'lib/a.dart'),
        _file(repoPath, 'lib/b.dart'),
        _file(repoPath, 'lib/c.dart'),
      ];
      final hashes = <String, String>{};
      for (final f in files) {
        hashes[f.absolutePath] = 'hash_${f.relativePath}';
      }
      final walker = StubSourceFileWalker(walkResult: files, hashes: hashes);
      final grammars = StubGrammarManager(
        installResults: {'dart': _grammarPaths},
      );
      final ingestCalls = <StubIngestCall>[];
      final repo = StubCodeGraphRepository(ingestCalls: ingestCalls);

      var calls = 0;
      bool isCancelled() => ++calls >= 2;

      final result =
          await DefaultCodeIndexer(
            repository: repo,
            grammarManager: grammars,
            walker: walker,
            queryLoader: _fakeQueryLoader,
            extractor: _stubExtractor,
          ).indexRepo(
            workspaceId: _wsId,
            repoId: _repoId,
            repoPath: repoPath,
            isCancelled: isCancelled,
          );

      expect(result.filesIndexed, 1);
      expect(ingestCalls.length, 1);
      expect(ingestCalls[0].filePath, 'lib/a.dart');
    },
  );

  // ---- Progress callback ----
  test(
    'announces the work up front, then once per ingest batch',
    () async {
      final repoDir = _createTempRepo({
        'lib/a.dart': 'void main() {}',
        'lib/b.dart': 'void b() {}',
      });
      final repoPath = repoDir.path;
      addTearDown(() => repoDir.deleteSync(recursive: true));

      final files = [
        _file(repoPath, 'lib/a.dart'),
        _file(repoPath, 'lib/b.dart'),
      ];
      final hashes = <String, String>{};
      for (final f in files) {
        hashes[f.absolutePath] = 'hash_${f.relativePath}';
      }
      final walker = StubSourceFileWalker(walkResult: files, hashes: hashes);
      final grammars = StubGrammarManager(
        installResults: {'dart': _grammarPaths},
      );
      final repo = StubCodeGraphRepository();

      final progressEvents = <CodeIndexProgress>[];
      await DefaultCodeIndexer(
        repository: repo,
        grammarManager: grammars,
        walker: walker,
        queryLoader: _fakeQueryLoader,
        extractor: _stubExtractor,
      ).indexRepo(
        workspaceId: _wsId,
        repoId: _repoId,
        repoPath: repoPath,
        onProgress: progressEvents.add,
      );

      // The FIRST event fires before any parse, carrying the run's work count.
      // Everything after it rides an ingest flush — 32 files per transaction,
      // so both files here land in one batch. Without the up-front event a run
      // smaller than a batch (every incremental reindex) reported nothing until
      // it had already finished, leaving the pipeline step and the repo index
      // button blank for the whole slow part.
      expect(progressEvents, hasLength(2));
      expect(progressEvents.first.filesIndexed, 0);
      expect(progressEvents.first.filesToIndex, 2);
      expect(progressEvents.last.filesIndexed, 2);
      expect(progressEvents.last.filesToIndex, 2);
      expect(progressEvents.last.totalFiles, 2);
      // Monotonic and never over-counting, whatever the batch size.
      for (var i = 1; i < progressEvents.length; i++) {
        expect(
          progressEvents[i].filesIndexed,
          greaterThanOrEqualTo(progressEvents[i - 1].filesIndexed),
        );
      }
      expect(
        progressEvents.every((e) => e.filesIndexed <= e.filesToIndex),
        isTrue,
      );
    },
  );

  // ---- Pruning deleted files ----
  test('prunes files that no longer exist on disk', () async {
    // Use only unindexable files so byLanguage is empty — this avoids the
    // early "all skipped" return and lets prune code run.
    final walker = StubSourceFileWalker(
      walkResult: [_file(_dumpRepoPath, 'README.md')],
    );
    final grammars = StubGrammarManager();
    final deleteCalls = <StubDeleteCall>[];
    final repo = StubCodeGraphRepository(
      fileHashes: {
        'README.md': 'stale_hash',
        'lib/removed.dart': 'old_hash',
        'src/gone.ts': 'old_hash',
      },
      deleteCalls: deleteCalls,
    );

    await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: _fakeQueryLoader,
      extractor: _stubExtractor,
    ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: _dumpRepoPath);

    expect(deleteCalls.length, 1);
    expect(deleteCalls[0].workspaceId, _wsId);
    expect(deleteCalls[0].repoId, _repoId);
    expect(
      deleteCalls[0].filePaths,
      containsAll(['lib/removed.dart', 'src/gone.ts']),
    );
  });

  // ---- resolvePendingReferences flows through to result ----
  test('resolvePendingReferences count is reflected in result', () async {
    final walker = StubSourceFileWalker(walkResult: []);
    final grammars = StubGrammarManager();
    final repo = StubCodeGraphRepository(resolvePendingReferences: 42);

    final result = await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: _fakeQueryLoader,
      extractor: _stubExtractor,
    ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: _dumpRepoPath);

    expect(result.resolvedReferences, 42);
  });

  // ---- Edge case: some files changed, some unchanged (mixed hash) ----
  test('indexes changed files, skips unchanged ones', () async {
    final repoDir = _createTempRepo({'lib/a.dart': 'void main() {}'});
    final repoPath = repoDir.path;
    addTearDown(() => repoDir.deleteSync(recursive: true));

    final files = [
      _file(repoPath, 'lib/a.dart'),
      _file(repoPath, 'lib/b.dart'), // won't be read because hash matches
    ];
    final walker = StubSourceFileWalker(
      walkResult: files,
      hashes: {
        files[0].absolutePath: 'new_hash_a',
        files[1].absolutePath: 'old_hash_b',
      },
    );
    final grammars = StubGrammarManager(
      installResults: {'dart': _grammarPaths},
    );
    final ingestCalls = <StubIngestCall>[];
    final repo = StubCodeGraphRepository(
      fileHashes: {'lib/a.dart': 'old_hash_a', 'lib/b.dart': 'old_hash_b'},
      ingestCalls: ingestCalls,
    );

    final result = await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: _fakeQueryLoader,
      extractor: _stubExtractor,
    ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: repoPath);

    expect(result.filesIndexed, 1);
    expect(result.filesSkipped, 1);
    expect(ingestCalls.length, 1);
    expect(ingestCalls[0].filePath, 'lib/a.dart');
    expect(ingestCalls[0].contentHash, 'new_hash_a');
  });

  // ---- Full indexing flow ----
  test(
    'full indexing flow: walk, install, hash, extract, ingest, prune, resolve',
    () async {
      final repoDir = _createTempRepo({
        'lib/main.dart': 'void main() {}',
        'lib/utils.dart': 'int add(int a, int b) => a + b;',
      });
      final repoPath = repoDir.path;
      addTearDown(() => repoDir.deleteSync(recursive: true));

      final files = [
        _file(repoPath, 'lib/main.dart'),
        _file(repoPath, 'lib/utils.dart'),
        _file(repoPath, 'README.md'), // unindexable
      ];
      final walker = StubSourceFileWalker(
        walkResult: files,
        hashes: {
          files[0].absolutePath: 'hash_main',
          files[1].absolutePath: 'hash_utils',
        },
      );
      final grammars = StubGrammarManager(
        installResults: {'dart': _grammarPaths},
      );
      final ingestCalls = <StubIngestCall>[];
      final deleteCalls = <StubDeleteCall>[];
      final repo = StubCodeGraphRepository(
        fileHashes: {
          'lib/main.dart': 'old_hash_main',
          'lib/old_file.dart': 'stale',
        },
        ingestCalls: ingestCalls,
        deleteCalls: deleteCalls,
        resolvePendingReferences: 5,
      );

      final result = await DefaultCodeIndexer(
        repository: repo,
        grammarManager: grammars,
        walker: walker,
        queryLoader: _fakeQueryLoader,
        extractor: _stubExtractor,
      ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: repoPath);

      expect(result.filesIndexed, 2);
      expect(result.filesSkipped, 0);
      // symbols/edges are 0 because tree-sitter natives aren't installed in test,
      // so the isolate returns ExtractionResult.empty().
      expect(result.symbols, 0);
      expect(result.edges, 0);
      expect(result.removedFiles, 1);
      expect(result.resolvedReferences, 5);
      expect(result.nativeAvailable, isTrue);

      expect(ingestCalls.length, 2);
      expect(
        ingestCalls.map((c) => c.filePath),
        containsAll(['lib/main.dart', 'lib/utils.dart']),
      );

      expect(deleteCalls.length, 1);
      expect(deleteCalls[0].filePaths, ['lib/old_file.dart']);
    },
  );

  // ---- Edge case: only stale hashes, no current files ----
  test('prunes stale files even when no indexable files exist', () async {
    final walker = StubSourceFileWalker(walkResult: []);
    final grammars = StubGrammarManager();
    final deleteCalls = <StubDeleteCall>[];
    final repo = StubCodeGraphRepository(
      fileHashes: {'lib/old.dart': 'hash'},
      deleteCalls: deleteCalls,
    );

    await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: _fakeQueryLoader,
      extractor: _stubExtractor,
    ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: _dumpRepoPath);

    expect(deleteCalls.length, 1);
    expect(deleteCalls[0].filePaths, ['lib/old.dart']);
  });

  // ---- CodeIndexResult.skipped constructor ----
  test('CodeIndexResult.skipped has correct defaults', () {
    const skipped = CodeIndexResult.skipped('no natives for dart');
    expect(skipped.filesIndexed, 0);
    expect(skipped.filesSkipped, 0);
    expect(skipped.symbols, 0);
    expect(skipped.edges, 0);
    expect(skipped.removedFiles, 0);
    expect(skipped.resolvedReferences, 0);
    expect(skipped.nativeAvailable, isFalse);
    expect(skipped.skippedReason, 'no natives for dart');
  });

  // ---- CodeIndexProgress ----
  test('CodeIndexProgress holds correct values', () {
    const progress = CodeIndexProgress(
      filesIndexed: 3,
      filesToIndex: 4,
      totalFiles: 10,
      symbols: 42,
      edges: 7,
    );
    expect(progress.filesIndexed, 3);
    expect(progress.filesToIndex, 4);
    expect(progress.totalFiles, 10);
    expect(progress.symbols, 42);
    expect(progress.edges, 7);
  });

  // ---- QueryLoader override is used ----
  test('uses custom queryLoader instead of rootBundle', () async {
    final repoDir = _createTempRepo({'lib/a.dart': 'void main() {}'});
    final repoPath = repoDir.path;
    addTearDown(() => repoDir.deleteSync(recursive: true));

    final files = [_file(repoPath, 'lib/a.dart')];
    final walker = StubSourceFileWalker(
      walkResult: files,
      hashes: {files[0].absolutePath: 'hash_a'},
    );
    final grammars = StubGrammarManager(
      installResults: {'dart': _grammarPaths},
    );
    final repo = StubCodeGraphRepository();

    var loaderCalled = false;
    var receivedQueryId = '';
    await DefaultCodeIndexer(
      repository: repo,
      grammarManager: grammars,
      walker: walker,
      queryLoader: (queryId) async {
        loaderCalled = true;
        receivedQueryId = queryId;
        return ';;; (custom-query)\n';
      },
      extractor: _stubExtractor,
    ).indexRepo(workspaceId: _wsId, repoId: _repoId, repoPath: repoPath);

    expect(loaderCalled, isTrue);
    expect(receivedQueryId, 'dart');
  });
}
