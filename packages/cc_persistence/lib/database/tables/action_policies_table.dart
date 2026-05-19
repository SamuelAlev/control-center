import 'package:drift/drift.dart';

/// User-defined action-guardrail rules (PRD 24 §2).
///
/// A rule maps `(scope, ActionClass | commandPrefix) → allow | prompt | deny`
/// at workspace / channel / agent scope. Resolution (in domain) is
/// `channel > agent > workspace > mode preset > built-in default`; within a
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

  /// Scope type: `workspace` / `channel` / `agent`.
  TextColumn get scopeType => text()();

  /// Scope id (empty string for `workspace` scope; channel/agent id otherwise).
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
