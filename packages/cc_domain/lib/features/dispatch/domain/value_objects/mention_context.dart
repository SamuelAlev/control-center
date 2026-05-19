/// Context about an agent being mentioned/summoned in a channel, including
/// who summoned them and the full channel roster at time of mention.
class MentionContext {
  /// Creates a [MentionContext] with the summoning agent and channel roster.
  const MentionContext({
    required this.summonedBy,
    required this.channelRoster,
  });

  /// The agent that summoned this agent (the "@sender").
  final String summonedBy;

  /// The full roster of the channel at the moment of mention.
  final List<MentionRosterEntry> channelRoster;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionContext &&
          runtimeType == other.runtimeType &&
          summonedBy == other.summonedBy &&
          _listEquals(channelRoster, other.channelRoster);

  @override
  int get hashCode => Object.hash(summonedBy, Object.hashAll(channelRoster));

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

/// A single entry in a channel's mention roster: an agent present in the
/// channel at the time of a mention.
class MentionRosterEntry {
  /// Creates a [MentionRosterEntry].
  const MentionRosterEntry({
    required this.agentId,
    required this.name,
    required this.isTopLevel,
  });

  /// The agent's unique identifier.
  final String agentId;

  /// The agent's display name.
  final String name;

  /// Whether this agent is a top-level (human) participant.
  final bool isTopLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionRosterEntry &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          name == other.name &&
          isTopLevel == other.isTopLevel;

  @override
  int get hashCode => Object.hash(agentId, name, isTopLevel);
}
