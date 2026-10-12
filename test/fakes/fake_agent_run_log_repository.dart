import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';

/// In-memory fake [AgentRunLogRepository] for testing protocol handlers.
class FakeAgentRunLogRepository implements AgentRunLogRepository {
  final Map<String, AgentRunLog> _logs = {};

  /// Seed a log entry.
  void seed(AgentRunLog log) => _logs[log.id] = log;

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final log = _logs[id];
    // A run log id from another workspace lives in another database file, so it
    // must not resolve here.
    return log != null && log.workspaceId == workspaceId ? log : null;
  }

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final active =
        _logs.values
            .where(
              (l) =>
                  l.workspaceId == workspaceId &&
                  l.agentId == agentId &&
                  l.completedAt == null,
            )
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => _logs.values
      .where(
        (l) =>
            l.workspaceId == workspaceId &&
            l.conversationId == conversationId &&
            l.completedAt == null,
      )
      .toList();

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => _logs.values
      .where(
        (l) => l.workspaceId == workspaceId && l.pipelineRunId == pipelineRunId,
      )
      .toList();

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => _logs.values
      .where(
        (l) =>
            l.workspaceId == workspaceId &&
            l.pipelineRunId == pipelineRunId &&
            l.pipelineStepId == pipelineStepId,
      )
      .toList();

  @override
  Stream<List<AgentRunLog>> watchByAgent(
    String workspaceId,
    String agentId,
  ) async* {
    yield _logs.values.where((l) => l.agentId == agentId).toList();
  }

  @override
  Stream<List<AgentRunLog>> watchAll() async* {
    yield _logs.values.toList();
  }

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => watchAll().map(
    (logs) => logs.length <= limit ? logs : logs.sublist(0, limit),
  );

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
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String spaceId,
  ) async* {
    yield _logs.values
        .where(
          (l) =>
              l.workspaceId == workspaceId &&
              l.spaceId == spaceId &&
              l.completedAt == null,
        )
        .toList();
  }

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) async* {
    yield _logs.values
        .where(
          (l) =>
              l.workspaceId == workspaceId &&
              l.conversationId == conversationId,
        )
        .toList();
  }

  @override
  Stream<List<AgentRunLog>> watchBySpace(
    String workspaceId,
    String conversationId,
  ) async* {
    yield _logs.values
        .where(
          (l) =>
              l.workspaceId == workspaceId &&
              l.conversationId == conversationId,
        )
        .toList();
  }

  @override
  Future<void> upsert(AgentRunLog log) async {
    _logs[log.id] = log;
  }

  @override
  Future<void> updateCost(
    String workspaceId,
    String runId,
    RunCost cost,
  ) async {
    final current = _logs[runId];
    if (current == null || current.workspaceId != workspaceId) {
      return;
    }
    await upsert(current.copyWith(cost: cost));
  }

  @override
  Future<void> addChildCostMicros(
    String workspaceId,
    String runId,
    int amountMicros,
  ) async {
    if (amountMicros < 0) {
      throw ArgumentError.value(amountMicros, 'amountMicros');
    }
    final current = _logs[runId];
    if (current == null || current.workspaceId != workspaceId) {
      return;
    }
    final micros =
        (current.childCostMicros != 0
            ? current.childCostMicros
            : current.childCostCents * 10000) +
        amountMicros;
    await upsert(
      current.copyWith(
        childCostMicros: micros,
        childCostCents: (micros / 10000).round(),
      ),
    );
  }

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async {
    final current = _logs[runId];
    if (current == null || current.workspaceId != workspaceId) {
      return false;
    }
    final start =
        markRunning &&
        current.completedAt == null &&
        current.status == RunStatus.pending;
    final hasMetadata =
        pid != null ||
        logPath != null ||
        contextSnapshotJson != null ||
        lastOutputAt != null ||
        liveness != null ||
        errorFamily != null ||
        summary != null ||
        modelId != null ||
        effort != null ||
        taskFamily != null;
    if (!start && !hasMetadata) {
      return false;
    }
    await upsert(
      current.copyWith(
        pid: pid,
        status: start ? RunStatus.running : null,
        logPath: logPath,
        contextSnapshotJson: contextSnapshotJson,
        lastOutputAt: lastOutputAt,
        liveness: liveness,
        errorFamily: errorFamily,
        summary: summary,
        modelId: modelId,
        effort: effort,
        taskFamily: taskFamily,
      ),
    );
    return true;
  }

  @override
  Future<bool> completeIfActive(
    AgentRunLog completed, {
    bool writeCost = true,
  }) async {
    final current = _logs[completed.id];
    if (current == null ||
        current.workspaceId != completed.workspaceId ||
        current.completedAt != null ||
        !current.isActive) {
      return false;
    }
    await upsert(
      current.copyWith(
        completedAt: completed.completedAt,
        status: completed.status,
        summary: completed.summary,
        cost: writeCost
            ? completed.cost
            : current.cost.copyWith(durationMs: completed.cost.durationMs),
        liveness: completed.liveness,
        errorFamily: completed.errorFamily,
        continuationSummary: completed.continuationSummary,
        outputJson: completed.outputJson,
        outputRejections: completed.outputRejections,
        verification: completed.verification,
        latency: completed.latency,
        nativeSessionId: completed.nativeSessionId,
        resumedNativeSession: completed.resumedNativeSession,
      ),
    );
    return true;
  }
}
