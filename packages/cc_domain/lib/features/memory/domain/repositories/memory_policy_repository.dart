import 'package:cc_domain/core/domain/entities/memory_policy.dart';

/// Repository for [MemoryPolicy] persistence.
abstract class MemoryPolicyRepository {
  /// Watches all policies in a workspace.
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId);
  /// Fetches all policies in a workspace.
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId);

  /// Looks up a policy by id within [workspaceId]. A policy owned by another
  /// workspace is not found — ids are global UUIDs, so the workspace is the
  /// isolation boundary, not id uniqueness.
  Future<MemoryPolicy?> getById(String workspaceId, String id);
  /// Inserts or updates a policy.
  Future<void> upsert(MemoryPolicy policy);
  /// Fetches active policies for a workspace, optionally filtered by domain.
  Future<List<MemoryPolicy>> getActiveByWorkspace(String workspaceId, {String? domain});

  /// Deletes a policy by id within [workspaceId] so one workspace can never
  /// delete another's policy.
  Future<void> delete(String workspaceId, String id);
}
