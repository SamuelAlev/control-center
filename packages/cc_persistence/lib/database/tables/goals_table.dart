import 'package:drift/drift.dart';

/// Drift table for the organizational goal hierarchy
/// (company → team → agent → task).
///
/// Goals cascade from a company mission down to the tasks an individual agent
/// works on, so any agent can see how its work serves the bigger picture. A
/// goal's [parentGoalId] forms a strict tree; progress aggregates upward from
/// task completion. Workspace-scoped: every read filters by [workspaceId].
@TableIndex(name: 'idx_goals_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_goals_parent', columns: {#parentGoalId})
class GoalsTable extends Table {
  /// Unique goal identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Parent goal in the hierarchy, or null for the company mission (the root).
  TextColumn get parentGoalId => text().nullable()();

  /// Hierarchy level: `company`, `team`, `agent`, or `task`.
  TextColumn get level => text().withDefault(const Constant('company'))();

  /// Short goal title.
  TextColumn get title => text()();

  /// Optional longer description of the objective.
  TextColumn get description => text().nullable()();

  /// Lifecycle status: `active`, `achieved`, or `abandoned`.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Agent that owns this goal (for agent/task level goals), if any.
  TextColumn get ownerAgentId => text().nullable()();

  /// Team this goal belongs to (for team-level goals), if any.
  TextColumn get teamId => text().nullable()();

  /// Ticket this goal is realized by (for task-level goals), if any.
  TextColumn get targetTicketId => text().nullable()();

  /// Self-reported or aggregated completion percentage (0–100).
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// When this goal was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this goal was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'goals';

  @override
  Set<Column> get primaryKey => {id};
}
