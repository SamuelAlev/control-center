import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/dispatch/domain/services/run_settlement.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

AgentRunLog _running({
  String id = 'run-1',
  AgentRunRole role = AgentRunRole.main,
  String? parentRunId,
  String? requestedByUserId = 'user-1',
}) => AgentRunLog(
  id: id,
  agentId: 'agent-1',
  workspaceId: 'ws-1',
  spaceId: 'space-1',
  conversationId: 'conv-1',
  startedAt: DateTime.utc(2026, 7, 1),
  status: RunStatus.running,
  role: role,
  parentRunId: parentRunId,
  childCostMicros: 250,
  wakeIds: const ['wake-1'],
  requestedByUserId: requestedByUserId,
);

void main() {
  late FakeAgentRunLogRepository runLogs;
  late DomainEventBus bus;
  late List<AgentRunSettled> settled;
  late RunSettlement settlement;

  setUp(() {
    runLogs = FakeAgentRunLogRepository();
    bus = DomainEventBus();
    settled = [];
    bus.on<AgentRunSettled>().listen(settled.add);
    settlement = RunSettlement(runLogs: runLogs, eventBus: bus);
  });

  tearDown(() => bus.dispose());

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  AgentRunLog terminal(AgentRunLog run, RunStatus status) => run.copyWith(
    status: status,
    completedAt: DateTime.utc(2026, 7, 1, 1),
    cost: const RunCost(costMicros: 1000),
  );

  test('the first terminal write is announced after it lands, with the '
      "run's facts", () async {
    final run = _running();
    runLogs.seed(run);

    final won = await settlement.settle(
      terminal(run, RunStatus.completed),
      endReason: RunEndReason.completed,
    );
    await flush();

    expect(won, isTrue);
    final row = await runLogs.getById('ws-1', run.id);
    expect(row!.status, RunStatus.completed);
    expect(row.endReason, RunEndReason.completed);
    final event = settled.single;
    expect(event.agentId, 'agent-1');
    expect(event.workspaceId, 'ws-1');
    expect(event.spaceId, 'space-1');
    expect(event.conversationId, 'conv-1');
    expect(event.status, RunStatus.completed);
    expect(event.endReason, RunEndReason.completed);
    // The run's own cost plus its subagents'.
    expect(event.costMicros, 1250);
    expect(event.wakeIds, ['wake-1']);
    expect(event.requestedByUserId, 'user-1');
    expect(event.limitResetsAt, isNull);
  });

  test('a second terminal write publishes nothing', () async {
    final run = _running();
    runLogs.seed(run);

    await settlement.settle(
      terminal(run, RunStatus.error),
      endReason: RunEndReason.stoppedByUser,
    );
    final second = await settlement.settle(
      terminal(run, RunStatus.completed),
      endReason: RunEndReason.completed,
    );
    await flush();

    expect(second, isFalse);
    expect(settled, hasLength(1));
    expect(settled.single.endReason, RunEndReason.stoppedByUser);
    final row = await runLogs.getById('ws-1', run.id);
    expect(row!.status, RunStatus.error);
    expect(row.endReason, RunEndReason.stoppedByUser);
  });

  test('the reset time travels only with a usage-limit end', () async {
    final resets = DateTime.utc(2026, 7, 2);
    final limited = _running(id: 'run-limit');
    final failed = _running(id: 'run-error');
    runLogs
      ..seed(limited)
      ..seed(failed);

    await settlement.settle(
      terminal(limited, RunStatus.error),
      endReason: RunEndReason.usageLimit,
      limitResetsAt: resets,
    );
    await settlement.settle(
      terminal(failed, RunStatus.error),
      endReason: RunEndReason.error,
      limitResetsAt: resets,
    );
    await flush();

    expect(settled[0].limitResetsAt, resets);
    expect(settled[1].limitResetsAt, isNull);
  });

  test('a subagent row is written but not announced', () async {
    final sub = _running(id: 'run-sub', role: AgentRunRole.sub);
    final child = _running(id: 'run-child', parentRunId: 'run-parent');
    runLogs
      ..seed(sub)
      ..seed(child);

    expect(
      await settlement.settle(
        terminal(sub, RunStatus.completed),
        endReason: RunEndReason.completed,
      ),
      isTrue,
    );
    await settlement.settle(
      terminal(child, RunStatus.completed),
      endReason: RunEndReason.completed,
    );
    await flush();

    expect(settled, isEmpty);
    expect(
      (await runLogs.getById('ws-1', 'run-sub'))!.status,
      RunStatus.completed,
    );
  });

  test('the requester is the one the row recorded, whatever the caller '
      'built', () async {
    final run = _running();
    runLogs.seed(run);

    // A caller that never knew the requester (the reaper at boot, a kill,
    // a client's completeIfActive) builds its terminal row without one.
    await settlement.settle(
      terminal(run, RunStatus.error).copyWith(removeRequestedByUserId: true),
      endReason: RunEndReason.serverStopped,
    );
    await flush();

    expect(settled.single.requestedByUserId, 'user-1');
    expect(
      (await runLogs.getById('ws-1', run.id))!.requestedByUserId,
      'user-1',
    );
  });

  test('a run the server started names no requester', () async {
    final run = _running(requestedByUserId: null);
    runLogs.seed(run);

    await settlement.settle(
      terminal(run, RunStatus.completed),
      endReason: RunEndReason.completed,
    );
    await flush();

    expect(settled.single.requestedByUserId, isNull);
  });

  test('a non-terminal status is refused', () async {
    final run = _running();
    runLogs.seed(run);

    expect(
      () => settlement.settle(run, endReason: RunEndReason.completed),
      throwsArgumentError,
    );
  });
}
