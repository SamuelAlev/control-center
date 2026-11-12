import 'package:drift/drift.dart';

/// Drift table for per-user read/cleared watermarks over the workspace's
/// notification feed (`notification_feed`).
///
/// One row per user per workspace file. Each watermark is the position of the
/// newest feed item the user had in front of them, as the pair
/// `(created_at, rowid)`: an item is after it when it was created in a later
/// second, or in the same second with a larger rowid. `created_at` alone has
/// whole-second resolution, so an item recorded later in the second of a
/// "clear all" used to compare as covered by it and stayed hidden.
///
/// An item is unread for a user when it is after the last-seen mark and
/// hidden when it is not after the cleared mark. The marks are written by the
/// `notifications.*` ops, keyed on the session's authenticated user — a
/// client can only ever touch its own row.
class NotificationReadMarksTable extends Table {
  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The user this mark belongs to. No foreign key: `users` lives in
  /// `global.db`.
  TextColumn get userId => text()();

  /// `created_at` of the newest item seen. Null: the user has never opened
  /// the bell in this workspace.
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  /// `rowid` of the newest item seen (0 when the feed was empty).
  IntColumn get lastSeenSeq => integer().withDefault(const Constant(0))();

  /// `created_at` of the newest item hidden by "clear all". Null: nothing
  /// was cleared.
  DateTimeColumn get clearedBefore => dateTime().nullable()();

  /// `rowid` of the newest item hidden by "clear all" (0 when the feed was
  /// empty).
  IntColumn get clearedBeforeSeq => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'notification_read_marks';

  @override
  Set<Column> get primaryKey => {userId};
}
