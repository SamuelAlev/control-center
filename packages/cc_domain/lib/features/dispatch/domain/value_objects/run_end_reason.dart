/// Why an agent run ended. Written on the run's terminal row and carried by
/// `AgentRunSettled`, so a listener decides from one settled fact instead of
/// inferring it from the status and an error string.
enum RunEndReason {
  /// The agent finished its turn.
  completed,

  /// The run failed: a provider, tool-loop or process error.
  error,

  /// A person stopped the run.
  stoppedByUser,

  /// The run reached its cost cap.
  budget,

  /// The silence watchdog ended a run that produced nothing for too long.
  silence,

  /// The provider's usage limit was reached and no other account could take
  /// over. The settled event carries the reset time when the provider
  /// reported one.
  usageLimit,

  /// The server stopped or restarted while the run was live.
  serverStopped,
}

/// Wire names for [RunEndReason] (persisted as TEXT).
extension RunEndReasonWire on RunEndReason {
  /// Persisted wire name.
  String get wire => switch (this) {
    RunEndReason.completed => 'completed',
    RunEndReason.error => 'error',
    RunEndReason.stoppedByUser => 'stopped_by_user',
    RunEndReason.budget => 'budget',
    RunEndReason.silence => 'silence',
    RunEndReason.usageLimit => 'usage_limit',
    RunEndReason.serverStopped => 'server_stopped',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final reason in RunEndReason.values) reason.wire,
  ];

  /// Parses a wire name. Null for a run that has not ended, for a row
  /// written before the column existed, and for an unknown value.
  static RunEndReason? tryParse(String? raw) {
    for (final reason in RunEndReason.values) {
      if (reason.wire == raw) {
        return reason;
      }
    }
    return null;
  }
}
