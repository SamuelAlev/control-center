import 'dart:typed_data';

import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/features/mcp/application/tools/propose_fact_tool.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMemoryFactRepository implements MemoryFactRepository {
  final List<MemoryFact> _facts = [];

  @override
  Future<void> upsert(MemoryFact fact) async {
    _facts.add(fact);
  }

  @override
  Future<MemoryFact?> getById(String id) async => _facts.where((f) => f.id == id).firstOrNull;

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) => Stream.value(_facts);

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async => _facts;

  @override
  Future<List<MemoryFact>> getActiveByTopic(String workspaceId, String topic) async => [];

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  }) async => [];

  @override
  Future<List<MemoryFact>> getByAuthor(
    String workspaceId,
    String agentId,
  ) async => [];

  @override
  Future<void> delete(String id) async {}
}

class _FakeDomainRepo implements MemoryDomainRepository {
  @override
  Future<List<MemoryDomain>> getByWorkspace(String ws) async => [];
  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String ws) => Stream.value([]);
  @override
  Future<MemoryDomain?> findByName(String ws, String name) async => null;
  @override
  Future<void> upsert(MemoryDomain d) async {}
}

class _FakeGrantRepo implements MemoryAccessGrantRepository {
  @override
  Future<List<MemoryAccessGrant>> getByWorkspace(String ws) async => [];
  @override
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String ws) => Stream.value([]);
  @override
  Future<void> upsert(MemoryAccessGrant g) async {}
  @override
  Future<void> upsertAll(List<MemoryAccessGrant> g) async {}
}

void main() {
  group('ProposeFactTool', () {
    late FakeMemoryFactRepository fakeRepo;
    late ProposeFactTool tool;

    setUp(() {
      fakeRepo = FakeMemoryFactRepository();
      tool = ProposeFactTool(
        repository: fakeRepo,
        resolveDomainUseCase: ResolveOrCreateDomainUseCase(
          domainRepository: _FakeDomainRepo(),
          grantRepository: _FakeGrantRepo(),
        ),
      );
    });

    test('name is propose_fact', () {
      expect(tool.name, 'propose_fact');
    });

    test('creates a fact', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'domain': 'tech-stack',
        'topic': 'tech stack',
        'content': 'We use Flutter',
      });

      expect(result.isError, isFalse);
      expect(fakeRepo._facts.length, 1);
      expect(fakeRepo._facts[0].topic, 'tech stack');
      expect(fakeRepo._facts[0].content, 'We use Flutter');
    });

    test('respects confidence parameter', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'domain': 'test',
        'topic': 'test',
        'content': 'fact',
        'confidence': 0.8,
      });

      expect(fakeRepo._facts[0].confidence, 0.8);
    });

    test('clamps confidence to 0-1', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'domain': 'test',
        'topic': 'test',
        'content': 'fact',
        'confidence': 1.5,
      });

      expect(fakeRepo._facts[0].confidence, 1.0);
    });

    test('stores agent metadata', () async {
      await tool.run({
        'workspace_id': 'ws-1',
        'domain': 'test',
        'topic': 'test',
        'content': 'fact',
        'agent_id': 'a-1',
        'agent_role': 'ceo',
      });

      expect(fakeRepo._facts[0].authoredByAgentId, 'a-1');
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({'domain': 'test', 'topic': 'test', 'content': 'fact'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing topic', () async {
      final result = await tool.run({'workspace_id': 'ws-1', 'domain': 'test', 'content': 'fact'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing content', () async {
      final result = await tool.run({'workspace_id': 'ws-1', 'domain': 'test', 'topic': 'test'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing domain with helpful message', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'topic': 'test',
        'content': 'fact',
      });
      expect(result.isError, isTrue);
      final text = ((result.toJson()['content'] as List).first as Map<String, dynamic>)['text'] as String;
      expect(text, contains('kebab-case'));
    });
  });
}
