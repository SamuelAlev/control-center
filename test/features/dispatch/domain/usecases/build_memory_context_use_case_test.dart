import 'dart:async';

import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [MemoryPolicyRepository].
class _FakePolicyRepo implements MemoryPolicyRepository {

  _FakePolicyRepo({this.policies = const []});
  final List<MemoryPolicy> policies;
  bool throwOnLoad = false;

  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(String workspaceId,
      {String? domain}) async {
    if (throwOnLoad) {
      throw Exception('policy load failed');
    }
    return policies.where((p) => p.workspaceId == workspaceId).toList();
  }

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) async =>
      policies.where((p) => p.workspaceId == workspaceId).toList();

  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) async =>
      policies.where((p) => p.id == id && p.workspaceId == workspaceId).firstOrNull;

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) =>
      Stream.value(policies.where((p) => p.workspaceId == workspaceId).toList());

  @override
  Future<void> upsert(MemoryPolicy policy) async {}

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

/// Fake [AgentWorkingMemoryRepository].
class _FakeWorkingMemoryRepo implements AgentWorkingMemoryRepository {
  AgentWorkingMemory? memory;
  bool throwOnLoad = false;

  @override
  Future<AgentWorkingMemory?> getByAgent(String workspaceId, String agentId) async {
    if (throwOnLoad) {
      throw Exception('working memory load failed');
    }
    return memory;
  }

  @override
  Stream<AgentWorkingMemory?> watchByAgent(String workspaceId, String agentId) =>
      Stream.value(memory);

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<void> upsert(AgentWorkingMemory memory) async {}
}

MemoryPolicy _policy(String id, String workspaceId, String domain, String rule) =>
    MemoryPolicy(
      id: id,
      workspaceId: workspaceId,
      domain: domain,
      rule: rule,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

AgentWorkingMemory _wm(String content) => AgentWorkingMemory(
      id: 'wm1',
      workspaceId: 'ws1',
      agentId: 'agent1',
      content: content,
      updatedAt: DateTime(2025),
    );

void main() {
  group('BuildMemoryContextUseCase', () {
    test('returns empty string when no policies and no working memory', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(),
        workingMemoryRepository: _FakeWorkingMemoryRepo(),
      );

      final result = await useCase.execute(
        workspaceId: 'ws1', agentId: 'agent1',
      );
      expect(result, '');
    });

    test('returns empty string when working memory is null and no policies',
        () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(),
        workingMemoryRepository: _FakeWorkingMemoryRepo()..memory = null,
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, '');
    });

    test('returns empty string when working memory content is empty', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(),
        workingMemoryRepository: _FakeWorkingMemoryRepo()..memory = _wm(''),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, '');
    });

    test('returns empty string when working memory content is whitespace',
        () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(),
        workingMemoryRepository: _FakeWorkingMemoryRepo()..memory = _wm('   '),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, '');
    });

    test('includes active policies when present', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(policies: [
          _policy('p1', 'ws1', 'security', 'Never share API keys'),
          _policy('p2', 'ws1', 'style', 'Use tabs for indentation'),
        ]),
        workingMemoryRepository: _FakeWorkingMemoryRepo(),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, contains('Active Policies'));
      expect(result, contains('[security] Never share API keys'));
      expect(result, contains('[style] Use tabs for indentation'));
      expect(result, contains('Agent Memory'));
      expect(result, contains('search_memory'));
    });

    test('filters policies by workspace', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(policies: [
          _policy('p1', 'ws1', 'domain', 'Rule for ws1'),
          _policy('p2', 'ws2', 'domain', 'Rule for ws2'),
        ]),
        workingMemoryRepository: _FakeWorkingMemoryRepo(),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, contains('Rule for ws1'));
      expect(result, isNot(contains('Rule for ws2')));
    });

    test('handles empty policies list', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(policies: []),
        workingMemoryRepository: _FakeWorkingMemoryRepo(),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, '');
    });

    test('includes working memory content when present', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(),
        workingMemoryRepository: _FakeWorkingMemoryRepo()
          ..memory = _wm('Remember my name: Alice'),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, contains('My Notes'));
      expect(result, contains('Remember my name: Alice'));
      expect(result, contains('Agent Memory'));
    });

    test('includes both policies and working memory', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(policies: [
          _policy('p1', 'ws1', 'general', 'Be concise'),
        ]),
        workingMemoryRepository: _FakeWorkingMemoryRepo()
          ..memory = _wm('User prefers short answers'),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, contains('Active Policies'));
      expect(result, contains('[general] Be concise'));
      expect(result, contains('My Notes'));
      expect(result, contains('User prefers short answers'));
    });

    test('survives policy load failure and still returns working memory',
        () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo()..throwOnLoad = true,
        workingMemoryRepository: _FakeWorkingMemoryRepo()
          ..memory = _wm('Important note'),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, isNot(contains('Active Policies')));
      expect(result, contains('Important note'));
    });

    test('survives working memory load failure and still returns policies',
        () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(policies: [
          _policy('p1', 'ws1', 'general', 'Be polite'),
        ]),
        workingMemoryRepository: _FakeWorkingMemoryRepo()..throwOnLoad = true,
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, contains('Active Policies'));
      expect(result, contains('Be polite'));
      expect(result, isNot(contains('My Notes')));
    });

    test('survives both repos failing', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo()..throwOnLoad = true,
        workingMemoryRepository: _FakeWorkingMemoryRepo()..throwOnLoad = true,
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, '');
    });

    test('output includes search_memory hint', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(policies: [
          _policy('p1', 'ws1', 'test', 'Rule'),
        ]),
        workingMemoryRepository: _FakeWorkingMemoryRepo(),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, contains('search_memory'));
    });

    test('output starts with Agent Memory header', () async {
      final useCase = BuildMemoryContextUseCase(
        policyRepository: _FakePolicyRepo(policies: [
          _policy('p1', 'ws1', 'test', 'Rule'),
        ]),
        workingMemoryRepository: _FakeWorkingMemoryRepo(),
      );

      final result = await useCase.execute(workspaceId: 'ws1', agentId: 'agent1');
      expect(result, startsWith('## Agent Memory'));
    });
  });
}
