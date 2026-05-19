import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/repo_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Drift DAO-backed implementation of [RepoRepository].
///
/// Holds the [WorkspaceDatabaseManager] rather than a DAO, and resolves
/// `_dbs.of(workspaceId).repoDao` per call: repos live in their workspace's own
/// database file, so the workspace id picks the file before any SQL runs.
class DaoRepoRepository implements RepoRepository {
  /// Creates a [DaoRepoRepository] over the per-workspace databases.
  DaoRepoRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  static const _mapper = RepoMapper();

  @override
  Stream<List<Repo>> watchAll(String workspaceId) =>
      _dbs.of(workspaceId).repoDao.watchAll().map(_mapper.toDomainList);

  @override
  Future<List<Repo>> getAll(String workspaceId) =>
      _dbs.of(workspaceId).repoDao.getAll().then(_mapper.toDomainList);

  @override
  Future<Repo?> getById(String workspaceId, String repoId) => _dbs
      .of(workspaceId)
      .repoDao
      .getById(repoId)
      .then((row) => row == null ? null : _mapper.toDomain(row));

  @override
  Future<Repo?> findByPath(String workspaceId, String path) => _dbs
      .of(workspaceId)
      .repoDao
      .getByPath(path)
      .then((row) => row == null ? null : _mapper.toDomain(row));

  @override
  Future<bool> exists(String workspaceId, String repoId) =>
      _dbs.of(workspaceId).repoDao.exists(repoId);

  @override
  Future<String> upsert(String workspaceId, Repo repo) async {
    await _dbs
        .of(workspaceId)
        .repoDao
        .upsertRepo(
          ReposTableCompanion(
            id: drift.Value(repo.id),
            name: drift.Value(repo.name),
            path: drift.Value(repo.path),
            githubOwner: drift.Value(repo.githubOwner),
            githubRepoName: drift.Value(repo.githubRepoName),
            createdAt: drift.Value(repo.createdAt),
            updatedAt: drift.Value(repo.updatedAt),
          ),
        );
    return repo.id;
  }

  @override
  Future<void> delete(String workspaceId, String repoId) =>
      _dbs.of(workspaceId).repoDao.deleteRepo(repoId).then((_) {});

  @override
  Future<void> reorder(String workspaceId, List<String> orderedIds) =>
      _dbs.of(workspaceId).repoDao.reorderRepos(orderedIds);
}
