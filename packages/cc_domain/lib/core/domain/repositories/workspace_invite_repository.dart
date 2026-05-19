import 'package:cc_domain/core/domain/entities/workspace_invite.dart';

/// Persistence port for workspace invites.
///
/// The invite *code* is never stored — only its SHA-256 hash — so redemption
/// looks up by hash. Reads are workspace-scoped except [getByCodeHash], which
/// is the pre-auth redemption lookup (the caller holds the code, which is the
/// proof).
abstract class WorkspaceInviteRepository {
  /// Invites created for [workspaceId], newest first.
  Future<List<WorkspaceInvite>> getForWorkspace(String workspaceId);

  /// Live stream of [workspaceId]'s invites.
  Stream<List<WorkspaceInvite>> watchForWorkspace(String workspaceId);

  /// The invite whose stored hash matches [codeHash], or null. Pre-auth
  /// lookup used during redemption; possession of the code is the proof, so
  /// this is deliberately not workspace-scoped.
  Future<WorkspaceInvite?> getByCodeHash(String codeHash);

  /// Inserts or updates [invite].
  Future<void> upsert(WorkspaceInvite invite);

  /// Deletes the invite [id] in [workspaceId].
  Future<void> delete(String workspaceId, String id);
}
