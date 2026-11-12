import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/teams_table.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:drift/drift.dart';

/// Drift table for the organizational goal hierarchy
/// (company → team → agent → task).
///
/// Goals cascade from a company mission down to the tasks an individual agent
/// works on, so any agent can see how its work serves the bigger picture. A
/// goal's [parentGoalId] forms a strict tree; progress aggregates upward from
/// task completion. Workspace-scoped: every read filters by [workspaceId].
///
/// Every reference is `SET NULL`: deleting a goal makes its children roots
/// (no subtree delete behind the caller's back), and a goal outlives the
/// agent, team or ticket it pointed at.
@TableIndex(name: 'idx_goals_created', columns: {#createdAt})
@TableIndex(name: 'idx_goals_parent', columns: {#parentGoalId})
@TableIndex(name: 'idx_goals_owner_agent', columns: {#ownerAgentId})
@TableIndex(name: 'idx_goals_team', columns: {#teamId})
@TableIndex(name: 'idx_goals_target_ticket', columns: {#targetTicketId})
class GoalsTable extends Table {
  /// Unique goal identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Parent goal in the hierarchy, or null for the company mission (the root).
  TextColumn get parentGoalId => text().nullable().references(
    GoalsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Hierarchy level: an `OrgGoalLevel` name.
  TextColumn get level => text()
      // ignore: recursive_getters
      .check(level.isIn(AgentsStoredValues.orgGoalLevel))
      .withDefault(const Constant('company'))();

  /// Short goal title.
  TextColumn get title => text()();

  /// Optional longer description of the objective.
  TextColumn get description => text().nullable()();

  /// Lifecycle status: an `OrgGoalStatus` name.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(AgentsStoredValues.orgGoalStatus))
      .withDefault(const Constant('active'))();

  /// Agent that owns this goal (for agent/task level goals), if any.
  TextColumn get ownerAgentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Team this goal belongs to (for team-level goals), if any.
  TextColumn get teamId => text().nullable().references(
    TeamsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Ticket this goal is realized by (for task-level goals), if any.
  TextColumn get targetTicketId => text().nullable().references(
    TicketsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

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
