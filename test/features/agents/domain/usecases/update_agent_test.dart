import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/usecases/update_agent.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory repository good enough for the use-case rules.
class _FakeRepo implements AgentRepository {
  final Map<String, Agent> store = {};
  final List<String> deleted = [];

  @override
  Future<Agent?> getById(String id) async => store[id];

  @override
  Future<void> upsert(Agent agent) async => store[agent.id] = agent;

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    store.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}

Agent _agent(String id, String workspaceId) => Agent(
      id: id,
      name: 'engineer',
      title: 'Engineer',
      agentMdPath: '/x/AGENTS.md',
      workspaceId: workspaceId,
      skills: AgentSkills(const ['testing']),
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('UpdateAgentUseCase', () {
    test('updates editable fields when the workspace matches', () async {
      final repo = _FakeRepo()..store['a'] = _agent('a', 'ws-1');
      final usecase = UpdateAgentUseCase(repository: repo);

      final result = await usecase.execute(
        const UpdateAgentCommand(
          agentId: 'a',
          workspaceId: 'ws-1',
          title: 'Staff engineer',
          skills: ['testing', 'review'],
          reportsTo: 'mgr',
          persona: 'Careful.',
        ),
      );

      expect(result.title, 'Staff engineer');
      expect(result.reportsTo, 'mgr');
      expect(result.skills.toList(), ['testing', 'review']);
      expect(result.persona, 'Careful.');
      expect(repo.store['a']!.title, 'Staff engineer');
    });

    test('clears reportsTo and persona when null', () async {
      final seeded = _agent('a', 'ws-1').copyWith(
        reportsTo: 'mgr',
        persona: 'old',
      );
      final repo = _FakeRepo()..store['a'] = seeded;
      final usecase = UpdateAgentUseCase(repository: repo);

      final result = await usecase.execute(
        const UpdateAgentCommand(
          agentId: 'a',
          workspaceId: 'ws-1',
          title: 'Engineer',
          skills: ['testing'],
        ),
      );

      expect(result.reportsTo, isNull);
      expect(result.persona, isNull);
    });

    test('denies a cross-workspace edit', () async {
      final repo = _FakeRepo()..store['a'] = _agent('a', 'ws-1');
      final usecase = UpdateAgentUseCase(repository: repo);

      expect(
        () => usecase.execute(
          const UpdateAgentCommand(
            agentId: 'a',
            workspaceId: 'ws-OTHER',
            title: 'Hijacked',
            skills: [],
          ),
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });
  });

  group('DeleteAgentUseCase', () {
    test('deletes when the workspace matches', () async {
      final repo = _FakeRepo()..store['a'] = _agent('a', 'ws-1');
      final usecase = DeleteAgentUseCase(repository: repo);

      await usecase.execute(agentId: 'a', workspaceId: 'ws-1');

      expect(repo.deleted, ['a']);
    });

    test('denies a cross-workspace delete', () async {
      final repo = _FakeRepo()..store['a'] = _agent('a', 'ws-1');
      final usecase = DeleteAgentUseCase(repository: repo);

      expect(
        () => usecase.execute(agentId: 'a', workspaceId: 'ws-OTHER'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(repo.deleted, isEmpty);
    });
  });
}
