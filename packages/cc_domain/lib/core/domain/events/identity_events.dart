import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// A new user was provisioned (bootstrap, invite redemption, or OIDC JIT).
class UserCreated implements DomainEvent {
  /// Creates a [UserCreated] event.
  const UserCreated({required this.userId, required this.occurredAt});

  /// The new user's id.
  final String userId;

  @override
  final DateTime occurredAt;
}

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

/// A device credential was revoked. Any live session authenticated by this
/// device must be terminated within seconds, not on next reconnect.
class UserDeviceRevoked implements DomainEvent {
  /// Creates a [UserDeviceRevoked] event.
  const UserDeviceRevoked({
    required this.deviceId,
    required this.userId,
    required this.occurredAt,
  });

  /// The revoked device.
  final String deviceId;

  /// The user the device belonged to.
  final String userId;

  @override
  final DateTime occurredAt;
}

/// An invite was redeemed: the user exists, membership is recorded and
/// device pairing has begun.
class WorkspaceInviteRedeemed implements DomainEvent {
  /// Creates a [WorkspaceInviteRedeemed] event.
  const WorkspaceInviteRedeemed({
    required this.workspaceId,
    required this.inviteId,
    required this.userId,
    required this.occurredAt,
  });

  /// The workspace joined.
  final String workspaceId;

  /// The redeemed invite.
  final String inviteId;

  /// The provisioned/admitted user.
  final String userId;

  @override
  final DateTime occurredAt;
}
