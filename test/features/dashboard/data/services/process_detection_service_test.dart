import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/dashboard/data/services/process_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRunLogRepository implements AgentRunLogRepository {
  _FakeAgentRunLogRepository(this._logs);
  final List<AgentRunLog> _logs;

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
  Stream<List<AgentRunLog>> watchByAgent(String agentId) => Stream.value(
    _logs.where((l) => l.agentId == agentId).toList(),
  );

  @override
  Future<AgentRunLog?> getById(String id) async =>
      _logs.cast<AgentRunLog?>().firstWhere((l) => l?.id == id, orElse: () => null);

  @override
  Future<void> upsert(AgentRunLog log) async {}
}

class _FakeAgentRepository implements AgentRepository {
  _FakeAgentRepository(this._agents);
  final List<Agent> _agents;

  @override
  Stream<List<Agent>> watchAll() => Stream.value(_agents);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String id) async =>
      _agents.cast<Agent?>().firstWhere((a) => a?.id == id, orElse: () => null);

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => _agents
      .cast<Agent?>()
      .firstWhere(
        (a) => a?.workspaceId == workspaceId && a?.name == name,
        orElse: () => null,
      );

  @override
  Future<void> upsert(Agent agent) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  _FakeWorkspaceRepository(this._workspaces);
  final List<Workspace> _workspaces;

  @override
  Stream<List<Workspace>> watchAll() => Stream.value(_workspaces);

  @override
  Future<String> upsert(Workspace workspace) async => workspace.id;

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {}

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async =>
      false;

  @override
  Future<void> linkRepoToWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}
}

AgentRunLog _runningLog({
  String id = 'log-1',
  String agentId = 'agent-1',
  String? workspaceId,
  int? pid = 1,
}) {
  return AgentRunLog(
    id: id,
    agentId: agentId,
    workspaceId: workspaceId,
    startedAt: DateTime(2024),
    status: RunStatus.running,
    pid: pid,
  );
}

void main() {
  group('ProcessDetectionService', () {
    test('detect returns empty list when no running logs', () async {
      final service = ProcessDetectionService(
        runLogRepo: _FakeAgentRunLogRepository([]),
        agentRepo: _FakeAgentRepository([]),
        workspaceRepo: _FakeWorkspaceRepository([]),
      );

      final result = await service.detect();
      expect(result, isEmpty);
    });

    test('detect filters logs without pid', () async {
      final service = ProcessDetectionService(
        runLogRepo: _FakeAgentRunLogRepository([
          _runningLog(id: 'log-1', pid: null),
        ]),
        agentRepo: _FakeAgentRepository([]),
        workspaceRepo: _FakeWorkspaceRepository([]),
      );

      final result = await service.detect();
      expect(result, isEmpty);
    });

    test('detect filters non-running logs', () async {
      final service = ProcessDetectionService(
        runLogRepo: _FakeAgentRunLogRepository([
          AgentRunLog(
            id: 'log-1',
            agentId: 'agent-1',
            startedAt: DateTime(2024),
            status: RunStatus.completed,
            pid: 42,
          ),
        ]),
        agentRepo: _FakeAgentRepository([]),
        workspaceRepo: _FakeWorkspaceRepository([]),
      );

      final result = await service.detect();
      expect(result, isEmpty);
    });

    test('killProcess does not throw', () async {
      final service = ProcessDetectionService(
        runLogRepo: _FakeAgentRunLogRepository([]),
        agentRepo: _FakeAgentRepository([]),
        workspaceRepo: _FakeWorkspaceRepository([]),
      );

      await service.killProcess(99999);
    });
  });
}
