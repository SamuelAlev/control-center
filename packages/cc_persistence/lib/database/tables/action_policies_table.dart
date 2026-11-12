import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// User-defined action-guardrail rules (PRD 24 §2).
///
/// A rule maps `(scope, ActionClass | commandPrefix) → allow | prompt | deny`
/// at workspace / space / agent scope. Resolution (in domain) is
/// `space > agent > workspace > mode preset > built-in default`; within a
/// scope, longest-prefix then most-restrictive.
///
/// A rule's identity is a schema fact, not a Dart convention: the two partial
/// unique indexes below hold one per subject shape (an action class, or a
/// command prefix) and spell `ActionPolicyRule.sharesIdentityWith`. A plain
/// rule (a person's `user` rule with no constraint and no expiry) is unique
/// per scope and subject; any other rule is unique per scope, subject,
/// provenance and exact constraint, so a plain rule and a standing approval
/// of the same class coexist. `ActionPolicyDao.upsertRule` writes against
/// these indexes in one statement, so a second rule with an identity that
/// already exists updates that row instead of joining it.
///
/// No foreign key on [scopeId]: it names a space or an agent depending on
/// [scopeType], and a rule must outlive neither (deleting a space or an agent
/// leaves its rules unreachable, which resolves to nothing).
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_action_policies_class_rule '
  'ON action_policies (scope_type, scope_id, action_class, provenance, '
  "coalesce(constraint_json, ''), "
  "(provenance = 'user' AND constraint_json IS NULL AND expires_at IS NULL)) "
  'WHERE action_class IS NOT NULL',
)
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_action_policies_command_rule '
  'ON action_policies (scope_type, scope_id, command_prefix, provenance, '
  "coalesce(constraint_json, ''), "
  "(provenance = 'user' AND constraint_json IS NULL AND expires_at IS NULL)) "
  'WHERE command_prefix IS NOT NULL',
)
@TableIndex(name: 'idx_action_policies_scope', columns: {#scopeType, #scopeId})
class ActionPoliciesTable extends Table {
  @override
  String get tableName => 'action_policies';

  /// Unique row id (UUID v4, or the desktop's stable per-cell id).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Scope type: an `ActionScopeType` wire name.
  TextColumn get scopeType => text().check(
    // ignore: recursive_getters
    scopeType.isIn(AgentsStoredValues.actionScopeType),
  )();

  /// Scope id: empty for `workspace` scope, the space or agent id otherwise
  /// (the table's scope-shape check holds the pairing).
  TextColumn get scopeId => text().withDefault(const Constant(''))();

  /// The ActionClass wire name this rule governs (null when a [commandPrefix]
  /// rule instead). Exactly one of actionClass / commandPrefix is set.
  TextColumn get actionClass =>
      text().nullable()
      // ignore: recursive_getters
      .check(actionClass.isIn(AgentsStoredValues.actionClass))();

  /// A command prefix (e.g. `git push`) this rule governs (null when an
  /// [actionClass] rule instead). Resolved by longest matching prefix.
  TextColumn get commandPrefix => text().nullable()();

  /// The decision: an `ActionDecision` wire name.
  TextColumn get decision => text()
      .check(
        // ignore: recursive_getters
        decision.isIn(AgentsStoredValues.actionDecision),
      )
      .withDefault(const Constant('prompt'))();

  /// Provenance: `user` / `remembered` (a materialized RememberScope
  /// decision).
  TextColumn get provenance => text()
      .check(
        // ignore: recursive_getters
        provenance.isIn(AgentsStoredValues.actionPolicyProvenance),
      )
      .withDefault(const Constant('user'))();

  /// Optional argument constraint JSON (`ActionConstraint` wire shape: path
  /// globs, ref patterns, host allowlists, magnitude ceilings). NULL matches
  /// every request.
  TextColumn get constraintJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(constraintJson))();

  /// Optional expiry. A rule past its [expiresAt] is skipped by the resolver
  /// — this is what makes "remember this decision for 8 hours" and other
  /// standing approvals self-revoking. NULL = permanent.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Enforcement level: an `EnforcementLevel` wire name. NULL reads as
  /// `hard`.
  TextColumn get enforcement =>
      text().nullable()
      // ignore: recursive_getters
      .check(enforcement.isIn(AgentsStoredValues.enforcementLevel))();

  /// Principal that created the rule (no foreign key: a user id lives in
  /// `global.db`).
  TextColumn get createdBy => text().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  /// A rule names exactly one subject, and its scope id agrees with its scope
  /// type: none for the workspace, the space or agent otherwise.
  @override
  List<String> get customConstraints => [
    'CHECK ((action_class IS NULL) <> (command_prefix IS NULL))',
    "CHECK ((scope_type = 'workspace') = (scope_id = ''))",
  ];
}
