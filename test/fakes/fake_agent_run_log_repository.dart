import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';

/// In-memory fake [AgentRunLogRepository] for testing protocol handlers.
class FakeAgentRunLogRepository implements AgentRunLogRepository {
  final Map<String, AgentRunLog> _logs = {};

  /// Seed a log entry.
  void seed(AgentRunLog log) => _logs[log.id] = log;

  @override
  Future<AgentRunLog?> getById(String id) async => _logs[id];

  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async {
    final active = _logs.values
        .where((l) => l.agentId == agentId && l.completedAt == null)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async =>
      _logs.values
          .where(
            (l) =>
                l.workspaceId == workspaceId &&
                l.pipelineRunId == pipelineRunId,
          )
          .toList();

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async =>
      _logs.values
          .where(
            (l) =>
                l.workspaceId == workspaceId &&
                l.pipelineRunId == pipelineRunId &&
                l.pipelineStepRunId == pipelineStepId,
          )
          .toList();

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) async* {
    yield _logs.values.where((l) => l.agentId == agentId).toList();
  }

  @override
  Stream<List<AgentRunLog>> watchAll() async* {
    yield _logs.values.toList();
  }

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) async* {
    yield _logs.values
        .where(
          (l) =>
              l.workspaceId == workspaceId &&
              l.conversationId == conversationId &&
              l.completedAt == null,
        )
        .toList();
  }

  @override
  Future<void> upsert(AgentRunLog log) async {
    _logs[log.id] = log;
  }
}
