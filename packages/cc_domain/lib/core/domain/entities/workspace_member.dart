import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// One human user's membership in one workspace.
///
/// Users are global; membership (and therefore access) is workspace-scoped.
/// The pair `(workspaceId, userId)` is unique — a user holds exactly one role
/// per workspace.
class WorkspaceMember {
  /// Creates a [WorkspaceMember].
  WorkspaceMember({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    this.invitedBy,
    required this.joinedAt,
  }) : assert(id.isNotEmpty, 'WorkspaceMember id must not be empty'),
       assert(
         workspaceId.isNotEmpty,
         'WorkspaceMember workspaceId must not be empty',
       ),
       assert(userId.isNotEmpty, 'WorkspaceMember userId must not be empty');

  /// Unique identifier.
  final String id;

  /// The workspace this membership belongs to.
  final String workspaceId;

  /// The user who is a member.
  final String userId;

  /// The member's role in this workspace.
  final WorkspaceRole role;

  /// The user id of whoever invited this member (null for the bootstrap
  /// owner).
  final String? invitedBy;

  /// When the membership was created.
  final DateTime joinedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          userId == other.userId &&
          role == other.role &&
          invitedBy == other.invitedBy &&
          joinedAt == other.joinedAt;

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, userId, role, invitedBy, joinedAt);

  /// Returns a copy with optional overrides.
  WorkspaceMember copyWith({
    String? id,
    String? workspaceId,
    String? userId,
    WorkspaceRole? role,
    String? invitedBy,
    DateTime? joinedAt,
  }) {
    return WorkspaceMember(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      invitedBy: invitedBy ?? this.invitedBy,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
