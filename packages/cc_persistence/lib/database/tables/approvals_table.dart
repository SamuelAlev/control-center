import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// Drift table for board approvals — durable, reviewable governance gates for
/// high-stakes actions (plan-mode exit, merge decisions, release gates, hires).
///
/// An approval moves through a decision state machine — `pending` → one of
/// `approved` / `rejected` / `revision_requested` and a revision-requested
/// approval can be resubmitted back to `pending`. Unlike a per-action
/// confirmation prompt, an approval is a persisted object with a comment
/// history. Workspace-scoped: every read filters by [workspaceId].
///
/// No foreign keys on the actor ids (a user lives in `global.db`, an agent
/// here: the actor type says which) nor on the linked entity (its type says
/// which table, and an approval is a record that outlives what it gated).
@TableIndex(name: 'idx_approvals_status', columns: {#status, #createdAt})
@TableIndex(name: 'idx_approvals_created', columns: {#createdAt})
class ApprovalsTable extends Table {
  /// Unique approval identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Short title of what is being approved.
  TextColumn get title => text()();

  /// Optional longer description / rationale.
  TextColumn get description => text().nullable()();

  /// Kind of governed action: an `ApprovalKind` storage key.
  TextColumn get kind => text()
      .check(
        // ignore: recursive_getters
        kind.isIn(AgentsStoredValues.approvalKind),
      )
      .withDefault(const Constant('custom'))();

  /// Decision state: an `ApprovalStatus` storage key.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.approvalStatus),
      )
      .withDefault(const Constant('pending'))();

  /// Actor type that requested the approval: an `ActorKind` name.
  TextColumn get requestedByActorType => text()
      .check(
        // ignore: recursive_getters
        requestedByActorType.isIn(AgentsStoredValues.actorKind),
      )
      .withDefault(const Constant('agent'))();

  /// Identifier of the requesting actor, if known.
  TextColumn get requestedById => text().nullable()();

  /// JSON array of ticket ids this approval gates (multi-issue gate).
  TextColumn get linkedTicketIds => text()
      // ignore: recursive_getters
      .check(isJsonArray(linkedTicketIds))
      .withDefault(const Constant('[]'))();

  /// Type of a single linked entity (e.g. `pull_request`, `goal`), if any.
  /// Open set: each gating feature names its own entity.
  TextColumn get linkedEntityType => text().nullable()();

  /// Identifier of the single linked entity, if any.
  TextColumn get linkedEntityId => text().nullable()();

  /// Actor type that made the decision (an `ActorKind` name), if decided.
  TextColumn get decidedByActorType =>
      text().nullable()
      // ignore: recursive_getters
      .check(decidedByActorType.isIn(AgentsStoredValues.actorKind))();

  /// Identifier of the deciding actor, if decided.
  TextColumn get decidedById => text().nullable()();

  /// Reason captured with the decision, if any.
  TextColumn get decisionReason => text().nullable()();

  /// When the approval was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When a terminal decision was recorded, if decided.
  DateTimeColumn get decidedAt => dateTime().nullable()();

  /// When the approval was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'approvals';

  @override
  Set<Column> get primaryKey => {id};
}
