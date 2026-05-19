import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_persistence/database/daos/memory_domain_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/memory_domain_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory domains.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).memoryDomainDao` per call: domains live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoMemoryDomainRepository implements MemoryDomainRepository {
  /// Creates a [DaoMemoryDomainRepository] over the per-workspace databases.
  DaoMemoryDomainRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final MemoryDomainMapper _mapper = const MemoryDomainMapper();

  MemoryDomainDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).memoryDomainDao;

  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<MemoryDomain?> findByName(String workspaceId, String name) =>
      _dao(workspaceId)
          .findByName(workspaceId, name)
          .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(MemoryDomain domain) => _dao(domain.workspaceId).upsert(
    db.MemoryDomainsTableCompanion(
      id: Value(domain.id),
      workspaceId: Value(domain.workspaceId),
      name: Value(domain.name),
      label: Value(domain.label),
      description: Value.absentIfNull(domain.description),
      createdAt: Value(domain.createdAt),
      createdByRole: Value(domain.createdByRole),
    ),
  );
}
