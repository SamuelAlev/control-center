import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/mcp/application/tools/fire_agent_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];
  final _controller = StreamController<List<Agent>>.broadcast();

  List<Agent> get saved => List.unmodifiable(_agents);

  @override
  Stream<List<Agent>> watchAll() => _controller.stream;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _controller.stream.map(
        (list) => list.where((a) => a.workspaceId == workspaceId).toList(),
      );

  @override
  Future<Agent?> getById(String id) async {
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async {
    for (final a in _agents) {
      if (a.workspaceId == workspaceId && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }
    _controller.add(List.unmodifiable(_agents));
  }

  @override
  Future<void> delete(String id) async {
    _agents.removeWhere((a) => a.id == id);
    _controller.add(List.unmodifiable(_agents));
  }

  void dispose() => _controller.close();
}

void main() {
  group('FireAgentTool', () {
    late _FakeAgentRepository repository;
    late FireAgentTool tool;

    setUp(() {
      repository = _FakeAgentRepository();
      tool = FireAgentTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'fire_agent');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], ['workspace_id', 'agent_id']);
    });

    test('returns error when agent not found', () async {
      final result =
          await tool.call({'workspace_id': 'ws-1', 'agent_id': 'nonexistent'});

      expect(result.isError, isTrue);
    });

    test('rejects an agent from a different workspace', () async {
      await repository.upsert(Agent(
        id: 'a-1',
        name: 'coder',
        title: 'Coder',
        agentMdPath: '/fake/a1.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2026, 1, 1),
      ));

      final result =
          await tool.call({'workspace_id': 'other-ws', 'agent_id': 'a-1'});

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('different workspace'));
      // The agent in the other workspace is untouched.
      expect(repository.saved, hasLength(1));
    });

    test('removes existing agent', () async {
      await repository.upsert(Agent(
        id: 'a-1',
        name: 'coder',
        title: 'Coder',
        agentMdPath: '/fake/a1.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2026, 1, 1),
      ));

      final result =
          await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['agent_id'], 'a-1');
      expect(data['name'], 'coder');
      expect(data['status'], 'removed');
      expect(repository.saved, isEmpty);
    });
  });
}
