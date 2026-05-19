import 'package:drift/drift.dart';

/// User-defined action-guardrail rules (PRD 24 §2).
///
/// A rule maps `(scope, ActionClass | commandPrefix) → allow | prompt | deny`
/// at workspace / space / agent scope. Resolution (in domain) is
/// `space > agent > workspace > mode preset > built-in default`; within a
/// scope, longest-prefix then most-restrictive. Workspace-scoped; the unique
/// key guarantees at most one rule per `(scope, actionClass, commandPrefix)`.
@TableIndex(name: 'idx_action_policies_workspace', columns: {#workspaceId})
@TableIndex(
  name: 'idx_action_policies_scope',
  columns: {#workspaceId, #scopeType, #scopeId},
)
class ActionPoliciesTable extends Table {
  @override
  String get tableName => 'action_policies';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Scope type: `workspace` / `space` / `agent`.
  TextColumn get scopeType => text()();

  /// Scope id (empty string for `workspace` scope; space/agent id otherwise).
  TextColumn get scopeId => text().withDefault(const Constant(''))();

  /// The ActionClass wire name this rule governs (null when a [commandPrefix]
  /// rule instead). Exactly one of actionClass / commandPrefix is set.
  TextColumn get actionClass => text().nullable()();

  /// A command prefix (e.g. `git push`) this rule governs (null when an
  /// [actionClass] rule instead). Resolved by longest matching prefix.
  TextColumn get commandPrefix => text().nullable()();

  /// The decision: `allow` / `prompt` / `deny`.
  TextColumn get decision => text().withDefault(const Constant('prompt'))();

  /// Provenance: `user` / `remembered` (a materialized RememberScope decision).
  TextColumn get provenance => text().withDefault(const Constant('user'))();

  /// Optional argument constraint JSON (`ActionConstraint` wire shape: path
  /// globs, ref patterns, host allowlists, magnitude ceilings). NULL matches
  /// every request — every pre-constraint row keeps its exact meaning.
  TextColumn get constraintJson => text().nullable()();

  /// Optional expiry. A rule past its [expiresAt] is skipped by the resolver
  /// — this is what makes "remember this decision for 8 hours" and other
  /// standing approvals self-revoking. NULL = permanent.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Enforcement level: `advisory` (log only) / `soft` (deny, overridable
  /// with the override permission + a recorded reason) / `hard` (nothing
  /// overrides). NULL = `hard`, the pre-column behavior.
  TextColumn get enforcement => text().nullable()();

  /// Principal that created the rule.
  TextColumn get createdBy => text().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, scopeType, scopeId, actionClass, commandPrefix},
  ];
}
