/// A minimal snapshot of one agent's liveness, decoupled from the dispatch
/// registry, for the awake policy to weigh.
class AgentAwakeSignal {
  /// Creates an [AgentAwakeSignal].
  const AgentAwakeSignal({required this.isWorking, required this.lastActivity});

  /// Whether the agent is actively running a turn.
  final bool isWorking;

  /// When the agent last showed activity (used to ignore a stuck/stale run).
  final DateTime lastActivity;
}

/// Decides whether the OS should be kept awake based on agent activity.
///
/// The machine is kept awake only while at least one agent is genuinely working
/// and recently active: a run observed within [staleAfter] (default 2h). A run
/// that has been "working" with no activity past that window is treated as
/// stuck and no longer holds the machine awake — otherwise a crashed agent
/// would pin the display on indefinitely.
class AgentAwakePolicy {
  /// Creates an [AgentAwakePolicy].
  const AgentAwakePolicy({this.staleAfter = const Duration(hours: 2)});

  /// How long a working agent may be idle before it stops counting.
  final Duration staleAfter;

  /// Whether the machine should be kept awake right now.
  bool shouldKeepAwake({
    required Iterable<AgentAwakeSignal> signals,
    required DateTime now,
    required bool enabled,
  }) {
    if (!enabled) {
      return false;
    }
    for (final s in signals) {
      if (s.isWorking && now.difference(s.lastActivity) < staleAfter) {
        return true;
      }
    }
    return false;
  }
}
