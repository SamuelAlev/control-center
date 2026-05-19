/// Governance lifecycle status of an agent — distinct from its runtime
/// liveness (heartbeat) and its derived live state (what it is doing now).
///
/// This is the durable, human-or-policy-set status: an [active] agent may be
/// dispatched; a [paused] agent is held (e.g. a budget hard-stop tripped, or a
/// human paused it) and must not be dispatched until resumed; an [archived]
/// agent is retired.
enum AgentLifecycleStatus {
  /// Eligible for dispatch.
  active('Active'),

  /// Held — not eligible for dispatch (budget hard-stop or manual pause).
  paused('Paused'),

  /// Retired and hidden from active rosters.
  archived('Archived');

  /// Creates an [AgentLifecycleStatus] with a display [label].
  const AgentLifecycleStatus(this.label);

  /// Human-readable display label.
  final String label;

  /// Whether an agent in this status may be dispatched.
  bool get isDispatchable => this == AgentLifecycleStatus.active;

  /// Parses a stored value (case-insensitive), defaulting to [active].
  static AgentLifecycleStatus fromStorage(String? value) {
    if (value == null) {
      return AgentLifecycleStatus.active;
    }
    return AgentLifecycleStatus.values
            .where((v) => v.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        AgentLifecycleStatus.active;
  }
}
