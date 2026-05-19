import 'package:drift/drift.dart';

/// Drift table for PER-ITEM, per-user state over the workspace's notification
/// feed (`notification_feed`).
///
/// The watermarks in `notification_read_marks` answer "everything up to here"
/// cheaply, which is all a bell that acknowledges on open ever needed. They
/// cannot express "this one row is read" or "this one row is gone for me",
/// because a watermark is a single instant and the feed is ordered by time —
/// marking one item read would silently swallow every older unread item.
///
/// So the two live side by side: the watermark is the bulk answer and a row
/// here is a per-item OVERRIDE. An item is read for a user when the watermark
/// covers it OR it has a row here with a non-null [readAt]; it is hidden when
/// `clearedBefore` covers it OR its row here has a non-null [dismissedAt].
///
/// Rows are bounded by the feed's own retention: `insertAndPrune` drops states
/// whose feed item is gone, and "clear all" replaces them with a watermark.
/// The feed row itself is never deleted for a dismiss — it is shared by every
/// member of the workspace, so hiding is necessarily per user.
@TableIndex(
  name: 'idx_notification_item_states_user',
  columns: {#workspaceId, #userId},
)
class NotificationItemStatesTable extends Table {
  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The user this state belongs to.
  TextColumn get userId => text()();

  /// The `notification_feed` row this state overrides.
  TextColumn get itemId => text()();

  /// When the user marked this single item read. Null: no per-item opinion
  /// (the watermark still applies).
  DateTimeColumn get readAt => dateTime().nullable()();

  /// When the user deleted this single item from their own list. Null: not
  /// dismissed.
  DateTimeColumn get dismissedAt => dateTime().nullable()();

  @override
  String get tableName => 'notification_item_states';

  @override
  Set<Column> get primaryKey => {workspaceId, userId, itemId};
}
