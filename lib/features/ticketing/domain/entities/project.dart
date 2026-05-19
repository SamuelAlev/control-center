/// Lifecycle status of a [Project].
enum ProjectStatus {
  /// Work is ongoing.
  active,

  /// The project's goal has been reached.
  completed,

  /// Set aside; hidden from the default sidebar list.
  archived;

  /// Whether the project is still being worked on.
  bool get isActive => this == ProjectStatus.active;

  /// Parses a stored value, defaulting to [active] for unknown input.
  static ProjectStatus fromStorage(String? value) =>
      ProjectStatus.values.where((s) => s.name == value).firstOrNull ??
      ProjectStatus.active;

  /// The stored string form.
  String toStorageString() => name;
}

/// A small fixed palette of project colors. The color is always paired with
/// the project name (and an icon) in the UI — never status-by-color-alone. The
/// names map to design system token hues in the presentation layer.
enum ProjectColor {
  /// Neutral gray (default).
  gray,

  /// Brand blue.
  blue,

  /// Success green.
  green,

  /// Caution amber.
  amber,

  /// Alert red.
  red,

  /// Purple.
  purple,

  /// Teal.
  teal,

  /// Pink.
  pink;

  /// Parses a stored value, defaulting to [gray] for unknown input.
  static ProjectColor fromStorage(String? value) =>
      ProjectColor.values.where((c) => c.name == value).firstOrNull ??
      ProjectColor.gray;

  /// The stored string form.
  String toStorageString() => name;
}

/// A workspace-scoped grouping of tickets toward a shared goal (e.g. "Make
/// auth work", "Go-to-market"). Control-Center-only metadata: projects are not
/// synced to any remote ticket provider.
class Project {
  /// Creates a [Project].
  Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    this.color = ProjectColor.gray,
    this.status = ProjectStatus.active,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(name != '', 'Project name must not be empty');

  /// Unique project id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// Short human-readable name.
  final String name;

  /// Optional longer description / goal.
  final String? description;

  /// Display color (paired with the name; never color alone).
  final ProjectColor color;

  /// Lifecycle status.
  final ProjectStatus status;

  /// When the project was created.
  final DateTime createdAt;

  /// Last mutation time.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  Project copyWith({
    String? name,
    String? description,
    bool removeDescription = false,
    ProjectColor? color,
    ProjectStatus? status,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      workspaceId: workspaceId,
      name: name ?? this.name,
      description: removeDescription ? null : (description ?? this.description),
      color: color ?? this.color,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          color == other.color &&
          status == other.status &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, description, color, status, updatedAt);
}
