import 'package:drift/drift.dart';

/// Drift table for a connected external calendar account.
///
/// A workspace may connect **several** accounts (still workspace-isolated): the
/// unique `(userId, accountEmail)` index enforces one row per distinct account
/// for one member within the workspace this file holds, so reconnecting the
/// same account updates in place (one `INSERT … ON CONFLICT` on it) while a
/// different email adds another. OAuth secrets
/// are NOT stored here — they live in the platform secure store (see
/// `GoogleCredentialsRepository`); this row holds only non-secret metadata for
/// display and sync bookkeeping.
@TableIndex(
  name: 'uq_calendar_accounts_user_email',
  columns: {#userId, #accountEmail},
  unique: true,
)
class CalendarAccountsTable extends Table {
  /// Unique account identifier (local UUID).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The member who connected this account. Empty when no member owns it.
  /// No foreign key: `users` lives in `global.db`.
  TextColumn get userId => text().withDefault(const Constant(''))();

  /// Provider id (`google`). Open set: names the calendar adapter that
  /// synced the account.
  TextColumn get providerId => text().withDefault(const Constant('google'))();

  /// The connected account's email.
  TextColumn get accountEmail => text()();

  /// Optional display name.
  TextColumn get displayName => text().nullable()();

  /// When events were last synced for this account.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// When this account's OAuth refresh token was found to be dead
  /// (Google `invalid_grant`) and the user must re-consent. Null while the
  /// account is healthy; set when a refresh fails terminally and cleared on the
  /// next successful sync or on reconnect. Drives the in-app "reconnect" banner.
  DateTimeColumn get authExpiredAt => dateTime().nullable()();

  /// When the row was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the row was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'calendar_accounts';

  @override
  Set<Column> get primaryKey => {id};
}
