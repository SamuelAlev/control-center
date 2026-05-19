import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_mcp/src/tools/list_agents_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRepository implements AgentRepository {
  final _controller = StreamController<List<Agent>>.broadcast();
  List<Agent> _agents = [];

  void setAgents(List<Agent> agents) {
    _agents = agents;
    _controller.add(agents);
  }

  @override
  Stream<List<Agent>> watchAll() =>
      Stream.value(List.unmodifiable(_agents));

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(List.unmodifiable(
        _agents.where((a) => a.workspaceId == workspaceId).toList(),
      ));

  @override
  Future<Agent?> getById(String id) async {
    return _agents.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async {
    return _agents
        .where((a) => a.workspaceId == workspaceId && a.name == name)
        .firstOrNull;
  }

  @override
  Future<String> upsert(Agent agent) async => agent.id;

  @override
  Future<void> delete(String id) async {
    _agents.removeWhere((a) => a.id == id);
    _controller.add(_agents);
  }
}

void main() {
  late _FakeAgentRepository repository;
  late ListAgentsTool tool;

  Agent testAgent(String id, String name, String title) {
    return Agent(
      id: id,
      name: name,
      title: title,
      agentMdPath: '/tmp/$name.md',
      workspaceId: 'ws-1',
      skills: AgentSkills(['code-review']),
      createdAt: DateTime(2025),
    );
  }

  setUp(() {
    repository = _FakeAgentRepository();
    tool = ListAgentsTool(repository: repository);
    repository.setAgents([]);
  });

  group('ListAgentsTool metadata', () {
    test('has correct name', () {
      expect(tool.name, 'list_agents');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(((schema['properties'] as Map<String, dynamic>)['workspace_id'] as Map<String, dynamic>)['type'], 'string');
    });

    test('definition returns correct ToolDef', () {
      final def = tool.definition;
      expect(def.name, 'list_agents');
    });
  });

  group('ListAgentsTool call', () {
    test('returns empty agents list', () async {
      repository.setAgents([]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['agents'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns agents with correct fields', () async {
      repository.setAgents([
        testAgent('a1', 'architect', 'Software Architect'),
      ]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(((data['agents'] as List<dynamic>)[0] as Map<String, dynamic>)['id'], 'a1');
      expect(((data['agents'] as List<dynamic>)[0] as Map<String, dynamic>)['name'], 'architect');
      expect(((data['agents'] as List<dynamic>)[0] as Map<String, dynamic>)['title'], 'Software Architect');
    });

    test('returns multiple agents', () async {
      repository.setAgents([
        testAgent('a1', 'architect', 'Architect'),
        testAgent('a2', 'reviewer', 'Reviewer'),
        testAgent('a3', 'tester', 'Tester'),
      ]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
      expect(data['agents'], hasLength(3));
    });

    test('returns agent skills as list', () async {
      repository.setAgents([
        Agent(
          id: 'a1',
          name: 'architect',
          title: 'Architect',
          agentMdPath: '/tmp/architect.md',
          workspaceId: 'ws-1',
          skills: AgentSkills(['planning', 'architecture']),
          createdAt: DateTime(2025),
        ),
      ]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(((data['agents'] as List<dynamic>)[0] as Map<String, dynamic>)['skills'], ['planning', 'architecture']);
    });
  });
}
