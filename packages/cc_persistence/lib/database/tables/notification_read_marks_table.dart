import 'package:drift/drift.dart';

/// Drift table for per-user read/cleared watermarks over the workspace's
/// notification feed (`notification_feed`).
///
/// One row per user per workspace file. An item is unread for a user when
/// `createdAt > lastSeenAt` and hidden when `createdAt <= clearedBefore`.
/// Both stamps are written with the server clock by the `notifications.*`
/// ops, keyed on the session's authenticated user — a client can only ever
/// touch its own row.
class NotificationReadMarksTable extends Table {
  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The user this mark belongs to.
  TextColumn get userId => text()();

  /// Everything created at or before this stamp has been seen. Null: the
  /// user has never opened the bell in this workspace.
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  /// Everything created at or before this stamp is hidden ("clear all").
  DateTimeColumn get clearedBefore => dateTime().nullable()();

  @override
  String get tableName => 'notification_read_marks';

  @override
  Set<Column> get primaryKey => {workspaceId, userId};
}
