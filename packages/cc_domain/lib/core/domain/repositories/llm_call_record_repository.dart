import 'package:cc_domain/core/domain/entities/llm_call_record.dart';

/// Durable store of per-request model-call accounting records.
///
/// This is the accounting LEDGER, not the run log: one row per model request —
/// including failed, retried and auxiliary calls — so cost attribution does not
/// depend on how a particular code path happened to aggregate its tokens.
///
/// Workspace-scoped by construction: every method names its `workspaceId`, and
/// an implementation must resolve the run only inside it (a run id alone never
/// reaches across the isolation boundary).
abstract class LlmCallRecordRepository {
  /// Stores [record], replacing an existing row with the same deterministic
  /// [LlmCallRecord.id] (`runId/requestId/attempt`).
  ///
  /// Upsert (not insert) is what makes replay safe: the same completed call
  /// reported twice — by an adapter retry, a transcript replay or a cumulative
  /// CLI ledger re-read — counts exactly once.
  Future<void> upsert(String workspaceId, LlmCallRecord record);

  /// Stores [records] in one transaction, upserting each by its id. Returns the
  /// number of rows actually written (duplicates already present are counted,
  /// since the row exists either way).
  Future<int> upsertAll(String workspaceId, Iterable<LlmCallRecord> records);

  /// All records for [runId] within [workspaceId], oldest call first.
  Future<List<LlmCallRecord>> listByRun(String workspaceId, String runId);

  /// Watches the records for [runId] within [workspaceId], oldest call first.
  Stream<List<LlmCallRecord>> watchByRun(String workspaceId, String runId);

  /// All records for every run of [conversationId] within [workspaceId],
  /// newest call first. Backs the conversation-level cost breakdown.
  Future<List<LlmCallRecord>> listByConversation(
    String workspaceId,
    String conversationId,
  );

  /// Sums the exact cost of every record for [runId], in micro-USD.
  ///
  /// A read-through helper rather than a stored rollup: the ledger is the
  /// source of truth, and a cached total that drifts from its rows is worse
  /// than a cheap `SUM`.
  Future<int> costMicrosForRun(String workspaceId, String runId) async {
    final records = await listByRun(workspaceId, runId);
    var total = 0;
    for (final record in records) {
      total += record.costMicros ?? 0;
    }
    return total;
  }
}
