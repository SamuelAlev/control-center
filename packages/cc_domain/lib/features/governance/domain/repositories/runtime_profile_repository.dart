import 'package:cc_domain/features/governance/domain/entities/runtime_profile.dart';

/// Repository for custom runtime profiles. Every method is workspace-scoped —
/// `workspaceId` is required and never optional.
abstract interface class RuntimeProfileRepository {
  /// Watches all runtime profiles for [workspaceId].
  Stream<List<RuntimeProfile>> watchByWorkspace(String workspaceId);

  /// Returns all runtime profiles for [workspaceId].
  Future<List<RuntimeProfile>> listByWorkspace(String workspaceId);

  /// Returns a single profile by [id] within [workspaceId], or null.
  Future<RuntimeProfile?> getById(String workspaceId, String id);

  /// Inserts or updates a runtime profile.
  Future<void> upsert(RuntimeProfile profile);

  /// Deletes a profile by [id] within [workspaceId].
  Future<void> delete(String workspaceId, String id);
}
