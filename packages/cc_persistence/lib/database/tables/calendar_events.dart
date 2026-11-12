import 'package:cc_persistence/database/tables/calendar_accounts.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'uq_calendar_events_account_external',
  columns: {#accountId, #externalEventId},
  unique: true,
)
// The range watch and the "starting soon" alert scan.
@TableIndex(name: 'idx_calendar_events_start', columns: {#startTime})
/// Drift table for events synced (read-only) from a connected calendar.
///
/// Workspace-scoped via [workspaceId]; idempotent on `(accountId,
/// externalEventId)` so re-syncs update in place rather than duplicating. Times
/// are stored as the provider supplied them (UTC for timed events; HOST-local
/// midnight for all-day, flagged by [isAllDay]). Timed events render with
/// `toLocal()`; all-day events cross the wire as bare `YYYY-MM-DD` civil dates
/// so the viewing device — not the host's timezone — decides the day.
class CalendarEventsTable extends Table {
  /// Local UUID identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The connected account this event was synced from.
  TextColumn get accountId => text().references(
    CalendarAccountsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The provider's event id (per-instance for expanded recurrences).
  TextColumn get externalEventId => text()();

  /// The provider calendar id this event belongs to. No foreign key: it is
  /// the provider's id, which `calendar_sources` carries per account.
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
  TextColumn get attendeesJson => text()
      .check(
        // ignore: recursive_getters
        isJsonArray(attendeesJson),
      )
      .withDefault(const Constant('[]'))();

  /// Resolved video-conference (Meet) URL, when present.
  TextColumn get meetingUrl => text().nullable()();

  /// Event status (`confirmed` / `tentative` / `cancelled`,
  /// `CalendarEventStatus.toStorage()`).
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(SpacesStoredValues.calendarEventStatus),
      )
      .withDefault(const Constant('confirmed'))();

  /// The master recurring-event id, when this is a recurrence instance.
  TextColumn get recurringEventId => text().nullable()();

  /// When a "starting soon" alert was fired for this event (dedup across
  /// restarts). Null until alerted; preserved across re-syncs.
  DateTimeColumn get alertedAt => dateTime().nullable()();

  /// When the row was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'calendar_events';

  @override
  Set<Column> get primaryKey => {id};
}
