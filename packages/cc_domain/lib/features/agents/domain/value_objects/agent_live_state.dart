import 'package:cc_domain/core/domain/entities/agent_run_log.dart';

/// The live state of an agent, derived from its most recent run logs.
///
/// This is the single source of truth for "what is this agent doing right
/// now" on the roster. Presentation pairs each state with colour + shape +
/// label so state is never conveyed by colour alone (DESIGN.md status rule).
/// Declaration order IS priority order — `sortPriority` must stay monotonically
/// increasing down this list, which a test enforces.
enum AgentLiveState {
  /// A run is currently in progress.
  running,

  /// The last run hit a blocker, stalled, or looped and is waiting.
  blocked,

  /// The last run ended in error / failure.
  failed,

  /// A run is dispatched but not executing yet — parked behind another run of
  /// the same agent, or written but not yet started.
  ///
  /// Distinct from [running] so a run tree can report "waiting its turn" instead
  /// of implying work in flight. Only meaningful per-run: the roster's
  /// [deriveAgentLiveState] never produces it.
  queued,

  /// The run finished successfully.
  ///
  /// Distinct from [idle], which means "this AGENT has nothing in flight" — a
  /// finished run is a positive outcome and reads green, where idle is neutral
  /// grey. Only produced per-run (see `runLiveState`), never by the roster.
  succeeded,

  /// The agent has run before and is currently idle.
  idle,

  /// The agent has never produced a run.
  neverRun;

  /// Sort weight so the roster can surface the agents that need attention
  /// first: running, then blocked, then failed, then queued, then the settled
  /// states (succeeded, idle, never-run).
  int get sortPriority => switch (this) {
    AgentLiveState.running => 0,
    AgentLiveState.blocked => 1,
    AgentLiveState.failed => 2,
    AgentLiveState.queued => 3,
    AgentLiveState.succeeded => 4,
    AgentLiveState.idle => 5,
    AgentLiveState.neverRun => 6,
  };
}

/// Derives the [AgentLiveState] from an agent's run logs.
///
/// [logs] are expected newest-first (the repository orders by `startedAt`
/// descending). Running wins over everything; otherwise the latest run's
/// status and liveness classify the state.
AgentLiveState deriveAgentLiveState(List<AgentRunLog> logs) {
  if (logs.isEmpty) {
    return AgentLiveState.neverRun;
  }
  if (logs.any((l) => l.status == RunStatus.running)) {
    return AgentLiveState.running;
  }
  final latest = logs.first;
  if (latest.status == RunStatus.error ||
      latest.liveness == RunLiveness.failed ||
      latest.liveness == RunLiveness.dead) {
    return AgentLiveState.failed;
  }
  if (latest.liveness == RunLiveness.blocked ||
      latest.liveness == RunLiveness.stalled ||
      latest.liveness == RunLiveness.looping) {
    return AgentLiveState.blocked;
  }
  return AgentLiveState.idle;
}

/// The most recent moment an agent showed activity, for a "last active" hint.
DateTime? agentLastActive(List<AgentRunLog> logs) {
  if (logs.isEmpty) {
    return null;
  }
  final latest = logs.first;
  return latest.lastOutputAt ?? latest.completedAt ?? latest.startedAt;
}
