import 'package:cc_domain/core/domain/entities/llm_call_record.dart';
import 'package:cc_domain/core/domain/repositories/llm_call_record_repository.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart' as drift;

/// Drift-backed [LlmCallRecordRepository] over the per-workspace databases.
///
/// The ledger lives in the workspace file the run belongs to, so the workspace
/// id picks the database before any SQL runs and a run id alone can never reach
/// across the isolation boundary.
///
/// Writes are upserts keyed on the record's DETERMINISTIC id
/// (`runId/requestId/attempt`), which is what makes replay safe: a call
/// reported again after a retry, a transcript replay or a cumulative CLI ledger
/// re-read collapses onto its existing row instead of adding a second charge.
class DaoLlmCallRecordRepository implements LlmCallRecordRepository {
  /// Creates a repository over the supplied workspace database manager.
  DaoLlmCallRecordRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  WorkspaceDatabase _db(String workspaceId) {
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'a call record must name the workspace it belongs to',
      );
    }
    return _dbs.of(workspaceId);
  }

  @override
  Future<void> upsert(String workspaceId, LlmCallRecord record) async {
    final db = _db(workspaceId);
    await db
        .into(db.runCallUsagesTable)
        .insertOnConflictUpdate(_companion(workspaceId, record));
  }

  @override
  Future<int> upsertAll(
    String workspaceId,
    Iterable<LlmCallRecord> records,
  ) async {
    final list = records.toList(growable: false);
    if (list.isEmpty) {
      return 0;
    }
    final db = _db(workspaceId);
    // One transaction: a partially-applied batch would leave the ledger with
    // some of a run's calls counted and others missing, which is worse than
    // none — a total that is wrong without saying so.
    await db.transaction(() async {
      for (final record in list) {
        await db
            .into(db.runCallUsagesTable)
            .insertOnConflictUpdate(_companion(workspaceId, record));
      }
    });
    return list.length;
  }

  @override
  Future<List<LlmCallRecord>> listByRun(
    String workspaceId,
    String runId,
  ) async {
    final db = _db(workspaceId);
    final rows =
        await (db.select(db.runCallUsagesTable)
              ..where((t) => t.runId.equals(runId))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.startedAt)]))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<int> costMicrosForRun(String workspaceId, String runId) async {
    final db = _db(workspaceId);
    final table = db.runCallUsagesTable;
    final total = table.costMicros.sum();
    final row =
        await (db.selectOnly(table)
              ..addColumns([total])
              ..where(table.runId.equals(runId)))
            .getSingle();
    return row.read(total) ?? 0;
  }

  @override
  Stream<List<LlmCallRecord>> watchByRun(String workspaceId, String runId) {
    final db = _db(workspaceId);
    return (db.select(db.runCallUsagesTable)
          ..where((t) => t.runId.equals(runId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.startedAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList(growable: false));
  }

  @override
  Future<List<LlmCallRecord>> listByConversation(
    String workspaceId,
    String conversationId,
  ) async {
    final db = _db(workspaceId);
    final rows =
        await (db.select(db.runCallUsagesTable)
              ..where((t) => t.conversationId.equals(conversationId))
              ..orderBy([(t) => drift.OrderingTerm.desc(t.startedAt)]))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  static RunCallUsagesTableCompanion _companion(
    String workspaceId,
    LlmCallRecord record,
  ) => RunCallUsagesTableCompanion(
    id: drift.Value(record.id),
    runId: drift.Value.absentIfNull(record.runId),
    // The file's workspace wins over the record's: a record that arrived from
    // an adapter without a workspace still has to be filed where it was stored,
    // and a disagreeing pair would be an isolation bug, not a preference.
    workspaceId: drift.Value(workspaceId),
    conversationId: drift.Value.absentIfNull(record.conversationId),
    requestId: drift.Value(record.requestId),
    attempt: drift.Value(record.attempt),
    purpose: drift.Value(record.purpose.wire),
    provider: drift.Value(record.provider),
    modelId: drift.Value(record.modelId),
    inputTokens: drift.Value(record.inputTokens),
    outputTokens: drift.Value(record.outputTokens),
    thoughtTokens: drift.Value(record.thoughtTokens),
    cachedReadTokens: drift.Value(record.cachedReadTokens),
    cachedWriteTokens: drift.Value(record.cachedWriteTokens),
    costMicros: drift.Value.absentIfNull(record.costMicros),
    costBasis: drift.Value(record.costBasis.name),
    transportFirstByteMs: drift.Value.absentIfNull(record.transportFirstByteMs),
    firstModelEventMs: drift.Value.absentIfNull(record.firstModelEventMs),
    durationMs: drift.Value.absentIfNull(record.durationMs),
    outcome: drift.Value(record.outcome.wire),
    errorCode: drift.Value.absentIfNull(record.errorCode),
    startedAt: drift.Value(record.startedAt),
    recordedAt: drift.Value(record.recordedAt),
  );

  static LlmCallRecord _toDomain(RunCallUsagesTableData row) => LlmCallRecord(
    requestId: row.requestId,
    purpose: LlmCallPurpose.fromWire(row.purpose),
    provider: row.provider,
    modelId: row.modelId,
    startedAt: row.startedAt,
    recordedAt: row.recordedAt,
    runId: row.runId,
    workspaceId: row.workspaceId,
    conversationId: row.conversationId,
    attempt: row.attempt,
    inputTokens: row.inputTokens,
    outputTokens: row.outputTokens,
    thoughtTokens: row.thoughtTokens,
    cachedReadTokens: row.cachedReadTokens,
    cachedWriteTokens: row.cachedWriteTokens,
    costMicros: row.costMicros,
    costBasis: CostBasis.fromWire(row.costBasis),
    transportFirstByteMs: row.transportFirstByteMs,
    firstModelEventMs: row.firstModelEventMs,
    durationMs: row.durationMs,
    outcome: LlmCallOutcome.fromWire(row.outcome),
    errorCode: row.errorCode,
  );
}
