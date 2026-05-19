import 'package:control_center/features/memory/domain/entities/memory_domain.dart';

abstract class MemoryDomainRepository {
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId);
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId);
  Future<MemoryDomain?> findByName(String workspaceId, String name);
  Future<void> upsert(MemoryDomain domain);
}
