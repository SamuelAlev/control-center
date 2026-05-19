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
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
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
    required WorkspaceInviteRepository invites,
    required WorkspaceMembershipRepository members,
    required UserRepository users,
    DomainEventBus? eventBus,
    DateTime Function()? now,
  }) : _invites = invites,
       _members = members,
       _users = users,
       _eventBus = eventBus,
       _now = now ?? DateTime.now;

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

  /// Revokes the open invite [inviteId] in [workspaceId].
  Future<void> revoke(String workspaceId, String inviteId) async {
    final all = await _invites.getForWorkspace(workspaceId);
    final invite = all.where((i) => i.id == inviteId).firstOrNull;
    if (invite == null) {
      throw const NotFoundException('Invite not found');
    }
    await _invites.upsert(invite.copyWith(revokedAt: _now()));
  }

  /// Redeems [code]: validates it, JIT-provisions the user (or admits an
  /// existing one by [existingUserId]), records membership + repo grants and
  /// marks the invite used. Denials are generic — the code is the proof and
  /// an attacker probing codes learns nothing about which ones exist.
  Future<RedeemedInvite> redeem({
    required String code,
    String? handle,
    String? displayName,
    String? email,
    String? existingUserId,
  }) async {
    final invite = await _invites.getByCodeHash(hashInviteCode(code));
    if (invite == null || !invite.isRedeemableAt(_now())) {
      throw const AuthException('Invite is invalid or expired');
    }

    final user = existingUserId != null
        ? await _users.getById(existingUserId)
        : await _provisionUser(
            handle: handle,
            displayName: displayName,
            email: email,
          );
    if (user == null) {
      throw const AuthException('Invite is invalid or expired');
    }

    final existing = await _members.getMember(invite.workspaceId, user.id);
    final now = _now();
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
      _eventBus?.publish(
        WorkspaceMemberAdded(
          workspaceId: invite.workspaceId,
          userId: user.id,
          role: invite.role,
          occurredAt: now,
        ),
      );
    }

    await _invites.upsert(invite.copyWith(usedAt: now, usedBy: user.id));
    _eventBus?.publish(
      WorkspaceInviteRedeemed(
        workspaceId: invite.workspaceId,
        inviteId: invite.id,
        userId: user.id,
        occurredAt: now,
      ),
    );
    return RedeemedInvite(user: user, member: member, invite: invite);
  }

  Future<User> _provisionUser({
    String? handle,
    String? displayName,
    String? email,
  }) async {
    final base = _sanitizeHandle(handle ?? displayName ?? 'member');
    var candidate = base;
    var suffix = 1;
    while (await _users.getByHandle(candidate) != null) {
      suffix += 1;
      candidate = '$base$suffix';
    }
    final user = User(
      id: _uuid.v4(),
      handle: candidate,
      displayName: (displayName?.isNotEmpty ?? false)
          ? displayName!
          : candidate,
      email: email,
      createdAt: _now(),
    );
    await _users.upsert(user);
    _eventBus?.publish(UserCreated(userId: user.id, occurredAt: _now()));
    return user;
  }

  /// SHA-256 hex of an invite code — the only form that is ever stored.
  static String hashInviteCode(String code) =>
      sha256.convert(utf8.encode(code)).toString();

  static String _sanitizeHandle(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_.-]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    return cleaned.isEmpty ? 'member' : cleaned;
  }
}
