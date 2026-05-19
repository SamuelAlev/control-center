import 'package:control_center/core/domain/entities/memory_access_grant.dart';

/// Repository for access-grant entries that control which roles may read or
/// write specific memory domains.
abstract class MemoryAccessGrantRepository {
  /// Fetches all access grants for a workspace.
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId);
  /// Watches all access grants for a workspace.
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId);
  /// Inserts or updates a single access grant.
  Future<void> upsert(MemoryAccessGrant grant);
  /// Inserts or updates multiple access grants in a batch.
  Future<void> upsertAll(List<MemoryAccessGrant> grants);
}
