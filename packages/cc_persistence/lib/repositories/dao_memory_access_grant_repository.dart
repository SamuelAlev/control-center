import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_persistence/database/daos/memory_access_grant_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/memory_access_grant_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory access grants.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).memoryAccessGrantDao` per call: grants live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoMemoryAccessGrantRepository implements MemoryAccessGrantRepository {
  /// Creates a [DaoMemoryAccessGrantRepository] over the per-workspace
  /// databases.
  DaoMemoryAccessGrantRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final MemoryAccessGrantMapper _mapper = const MemoryAccessGrantMapper();

  MemoryAccessGrantDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).memoryAccessGrantDao;

  @override
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<void> upsert(MemoryAccessGrant grant) =>
      _dao(grant.workspaceId).upsert(_companion(grant));

  /// Writes each grant into the file of the workspace it names.
  ///
  /// The list is grouped rather than assumed homogeneous: the seeding path
  /// builds grants for one workspace, but a caller mixing two would otherwise
  /// silently write both into whichever file the first grant picked.
  @override
  Future<void> upsertAll(List<MemoryAccessGrant> grants) async {
    final byWorkspace = <String, List<db.MemoryAccessGrantsTableCompanion>>{};
    for (final grant in grants) {
      byWorkspace
          .putIfAbsent(grant.workspaceId, () => [])
          .add(_companion(grant));
    }
    for (final entry in byWorkspace.entries) {
      await _dao(entry.key).upsertAll(entry.value);
    }
  }

  db.MemoryAccessGrantsTableCompanion _companion(MemoryAccessGrant grant) =>
      db.MemoryAccessGrantsTableCompanion(
        workspaceId: Value(grant.workspaceId),
        agentRole: Value(grant.agentRole.name),
        memoryDomain: Value(grant.memoryDomain),
        permission: Value(grant.permission.name),
      );
}
