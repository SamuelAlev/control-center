import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/features/messaging/providers/space_activity_summary_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises [summarizeSpaceActivity] — the pure shaping the sidebar's space
/// flyout reads: which runs count as live, what roots the tree, how spend is
/// summed without double-counting delegated cost and how the elapsed clock's
/// origin is chosen.
void main() {
  AgentRunLog run({
    required String id,
    String agentId = 'a-1',
    RunStatus status = RunStatus.running,
    RunLiveness? liveness,
    String? summary,
    String? parentRunId,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastOutputAt,
    RunCost? cost,
    int childCostCents = 0,
  }) => AgentRunLog(
    id: id,
    agentId: agentId,
    workspaceId: 'ws-1',
    conversationId: 'c-1',
    startedAt: startedAt ?? DateTime(2026, 7, 1, 10),
    completedAt: completedAt,
    lastOutputAt: lastOutputAt,
    status: status,
    liveness: liveness,
    summary: summary,
    parentRunId: parentRunId,
    cost: cost,
    childCostCents: childCostCents,
  );

  group('summarizeSpaceActivity', () {
    test('reports nothing for a conversation with no runs', () {
      expect(summarizeSpaceActivity(const []), SpaceActivitySummary.empty);
    });

    test('an idle conversation has no live runs but keeps its totals', () {
      final summary = summarizeSpaceActivity([
        run(
          id: 'r-1',
          status: RunStatus.completed,
          completedAt: DateTime(2026, 7, 1, 10, 5),
          cost: const RunCost(
            inputTokens: 900,
            outputTokens: 100,
            estimatedCostCents: 42,
          ),
        ),
      ]);

      expect(summary.isLive, isFalse);
      expect(summary.liveRuns, isEmpty);
      expect(summary.startedAt, isNull);
      expect(summary.totalTokens, 1000);
      expect(summary.costCents, 42);
      expect(summary.runCount, 1);
      expect(summary.lastActivityAt, DateTime(2026, 7, 1, 10, 5));
    });

    test('a pending run counts as live but reports queued, not running', () {
      final summary = summarizeSpaceActivity([
        run(id: 'r-1', status: RunStatus.pending),
      ]);

      // Still live: the space has work in flight, which is what `isLive`
      // answers (the filter is `AgentRunLog.isActive` = pending || running).
      expect(summary.isLive, isTrue);
      // But its own state is `queued` — dispatched and waiting, not executing.
      // Folding pending into `running` gave a parked run the accent breathing
      // dot as though it were working.
      expect(summary.liveRuns.single.state, AgentLiveState.queued);
    });

    test('a blocked live run reports blocked, not running', () {
      final summary = summarizeSpaceActivity([
        run(id: 'r-1', liveness: RunLiveness.blocked),
      ]);

      expect(summary.liveRuns.single.state, AgentLiveState.blocked);
    });

    test('nests live subagents under their live parent', () {
      final summary = summarizeSpaceActivity([
        run(id: 'parent', agentId: 'architect'),
        run(id: 'kid-a', parentRunId: 'parent', summary: 'audit diff tree'),
        run(id: 'kid-b', parentRunId: 'parent', summary: 'write tests'),
        run(id: 'grandkid', parentRunId: 'kid-a', summary: 'read config'),
      ]);

      expect(summary.liveRuns, hasLength(1));
      final parent = summary.liveRuns.single;
      expect(parent.runId, 'parent');
      expect(parent.children.map((c) => c.runId), ['kid-a', 'kid-b']);
      expect(parent.children.first.children.single.runId, 'grandkid');
      expect(parent.children.first.summary, 'audit diff tree');
      expect(summary.liveAgentCount, 1);
      expect(summary.liveSubagentCount, 3);
    });

    test(
      'drops finished subagents from the tree but keeps them in the totals',
      () {
        final summary = summarizeSpaceActivity([
          run(id: 'parent'),
          run(
            id: 'done-kid',
            parentRunId: 'parent',
            status: RunStatus.completed,
            cost: const RunCost(inputTokens: 50, estimatedCostCents: 7),
          ),
        ]);

        expect(summary.liveRuns.single.children, isEmpty);
        expect(summary.runCount, 2);
        expect(summary.totalTokens, 50);
        expect(summary.costCents, 7);
      },
    );

    test('a live subagent whose parent finished still gets a row', () {
      final summary = summarizeSpaceActivity([
        run(id: 'parent', status: RunStatus.error),
        run(id: 'orphan', parentRunId: 'parent', summary: 'still working'),
      ]);

      expect(summary.liveRuns.map((r) => r.runId), ['orphan']);
      expect(summary.liveSubagentCount, 0);
    });

    test('two agents working at once are two separate roots', () {
      final summary = summarizeSpaceActivity([
        run(id: 'r-1', agentId: 'architect'),
        run(id: 'r-2', agentId: 'reviewer'),
      ]);

      expect(summary.liveRuns.map((r) => r.agentId), ['architect', 'reviewer']);
      expect(summary.liveAgentCount, 2);
    });

    test('the elapsed clock starts at the OLDEST live run', () {
      final summary = summarizeSpaceActivity([
        run(id: 'r-1', startedAt: DateTime(2026, 7, 1, 10, 30)),
        run(id: 'r-2', startedAt: DateTime(2026, 7, 1, 10, 5)),
        // A finished run that started even earlier must not move the clock.
        run(
          id: 'r-0',
          status: RunStatus.completed,
          startedAt: DateTime(2026, 7, 1, 9),
          completedAt: DateTime(2026, 7, 1, 9, 30),
        ),
      ]);

      expect(summary.startedAt, DateTime(2026, 7, 1, 10, 5));
    });

    test('delegated cost is not double-counted', () {
      // `childCostCents` on the parent is a roll-up of the child's own cost and
      // the child is in this same set — adding both would report 2x the spend.
      final summary = summarizeSpaceActivity([
        run(
          id: 'parent',
          cost: const RunCost(estimatedCostCents: 100),
          childCostCents: 30,
        ),
        run(
          id: 'kid',
          parentRunId: 'parent',
          status: RunStatus.completed,
          cost: const RunCost(estimatedCostCents: 30),
        ),
      ]);

      expect(summary.costCents, 130);
    });

    test('last activity takes the newest of start, output and completion', () {
      final summary = summarizeSpaceActivity([
        run(
          id: 'r-1',
          status: RunStatus.completed,
          startedAt: DateTime(2026, 7, 1, 10),
          completedAt: DateTime(2026, 7, 1, 10, 5),
          lastOutputAt: DateTime(2026, 7, 1, 10, 9),
        ),
      ]);

      expect(summary.lastActivityAt, DateTime(2026, 7, 1, 10, 9));
    });

    test('a summary of only whitespace is treated as absent', () {
      final summary = summarizeSpaceActivity([run(id: 'r-1', summary: '   ')]);

      expect(summary.liveRuns.single.summary, isNull);
    });
  });
}
