import 'package:control_center/core/database/tables/calendar_accounts.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'uq_calendar_events_account_external',
  columns: {#accountId, #externalEventId},
  unique: true,
)
@TableIndex(
  name: 'idx_calendar_events_ws_start',
  columns: {#workspaceId, #startTime},
)
/// Drift table for events synced (read-only) from a connected calendar.
///
/// Workspace-scoped via [workspaceId]; idempotent on `(accountId,
/// externalEventId)` so re-syncs update in place rather than duplicating. Times
/// are stored as the provider supplied them (UTC for timed events; local
/// midnight for all-day, flagged by [isAllDay]); render with `toLocal()`.
class CalendarEventsTable extends Table {
  /// Local UUID identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// The connected account this event was synced from.
  TextColumn get accountId => text()
      .references(CalendarAccountsTable, #id, onDelete: KeyAction.cascade)();

  /// The provider's event id (per-instance for expanded recurrences).
  TextColumn get externalEventId => text()();

  /// The provider calendar id this event belongs to.
  TextColumn get calendarId => text()();

  /// Event title.
  TextColumn get title => text()();

  /// Optional description.
  TextColumn get description => text().nullable()();

  /// Optional location.
  TextColumn get location => text().nullable()();

  /// Event start (UTC for timed; local midnight for all-day).
  DateTimeColumn get startTime => dateTime()();

  /// Event end.
  DateTimeColumn get endTime => dateTime()();

  /// Whether this is an all-day (date-only) event.
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();

  /// Attendees as a JSON array (low query value, stored as a blob).
  TextColumn get attendeesJson => text().withDefault(const Constant('[]'))();

  /// Resolved video-conference (Meet) URL, when present.
  TextColumn get meetingUrl => text().nullable()();

  /// Event status (`confirmed` / `tentative` / `cancelled`).
  TextColumn get status => text().withDefault(const Constant('confirmed'))();

  /// The master recurring-event id, when this is a recurrence instance.
  TextColumn get recurringEventId => text().nullable()();

  /// When a "starting soon" alert was fired for this event (dedup across
  /// restarts). Null until alerted; preserved across re-syncs.
  DateTimeColumn get alertedAt => dateTime().nullable()();

  /// When the row was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
