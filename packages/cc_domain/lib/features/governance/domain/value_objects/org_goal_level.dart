/// Level of a goal in the organizational hierarchy
/// (company → team → agent → task).
enum OrgGoalLevel {
  /// The company mission — the root of the goal tree.
  company('Company'),

  /// A team objective beneath the company mission.
  team('Team'),

  /// An individual agent's goal beneath a team objective.
  agent('Agent'),

  /// A concrete task beneath an agent goal, usually realized by a ticket.
  task('Task');

  /// Creates an [OrgGoalLevel] with a display [label].
  const OrgGoalLevel(this.label);

  /// Human-readable display label.
  final String label;

  /// Parses a stored value (case-insensitive), defaulting to [company].
  static OrgGoalLevel fromStorage(String? value) {
    if (value == null) {
      return OrgGoalLevel.company;
    }
    return OrgGoalLevel.values
            .where((v) => v.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        OrgGoalLevel.company;
  }
}
