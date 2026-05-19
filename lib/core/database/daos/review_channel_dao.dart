import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/review_channels.dart';
import 'package:drift/drift.dart';

part 'review_channel_dao.g.dart';

/// Data access object for [ReviewChannelsTable].
@DriftAccessor(tables: [ReviewChannelsTable])
class ReviewChannelDao extends DatabaseAccessor<AppDatabase>
    with _$ReviewChannelDaoMixin {
  /// Creates a [ReviewChannelDao] for the given database.
  ReviewChannelDao(super.attachedDatabase);

  /// Watches the association for a specific PR by [prNodeId], scoped to
  /// [workspaceId].
  ///
  /// A PR node id is globally unique on GitHub, but the same upstream repo can
  /// be linked into multiple workspaces, so the lookup MUST be workspace-scoped
  /// to avoid surfacing another workspace's review channel.
  Stream<ReviewChannelsTableData?> watchByPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(reviewChannelsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watchSingleOrNull();

  /// Watches the association for a specific channel.
  Stream<ReviewChannelsTableData?> watchByChannel(String channelId) =>
      (select(reviewChannelsTable)
            ..where((t) => t.channelId.equals(channelId)))
          .watchSingleOrNull();

  /// Watches all associations for a workspace.
  Stream<List<ReviewChannelsTableData>> watchByWorkspace(String workspaceId) =>
      (select(reviewChannelsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Returns an association by [id] or null.
  Future<ReviewChannelsTableData?> getById(String id) =>
      (select(reviewChannelsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Inserts a new review channel association.
  Future<void> insertAssociation(ReviewChannelsTableCompanion entry) =>
      into(reviewChannelsTable).insert(entry);

  /// Updates the status of an association.
  Future<void> updateStatus(String id, String status) =>
      (update(reviewChannelsTable)..where((t) => t.id.equals(id))).write(
        ReviewChannelsTableCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes an association by [id].
  Future<void> deleteAssociation(String id) =>
      (delete(reviewChannelsTable)..where((t) => t.id.equals(id))).go();
}
