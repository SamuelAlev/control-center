import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/database/daos/memory_domain_dao.dart';
import 'package:control_center/features/memory/data/mappers/memory_domain_mapper.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:drift/drift.dart';

class DaoMemoryDomainRepository implements MemoryDomainRepository {
  DaoMemoryDomainRepository(this._dao);

  final MemoryDomainDao _dao;
  final MemoryDomainMapper _mapper = const MemoryDomainMapper();

  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<MemoryDomain?> findByName(String workspaceId, String name) =>
      _dao.findByName(workspaceId, name).then(
        (row) => row != null ? _mapper.toDomain(row) : null,
      );

  @override
  Future<void> upsert(MemoryDomain domain) => _dao.upsert(
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
