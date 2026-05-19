import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_persistence/database/daos/project_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/project_mapper.dart';

/// Drift-backed [ProjectRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).projectDao` per call: projects live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoProjectRepository implements ProjectRepository {
  /// Creates a [DaoProjectRepository] over the per-workspace databases.
  DaoProjectRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  static const _mapper = ProjectMapper();

  ProjectDao _dao(String workspaceId) => _dbs.of(workspaceId).projectDao;

  @override
  Future<void> insert(Project project) =>
      _dao(project.workspaceId).insert(_mapper.toCompanion(project));

  @override
  Future<int> update(Project project) => _dao(
    project.workspaceId,
  ).updateById(project.id, project.workspaceId, _mapper.toCompanion(project));

  @override
  Future<int> delete(String projectId, {required String workspaceId}) =>
      _dao(workspaceId).deleteProject(projectId, workspaceId);

  @override
  Future<Project?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id);
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<List<Project>> getForWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).getForWorkspace(workspaceId);
    return rows.map(_mapper.fromRow).toList();
  }

  @override
  Stream<List<Project>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchForWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.fromRow).toList());
}
