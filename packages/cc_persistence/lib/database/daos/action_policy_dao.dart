import 'package:cc_persistence/database/tables/action_policies_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'action_policy_dao.g.dart';

/// Data access for the action-guardrail rules store (PRD 24). Every read
/// filters by `workspaceId` (workspace isolation invariant).
@DriftAccessor(tables: [ActionPoliciesTable])
class ActionPolicyDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ActionPolicyDaoMixin {
  /// Creates an [ActionPolicyDao].
  ActionPolicyDao(super.db);

  /// Inserts or replaces a rule by id (deterministic id → PK upsert).
  Future<void> upsertRule(ActionPoliciesTableCompanion entry) =>
      into(actionPoliciesTable).insertOnConflictUpdate(entry);

  /// All rules in [workspaceId] (the resolver loads the full set once per
  /// evaluation batch and resolves in memory).
  Future<List<ActionPoliciesTableData>> rules(String workspaceId) => (select(
    actionPoliciesTable,
  )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// Live rules in [workspaceId] (policy surface).
  Stream<List<ActionPoliciesTableData>> watchRules(String workspaceId) =>
      (select(actionPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.scopeType),
              (t) => OrderingTerm.asc(t.scopeId),
            ]))
          .watch();

  /// Rules for a specific scope within [workspaceId].
  Future<List<ActionPoliciesTableData>> rulesForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  ) =>
      (select(actionPoliciesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.scopeType.equals(scopeType) &
                t.scopeId.equals(scopeId),
          ))
          .get();

  /// One rule by id within [workspaceId], or null.
  Future<ActionPoliciesTableData?> ruleById(String workspaceId, String id) =>
      (select(actionPoliciesTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Deletes a rule within [workspaceId].
  Future<void> deleteRule(String workspaceId, String id) => (delete(
    actionPoliciesTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
