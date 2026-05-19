import 'package:cc_domain/features/skills/domain/entities/skill_source.dart';
import 'package:cc_domain/features/skills/domain/repositories/skill_source_repository.dart';
import 'package:cc_persistence/database/daos/skill_source_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [SkillSourceRepository]. Sources live in their workspace's own
/// database file, so the `workspaceId` every method takes picks the file
/// before any SQL runs — a foreign workspace's source is simply not found.
class DaoSkillSourceRepository implements SkillSourceRepository {
  /// Creates a [DaoSkillSourceRepository] over the per-workspace databases.
  DaoSkillSourceRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  // Resolved per call, never cached in a field: a cached DAO pins the first
  // workspace it served and answers every later caller from that workspace's
  // file (the one leak the database split exists to make impossible).
  SkillSourceDao _dao(String workspaceId) => _dbs.of(workspaceId).skillSourceDao;

  @override
  Future<List<SkillSource>> list(String workspaceId) async {
    final rows = await _dao(workspaceId).list(workspaceId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<SkillSource?> byId(String workspaceId, String sourceId) async {
    final row = await _dao(workspaceId).byId(workspaceId, sourceId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<SkillSource?> byOwnerRepo(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    final row = await _dao(workspaceId).byOwnerRepo(workspaceId, owner, repo);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<SkillSource> add(String workspaceId, SkillSource source) async {
    await _dao(workspaceId).upsert(_companion(source));
    final stored = await byOwnerRepo(workspaceId, source.owner, source.repo);
    return stored ?? source;
  }

  @override
  Future<void> update(String workspaceId, SkillSource source) =>
      _dao(workspaceId).upsert(_companion(source));

  @override
  Future<void> remove(String workspaceId, String sourceId) =>
      _dao(workspaceId).deleteSource(workspaceId, sourceId);

  static SkillSourcesTableCompanion _companion(SkillSource s) =>
      SkillSourcesTableCompanion(
        id: Value(s.id),
        workspaceId: Value(s.workspaceId),
        owner: Value(s.owner),
        repo: Value(s.repo),
        url: Value(s.url),
        description: Value(s.description),
        defaultBranch: Value(s.defaultBranch),
        starCount: Value(s.starCount),
        skillCount: Value(s.skillCount),
        lastSyncedAt: Value(s.lastSyncedAt),
        lastError: Value(s.lastError),
        createdAt: Value(s.createdAt),
      );

  static SkillSource _fromRow(SkillSourcesTableData r) => SkillSource(
    id: r.id,
    workspaceId: r.workspaceId,
    owner: r.owner,
    repo: r.repo,
    url: r.url,
    description: r.description,
    defaultBranch: r.defaultBranch,
    starCount: r.starCount,
    skillCount: r.skillCount,
    lastSyncedAt: r.lastSyncedAt,
    lastError: r.lastError,
    createdAt: r.createdAt,
  );
}
