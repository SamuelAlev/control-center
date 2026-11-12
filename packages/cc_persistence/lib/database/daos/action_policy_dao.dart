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

  /// The rule identity of one subject shape, exactly as the table's partial
  /// unique index on that shape spells it (an upsert target must repeat the
  /// index's columns and `WHERE`).
  static String _identityTarget(String subject) =>
      '(scope_type, scope_id, $subject, provenance, '
      "coalesce(constraint_json, ''), "
      "(provenance = 'user' AND constraint_json IS NULL "
      'AND expires_at IS NULL)) WHERE $subject IS NOT NULL';

  /// The upsert of a rule writing [columns]: an insert whose conflicts with
  /// the id or with either identity index update the existing row's
  /// [columns] in place.
  ///
  /// A new id whose identity already exists takes over the existing row, id
  /// included, so the caller's id names the rule it just wrote (no key
  /// points at a rule id).
  static String _upsertSql(List<String> columns) {
    final edit = [
      for (final c in columns)
        if (c != 'id') '$c = excluded.$c',
    ].join(', ');
    final takeOver = [for (final c in columns) '$c = excluded.$c'].join(', ');
    return 'INSERT INTO action_policies (${columns.join(', ')}) '
        'VALUES (${List.filled(columns.length, '?').join(', ')}) '
        // The same id is an edit of that rule, whatever it now says.
        'ON CONFLICT (id) DO UPDATE SET $edit '
        // A new id whose identity already exists replaces that rule in place
        // instead of adding a second one.
        'ON CONFLICT ${_identityTarget('action_class')} '
        'DO UPDATE SET $takeOver '
        'ON CONFLICT ${_identityTarget('command_prefix')} '
        'DO UPDATE SET $takeOver';
  }

  /// Writes [entry] in ONE statement keyed on the rule's identity.
  ///
  /// The row with the same id is updated; otherwise the row that already has
  /// the rule's identity (same scope, subject, provenance and constraint, see
  /// `ActionPolicyRule.sharesIdentityWith`) is updated; otherwise the rule is
  /// inserted. Two writers of the same rule therefore leave one row, and no
  /// moment exists where an old deny is gone and its replacement not yet
  /// written. Editing a rule (same id) into the identity of ANOTHER existing
  /// rule is refused by the unique index rather than merging the two.
  ///
  /// Only the columns present in [entry] are written; an absent column takes
  /// its default on insert and keeps its value on update.
  Future<void> upsertRule(ActionPoliciesTableCompanion entry) {
    final columns = entry.toColumns(false);
    return customInsert(
      _upsertSql(columns.keys.toList()),
      variables: [for (final value in columns.values) value as Variable],
      updates: {actionPoliciesTable},
    );
  }

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
