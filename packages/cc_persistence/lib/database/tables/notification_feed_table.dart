import 'package:drift/drift.dart';

/// Drift table for the workspace's durable notification feed.
///
/// One row per recorded `notifications/*` frame: the raw wire [method] +
/// [paramsJson], stamped server-side at [createdAt]. Recorded once per domain
/// event by the server's `NotificationFeedRecorder` — never per connected
/// device, so a user with three clients still produces one row. Rendering
/// (localization + PRD 16 §7 principal routing) happens client-side from the
/// stored frame, so per-user relevance is applied at read time and rows stay
/// user-agnostic; the per-user state lives in `notification_read_marks`.
@TableIndex(
  name: 'idx_notification_feed_workspace_created',
  columns: {#workspaceId, #createdAt},
)
class NotificationFeedTable extends Table {
  /// Unique item identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The JSON-RPC notification method, e.g. `notifications/pr_merged`.
  TextColumn get method => text()();

  /// The frame's wire params as a JSON object string.
  TextColumn get paramsJson => text()();

  /// When the server recorded the item.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'notification_feed';

  @override
  Set<Column> get primaryKey => {id};
}
