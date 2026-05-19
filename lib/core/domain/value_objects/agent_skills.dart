/// Immutable collection of skills assigned to an agent.
///
/// Comparison is case-insensitive.
class AgentSkills {
  /// Creates an [AgentSkills] value object from a list of skill names.
  AgentSkills(List<String> skills) : _skills = List.unmodifiable(skills);

  final List<String> _skills;

  /// To list.
  List<String> toList() => List.unmodifiable(_skills);

  /// True when the named skill is present (case-insensitive).
  bool hasSkill(String skillName) =>
      _skills.any((s) => s.toLowerCase() == skillName.toLowerCase());

  /// True when no skills are assigned.
  bool get isEmpty => _skills.isEmpty;

  /// True when at least one skill is assigned.
  bool get isNotEmpty => _skills.isNotEmpty;

  /// Join.
  String join(String separator) => _skills.join(separator);

  /// Where.
  List<String> where(bool Function(String) test) =>
      _skills.where(test).toList();

  /// Take.
  List<String> take(int count) => _skills.take(count).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentSkills &&
          runtimeType == other.runtimeType &&
          _skillSetEquals(_skills, other._skills);

  @override
  int get hashCode => Object.hashAll(_skills.map((s) => s.toLowerCase()));

  static bool _skillSetEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    final aLower = a.map((s) => s.toLowerCase()).toSet();
    final bLower = b.map((s) => s.toLowerCase()).toSet();
    return aLower.containsAll(bLower) && bLower.containsAll(aLower);
  }

  @override
  String toString() => 'AgentSkills(${_skills.join(", ")})';
}
