/// What a goal does when one of its runs asks a question and nobody answers.
/// Approvals are never released by either value.
enum GoalUnattendedPolicy {
  /// Waits for a person; the request expires at the workspace's expiry
  /// (72 hours by default).
  wait,

  /// After 10 minutes the question is released: the agent states its
  /// assumption and proceeds only if the stop conditions allow it.
  assume,
}

/// Wire names for [GoalUnattendedPolicy] (persisted as TEXT).
extension GoalUnattendedPolicyWire on GoalUnattendedPolicy {
  /// Persisted wire name.
  String get wire => switch (this) {
    GoalUnattendedPolicy.wait => 'wait',
    GoalUnattendedPolicy.assume => 'assume',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in GoalUnattendedPolicy.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static GoalUnattendedPolicy? tryParse(String? raw) {
    for (final value in GoalUnattendedPolicy.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}
