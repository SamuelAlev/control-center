import 'package:drift/drift.dart';

/// Drift table for budget policies.
///
/// A policy caps monthly spend for a scope (agent / team / company). The soft
/// threshold fires a warning; the hard limit auto-pauses the scope. Cost rolls
/// up per-agent → per-team → per-company. Workspace-scoped: every read filters
/// by [workspaceId].
@TableIndex(name: 'idx_budget_policies_workspaceId', columns: {#workspaceId})
class BudgetPolicyTable extends Table {
  /// Unique policy identifier.
  TextColumn get id => text()();

  /// Owning workspace. Defaults to empty for legacy rows (none exist in
  /// practice — the table had no DAO before governance).
  TextColumn get workspaceId => text().withDefault(const Constant(''))();

  /// Scope type (e.g. 'workspace', 'agent').
  TextColumn get scopeType => text()();

  /// Id of the scope this policy applies to.
  TextColumn get scopeId => text()();

  /// Monthly budget in cents.
  IntColumn get monthlyBudgetCents =>
      integer().withDefault(const Constant(0))();

  /// Soft threshold as a percentage of the budget.
  IntColumn get softThresholdPercent =>
      integer().withDefault(const Constant(80))();

  /// Whether hard stop is enabled.
  BoolColumn get hardStopEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Amount spent so far in cents.
  IntColumn get spentCents => integer().withDefault(const Constant(0))();

  /// Policy status ('active', 'paused', etc.).
  TextColumn get status => text().withDefault(const Constant('active'))();

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
