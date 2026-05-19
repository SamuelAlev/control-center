import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One agent run currently in flight in a channel, plus the subagent runs it
/// spawned that are themselves still in flight.
///
/// Deliberately narrower than [RunTreeNode]: the sidebar flyout reports what is
/// happening NOW, so a finished run never becomes a row (it is counted in the
/// summary's totals instead). Carrying [startedAt] is what lets a row tick its
/// own elapsed time without a second lookup.
class ChannelLiveRun {
  /// Creates a [ChannelLiveRun].
  const ChannelLiveRun({
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
  final List<ChannelLiveRun> children;

  /// This run plus every live descendant.
  int get subtreeSize =>
      1 + children.fold(0, (sum, child) => sum + child.subtreeSize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelLiveRun &&
          runId == other.runId &&
          agentId == other.agentId &&
          startedAt == other.startedAt &&
          state == other.state &&
          summary == other.summary &&
          const ListEquality<ChannelLiveRun>().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    runId,
    agentId,
    startedAt,
    state,
    summary,
    const ListEquality<ChannelLiveRun>().hash(children),
  );
}

/// What the sidebar's channel flyout reports about one channel: the live run
/// tree, when the oldest live run started, the conversation's accumulated spend,
/// and when anything last happened.
class ChannelActivitySummary {
  /// Creates a [ChannelActivitySummary].
  const ChannelActivitySummary({
    required this.liveRuns,
    required this.totalTokens,
    required this.costCents,
    required this.runCount,
    this.startedAt,
    this.lastActivityAt,
  });

  /// Top-level runs in flight, each carrying its live subagents.
  final List<ChannelLiveRun> liveRuns;

  /// When the OLDEST live run started — the channel's "how long has this been
  /// going" clock. Null when nothing is in flight.
  final DateTime? startedAt;

  /// Tokens billed across every run this conversation has ever had.
  final int totalTokens;

  /// Cost in cents across every run. Sums each run's OWN cost only:
  /// `childCostCents` is a roll-up of runs already in this set, so adding it
  /// would double-count delegated spend.
  final int costCents;

  /// How many runs this conversation has had, live and finished.
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
  static const ChannelActivitySummary empty = ChannelActivitySummary(
    liveRuns: [],
    totalTokens: 0,
    costCents: 0,
    runCount: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelActivitySummary &&
          const ListEquality<ChannelLiveRun>().equals(
            liveRuns,
            other.liveRuns,
          ) &&
          startedAt == other.startedAt &&
          totalTokens == other.totalTokens &&
          costCents == other.costCents &&
          runCount == other.runCount &&
          lastActivityAt == other.lastActivityAt;

  @override
  int get hashCode => Object.hash(
    const ListEquality<ChannelLiveRun>().hash(liveRuns),
    startedAt,
    totalTokens,
    costCents,
    runCount,
    lastActivityAt,
  );
}

/// Folds a conversation's run logs into the flyout's summary.
///
/// Pure and top-level so the shaping rules (what counts as live, what roots the
/// tree, how spend is summed) are unit-testable without a container.
ChannelActivitySummary summarizeChannelActivity(List<AgentRunLog> logs) {
  if (logs.isEmpty) {
    return ChannelActivitySummary.empty;
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

  ChannelLiveRun build(AgentRunLog run) {
    final summary = run.summary?.trim();
    return ChannelLiveRun(
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

  return ChannelActivitySummary(
    liveRuns: roots,
    startedAt: oldestLive,
    totalTokens: tokens,
    costCents: cents,
    runCount: logs.length,
    lastActivityAt: lastActivity,
  );
}

/// The sidebar flyout's view of a channel's agent activity.
///
/// Derived from [conversationRunLogsProvider], so hovering a row that is already
/// open costs no second subscription, and the panel updates live as runs start,
/// spawn subagents, spend tokens, and finish.
final channelActivitySummaryProvider = Provider.autoDispose
    .family<ChannelActivitySummary, ConversationRunsKey>((ref, key) {
      final logs = ref.watch(conversationRunLogsProvider(key)).asData?.value;
      return logs == null
          ? ChannelActivitySummary.empty
          : summarizeChannelActivity(logs);
    });
