import 'package:cc_domain/features/governance/domain/entities/runtime_profile.dart';
import 'package:cc_domain/features/governance/domain/repositories/runtime_profile_repository.dart';
import 'package:cc_persistence/database/daos/runtime_profile_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/runtime_profile_mapper.dart';

/// Drift-backed [RuntimeProfileRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).runtimeProfileDao` per call: profiles live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoRuntimeProfileRepository implements RuntimeProfileRepository {
  /// Creates a [DaoRuntimeProfileRepository] over the per-workspace databases.
  DaoRuntimeProfileRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final RuntimeProfileMapper _mapper = const RuntimeProfileMapper();

  RuntimeProfileDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).runtimeProfileDao;

  @override
  Stream<List<RuntimeProfile>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<List<RuntimeProfile>> listByWorkspace(String workspaceId) async =>
      _mapper.toDomainList(await _dao(workspaceId).getByWorkspace(workspaceId));

  @override
  Future<RuntimeProfile?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(workspaceId, id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(RuntimeProfile profile) =>
      _dao(profile.workspaceId).upsert(_mapper.toCompanion(profile));

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id).then((_) {});
}
