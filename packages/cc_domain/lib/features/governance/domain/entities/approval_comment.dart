/// A single immutable comment in an approval's review discussion.
class ApprovalComment {
  /// Creates an [ApprovalComment].
  const ApprovalComment({
    required this.id,
    required this.approvalId,
    required this.workspaceId,
    this.authorType = 'user',
    this.authorId,
    required this.body,
    required this.createdAt,
  });

  /// Unique comment identifier.
  final String id;

  /// Approval this comment belongs to.
  final String approvalId;

  /// Owning workspace (mirrors the parent approval).
  final String workspaceId;

  /// Actor type that authored the comment (`user`, `agent`, `system`).
  final String authorType;

  /// Identifier of the authoring actor, if known.
  final String? authorId;

  /// The comment body.
  final String body;

  /// When the comment was written.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalComment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          approvalId == other.approvalId &&
          workspaceId == other.workspaceId &&
          authorType == other.authorType &&
          authorId == other.authorId &&
          body == other.body &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    approvalId,
    workspaceId,
    authorType,
    authorId,
    body,
    createdAt,
  );
}
