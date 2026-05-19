/// Context about an agent being mentioned/summoned in a space, including
/// who summoned them and the full space roster at time of mention.
class MentionContext {
  /// Creates a [MentionContext] with the summoning agent and space roster.
  const MentionContext({required this.summonedBy, required this.spaceRoster});

  /// The agent that summoned this agent (the "@sender").
  final String summonedBy;

  /// The full roster of the space at the moment of mention.
  final List<MentionRosterEntry> spaceRoster;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionContext &&
          runtimeType == other.runtimeType &&
          summonedBy == other.summonedBy &&
          _listEquals(spaceRoster, other.spaceRoster);

  @override
  int get hashCode => Object.hash(summonedBy, Object.hashAll(spaceRoster));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Whether a roster entry is an agent or a human user.
enum MentionRosterKind { agent, user }

/// A single entry in a space's mention roster: an agent or a human present
/// in the space at the time of a mention (PRD 16 §15: principals, not just
/// agents).
class MentionRosterEntry {
  /// Creates a [MentionRosterEntry] for an agent participant.
  const MentionRosterEntry.agent({
    required this.agentId,
    required this.name,
    required this.isTopLevel,
  }) : userId = null,
       kind = MentionRosterKind.agent;

  /// Creates a [MentionRosterEntry] for a human member.
  const MentionRosterEntry.user({required this.userId, required this.name})
    : agentId = null,
      isTopLevel = true,
      kind = MentionRosterKind.user;

  /// The agent's unique identifier (null for human entries).
  final String? agentId;

  /// The human user's unique identifier (null for agent entries).
  final String? userId;

  /// The display name.
  final String name;

  /// Whether this agent is a top-level (human-directed) participant.
  final bool isTopLevel;

  /// Whether this entry is an agent or a human user.
  final MentionRosterKind kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionRosterEntry &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          userId == other.userId &&
          name == other.name &&
          isTopLevel == other.isTopLevel &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(agentId, userId, name, isTopLevel, kind);
}
