class MentionContext {
  const MentionContext({
    required this.summonedBy,
    required this.channelRoster,
  });

  final String summonedBy;
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
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class MentionRosterEntry {
  const MentionRosterEntry({
    required this.agentId,
    required this.name,
    required this.isTopLevel,
  });

  final String agentId;
  final String name;
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
