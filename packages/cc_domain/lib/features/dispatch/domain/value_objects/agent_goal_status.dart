/// Lifecycle status of a durable supervised goal (`AgentGoalRun`).
enum AgentGoalStatus {
  /// The supervisor is actively pursuing the objective: a run is in flight
  /// or the next one is being scheduled.
  active,

  /// A human paused the goal; no further runs are dispatched until resumed.
  paused,

  /// The agent declared the objective achieved (via the `complete_goal`
  /// tool). Terminal.
  completed,

  /// The goal kept failing and the supervisor gave up after too many
  /// consecutive failed runs. Terminal.
  failed,

  /// A human cancelled the goal. Terminal.
  cancelled,

  /// A budget wall was hit: the deadline passed, the cost cap was reached,
  /// or the run budget was exhausted. Terminal.
  budgetExhausted,
}

/// Wire names for [AgentGoalStatus] (persisted as TEXT).
extension AgentGoalStatusWire on AgentGoalStatus {
  /// Persisted wire name.
  String get wire => switch (this) {
    AgentGoalStatus.active => 'active',
    AgentGoalStatus.paused => 'paused',
    AgentGoalStatus.completed => 'completed',
    AgentGoalStatus.failed => 'failed',
    AgentGoalStatus.cancelled => 'cancelled',
    AgentGoalStatus.budgetExhausted => 'budget_exhausted',
  };

  /// Parses a wire name back into a status; unknown values fail closed to
  /// [AgentGoalStatus.cancelled] so a corrupt row can never silently resume
  /// dispatching runs.
  static AgentGoalStatus fromWire(String? raw) => switch (raw) {
    'active' => AgentGoalStatus.active,
    'paused' => AgentGoalStatus.paused,
    'completed' => AgentGoalStatus.completed,
    'failed' => AgentGoalStatus.failed,
    'budget_exhausted' => AgentGoalStatus.budgetExhausted,
    _ => AgentGoalStatus.cancelled,
  };
}

/// Whether a status is terminal (no further runs are ever dispatched).
extension AgentGoalStatusTerminal on AgentGoalStatus {
  /// True when the goal will never run again.
  bool get isTerminal => switch (this) {
    AgentGoalStatus.active || AgentGoalStatus.paused => false,
    _ => true,
  };
}
