import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A node in a conversation's live run tree: one run plus the subagent runs it
/// spawned (linked via [AgentRunLog.parentRunId]).
///
/// The tree holds exactly the rows the panel renders — one row per agent for its
/// CURRENT run, then that run's subagents to whatever depth they nest. Nothing is
/// carried that is not drawn, so the section's `settled/total` count can no
/// longer disagree with what is on screen.
class RunTreeNode {
  /// Creates a [RunTreeNode].
  const RunTreeNode({
    required this.runId,
    required this.agentId,
    required this.label,
    required this.status,
    required this.turnCount,
    required this.children,
    this.retryAttempt = 0,
    this.startedAt,
  });

  /// The run-log id.
  final String runId;

  /// The agent that executed the run (or `subagent` for ephemeral children).
  final String agentId;

  /// Display label (the subagent's task label, or the agent's name/summary), or
  /// EMPTY when a run has produced no summary yet.
  ///
  /// Empty rather than a placeholder because the placeholder is localized and a
  /// provider has no `BuildContext`; the panel composes it from [retryAttempt]
  /// and [startedAt]. It must NEVER fall back to [agentId]: a pending
  /// re-dispatch then renders the agent's raw id directly beneath that same
  /// agent's resolved display name, which reads as the agent being a subagent of
  /// itself.
  final String label;

  /// Attempt number from the run's own retry metadata, 0 when it is not a
  /// tracked retry. Note a chat-driven "try again" is a fresh dispatch and
  /// leaves this at 0; only an in-place retry (the heartbeat recovery service
  /// bumping an existing row) sets it.
  final int retryAttempt;

  /// When the run started. Feeds the fallback label's time; null for rows that
  /// do not stand for a single run.
  final DateTime? startedAt;

  /// Derived live status.
  final AgentLiveState status;

  /// A rough activity count shown as `+N` (currently the child count; a proxy
  /// for how much work the run has done).
  final int turnCount;

  /// Subagent runs spawned by this run.
  final List<RunTreeNode> children;
}

/// Derives a single run's live status from its log row.
///
/// Public so a run-scoped surface (an activity tab's header) reports the same
/// state the run tree's dot does. Deliberately not `deriveAgentLiveState`, which
/// answers "what is this AGENT doing" for the roster and collapses a finished run
/// into a neutral `idle`. Here each state is the run's own outcome, so the dot can
/// read accent while working, grey while queued, green when it succeeded and red
/// when it failed.
AgentLiveState runLiveState(AgentRunLog run) => _statusOf(run);

AgentLiveState _statusOf(AgentRunLog run) {
  // Blocked outranks the raw status: "waiting on a gate" is what the operator
  // needs to see, whether the row still says pending or running.
  if (run.liveness == RunLiveness.blocked &&
      (run.status == RunStatus.running || run.status == RunStatus.pending)) {
    return AgentLiveState.blocked;
  }
  switch (run.status) {
    case RunStatus.pending:
      return AgentLiveState.queued;
    case RunStatus.running:
      return AgentLiveState.running;
    case RunStatus.error:
      return AgentLiveState.failed;
    case RunStatus.completed:
      return AgentLiveState.succeeded;
  }
}

/// The run's summary-derived row label, or empty when it has none yet.
///
/// Returns empty instead of falling back to `run.agentId` — see
/// [RunTreeNode.label] for why that fallback was the "agent nested under
/// itself" bug.
String _labelFor(AgentRunLog run) {
  final summary = run.summary?.trim();
  if (summary == null || summary.isEmpty) {
    return '';
  }
  // Keep it short for the tree row.
  return summary.length <= 60 ? summary : '${summary.substring(0, 59)}…';
}

/// Whether [candidate] is a later dispatch of the same agent than [best] — the
/// "current run" rule behind an agent's single row.
///
/// A real top-level run always outranks a promoted orphan (a subagent whose
/// parent row is missing from this conversation): the orphan is a fallback row,
/// not a dispatch and letting a newer orphan win would blank the live main run's
/// entire subtree.
///
/// Among rows of the same kind the later [AgentRunLog.startedAt] wins and a TIE
/// goes to the later arrival: `startedAt` persists at second resolution, so two
/// dispatches inside one second compare equal and the conversation stream is
/// ordered ascending — which makes the later arrival the later dispatch.
bool _supersedes(AgentRunLog candidate, AgentRunLog best) {
  final candidateIsTopLevel = candidate.parentRunId == null;
  if (candidateIsTopLevel != (best.parentRunId == null)) {
    return candidateIsTopLevel;
  }
  return !candidate.startedAt.isBefore(best.startedAt);
}

List<RunTreeNode> _buildTree(List<AgentRunLog> logs) {
  final byParent = <String?, List<AgentRunLog>>{};
  for (final l in logs) {
    byParent.putIfAbsent(l.parentRunId, () => []).add(l);
  }

  // Builds a spawned-subagent subtree (its task label stays its own summary).
  RunTreeNode buildSub(AgentRunLog run) {
    final children = (byParent[run.id] ?? const <AgentRunLog>[])
        .map(buildSub)
        .toList(growable: false);
    return RunTreeNode(
      runId: run.id,
      agentId: run.agentId,
      label: _labelFor(run),
      status: _statusOf(run),
      retryAttempt: run.retry.attempt,
      startedAt: run.startedAt,
      turnCount: children.length,
      children: children,
    );
  }

  // Roots = runs whose parent isn't itself in this conversation's set (covers
  // top-level runs with a null parent AND any orphaned children). Computed over
  // the FULL log set on purpose — see the pruning note below.
  final ids = {for (final l in logs) l.id};
  final roots = [
    for (final l in logs)
      if (l.parentRunId == null || !ids.contains(l.parentRunId)) l,
  ];

  // One row per agent, standing for that agent's CURRENT run only, with that
  // run's subagents hanging DIRECTLY off it.
  //
  // Every chat turn opens its own top-level run, so an agent accumulates one root
  // run per message sent to it. Emitting a row per run turned a 200px sidebar
  // into a run history in which the rows that actually matter — the subagents
  // working right now — sank one level deeper on every turn. The newest dispatch
  // wins; earlier runs and their subagents leave the tree. They stay reachable
  // from the conversation transcript (a past turn's `task` cell opens its child
  // run), the space activity flyout and any already-open activity tab.
  //
  // Superseded runs are dropped from `roots`, NEVER from `logs`: `ids` and
  // `byParent` still see the whole conversation, so a superseded run's subagents
  // read as "parent present, just not rendered" and are skipped. Pruning `logs`
  // first would leave them parentless and promote them straight back to
  // top-level rows — the exact bug this shape avoids.
  final order = <String>[];
  final currentByAgent = <String, AgentRunLog>{};
  for (final run in roots) {
    final best = currentByAgent[run.agentId];
    if (best == null) {
      order.add(run.agentId);
      currentByAgent[run.agentId] = run;
    } else if (_supersedes(run, best)) {
      currentByAgent[run.agentId] = run;
    }
  }

  // Row order is the agent's FIRST appearance among roots, not its current run's
  // start time: the 1..9 shortcuts are positional and rows reshuffling under the
  // user's fingers on every turn is worse than a stable-but-older order.
  return [
    for (final agentId in order)
      () {
        final run = currentByAgent[agentId]!;
        final children = [
          for (final child in byParent[run.id] ?? const <AgentRunLog>[])
            buildSub(child),
        ];
        return RunTreeNode(
          runId: run.id,
          agentId: agentId,
          // The agentId; the panel resolves it to the display name.
          label: agentId,
          status: _statusOf(run),
          startedAt: run.startedAt,
          turnCount: children.length,
          children: children,
        );
      }(),
  ];
}

/// The conversation's raw run-log stream — the single subscription every
/// run-scoped surface in this conversation derives from (the AGENTS tree and a
/// run's activity tab reading its own row's status/cost).
final conversationRunLogsProvider = StreamProvider.autoDispose
    .family<List<AgentRunLog>, ConversationRunsKey>((ref, key) {
      return ref
          .watch(agentRunLogRepositoryProvider)
          .watchByConversation(key.workspaceId, key.conversationId);
    });

/// The SPACE's raw run-log stream — every conversation in it, threads
/// included. The AGENTS panel is a space-level surface: it answers "who has
/// worked here", which a single stream cannot.
final spaceRunLogsProvider = StreamProvider.autoDispose
    .family<List<AgentRunLog>, SpaceRunsKey>((ref, key) {
      return ref
          .watch(agentRunLogRepositoryProvider)
          .watchBySpace(key.workspaceId, key.spaceId);
    });

/// The live run tree (parent dispatch + spawned subagents) of a whole space,
/// for the General pane's AGENTS section.
final spaceRunTreeProvider = Provider.autoDispose
    .family<AsyncValue<List<RunTreeNode>>, SpaceRunsKey>((ref, key) {
      return ref.watch(spaceRunLogsProvider(key)).whenData(_buildTree);
    });

/// Watches the live run tree (parent dispatch + spawned subagents) for a
/// conversation, for the General pane's AGENTS section.
///
/// Derived rather than its own subscription, so the tree and any open activity
/// tab share one stream over the same conversation.
final conversationRunTreeProvider = Provider.autoDispose
    .family<AsyncValue<List<RunTreeNode>>, ConversationRunsKey>((ref, key) {
      return ref.watch(conversationRunLogsProvider(key)).whenData(_buildTree);
    });
