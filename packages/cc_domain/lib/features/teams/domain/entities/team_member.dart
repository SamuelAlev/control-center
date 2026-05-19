/// Role a member plays within a team.
enum TeamMemberRole {
  /// Team leader with full permissions.
  leader,
  /// Regular team member.
  member;

  /// Parses a [TeamMemberRole] from its storage string.
  static TeamMemberRole fromString(String value) => switch (value) {
        'leader' => TeamMemberRole.leader,
        _ => TeamMemberRole.member,
      };

  /// Serializes this role to its storage string.
  String toStorageString() => name;
}

/// Links an agent to a team with an optional role.
class TeamMember {
  /// Creates a [TeamMember].
  TeamMember({
    required this.teamId,
    required this.agentId,
    this.role = TeamMemberRole.member,
  });

  /// The team this member belongs to.
  final String teamId;
  /// The agent assigned to the team.
  final String agentId;
  /// The role this member plays in the team.
  final TeamMemberRole role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          agentId == other.agentId;

  @override
  int get hashCode => Object.hash(teamId, agentId);
}
