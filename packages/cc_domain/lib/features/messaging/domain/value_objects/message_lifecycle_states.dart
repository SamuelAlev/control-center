/// Approval state of a `plan` message (`metadata['planStatus']`).
///
/// A plan without a stored state is [pending]: the agent proposed it and
/// nobody has answered yet.
enum PlanMessageStatus {
  /// Proposed, waiting for the person's answer.
  pending('pending'),

  /// The person approved the plan.
  approved('approved'),

  /// The person sent feedback and the agent is reworking the plan.
  refining('refining');

  const PlanMessageStatus(this.wire);

  /// The stored/wire value.
  final String wire;

  /// Decodes a stored value, or null when it names no state.
  static PlanMessageStatus? tryFromWire(String? value) =>
      PlanMessageStatus.values.where((s) => s.wire == value).firstOrNull;
}

/// Queue state of a `steering` message (`metadata['steerState']`).
enum SteeringState {
  /// Waiting in the composer's queue strip for a run to take it.
  queued('queued'),

  /// A live run took it at a turn boundary; it renders in the trail.
  injected('injected'),

  /// The run ended before taking it, so it was turned into a plain message.
  converted('converted'),

  /// A person stopped the run before it took the card: the card waits, kept
  /// out of every run, until they release it (`steering.release`, which puts
  /// it back to [queued] and sends it when no run is live) or delete it.
  held('held');

  const SteeringState(this.wire);

  /// The stored/wire value.
  final String wire;

  /// Decodes a stored value, or null when it names no state.
  static SteeringState? tryFromWire(String? value) =>
      SteeringState.values.where((s) => s.wire == value).firstOrNull;
}
