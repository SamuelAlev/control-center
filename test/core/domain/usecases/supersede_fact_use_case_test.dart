import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMemoryFactRepository implements MemoryFactRepository {
  final Map<String, MemoryFact> _facts = {};

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) async {
    final fact = _facts[id];
    return fact != null && fact.workspaceId == workspaceId ? fact : null;
  }

  @override
  Future<void> upsert(MemoryFact fact) async {
    _facts[fact.id] = fact;
  }

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) => Stream.value([]);

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async => _facts.values.toList();

  @override
  Future<List<MemoryFact>> getActiveByTopic(String workspaceId, String topic) async => [];

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  }) async => [];

  @override
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
  }) async => [];

  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) async =>
      _facts.values
          .where((f) => f.workspaceId == workspaceId && !f.isSuperseded)
          .toList();

  @override
  Future<void> markRecalled(String workspaceId, List<String> ids) async {}

  @override
  Future<List<MemoryFact>> getByAuthor(
    String workspaceId,
    String agentId,
  ) async => [];

  @override
  Future<void> delete(String workspaceId, String id) async {
    final fact = _facts[id];
    if (fact != null && fact.workspaceId == workspaceId) {
      _facts.remove(id);
    }
  }
}

void main() {
  final now = DateTime(2026, 5, 22, 12, 0);

  group('SupersedeFactUseCase', () {
    late FakeMemoryFactRepository fakeRepo;
    late SupersedeFactUseCase useCase;

    setUp(() {
      fakeRepo = FakeMemoryFactRepository();
      useCase = SupersedeFactUseCase(factRepository: fakeRepo);
    });

    test('supersedes a fact', () async {
      final fact = MemoryFact(
        id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
        content: 'old fact', createdAt: now, updatedAt: now,
      );
      fakeRepo._facts['f-1'] = fact;

      final result = await useCase.execute(
        workspaceId: 'ws-1',
        factId: 'f-1',
        supersedingFactId: 'f-2',
      );

      expect(result.supersededBy, 'f-2');
      expect(result.id, 'f-1');
      expect(fakeRepo._facts['f-1']!.supersededBy, 'f-2');
    });

    test('throws if fact not found', () {
      expect(
        () => useCase.execute(
          workspaceId: 'ws-1',
          factId: 'missing',
          supersedingFactId: 'f-2',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws if the fact belongs to another workspace', () async {
      final fact = MemoryFact(
        id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
        content: 'old fact', createdAt: now, updatedAt: now,
      );
      fakeRepo._facts['f-1'] = fact;

      expect(
        () => useCase.execute(
          workspaceId: 'ws-2',
          factId: 'f-1',
          supersedingFactId: 'f-2',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
