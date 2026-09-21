import 'package:drift/drift.dart';

/// Drift table for PER-ITEM, per-user state over the workspace's notification feed
/// (`notification_feed`).
///
/// The watermarks in `notification_read_marks` answer "everything up to here" cheaply,
/// which is all a bell that acknowledges on open ever needed.
/// They cannot express "this one row is read" or "this one row is gone for me", because a
/// watermark is a single instant and the feed is ordered by time — marking one item read
/// would silently swallow every older unread item.
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
