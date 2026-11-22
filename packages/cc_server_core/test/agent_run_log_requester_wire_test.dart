import 'package:cc_domain/cc_domain.dart' show AuthException, NotFoundException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_host/cc_host.dart'
    show RepoOp, RepoOpContext, SessionCapability;
import 'package:cc_infra/cc_infra.dart' show ProcessDetectionService;
import 'package:cc_server_core/src/catalog/agent_run_log_write_ops.dart';
import 'package:test/test.dart';

/// Records every stop it is asked for; stops nothing.
class _Processes implements ProcessDetectionService {
  final List<int> stopped = [];

  @override
  Future<bool> stopRun(
    int pid, {
    required Future<bool> Function(String workspaceId) mayStop,
  }) async {
    if (!await mayStop('ws-1')) {
      return false;
    }
    stopped.add(pid);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Run rows, recorded at dispatch with their requester, and the terminal
/// write the way the real store does it: the requester column is never
/// written by it.
class _Runs implements AgentRunLogRepository {
  _Runs(List<AgentRunLog> rows) : rows = {for (final r in rows) r.id: r};

  final Map<String, AgentRunLog> rows;

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final row = rows[id];
    return row != null && row.workspaceId == workspaceId ? row : null;
  }

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      Stream.value([
        for (final r in rows.values)
          if (r.workspaceId == workspaceId && r.agentId == agentId) r,
      ]);

  @override
  Future<bool> completeIfActive(
    AgentRunLog completed, {
    bool writeCost = true,
  }) async {
    final row = rows[completed.id];
    if (row == null || row.completedAt != null) {
      return false;
    }
    rows[row.id] = row.copyWith(
      status: completed.status,
      completedAt: completed.completedAt,
      summary: completed.summary,
      endReason: completed.endReason,
    );
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [_Runs] holding one run, [row].
class _OneRun extends _Runs {
  _OneRun(AgentRunLog row) : super([row]);

  AgentRunLog get row => rows.values.single;
}

/// One agent, `agent-1` of `ws-1`.
class _Agents implements AgentRepository {
  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      workspaceId == 'ws-1' && id == 'agent-1'
      ? Agent(
          id: id,
          name: 'Builder',
          title: 'Builder',
          agentMdPath: '/agents/$id.md',
          workspaceId: workspaceId,
          skills: AgentSkills(const []),
          createdAt: DateTime.utc(2026),
        )
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The space gate of `agent_run_log.get` (`PrDataGate.requireRunLog`):
/// `space-secret` is a space the caller may not read; a run with no space
/// asks nothing.
Future<void> _requireRunLog(
  String workspaceId,
  String userId,
  AgentRunLog log,
) async {
  if (log.spaceId == 'space-secret') {
    throw const AuthException('space hidden');
  }
}

List<RepoOp> _ops(_Runs runs, _Processes? processes, DomainEventBus? bus) =>
    buildAgentRunLogWriteOps(
      runs,
      agentRepository: _Agents(),
      processDetection: processes,
      eventBus: bus,
      requireRunLog: _requireRunLog,
    );

AgentRunLog _running() => AgentRunLog(
  id: 'run-1',
  agentId: 'agent-1',
  workspaceId: 'ws-1',
  spaceId: 'space-1',
  conversationId: 'conv-1',
  startedAt: DateTime.utc(2026, 7, 1),
  status: RunStatus.running,
  requestedByUserId: 'olga',
  pid: 4242,
);

/// A run's requester is the server's record of who started it: no client op
/// writes a run log, and a run a person stops still settles for the person
/// whose run it was.
void main() {
  test('the only client write is a stop: no row, cost, runtime or end', () {
    final ops = _ops(_OneRun(_running()), _Processes(), null);

    expect(ops.map((o) => o.name), [
      'agent_run_log.stop',
      'agents.killProcesses',
    ]);
    for (final op in ops) {
      expect(op.requiredCapability, SessionCapability.fullClient);
    }
    expect(
      _ops(_OneRun(_running()), null, null),
      isEmpty,
      reason: 'no process detector, no stop',
    );
  });

  group('agent_run_log.stop', () {
    Future<Map<String, dynamic>> stop(
      _OneRun runs,
      _Processes processes,
      DomainEventBus bus, {
      String workspaceId = 'ws-1',
      String runId = 'run-1',
    }) async {
      final op = _ops(
        runs,
        processes,
        bus,
      ).singleWhere((o) => o.name == 'agent_run_log.stop');
      final result = await op.handler(
        RepoOpContext(
          args: {'run_id': runId},
          workspaceId: workspaceId,
          deviceId: 'device-1',
          userId: 'mallory',
        ),
      );
      return (result as Map).cast<String, dynamic>();
    }

    test("signals the run's own process and settles it as the requester's "
        'run, stopped by a person, whoever pressed Stop', () async {
      final runs = _OneRun(_running());
      final processes = _Processes();
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final settled = <AgentRunSettled>[];
      bus.on<AgentRunSettled>().listen(settled.add);

      expect(await stop(runs, processes, bus), {'stopped': true});
      await Future<void>.delayed(Duration.zero);

      expect(processes.stopped, [4242]);
      expect(runs.row.status, RunStatus.error);
      expect(runs.row.summary, 'Killed by user');
      expect(runs.row.endReason, RunEndReason.stoppedByUser);
      expect(settled.single.endReason, RunEndReason.stoppedByUser);
      expect(settled.single.requestedByUserId, 'olga');
    });

    test('a finished run, a run with no process and an unknown run are not '
        'found, and nothing is signalled', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final processes = _Processes();
      final finished = _OneRun(
        _running().copyWith(
          status: RunStatus.completed,
          completedAt: DateTime.utc(2026, 7, 2),
        ),
      );
      final noProcess = _OneRun(
        AgentRunLog(
          id: 'run-1',
          agentId: 'agent-1',
          workspaceId: 'ws-1',
          startedAt: DateTime.utc(2026, 7, 1),
          status: RunStatus.running,
        ),
      );
      for (final runs in [finished, noProcess]) {
        await expectLater(
          stop(runs, processes, bus),
          throwsA(isA<NotFoundException>()),
        );
      }
      await expectLater(
        stop(_OneRun(_running()), processes, bus, runId: 'run-nope'),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        stop(_OneRun(_running()), processes, bus, workspaceId: 'ws-2'),
        throwsA(isA<NotFoundException>()),
        reason: "another workspace's run is not found from this one",
      );
      expect(processes.stopped, isEmpty);
      expect(finished.row.status, RunStatus.completed);
    });

    test('a run in a space the caller may not read answers exactly like a '
        'missing one, and keeps running', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final processes = _Processes();
      final hidden = _OneRun(_running().copyWith(spaceId: 'space-secret'));

      Future<String> refusal(Future<Object?> call) async {
        try {
          await call;
        } on NotFoundException catch (e) {
          return e.message;
        }
        fail('expected not found');
      }

      expect(
        await refusal(stop(hidden, processes, bus)),
        await refusal(stop(hidden, processes, bus, runId: 'run-nope')),
      );
      expect(processes.stopped, isEmpty);
      expect(hidden.row.status, RunStatus.running);
      expect(hidden.row.completedAt, isNull);
    });

    test('a run with no space stops as before', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final processes = _Processes();
      final runs = _OneRun(
        AgentRunLog(
          id: 'run-1',
          agentId: 'agent-1',
          workspaceId: 'ws-1',
          startedAt: DateTime.utc(2026, 7, 1),
          status: RunStatus.running,
          pid: 7,
        ),
      );

      expect(await stop(runs, processes, bus), {'stopped': true});
      expect(processes.stopped, [7]);
      expect(runs.row.endReason, RunEndReason.stoppedByUser);
    });
  });

  group('agents.killProcesses', () {
    test("stops the agent's live runs the caller may read; a run in a space "
        'they may not read keeps running and is not counted', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final processes = _Processes();
      final runs = _Runs([
        _running(),
        _running().copyWith(id: 'run-hidden', spaceId: 'space-secret', pid: 99),
        AgentRunLog(
          id: 'run-none',
          agentId: 'agent-1',
          workspaceId: 'ws-1',
          startedAt: DateTime.utc(2026, 7, 1),
          status: RunStatus.running,
          pid: 7,
        ),
      ]);
      final op = _ops(
        runs,
        processes,
        bus,
      ).singleWhere((o) => o.name == 'agents.killProcesses');

      final result = await op.handler(
        const RepoOpContext(
          args: {'agent_id': 'agent-1'},
          workspaceId: 'ws-1',
          deviceId: 'device-1',
          userId: 'mallory',
        ),
      );

      expect(result, {'killed': 2});
      expect(processes.stopped, unorderedEquals([4242, 7]));
      expect(runs.rows['run-hidden']!.status, RunStatus.running);
      expect(runs.rows['run-hidden']!.completedAt, isNull);
      expect(runs.rows['run-1']!.endReason, RunEndReason.stoppedByUser);
      expect(runs.rows['run-none']!.endReason, RunEndReason.stoppedByUser);
    });

    test("another workspace's agent is not found from this one", () async {
      final processes = _Processes();
      final op = _ops(
        _OneRun(_running()),
        processes,
        null,
      ).singleWhere((o) => o.name == 'agents.killProcesses');
      await expectLater(
        op.handler(
          const RepoOpContext(
            args: {'agent_id': 'agent-1'},
            workspaceId: 'ws-2',
            deviceId: 'device-1',
            userId: 'mallory',
          ),
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(processes.stopped, isEmpty);
    });
  });

  test("a person's stop settles for the person whose run it was, as their "
      'stop', () async {
    final runs = _OneRun(_running());
    final bus = DomainEventBus();
    addTearDown(bus.dispose);
    final settled = <AgentRunSettled>[];
    bus.on<AgentRunSettled>().listen(settled.add);

    await settleKilledRun(runs, bus, _running(), DateTime.utc(2026, 7, 1, 1));
    await Future<void>.delayed(Duration.zero);

    expect(runs.row.status, RunStatus.error);
    expect(runs.row.summary, 'Killed by user');
    expect(settled.single.endReason, RunEndReason.stoppedByUser);
    expect(settled.single.requestedByUserId, 'olga');
  });
}
