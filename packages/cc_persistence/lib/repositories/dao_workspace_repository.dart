import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_persistence/database/daos/workspace_registry_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/repo_mapper.dart';
import 'package:cc_persistence/mappers/workspace_mapper.dart';
import 'package:drift/drift.dart' as drift;

/// Drift DAO-backed implementation of [WorkspaceRepository].
///
/// This repository straddles both halves of the split database on purpose and
/// it is the only one that does: the workspace *registry* is global (so the
/// switcher can list workspaces without opening any of them), while a
/// workspace's repos live inside that workspace's own file. Bridging the two
/// here keeps every caller's view simple — they ask a workspace question and get
/// an answer, without knowing which file it came from.
class DaoWorkspaceRepository implements WorkspaceRepository {
  /// Creates a [DaoWorkspaceRepository] over the global registry [_registry]
  /// and the per-workspace databases [_dbs].
  DaoWorkspaceRepository(this._registry, this._dbs);

  final WorkspaceRegistryDao _registry;
  final WorkspaceDatabaseManager _dbs;
  static const _workspaceMapper = WorkspaceMapper();
  static const _repoMapper = RepoMapper();

  @override
  Stream<List<Workspace>> watchAll() =>
      _registry.watchAll().map(_workspaceMapper.toDomainList);

  @override
  Future<List<Workspace>> getAll() =>
      _registry.getAll().then(_workspaceMapper.toDomainList);

  /// Returns a single workspace by [id], or null when it does not exist or has
  /// been soft-deleted. Used by server-side resolvers (e.g. the `/workspace/logo`
  /// endpoint) that need a single row without streaming the whole list.
  @override
  Future<Workspace?> getById(String id) async {
    final row = await _registry.getById(id);
    return row == null ? null : _workspaceMapper.toDomain(row);
  }

  @override
  Future<String> upsert(Workspace workspace) async {
    await _registry.upsertWorkspace(
      WorkspacesTableCompanion(
        id: drift.Value(workspace.id),
        name: drift.Value(workspace.name),
        logoPath: drift.Value(workspace.logoPath),
        ownerUserId: drift.Value(workspace.ownerUserId),
        secretExcludeGlobs: drift.Value(
          jsonEncode(workspace.secretExcludeGlobs),
        ),
        createdAt: drift.Value(workspace.createdAt),
        updatedAt: drift.Value(workspace.updatedAt),
        reviewConcurrency: drift.Value(workspace.reviewConcurrency),
        autoPublishReview: drift.Value(workspace.autoPublishReview),
        deletedAt: drift.Value(workspace.deletedAt),
      ),
    );
    // Materialise the workspace's database file so the schema exists before any
    // reader touches it. Without this, the first read of a brand-new workspace
    // would create the file as a side effect — harmless, but it would put schema
    // creation on an arbitrary caller's latency path.
    await _dbs.create(workspace.id);
    return workspace.id;
  }

  /// Soft-deletes the registry row AND drops the workspace's database file.
  ///
  /// This is the payoff of the split: deleting a workspace's data is unlinking
  /// one file, not cascading forty foreign keys through a database shared with
  /// every other workspace.
  @override
  Future<void> delete(String id) async {
    await _registry.deleteWorkspace(id);
    await _dbs.dropAndClose(id);
  }

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) =>
      _registry.reorderWorkspaces(orderedIds);

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      _dbs.of(workspaceId).repoDao.watchAll().map(_repoMapper.toDomainList);

  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      _dbs.of(workspaceId).repoDao.reorderRepos(repoIds);

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      _dbs.of(workspaceId).repoDao.exists(repoId);

  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      _dbs.of(workspaceId).repoDao.deleteRepo(repoId).then((_) {});
}
