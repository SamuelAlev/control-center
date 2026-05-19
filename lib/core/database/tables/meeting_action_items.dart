import 'package:control_center/core/database/tables/meetings.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_meeting_action_items_meetingId', columns: {#meetingId})
@TableIndex(
  name: 'idx_meeting_action_items_workspaceId',
  columns: {#workspaceId},
)
/// Drift table for action items extracted from a meeting summary.
///
/// Persisted as structured rows — NOT parsed out of the notes markdown. The
/// `meeting_summary` pipeline's deterministic `meeting.addActionItems` step
/// writes one row per action item the agent returned in its structured output.
/// Workspace-scoped via [workspaceId] in addition to the [meetingId] foreign
/// key (an action item from one workspace must never surface in another).
class MeetingActionItemsTable extends Table {
  /// Unique action-item identifier.
  TextColumn get id => text()();

  /// Parent meeting.
  TextColumn get meetingId =>
      text().references(MeetingsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace (denormalized for workspace-scoped reads).
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// The action-item text.
  TextColumn get content => text()();

  /// Optional owner / assignee, when the agent attributed one.
  TextColumn get owner => text().nullable()();

  /// Whether the user has checked the item off (persisted triage state).
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  /// The id / key of a ticket created from this item, when one exists.
  TextColumn get ticketId => text().nullable()();

  /// Ordering within the meeting (the agent's original ordering).
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// When the row was created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
