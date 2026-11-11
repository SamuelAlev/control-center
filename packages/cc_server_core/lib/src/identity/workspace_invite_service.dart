import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_invite.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_invite_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// The one-time result of creating an invite: the code is returned exactly
/// once and never stored (only its hash is).
class CreatedInvite {
  /// Creates a [CreatedInvite].
  const CreatedInvite({required this.invite, required this.code});

  /// The stored invite row (hash only).
  final WorkspaceInvite invite;

  /// The one-time redemption code.
  final String code;
}

/// The result of redeeming an invite: the (possibly JIT-provisioned) user and
/// the membership that was recorded.
class RedeemedInvite {
  /// Creates a [RedeemedInvite].
  const RedeemedInvite({
    required this.user,
    required this.member,
    required this.invite,
  });

  /// The admitted user.
  final User user;

  /// The recorded membership.
  final WorkspaceMember member;

  /// The redeemed invite.
  final WorkspaceInvite invite;
}

/// Email-optional workspace invites: an admin mints a signed, expiring,
/// single-use code (copy-paste link and QR); redeeming it JIT-provisions the
/// user, records membership at the invite's role, applies the invite's
/// per-repo grants and hands off to device pairing.
class WorkspaceInviteService {
  /// Creates a [WorkspaceInviteService].
  WorkspaceInviteService({
    required this._invites,
    required this._members,
    required this._users,
    this._eventBus,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final WorkspaceInviteRepository _invites;
  final WorkspaceMembershipRepository _members;
  final UserRepository _users;
  final DomainEventBus? _eventBus;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  /// Default invite validity window.
  static const defaultTtl = Duration(days: 7);

  /// Creates a single-use invite for [workspaceId] at [role], sharing exactly
  /// [repoGrants]. Returns the one-time code — show it once, never store it.
  Future<CreatedInvite> create({
    required String workspaceId,
    required String createdBy,
    required WorkspaceRole role,
    Map<String, RepoGrantLevel> repoGrants = const {},
    Duration ttl = defaultTtl,
  }) async {
    if (role == WorkspaceRole.owner) {
      throw ArgumentError(
        'Ownership is transferred explicitly, never granted by invite',
      );
    }
    final code = RemoteControlCrypto.generatePsk();
    final now = _now();
    final invite = WorkspaceInvite(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      codeHash: hashInviteCode(code),
      role: role,
      repoGrants: repoGrants,
      createdBy: createdBy,
      createdAt: now,
      expiresAt: now.add(ttl),
    );
    await _invites.upsert(invite);
    return CreatedInvite(invite: invite, code: code);
  }

  /// Only active, unexpired invites yield a Noise secret. The caller knows a
  /// public *second* digest; the stored hash itself never appears on the wire.
  Future<String?> resolveInvitePsk(String routeId) async {
    final invite = await _invites.getByRouteId(routeId);
    if (invite == null || !invite.isRedeemableAt(_now())) {
      return null;
    }
    return InvitePairingProof.pskFromHash(invite.codeHash);
  }

  /// Revokes the open invite [inviteId] in [workspaceId].
  Future<void> revoke(String workspaceId, String inviteId) async {
    final all = await _invites.getForWorkspace(workspaceId);
    final invite = all.where((i) => i.id == inviteId).firstOrNull;
    if (invite == null) {
      throw const NotFoundException('Invite not found');
    }
    await _invites.upsert(invite.copyWith(revokedAt: _now()));
  }

  /// Redeems [code]: validates it, claims the code atomically before
  /// provisioning a user, then records membership and repo grants.
  /// Denials are generic so probing codes reveals nothing about their status.
  Future<RedeemedInvite> redeem({
    required String code,
    String? handle,
    String? displayName,
    String? email,
  }) async {
    final invite = await _invites.getByCodeHash(hashInviteCode(code));
    if (invite == null || !invite.isRedeemableAt(_now())) {
      throw const AuthException('Invite is invalid or expired');
    }

    final now = _now();
    if (!await _invites.consume(invite, now)) {
      throw const AuthException('Invite is invalid or expired');
    }
    // A redeemed invite always provisions a new account: it never yields
    // an existing one, the server owner included.
    final user = await _provisionUser(
      handle: handle,
      displayName: displayName,
      email: email,
    );

    final existing = await _members.getMember(invite.workspaceId, user.id);
    final member =
        existing ??
        WorkspaceMember(
          id: _uuid.v4(),
          workspaceId: invite.workspaceId,
          userId: user.id,
          role: invite.role,
          invitedBy: invite.createdBy,
          joinedAt: now,
        );
    if (existing == null) {
      await _members.upsert(member);
      for (final entry in invite.repoGrants.entries) {
        await _members.setRepoGrant(
          invite.workspaceId,
          user.id,
          entry.key,
          entry.value,
        );
      }
    }

    await _invites.recordUsedBy(invite, user.id);
    if (existing == null) {
      _eventBus?.publish(
        WorkspaceMemberAdded(
          workspaceId: invite.workspaceId,
          userId: user.id,
          role: invite.role,
          occurredAt: now,
        ),
      );
    }

    return RedeemedInvite(
      user: user,
      member: member,
      invite: invite.copyWith(usedAt: now, usedBy: user.id),
    );
  }

  /// Creates the redeemer's account under a suggested username (the hint,
  /// else their name, else `member`, then the next free one). They choose
  /// their own in onboarding's first step.
  Future<User> _provisionUser({
    String? handle,
    String? displayName,
    String? email,
  }) {
    final suggested = Username.fromFreeText(
      handle ?? displayName ?? '',
      fallback: 'member',
    );
    final name = displayName?.trim() ?? '';
    return _users.insertWithFreeHandle(
      User(
        id: _uuid.v4(),
        handle: suggested.value,
        displayName: name.isNotEmpty ? name : suggested.value,
        email: email,
        createdAt: _now(),
      ),
    );
  }

  /// SHA-256 hex of an invite code — the only form that is ever stored.
  static String hashInviteCode(String code) =>
      sha256.convert(utf8.encode(code)).toString();
}
