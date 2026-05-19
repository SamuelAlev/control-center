import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/isolated_repo_dao.dart';
import 'package:control_center/core/domain/entities/isolated_repo.dart';
import 'package:control_center/core/domain/repositories/isolated_repo_repository.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:drift/drift.dart';

/// Drift-backed [IsolatedRepoRepository].
class DaoIsolatedRepoRepository implements IsolatedRepoRepository {
  /// Creates a [DaoIsolatedRepoRepository].
  DaoIsolatedRepoRepository(this._dao);

  final IsolatedRepoDao _dao;

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String channelId,
    String repoId,
  ) async {
    final row = await _dao.findForUnit(workspaceId, channelId, repoId);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<IsolatedRepo>> forChannel(
    String workspaceId,
    String channelId,
  ) async {
    final rows = await _dao.forChannel(workspaceId, channelId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final rows = await _dao.forTicket(workspaceId, ticketId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(
    String channelId,
  ) async {
    final rows = await _dao.findByChannelAcrossWorkspaces(channelId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async {
    final rows = await _dao.findByTicketAcrossWorkspaces(ticketId);
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) =>
      _dao.watchForWorkspace(workspaceId).map(
            (rows) => rows.map(_toEntity).toList(),
          );

  @override
  Future<void> upsert(IsolatedRepo repo) => _dao.upsert(
        IsolatedReposTableCompanion(
          id: Value(repo.id),
          workspaceId: Value(repo.workspaceId),
          channelId: Value(repo.channelId),
          repoId: Value(repo.repoId),
          path: Value(repo.path),
          branch: Value(repo.branch),
          backend: Value(repo.backend.name),
          sourcePath: Value(repo.sourcePath),
          ticketId: Value(repo.ticketId),
          createdAt: Value(repo.createdAt),
        ),
      );

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);

  IsolatedRepo _toEntity(IsolatedReposTableData row) => IsolatedRepo(
        id: row.id,
        workspaceId: row.workspaceId,
        channelId: row.channelId,
        repoId: row.repoId,
        path: row.path,
        branch: row.branch,
        backend: RepoIsolationBackend.fromName(row.backend),
        sourcePath: row.sourcePath,
        ticketId: row.ticketId,
        createdAt: row.createdAt,
      );
}
