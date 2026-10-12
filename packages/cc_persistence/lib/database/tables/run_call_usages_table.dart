import 'package:drift/drift.dart';

/// Drift table holding the per-REQUEST accounting ledger for agent runs.
///
/// One row per model request — including failed, retried, cancelled and
/// auxiliary calls (compaction, advisor, side requests, subagents). This is
/// deliberately NOT the run log: run-level totals aggregate, but attribution
/// and reconciliation need the individual requests, and a request that never
/// reached the loop (a summarizer whose `LlmUsage` was discarded) must still be
/// counted somewhere.
///
/// The primary key is DETERMINISTIC — `'$runId/$requestId/$attempt'` — so an
/// upsert of the same call (a replay, a cumulative CLI ledger re-read, a retry
/// re-report) collapses onto the existing row instead of double charging the
/// run.
@TableIndex(name: 'idx_run_call_usages_runId', columns: {#runId})
@TableIndex(name: 'idx_run_call_usages_workspace', columns: {#workspaceId})
@TableIndex(
  name: 'idx_run_call_usages_conversation',
  columns: {#workspaceId, #conversationId},
)
@TableIndex(
  name: 'idx_run_call_usages_started',
  columns: {#workspaceId, #startedAt},
)
class RunCallUsagesTable extends Table {
  /// Deterministic dedup key: `runId/requestId/attempt`.
  TextColumn get id => text()();

  /// Run this call belongs to. Nullable: a call can be recorded before its run
  /// row exists (or by a scheduler that has no run log), and dropping the usage
  /// in that case would lose real spend.
  TextColumn get runId => text().nullable()();

  /// Workspace the call was made in. Nullable for the same reason as [runId];
  /// rows are still filed in that workspace's own database file, so the file
  /// boundary is the isolation boundary either way.
  TextColumn get workspaceId => text().nullable()();

  /// Conversation the run belongs to, when known. Backs the conversation-level
  /// cost breakdown.
  TextColumn get conversationId => text().nullable()();

  /// Provider-assigned/loop-assigned request id (stable across retries).
  TextColumn get requestId => text()();

  /// 1-based attempt number for calls sharing [requestId].
  IntColumn get attempt => integer().withDefault(const Constant(1))();

  /// What the call was for: `main` | `compaction` | `advisor` |
  /// `side_request` | `subagent`.
  TextColumn get purpose => text().withDefault(const Constant('main'))();

  /// Provider that served the call (e.g. `anthropic`, `claude-cli`).
  TextColumn get provider => text().withDefault(const Constant(''))();

  /// The model that ACTUALLY served the call (a re-route is not the requested
  /// alias).
  TextColumn get modelId => text().withDefault(const Constant(''))();

  /// Non-cached input tokens.
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();

  /// Output (completion) tokens.
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();

  /// Reasoning / thinking tokens, when reported separately.
  IntColumn get thoughtTokens => integer().withDefault(const Constant(0))();

  /// Cache-hit read tokens.
  IntColumn get cachedReadTokens => integer().withDefault(const Constant(0))();

  /// Cache-write tokens.
  IntColumn get cachedWriteTokens => integer().withDefault(const Constant(0))();

  /// Exact cost in micro-USD (`1e-6` USD). NULLABLE on purpose: null means the
  /// call was UNPRICED, which is a different fact from a genuinely free call and
  /// must not be flattened to zero in a cost report.
  IntColumn get costMicros => integer().nullable()();

  /// How [costMicros] was obtained: `estimated` | `providerReported` |
  /// `subscription` | `mixed`.
  TextColumn get costBasis => text().withDefault(const Constant('estimated'))();

  /// Milliseconds from request start to the first response byte on the
  /// transport. Null when unobservable (a CLI that hides its socket) — never
  /// fabricated.
  IntColumn get transportFirstByteMs => integer().nullable()();

  /// Milliseconds from request start to the first model delta. Null when
  /// unobserved.
  IntColumn get firstModelEventMs => integer().nullable()();

  /// Total call duration in milliseconds, when measured.
  IntColumn get durationMs => integer().nullable()();

  /// How the call ended: `success` | `failure` | `cancelled`.
  TextColumn get outcome => text().withDefault(const Constant('success'))();

  /// Structured provider error code when the call did not succeed.
  TextColumn get errorCode => text().nullable()();

  /// When the call started.
  DateTimeColumn get startedAt => dateTime()();

  /// When the record was captured.
  DateTimeColumn get recordedAt => dateTime()();

  @override
  String get tableName => 'run_call_usages';

  @override
  Set<Column> get primaryKey => {id};
}
