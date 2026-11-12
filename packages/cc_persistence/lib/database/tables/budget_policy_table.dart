import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Drift table for budget policies.
///
/// A policy caps monthly spend for a scope (agent / team / company). The soft
/// threshold fires a warning; the hard limit auto-pauses the scope. Cost rolls
/// up per-agent → per-team → per-company. Workspace-scoped: every read filters
/// by [workspaceId]. One policy per scope (`uq_budget_policy_scope`), which
/// `BudgetDao.upsertPolicy` writes against.
@TableIndex(
  name: 'uq_budget_policy_scope',
  columns: {#scopeType, #scopeId},
  unique: true,
)
class BudgetPolicyTable extends Table {
  /// Unique policy identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Scope type: a `BudgetScopeType` name.
  TextColumn get scopeType => text().check(
    // ignore: recursive_getters
    scopeType.isIn(AgentsStoredValues.budgetScopeType),
  )();

  /// Id of the scope this policy applies to. No foreign key: the scope type
  /// says which table.
  TextColumn get scopeId => text()();

  /// Monthly budget in micro-dollars (0 means unlimited).
  IntColumn get monthlyBudgetMicros =>
      integer().withDefault(const Constant(0))();

  /// Soft threshold as a percentage of the budget.
  IntColumn get softThresholdPercent =>
      integer().withDefault(const Constant(80))();

  /// Whether hard stop is enabled.
  BoolColumn get hardStopEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Amount spent so far in micro-dollars.
  IntColumn get spentMicros => integer().withDefault(const Constant(0))();

  /// Policy status: a `BudgetPolicyStatus` name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.budgetPolicyStatus),
      )
      .withDefault(const Constant('active'))();

  /// Start of the current billing period.
  DateTimeColumn get periodStart =>
      dateTime().withDefault(currentDateAndTime)();

  /// End of the current billing period.
  DateTimeColumn get periodEnd => dateTime().nullable()();

  /// When this policy was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'budget_policy';

  @override
  Set<Column> get primaryKey => {id};
}
