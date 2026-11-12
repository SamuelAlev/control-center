import 'package:cc_persistence/database/tables/budget_incidents_table.dart';
import 'package:cc_persistence/database/tables/budget_policy_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'budget_dao.g.dart';

/// Data access for budget policies and the incidents they raise. Every read
/// filters by `workspaceId`.
@DriftAccessor(tables: [BudgetPolicyTable, BudgetIncidentsTable])
class BudgetDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$BudgetDaoMixin {
  /// Creates a [BudgetDao].
  BudgetDao(super.db);

  // ── Budget policies ──

  /// Watches all budget policies for [workspaceId].
  Stream<List<BudgetPolicyTableData>> watchPolicies(String workspaceId) =>
      (select(budgetPolicyTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.scopeType)]))
          .watch();

  /// Returns all budget policies for [workspaceId].
  Future<List<BudgetPolicyTableData>> getPolicies(String workspaceId) =>
      (select(
        budgetPolicyTable,
      )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// Returns a single policy by [id] within [workspaceId], or null.
  Future<BudgetPolicyTableData?> getPolicyById(String workspaceId, String id) =>
      (select(budgetPolicyTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Returns the policy governing [scopeType]/[scopeId] in [workspaceId], or
  /// null when the scope is uncapped.
  Future<BudgetPolicyTableData?> getPolicyForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  ) =>
      (select(budgetPolicyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.scopeType.equals(scopeType) &
                t.scopeId.equals(scopeId),
          ))
          .getSingleOrNull();

  /// Inserts or updates a budget policy in one statement: the row with the
  /// same id, else the scope's existing policy (one per scope,
  /// `uq_budget_policy_scope`), which keeps its id.
  Future<void> upsertPolicy(BudgetPolicyTableCompanion entry) =>
      into(budgetPolicyTable).insert(
        entry,
        onConflict: UpsertMultiple([
          DoUpdate((_) => entry, target: [budgetPolicyTable.id]),
          DoUpdate(
            (_) => entry.copyWith(id: const Value.absent()),
            target: [budgetPolicyTable.scopeType, budgetPolicyTable.scopeId],
          ),
        ]),
      );

  /// Deletes a policy by [id] within [workspaceId]. Returns rows deleted.
  Future<int> deletePolicy(String workspaceId, String id) => (delete(
    budgetPolicyTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Budget incidents ──

  /// Watches budget incidents for [workspaceId], newest first.
  Stream<List<BudgetIncidentsTableData>> watchIncidents(
    String workspaceId, {
    int limit = 100,
  }) =>
      (select(budgetIncidentsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.triggeredAt)])
            ..limit(limit))
          .watch();

  /// Returns budget incidents for a specific scope within [workspaceId].
  Future<List<BudgetIncidentsTableData>> incidentsForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  ) =>
      (select(budgetIncidentsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.scopeType.equals(scopeType) &
                  t.scopeId.equals(scopeId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.triggeredAt)]))
          .get();

  /// Inserts a new budget incident.
  Future<void> insertIncident(BudgetIncidentsTableCompanion entry) =>
      into(budgetIncidentsTable).insert(entry);
}
