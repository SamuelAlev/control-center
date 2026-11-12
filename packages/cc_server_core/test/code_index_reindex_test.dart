import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/dao_code_graph_repository.dart';
import 'package:rhttp/rhttp.dart' show CancelToken;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The code index is disposable: an install upgrading to a separate
/// `code_index.db` starts with an empty one, and a damaged file is replaced by
/// an empty one. Neither is repaired; both rely on the next ordinary,
/// unforced run of the indexer noticing that the partition has no checkpoint
/// and indexing it in full. These tests run the real indexer over the real
/// repository and file-backed manager to pin that.
void main() {
  late Directory tmp;
  late Directory checkout;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _CountingWalker walker;

  WorkspaceDatabaseManager manager() =>
      WorkspaceDatabaseManager(dataDir: '${tmp.path}/data', global: global);

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('code_index_reindex_');
    checkout = Directory('${tmp.path}/checkout')..createSync();
    File('${checkout.path}/a.dart').writeAsStringSync('class S {}');
    walker = _CountingWalker(checkout.path, {'a.dart': 'h1'});
    global = createTestGlobalDatabase();
    dbs = manager();
    await seedTestWorkspace(global, dbs, 'ws1');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
    tmp.deleteSync(recursive: true);
  });

  DefaultCodeIndexer indexer() => DefaultCodeIndexer(
    repository: DaoCodeGraphRepository(dbs),
    grammarManager: _FakeGrammarManager(),
    queryLoader: (_) async => '(query)',
    walker: walker,
    probe: const _FakeProbe(
      RepoStateFingerprint(headSha: 'head-1', digest: 'd-1', dirtyCount: 0),
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

  Future<CodeIndexResult> run() => indexer().indexRepo(
    workspaceId: 'ws1',
    repoId: 'repo1',
    repoPath: checkout.path,
  );

  Future<List<String>> symbolIds() async => [
    for (final row
        in await dbs.codeIndexOf('ws1').codeGraphDao.getSymbolsByRepo('repo1'))
      row.id,
  ];

  /// Indexes the checkout once, then proves the unchanged repo is skipped,
  /// so a later full pass can only come from the missing checkpoint.
  Future<void> indexAndSettle() async {
    expect((await run()).filesIndexed, 1);
    final second = await run();
    expect(second.checkpointSkipped, isTrue);
    expect(walker.walkCalls, 1);
    expect(await symbolIds(), ['sym:a.dart']);
  }

  Future<void> expectFullPassAfterRestart() async {
    dbs = manager();
    final result = await run();
    expect(result.checkpointSkipped, isFalse);
    expect(result.filesIndexed, 1);
    expect(walker.walkCalls, 2);
    expect(await symbolIds(), ['sym:a.dart']);
    expect(
      await dbs.codeIndexOf('ws1').codeGraphDao.getCheckpointRows('repo1'),
      hasLength(1),
      reason: 'the next run is skipped again',
    );
  }

  test('a missing code index is filled by the next unforced run', () async {
    await indexAndSettle();
    final path = dbs.codeIndexPathFor('ws1');
    await dbs.closeAll();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('$path$suffix');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    await expectFullPassAfterRestart();
  });

  test('a code index replaced for damage is filled by the next unforced '
      'run', () async {
    await indexAndSettle();
    final path = dbs.codeIndexPathFor('ws1');
    await dbs.closeAll();
    for (final suffix in const ['-wal', '-shm']) {
      final file = File('$path$suffix');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    File(path).writeAsStringSync('not a database, just bytes' * 400);

    await expectFullPassAfterRestart();
  });
}

class _FakeProbe extends RepoStateProbe {
  const _FakeProbe(this.fingerprint);

  final RepoStateFingerprint fingerprint;

  @override
  Future<RepoStateFingerprint?> probe(String repoPath) async => fingerprint;
}

class _FakeGrammarManager implements GrammarManager {
  @override
  Future<List<String>> artifactStamps() async => const ['stamp-1'];

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
  _CountingWalker(this.root, this.tree);

  final String root;
  final Map<String, String> tree;
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
