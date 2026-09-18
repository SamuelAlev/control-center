import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/code_graph/code_graph_rpc.dart';
import 'package:test/test.dart';

const _ws = 'ws-1';
const _repoId = 'repo-1';

void main() {
  late FakeWorkspaceRepository workspaces;
  late _FakeGraph graph;
  late _FakeTree tree;
  late RepoOp op;

  setUp(() {
    workspaces = FakeWorkspaceRepository()
      ..seedRepos(_ws, [_repo(id: _repoId)]);
    graph = _FakeGraph();
    tree = _FakeTree();
    op = buildCodeGraphOps(
      workspaceRepository: workspaces,
      codeGraph: graph,
      tree: tree,
    ).singleWhere((o) => o.name == 'codeGraph.symbolLookup');
  });

  RepoOpContext ctx(Map<String, dynamic> args) => RepoOpContext(
    args: args,
    workspaceId: _ws,
    deviceId: 'dev-1',
    userId: 'user-1',
    role: WorkspaceRole.member,
  );

  test('refuses a repo that is not linked to the workspace', () async {
    await expectLater(
      op.handler(
        ctx({'workspace_id': _ws, 'repo_id': 'foreign', 'name': 'Foo'}),
      ),
      throwsA(isA<WorkspaceMismatchException>()),
    );
  });

  test('refuses an empty name', () async {
    await expectLater(
      op.handler(ctx({'workspace_id': _ws, 'repo_id': _repoId, 'name': '  '})),
      throwsA(isA<ValidationException>()),
    );
  });

  test('returns definitions, caller counts, and implementors', () async {
    final animal = _symbol(id: 'cls-1', name: 'Animal', kind: CodeSymbolKind.classKind);
    final dog = _symbol(id: 'cls-2', name: 'Dog', kind: CodeSymbolKind.classKind);
    final caller = _symbol(id: 'fn-1', name: 'walk');
    graph.byName['Animal'] = [animal];
    graph.callersById[animal.id] = [caller];
    graph.implementorsById[animal.id] = [dog];

    final data = await op.handler(
      ctx({
        'workspace_id': _ws,
        'repo_id': _repoId,
        'name': 'Animal',
        'space_id': 'space-1',
      }),
    );

    expect(data['from_base'], isFalse);
    expect(graph.lastCheckoutId, 'wt-1');
    final defs = data['definitions'] as List;
    expect(defs, hasLength(1));
    final def = defs.single as Map;
    expect(def['name'], 'Animal');
    expect(def['caller_count'], 1);
    expect(def['file_path'], 'lib/animal.dart');
    expect((def['implementors'] as List).single['name'], 'Dog');
  });

  test('fails open to the base partition when the worktree is empty', () async {
    graph.worktreeIndexed = false;
    graph.byName['Foo'] = [_symbol(id: 'fn-1', name: 'Foo')];

    final data = await op.handler(
      ctx({
        'workspace_id': _ws,
        'repo_id': _repoId,
        'name': 'Foo',
        'space_id': 'space-1',
      }),
    );

    expect(data['from_base'], isTrue);
    expect(graph.lastCheckoutId, isNull);
    expect((data['definitions'] as List).single['name'], 'Foo');
  });
}

Repo _repo({required String id}) => Repo(
  id: id,
  name: 'acme/app',
  path: '/repos/app',
  remoteOwner: 'acme',
  remoteName: 'app',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

CodeSymbol _symbol({
  required String id,
  required String name,
  CodeSymbolKind kind = CodeSymbolKind.function,
}) => CodeSymbol(
  id: id,
  workspaceId: _ws,
  repoId: _repoId,
  kind: kind,
  name: name,
  qualifiedName: 'pkg.$name',
  filePath: 'lib/${name.toLowerCase()}.dart',
  language: 'dart',
  startLine: 1,
  endLine: 8,
);

class _FakeTree implements CodeGraphTreePort {
  @override
  Future<String?> checkoutIdFor({
    required String workspaceId,
    required String repoId,
    String? spaceId,
  }) async => spaceId == null ? null : 'wt-1';

  @override
  Future<CodeGraphPathAudit?> audit({
    required String workspaceId,
    required String repoId,
    required List<String> paths,
    String? spaceId,
    String? checkoutId,
  }) async => null;
}

class _FakeGraph implements CodeGraphRepository {
  final Map<String, List<CodeSymbol>> byName = {};
  final Map<String, List<CodeSymbol>> callersById = {};
  final Map<String, List<CodeSymbol>> implementorsById = {};
  String? lastCheckoutId;
  bool worktreeIndexed = true;

  @override
  Future<bool> hasIndexedFiles(
    String workspaceId,
    String repoId, {
    String? checkoutId,
  }) async => worktreeIndexed;

  @override
  Future<List<CodeSymbol>> getByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit = 20,
    String? checkoutId,
  }) async {
    lastCheckoutId = checkoutId;
    final hits = byName[name] ?? const [];
    return hits.take(limit).toList();
  }

  @override
  Future<List<CodeSymbol>> callers(
    String workspaceId,
    String symbolId, {
    int? limit,
    String? checkoutId,
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
  }) async {
    final rows = kinds.contains(CodeEdgeKind.calls)
        ? (callersById[symbolId] ?? const [])
        : (implementorsById[symbolId] ?? const []);
    return limit == null ? rows : rows.take(limit).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
