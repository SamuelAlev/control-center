/// Role a member plays within a team.
enum TeamMemberRole {
  leader,
  member;

  static TeamMemberRole fromString(String value) => switch (value) {
        'leader' => TeamMemberRole.leader,
        _ => TeamMemberRole.member,
      };

  String toStorageString() => name;
}

/// Links an agent to a team with an optional role.
class TeamMember {
  TeamMember({
    required this.teamId,
    required this.agentId,
    this.role = TeamMemberRole.member,
  });

  final String teamId;
  final String agentId;
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
