import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/workspace_dao.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/repos/data/mappers/repo_mapper.dart';
import 'package:control_center/features/workspaces/data/mappers/workspace_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Drift DAO-backed implementation of [WorkspaceRepository].
class DaoWorkspaceRepository implements WorkspaceRepository {
  /// Creates a [DaoWorkspaceRepository] backed by a [WorkspaceDao].
  DaoWorkspaceRepository(this._dao);

  final WorkspaceDao _dao;
  static const _workspaceMapper = WorkspaceMapper();
  static const _repoMapper = RepoMapper();

  @override
  Stream<List<Workspace>> watchAll() =>
      _dao.watchAll().map(_workspaceMapper.toDomainList);

  @override
  Future<String> upsert(Workspace workspace) async {
    await _dao.upsertWorkspace(
      WorkspacesTableCompanion(
        id: drift.Value(workspace.id),
        name: drift.Value(workspace.name),
        logoPath: drift.Value(workspace.logoPath),

        createdAt: drift.Value(workspace.createdAt),
        updatedAt: drift.Value(workspace.updatedAt),
        reviewConcurrency: drift.Value(workspace.reviewConcurrency),
        deletedAt: drift.Value(workspace.deletedAt),
      ),
    );
    return workspace.id;
  }

  @override
  Future<void> delete(String id) => _dao.deleteWorkspace(id).then((_) {});

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      _dao.watchReposForWorkspace(workspaceId).map(_repoMapper.toDomainList);

  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      _dao.setReposForWorkspace(workspaceId, repoIds);

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      _dao.isRepoLinkedToWorkspace(workspaceId, repoId);

  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) =>
      _dao.linkRepoToWorkspace(workspaceId, repoId);

  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      _dao.unlinkRepoFromWorkspace(workspaceId, repoId);
}
