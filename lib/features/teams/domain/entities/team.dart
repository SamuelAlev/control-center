/// A named group of agents that can be dispatched together.
class Team {
  /// Creates a [Team] with the given properties.
  Team({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    required this.createdAt,
  }) : assert(name.isNotEmpty, 'Team name must not be empty');

  /// Unique identifier.
  final String id;
  /// Owning workspace identifier.
  final String workspaceId;
  /// Team display name.
  final String name;
  /// Optional team description.
  final String? description;
  /// Timestamp when the team was created.
  final DateTime createdAt;

  /// Returns a copy with optionally updated [name] and/or [description].
  Team copyWith({String? name, String? description}) => Team(
        id: id,
        workspaceId: workspaceId,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
