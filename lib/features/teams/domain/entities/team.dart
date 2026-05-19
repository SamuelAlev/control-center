/// A named group of agents that can be dispatched together.
class Team {
  Team({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    required this.createdAt,
  }) : assert(name.isNotEmpty, 'Team name must not be empty');

  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final DateTime createdAt;

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
