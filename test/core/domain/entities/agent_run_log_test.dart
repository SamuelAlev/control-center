import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testStartedAt = DateTime(2024, 1, 1, 10, 0, 0);
  final testCompletedAt = DateTime(2024, 1, 1, 10, 30, 0);

  AgentRunLog createLog({
    String id = 'log-1',
    String agentId = 'agent-1',
    String? workspaceId,
    String? conversationId,
    DateTime? startedAt,
    DateTime? completedAt,
    RunStatus status = RunStatus.running,
    String? summary,
    String? adapter,
    int? pid,
  }) {
    return AgentRunLog(
      id: id,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      startedAt: startedAt ?? testStartedAt,
      completedAt: completedAt,
      status: status,
      summary: summary,
      adapter: adapter,
      pid: pid,
    );
  }

  group('RunStatus', () {
    test('has four values', () {
      expect(RunStatus.values.length, 4);
      expect(RunStatus.values, contains(RunStatus.pending));
      expect(RunStatus.values, contains(RunStatus.running));
      expect(RunStatus.values, contains(RunStatus.completed));
      expect(RunStatus.values, contains(RunStatus.error));
    });
  });

  group('AgentRunLog', () {
    group('constructor', () {
      test('creates log with required fields', () {
        final log = AgentRunLog(
          id: 'log-1',
          agentId: 'agent-1',
          startedAt: testStartedAt,
          status: RunStatus.running,
        );
        expect(log.id, 'log-1');
        expect(log.agentId, 'agent-1');
        expect(log.startedAt, testStartedAt);
        expect(log.status, RunStatus.running);
        expect(log.workspaceId, isNull);
        expect(log.conversationId, isNull);
        expect(log.completedAt, isNull);
        expect(log.summary, isNull);
        expect(log.adapter, isNull);
      });

      test('creates log with all fields', () {
        final log = AgentRunLog(
          id: 'log-full',
          agentId: 'agent-2',
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          startedAt: testStartedAt,
          completedAt: testCompletedAt,
          status: RunStatus.completed,
          summary: 'All tasks done.',
          adapter: 'openai',
        );
        expect(log.id, 'log-full');
        expect(log.agentId, 'agent-2');
        expect(log.workspaceId, 'ws-1');
        expect(log.conversationId, 'conv-1');
        expect(log.startedAt, testStartedAt);
        expect(log.completedAt, testCompletedAt);
        expect(log.status, RunStatus.completed);
        expect(log.summary, 'All tasks done.');
        expect(log.adapter, 'openai');
      });

      test('creates log in error state', () {
        final log = AgentRunLog(
          id: 'log-err',
          agentId: 'agent-3',
          startedAt: testStartedAt,
          status: RunStatus.error,
          summary: 'Connection timeout',
        );
        expect(log.status, RunStatus.error);
        expect(log.isError, isTrue);
        expect(log.summary, 'Connection timeout');
      });

      test('constructor asserts agentId is not empty', () {
        expect(
          () => AgentRunLog(
            id: 'log-x',
            agentId: '',
            startedAt: testStartedAt,
            status: RunStatus.running,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('status getters', () {
      test('isRunning is true when status is running', () {
        final log = createLog(status: RunStatus.running);
        expect(log.isRunning, isTrue);
        expect(log.isCompleted, isFalse);
        expect(log.isError, isFalse);
      });

      test('isCompleted is true when status is completed', () {
        final log = createLog(status: RunStatus.completed);
        expect(log.isCompleted, isTrue);
        expect(log.isRunning, isFalse);
        expect(log.isError, isFalse);
      });

      test('isError is true when status is error', () {
        final log = createLog(status: RunStatus.error);
        expect(log.isError, isTrue);
        expect(log.isRunning, isFalse);
        expect(log.isCompleted, isFalse);
      });

      test('status getters are mutually exclusive', () {
        final running = createLog(status: RunStatus.running);
        expect(running.isRunning, isTrue);
        expect(running.isCompleted || running.isError, isFalse);

        final completed = createLog(status: RunStatus.completed);
        expect(completed.isCompleted, isTrue);
        expect(completed.isRunning || completed.isError, isFalse);

        final error = createLog(status: RunStatus.error);
        expect(error.isError, isTrue);
        expect(error.isRunning || error.isCompleted, isFalse);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical logs', () {
        expect(createLog(), equals(createLog()));
      });

      test('== returns false for different id', () {
        expect(
          createLog(id: 'a') == createLog(id: 'b'),
          isFalse,
        );
      });

      test('== returns false for different agentId', () {
        expect(
          createLog(agentId: 'a') == createLog(agentId: 'b'),
          isFalse,
        );
      });

      test('== returns false for different workspaceId', () {
        expect(
          createLog(workspaceId: null) == createLog(workspaceId: 'ws-1'),
          isFalse,
        );
      });

      test('== returns false for different conversationId', () {
        expect(
          createLog(conversationId: null) == createLog(conversationId: 'c-1'),
          isFalse,
        );
      });

      test('== returns false for different startedAt', () {
        expect(
          createLog(startedAt: DateTime(2024, 1, 1)) ==
              createLog(startedAt: DateTime(2024, 2, 1)),
          isFalse,
        );
      });

      test('== returns false for different completedAt', () {
        expect(
          createLog(completedAt: null) == createLog(completedAt: testCompletedAt),
          isFalse,
        );
      });

      test('== returns false for different status', () {
        expect(
          createLog(status: RunStatus.running) ==
              createLog(status: RunStatus.completed),
          isFalse,
        );
      });

      test('== returns false for different summary', () {
        expect(
          createLog(summary: 'a') == createLog(summary: 'b'),
          isFalse,
        );
      });

      test('== returns false for different adapter', () {
        expect(
          createLog(adapter: 'a') == createLog(adapter: 'b'),
          isFalse,
        );
      });

      test('== returns false for different pid', () {
        expect(
          createLog(pid: 1234) == createLog(pid: 5678),
          isFalse,
        );
      });

      test('== (identical)', () {
        final log = createLog();
        expect(log, equals(log));
      });

      test('hashCode equal for identical logs', () {
        final l1 = createLog();
        final l2 = createLog();
        expect(l1.hashCode, equals(l2.hashCode));
      });

      test('hashCode differs for different logs', () {
        final l1 = createLog(id: 'a');
        final l2 = createLog(id: 'b');
        expect(l1.hashCode, isNot(equals(l2.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final log = createLog();
        final copy = log.copyWith();
        expect(copy, equals(log));
      });

      test('updates id', () {
        final copy = createLog().copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
      });

      test('updates agentId', () {
        final copy = createLog().copyWith(agentId: 'agent-2');
        expect(copy.agentId, 'agent-2');
      });

      test('updates workspaceId', () {
        final copy = createLog().copyWith(workspaceId: 'ws-2');
        expect(copy.workspaceId, 'ws-2');
      });

      test('updates conversationId', () {
        final copy = createLog().copyWith(conversationId: 'conv-2');
        expect(copy.conversationId, 'conv-2');
      });

      test('updates startedAt', () {
        final newDate = DateTime(2025, 1, 1);
        final copy = createLog().copyWith(startedAt: newDate);
        expect(copy.startedAt, newDate);
      });

      test('updates completedAt', () {
        final copy = createLog().copyWith(completedAt: testCompletedAt);
        expect(copy.completedAt, testCompletedAt);
      });

      test('removes completedAt via removeCompletedAt flag', () {
        final log = createLog(completedAt: testCompletedAt);
        final copy = log.copyWith(removeCompletedAt: true);
        expect(copy.completedAt, isNull);
      });

      test('updates status', () {
        final copy = createLog(status: RunStatus.running)
            .copyWith(status: RunStatus.completed);
        expect(copy.status, RunStatus.completed);
        expect(copy.isCompleted, isTrue);
      });

      test('updates summary', () {
        final copy = createLog().copyWith(summary: 'All good');
        expect(copy.summary, 'All good');
      });

      test('removes summary via removeSummary flag', () {
        final log = createLog(summary: 'existing summary');
        final copy = log.copyWith(removeSummary: true);
        expect(copy.summary, isNull);
      });

      test('updates adapter', () {
        final copy = createLog().copyWith(adapter: 'anthropic');
        expect(copy.adapter, 'anthropic');
      });

      test('removes adapter via removeAdapter flag', () {
        final log = createLog(adapter: 'openai');
        final copy = log.copyWith(removeAdapter: true);
        expect(copy.adapter, isNull);
      });

      test('updates pid', () {
        final copy = createLog().copyWith(pid: 1234);
        expect(copy.pid, 1234);
      });

      test('removes pid via removePid flag', () {
        final log = createLog(pid: 1234);
        final copy = log.copyWith(removePid: true);
        expect(copy.pid, isNull);
      });

      test('copyWith does not mutate original', () {
        final log = createLog(id: 'original');
        log.copyWith(id: 'changed');
        expect(log.id, 'original');
      });

      test('chaining copyWith calls', () {
        final log = createLog();
        final copy = log
            .copyWith(status: RunStatus.completed)
            .copyWith(completedAt: testCompletedAt)
            .copyWith(summary: 'Done');
        expect(copy.status, RunStatus.completed);
        expect(copy.completedAt, testCompletedAt);
        expect(copy.summary, 'Done');
      });

      test('copyWith preserves other fields unchanged', () {
        final log = createLog(
          id: 'log-x',
          agentId: 'agent-x',
          workspaceId: 'ws-x',
        );
        final copy = log.copyWith(status: RunStatus.error);
        expect(copy.id, 'log-x');
        expect(copy.agentId, 'agent-x');
        expect(copy.workspaceId, 'ws-x');
        expect(copy.status, RunStatus.error);
      });
    });
  });
}
