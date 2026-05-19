class MemoryDomain {
  MemoryDomain({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.label,
    this.description,
    required this.createdAt,
    required this.createdByRole,
  }) : assert(workspaceId.isNotEmpty, 'MemoryDomain workspaceId must not be empty'),
       assert(name.isNotEmpty, 'MemoryDomain name must not be empty');

  final String id;
  final String workspaceId;
  final String name;
  final String label;
  final String? description;
  final DateTime createdAt;
  final String createdByRole;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryDomain &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          name == other.name &&
          label == other.label &&
          description == other.description &&
          createdByRole == other.createdByRole;

  @override
  int get hashCode => Object.hash(
    id, workspaceId, name, label, description, createdByRole,
  );
}
