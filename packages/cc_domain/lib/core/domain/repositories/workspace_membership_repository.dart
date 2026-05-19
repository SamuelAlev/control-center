import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// Persistence port for workspace membership, roles, and per-repo grants.
///
/// Membership is the workspace access boundary: "may this user see this
/// workspace at all" and "what may they do in it" both resolve here. Every
/// read is workspace- or user-scoped; there is no unscoped listing.
abstract class WorkspaceMembershipRepository {
  /// Members of [workspaceId], oldest first.
  Future<List<WorkspaceMember>> getForWorkspace(String workspaceId);

  /// Live stream of [workspaceId]'s members.
  Stream<List<WorkspaceMember>> watchForWorkspace(String workspaceId);

  /// The membership of [userId] in [workspaceId], or null when not a member.
  Future<WorkspaceMember?> getMember(String workspaceId, String userId);

  /// All memberships of [userId] across workspaces (drives the picker:
  /// a user sees only workspaces they belong to).
  Future<List<WorkspaceMember>> getForUser(String userId);

  /// Adds or updates a membership row.
  Future<void> upsert(WorkspaceMember member);

  /// Changes [userId]'s role in [workspaceId].
  Future<void> setRole(String workspaceId, String userId, WorkspaceRole role);

  /// Removes [userId] from [workspaceId] (their repo grants go with them).
  Future<void> remove(String workspaceId, String userId);

  /// Per-repo grants of [userId] in [workspaceId] (repos absent from the map
  /// are ungranted).
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  );

  /// Sets [userId]'s grant on [repoId] in [workspaceId]. A level of
  /// [RepoGrantLevel.none] removes the row.
  Future<void> setRepoGrant(
    String workspaceId,
    String userId,
    String repoId,
    RepoGrantLevel level,
  );
}
