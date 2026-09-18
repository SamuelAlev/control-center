/// A GitHub issue/PR label as returned on pull-request payloads and
/// `labeled` / `unlabeled` timeline events.
class GitHubLabel {
  /// Creates a [GitHubLabel].
  const GitHubLabel({
    required this.name,
    this.color = '',
    this.description = '',
  });

  /// Creates a [GitHubLabel] from JSON.
  factory GitHubLabel.fromJson(Map<String, dynamic> json) => GitHubLabel(
    name: json['name'] as String? ?? '',
    color: json['color'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );

  /// Serializes this label back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'color': color,
    if (description.isNotEmpty) 'description': description,
  };

  /// Display name.
  final String name;

  /// 6-digit hex, no `#`.
  final String color;

  /// Optional description.
  final String description;
}
