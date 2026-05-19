import 'package:control_center/core/domain/entities/memory_access_grant.dart';

abstract class MemoryAccessGrantRepository {
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId);
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId);
  Future<void> upsert(MemoryAccessGrant grant);
  Future<void> upsertAll(List<MemoryAccessGrant> grants);
}
