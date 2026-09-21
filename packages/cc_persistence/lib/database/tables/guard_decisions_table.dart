import 'package:drift/drift.dart';

/// Tamper-evident authorization audit (one row per guard verdict, allow and deny).
///
/// Attribution: actor, on-behalf-of user, rule/source scope, optional delegation
/// chain. Hash-chained per workspace (`entryHash`/`prevHash`/`seq`); never
/// age-pruned — retention is export-then-truncate with a checkpoint hash.
@TableIndex(name: 'idx_guard_decisions_workspace', columns: {#workspaceId})
@TableIndex(
  name: 'idx_guard_decisions_time',
  columns: {#workspaceId, #occurredAt},
)
class GuardDecisionsTable extends Table {
  @override
  String get tableName => 'guard_decisions';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// The owning workspace.
  TextColumn get workspaceId => text()();

  /// Monotonic per-workspace sequence — the chain order. Allocated in the
  /// same transaction as the insert, so two writers cannot fork the chain.
  IntColumn get seq => integer()();

  /// When the decision was made.
  DateTimeColumn get occurredAt => dateTime()();

  /// `user` | `agent` | `system` — who initiated the action.
  TextColumn get actorType => text()();

  /// The initiating principal's id (user id / agent id).
  TextColumn get actorId => text()();

  /// The human the action is attributed to when [actorType] is `agent` (the
  /// dispatching user). Null for a background run with no human behind it.
  TextColumn get onBehalfOfUserId => text().nullable()();

  /// Delegation chain root (the original ticket/task id) when the authority
  /// arrived via `delegate_task`; null for direct actions.
  TextColumn get delegationChainId => text().nullable()();

  /// Depth in the delegation chain (0 = direct).
  IntColumn get delegationDepth => integer().nullable()();

  /// The space the action ran in, when space-scoped.
  TextColumn get spaceId => text().nullable()();

  /// The agent run, when the action came from a run.
  TextColumn get runId => text().nullable()();

  /// The calling device (human surfaces).
  TextColumn get deviceId => text().nullable()();

  /// The server's view of the client IP (human surfaces).
  TextColumn get ip => text().nullable()();

  /// Which chokepoint decided: `repo_rpc` | `harness` | `mcp` |
  /// `skill_install` | `sandbox` | `subscription`.
  TextColumn get surface => text()();

  /// The op/tool name that was gated.
  TextColumn get actionName => text()();

  /// The ActionClass wire names involved, as a JSON array (empty for pure
  /// role-gate decisions).
  TextColumn get actionClasses => text().withDefault(const Constant('[]'))();

  /// The derived permission (`domain:tier`) for human-lane decisions.
  TextColumn get permission => text().nullable()();

  /// SHA-256 of the canonical JSON of the REDACTED extracted arguments
  /// (paths/refs/hosts/command), so an audit row proves WHAT was authorized
  /// without storing secrets.
  TextColumn get argsDigest => text().nullable()();

  /// Human-readable summary of the constraint that matched (e.g.
  /// `refs=!main`), for rendering without re-resolving.
  TextColumn get constraintSummary => text().nullable()();

  /// `allow` | `prompt` | `deny` — the resolved verdict.
  TextColumn get decision => text()();

  /// `advisory` | `soft` | `hard` — the enforcement level of the deciding
  /// rule (null = hard, the default).
  TextColumn get enforcement => text().nullable()();

  /// Which scope decided: `space` | `agent` | `workspace` | `managed` |
  /// `preset` | `default` | `role` | `grant`.
  TextColumn get sourceScope => text().nullable()();

  /// The deciding `action_policies` row id, when a stored rule decided.
  TextColumn get ruleId => text().nullable()();

  /// Whether a human was asked (a `prompt` that reached a responder).
  BoolColumn get prompted => boolean().withDefault(const Constant(false))();

  /// The human who answered a prompt (approve or deny).
  TextColumn get responderUserId => text().nullable()();

  /// The mandatory justification recorded when a soft-mandatory deny was
  /// overridden.
  TextColumn get overrideReason => text().nullable()();

  /// Correlates with the `user_activity` row for the same call, when one was
  /// written.
  TextColumn get correlationId => text().nullable()();

  /// The previous row's [entryHash] ('' for the chain genesis / a checkpoint).
  TextColumn get prevHash => text()();

  /// `sha256(prevHash ‖ canonicalJson(row minus hashes))`.
  TextColumn get entryHash => text()();

  /// Row kind: `decision` (normal) or `checkpoint` (written by
  /// export-then-truncate, carrying the removed segment's terminal hash in
  /// [prevHash] so the surviving chain still verifies back to genesis).
  TextColumn get kind => text().withDefault(const Constant('decision'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, seq},
  ];
}
