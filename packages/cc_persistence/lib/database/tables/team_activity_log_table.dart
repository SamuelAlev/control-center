import 'package:drift/drift.dart';

/// Records each team-leader evaluation of a routed request — both an audit
/// trail and the dedup substrate for the leader re-trigger loop.
@TableIndex(
  name: 'idx_team_activity_workspace_team',
  columns: {#workspaceId, #teamId},
)
@TableIndex(name: 'idx_team_activity_ticket', columns: {#ticketId})
class TeamActivityLogTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The team whose leader recorded this evaluation.
  TextColumn get teamId => text()();

  /// The ticket the evaluation is about.
  TextColumn get ticketId => text()();

  /// The recorded outcome: `action` | `no_action` | `failed`.
  TextColumn get kind => text()();

  /// The leader agent that recorded it, if known.
  TextColumn get leaderId => text().nullable()();

  /// The member delegated to, for an `action` outcome, if any.
  TextColumn get memberId => text().nullable()();

  /// Short human-readable note about the decision.
  TextColumn get summary => text().nullable()();

  /// When the evaluation was recorded.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
