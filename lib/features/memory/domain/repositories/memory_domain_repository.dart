import 'package:control_center/features/memory/domain/entities/memory_domain.dart';

/// Repository for [MemoryDomain] persistence.
abstract class MemoryDomainRepository {
  /// Watches all domains in a workspace.
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId);
  /// Fetches all domains in a workspace.
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId);
  /// Finds a domain by its slug name within a workspace.
  Future<MemoryDomain?> findByName(String workspaceId, String name);
  /// Inserts or updates a domain.
  Future<void> upsert(MemoryDomain domain);
}
