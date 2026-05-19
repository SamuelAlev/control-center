import 'package:drift/drift.dart';

/// Drift table for budget incidents — the durable record written whenever a
/// scope (agent / team / company) crosses a budget threshold.
///
/// A soft incident ([isHardStop] = false) records a warning; a hard incident
/// ([isHardStop] = true) records the auto-pause that flips the offending
/// agent's lifecycle status to `paused`. Workspace-scoped: every read filters
/// by [workspaceId].
@TableIndex(name: 'idx_budget_incidents_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_budget_incidents_scope', columns: {#scopeType, #scopeId})
class BudgetIncidentsTable extends Table {
  /// Unique incident identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Budget policy that triggered this incident, if a policy was involved.
  TextColumn get policyId => text().nullable()();

  /// Scope type the budget applies to: `agent`, `team`, or `company`.
  TextColumn get scopeType => text()();

  /// Identifier within the scope (e.g. the agent id).
  TextColumn get scopeId => text()();

  /// Cents spent in the current window at the moment the incident fired.
  IntColumn get spentCents => integer()();

  /// The budget ceiling in cents at the moment the incident fired.
  IntColumn get budgetCents => integer()();

  /// Whether this incident hard-stopped the scope (vs a soft warning).
  BoolColumn get isHardStop => boolean().withDefault(const Constant(false))();

  /// Human-readable reason (e.g. `budget_exhausted`, `soft_threshold`).
  TextColumn get reason => text()();

  /// When the incident fired.
  DateTimeColumn get triggeredAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'budget_incidents';

  @override
  Set<Column> get primaryKey => {id};
}
