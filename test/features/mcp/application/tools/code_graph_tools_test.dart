import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_subgraph.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_mcp/src/tools/code_graph_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_workspace_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _wsId = 'ws-1';
const _repoId = 'repo-1';

CodeSymbol _symbol({
  String id = 'sym-1',
  String name = 'myFunc',
}) {
  return CodeSymbol(
    id: id,
    workspaceId: _wsId,
    repoId: _repoId,
    kind: CodeSymbolKind.function,
    name: name,
    qualifiedName: 'pkg.$name',
    filePath: 'lib/src/$name.dart',
    language: 'dart',
    startLine: 1,
    endLine: 5,
    signature: 'void $name()',
    docstring: 'Docs for $name.',
  );
}

List<CodeSymbol> _threeSymbols() => [
  _symbol(id: 'sym-1', name: 'alpha'),
  _symbol(id: 'sym-2', name: 'beta'),
  _symbol(id: 'sym-3', name: 'gamma'),
];

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeEmbeddingPort implements EmbeddingPort {

  _FakeEmbeddingPort({this.isReady = true});
  @override
  bool isReady;
  bool embedCalled = false;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async {
    embedCalled = true;
    return Float32List(dimension);
  }
}

class _ThrowingEmbeddingPort implements EmbeddingPort {
  @override
  bool get isReady => true;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async {
    throw Exception('bad embed');
  }
}

enum _GraphMethod { search, getByName, getById, callers, callees, impactRadius }

class _FakeCodeGraphRepository implements CodeGraphRepository {
  final List<CodeSymbol> _symbols = [];
  final Map<String, double> _searchResults = {}; // name -> score
  CodeSubgraph? _impactSubgraph;
  bool _throwOnNext = false;


  // Track the last call args for assertions.
  _GraphMethod? lastMethod;
  Map<String, dynamic> lastArgs = {};

  void addSymbols(Iterable<CodeSymbol> symbols) => _symbols.addAll(symbols);

  void setSearchResults(Map<String, double> nameToScore) {
    _searchResults
      ..clear()
      ..addAll(nameToScore);
  }

  void setImpactSubgraph(CodeSubgraph s) => _impactSubgraph = s;

  void throwOnNext() => _throwOnNext = true;

  @override
  Future<List<CodeSymbol>> search(
    String workspaceId,
    String repoId,
    String query, {
    Float32List? queryEmbedding,
  }) async {
    if (_throwOnNext) {
      _throwOnNext = false;
      throw Exception('search failed');
    }
    lastMethod = _GraphMethod.search;
    lastArgs = {
      'workspaceId': workspaceId,
      'repoId': repoId,
      'query': query,
      'hasEmbedding': queryEmbedding != null,
    };
    // Return symbols whose name is in the results map, sorted by score desc.
    final matches = _symbols
        .where((s) => _searchResults.containsKey(s.name))
        .toList()
      ..sort(
        (a, b) => _searchResults[b.name]!.compareTo(_searchResults[a.name]!),
      );
    return matches;
  }

  @override
  Future<List<CodeSymbol>> getByName(
    String workspaceId,
    String repoId,
    String name, {
    int limit = 100,
  }) async {
    if (_throwOnNext) {
      _throwOnNext = false;
      throw Exception('getByName failed');
    }
    lastMethod = _GraphMethod.getByName;
    lastArgs = {'workspaceId': workspaceId, 'repoId': repoId, 'name': name};
    return _symbols.where((s) => s.name == name).toList();
  }

  @override
  Future<CodeSymbol?> getById(String workspaceId, String id) async {
    if (_throwOnNext) {
      _throwOnNext = false;
      throw Exception('getById failed');
    }
    lastMethod = _GraphMethod.getById;
    lastArgs = {'workspaceId': workspaceId, 'id': id};
    return _symbols.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<List<CodeSymbol>> callers(
    String workspaceId,
    String symbolId, {
    int? limit,
  }) async {
    if (_throwOnNext) {
      _throwOnNext = false;
      throw Exception('callers failed');
    }
    lastMethod = _GraphMethod.callers;
    lastArgs = {
      'workspaceId': workspaceId,
      'symbolId': symbolId,
      'limit': limit,
    };
    final result = _symbols.where((s) => s.id != symbolId).toList();
    return limit != null ? result.take(limit).toList() : result;
  }

  @override
  Future<List<CodeSymbol>> callees(
    String workspaceId,
    String symbolId, {
    int? limit,
  }) async {
    if (_throwOnNext) {
      _throwOnNext = false;
      throw Exception('callees failed');
    }
    lastMethod = _GraphMethod.callees;
    lastArgs = {
      'workspaceId': workspaceId,
      'symbolId': symbolId,
      'limit': limit,
    };
    final result = _symbols.where((s) => s.id != symbolId).toList();
    return limit != null ? result.take(limit).toList() : result;
  }

  @override
  Future<CodeSubgraph> impactRadius(
    String workspaceId,
    String symbolId, {
    int depth = 2,
  }) async {
    if (_throwOnNext) {
      _throwOnNext = false;
      throw Exception('impactRadius failed');
    }
    lastMethod = _GraphMethod.impactRadius;
    lastArgs = {
      'workspaceId': workspaceId,
      'symbolId': symbolId,
      'depth': depth,
    };
    return _impactSubgraph ?? const CodeSubgraph.empty();
  }

  // Unused by tools — stubs only.
  @override
  Future<List<CodeSymbol>> symbolsForRepo(String ws, String repo) async => [];
  @override
  Stream<List<CodeSymbol>> watchByRepo(String ws, String repo) =>
      Stream.value([]);
  @override
  Future<Map<String, String>> fileHashes(String ws, String repo) async => {};
  @override
  Future<void> deleteFiles(String ws, String repo, List<String> paths) async {}
  @override
  Future<int> resolvePendingReferences(String ws, String repo) async => 0;
  @override
  Future<void> ingestFile({
    required String workspaceId,
    required String repoId,
    required String filePath,
    required String contentHash,
    required List<CodeSymbol> symbols,
    required List<CodeEdge> edges,
    String? language,
  }) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeWorkspaceRepository wsRepo;
  late _FakeCodeGraphRepository graphRepo;
  late _FakeEmbeddingPort embedding;

  setUp(() {
    wsRepo = FakeWorkspaceRepository();
    graphRepo = _FakeCodeGraphRepository();
    embedding = _FakeEmbeddingPort(isReady: true);
  });

  // -- SearchCodeTool -------------------------------------------------------

  group('SearchCodeTool', () {
    SearchCodeTool makeTool() => SearchCodeTool(
      repository: graphRepo,
      workspaceRepository: wsRepo,
      embeddingService: embedding,
    );

    test('name, description, schema', () {
      final t = makeTool();
      expect(t.name, 'search_code');
      expect(t.description, contains('Searches indexed code symbols'));
      final s = t.inputSchema;
      expect(s['required'], containsAll(['workspace_id', 'repo_id', 'query']));
    });

    group('arg validation', () {
      test('missing workspace_id', () async {
        final r = await makeTool().call({});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing workspace_id'));
      });

      test('workspace_id is not a string', () async {
        final r = await makeTool().call({'workspace_id': 42});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing workspace_id'));
      });

      test('missing repo_id', () async {
        final r = await makeTool().call({'workspace_id': _wsId});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing repo_id'));
      });

      test('missing query', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing query'));
      });

      test('repo not in workspace', () async {
        // wsRepo has no links by default.
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'foo',
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('not part of workspace'));
      });
    });

    group('success', () {
      setUp(() async {
        await wsRepo.linkRepoToWorkspace(_wsId, _repoId);
      });

      test('returns symbols as JSON with hybrid mode (default)', () async {
        final syms = _threeSymbols();
        graphRepo.addSymbols(syms);
        graphRepo.setSearchResults({'alpha': 0.9, 'beta': 0.5, 'gamma': 0.3});

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'alpha',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        final symbols = data['symbols'] as List;
        expect(symbols.length, 3);
        // Ordered by score descending.
        expect((symbols[0] as Map)['name'], 'alpha');
        expect((symbols[1] as Map)['name'], 'beta');
        expect((symbols[2] as Map)['name'], 'gamma');
        expect(graphRepo.lastMethod, _GraphMethod.search);
      });

      test('returns empty symbols', () async {
        graphRepo.setSearchResults({});

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'nonexistent',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        final symbols = data['symbols'] as List;
        expect(symbols.length, 0);
      });

      test('keyword mode skips embedding', () async {
        final syms = _threeSymbols();
        graphRepo.addSymbols(syms);
        graphRepo.setSearchResults({'alpha': 0.9});

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'alpha',
          'mode': 'keyword',
        });

        expect(r.isError, isFalse);
        expect(graphRepo.lastArgs['hasEmbedding'], false);
        expect(embedding.embedCalled, isFalse);
      });

      test('semantic mode uses embedding', () async {
        graphRepo.addSymbols(_threeSymbols());
        graphRepo.setSearchResults({'alpha': 0.9});

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'alpha',
          'mode': 'semantic',
        });

        expect(r.isError, isFalse);
        expect(embedding.embedCalled, isTrue);
        expect(graphRepo.lastArgs['hasEmbedding'], true);
      });

      test('with embedding not ready still succeeds', () async {
        final slowEmbedding = _FakeEmbeddingPort(isReady: false);
        final t = SearchCodeTool(
          repository: graphRepo,
          workspaceRepository: wsRepo,
          embeddingService: slowEmbedding,
        );
        graphRepo.addSymbols(_threeSymbols());
        graphRepo.setSearchResults({'alpha': 0.9});

        final r = await t.call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'alpha',
        });

        expect(r.isError, isFalse);
        expect(slowEmbedding.embedCalled, isFalse);
      });

      test('embedding throws does not fail the tool', () async {
        final throwingEmbedding = _ThrowingEmbeddingPort();
        final t = SearchCodeTool(
          repository: graphRepo,
          workspaceRepository: wsRepo,
          embeddingService: throwingEmbedding,
        );
        graphRepo.addSymbols(_threeSymbols());
        graphRepo.setSearchResults({'alpha': 0.9});

        final r = await t.call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'alpha',
          'mode': 'semantic',
        });

        expect(r.isError, isFalse);
        expect(graphRepo.lastArgs['hasEmbedding'], false);
      });

      test('no embedding service still works', () async {
        final t = SearchCodeTool(
          repository: graphRepo,
          workspaceRepository: wsRepo,
        );
        graphRepo.addSymbols(_threeSymbols());
        graphRepo.setSearchResults({'alpha': 0.9});

        final r = await t.call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'query': 'alpha',
        });

        expect(r.isError, isFalse);
        expect(graphRepo.lastArgs['hasEmbedding'], false);
      });
    });
  });

  // -- CodeSymbolTool -------------------------------------------------------

  group('CodeSymbolTool', () {
    CodeSymbolTool makeTool() => CodeSymbolTool(
      repository: graphRepo,
      workspaceRepository: wsRepo,
    );

    test('name, description, schema', () {
      final t = makeTool();
      expect(t.name, 'code_symbol');
      expect(t.description, contains('Looks up code symbols'));
      final s = t.inputSchema;
      expect(s['required'], containsAll(['workspace_id', 'repo_id', 'name']));
    });

    group('arg validation', () {
      test('missing workspace_id', () async {
        final r = await makeTool().call({});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing workspace_id'));
      });

      test('missing repo_id', () async {
        final r = await makeTool().call({'workspace_id': _wsId});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing repo_id'));
      });

      test('missing name', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing name'));
      });

      test('repo not in workspace', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'name': 'myFunc',
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('not part of workspace'));
      });
    });

    group('success', () {
      setUp(() async {
        await wsRepo.linkRepoToWorkspace(_wsId, _repoId);
      });

      test('returns matching symbols', () async {
        graphRepo.addSymbols([_symbol(), _symbol(id: 'sym-2', name: 'other')]);

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'name': 'myFunc',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        final symbols = data['symbols'] as List;
        expect(symbols.length, 1);
        expect((symbols[0] as Map)['name'], 'myFunc');
        expect(graphRepo.lastMethod, _GraphMethod.getByName);
        expect(graphRepo.lastArgs['name'], 'myFunc');
      });

      test('returns empty when no matches', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'repo_id': _repoId,
          'name': 'nonexistent',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        expect((data['symbols'] as List).length, 0);
      });
    });
  });

  // -- CodeCallersTool ------------------------------------------------------

  group('CodeCallersTool', () {
    CodeCallersTool makeTool() => CodeCallersTool(repository: graphRepo);

    test('name, description, schema', () {
      final t = makeTool();
      expect(t.name, 'code_callers');
      expect(t.description, contains('call or depend on'));
      final s = t.inputSchema;
      expect(s['required'], containsAll(['workspace_id', 'symbol_id']));
      expect(((s['properties'] as Map<String, dynamic>)['limit'] as Map<String, dynamic>)['type'], 'integer');
    });

    group('arg validation', () {
      test('missing workspace_id', () async {
        final r = await makeTool().call({});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing workspace_id'));
      });

      test('missing symbol_id', () async {
        final r = await makeTool().call({'workspace_id': _wsId});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing symbol_id'));
      });

      test('symbol not found in workspace', () async {
        // _getById returns null when symbol missing.
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'nonexistent',
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('not found in workspace'));
      });
    });

    group('success', () {
      setUp(() {
        graphRepo.addSymbols(_threeSymbols());
      });

      test('returns callers excluding the symbol itself', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        final callers = data['callers'] as List;
        expect(callers.length, 2);
        expect(graphRepo.lastMethod, _GraphMethod.callers);
      });

      test('respects custom limit', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
          'limit': 1,
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        expect((data['callers'] as List).length, 1);
        expect(graphRepo.lastArgs['limit'], 1);
      });

      test('defaults limit to 50', () async {
        await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });
        expect(graphRepo.lastArgs['limit'], 50);
      });

      test('null symbol_id with type other than String', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': null,
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing symbol_id'));
      });
    });
  });

  // -- CodeCalleesTool ------------------------------------------------------

  group('CodeCalleesTool', () {
    CodeCalleesTool makeTool() => CodeCalleesTool(repository: graphRepo);

    test('name, description, schema', () {
      final t = makeTool();
      expect(t.name, 'code_callees');
      expect(t.description, contains('calls or depends on'));
      final s = t.inputSchema;
      expect(s['required'], containsAll(['workspace_id', 'symbol_id']));
    });

    group('arg validation', () {
      test('missing workspace_id', () async {
        final r = await makeTool().call({});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing workspace_id'));
      });

      test('missing symbol_id', () async {
        final r = await makeTool().call({'workspace_id': _wsId});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing symbol_id'));
      });

      test('symbol not found in workspace', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'nonexistent',
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('not found in workspace'));
      });
    });

    group('success', () {
      setUp(() {
        graphRepo.addSymbols(_threeSymbols());
      });

      test('returns callees', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        final callees = data['callees'] as List;
        expect(callees.length, 2);
        expect(graphRepo.lastMethod, _GraphMethod.callees);
      });

      test('respects custom limit', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
          'limit': 1,
        });

        expect(r.isError, isFalse);
        expect(((jsonDecode(r.content.single.text) as Map<String, dynamic>)['callees'] as List).length, 1);
      });

      test('defaults limit to 50', () async {
        await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });
        expect(graphRepo.lastArgs['limit'], 50);
      });
    });
  });

  // -- CodeImpactTool -------------------------------------------------------

  group('CodeImpactTool', () {
    CodeImpactTool makeTool() => CodeImpactTool(repository: graphRepo);

    test('name, description, schema', () {
      final t = makeTool();
      expect(t.name, 'code_impact');
      expect(t.description, contains('transitive impact radius'));
      final s = t.inputSchema;
      expect(s['required'], containsAll(['workspace_id', 'symbol_id']));
      expect(((s['properties'] as Map<String, dynamic>)['depth'] as Map<String, dynamic>)['type'], 'integer');
    });

    group('arg validation', () {
      test('missing workspace_id', () async {
        final r = await makeTool().call({});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing workspace_id'));
      });

      test('missing symbol_id', () async {
        final r = await makeTool().call({'workspace_id': _wsId});
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('Missing symbol_id'));
      });

      test('symbol not found in workspace', () async {
        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'nonexistent',
        });
        expect(r.isError, isTrue);
        expect(r.content.single.text, contains('not found in workspace'));
      });
    });

    group('success', () {
      setUp(() {
        graphRepo.addSymbols(_threeSymbols());
      });

      test('returns impact subgraph', () async {
        final subgraph = CodeSubgraph(
          root: _symbol(id: 'sym-1'),
          nodes: _threeSymbols(),
          edges: const [],
          depthById: {'sym-1': 0, 'sym-2': 1, 'sym-3': 1},
        );
        graphRepo.setImpactSubgraph(subgraph);

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        expect(data['root'], isNotNull);
        expect((data['impacted'] as List).length, 3);
        expect(data['edgeCount'], 0);
        expect(graphRepo.lastMethod, _GraphMethod.impactRadius);
      });

      test('defaults depth to 2', () async {
        final subgraph = CodeSubgraph(
          root: _symbol(id: 'sym-1'),
          nodes: [],
          edges: const [],
          depthById: {},
        );
        graphRepo.setImpactSubgraph(subgraph);

        await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });
        expect(graphRepo.lastArgs['depth'], 2);
      });

      test('respects custom depth', () async {
        final subgraph = CodeSubgraph(
          root: _symbol(id: 'sym-1'),
          nodes: [],
          edges: const [],
          depthById: {},
        );
        graphRepo.setImpactSubgraph(subgraph);

        await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
          'depth': 4,
        });
        expect(graphRepo.lastArgs['depth'], 4);
      });

      test('handles null root (empty subgraph)', () async {
        graphRepo.setImpactSubgraph(const CodeSubgraph.empty());

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        expect(data['root'], isNull);
        expect((data['impacted'] as List).length, 0);
        expect(data['edgeCount'], 0);
      });

      test('impacted symbols include depth from depthById', () async {
        final subgraph = CodeSubgraph(
          root: _symbol(id: 'sym-1', name: 'rootFunc'),
          nodes: [
            _symbol(id: 'sym-1', name: 'rootFunc'),
            _symbol(id: 'sym-2', name: 'child1'),
            _symbol(id: 'sym-3', name: 'child2'),
          ],
          edges: const [],
          depthById: {'sym-1': 0, 'sym-2': 2, 'sym-3': 1},
        );
        graphRepo.setImpactSubgraph(subgraph);

        final r = await makeTool().call({
          'workspace_id': _wsId,
          'symbol_id': 'sym-1',
        });

        expect(r.isError, isFalse);
        final data = jsonDecode(r.content.single.text) as Map<String, dynamic>;
        final impacted = data['impacted'] as List;
        // Get the depth field from each impacted symbol.
        final depths = impacted.map((s) => (s as Map)['depth'] as int).toList()..sort();
        expect(depths, [0, 1, 2]);
      });
    });
  });

  // -- Error wrapping via McpTool.call --------------------------------------

  group('McpTool.call exception wrapping', () {
    test('catches thrown exception and returns error', () async {
      await wsRepo.linkRepoToWorkspace(_wsId, _repoId);
      graphRepo.throwOnNext();

      final tool = SearchCodeTool(
        repository: graphRepo,
        workspaceRepository: wsRepo,
      );
      final r = await tool.call({
        'workspace_id': _wsId,
        'repo_id': _repoId,
        'query': 'alpha',
      });

      expect(r.isError, isTrue);
      expect(r.content.single.text, contains('Exception: search failed'));
    });
  });
}
