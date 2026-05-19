import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_mcp/src/tools/code_graph_tools.dart';
import 'package:cc_server_core/src/code_graph_tree_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The code graph is built from the linked checkout and only refreshed by a
/// re-index, so it drifts: `search_code` used to answer with paths that had been
/// renamed or deleted weeks earlier, and the agent then burned turns on
/// "File not found". These tests pin the verification that stops that, and the
/// isolation rule that keeps one conversation's branch from erasing the index.
void main() {
  const workspaceId = 'ws-1';
  const repoId = 'repo-1';
  const conversationId = 'conv-1';

  late Directory temp;
  late Directory checkout; // the linked checkout the index describes
  late Directory worktree; // the conversation's isolated copy
  late _FakeCodeGraphRepo graph;
  late CodeGraphTreeService tree;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('code_graph_stale_');
    checkout = Directory(p.join(temp.path, 'checkout'))..createSync();
    worktree = Directory(p.join(temp.path, 'worktree'))..createSync();
    // `live.dart` is in both trees; `branch_only.dart` exists in the checkout
    // but not in this conversation's copy; `gone.dart` exists in neither.
    for (final root in [checkout, worktree]) {
      File(p.join(root.path, 'lib', 'live.dart'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('class Live {}');
    }
    File(
      p.join(checkout.path, 'lib', 'branch_only.dart'),
    ).writeAsStringSync('class BranchOnly {}');

    graph = _FakeCodeGraphRepo([
      _symbol('Live', 'lib/live.dart'),
      _symbol('BranchOnly', 'lib/branch_only.dart'),
      _symbol('Gone', 'lib/gone.dart'),
    ]);
    final workspaces = _FakeWorkspaceRepo()..linked[workspaceId] = {repoId};
    final isolated = _FakeIsolatedRepoRepo()
      ..byChannel['$workspaceId:$conversationId'] = [
        _isolatedRepo(repoId, worktree.path),
      ];
    tree = CodeGraphTreeService(
      repoRepository: _FakeRepoRepo({repoId: _repo(repoId, checkout.path)}),
      workspaceRepository: workspaces,
      isolatedRepoRepository: isolated,
    );
  });

  tearDown(() => temp.deleteSync(recursive: true));

  SearchCodeTool searchTool({bool verify = true}) => SearchCodeTool(
    repository: graph,
    workspaceRepository: _FakeWorkspaceRepo()..linked[workspaceId] = {repoId},
    tree: verify ? tree : null,
  );

  Future<Map<String, dynamic>> run(
    SearchCodeTool tool, {
    String? conversation,
  }) async {
    final result = await tool.run({
      'workspace_id': workspaceId,
      'repo_id': repoId,
      'query': 'x',
      'mode': 'keyword',
      'conversation_id': ?conversation,
    });
    final text = result.content.map((c) => c.text).join();
    expect(result.isError, isFalse, reason: text);
    return jsonDecode(text) as Map<String, dynamic>;
  }

  test('hides symbols whose file is gone from the conversation copy', () async {
    final json = await run(searchTool(), conversation: conversationId);
    expect(
      [for (final s in json['symbols'] as List) (s as Map)['filePath']],
      ['lib/live.dart'],
    );
    expect(json['staleOmitted'], 2);
    expect(json['note'], contains('search_files'));
  });

  test(
    'prunes only rows the INDEXED checkout lost, never a branch difference',
    () async {
      await run(searchTool(), conversation: conversationId);
      // `gone.dart` is absent from the checkout the index was built from → dead
      // row, pruned. `branch_only.dart` is missing from this conversation's copy
      // but still in the checkout → hidden from this caller, kept in the index,
      // or one conversation's branch would erase the shared graph.
      expect(graph.deleted, hasLength(1));
      expect(graph.deleted.single.workspaceId, workspaceId);
      expect(graph.deleted.single.repoId, repoId);
      expect(graph.deleted.single.paths, ['lib/gone.dart']);
    },
  );

  test(
    'without a conversation, verifies against the linked checkout',
    () async {
      final json = await run(searchTool());
      expect(
        [for (final s in json['symbols'] as List) (s as Map)['filePath']],
        ['lib/live.dart', 'lib/branch_only.dart'],
      );
      expect(json['staleOmitted'], 1);
    },
  );

  test('serves everything unverified when no tree port is wired', () async {
    final json = await run(
      searchTool(verify: false),
      conversation: conversationId,
    );
    expect(json['symbols'] as List, hasLength(3));
    expect(json.containsKey('staleOmitted'), isFalse);
    expect(graph.deleted, isEmpty);
  });

  test(
    'an unresolvable repo fails open instead of returning nothing',
    () async {
      // Repo not linked to the workspace → no tree resolves → serve unfiltered
      // rather than pretend the repo is empty.
      final unlinked = CodeGraphTreeService(
        repoRepository: _FakeRepoRepo(const {}),
        workspaceRepository: _FakeWorkspaceRepo(),
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
      );
      final json = await run(
        SearchCodeTool(
          repository: graph,
          workspaceRepository: _FakeWorkspaceRepo()
            ..linked[workspaceId] = {repoId},
          tree: unlinked,
        ),
      );
      expect(json['symbols'] as List, hasLength(3));
      expect(graph.deleted, isEmpty);
    },
  );

  test('a verification failure never breaks the search', () async {
    final json = await run(
      SearchCodeTool(
        repository: graph,
        workspaceRepository: _FakeWorkspaceRepo()
          ..linked[workspaceId] = {repoId},
        tree: _ThrowingTree(),
      ),
    );
    expect(json['symbols'] as List, hasLength(3));
  });
}

CodeSymbol _symbol(String name, String filePath) => CodeSymbol(
  id: 'sym-$name',
  workspaceId: 'ws-1',
  repoId: 'repo-1',
  name: name,
  qualifiedName: name,
  kind: CodeSymbolKind.classKind,
  filePath: filePath,
  language: 'dart',
  startLine: 1,
  endLine: 2,
  signature: 'class $name',
);

Repo _repo(String id, String path) => Repo(
  id: id,
  name: 'repo',
  path: path,
  githubOwner: 'acme',
  githubRepoName: 'repo',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

IsolatedRepo _isolatedRepo(String repoId, String path) => IsolatedRepo(
  id: 'iso-$repoId',
  workspaceId: 'ws-1',
  channelId: 'conv-1',
  repoId: repoId,
  path: path,
  branch: 'main',
  backend: RepoIsolationBackend.rift,
  sourcePath: '/src/$repoId',
  createdAt: DateTime(2025),
);

class _FakeCodeGraphRepo implements CodeGraphRepository {
  _FakeCodeGraphRepo(this._symbols);

  final List<CodeSymbol> _symbols;
  final deleted = <({String workspaceId, String repoId, List<String> paths})>[];

  /// No worktree partition has been built, so every call here resolves to the
  /// linked partition — the pre-partition path these tests pin.
  @override
  Future<bool> hasIndexedFiles(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => false;

  @override
  Future<List<CodeSymbol>> search(
    String workspaceId,
    String repoId,
    String query, {
    Object? queryEmbedding,
    int limit = 20,
    String? checkoutId,
  }) async => _symbols;

  @override
  Future<void> deleteFiles(
    String workspaceId,
    String repoId,
    List<String> filePaths, {
    String? checkoutId,
  }) async =>
      deleted.add((workspaceId: workspaceId, repoId: repoId, paths: filePaths));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingTree implements CodeGraphTreePort {
  @override
  Future<String?> checkoutIdFor({
    required String workspaceId,
    required String repoId,
    String? conversationId,
  }) => throw StateError('filesystem unavailable');

  @override
  Future<CodeGraphPathAudit?> audit({
    required String workspaceId,
    required String repoId,
    required List<String> paths,
    String? conversationId,
    String? checkoutId,
  }) => throw StateError('filesystem unavailable');
}

class _FakeRepoRepo implements RepoRepository {
  _FakeRepoRepo(this._byId);
  final Map<String, Repo> _byId;

  @override
  Future<Repo?> getById(String workspaceId, String id) =>
      Future.value(_byId[id]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkspaceRepo implements WorkspaceRepository {
  final Map<String, Set<String>> linked = {};

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      Future.value(linked[workspaceId]?.contains(repoId) ?? false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIsolatedRepoRepo implements IsolatedRepoRepository {
  final Map<String, List<IsolatedRepo>> byChannel = {};

  @override
  Future<List<IsolatedRepo>> forChannel(String workspaceId, String channelId) =>
      Future.value(byChannel['$workspaceId:$channelId'] ?? const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
