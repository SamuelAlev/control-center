import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// One human user's membership in one workspace.
///
/// Users are global; membership (and therefore access) is workspace-scoped.
/// The pair `(workspaceId, userId)` is unique — a user holds exactly one role
/// per workspace.
///
/// Profile overlay columns (`displayName`, `email`, `gitAuthor*`) are this
/// member **in this workspace**. Null inherits the global `User` row. Handle,
/// SSO and onboarding stay on `User`.
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
    this.displayName,
    this.email,
    this.gitAuthorName,
    this.gitAuthorEmail,
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

  /// Display name in this workspace. Null inherits the global user row.
  final String? displayName;

  /// Email in this workspace. Null inherits the global user row.
  final String? email;

  /// Git author name in this workspace. Null inherits the global user row.
  final String? gitAuthorName;

  /// Git author email in this workspace. Null inherits the global user row.
  final String? gitAuthorEmail;

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
          joinedAt == other.joinedAt &&
          displayName == other.displayName &&
          email == other.email &&
          gitAuthorName == other.gitAuthorName &&
          gitAuthorEmail == other.gitAuthorEmail;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    userId,
    role,
    roleWire,
    invitedBy,
    joinedAt,
    displayName,
    email,
    gitAuthorName,
    gitAuthorEmail,
  );

  /// Returns a copy with optional overrides.
  WorkspaceMember copyWith({
    String? id,
    String? workspaceId,
    String? userId,
    WorkspaceRole? role,
    String? roleWire,
    String? invitedBy,
    DateTime? joinedAt,
    String? displayName,
    bool clearDisplayName = false,
    String? email,
    bool clearEmail = false,
    String? gitAuthorName,
    bool clearGitAuthorName = false,
    String? gitAuthorEmail,
    bool clearGitAuthorEmail = false,
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
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      email: clearEmail ? null : (email ?? this.email),
      gitAuthorName: clearGitAuthorName
          ? null
          : (gitAuthorName ?? this.gitAuthorName),
      gitAuthorEmail: clearGitAuthorEmail
          ? null
          : (gitAuthorEmail ?? this.gitAuthorEmail),
    );
  }
}
