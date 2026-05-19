/// A recorded contradiction between two memory facts in the same workspace.
///
/// When two active facts share a `(domain, topic)` but assert materially
/// different content, the memory engine records a [MemoryConflict] and supersedes
/// the loser. The row is the audit trail: which two facts clashed, how it was
/// resolved, and when.
class MemoryConflict {
  /// Creates a [MemoryConflict].
  MemoryConflict({
    required this.id,
    required this.workspaceId,
    required this.factAId,
    required this.factBId,
    this.conflictType = 'contradiction',
    this.resolution,
    this.winningFactId,
    this.resolvedAt,
    required this.createdAt,
  }) : assert(workspaceId.isNotEmpty, 'MemoryConflict workspaceId must not be empty');

  /// Unique identifier.
  final String id;
  /// Workspace this conflict belongs to.
  final String workspaceId;
  /// One side of the conflict (the loser, by convention, when resolved).
  final String factAId;
  /// The other side of the conflict (the winner, by convention, when resolved).
  final String factBId;
  /// Kind of conflict. Currently always `contradiction`.
  final String conflictType;
  /// How it was resolved (e.g. `superseded`), or null while open.
  final String? resolution;
  /// The fact that won, or null while open.
  final String? winningFactId;
  /// When it was resolved, or null while open.
  final DateTime? resolvedAt;
  /// When the conflict was first detected.
  final DateTime createdAt;

  /// Whether this conflict has been resolved.
  bool get isResolved => resolution != null;

  /// Returns a copy with optional field overrides.
  MemoryConflict copyWith({
    String? resolution,
    String? winningFactId,
    DateTime? resolvedAt,
  }) =>
      MemoryConflict(
        id: id,
        workspaceId: workspaceId,
        factAId: factAId,
        factBId: factBId,
        conflictType: conflictType,
        resolution: resolution ?? this.resolution,
        winningFactId: winningFactId ?? this.winningFactId,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryConflict &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          factAId == other.factAId &&
          factBId == other.factBId &&
          conflictType == other.conflictType &&
          resolution == other.resolution &&
          winningFactId == other.winningFactId;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        factAId,
        factBId,
        conflictType,
        resolution,
        winningFactId,
      );
}