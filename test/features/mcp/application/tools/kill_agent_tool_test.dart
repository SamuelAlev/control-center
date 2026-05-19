import 'dart:convert';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/ports/process_detection_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/agents/domain/usecases/kill_agent_processes.dart';
import 'package:control_center/features/dashboard/domain/entities/dashboard_status.dart';
import 'package:control_center/features/mcp/application/tools/kill_agent_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];

  List<Agent> get saved => List.unmodifiable(_agents);

  @override
  Future<void> upsert(Agent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }
  }

  @override
  Future<Agent?> getById(String id) async =>
      _agents.where((a) => a.id == id).firstOrNull;

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async =>
      _agents
          .where((a) => a.workspaceId == workspaceId && a.name == name)
          .firstOrNull;

  @override
  Stream<List<Agent>> watchAll() => Stream.value(_agents);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<void> delete(String id) async {
    _agents.removeWhere((a) => a.id == id);
  }
}

class _FakeRunLogRepository implements AgentRunLogRepository {
  final List<AgentRunLog> _logs = [];

  @override
  Stream<List<AgentRunLog>> watchByAgent(String agentId) =>
      Stream.value(_logs.where((l) => l.agentId == agentId).toList());

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
  Future<AgentRunLog?> getById(String id) async => null;

  @override
  Future<void> upsert(AgentRunLog log) async => _logs.add(log);
}

class _FakeProcessDetection implements ProcessDetectionPort {
  final List<int> killedPids = [];

  @override
  Future<void> killProcess(int pid) async {
    killedPids.add(pid);
  }

  @override
  Future<List<ActiveProcessInfo>> detect() async => [];
}

void main() {
  group('KillAgentTool', () {
    late _FakeAgentRepository agentRepo;
    late _FakeRunLogRepository runLogRepo;
    late _FakeProcessDetection processDetection;
    late KillAgentTool tool;

    setUp(() {
      agentRepo = _FakeAgentRepository();
      runLogRepo = _FakeRunLogRepository();
      processDetection = _FakeProcessDetection();
      tool = KillAgentTool(
        agentRepository: agentRepo,
        killAgentProcessesUseCase: KillAgentProcessesUseCase(
          runLogRepository: runLogRepo,
          processDetection: processDetection,
        ),
      );
    });

    test('has correct name', () {
      expect(tool.name, 'kill_agent');
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

    test('kills running agent processes', () async {
      await agentRepo.upsert(Agent(
        id: 'a-1',
        name: 'coder',
        title: 'Coder',
        agentMdPath: '/fake/a1.md',
        workspaceId: 'ws-1',
        skills: AgentSkills(const []),
        createdAt: DateTime(2026, 1, 1),
      ));
      await runLogRepo.upsert(AgentRunLog(
        id: 'log-1',
        agentId: 'a-1',
        startedAt: DateTime(2026, 1, 1),
        status: RunStatus.running,
        pid: 12345,
      ));

      final result =
          await tool.call({'workspace_id': 'ws-1', 'agent_id': 'a-1'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['status'], 'killed');
      expect(data['agent_id'], 'a-1');
      expect(processDetection.killedPids, contains(12345));
    });
  });
}
