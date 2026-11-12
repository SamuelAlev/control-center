import 'package:cc_persistence/database/tables/budget_policy_table.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Drift table for budget incidents — the durable record written whenever a
/// scope (agent / team / company) crosses a budget threshold.
///
/// A soft incident ([isHardStop] = false) records a warning; a hard incident
/// ([isHardStop] = true) records the auto-pause that flips the offending
/// agent's lifecycle status to `paused`. Workspace-scoped: every read filters
/// by [workspaceId].
@TableIndex(
  name: 'idx_budget_incidents_scope',
  columns: {#scopeType, #scopeId, #triggeredAt},
)
@TableIndex(name: 'idx_budget_incidents_triggered', columns: {#triggeredAt})
@TableIndex(name: 'idx_budget_incidents_policy', columns: {#policyId})
class BudgetIncidentsTable extends Table {
  /// Unique incident identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Budget policy that triggered this incident, if a policy was involved.
  /// `SET NULL`: the incident is a record and outlives the policy.
  TextColumn get policyId => text().nullable().references(
    BudgetPolicyTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Scope type the budget applies to: a `BudgetScopeType` name.
  TextColumn get scopeType => text().check(
    // ignore: recursive_getters
    scopeType.isIn(AgentsStoredValues.budgetScopeType),
  )();

  /// Identifier within the scope (e.g. the agent id). No foreign key: the
  /// scope type says which table, and the incident outlives it.
  TextColumn get scopeId => text()();

  /// Micro-dollars spent in the current window at the moment the incident
  /// fired. The default only serves rows written before the unit was
  /// micro-dollars: their cents figure is not carried over.
  IntColumn get spentMicros => integer().withDefault(const Constant(0))();

  /// The budget ceiling in micro-dollars at the moment the incident fired.
  /// Defaulted for the same reason as [spentMicros].
  IntColumn get budgetMicros => integer().withDefault(const Constant(0))();

  /// Whether this incident hard-stopped the scope (vs a soft warning).
  BoolColumn get isHardStop => boolean().withDefault(const Constant(false))();

  /// Reason code (e.g. `budget_exhausted`, `soft_threshold`). Open set: the
  /// governance services name their own reasons.
  TextColumn get reason => text()();

  /// When the incident fired.
  DateTimeColumn get triggeredAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'budget_incidents';

  @override
  Set<Column> get primaryKey => {id};
}
