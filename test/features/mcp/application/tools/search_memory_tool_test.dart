import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_infra/src/embedding/embedding_service.dart';
import 'package:cc_mcp/src/tools/search_memory_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFactRepository implements MemoryFactRepository {

  _FakeFactRepository(this._facts);
  final List<MemoryFact> _facts;
  Float32List? lastQueryEmbedding;
  String? lastMode;

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  }) async {
    lastQueryEmbedding = queryEmbedding;
    lastMode = queryEmbedding != null ? 'hybrid' : 'keyword';
    return _facts
        .where((f) => f.workspaceId == workspaceId && !f.isSuperseded)
        .toList();
  }

  @override
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
  }) async {
    lastQueryEmbedding = queryEmbedding;
    lastMode = 'hybrid';
    return _facts
        .where((f) => f.workspaceId == workspaceId && !f.isSuperseded)
        .take(topK)
        .toList();
  }

  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) async =>
      _facts
          .where((f) => f.workspaceId == workspaceId && !f.isSuperseded)
          .toList();

  @override
  Future<void> markRecalled(String workspaceId, List<String> ids) async {}

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) =>
      Stream.value(_facts);

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async => _facts;

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) async => null;

  @override
  Future<void> upsert(MemoryFact fact) async {}

  @override
  Future<List<MemoryFact>> getActiveByTopic(
          String workspaceId, String topic) async =>
      [];

  @override
  Future<List<MemoryFact>> getByAuthor(
    String workspaceId,
    String agentId,
  ) async => [];

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

class _FakePolicyRepository implements MemoryPolicyRepository {
  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(
          String workspaceId, {String? domain}) async =>
      [];

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) async => [];

  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) async => null;

  @override
  Future<void> upsert(MemoryPolicy policy) async {}

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

class _FakeEmbeddingService extends EmbeddingService {
  _FakeEmbeddingService()
      : super(
          modelInfo: EmbeddingModelInfo.allMiniLmL6V2,
          paths: const EmbeddingModelPaths(
            model: '/fake/model.onnx',
            vocab: '/fake/vocab.txt',
          ),
        );

  @override
  bool get isReady => true;

  @override
  Future<Float32List> embed(String text) async => Float32List(384);
}

class _NotReadyEmbeddingService extends EmbeddingService {
  _NotReadyEmbeddingService()
      : super(
          modelInfo: EmbeddingModelInfo.allMiniLmL6V2,
          paths: const EmbeddingModelPaths(
            model: '/fake/model.onnx',
            vocab: '/fake/vocab.txt',
          ),
        );

  @override
  bool get isReady => false;
}

MemoryFact _makeFact({
  String id = 'f1',
  String workspaceId = 'ws1',
  String topic = 'auth',
  String content = 'uses JWT tokens',
  double confidence = 0.9,
  String? supersededBy,
}) {
  return MemoryFact(
    id: id,
    workspaceId: workspaceId,
    domain: 'test',
    topic: topic,
    content: content,
    confidence: confidence,
    supersededBy: supersededBy,
    sourceObservationIds: [],
    authoredByRole: AgentRole.ceo,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('SearchMemoryTool', () {
    test('name is search_memory', () {
      final tool = SearchMemoryTool(
        factRepository: _FakeFactRepository([]),
        policyRepository: _FakePolicyRepository(),
      );
      expect(tool.name, equals('search_memory'));
    });

    test('inputSchema has required fields', () {
      final tool = SearchMemoryTool(
        factRepository: _FakeFactRepository([]),
        policyRepository: _FakePolicyRepository(),
      );
      final schema = tool.inputSchema;
      expect(schema['required'], containsAll(['workspace_id', 'query']));
      final props = schema['properties'] as Map<String, dynamic>;
      expect(props.containsKey('workspace_id'), isTrue);
      expect(props.containsKey('query'), isTrue);
      expect(props.containsKey('mode'), isTrue);
    });

    test('returns error when workspace_id is missing', () async {
      final tool = SearchMemoryTool(
        factRepository: _FakeFactRepository([]),
        policyRepository: _FakePolicyRepository(),
      );
      final result = await tool.run({'query': 'test'});
      expect(result.isError, isTrue);
    });

    test('returns error when query is missing', () async {
      final tool = SearchMemoryTool(
        factRepository: _FakeFactRepository([]),
        policyRepository: _FakePolicyRepository(),
      );
      final result = await tool.run({'workspace_id': 'ws1'});
      expect(result.isError, isTrue);
    });

    test('returns facts and empty policies on success', () async {
      final facts = [_makeFact()];
      final tool = SearchMemoryTool(
        factRepository: _FakeFactRepository(facts),
        policyRepository: _FakePolicyRepository(),
      );
      final result = await tool.run({
        'workspace_id': 'ws1',
        'query': 'JWT',
      });
      expect(result.isError, isFalse);
      final text = result.content.first.text;
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      expect(decoded.containsKey('facts'), isTrue);
      expect(decoded.containsKey('policies'), isTrue);
      final factsList = (decoded['facts'] as List).cast<Map<String, dynamic>>();
      expect(factsList, isNotEmpty);
      expect(factsList.first['id'], equals('f1'));
    });

    test('filters out superseded facts', () async {
      final facts = [
        _makeFact(id: 'f1'),
        _makeFact(id: 'f2', supersededBy: 'f3'),
      ];
      final tool = SearchMemoryTool(
        factRepository: _FakeFactRepository(facts),
        policyRepository: _FakePolicyRepository(),
      );
      final result = await tool.run({
        'workspace_id': 'ws1',
        'query': 'JWT',
      });
      final text = result.content.first.text;
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final factsList = (decoded['facts'] as List).cast<Map<String, dynamic>>();
      expect(factsList.length, equals(1));
      expect(factsList.first['id'], equals('f1'));
    });

    test('uses hybrid mode by default', () async {
      final factRepo = _FakeFactRepository([]);
      final tool = SearchMemoryTool(
        factRepository: factRepo,
        policyRepository: _FakePolicyRepository(),
        embeddingService: _FakeEmbeddingService(),
      );
      await tool.run({
        'workspace_id': 'ws1',
        'query': 'test',
      });
      expect(factRepo.lastMode, equals('hybrid'));
      expect(factRepo.lastQueryEmbedding, isNotNull);
    });

    test('keyword mode skips embedding', () async {
      final factRepo = _FakeFactRepository([]);
      final tool = SearchMemoryTool(
        factRepository: factRepo,
        policyRepository: _FakePolicyRepository(),
        embeddingService: _FakeEmbeddingService(),
      );
      await tool.run({
        'workspace_id': 'ws1',
        'query': 'test',
        'mode': 'keyword',
      });
      expect(factRepo.lastMode, equals('keyword'));
      expect(factRepo.lastQueryEmbedding, isNull);
    });

    test('falls back to keyword when embedding service is null', () async {
      final factRepo = _FakeFactRepository([]);
      final tool = SearchMemoryTool(
        factRepository: factRepo,
        policyRepository: _FakePolicyRepository(),
      );
      await tool.run({
        'workspace_id': 'ws1',
        'query': 'test',
        'mode': 'hybrid',
      });
      expect(factRepo.lastQueryEmbedding, isNull);
    });

    test('falls back to keyword when embedding service is not ready', () async {
      final factRepo = _FakeFactRepository([]);
      final tool = SearchMemoryTool(
        factRepository: factRepo,
        policyRepository: _FakePolicyRepository(),
        embeddingService: _NotReadyEmbeddingService(),
      );
      await tool.run({
        'workspace_id': 'ws1',
        'query': 'test',
        'mode': 'hybrid',
      });
      expect(factRepo.lastQueryEmbedding, isNull);
    });

    test('includes policies in response', () async {
      final tool = SearchMemoryTool(
        factRepository: _FakeFactRepository([]),
        policyRepository: _FakePolicyRepository(),
      );
      final result = await tool.run({
        'workspace_id': 'ws1',
        'query': 'test',
      });
      final text = result.content.first.text;
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      expect(decoded.containsKey('policies'), isTrue);
    });
  });
}
