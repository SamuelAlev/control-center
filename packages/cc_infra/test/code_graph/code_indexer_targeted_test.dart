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
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A TARGETED run is what makes "reindex on save" cost the size of the CHANGE
/// instead of the size of the CHECKOUT.
///
/// Before it, every watcher event re-ran the whole discovery pass — a
/// `git ls-files` plus a stat of every file in the tree, and a read of the
/// partition's entire `code_files` table (twice for a worktree: its own and the
/// base's). Measured on a 19k-file checkout that was 5-9 SECONDS per run to
/// index ONE saved file, ~90 times an hour while an agent worked, and 185s for
/// a single file once runs started contending.
///
/// These tests use the REAL [SourceFileWalker] over a REAL git work tree,
/// because the risk targeting introduces is not "is it faster" — it is whether
/// the narrow path can index something the full path would have excluded, or
/// prune something it should not have touched. Only git can answer the first
/// (`.gitignore` is per-project and the watcher's static ignore list knows
/// nothing about it).
/// The platform-native form of a repo-relative POSIX literal. The walker's
/// stored `filePath`s (and everything keyed by them) use native separators on
/// Windows, so every seed, handed path and expectation goes through here.
String _f(String posix) => p.joinAll(posix.split('/'));

void main() {
  late _RecordingRepo repo;
  late Directory tmp;

  /// Writes [path] with [contents] under the work tree.
  void write(String path, [String contents = 'class S {}']) {
    File('${tmp.path}/$path')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  DefaultCodeIndexer indexer() => DefaultCodeIndexer(
    repository: repo,
    grammarManager: _FakeGrammarManager(),
    queryLoader: (_) async => '(query)',
    // No `walker:` override — this suite is about what the REAL walker's
    // targeted path does and does not let through.
    probe: const _FakeProbe(
      RepoStateFingerprint(headSha: 'head', digest: 'digest', dirtyCount: 0),
    ),
    extractor: (request) async => ExtractionResult(
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
    ),
  );

  setUp(() async {
    repo = _RecordingRepo();
    tmp = Directory.systemTemp.createTempSync('code_indexer_targeted_');
    await Process.run('git', const ['init', '-q'], workingDirectory: tmp.path);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('reads and hashes only the paths it was handed', () async {
    // A checkout with more in it than the change — the whole point.
    write('lib/changed.dart');
    write('lib/untouched_a.dart');
    write('lib/untouched_b.dart');
    repo.stateByCheckout[null] = {
      _f('lib/changed.dart'): 'stale-hash',
      _f('lib/untouched_a.dart'): 'whatever',
      _f('lib/untouched_b.dart'): 'whatever',
    };

    final result = await indexer().indexRepo(
      workspaceId: 'ws1',
      repoId: 'repo1',
      repoPath: tmp.path,
      force: true,
      changedPaths: [_f('lib/changed.dart')],
    );

    expect(repo.ingestedPaths, [_f('lib/changed.dart')]);
    expect(result.filesIndexed, 1);
    expect(
      repo.fullPartitionReads,
      isEmpty,
      reason: 'a whole-partition read is the cost targeting exists to avoid',
    );
    expect(repo.scopedReads, [
      [_f('lib/changed.dart')],
    ]);
  });

  test('a full pass still reads the whole partition', () async {
    write('lib/a.dart');
    write('lib/b.dart');

    final result = await indexer().indexRepo(
      workspaceId: 'ws1',
      repoId: 'repo1',
      repoPath: tmp.path,
    );

    expect(result.filesIndexed, 2);
    expect(repo.scopedReads, isEmpty);
    expect(repo.fullPartitionReads, isNotEmpty);
  });

  test('an EMPTY path set takes the full pass, not an empty one', () async {
    // An event whose paths were all filtered out must not be read as "nothing
    // in this repo changed" — that would silently skip a real change.
    write('lib/a.dart');

    final result = await indexer().indexRepo(
      workspaceId: 'ws1',
      repoId: 'repo1',
      repoPath: tmp.path,
      force: true,
      changedPaths: const [],
    );

    expect(result.filesIndexed, 1);
    expect(repo.fullPartitionReads, isNotEmpty);
  });

  group('a targeted run applies every filter a full run does', () {
    test('honours .gitignore', () async {
      // The case only git can answer: a project-specific ignore rule the
      // watcher's static directory list knows nothing about. Indexing it here
      // would put symbols in the graph that a full pass then prunes back out.
      write('.gitignore', 'generated/\n');
      write('generated/ignored.dart');
      write('lib/kept.dart');

      await indexer().indexRepo(
        workspaceId: 'ws1',
        repoId: 'repo1',
        repoPath: tmp.path,
        force: true,
        changedPaths: [_f('generated/ignored.dart'), _f('lib/kept.dart')],
      );

      expect(repo.ingestedPaths, [_f('lib/kept.dart')]);
    });

    test('honours the generated-file filter', () async {
      write('lib/thing.g.dart');
      write('lib/thing.dart');

      await indexer().indexRepo(
        workspaceId: 'ws1',
        repoId: 'repo1',
        repoPath: tmp.path,
        force: true,
        changedPaths: [_f('lib/thing.g.dart'), _f('lib/thing.dart')],
      );

      expect(repo.ingestedPaths, [_f('lib/thing.dart')]);
    });

    test('drops a path whose extension is not indexable', () async {
      write('README.md');
      write('lib/real.dart');

      await indexer().indexRepo(
        workspaceId: 'ws1',
        repoId: 'repo1',
        repoPath: tmp.path,
        force: true,
        changedPaths: [_f('README.md'), _f('lib/real.dart')],
      );

      expect(repo.ingestedPaths, [_f('lib/real.dart')]);
    });
  });

  group('pruning stays inside the handed set', () {
    test('a deleted path is pruned', () async {
      write('lib/survivor.dart');
      repo.stateByCheckout[null] = {
        _f('lib/gone.dart'): 'hash',
        _f('lib/survivor.dart'): 'hash',
      };

      final result = await indexer().indexRepo(
        workspaceId: 'ws1',
        repoId: 'repo1',
        repoPath: tmp.path,
        force: true,
        // Deleted on disk, so `hashPaths` returns nothing for it.
        changedPaths: [_f('lib/gone.dart')],
      );

      expect(repo.deleted.single.$3, [_f('lib/gone.dart')]);
      expect(result.removedFiles, 1);
    });

    test('an untouched file is NEVER pruned, however stale', () async {
      // The failure this guards: `removed` is `existing - current`, and if
      // `existing` were still the whole partition while `current` held only the
      // changed path, one save would delete the entire rest of the index.
      write('lib/changed.dart');
      write('lib/untouched.dart');
      repo.stateByCheckout[null] = {
        _f('lib/changed.dart'): 'stale',
        _f('lib/untouched.dart'): 'stale',
      };

      final result = await indexer().indexRepo(
        workspaceId: 'ws1',
        repoId: 'repo1',
        repoPath: tmp.path,
        force: true,
        changedPaths: [_f('lib/changed.dart')],
      );

      expect(repo.deleted, isEmpty);
      expect(result.removedFiles, 0);
    });
  });

  test('a worktree still inherits from base without reading all of '
      'it', () async {
    write('lib/same.dart');
    write('lib/diverged.dart');
    // Both changed paths exist in base; only one still matches it.
    final hashes = await _hashesOf(tmp.path, [
      _f('lib/same.dart'),
      _f('lib/diverged.dart'),
    ]);
    repo.stateByCheckout[null] = {
      _f('lib/same.dart'): hashes[_f('lib/same.dart')]!,
      _f('lib/diverged.dart'): 'a-different-hash',
    };

    final result = await indexer().indexRepo(
      workspaceId: 'ws1',
      repoId: 'repo1',
      repoPath: tmp.path,
      checkoutId: 'wt1',
      force: true,
      changedPaths: [_f('lib/same.dart'), _f('lib/diverged.dart')],
    );

    expect(repo.ingestedPaths, [
      _f('lib/diverged.dart'),
    ], reason: 'a file byte-identical to base is left to the base partition');
    expect(result.filesSkipped, 1);
    expect(
      repo.fullPartitionReads,
      isEmpty,
      reason: 'the base comparison is scoped too — it was the second 19k read',
    );
  });

  test('a targeted run records the checkpoint', () async {
    // Deliberate: the fingerprint is probed BEFORE the run and describes the
    // whole tree, so writing it asserts the handed set explained every
    // difference. Not writing it would make the next arm-time pass re-walk the
    // checkout for changes this run already indexed.
    write('lib/a.dart');

    await indexer().indexRepo(
      workspaceId: 'ws1',
      repoId: 'repo1',
      repoPath: tmp.path,
      force: true,
      changedPaths: [_f('lib/a.dart')],
    );

    expect(repo.checkpoints, hasLength(1));
    expect(repo.checkpoints.values.single.headSha, 'head');
  });
}

/// The hashes the real walker computes for [paths], so a test can seed a
/// partition with a value that genuinely matches the bytes on disk.
Future<Map<String, String>> _hashesOf(String root, List<String> paths) async {
  final hashed = await const SourceFileWalker().hashPaths(root, paths);
  return {for (final file in hashed) file.relativePath: file.contentHash};
}

class _FakeProbe extends RepoStateProbe {
  const _FakeProbe(this.fingerprint);

  final RepoStateFingerprint? fingerprint;

  @override
  Future<RepoStateFingerprint?> probe(String repoPath) async => fingerprint;
}

class _FakeGrammarManager implements GrammarManager {
  @override
  Future<List<String>> artifactStamps() async => const ['stamp'];

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

/// Records WHICH reads the indexer made, not just what it returned — the whole
/// claim under test is that a targeted run never asks for a whole partition.
class _RecordingRepo implements CodeGraphRepository {
  /// checkoutId (null = linked) → path → stored hash.
  final Map<String?, Map<String, String>> stateByCheckout = {};
  final List<String> ingestedPaths = [];
  final List<(String, String, List<String>, String?)> deleted = [];
  final Map<String, CodeIndexCheckpoint> checkpoints = {};

  /// One entry per whole-partition read (`fileStates` / `fileHashes`).
  final List<String?> fullPartitionReads = [];

  /// The path list of each scoped read (`fileStatesFor` / `fileHashesFor`).
  final List<List<String>> scopedReads = [];

  Map<String, String> _partition(String? checkoutId) =>
      stateByCheckout[checkoutId] ?? const {};

  @override
  Future<Map<String, String>> fileHashes(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    fullPartitionReads.add(checkoutId);
    return _partition(checkoutId);
  }

  @override
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStates(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async {
    fullPartitionReads.add(checkoutId);
    return {
      for (final e in _partition(checkoutId).entries)
        // Indexed in the distant past, so the walker's mtime fast-path never
        // short-circuits and these tests exercise real hashing.
        e.key: (contentHash: e.value, indexedAt: DateTime(2000)),
    };
  }

  @override
  Future<Map<String, String>> fileHashesFor(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async {
    scopedReads.add(filePaths);
    final partition = _partition(checkoutId);
    return {
      for (final path in filePaths)
        if (partition.containsKey(path)) path: partition[path]!,
    };
  }

  @override
  Future<Map<String, ({String contentHash, DateTime indexedAt})>> fileStatesFor(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async {
    scopedReads.add(filePaths);
    final partition = _partition(checkoutId);
    return {
      for (final path in filePaths)
        if (partition.containsKey(path))
          path: (contentHash: partition[path]!, indexedAt: DateTime(2000)),
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
  }) async => CodeIndexCheckpointView(
    own: checkpoints['$workspaceId|$repoId|${checkoutId ?? ''}'],
    baseGeneration: checkpoints['$workspaceId|$repoId|']?.generation ?? 0,
  );

  @override
  Future<void> writeCheckpoint(CodeIndexCheckpoint checkpoint) async {
    checkpoints['${checkpoint.workspaceId}|${checkpoint.repoId}|'
            '${checkpoint.checkoutId ?? ''}'] =
        checkpoint;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
