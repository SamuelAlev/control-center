import 'package:control_center/core/database/daos/project_dao.dart';
import 'package:control_center/features/ticketing/data/mappers/project_mapper.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/repositories/project_repository.dart';

/// Drift-backed [ProjectRepository].
class DaoProjectRepository implements ProjectRepository {
  /// Creates a [DaoProjectRepository].
  DaoProjectRepository(this._dao);

  final ProjectDao _dao;
  static const _mapper = ProjectMapper();

  @override
  Future<void> insert(Project project) =>
      _dao.insert(_mapper.toCompanion(project));

  @override
  Future<int> update(Project project) => _dao.updateById(
        project.id,
        project.workspaceId,
        _mapper.toCompanion(project),
      );

  @override
  Future<int> delete(String projectId, {required String workspaceId}) =>
      _dao.deleteProject(projectId, workspaceId);

  @override
  Future<Project?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<List<Project>> getForWorkspace(String workspaceId) async {
    final rows = await _dao.getForWorkspace(workspaceId);
    return rows.map(_mapper.fromRow).toList();
  }

  @override
  Stream<List<Project>> watchForWorkspace(String workspaceId) =>
      _dao.watchForWorkspace(workspaceId).map(
            (rows) => rows.map(_mapper.fromRow).toList(),
          );
}
