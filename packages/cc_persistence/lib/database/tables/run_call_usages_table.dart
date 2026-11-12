import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
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
///
/// A call goes with its run (it is that run's accounting); a call with no run
/// (a scheduler's) stands alone.
@TableIndex(name: 'idx_run_call_usages_runId', columns: {#runId, #startedAt})
@TableIndex(
  name: 'idx_run_call_usages_conversation',
  columns: {#conversationId, #startedAt},
)
class RunCallUsagesTable extends Table {
  /// Deterministic dedup key: `runId/requestId/attempt`.
  TextColumn get id => text()();

  /// Run this call belongs to. Nullable: a scheduler with no run log still
  /// records its calls. A call of a run is written while that run's log
  /// exists (the accounting runs inside the run), and goes with it.
  TextColumn get runId => text().nullable().references(
    AgentRunLogsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Workspace the call was made in: always the file's workspace, which the
  /// repository writes whatever the record carried.
  TextColumn get workspaceId => text()();

  /// Conversation the run belongs to, when known. Backs the conversation-level
  /// cost breakdown. `SET NULL`: the spend outlives the conversation.
  TextColumn get conversationId => text().nullable().references(
    ConversationsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Provider-assigned/loop-assigned request id (stable across retries).
  TextColumn get requestId => text()();

  /// 1-based attempt number for calls sharing [requestId].
  IntColumn get attempt => integer().withDefault(const Constant(1))();

  /// What the call was for: an `LlmCallPurpose` wire name.
  TextColumn get purpose => text()
      .check(
        // ignore: recursive_getters
        purpose.isIn(AgentsStoredValues.llmCallPurpose),
      )
      .withDefault(const Constant('main'))();

  /// Provider that served the call (e.g. `anthropic`, `claude-cli`). Open
  /// set: provider ids.
  TextColumn get provider => text().withDefault(const Constant(''))();

  /// The model that ACTUALLY served the call (a re-route is not the requested
  /// alias). Open set: provider model ids.
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

  /// How [costMicros] was obtained: a `CostBasis` name.
  TextColumn get costBasis => text()
      .check(
        // ignore: recursive_getters
        costBasis.isIn(AgentsStoredValues.costBasis),
      )
      .withDefault(const Constant('estimated'))();

  /// Milliseconds from request start to the first response byte on the
  /// transport. Null when unobservable (a CLI that hides its socket) — never
  /// fabricated.
  IntColumn get transportFirstByteMs => integer().nullable()();

  /// Milliseconds from request start to the first model delta. Null when
  /// unobserved.
  IntColumn get firstModelEventMs => integer().nullable()();

  /// Total call duration in milliseconds, when measured.
  IntColumn get durationMs => integer().nullable()();

  /// How the call ended: an `LlmCallOutcome` wire name.
  TextColumn get outcome => text()
      .check(
        // ignore: recursive_getters
        outcome.isIn(AgentsStoredValues.llmCallOutcome),
      )
      .withDefault(const Constant('success'))();

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
