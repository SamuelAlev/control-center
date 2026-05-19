import 'package:cc_persistence/database/tables/review_spaces.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'review_space_dao.g.dart';

/// Data access object for [ReviewSpacesTable].
@DriftAccessor(tables: [ReviewSpacesTable])
class ReviewSpaceDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ReviewSpaceDaoMixin {
  /// Creates a [ReviewSpaceDao] for the given database.
  ReviewSpaceDao(super.attachedDatabase);

  /// Watches the association for a specific PR by [prExternalId], scoped to
  /// [workspaceId].
  ///
  /// A PR node id is globally unique on GitHub, but the same upstream repo can
  /// be linked into multiple workspaces, so the lookup MUST be workspace-scoped
  /// to avoid surfacing another workspace's review space.
  Stream<ReviewSpacesTableData?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewSpacesTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watchSingleOrNull();

  /// Watches the most recent association for a specific space. A space can
  /// carry more than one PR association (multiple PRs, one or more repos), so
  /// this returns the latest and never throws — callers that need every
  /// association use [watchAllBySpace].
  Stream<ReviewSpacesTableData?> watchBySpace(String spaceId) =>
      (select(reviewSpacesTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .watchSingleOrNull();

  /// Watches every association for a space, workspace-scoped (isolation: a
  /// bare space id is not an ownership boundary). Newest first.
  Stream<List<ReviewSpacesTableData>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(reviewSpacesTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.spaceId.equals(spaceId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Watches all associations for a workspace.
  Stream<List<ReviewSpacesTableData>> watchByWorkspace(String workspaceId) =>
      (select(reviewSpacesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Returns an association by [id] or null.
  Future<ReviewSpacesTableData?> getById(String id) => (select(
    reviewSpacesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts a new review space association.
  Future<void> insertAssociation(ReviewSpacesTableCompanion entry) =>
      into(reviewSpacesTable).insert(entry);

  /// Updates the status of an association.
  Future<void> updateStatus(String id, String status) =>
      (update(reviewSpacesTable)..where((t) => t.id.equals(id))).write(
        ReviewSpacesTableCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes an association by [id].
  Future<void> deleteAssociation(String id) =>
      (delete(reviewSpacesTable)..where((t) => t.id.equals(id))).go();
}
