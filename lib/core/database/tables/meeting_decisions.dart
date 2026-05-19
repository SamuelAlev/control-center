import 'package:control_center/core/database/tables/meetings.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_meeting_decisions_meetingId', columns: {#meetingId})
@TableIndex(name: 'idx_meeting_decisions_workspaceId', columns: {#workspaceId})
/// Drift table for decisions extracted from a meeting summary.
///
/// Persisted as structured rows — NOT parsed out of the notes markdown. The
/// `meeting_summary` pipeline's deterministic `meeting.addDecisions` step writes
/// one row per decision the agent returned in its structured output. Workspace-
/// scoped via [workspaceId] in addition to the [meetingId] foreign key.
class MeetingDecisionsTable extends Table {
  /// Unique decision identifier.
  TextColumn get id => text()();

  /// Parent meeting.
  TextColumn get meetingId =>
      text().references(MeetingsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace (denormalized for workspace-scoped reads).
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// The decision text.
  TextColumn get content => text()();

  /// Ordering within the meeting (the agent's original ordering).
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// When the row was created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
