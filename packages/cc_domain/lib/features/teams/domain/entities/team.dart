/// A named group of agents that can be dispatched together, optionally led by
/// a single coordinating **leader** agent.
class Team {
  /// Creates a [Team] with the given properties.
  Team({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    this.leaderId,
    this.instructions,
    required this.createdAt,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Team name must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// Owning workspace identifier.
  final String workspaceId;

  /// Team display name.
  final String name;

  /// Optional team description.
  final String? description;

  /// Agent id of the team's leader, or `null` when the team has no leader.
  ///
  /// The leader is the coordinator: assigning work to the team routes through
  /// this agent, which evaluates the request and delegates to the best-suited
  /// member. A team without a leader cannot be leader-routed (work falls back
  /// to direct member dispatch).
  final String? leaderId;

  /// Optional free-form operating instructions appended to the leader's
  /// coordinator briefing (team conventions, escalation rules, tone).
  final String? instructions;

  /// Timestamp when the team was created.
  final DateTime createdAt;

  /// Whether this team has a designated leader and can be leader-routed.
  bool get hasLeader => leaderId != null && leaderId!.isNotEmpty;

  /// Returns a copy with optionally updated fields.
  ///
  /// [description], [leaderId] and [instructions] are cleared by passing the
  /// matching `clear*` flag (since `null` is a meaningful "leave unchanged"
  /// default).
  Team copyWith({
    String? name,
    String? description,
    String? leaderId,
    String? instructions,
    bool clearDescription = false,
    bool clearLeader = false,
    bool clearInstructions = false,
  }) => Team(
    id: id,
    workspaceId: workspaceId,
    name: name ?? this.name,
    description: clearDescription ? null : (description ?? this.description),
    leaderId: clearLeader ? null : (leaderId ?? this.leaderId),
    instructions: clearInstructions
        ? null
        : (instructions ?? this.instructions),
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
