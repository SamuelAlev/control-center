import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';

/// In-memory [AgentRepository] fake — no RPC/DB needed.
class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];
  final _controller = StreamController<List<Agent>>.broadcast();

  void seed(List<Agent> agents) {
    _agents
      ..clear()
      ..addAll(agents);
    _controller.add(List.unmodifiable(_agents));
  }

  List<Agent> _sorted() =>
      [..._agents]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Stream<List<Agent>> watchAll() {
    Future.microtask(() => _controller.add(_sorted()));
    return _controller.stream;
  }

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => watchAll().map(
    (a) => a.where((x) => x.workspaceId == workspaceId).toList(),
  );

  @override
  Future<Agent?> getById(String workspaceId, String id) async => _agents
      .where((a) => a.id == id && a.workspaceId == workspaceId)
      .firstOrNull;

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => _agents
      .where((a) => a.workspaceId == workspaceId && a.name == name)
      .firstOrNull;

  @override
  Future<void> upsert(Agent agent) async {
    _agents.removeWhere((a) => a.id == agent.id);
    _agents.add(agent);
    _controller.add(_sorted());
  }

  @override
  Future<void> delete(String workspaceId, String id) async {
    _agents.removeWhere((a) => a.id == id && a.workspaceId == workspaceId);
    _controller.add(_sorted());
  }
}

Agent _agent({
  required String id,
  required String name,
  required String title,
  String skills = '',
  String? persona,
  String workspaceId = 'ws-test',
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '.kilo/$id.md',
    workspaceId: workspaceId,
    skills: AgentSkills(skills.isEmpty ? const [] : skills.split(',')),
    persona: persona,
    createdAt: DateTime(2024),
  );
}

void main() {
  group('agentsProvider', () {
    late _FakeAgentRepository repo;

    setUp(() {
      repo = _FakeAgentRepository();
    });

    test('returns empty list when no agents exist', () async {
      final container = ProviderContainer(
        overrides: [
          agentRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdOverride(),
        ],
      );
      addTearDown(container.dispose);
      container.listen(agentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(agentsProvider).value;
      expect(agents, isEmpty);
    });

    test('returns all agents sorted by name', () async {
      repo.seed([
        _agent(id: 'z', name: 'zephyr', title: 'Z', skills: 'w'),
        _agent(id: 'a', name: 'alpha', title: 'A', skills: 'a'),
      ]);

      final container = ProviderContainer(
        overrides: [
          agentRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdOverride(),
        ],
      );
      addTearDown(container.dispose);
      container.listen(agentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(agentsProvider).value;
      expect(agents?.length, 2);
      expect(agents?[0].name, 'alpha');
      expect(agents?[1].name, 'zephyr');
    });

    test('returns agents with correct fields', () async {
      repo.seed([
        _agent(
          id: 'r',
          name: 'reviewer',
          title: 'Code Reviewer',
          skills: 'review',
          persona: 'pedantic',
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          agentRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdOverride(),
        ],
      );
      addTearDown(container.dispose);
      container.listen(agentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(agentsProvider).value;
      expect(agents?.length, 1);
      expect(agents?.first.name, 'reviewer');
      expect(agents?.first.persona, 'pedantic');
    });
  });

  group('agentDetailProvider', () {
    late _FakeAgentRepository repo;

    setUp(() {
      repo = _FakeAgentRepository();
    });

    test('returns null when agent does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          agentRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdOverride(),
        ],
      );
      addTearDown(container.dispose);
      final agent = await container.read(
        agentDetailProvider('nonexistent').future,
      );
      expect(agent, null);
    });

    test('returns agent by id', () async {
      repo.seed([
        _agent(id: 'b', name: 'builder', title: 'Builder', skills: 'build'),
      ]);

      final container = ProviderContainer(
        overrides: [
          agentRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdOverride(),
        ],
      );
      addTearDown(container.dispose);
      final agent = await container.read(agentDetailProvider('b').future);
      expect(agent, isNotNull);
      expect(agent!.name, 'builder');
    });

    test('returns correct agent when multiple exist', () async {
      repo.seed([
        _agent(id: 'x', name: 'xray', title: 'X', skills: 's'),
        _agent(id: 'y', name: 'yankee', title: 'Y', skills: 'p'),
      ]);

      final container = ProviderContainer(
        overrides: [
          agentRepositoryProvider.overrideWithValue(repo),
          activeWorkspaceIdOverride(),
        ],
      );
      addTearDown(container.dispose);
      final agent = await container.read(agentDetailProvider('y').future);
      expect(agent!.name, 'yankee');
    });
  });
}
