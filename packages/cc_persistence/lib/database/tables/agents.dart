import 'package:cc_persistence/database/tables/budget_policy_table.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/runtime_profiles_table.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'uq_agents_name', columns: {#name}, unique: true)
@TableIndex(name: 'idx_agents_reports_to', columns: {#reportsTo})
@TableIndex(name: 'idx_agents_budget_policy', columns: {#budgetPolicyId})
@TableIndex(name: 'idx_agents_runtime_profile', columns: {#runtimeProfileId})
/// Drift table definition for agents.
class AgentsTable extends Table {
  /// Unique agent identifier.
  TextColumn get id => text()();

  /// Short agent name. Unique in its workspace, whose file this is
  /// (`uq_agents_name`).
  TextColumn get name => text()();

  /// Human-readable title.
  TextColumn get title => text()();

  /// Path to the agent's markdown file.
  TextColumn get agentMdPath => text()();

  /// Id of the workspace this agent belongs to.
  TextColumn get workspaceId => text()();

  /// Id of the agent this one reports to, if any. `SET NULL`: deleting a
  /// manager leaves its reports at the top of the chart.
  TextColumn get reportsTo => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Comma-separated list of skills.
  TextColumn get skills => text()();

  /// Optional persona description.
  TextColumn get persona => text().nullable()();

  /// System prompt override for the agent.
  TextColumn get systemPrompt => text().nullable()();

  /// Selected adapter identifier. Open set: registered adapter ids.
  TextColumn get adapterId => text().nullable()();

  /// Selected model identifier. Open set: provider model ids.
  TextColumn get modelId => text().nullable()();

  /// Whether strict identity checking is enabled.
  BoolColumn get strictMode => boolean().withDefault(const Constant(false))();

  /// Reasoning effort level (`low`, `medium`, `high`, `xhigh`, …). Open set:
  /// each adapter names its own levels.
  TextColumn get effort => text().nullable()();

  /// Context window size in tokens.
  IntColumn get contextSize => integer().nullable()();

  /// Agent role: an `AgentRole` name. Null when unassigned.
  TextColumn get role =>
      text().nullable()
      // ignore: recursive_getters
      .check(role.isIn(AgentsStoredValues.agentRole))();

  /// Monthly budget in micro-dollars for this agent (0 means unlimited).
  IntColumn get monthlyBudgetMicros =>
      integer().withDefault(const Constant(0))();

  /// Per-agent silence-timeout override in minutes. Null falls back to the
  /// per-mode default at dispatch time.
  IntColumn get silenceTimeoutMinutes => integer().nullable()();

  /// Maximum number of tasks this agent may work concurrently. Drives the
  /// presence workload model (running/queued/idle vs capacity).
  IntColumn get maxConcurrentTasks =>
      integer().withDefault(const Constant(1))();

  /// Agent visibility: an `AgentVisibility` name.
  TextColumn get visibility => text()
      .check(
        // ignore: recursive_getters
        visibility.isIn(AgentsStoredValues.agentVisibility),
      )
      .withDefault(const Constant('workspace'))();

  /// Governance lifecycle status: an `AgentLifecycleStatus` name (`paused`
  /// e.g. after a budget hard-stop).
  TextColumn get lifecycleStatus => text()
      .check(
        // ignore: recursive_getters
        lifecycleStatus.isIn(AgentsStoredValues.agentLifecycleStatus),
      )
      .withDefault(const Constant('active'))();

  /// Shared budget policy this agent draws from, if any. Null means the
  /// per-agent `monthlyBudgetMicros` applies directly, which is what `SET
  /// NULL` leaves when the policy is deleted.
  TextColumn get budgetPolicyId => text().nullable().references(
    BudgetPolicyTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Custom runtime profile backing this agent, if any. Null means the
  /// adapter's default launch configuration applies, which is what `SET
  /// NULL` leaves when the profile is deleted.
  TextColumn get runtimeProfileId => text().nullable().references(
    RuntimeProfilesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'agents';

  @override
  Set<Column> get primaryKey => {id};
}
