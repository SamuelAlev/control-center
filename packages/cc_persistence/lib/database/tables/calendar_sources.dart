import 'package:cc_persistence/database/tables/calendar_accounts.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_calendar_sources_workspaceId',
  columns: {#workspaceId},
)
@TableIndex(
  name: 'uq_calendar_sources_account_cal',
  columns: {#accountId, #calendarId},
  unique: true,
)
/// Drift table for a synced calendar source — one of a connected account's
/// calendars (the user's primary calendar, a shared "Team" calendar, a
/// "Holidays" subscription, …), i.e. one row of the sidebar's per-account
/// calendar list.
///
/// Workspace-scoped via [workspaceId] and account-scoped via [accountId]
/// (cascading when the account is deleted); idempotent on
/// `(accountId, calendarId)` so re-syncs replace in place. Persisted read-only
/// by the sync sweep (which holds the OAuth tokens host-side); read by thin
/// clients over the `calendar.watchSources` RPC. No event data lives here —
/// only the per-calendar display metadata.
class CalendarSourcesTable extends Table {
  /// Surrogate UUID identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// The connected account this calendar belongs to.
  TextColumn get accountId => text()
      .references(CalendarAccountsTable, #id, onDelete: KeyAction.cascade)();

  /// The provider calendar id (`primary` for the account's main calendar).
  TextColumn get calendarId => text()();

  /// Display name.
  TextColumn get summary => text()();

  /// The calendar's accent color as a `#rrggbb` hex string, when provided.
  TextColumn get backgroundColor => text().nullable()();

  /// Whether this is the account's primary calendar.
  BoolColumn get primary => boolean().withDefault(const Constant(false))();

  /// Whether the user can write to it (owner/writer access role).
  BoolColumn get writable => boolean().withDefault(const Constant(false))();

  /// When the row was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
