/// One agent in the workspace an executing agent can hand work to.
///
/// Deliberately not the full `Agent` entity: the prompt needs an id (the
/// argument `delegate_task` takes), a name to address and enough about the
/// teammate to judge "is this one better suited than me" — nothing else.
class TeammateBrief {
  /// Creates a [TeammateBrief].
  const TeammateBrief({
    required this.id,
    required this.name,
    required this.title,
    this.skills = const [],
    this.isTopLevel = false,
  });

  /// The teammate's agent id — what `delegate_task`/`ask_agent` take.
  final String id;

  /// Handle used to address them (`@name`).
  final String name;

  /// Their role title.
  final String title;

  /// Their skills, the main signal for "better suited than me".
  final List<String> skills;

  /// Whether they report to nobody (a peer rather than a subordinate).
  final bool isTopLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeammateBrief &&
          id == other.id &&
          name == other.name &&
          title == other.title &&
          isTopLevel == other.isTopLevel &&
          _skillsEq(skills, other.skills);

  @override
  int get hashCode => Object.hash(id, name, title, isTopLevel, skills.length);
}

bool _skillsEq(List<String> a, List<String> b) {
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
