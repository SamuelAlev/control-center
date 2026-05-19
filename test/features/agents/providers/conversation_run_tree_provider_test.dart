import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises [conversationRunTreeProvider]'s tree builder — the pure logic that
/// turns a flat list of [AgentRunLog]s (parent dispatch + spawned subagents,
/// linked via `parentRunId`) into one row PER AGENT for that agent's CURRENT run,
/// with its subagents nested beneath. Covers grouping, the current-run rule,
/// subagent nesting, status, and label truncation.
void main() {
  /// Builds a run log. [startedAt] is explicit on purpose wherever the
  /// current-run rule is under test: the default is shared by every fixture, so
  /// a test that relies on it is only proving list order, not the rule.
  AgentRunLog runLog({
    required String id,
    required String agentId,
    RunStatus status = RunStatus.running,
    RunLiveness? liveness,
    String? summary,
    String? parentRunId,
    String? pipelineStepId,
    DateTime? startedAt,
  }) => AgentRunLog(
    id: id,
    agentId: agentId,
    workspaceId: 'ws-1',
    conversationId: 'c-1',
    startedAt: startedAt ?? DateTime(2026, 7, 1),
    status: status,
    liveness: liveness,
    summary: summary,
    parentRunId: parentRunId,
    // Holds the TEMPLATE step id (see AgentRunLog.pipelineStepRunId).
    pipelineStepRunId: pipelineStepId,
  );

  ProviderContainer containerWithLogs(List<AgentRunLog> logs) {
    final container = ProviderContainer(
      overrides: [
        agentRunLogRepositoryProvider.overrideWithValue(
          _ScriptedRunLogRepo(logs),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Reads the first emission of the (autoDispose) provider, keeping it alive
  /// via a held subscription so it is not disposed mid-load.
  Future<List<RunTreeNode>> firstTree(ProviderContainer container) {
    const key = (workspaceId: 'ws-1', conversationId: 'c-1');
    final completer = Completer<List<RunTreeNode>>();
    final sub = container.listen<AsyncValue<List<RunTreeNode>>>(
      conversationRunTreeProvider(key),
      (previous, next) {
        next.whenData((tree) {
          if (!completer.isCompleted) {
            completer.complete(tree);
          }
        });
      },
      fireImmediately: true,
    );
    return completer.future
        .timeout(const Duration(seconds: 1))
        .whenComplete(sub.close);
  }

  group('conversationRunTreeProvider', () {
    test('groups root runs by distinct agent (one row per agent)', () async {
      final container = containerWithLogs([
        runLog(id: 'r-1', agentId: 'ceo', summary: 'CEO turn'),
        runLog(id: 'r-2', agentId: 'architect', summary: 'Architect turn'),
      ]);

      final tree = await firstTree(container);

      expect(tree.length, 2);
      expect(tree.map((n) => n.agentId), ['ceo', 'architect']);
    });

    test('a single agent with multiple runs keeps one agent row', () async {
      final container = containerWithLogs([
        runLog(
          id: 'r-1',
          agentId: 'ceo',
          status: RunStatus.completed,
          startedAt: DateTime(2026, 7, 1, 9),
        ),
        runLog(
          id: 'r-2',
          agentId: 'ceo',
          status: RunStatus.running,
          startedAt: DateTime(2026, 7, 1, 10),
        ),
      ]);

      final tree = await firstTree(container);

      expect(tree.length, 1);
      // The agent row IS its current run — r-2 because it is the newest
      // dispatch, not because it happens to be the live one.
      expect(tree.first.runId, 'r-2');
    });

    test('only the newest run of an agent is in the tree', () async {
      // Every chat turn opens its own top-level run, so a second message to the
      // same agent must reset the tree rather than add a history row.
      final container = containerWithLogs([
        runLog(
          id: 'r-1',
          agentId: 'worker',
          summary: 'parsing',
          startedAt: DateTime(2026, 7, 1, 9),
        ),
        runLog(
          id: 'r-2',
          agentId: 'worker',
          summary: 'backfilling',
          startedAt: DateTime(2026, 7, 1, 10),
        ),
      ]);

      final tree = await firstTree(container);

      expect(tree.length, 1);
      expect(tree.single.runId, 'r-2');
      expect(
        tree.single.children,
        isEmpty,
        reason: 'the superseded run must not survive as a nested row',
      );
    });

    test(
      'the newest run wins even when an older run is still non-terminal',
      () async {
        // No orphan reaper runs in production, so a crash leaves a `pending` row
        // with completedAt == null forever. Preferring non-terminal runs would pin
        // the sidebar to that zombie and never show a new dispatch again.
        final container = containerWithLogs([
          runLog(
            id: 'zombie',
            agentId: 'ceo',
            status: RunStatus.pending,
            startedAt: DateTime(2026, 7, 1, 9),
          ),
          runLog(
            id: 'fresh',
            agentId: 'ceo',
            status: RunStatus.completed,
            startedAt: DateTime(2026, 7, 1, 10),
          ),
        ]);

        final tree = await firstTree(container);

        expect(tree.single.runId, 'fresh');
      },
    );

    test('the newest run wins regardless of list order', () async {
      final container = containerWithLogs([
        runLog(
          id: 'newest',
          agentId: 'ceo',
          startedAt: DateTime(2026, 7, 1, 12),
        ),
        runLog(
          id: 'oldest',
          agentId: 'ceo',
          startedAt: DateTime(2026, 7, 1, 8),
        ),
      ]);

      final tree = await firstTree(container);

      expect(tree.single.runId, 'newest');
    });

    test('runs that tie on startedAt resolve to the later arrival', () async {
      // startedAt persists at second resolution, so two dispatches inside one
      // second compare equal; the stream is ordered ascending, which makes the
      // later arrival the later dispatch.
      final sameInstant = DateTime(2026, 7, 1, 11);
      final container = containerWithLogs([
        runLog(id: 'first', agentId: 'ceo', startedAt: sameInstant),
        runLog(id: 'second', agentId: 'ceo', startedAt: sameInstant),
      ]);

      final tree = await firstTree(container);

      expect(tree.single.runId, 'second');
    });

    test(
      "a superseded run's subagents are not promoted to top-level rows",
      () async {
        // The reason superseded runs are pruned from `roots` and never from
        // `logs`: dropping them from the log set would leave their subagents
        // parentless, and a parentless run is treated as a root.
        final container = containerWithLogs([
          runLog(
            id: 'r-1',
            agentId: 'ceo',
            summary: 'first attempt',
            startedAt: DateTime(2026, 7, 1, 9),
          ),
          runLog(
            id: 'sub-a',
            agentId: 'ceo',
            summary: 'explorer-a',
            parentRunId: 'r-1',
            startedAt: DateTime(2026, 7, 1, 9, 30),
          ),
          runLog(
            id: 'r-2',
            agentId: 'ceo',
            summary: 'second attempt',
            startedAt: DateTime(2026, 7, 1, 10),
          ),
        ]);

        final tree = await firstTree(container);

        expect(
          tree.length,
          1,
          reason: 'sub-a must not become its own root row',
        );
        expect(tree.single.runId, 'r-2');
        expect(tree.single.children, isEmpty);
      },
    );

    test(
      'a real top-level run beats a newer orphan of the same agent',
      () async {
        // A subagent whose parent row is missing is promoted to a root as a
        // fallback. It must never outrank an actual dispatch, or the live run's
        // whole subtree disappears.
        final container = containerWithLogs([
          runLog(
            id: 'r-1',
            agentId: 'ceo',
            summary: 'live run',
            startedAt: DateTime(2026, 7, 1, 9),
          ),
          runLog(
            id: 'sub-mine',
            agentId: 'ceo',
            summary: 'my own subagent',
            parentRunId: 'r-1',
            startedAt: DateTime(2026, 7, 1, 9, 10),
          ),
          runLog(
            id: 'orphan',
            agentId: 'ceo',
            summary: 'parent is gone',
            parentRunId: 'vanished-run',
            startedAt: DateTime(2026, 7, 1, 11),
          ),
        ]);

        final tree = await firstTree(container);

        expect(tree.single.runId, 'r-1');
        expect(tree.single.children.map((c) => c.label), ['my own subagent']);
      },
    );

    test('the current run keeps its subagents after it goes terminal', () async {
      // Stopping the agent must not blank its subtree — the row stays until the
      // next message so finished subagents remain openable.
      final container = containerWithLogs([
        runLog(
          id: 'r-1',
          agentId: 'ceo',
          status: RunStatus.error,
          summary: 'Stopped by user',
          startedAt: DateTime(2026, 7, 1, 9),
        ),
        runLog(
          id: 'sub-1',
          agentId: 'ceo',
          status: RunStatus.completed,
          summary: 'explorer-a',
          parentRunId: 'r-1',
          startedAt: DateTime(2026, 7, 1, 9, 5),
        ),
      ]);

      final tree = await firstTree(container);

      expect(tree.single.status, AgentLiveState.failed);
      expect(tree.single.children.map((c) => c.label), ['explorer-a']);
    });

    test('two agents each keep their own current run', () async {
      final container = containerWithLogs([
        runLog(id: 'ceo-1', agentId: 'ceo', startedAt: DateTime(2026, 7, 1, 8)),
        runLog(
          id: 'arch-1',
          agentId: 'architect',
          startedAt: DateTime(2026, 7, 1, 9),
        ),
        runLog(
          id: 'ceo-2',
          agentId: 'ceo',
          startedAt: DateTime(2026, 7, 1, 10),
        ),
      ]);

      final tree = await firstTree(container);

      // Row order is each agent's FIRST appearance, so the positional 1..9
      // shortcuts do not reshuffle when an agent is re-dispatched.
      expect(tree.map((n) => n.agentId), ['ceo', 'architect']);
      expect(tree.map((n) => n.runId), ['ceo-2', 'arch-1']);
    });

    test('nests spawned subagents beneath their parent agent row', () async {
      final container = containerWithLogs([
        runLog(id: 'r-1', agentId: 'ceo', summary: 'CEO turn'),
        runLog(
          id: 'sub-1',
          agentId: 'subagent',
          summary: 'investigate the bug',
          parentRunId: 'r-1',
        ),
      ]);

      final tree = await firstTree(container);

      expect(tree.length, 1);
      expect(tree.first.children.length, 1);
      expect(tree.first.children.first.runId, 'sub-1');
      expect(tree.first.children.first.label, 'investigate the bug');
      // turnCount is the child count for the agent row.
      expect(tree.first.turnCount, 1);
    });

    test(
      "the agent row reports its CURRENT run's status, not an aggregate",
      () async {
        // The row used to aggregate every run the agent had ever made, so one old
        // failure kept the dot red forever. It now describes the current run only.
        final container = containerWithLogs([
          runLog(
            id: 'r-1',
            agentId: 'ceo',
            status: RunStatus.error,
            startedAt: DateTime(2026, 7, 1, 9),
          ),
          runLog(
            id: 'r-2',
            agentId: 'ceo',
            status: RunStatus.completed,
            startedAt: DateTime(2026, 7, 1, 10),
          ),
        ]);

        final tree = await firstTree(container);

        expect(tree.single.status, AgentLiveState.succeeded);
      },
    );

    test('a running current run reports running', () async {
      final container = containerWithLogs([
        runLog(id: 'r-1', agentId: 'ceo', status: RunStatus.running),
      ]);

      final tree = await firstTree(container);

      expect(tree.first.status, AgentLiveState.running);
    });

    test('a blocked current run reports blocked', () async {
      final container = containerWithLogs([
        runLog(
          id: 'r-1',
          agentId: 'ceo',
          status: RunStatus.running,
          liveness: RunLiveness.blocked,
        ),
      ]);

      final tree = await firstTree(container);

      expect(tree.first.status, AgentLiveState.blocked);
    });

    test('a completed current run reports succeeded, not idle', () async {
      // A finished run is a positive outcome (green dot), where `idle` is the
      // roster's neutral "this agent has nothing in flight" grey.
      final container = containerWithLogs([
        runLog(id: 'r-1', agentId: 'ceo', status: RunStatus.completed),
      ]);

      final tree = await firstTree(container);

      expect(tree.first.status, AgentLiveState.succeeded);
    });

    test('a pending run reports queued, not running', () async {
      // `pending` used to be folded into `running`, so a dispatched-but-parked
      // run showed the accent breathing dot as though it were working.
      final container = containerWithLogs([
        runLog(id: 'r-1', agentId: 'ceo', status: RunStatus.pending),
      ]);

      final tree = await firstTree(container);

      expect(tree.first.status, AgentLiveState.queued);
    });

    test('blocked liveness outranks both pending and running', () async {
      for (final status in [RunStatus.pending, RunStatus.running]) {
        final container = containerWithLogs([
          runLog(
            id: 'r-1',
            agentId: 'ceo',
            status: status,
            liveness: RunLiveness.blocked,
          ),
        ]);

        final tree = await firstTree(container);

        expect(
          tree.first.status,
          AgentLiveState.blocked,
          reason:
              'waiting on a gate is what the operator needs to see ($status)',
        );
      }
    });

    test('subagent dots report their own outcome independently', () async {
      // The whole point of the four-colour scheme: one glance separates the
      // subagent that succeeded from the one that failed and the one still going.
      final container = containerWithLogs([
        runLog(id: 'r-1', agentId: 'ceo', status: RunStatus.running),
        runLog(
          id: 'sub-ok',
          agentId: 'ceo',
          status: RunStatus.completed,
          summary: 'done well',
          parentRunId: 'r-1',
        ),
        runLog(
          id: 'sub-bad',
          agentId: 'ceo',
          status: RunStatus.error,
          summary: 'blew up',
          parentRunId: 'r-1',
        ),
        runLog(
          id: 'sub-busy',
          agentId: 'ceo',
          status: RunStatus.running,
          summary: 'still going',
          parentRunId: 'r-1',
        ),
        runLog(
          id: 'sub-wait',
          agentId: 'ceo',
          status: RunStatus.pending,
          summary: 'not started',
          parentRunId: 'r-1',
        ),
      ]);

      final tree = await firstTree(container);

      expect(
        {for (final c in tree.single.children) c.label: c.status},
        {
          'done well': AgentLiveState.succeeded,
          'blew up': AgentLiveState.failed,
          'still going': AgentLiveState.running,
          'not started': AgentLiveState.queued,
        },
      );
    });

    test('truncates a long summary to 60 chars with an ellipsis', () async {
      final longSummary = 'x' * 120;
      final container = containerWithLogs([
        runLog(
          id: 'sub-1',
          agentId: 'subagent',
          summary: longSummary,
          parentRunId: 'r-1',
        ),
        runLog(id: 'r-1', agentId: 'ceo'),
      ]);

      final tree = await firstTree(container);

      final subLabel = tree.first.children.first.label;
      expect(subLabel.length, 60);
      expect(subLabel.endsWith('…'), isTrue);
    });

    test('a summary-less run yields an EMPTY label, never the agentId', () async {
      final container = containerWithLogs([
        runLog(
          id: 'sub-1',
          agentId: 'subagent',
          summary: null,
          parentRunId: 'r-1',
        ),
        runLog(id: 'r-1', agentId: 'ceo'),
      ]);

      final tree = await firstTree(container);

      // Falling back to the agentId rendered an agent's raw id directly beneath
      // that same agent's resolved display name, which read as the agent being a
      // subagent of itself. Empty hands the panel the job of localizing a real
      // placeholder instead.
      expect(tree.first.children.first.label, isEmpty);
      expect(tree.first.children.first.startedAt, isNotNull);
    });

    test("a new run erases the previous run's subagents", () async {
      // The field report this whole change came from: message A spawned three
      // subagents, message B spawned two, and the sidebar grew a history layer
      // that pushed the live subagents a level deeper on every turn.
      final container = containerWithLogs([
        runLog(
          id: 'r-1',
          agentId: 'ceo',
          summary: 'First attempt',
          startedAt: DateTime(2026, 7, 1, 9),
        ),
        runLog(
          id: 'sub-a',
          agentId: 'ceo',
          summary: 'explorer-a',
          parentRunId: 'r-1',
          startedAt: DateTime(2026, 7, 1, 9, 5),
        ),
        runLog(
          id: 'r-2',
          agentId: 'ceo',
          summary: null,
          startedAt: DateTime(2026, 7, 1, 10),
        ),
        runLog(
          id: 'sub-b',
          agentId: 'ceo',
          summary: 'explorer-b',
          parentRunId: 'r-2',
          startedAt: DateTime(2026, 7, 1, 10, 5),
        ),
        runLog(
          id: 'sub-c',
          agentId: 'ceo',
          summary: 'explorer-c',
          parentRunId: 'r-2',
          startedAt: DateTime(2026, 7, 1, 10, 6),
        ),
      ]);

      final tree = await firstTree(container);

      final agent = tree.single;
      expect(agent.runId, 'r-2');
      // The new run's subagents hang DIRECTLY off the agent row — no per-run
      // layer in between.
      expect(agent.children.map((s) => s.label), ['explorer-b', 'explorer-c']);

      // Nothing from the superseded run survives anywhere in the tree.
      final allRunIds = <String>[];
      void collect(RunTreeNode n) {
        allRunIds.add(n.runId);
        n.children.forEach(collect);
      }

      tree.forEach(collect);
      expect(allRunIds, isNot(contains('r-1')));
      expect(allRunIds, isNot(contains('sub-a')));
    });

    test('agent row label falls back to the agentId', () async {
      final container = containerWithLogs([runLog(id: 'r-1', agentId: 'ceo')]);

      final tree = await firstTree(container);

      expect(tree.first.label, 'ceo');
    });

    test("the agent row is the agent's newest run", () async {
      final container = containerWithLogs([
        runLog(
          id: 'r-1',
          agentId: 'ceo',
          status: RunStatus.completed,
          startedAt: DateTime(2026, 7, 1, 9),
        ),
        runLog(
          id: 'r-2',
          agentId: 'ceo',
          status: RunStatus.completed,
          startedAt: DateTime(2026, 7, 1, 10),
        ),
      ]);

      final tree = await firstTree(container);

      expect(tree.first.runId, 'r-2');
    });

    test('an empty log list yields an empty tree', () async {
      final container = containerWithLogs([]);

      final tree = await firstTree(container);

      expect(tree, isEmpty);
    });

    test(
      'an orphaned subagent (parent not in set) becomes a root row',
      () async {
        final container = containerWithLogs([
          runLog(
            id: 'orphan',
            agentId: 'subagent',
            summary: 'orphaned child',
            parentRunId: 'missing-parent',
          ),
        ]);

        final tree = await firstTree(container);

        // The orphan is its own root (grouped by its agentId 'subagent').
        expect(tree.length, 1);
        expect(tree.first.agentId, 'subagent');
      },
    );
  });
}

/// A minimal [AgentRunLogRepository] that serves a scripted conversation stream
/// and stubs every other method. Only [watchByConversation] is read by the
/// provider under test.
class _ScriptedRunLogRepo implements AgentRunLogRepository {
  _ScriptedRunLogRepo(this._logs);

  final List<AgentRunLog> _logs;

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value(_logs);

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      Stream.value(const []);

  @override
  Stream<List<AgentRunLog>> watchAll() => Stream.value(const []);

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => watchAll().map(
    (logs) => logs.length <= limit ? logs : logs.sublist(0, limit),
  );

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value(const []);

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => const [];

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => null;

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => null;

  @override
  Future<void> upsert(AgentRunLog log) async {}
}
