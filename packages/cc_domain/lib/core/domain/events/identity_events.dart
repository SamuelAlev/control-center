import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// A user joined a workspace (invite redemption or admin add).
class WorkspaceMemberAdded implements DomainEvent {
  /// Creates a [WorkspaceMemberAdded] event.
  const WorkspaceMemberAdded({
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.occurredAt,
  });

  /// The workspace joined.
  final String workspaceId;

  /// The joining user.
  final String userId;

  /// The role granted.
  final WorkspaceRole role;

  @override
  final DateTime occurredAt;
}

/// A member was removed from a workspace. Live sessions of the removed user
/// scoped to this workspace must re-check access immediately.
class WorkspaceMemberRemoved implements DomainEvent {
  /// Creates a [WorkspaceMemberRemoved] event.
  const WorkspaceMemberRemoved({
    required this.workspaceId,
    required this.userId,
    required this.occurredAt,
  });

  /// The workspace left.
  final String workspaceId;

  /// The removed user.
  final String userId;

  @override
  final DateTime occurredAt;
}

/// A member's role changed.
class WorkspaceMemberRoleChanged implements DomainEvent {
  /// Creates a [WorkspaceMemberRoleChanged] event.
  const WorkspaceMemberRoleChanged({
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.occurredAt,
  });

  /// The workspace.
  final String workspaceId;

  /// The affected user.
  final String userId;

  /// The new role.
  final WorkspaceRole role;

  @override
  final DateTime occurredAt;
}

/// A user's username, display name or avatar changed.
///
/// The one path a rename takes to every server-side cache of who someone is
/// (presence roster names today): writers publish it after the row is
/// stored, caches listen, nobody calls a cache directly. Clients learn of it
/// through `users.watchAll`, which re-emits on the write itself.
class UserProfileChanged implements DomainEvent {
  /// Creates a [UserProfileChanged] event.
  const UserProfileChanged({
    required this.userId,
    required this.previousHandle,
    required this.handle,
    required this.displayName,
    required this.avatarRef,
    required this.occurredAt,
  });

  /// The user.
  final String userId;

  /// The username before the change (equal to [handle] when it did not
  /// change).
  final String previousHandle;

  /// The username now.
  final String handle;

  /// The display name now.
  final String displayName;

  /// The avatar reference now (null: none).
  final String? avatarRef;

  /// Whether the username itself changed.
  bool get renamed => previousHandle != handle;

  @override
  final DateTime occurredAt;
}
