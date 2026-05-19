/// An agent definition found on disk (an `AGENTS.md` file) that is not yet
/// registered in the workspace. Surfaced by discovery so the operator can
/// import it. This is the domain-facing shape; the parser's raw result stays
/// inside the data layer.
class DiscoveredAgent {
  /// Creates a [DiscoveredAgent].
  const DiscoveredAgent({
    required this.name,
    required this.title,
    required this.skills,
    required this.agentMdPath,
    this.reportsTo,
    this.persona,
  });

  /// The agent's unique name (from the file's frontmatter).
  final String name;

  /// The agent's display title.
  final String title;

  /// Skills declared in the file.
  final List<String> skills;

  /// Absolute path to the `AGENTS.md` file the definition came from.
  final String agentMdPath;

  /// Name of the manager agent declared in the file, if any.
  final String? reportsTo;

  /// Persona markdown body, if any.
  final String? persona;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredAgent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          title == other.title &&
          agentMdPath == other.agentMdPath &&
          reportsTo == other.reportsTo &&
          persona == other.persona &&
          _listEquals(skills, other.skills);

  @override
  int get hashCode => Object.hash(
        name,
        title,
        agentMdPath,
        reportsTo,
        persona,
        Object.hashAll(skills),
      );

  static bool _listEquals(List<String> a, List<String> b) {
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
