import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/isolated_repo_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [IsolatedRepoRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).isolatedRepoDao` per call: a worktree belongs to a
/// channel in one workspace, so the workspace id picks the file before any SQL
/// runs. The two teardown lookups are the exception — see their doc comments.
class DaoIsolatedRepoRepository implements IsolatedRepoRepository {
  /// Creates a [DaoIsolatedRepoRepository] over the per-workspace databases.
  DaoIsolatedRepoRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;

  IsolatedRepoDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).isolatedRepoDao;

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String channelId,
    String repoId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).findForUnit(workspaceId, channelId, repoId);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<IsolatedRepo>> forChannel(
    String workspaceId,
    String channelId,
  ) async {
    final rows = await _dao(workspaceId).forChannel(workspaceId, channelId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final rows = await _dao(workspaceId).forTicket(workspaceId, ticketId);
    return rows.map(_toEntity).toList();
  }

  /// CROSS-WORKSPACE BY DESIGN: worktree teardown by a globally-unique channel
  /// id, called when the channel — and with it the workspace context — has
  /// already been deleted, so there is no workspace id left to scope by. Each
  /// returned row still carries its own `workspaceId`, which is what the GC use
  /// case validates and what [deleteById] then needs. Prefer [forChannel]
  /// whenever the workspace is still known.
  @override
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(
    String channelId,
  ) async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.isolatedRepoDao.findByChannelAcrossWorkspaces(channelId),
    );
    return [
      for (final rows in perWorkspace)
        for (final row in rows) _toEntity(row),
    ];
  }

  /// CROSS-WORKSPACE BY DESIGN: worktree teardown by ticket id. Ticket
  /// lifecycle events (`TicketCompleted`/`TicketCancelled`) carry only a ticket
  /// id, so the owning workspace has to be discovered. Each returned row still
  /// carries its own `workspaceId`. Prefer [forTicket] when the workspace is
  /// known.
  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.isolatedRepoDao.findByTicketAcrossWorkspaces(ticketId),
    );
    return [
      for (final rows in perWorkspace)
        for (final row in rows) _toEntity(row),
    ];
  }

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) => _dao(
    workspaceId,
  ).watchForWorkspace(workspaceId).map((rows) => rows.map(_toEntity).toList());

  @override
  Future<void> upsert(IsolatedRepo repo) =>
      // The worktree names its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(repo.workspaceId).upsert(
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
  Future<void> deleteById(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(id);

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
