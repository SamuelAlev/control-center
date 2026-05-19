import 'dart:convert';

import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/features/mcp/application/tools/get_agent_run_logs_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRunLogRepository implements AgentRunLogRepository {
  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async => null;

  final List<AgentRunLog> _logs = [];

  void addLog(AgentRunLog log) => _logs.add(log);

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];
  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) {
    return Stream.value(
      _logs
          .where((l) => l.workspaceId == workspaceId && l.agentId == agentId)
          .toList(),
    );
  }

  @override
  Stream<List<AgentRunLog>> watchAll() => Stream.value(_logs);

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) =>
      Stream.value(
        _logs
            .where(
              (l) =>
                  l.workspaceId == workspaceId &&
                  l.conversationId == conversationId &&
                  l.completedAt == null,
            )
            .toList(),
      );

  @override
  Future<AgentRunLog?> getById(String id) async =>
      _logs.where((l) => l.id == id).firstOrNull;

  @override
  Future<void> upsert(AgentRunLog log) async {
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
    } else {
      _logs.add(log);
    }
  }
}

void main() {
  group('GetAgentRunLogsTool', () {
    late _FakeAgentRunLogRepository repository;
    late GetAgentRunLogsTool tool;

    setUp(() {
      repository = _FakeAgentRunLogRepository();
      tool = GetAgentRunLogsTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'get_agent_run_logs');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], ['workspace_id', 'agent_id']);
    });

    test('returns empty list when no logs', () async {
      final result = await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['run_logs'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns run logs for agent', () async {
      repository.addLog(AgentRunLog(
        id: 'log-1',
        agentId: 'a-1',
        workspaceId: 'ws-1',
        startedAt: DateTime(2026, 1, 1),
        status: RunStatus.completed,
        summary: 'Done',
      ));
      repository.addLog(AgentRunLog(
        id: 'log-2',
        agentId: 'a-1',
        workspaceId: 'ws-1',
        startedAt: DateTime(2026, 1, 2),
        status: RunStatus.running,
        adapter: 'claude',
      ));

      final result = await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 2);
      expect(((data['run_logs'] as List<dynamic>)[0] as Map<String, dynamic>)['status'], 'completed');
      expect(((data['run_logs'] as List<dynamic>)[0] as Map<String, dynamic>)['summary'], 'Done');
      expect(((data['run_logs'] as List<dynamic>)[1] as Map<String, dynamic>)['adapter'], 'claude');
    });

    test('filters by agent_id', () async {
      repository.addLog(AgentRunLog(
        id: 'log-1',
        agentId: 'a-1',
        workspaceId: 'ws-1',
        startedAt: DateTime(2026, 1, 1),
        status: RunStatus.completed,
      ));
      repository.addLog(AgentRunLog(
        id: 'log-2',
        agentId: 'a-2',
        workspaceId: 'ws-1',
        startedAt: DateTime(2026, 1, 1),
        status: RunStatus.completed,
      ));

      final result = await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
    });

    test('filters out logs from another workspace', () async {
      repository.addLog(AgentRunLog(
        id: 'log-1',
        agentId: 'a-1',
        workspaceId: 'ws-1',
        startedAt: DateTime(2026, 1, 1),
        status: RunStatus.completed,
      ));
      repository.addLog(AgentRunLog(
        id: 'log-2',
        agentId: 'a-1',
        workspaceId: 'other-ws',
        startedAt: DateTime(2026, 1, 1),
        status: RunStatus.completed,
      ));

      final result = await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
    });

    test('respects limit', () async {
      for (var i = 0; i < 10; i++) {
        repository.addLog(AgentRunLog(
          id: 'log-$i',
          agentId: 'a-1',
          workspaceId: 'ws-1',
          startedAt: DateTime(2026, 1, 1),
          status: RunStatus.completed,
        ));
      }

      final result =
          await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1', 'limit': 3});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
