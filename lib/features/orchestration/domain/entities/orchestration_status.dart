/// Lifecycle status of an [Orchestration].
enum OrchestrationStatus {
  /// Proposed by the orchestrator, awaiting the user's one upfront approval.
  proposed,

  /// Approved; deterministic materialization in progress (hires, team,
  /// project, pipeline template).
  approved,

  /// The generated pipeline is running (sub-tickets / discussion / work).
  executing,

  /// Sub-tickets are done; the synthesis step is producing the deliverable.
  synthesizing,

  /// Completed — the deliverable landed on the parent ticket.
  completed,

  /// Failed (a hard error, all sub-tickets failed, or budget exceeded).
  failed,

  /// Cancelled by the user.
  cancelled;

  /// Whether this is a terminal state.
  bool get isTerminal =>
      this == OrchestrationStatus.completed ||
      this == OrchestrationStatus.failed ||
      this == OrchestrationStatus.cancelled;

  /// Parses a stored value. Null defaults to [proposed]; an unknown value
  /// throws (a corrupt row must surface loudly).
  static OrchestrationStatus fromStorage(String? value) {
    if (value == null) {
      return OrchestrationStatus.proposed;
    }
    for (final s in values) {
      if (s.name == value) {
        return s;
      }
    }
    throw ArgumentError('Unknown orchestration status in storage: "$value"');
  }

  /// Storage representation.
  String toStorageString() => name;
}
