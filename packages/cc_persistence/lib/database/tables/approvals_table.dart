import 'package:drift/drift.dart';

/// Drift table for board approvals — durable, reviewable governance gates for
/// high-stakes actions (plan-mode exit, merge decisions, release gates, hires).
///
/// An approval moves through a decision state machine — `pending` → one of
/// `approved` / `rejected` / `revision_requested` and a revision-requested
/// approval can be resubmitted back to `pending`. Unlike a per-action
/// confirmation prompt, an approval is a persisted object with a comment
/// history. Workspace-scoped: every read filters by [workspaceId].
@TableIndex(name: 'idx_approvals_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_approvals_status', columns: {#workspaceId, #status})
class ApprovalsTable extends Table {
  /// Unique approval identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Short title of what is being approved.
  TextColumn get title => text()();

  /// Optional longer description / rationale.
  TextColumn get description => text().nullable()();

  /// Kind of governed action: `plan_exit`, `merge`, `release`, `hire`,
  /// or `custom`.
  TextColumn get kind => text().withDefault(const Constant('custom'))();

  /// Decision state: `pending`, `approved`, `rejected`, `revision_requested`.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Actor type that requested the approval (`agent`, `user`, `system`).
  TextColumn get requestedByActorType =>
      text().withDefault(const Constant('agent'))();

  /// Identifier of the requesting actor, if known.
  TextColumn get requestedById => text().nullable()();

  /// JSON array of ticket ids this approval gates (multi-issue gate).
  TextColumn get linkedTicketIds => text().withDefault(const Constant('[]'))();

  /// Type of a single linked entity (e.g. `pull_request`, `goal`), if any.
  TextColumn get linkedEntityType => text().nullable()();

  /// Identifier of the single linked entity, if any.
  TextColumn get linkedEntityId => text().nullable()();

  /// Actor type that made the decision (`user`, `agent`, `system`), if decided.
  TextColumn get decidedByActorType => text().nullable()();

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
