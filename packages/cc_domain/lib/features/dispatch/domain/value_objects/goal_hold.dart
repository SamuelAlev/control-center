/// What an active or paused goal is waiting on. The status says whether the
/// goal is alive; the hold says why no segment is running right now. Null
/// means nothing is held: a segment is running or the next one is queued.
enum GoalHold {
  /// The goal is owed something (a wake, a reply, a watched event) and waits
  /// for it instead of running again at once.
  waiting,

  /// The agent claimed completion and the server is verifying the claim.
  verifying,

  /// A provider usage limit was reached. The goal resumes after the reset.
  limit,

  /// A run is waiting for a person to answer a question or an approval.
  person,

  /// A person stopped or paused the goal.
  byPerson,

  /// The goal cannot go on by itself (it stalled, verification failed too
  /// often, or no sandbox was available) and a person must decide.
  needsReview,
}

/// Wire names for [GoalHold] (persisted as TEXT).
extension GoalHoldWire on GoalHold {
  /// Persisted wire name.
  String get wire => switch (this) {
    GoalHold.waiting => 'waiting',
    GoalHold.verifying => 'verifying',
    GoalHold.limit => 'limit',
    GoalHold.person => 'person',
    GoalHold.byPerson => 'by_person',
    GoalHold.needsReview => 'needs_review',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final hold in GoalHold.values) hold.wire,
  ];

  /// Parses a wire name. Null for no hold and for an unknown value.
  static GoalHold? tryParse(String? raw) {
    for (final hold in GoalHold.values) {
      if (hold.wire == raw) {
        return hold;
      }
    }
    return null;
  }
}
