import 'dart:async';

import 'package:control_center/core/domain/entities/active_process_info.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/ports/process_detection_port.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/agents/domain/usecases/kill_agent_processes.dart';
import 'package:test/test.dart';

// ── Fakes ────────────────────────────────────────────────────────────────

class FakeAgentRunLogRepository implements AgentRunLogRepository {
  FakeAgentRunLogRepository(this.logs);
  final List<AgentRunLog> logs;

  @override
  Stream<List<AgentRunLog>> watchByAgent(String agentId) async* {
    yield logs.where((l) => l.agentId == agentId).toList();
  }

  @override
  Stream<List<AgentRunLog>> watchAll() async* {
    yield logs;
  }

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) async* {
    yield logs
        .where(
          (l) =>
              l.workspaceId == workspaceId &&
              l.conversationId == conversationId &&
              l.completedAt == null,
        )
        .toList();
  }

  @override
  Future<AgentRunLog?> getById(String id) async {
    return logs.cast<AgentRunLog?>().firstWhere(
      (l) => l!.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> upsert(AgentRunLog log) async {
    throw UnimplementedError('FakeAgentRunLogRepository.upsert');
  }
}

class FakeProcessDetectionPort implements ProcessDetectionPort {
  FakeProcessDetectionPort(this.processes);
  final List<int> killedPids = [];
  final List<ActiveProcessInfo> processes;

  @override
  Future<List<ActiveProcessInfo>> detect() async => processes;

  @override
  Future<void> killProcess(int pid) async {
    killedPids.add(pid);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

Agent _agent() => Agent(
      id: 'agent-1',
      name: 'test-agent',
      title: 'Test',
      agentMdPath: '/fake',
      workspaceId: 'ws-1',
      skills: AgentSkills(const []),
      createdAt: DateTime(2026),
    );

AgentRunLog _runningLog({int? pid}) => AgentRunLog(
      id: 'log-1',
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      status: RunStatus.running,
      startedAt: DateTime(2026),
      pid: pid,
    );

AgentRunLog _completedLog() => AgentRunLog(
      id: 'log-2',
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      status: RunStatus.completed,
      startedAt: DateTime(2026),
      completedAt: DateTime(2026),
    );

ActiveProcessInfo _process({
  int pid = 100,
  String command = 'node test-agent',
}) =>
    ActiveProcessInfo(
      agentName: 'test-agent',
      workspaceName: 'workspace-1',
      pid: pid,
      command: command,
      startTime: DateTime(2026),
    );

void main() {
  group('KillAgentProcessesUseCase', () {
    test('No running logs → no kills', () async {
      final detection = FakeProcessDetectionPort([]);
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository([_completedLog()]),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      expect(detection.killedPids, isEmpty);
    });

    test('Running log with pid → kills that pid', () async {
      final detection = FakeProcessDetectionPort([]);
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository([_runningLog(pid: 42)]),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      expect(detection.killedPids, [42]);
    });

    test('Multiple running logs with pids → kills all', () async {
      final detection = FakeProcessDetectionPort([]);
      final logs = [
        _runningLog(pid: 10),
        _runningLog(pid: 20),
        _runningLog(pid: 30),
      ];
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository(logs),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      expect(detection.killedPids, unorderedEquals([10, 20, 30]));
    });

    test('Non-running logs ignored', () async {
      final detection = FakeProcessDetectionPort([]);
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository(
          [_completedLog().copyWith(pid: 99)],
        ),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      expect(detection.killedPids, isEmpty);
    });

    test('Running logs without pid ignored', () async {
      final detection = FakeProcessDetectionPort([]);
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository([_runningLog()]),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      expect(detection.killedPids, isEmpty);
    });

    test('Extra processes matching agent name killed as well', () async {
      final detection = FakeProcessDetectionPort([
        _process(pid: 200, command: 'node test-agent --flag'),
      ]);
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository([_runningLog(pid: 42)]),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      expect(detection.killedPids, containsAll([42, 200]));
    });

    test('Extra processes NOT matching agent name NOT killed', () async {
      final detection = FakeProcessDetectionPort([
        _process(pid: 300, command: 'node other-agent'),
      ]);
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository([_runningLog(pid: 42)]),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      expect(detection.killedPids, [42]);
      expect(detection.killedPids, isNot(contains(300)));
    });

    test('Pids already killed from logs not killed again via process detection',
        () async {
      // The process detection returns a process whose pid was already killed
      // from a log, but with a command matching the agent name.
      final detection = FakeProcessDetectionPort([
        _process(pid: 42, command: 'node test-agent --other'),
      ]);
      final useCase = KillAgentProcessesUseCase(
        runLogRepository: FakeAgentRunLogRepository([_runningLog(pid: 42)]),
        processDetection: detection,
      );

      await useCase.execute(_agent());

      // Only killed once — the log-path kill, not the process-detection dupe.
      expect(detection.killedPids, [42]);
    });
  });
}
