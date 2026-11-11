import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_repo_gate.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart'
    show CallResult;
import 'package:cc_domain/testing/fake_repo_repository.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart' show repoToWire;
import 'package:cc_server_core/src/catalog/repo_link_ops.dart';
import 'package:cc_server_core/src/code_graph/code_graph_rpc.dart';
import 'package:cc_server_core/src/repo_path_guard.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _ws = 'ws-a';
const _owner = 'u-owner';

/// A repository's code graph is read only while the repository is linked and
/// its checkout served. A host-path row nobody accountable linked keeps its
/// index, but `search_code`, `code_symbol`, the symbol traversals and the
/// `codeGraph.*` ops neither search it nor list it, until the server owner
/// links it again.
void main() {
  late Directory root;
  late String hostCheckout;
  late FakeRepoRepository repos;
  late _Graph graph;
  late RepoPathGuard guard;
  late CodeGraphRepoGate gate;

  Repo row({String linkedBy = ''}) => Repo(
    id: 'r1',
    name: 'acme/api',
    path: hostCheckout,
    remoteOwner: 'acme',
    remoteName: 'api',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    linkedBy: linkedBy,
  );

  setUp(() {
    root = Directory(
      Directory.systemTemp
          .createTempSync('cc_code_graph_served_')
          .resolveSymbolicLinksSync(),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final dataDir = p.join(root.path, 'data');
    Directory(p.join(dataDir, _ws)).createSync(recursive: true);
    hostCheckout = p.join(root.path, 'host', 'api');
    Directory(hostCheckout).createSync(recursive: true);
    guard = RepoPathGuard(
      dataDir: dataDir,
      workspaceDir: (ws) async => p.join(dataDir, ws),
      serverOwnerUserId: _owner,
    );
    // Indexed while the owner's link stood, then the row lost its linker
    // (stored before linkers were recorded, or imported).
    repos = FakeRepoRepository()..seed(_ws, [row()]);
    final workspaces = FakeWorkspaceRepository()..seedRepos(_ws, [row()]);
    graph = _Graph();
    gate = servedCodeGraphRepos(
      workspaces: workspaces,
      repos: repos,
      guard: guard,
    );
  });

  Future<CallResult> search() => SearchCodeTool(
    repository: graph,
    repoGate: gate,
  ).call({'workspace_id': _ws, 'repo_id': 'r1', 'query': 'Secret'});

  Future<CallResult> symbol() => CodeSymbolTool(
    repository: graph,
    repoGate: gate,
  ).call({'workspace_id': _ws, 'repo_id': 'r1', 'name': 'Secret'});

  Future<CallResult> callers() => CodeCallersTool(
    repository: graph,
    repoGate: gate,
  ).call({'workspace_id': _ws, 'symbol_id': 's2'});

  Future<Map<String, dynamic>> lookup() =>
      buildCodeGraphOps(repoGate: gate, codeGraph: graph)
          .singleWhere((o) => o.name == 'codeGraph.symbolLookup')
          .handler(
            const RepoOpContext(
              args: {'workspace_id': _ws, 'repo_id': 'r1', 'name': 'Secret'},
              workspaceId: _ws,
              deviceId: 'd',
              userId: 'u-mo',
              role: WorkspaceRole.member,
            ),
          );

  List<Object?> symbolsOf(CallResult r, String key) =>
      (jsonDecode(r.content.single.text) as Map<String, dynamic>)[key]
          as List<Object?>;

  test('an unserved repository is neither searched nor listed', () async {
    for (final r in [await search(), await symbol(), await callers()]) {
      expect(r.isError, isTrue);
    }
    await expectLater(lookup(), throwsA(anything));
    expect(graph.read, isEmpty);
  });

  test('after the owner relinks it, it is read again', () async {
    final ops = <String, RepoOp>{
      for (final op in buildRepoLinkOps(
        repos: repos,
        requireRepoRead:
            ({required workspaceId, required userId, required repoId}) async {},
        members: null,
        pathGuard: guard,
        inspector: _Inspector(),
      ))
        op.name: op,
    };
    await ops['repos.upsert']!.handler(
      RepoOpContext(
        args: {'repo': repoToWire(row())},
        workspaceId: _ws,
        deviceId: 'd',
        userId: _owner,
        role: WorkspaceRole.owner,
      ),
    );
    expect((await repos.getById(_ws, 'r1'))!.linkedBy, _owner);

    expect(symbolsOf(await search(), 'symbols'), hasLength(1));
    expect(symbolsOf(await symbol(), 'symbols'), hasLength(1));
    expect(symbolsOf(await callers(), 'callers'), hasLength(1));
    expect((await lookup())['definitions'] as List, hasLength(1));
  });

  test('a traversal leaves out symbols of an unserved repository', () async {
    // The asked symbol's repository is served; a caller in another one
    // (whose row is refused) is dropped from the results.
    final served = servedCodeGraphRepos(
      workspaces: FakeWorkspaceRepository()
        ..seedRepos(_ws, [row(), row().copyWith(id: 'r2')]),
      repos: FakeRepoRepository()
        ..seed(_ws, [row(linkedBy: _owner), row().copyWith(id: 'r2')]),
      guard: guard,
    );
    graph.callerRepo = 'r2';
    final r = await CodeCallersTool(
      repository: graph,
      repoGate: served,
    ).call({'workspace_id': _ws, 'symbol_id': 's2'});
    expect(r.isError, isFalse);
    expect(symbolsOf(r, 'callers'), isEmpty);
  });
}

CodeSymbol _symbol(String id, String name, {String repoId = 'r1'}) =>
    CodeSymbol(
      id: id,
      workspaceId: _ws,
      repoId: repoId,
      kind: CodeSymbolKind.function,
      name: name,
      qualifiedName: 'pkg.$name',
      filePath: 'lib/${name.toLowerCase()}.dart',
      language: 'dart',
      startLine: 1,
      endLine: 8,
    );

/// One repository's index: `Secret` (s1), called by `caller` (s2's caller).
final class _Graph implements CodeGraphRepository {
  final read = <String>[];
  String callerRepo = 'r1';

  @override
  Future<List<CodeSymbol>> search(
    String workspaceId,
    String repoId,
    String query, {
    Float32List? queryEmbedding,
    String? checkoutId,
  }) async {
    read.add('search $repoId');
    return [_symbol('s1', 'Secret')];
  }

  @override
  Future<List<CodeSymbol>> getByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit = 20,
    String? checkoutId,
  }) async {
    read.add('getByName $repoId');
    return [_symbol('s1', 'Secret')];
  }

  @override
  Future<CodeSymbol?> getById(String workspaceId, String id) async =>
      _symbol(id, 'Secret');

  @override
  Future<List<CodeSymbol>> callers(
    String workspaceId,
    String symbolId, {
    int? limit,
    String? checkoutId,
    Set<CodeEdgeKind> kinds = const {CodeEdgeKind.calls},
  }) async {
    read.add('callers $symbolId');
    return [_symbol('s3', 'caller', repoId: callerRepo)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

final class _Inspector implements GitRepoInspectorPort {
  @override
  Future<GitRepoInfo> inspect(String path) async => GitRepoInfo(
    path: path,
    forge: ForgeHost.github,
    owner: 'acme',
    repoName: 'api',
    branch: 'main',
  );
}
