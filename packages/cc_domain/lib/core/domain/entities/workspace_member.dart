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
    String? roleWire,
  }) : roleWire = roleWire ?? role.wireName {
    if (id.isEmpty) {
      throw ArgumentError('WorkspaceMember id must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('WorkspaceMember workspaceId must not be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('WorkspaceMember userId must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// The workspace this membership belongs to.
  final String workspaceId;

  /// The user who is a member.
  final String userId;

  /// The member's role in this workspace.
  ///
  /// For a CUSTOM role this is its base preset — every existing role gate
  /// therefore keeps working unchanged and can never be widened by one, since
  /// a custom role is subtractive. [roleWire] carries which custom role it is.
  final WorkspaceRole role;

  /// The stored wire value: a preset name, or `custom:<id>`.
  ///
  /// Kept alongside [role] rather than replacing it so the change is
  /// additive: code that only asks "is this member an admin?" is unaffected,
  /// and only the permission resolver needs the custom row.
  final String roleWire;

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
          roleWire == other.roleWire &&
          invitedBy == other.invitedBy &&
          joinedAt == other.joinedAt;

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, userId, role, roleWire, invitedBy, joinedAt);

  /// Returns a copy with optional overrides.
  WorkspaceMember copyWith({
    String? id,
    String? workspaceId,
    String? userId,
    WorkspaceRole? role,
    String? roleWire,
    String? invitedBy,
    DateTime? joinedAt,
  }) {
    return WorkspaceMember(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      // A role change without an explicit wire value re-derives it, so
      // assigning a preset clears any custom role the member held.
      roleWire: roleWire ?? (role != null ? role.wireName : this.roleWire),
      invitedBy: invitedBy ?? this.invitedBy,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
