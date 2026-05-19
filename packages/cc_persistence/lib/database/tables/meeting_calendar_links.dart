import 'package:cc_persistence/database/tables/calendar_events.dart';
import 'package:cc_persistence/database/tables/meetings.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'uq_meeting_calendar_links_meetingId',
  columns: {#meetingId},
  unique: true,
)
@TableIndex(
  name: 'idx_meeting_calendar_links_workspaceId',
  columns: {#workspaceId},
)
@TableIndex(
  name: 'idx_meeting_calendar_links_eventId',
  columns: {#calendarEventId},
)
/// Drift join table linking a recorded [MeetingsTable] row to the
/// [CalendarEventsTable] event it was recorded for (1:1 per meeting).
///
/// Kept separate from the meeting and event so neither has to know about the
/// other — a `Meeting` stays a pure recording artifact and a `CalendarEvent`
/// stays a pure synced commitment. Workspace-scoped via [workspaceId].
class MeetingCalendarLinksTable extends Table {
  /// Unique link identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// The recorded meeting.
  TextColumn get meetingId =>
      text().references(MeetingsTable, #id, onDelete: KeyAction.cascade)();

  /// The source calendar event.
  TextColumn get calendarEventId => text()
      .references(CalendarEventsTable, #id, onDelete: KeyAction.cascade)();

  /// When the link was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
