import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One agent run currently in flight in a space, plus the subagent runs it
/// spawned that are themselves still in flight.
///
/// Deliberately narrower than [RunTreeNode]: the sidebar flyout reports what is
/// happening NOW, so a finished run never becomes a row (it is counted in the
/// summary's totals instead). Carrying [startedAt] is what lets a row tick its
/// own elapsed time without a second lookup.
class SpaceLiveRun {
  /// Creates a [SpaceLiveRun].
  const SpaceLiveRun({
    required this.runId,
    required this.agentId,
    required this.startedAt,
    required this.state,
    required this.children,
    this.summary,
  });

  /// The run-log id — the handle the flyout hands back when a row is opened.
  final String runId;

  /// The agent that executed the run. For a spawned subagent this is the
  /// parent's agent id (or the literal `subagent`), not an agent of its own.
  final String agentId;

  /// When the run started, the origin of the row's elapsed clock.
  final DateTime startedAt;

  /// Derived live state (running / blocked), from [runLiveState].
  final AgentLiveState state;

  /// The run's own summary — a subagent's task label. Null for a top-level run
  /// that has not written one yet.
  final String? summary;

  /// Subagent runs spawned by this one that are still in flight.
  final List<SpaceLiveRun> children;

  /// This run plus every live descendant.
  int get subtreeSize =>
      1 + children.fold(0, (sum, child) => sum + child.subtreeSize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceLiveRun &&
          runId == other.runId &&
          agentId == other.agentId &&
          startedAt == other.startedAt &&
          state == other.state &&
          summary == other.summary &&
          const ListEquality<SpaceLiveRun>().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    runId,
    agentId,
    startedAt,
    state,
    summary,
    const ListEquality<SpaceLiveRun>().hash(children),
  );
}

/// What the sidebar's space flyout reports about one space: the live run
/// tree, when the oldest live run started, the space's accumulated spend,
/// and when anything last happened.
class SpaceActivitySummary {
  /// Creates a [SpaceActivitySummary].
  const SpaceActivitySummary({
    required this.liveRuns,
    required this.totalTokens,
    required this.costCents,
    required this.runCount,
    this.startedAt,
    this.lastActivityAt,
  });

  /// Top-level runs in flight, each carrying its live subagents.
  final List<SpaceLiveRun> liveRuns;

  /// When the OLDEST live run started — the space's "how long has this been
  /// going" clock. Null when nothing is in flight.
  final DateTime? startedAt;

  /// Tokens billed across every run this space has ever had.
  final int totalTokens;

  /// Cost in cents across every run. Sums each run's OWN cost only:
  /// `childCostCents` is a roll-up of runs already in this set, so adding it
  /// would double-count delegated spend.
  final int costCents;

  /// How many runs this space has had, live and finished.
  final int runCount;

  /// The most recent moment any run started, produced output, or finished.
  final DateTime? lastActivityAt;

  /// Whether any agent is working right now.
  bool get isLive => liveRuns.isNotEmpty;

  /// How many distinct top-level runs are in flight.
  int get liveAgentCount => liveRuns.length;

  /// How many spawned subagent runs are in flight beneath them.
  int get liveSubagentCount =>
      liveRuns.fold(0, (sum, run) => sum + run.subtreeSize) - liveRuns.length;

  /// Nothing known yet (the run-log stream has not produced a value).
  static const SpaceActivitySummary empty = SpaceActivitySummary(
    liveRuns: [],
    totalTokens: 0,
    costCents: 0,
    runCount: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceActivitySummary &&
          const ListEquality<SpaceLiveRun>().equals(liveRuns, other.liveRuns) &&
          startedAt == other.startedAt &&
          totalTokens == other.totalTokens &&
          costCents == other.costCents &&
          runCount == other.runCount &&
          lastActivityAt == other.lastActivityAt;

  @override
  int get hashCode => Object.hash(
    const ListEquality<SpaceLiveRun>().hash(liveRuns),
    startedAt,
    totalTokens,
    costCents,
    runCount,
    lastActivityAt,
  );
}

/// Folds a space's run logs into the flyout's summary.
///
/// Pure and top-level so the shaping rules (what counts as live, what roots the
/// tree, how spend is summed) are unit-testable without a container.
SpaceActivitySummary summarizeSpaceActivity(List<AgentRunLog> logs) {
  if (logs.isEmpty) {
    return SpaceActivitySummary.empty;
  }

  final live = logs.where((l) => l.isActive).toList(growable: false);
  final liveIds = {for (final l in live) l.id};
  final byParent = <String, List<AgentRunLog>>{};
  for (final l in live) {
    final parentId = l.parentRunId;
    if (parentId != null && liveIds.contains(parentId)) {
      byParent.putIfAbsent(parentId, () => []).add(l);
    }
  }

  SpaceLiveRun build(AgentRunLog run) {
    final summary = run.summary?.trim();
    return SpaceLiveRun(
      runId: run.id,
      agentId: run.agentId,
      startedAt: run.startedAt,
      state: runLiveState(run),
      summary: summary == null || summary.isEmpty ? null : summary,
      children: [
        for (final child in byParent[run.id] ?? const <AgentRunLog>[])
          build(child),
      ],
    );
  }

  // A live run roots the tree when its parent is null OR is no longer live —
  // an orphaned child still deserves a row rather than vanishing with its
  // finished parent.
  final roots = [
    for (final run in live)
      if (run.parentRunId == null || !liveIds.contains(run.parentRunId))
        build(run),
  ];

  var tokens = 0;
  var cents = 0;
  DateTime? oldestLive;
  DateTime? lastActivity;
  for (final l in logs) {
    tokens += l.cost.totalTokens;
    cents += l.cost.estimatedCostCents;
    if (l.isActive &&
        (oldestLive == null || l.startedAt.isBefore(oldestLive))) {
      oldestLive = l.startedAt;
    }
    for (final stamp in [l.completedAt, l.lastOutputAt, l.startedAt]) {
      if (stamp != null &&
          (lastActivity == null || stamp.isAfter(lastActivity))) {
        lastActivity = stamp;
      }
    }
  }

  return SpaceActivitySummary(
    liveRuns: roots,
    startedAt: oldestLive,
    totalTokens: tokens,
    costCents: cents,
    runCount: logs.length,
    lastActivityAt: lastActivity,
  );
}

/// The sidebar flyout's view of a space's agent activity.
///
/// Derived from [spaceRunLogsProvider] — the SPACE's stream, every
/// conversation in it. A conversation-scoped read keyed on the space id
/// matches nothing since the Space cutover gave conversation ids their own
/// uuids (a run dispatched into a space logs its standing conversation's id,
/// never the space's), which is exactly the "No agent has run here yet · 0
/// tokens · $0.00" lie on a space full of working agents. `autoDispose` keeps
/// an idle sidebar free and a hover's cost dies with the hover.
final spaceActivitySummaryProvider = Provider.autoDispose
    .family<SpaceActivitySummary, SpaceRunsKey>((ref, key) {
      final logs = ref.watch(spaceRunLogsProvider(key)).asData?.value;
      return logs == null
          ? SpaceActivitySummary.empty
          : summarizeSpaceActivity(logs);
    });
