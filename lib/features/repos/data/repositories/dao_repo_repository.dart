import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/repo_dao.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/repositories/repo_repository.dart';
import 'package:control_center/features/repos/data/mappers/repo_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Drift DAO-backed implementation of [RepoRepository].
class DaoRepoRepository implements RepoRepository {
  /// Creates a [DaoRepoRepository] backed by a [RepoDao].
  DaoRepoRepository(this._dao);

  final RepoDao _dao;
  static const _mapper = RepoMapper();

  @override
  Stream<List<Repo>> watchAll() => _dao.watchAll().map(_mapper.toDomainList);

  @override
  Future<Repo?> getById(String id) => _dao
      .getById(id)
      .then((row) => row == null ? null : _mapper.toDomain(row));

  @override
  Future<String> upsert(Repo repo) async {
    await _dao.upsertRepo(
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
  Future<void> delete(String id) => _dao.deleteRepo(id).then((_) {});
}
