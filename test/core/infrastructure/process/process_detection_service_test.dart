import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_infra/src/process/process_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentRunLogRepository implements AgentRunLogRepository {
  _FakeAgentRunLogRepository(this._logs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => const [];

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => null;
  final List<AgentRunLog> _logs;

  /// Serves only unfinished runs, as the store's status filter does.
  @override
  Future<List<AgentRunLog>> nonTerminal() async => [
    for (final log in _logs)
      if (log.isActive) log,
  ];

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchBySpace(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value(
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
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String conversationId,
  ) => Stream.value(
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
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];
  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      Stream.value(_logs.where((l) => l.agentId == agentId).toList());

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => _logs
      .cast<AgentRunLog?>()
      .firstWhere((l) => l?.id == id, orElse: () => null);

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
  Future<Agent?> getById(String workspaceId, String id) async =>
      _agents.cast<Agent?>().firstWhere((a) => a?.id == id, orElse: () => null);

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => _agents.cast<Agent?>().firstWhere(
    (a) => a?.workspaceId == workspaceId && a?.name == name,
    orElse: () => null,
  );

  @override
  Future<void> upsert(Agent agent) async {}

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  _FakeWorkspaceRepository(this._workspaces);
  final List<Workspace> _workspaces;

  @override
  Stream<List<Workspace>> watchAll() => Stream.value(_workspaces);

  @override
  Future<List<Workspace>> getAll() async => List.unmodifiable(_workspaces);

  @override
  Future<Workspace?> getById(String id) async =>
      _workspaces.where((w) => w.id == id).firstOrNull;

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
  ) async => false;

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {}
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

      final result = await service.detect(visible: (_) async => true);
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

      final result = await service.detect(visible: (_) async => true);
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

      final result = await service.detect(visible: (_) async => true);
      expect(result, isEmpty);
    });

    test('detect shows only runs of a workspace the caller sees', () async {
      final child = await Process.start('sleep', ['300']);
      addTearDown(() => child.kill(ProcessSignal.sigkill));
      final service = ProcessDetectionService(
        runLogRepo: _FakeAgentRunLogRepository([
          _runningLog(workspaceId: 'ws-a', pid: child.pid),
        ]),
        agentRepo: _FakeAgentRepository([]),
        workspaceRepo: _FakeWorkspaceRepository([]),
      );

      expect(
        await service.detect(visible: (ws) async => ws == 'ws-b'),
        isEmpty,
      );
      expect(
        (await service.detect(visible: (ws) async => ws == 'ws-a')).single.pid,
        child.pid,
      );
    }, skip: Platform.isWindows ? 'POSIX kill' : false);

    test(
      'stopRun signals only a live agent run its workspace admits',
      () async {
        final child = await Process.start('sleep', ['300']);
        addTearDown(() => child.kill(ProcessSignal.sigkill));
        final service = ProcessDetectionService(
          runLogRepo: _FakeAgentRunLogRepository([
            _runningLog(workspaceId: 'ws-a', pid: child.pid),
          ]),
          agentRepo: _FakeAgentRepository([]),
          workspaceRepo: _FakeWorkspaceRepository([]),
        );
        bool alive(int target) =>
            Process.runSync('kill', ['-0', '$target']).exitCode == 0;

        // Not an agent run at all: the test process itself.
        expect(await service.stopRun(pid, mayStop: (_) async => true), isFalse);
        expect(alive(pid), isTrue);
        // An agent run of a workspace the caller may not stop.
        expect(
          await service.stopRun(child.pid, mayStop: (ws) async => ws == 'ws-b'),
          isFalse,
        );
        expect(alive(child.pid), isTrue);

        expect(
          await service.stopRun(child.pid, mayStop: (ws) async => ws == 'ws-a'),
          isTrue,
        );
        await child.exitCode.timeout(const Duration(seconds: 10));
      },
      skip: Platform.isWindows ? 'POSIX kill' : false,
    );
  });
}
