import 'package:cc_persistence/database/tables/space_stack_entries.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'space_stack_dao.g.dart';

/// Data access for [SpaceStackEntriesTable].
@DriftAccessor(tables: [SpaceStackEntriesTable])
class SpaceStackDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$SpaceStackDaoMixin {
  /// Creates a [SpaceStackDao] bound to the given database.
  SpaceStackDao(super.attachedDatabase);

  /// Every layer in [spaceId], repo then position.
  Future<List<SpaceStackEntriesTableData>> forSpace(
    String workspaceId,
    String spaceId,
  ) {
    return (select(spaceStackEntriesTable)
          ..where(
            (t) => t.workspaceId.equals(workspaceId) & t.spaceId.equals(spaceId),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.repoId),
            (t) => OrderingTerm.asc(t.position),
          ]))
        .get();
  }

  /// One repo's layers, bottom to top.
  Future<List<SpaceStackEntriesTableData>> forRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) {
    return (select(spaceStackEntriesTable)
          ..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.repoId.equals(repoId),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  /// Inserts or replaces [entry].
  Future<void> upsert(SpaceStackEntriesTableCompanion entry) =>
      into(spaceStackEntriesTable).insertOnConflictUpdate(entry);

  /// Deletes every layer of one repo.
  Future<void> deleteForRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) {
    return (delete(spaceStackEntriesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.spaceId.equals(spaceId) &
              t.repoId.equals(repoId),
        ))
        .go();
  }

  /// Deletes the row [id] inside [workspaceId].
  Future<void> deleteById(String workspaceId, String id) {
    return (delete(spaceStackEntriesTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.id.equals(id),
        ))
        .go();
  }
}
