import 'package:cc_persistence/database/tables/notification_feed_table.dart';
import 'package:cc_persistence/database/tables/notification_item_states_table.dart';
import 'package:cc_persistence/database/tables/notification_read_marks_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'notification_feed_dao.g.dart';

/// Data access for the workspace notification feed, its per-user read marks
/// and the per-item state overrides. Every read and mutation filters by
/// `workspaceId` (and `userId` for marks/states) — an id-only query would leak
/// across workspaces.
@DriftAccessor(
  tables: [
    NotificationFeedTable,
    NotificationReadMarksTable,
    NotificationItemStatesTable,
  ],
)
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
  ///
  /// Per-item states are pruned with the rows they describe: a state whose
  /// feed item is gone can never be read again and would otherwise accumulate
  /// one row per user per notification, forever.
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
        await customStatement(
          'DELETE FROM notification_item_states WHERE workspace_id = ?1 '
          'AND item_id NOT IN '
          '(SELECT id FROM notification_feed WHERE workspace_id = ?1)',
          [entry.workspaceId.value],
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
  ///
  /// Read-only per-item states are dropped in the same transaction: a row is an
  /// OVERRIDE of the watermark, so an "explicitly unread" one would survive
  /// "mark all as read" and keep the bell badged. Rows carrying a dismissal
  /// survive — that is a hide, not a read opinion, and the watermark does not
  /// speak for it.
  Future<void> markAllRead(
    String workspaceId,
    String userId,
    DateTime lastSeenAt,
  ) => transaction(() async {
    await into(notificationReadMarksTable).insert(
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
    await (delete(notificationItemStatesTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.userId.equals(userId) &
              t.dismissedAt.isNull(),
        ))
        .go();
  });

  /// Stamps [clearedBefore] (and the last-seen watermark, since clearing
  /// implies having seen) for a user, and drops that user's per-item states.
  ///
  /// The states are dropped rather than kept because the watermark subsumes
  /// every one of them: a row saying "this item is read" cannot change the
  /// answer for an item the watermark already hides.
  Future<void> clearAll(
    String workspaceId,
    String userId,
    DateTime clearedBefore,
  ) => transaction(() async {
    await into(notificationReadMarksTable).insert(
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
    await (delete(notificationItemStatesTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
        ))
        .go();
  });

  /// Watches one user's per-item state overrides in this workspace.
  Stream<List<NotificationItemStatesTableData>> watchItemStates(
    String workspaceId,
    String userId,
  ) =>
      (select(notificationItemStatesTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
          ))
          .watch();

  /// Marks a single feed item read (or unread, when [readAt] is null) for a
  /// user, preserving any dismissal already recorded for that item.
  Future<void> setItemRead(
    String workspaceId,
    String userId,
    String itemId,
    DateTime? readAt,
  ) => into(notificationItemStatesTable).insert(
    NotificationItemStatesTableCompanion.insert(
      workspaceId: workspaceId,
      userId: userId,
      itemId: itemId,
      readAt: Value(readAt),
    ),
    onConflict: DoUpdate(
      (old) =>
          NotificationItemStatesTableCompanion(readAt: Value(readAt)),
    ),
  );

  /// Hides a single feed item for a user, stamping it read at the same time —
  /// deleting a notification you never opened must not leave the bell badged
  /// for a row that is no longer in the list.
  Future<void> dismissItem(
    String workspaceId,
    String userId,
    String itemId,
    DateTime at,
  ) => into(notificationItemStatesTable).insert(
    NotificationItemStatesTableCompanion.insert(
      workspaceId: workspaceId,
      userId: userId,
      itemId: itemId,
      readAt: Value(at),
      dismissedAt: Value(at),
    ),
    onConflict: DoUpdate(
      (old) => NotificationItemStatesTableCompanion(
        readAt: Value(at),
        dismissedAt: Value(at),
      ),
    ),
  );
}
