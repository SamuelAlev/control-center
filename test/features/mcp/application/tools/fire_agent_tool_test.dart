import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_mcp/src/tools/fire_agent_tool.dart';
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

    // --- Approval & confirmation ---

    test('requiresApproval is true', () {
      expect(tool.requiresApproval, isTrue);
    });

    test('buildConfirmationRequest returns payload with title "Fire agent"', () {
      final payload = tool.buildConfirmationRequest({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
      });
      expect(payload, isNotNull);
      expect(payload!.title, 'Fire agent');
    });

    test('buildConfirmationRequest includes agent_id in detail', () {
      final payload = tool.buildConfirmationRequest({
        'workspace_id': 'ws-1',
        'agent_id': 'a-42',
      });
      expect(payload!.detail, contains('a-42'));
    });

    test('buildConfirmationRequest with missing agent_id shows unknown in detail',
        () {
      final payload = tool.buildConfirmationRequest({
        'workspace_id': 'ws-1',
      });
      expect(payload!.detail, contains('unknown'));
    });

    test('buildConfirmationRequest isDestructive is true', () {
      final payload = tool.buildConfirmationRequest({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
      });
      expect(payload!.isDestructive, isTrue);
    });

    // --- Argument validation ---

    test('returns error when workspace_id is missing', () async {
      final result = await tool.call({'agent_id': 'a-1'});

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
    });

    test('returns error when agent_id is missing', () async {
      final result = await tool.call({'workspace_id': 'ws-1'});

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('agent_id'));
    });

    test('returns error when workspace_id is an int', () async {
      final result = await tool.call({
        'workspace_id': 123,
        'agent_id': 'a-1',
      });

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('workspace_id'));
    });

    test('returns error when agent_id is an int', () async {
      final result = await tool.call({
        'workspace_id': 'ws-1',
        'agent_id': 456,
      });

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('agent_id'));
    });

    test('empty string workspace_id passes validation (not-found on lookup)',
        () async {
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
          await tool.call({'workspace_id': '', 'agent_id': 'a-1'});

      // Workspace mismatch is caught, not a crash.
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('different workspace'));
    });

    test('empty string agent_id returns not-found error', () async {
      final result =
          await tool.call({'workspace_id': 'ws-1', 'agent_id': ''});

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    });

    // --- Success path details ---

    test('success result JSON has agent_id, name, and status fields', () async {
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
      expect(data.keys, containsAll(['agent_id', 'name', 'status']));
      expect(data['agent_id'], 'a-1');
      expect(data['name'], 'coder');
      expect(data['status'], 'removed');
    });

    test('agent is deleted from repository after successful call', () async {
      await repository.upsert(Agent(
        id: 'a-1',
        name: 'coder',
        title: 'Coder',
        agentMdPath: '/fake/a1.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2026, 1, 1),
      ));

      await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1'});

      final fetched = await repository.getById('a-1');
      expect(fetched, isNull);
    });

    test('removes only the targeted agent, leaving others intact', () async {
      await repository.upsert(Agent(
        id: 'a-1',
        name: 'coder',
        title: 'Coder',
        agentMdPath: '/fake/a1.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2026, 1, 1),
      ));
      await repository.upsert(Agent(
        id: 'a-2',
        name: 'tester',
        title: 'Tester',
        agentMdPath: '/fake/a2.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2026, 1, 1),
      ));
      await repository.upsert(Agent(
        id: 'a-3',
        name: 'reviewer',
        title: 'Reviewer',
        agentMdPath: '/fake/a3.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2026, 1, 1),
      ));

      final result =
          await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-2'});

      expect(result.isError, isFalse);
      expect(await repository.getById('a-2'), isNull);
      expect(await repository.getById('a-1'), isNotNull);
      expect(await repository.getById('a-3'), isNotNull);
      expect(repository.saved, hasLength(2));
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
