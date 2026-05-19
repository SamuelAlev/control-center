import 'package:cc_persistence/database/tables/skill_sources_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'skill_source_dao.g.dart';

/// Data access for registered skill sources. Every read filters by
/// `workspaceId` (workspace isolation invariant).
@DriftAccessor(tables: [SkillSourcesTable])
class SkillSourceDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$SkillSourceDaoMixin {
  /// Creates a [SkillSourceDao].
  SkillSourceDao(super.db);

  /// The workspace's sources, newest first.
  Future<List<SkillSourcesTableData>> list(String workspaceId) =>
      (select(skillSourcesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// The source with [id] in [workspaceId], or null.
  Future<SkillSourcesTableData?> byId(String workspaceId, String id) =>
      (select(skillSourcesTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.id.equals(id),
            ))
          .getSingleOrNull();

  /// The source for [owner]/[repo] in [workspaceId], or null (dedupe probe).
  Future<SkillSourcesTableData?> byOwnerRepo(
    String workspaceId,
    String owner,
    String repo,
  ) =>
      (select(skillSourcesTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.owner.equals(owner) &
                  t.repo.equals(repo),
            ))
          .getSingleOrNull();

  /// Inserts or replaces a source row (PK upsert).
  Future<void> upsert(SkillSourcesTableCompanion entry) =>
      into(skillSourcesTable).insertOnConflictUpdate(entry);

  /// Deletes the source row.
  Future<void> deleteSource(String workspaceId, String id) =>
      (delete(skillSourcesTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.id.equals(id),
            ))
          .go();
}
