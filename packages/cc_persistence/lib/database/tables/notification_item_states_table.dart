import 'package:cc_persistence/database/tables/notification_feed_table.dart';
import 'package:drift/drift.dart';

/// Drift table for PER-ITEM, per-user state over the workspace's notification feed
/// (`notification_feed`).
///
/// The watermarks in `notification_read_marks` answer "everything up to here" cheaply,
/// which is all a bell that acknowledges on open ever needed.
/// They cannot express "this one row is read" or "this one row is gone for me", because a
/// watermark is a single instant and the feed is ordered by time — marking one item read
/// would silently swallow every older unread item.
@TableIndex(name: 'idx_notification_item_states_item', columns: {#itemId})
class NotificationItemStatesTable extends Table {
  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The user this state belongs to. No foreign key: `users` lives in
  /// `global.db`.
  TextColumn get userId => text()();

  /// The `notification_feed` row this state overrides. `ON DELETE CASCADE`:
  /// a state outlives nothing once its item is pruned from the feed.
  TextColumn get itemId => text().references(
    NotificationFeedTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// When the user marked this single item read. Null: no per-item opinion
  /// (the watermark still applies).
  DateTimeColumn get readAt => dateTime().nullable()();

  /// When the user deleted this single item from their own list. Null: not
  /// dismissed.
  DateTimeColumn get dismissedAt => dateTime().nullable()();

  @override
  String get tableName => 'notification_item_states';

  @override
  Set<Column> get primaryKey => {userId, itemId};
}
