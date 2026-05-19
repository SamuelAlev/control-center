/// Lifecycle status of an organizational goal.
enum OrgGoalStatus {
  /// Actively being pursued.
  active('Active'),

  /// Reached its objective.
  achieved('Achieved'),

  /// Abandoned without being achieved.
  abandoned('Abandoned');

  /// Creates an [OrgGoalStatus] with a display [label].
  const OrgGoalStatus(this.label);

  /// Human-readable display label.
  final String label;

  /// Whether this is a terminal status (no further progress expected).
  bool get isTerminal => this != OrgGoalStatus.active;

  /// Parses a stored value (case-insensitive), defaulting to [active].
  static OrgGoalStatus fromStorage(String? value) {
    if (value == null) {
      return OrgGoalStatus.active;
    }
    return OrgGoalStatus.values
            .where((v) => v.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        OrgGoalStatus.active;
  }
}
