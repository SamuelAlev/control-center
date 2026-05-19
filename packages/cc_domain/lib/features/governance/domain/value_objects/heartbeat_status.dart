/// The liveness an agent self-reports in a heartbeat.
///
/// Distinct from the derived runtime health (which is computed from heartbeat
/// age): this is what the agent claims it is doing the moment it phones home.
enum HeartbeatStatus {
  /// Actively making progress on work.
  alive('Alive'),

  /// Reachable but waiting for work.
  idle('Idle'),

  /// Reachable but not making progress (looping, blocked, or wedged).
  stuck('Stuck'),

  /// Not reporting — has not phoned home.
  offline('Offline');

  /// Creates a [HeartbeatStatus] with a display [label].
  const HeartbeatStatus(this.label);

  /// Human-readable display label.
  final String label;

  /// Whether this status indicates the agent needs attention.
  bool get needsAttention => this == HeartbeatStatus.stuck;

  /// Parses a stored value (case-insensitive), defaulting to [offline].
  static HeartbeatStatus fromStorage(String? value) {
    if (value == null) {
      return HeartbeatStatus.offline;
    }
    return HeartbeatStatus.values
            .where((s) => s.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        HeartbeatStatus.offline;
  }
}
