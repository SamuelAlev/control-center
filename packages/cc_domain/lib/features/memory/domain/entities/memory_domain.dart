/// A named, labelled domain for memory entries within a workspace.
class MemoryDomain {
/// Creates a [MemoryDomain].
///
/// [workspaceId] and [name] must not be empty.
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

  /// Unique identifier.
  final String id;
  /// Workspace this domain belongs to.
  final String workspaceId;
  /// Unique machine-readable name (slug).
  final String name;
  /// Human-readable label for display.
  final String label;
  /// Optional longer description of the domain.
  final String? description;
  /// Timestamp when this domain was created.
  final DateTime createdAt;
  /// Role of the agent who created this domain.
  final String createdByRole;

  @override
  /// Equality based on all fields except [createdAt].
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
