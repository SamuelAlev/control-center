import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:collection/collection.dart';

/// A single-use, expiring invitation into one workspace.
///
/// Invites work with no email server: the admin copies a link (or shows a
/// QR) carrying the one-time code. Only the SHA-256 hash of the code is
/// stored; redeeming JIT-provisions the user, records membership at [role],
/// applies [repoGrants] and starts device pairing.
class WorkspaceInvite {
  /// Creates a [WorkspaceInvite].
  WorkspaceInvite({
    required this.id,
    required this.workspaceId,
    required this.codeHash,
    required this.role,
    required this.repoGrants,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedBy,
    this.revokedAt,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('WorkspaceInvite id must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('WorkspaceInvite workspaceId must not be empty');
    }
    if (codeHash.isEmpty) {
      throw ArgumentError('WorkspaceInvite codeHash must not be empty');
    }
    if (role == WorkspaceRole.owner) {
      throw ArgumentError(
        'Ownership is transferred explicitly, never granted by invite',
      );
    }
  }

  /// Unique identifier.
  final String id;

  /// The workspace being shared.
  final String workspaceId;

  /// SHA-256 hex hash of the one-time invite code (the code itself is shown
  /// once at creation and never stored).
  final String codeHash;

  /// Role the redeeming user will hold.
  final WorkspaceRole role;

  /// Exactly which linked repos are being shared and at what level. Repos
  /// absent from this map are NOT shared (`RepoGrantLevel.none`), so adding a
  /// member never silently out-privileges the forge.
  final Map<String, RepoGrantLevel> repoGrants;

  /// The user who created the invite.
  final String createdBy;

  /// When the invite was created.
  final DateTime createdAt;

  /// When the invite stops being redeemable.
  final DateTime expiresAt;

  /// When the invite was redeemed, or null while open.
  final DateTime? usedAt;

  /// The user provisioned/admitted by the redemption, or null while open.
  final String? usedBy;

  /// When the invite was revoked by an admin, or null.
  final DateTime? revokedAt;

  /// Whether the invite has been redeemed.
  bool get isUsed => usedAt != null;

  /// Whether the invite has been revoked.
  bool get isRevoked => revokedAt != null;

  /// Whether the invite can still be redeemed at [now].
  bool isRedeemableAt(DateTime now) =>
      !isUsed && !isRevoked && now.isBefore(expiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceInvite &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          codeHash == other.codeHash &&
          role == other.role &&
          const MapEquality<String, RepoGrantLevel>().equals(
            repoGrants,
            other.repoGrants,
          ) &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          expiresAt == other.expiresAt &&
          usedAt == other.usedAt &&
          usedBy == other.usedBy &&
          revokedAt == other.revokedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    codeHash,
    role,
    const MapEquality<String, RepoGrantLevel>().hash(repoGrants),
    createdBy,
    createdAt,
    expiresAt,
    usedAt,
    usedBy,
    revokedAt,
  );

  /// Returns a copy with optional overrides.
  WorkspaceInvite copyWith({
    String? id,
    String? workspaceId,
    String? codeHash,
    WorkspaceRole? role,
    Map<String, RepoGrantLevel>? repoGrants,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedBy,
    DateTime? revokedAt,
  }) {
    return WorkspaceInvite(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      codeHash: codeHash ?? this.codeHash,
      role: role ?? this.role,
      repoGrants: repoGrants ?? this.repoGrants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedBy: usedBy ?? this.usedBy,
      revokedAt: revokedAt ?? this.revokedAt,
    );
  }
}
