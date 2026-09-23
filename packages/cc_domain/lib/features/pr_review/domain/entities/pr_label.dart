/// A forge-assigned label on a pull request (GitHub label, GitLab label).
///
/// [color] is a 6-digit sRGB hex with no leading `#` — the shape GitHub's
/// REST and GraphQL APIs publish. An empty color means the forge omitted it
/// (GitLab's default list payload is names only) and the chip falls back to
/// the muted tag treatment.
class PrLabel {
  /// Creates a [PrLabel].
  const PrLabel({required this.name, this.color = '', this.description = ''});

  /// Display name (`bug`, `dependencies`).
  final String name;

  /// 6-digit hex background, no `#`. Empty when unknown.
  final String color;

  /// Optional description the forge attached to the label.
  final String description;

  /// Builds a label from a forge payload.
  ///
  /// Strips a leading `#` from [color] so GitLab's `#RRGGBB` and GitHub's
  /// 6-digit hex land in the same field.
  factory PrLabel.fromForge({
    required String name,
    String color = '',
    String description = '',
  }) {
    final hex = color.trim();
    return PrLabel(
      name: name,
      color: hex.startsWith('#') ? hex.substring(1) : hex,
      description: description,
    );
  }

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrLabel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          color == other.color &&
          description == other.description;

  /// Hash code.
  @override
  int get hashCode => Object.hash(name, color, description);
}
