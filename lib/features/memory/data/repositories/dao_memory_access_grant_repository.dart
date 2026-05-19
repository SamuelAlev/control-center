import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/database/daos/memory_access_grant_dao.dart';
import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/features/memory/data/mappers/memory_access_grant_mapper.dart';
import 'package:control_center/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:drift/drift.dart';

class DaoMemoryAccessGrantRepository implements MemoryAccessGrantRepository {
  DaoMemoryAccessGrantRepository(this._dao);

  final MemoryAccessGrantDao _dao;
  final MemoryAccessGrantMapper _mapper = const MemoryAccessGrantMapper();

  @override
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<void> upsert(MemoryAccessGrant grant) => _dao.upsert(
    db.MemoryAccessGrantsTableCompanion(
      workspaceId: Value(grant.workspaceId),
      agentRole: Value(grant.agentRole.name),
      memoryDomain: Value(grant.memoryDomain),
      permission: Value(grant.permission.name),
    ),
  );

  @override
  Future<void> upsertAll(List<MemoryAccessGrant> grants) => _dao.upsertAll(
    grants
        .map(
          (g) => db.MemoryAccessGrantsTableCompanion(
            workspaceId: Value(g.workspaceId),
            agentRole: Value(g.agentRole.name),
            memoryDomain: Value(g.memoryDomain),
            permission: Value(g.permission.name),
          ),
        )
        .toList(),
  );
}
