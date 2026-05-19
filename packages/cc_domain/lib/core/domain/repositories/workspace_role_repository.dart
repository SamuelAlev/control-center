import 'package:cc_domain/core/domain/entities/role_definition.dart';

/// Persistence port for workspace-defined CUSTOM roles.
///
/// Every method is workspace-scoped — a role belongs to the workspace that
/// defined it, and `custom:<id>` values are only meaningful there.
abstract interface class WorkspaceRoleRepository {
  /// The custom roles defined in [workspaceId].
  Future<List<RoleDefinition>> forWorkspace(String workspaceId);

  /// Streams [forWorkspace].
  Stream<List<RoleDefinition>> watchForWorkspace(String workspaceId);

  /// One custom role by id, or null (a foreign id is simply not found).
  Future<RoleDefinition?> byId(String workspaceId, String id);

  /// Creates or updates a custom role.
  Future<void> upsert(String workspaceId, RoleDefinition role);

  /// Deletes a custom role. Callers reassign its members to the base preset
  /// first — a member left holding a `custom:<id>` that no longer resolves
  /// would fail safe to guest, which is safe but silently demoting.
  Future<void> delete(String workspaceId, String id);
}
