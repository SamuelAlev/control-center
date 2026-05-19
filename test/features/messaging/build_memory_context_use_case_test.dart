import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePolicyRepository implements MemoryPolicyRepository {
  _FakePolicyRepository([this._policies = const []]);
  final List<MemoryPolicy> _policies;

  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(
    String workspaceId, {
    String? domain,
  }) async =>
      _policies;

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) =>
      Stream.value(_policies);

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) async =>
      _policies;

  @override
  Future<MemoryPolicy?> getById(String id) async => null;

  @override
  Future<void> upsert(MemoryPolicy policy) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeWorkingMemoryRepository implements AgentWorkingMemoryRepository {
  _FakeWorkingMemoryRepository([this._memory]);
  final AgentWorkingMemory? _memory;

  @override
  Future<AgentWorkingMemory?> getByAgent(
    String workspaceId,
    String agentId,
  ) async =>
      _memory;

  @override
  Future<void> upsert(AgentWorkingMemory memory) async {}

  @override
  Stream<AgentWorkingMemory?> watchByAgent(
    String workspaceId,
    String agentId,
  ) =>
      Stream.value(_memory);

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) =>
      Stream.value(_memory == null ? const [] : [_memory]);
}

MemoryPolicy _policy(String domain, String rule) => MemoryPolicy(
      id: '$domain-$rule',
      workspaceId: 'ws1',
      domain: domain,
      rule: rule,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

AgentWorkingMemory _notes(String content) => AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: content,
      updatedAt: DateTime(2024),
    );

void main() {
  group('BuildMemoryContextUseCase', () {
    test('returns empty string when no policies and no working memory',
        () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepository(),
        workingMemoryRepository: _FakeWorkingMemoryRepository(),
      );

      final result = await useCase.execute(
        workspaceId: 'ws1',
        agentId: 'agent1',
        taskDescription: 'anything',
      );

      expect(result, isEmpty);
    });

    test('includes active policies', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository:
            _FakePolicyRepository([_policy('auth', 'always use JWT')]),
        workingMemoryRepository: _FakeWorkingMemoryRepository(),
      );

      final result = await useCase.execute(
        workspaceId: 'ws1',
        agentId: 'agent1',
      );

      expect(result, contains('Active Policies'));
      expect(result, contains('always use JWT'));
    });

    test('includes the agent working-memory notes', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepository(),
        workingMemoryRepository:
            _FakeWorkingMemoryRepository(_notes('the user is called Sam')),
      );

      final result = await useCase.execute(
        workspaceId: 'ws1',
        agentId: 'agent1',
      );

      expect(result, contains('My Notes'));
      expect(result, contains('the user is called Sam'));
    });

    test('does not eagerly inject durable facts (lazy via search_memory)',
        () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepository(),
        workingMemoryRepository:
            _FakeWorkingMemoryRepository(_notes('note')),
      );

      final result = await useCase.execute(
        workspaceId: 'ws1',
        agentId: 'agent1',
        taskDescription: 'JWT',
      );

      // Facts are no longer dumped into the prompt; agents pull them on demand.
      expect(result, isNot(contains('Relevant facts')));
      expect(result, isNot(contains('Recent facts')));
      expect(result, contains('search_memory'));
    });
  });
}
