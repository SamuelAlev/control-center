/// How a wake enters a run of its agent that is already live in its
/// conversation. A wake that finds no live run starts one instead.
enum WakeLane {
  /// At the next turn boundary, framed as a system message.
  aside,

  /// When the agent would end its turn.
  followUp,
}

/// Wire names for [WakeLane] (persisted as TEXT).
extension WakeLaneWire on WakeLane {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeLane.aside => 'aside',
    WakeLane.followUp => 'follow_up',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeLane.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeLane? tryParse(String? raw) {
    for (final value in WakeLane.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Where a wake (`agent_wakes` row) is on its way to its agent.
enum WakeState {
  /// Waiting for its `notBefore` time and for admission.
  pending,

  /// A person must release it (they stopped the run, or a recovery
  /// waits for their Resume).
  held,

  /// Taken by the wake queue for a dispatch that is starting. A claim
  /// with no live run returns to pending at the next sweep.
  claimed,

  /// Handed to a run (the run log lists its id). Settled.
  delivered,

  /// Refused by admission for good, or a missed slot. Settled.
  skipped,

  /// Its `expiresAt` passed before it was delivered. Settled.
  expired,

  /// A person, the agent or its goal or rule withdrew it. Settled.
  cancelled,
}

/// Wire names for [WakeState] (persisted as TEXT).
extension WakeStateWire on WakeState {
  /// Persisted wire name.
  String get wire => switch (this) {
    WakeState.pending => 'pending',
    WakeState.held => 'held',
    WakeState.claimed => 'claimed',
    WakeState.delivered => 'delivered',
    WakeState.skipped => 'skipped',
    WakeState.expired => 'expired',
    WakeState.cancelled => 'cancelled',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in WakeState.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static WakeState? tryParse(String? raw) {
    for (final value in WakeState.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Whether a wake in this state is finished: it is never delivered again and
/// the retention sweep may delete it.
extension WakeStateSettled on WakeState {
  /// True for `delivered`, `skipped`, `expired` and `cancelled`.
  bool get isSettled => switch (this) {
    WakeState.pending || WakeState.held || WakeState.claimed => false,
    _ => true,
  };
}
