import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_calendar_accounts_workspaceId', columns: {#workspaceId})
@TableIndex(
  name: 'uq_calendar_accounts_ws_email',
  columns: {#workspaceId, #accountEmail},
  unique: true,
)
/// Drift table for a connected external calendar account.
///
/// A workspace may connect **several** accounts (still workspace-isolated): the
/// unique `(workspaceId, accountEmail)` index enforces one row per distinct
/// account within a workspace, so reconnecting the same account updates in
/// place while a different email adds another. OAuth secrets are NOT stored
/// here — they live in the platform secure store (see
/// `GoogleCredentialsRepository`); this row holds only non-secret metadata for
/// display and sync bookkeeping.
class CalendarAccountsTable extends Table {
  /// Unique account identifier (local UUID).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// Provider id (`google`).
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
  Set<Column> get primaryKey => {id};
}
