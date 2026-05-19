import 'package:control_center/core/domain/entities/memory_policy.dart';

abstract class MemoryPolicyRepository {
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId);
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId);
  Future<MemoryPolicy?> getById(String id);
  Future<void> upsert(MemoryPolicy policy);
  Future<List<MemoryPolicy>> getActiveByWorkspace(String workspaceId, {String? domain});

  Future<void> delete(String id);
}
