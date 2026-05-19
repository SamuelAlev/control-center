import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 6, 30, 12);

  test('phases serialize to snake_case wire strings', () {
    expect(TaskPhase.waitingLocalDirectory.wire, 'waiting_local_directory');
    expect(TaskPhase.running.wire, 'running');
    expect(TaskPhase.completed.wire, 'completed');
    expect(TaskPhase.failed.wire, 'failed');
  });

  test('message types serialize to snake_case wire strings', () {
    expect(TaskMessageType.toolUse.wire, 'tool_use');
    expect(TaskMessageType.toolResult.wire, 'tool_result');
    expect(TaskMessageType.thinking.wire, 'thinking');
  });

  test('lifecycle events carry task_id, seq and phase on the wire', () {
    final running = TaskRunning(
      taskId: 'run-1',
      seq: 3,
      workspaceId: 'ws1',
      agentId: 'a1',
      occurredAt: now,
    );
    final wire = running.toWire();
    expect(wire['task_id'], 'run-1');
    expect(wire['seq'], 3);
    expect(wire['phase'], 'running');
    expect(wire['workspace_id'], 'ws1');
    expect(wire['agent_id'], 'a1');
  });

  test('TaskWaitingLocalDirectory carries the locked path + holder', () {
    final waiting = TaskWaitingLocalDirectory(
      taskId: 'run-2',
      workspaceId: 'ws1',
      seq: 0,
      lockedPath: '/repo',
      holderTaskId: 'run-1',
      occurredAt: now,
    );
    final wire = waiting.toWire();
    expect(wire['phase'], 'waiting_local_directory');
    expect(wire['locked_path'], '/repo');
    expect(wire['holder_task_id'], 'run-1');
  });

  test(
    'TaskMessage carries the typed message payload under the progress phase',
    () {
      final msg = TaskMessage(
        taskId: 'run-3',
        workspaceId: 'ws1',
        seq: 7,
        messageType: TaskMessageType.toolUse,
        content: 'run_tests',
        occurredAt: now,
      );
      final wire = msg.toWire();
      expect(wire['phase'], 'progress');
      expect(wire['message_type'], 'tool_use');
      expect(wire['content'], 'run_tests');
    },
  );

  test('TaskFailed carries the error message', () {
    final failed = TaskFailed(
      taskId: 'run-4',
      workspaceId: 'ws1',
      seq: 9,
      errorMessage: 'boom',
      occurredAt: now,
    );
    expect(failed.toWire()['error_message'], 'boom');
    expect(failed.phase, TaskPhase.failed);
  });

  test('every lifecycle event is a TaskLifecycleEvent (sealed base)', () {
    final List<TaskLifecycleEvent> events = [
      TaskQueued(taskId: 't', workspaceId: 'ws1', seq: 0, occurredAt: now),
      TaskDispatched(taskId: 't', workspaceId: 'ws1', seq: 1, occurredAt: now),
      TaskRunning(taskId: 't', workspaceId: 'ws1', seq: 2, occurredAt: now),
      TaskProgress(taskId: 't', workspaceId: 'ws1', seq: 3, occurredAt: now),
      TaskCompleted(taskId: 't', workspaceId: 'ws1', seq: 4, occurredAt: now),
      TaskCancelled(taskId: 't', workspaceId: 'ws1', seq: 5, occurredAt: now),
    ];
    expect(events.map((e) => e.phase.wire), [
      'queued',
      'dispatch',
      'running',
      'progress',
      'completed',
      'cancelled',
    ]);
  });
}
