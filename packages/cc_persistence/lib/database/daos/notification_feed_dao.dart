import 'package:cc_persistence/database/tables/notification_feed_table.dart';
import 'package:cc_persistence/database/tables/notification_read_marks_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'notification_feed_dao.g.dart';

/// Data access for the workspace notification feed and its per-user read
/// marks. Every read and mutation filters by `workspaceId` (and `userId` for
/// marks) — an id-only query would leak across workspaces.
@DriftAccessor(tables: [NotificationFeedTable, NotificationReadMarksTable])
class NotificationFeedDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$NotificationFeedDaoMixin {
  /// Creates a [NotificationFeedDao].
  NotificationFeedDao(super.db);

  /// How many feed rows a workspace retains; older rows are pruned on insert.
  static const int retainedRows = 200;

  /// Watches the newest [limit] feed items, most-recent-first.
  Stream<List<NotificationFeedTableData>> watchRecent(
    String workspaceId, {
    int limit = 50,
  }) =>
      (select(notificationFeedTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Inserts one recorded frame, then prunes rows beyond [retainedRows]
  /// (oldest first) so the feed cannot grow without bound.
  Future<void> insertAndPrune(NotificationFeedTableCompanion entry) =>
      transaction(() async {
        await into(notificationFeedTable).insert(entry);
        await customStatement(
          'DELETE FROM notification_feed WHERE workspace_id = ?1 '
          'AND id NOT IN (SELECT id FROM notification_feed '
          'WHERE workspace_id = ?1 ORDER BY created_at DESC, id DESC '
          'LIMIT ?2)',
          [entry.workspaceId.value, retainedRows],
        );
      });

  /// Watches one user's read mark. Emits null until the first acknowledge.
  Stream<NotificationReadMarksTableData?> watchReadMark(
    String workspaceId,
    String userId,
  ) =>
      (select(notificationReadMarksTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
          ))
          .watchSingleOrNull();

  /// Stamps the last-seen watermark for a user (mark-all-read), preserving
  /// any existing cleared watermark.
  Future<void> markAllRead(
    String workspaceId,
    String userId,
    DateTime lastSeenAt,
  ) => into(notificationReadMarksTable).insert(
    NotificationReadMarksTableCompanion.insert(
      workspaceId: workspaceId,
      userId: userId,
      lastSeenAt: Value(lastSeenAt),
    ),
    onConflict: DoUpdate(
      (old) =>
          NotificationReadMarksTableCompanion(lastSeenAt: Value(lastSeenAt)),
    ),
  );

  /// Stamps [clearedBefore] (and the last-seen watermark, since clearing
  /// implies having seen) for a user.
  Future<void> clearAll(
    String workspaceId,
    String userId,
    DateTime clearedBefore,
  ) => into(notificationReadMarksTable).insert(
    NotificationReadMarksTableCompanion.insert(
      workspaceId: workspaceId,
      userId: userId,
      lastSeenAt: Value(clearedBefore),
      clearedBefore: Value(clearedBefore),
    ),
    onConflict: DoUpdate(
      (old) => NotificationReadMarksTableCompanion(
        lastSeenAt: Value(clearedBefore),
        clearedBefore: Value(clearedBefore),
      ),
    ),
  );
}
