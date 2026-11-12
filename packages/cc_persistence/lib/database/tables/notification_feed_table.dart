import 'package:cc_persistence/database/tables/checks/column_checks.dart';
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
///
/// Addressed by its implicit `rowid` as well as by [id]: read marks store the
/// rowid of the newest item seen, so the table keeps its text primary key and
/// is never `WITHOUT ROWID`.
// The feed page and the prune both walk the newest items first.
@TableIndex(name: 'idx_notification_feed_created', columns: {#createdAt})
// `NotificationFeedDao.resolveAgentWait` finds the row carrying a wait id
// without decoding every awaiting-input row's JSON. The UPDATE repeats the
// `json_valid` term so the planner can use it.
@TableIndex.sql(
  'CREATE INDEX idx_notification_feed_wait_id '
  "ON notification_feed (json_extract(params_json, '\$.wait_id')) "
  'WHERE json_valid(params_json)',
)
class NotificationFeedTable extends Table {
  /// Unique item identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The JSON-RPC notification method, e.g. `notifications/pr_merged`. Open
  /// set: every subsystem that publishes a notification names its own
  /// method, and the feed records whatever frame went out.
  TextColumn get method => text()();

  /// The frame's wire params as a JSON object string.
  TextColumn get paramsJson => text().check(
    // ignore: recursive_getters
    isJsonObject(paramsJson),
  )();

  /// When the server recorded the item.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'notification_feed';

  @override
  Set<Column> get primaryKey => {id};
}
