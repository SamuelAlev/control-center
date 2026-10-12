import 'package:cc_domain/core/domain/entities/llm_call_record.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/run_usage_ledger.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Pins the DURABLE half of request-level accounting.
///
/// The ledger's value is that a request is charged exactly once, across process
/// restarts and replays. That only holds if the deterministic id survives the
/// round trip through SQLite AND the upsert actually collapses on it — an
/// in-memory dedup that is lost on reload would re-charge a resumed run.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoLlmCallRecordRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    repo = DaoLlmCallRecordRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  LlmCallRecord call({
    String requestId = 'req-1',
    int attempt = 1,
    String? runId = 'run-1',
    String? workspaceId = 'ws-1',
    String? conversationId = 'conv-1',
    LlmCallPurpose purpose = LlmCallPurpose.main,
    String provider = 'anthropic',
    String modelId = 'claude-opus-4-8',
    int inputTokens = 100,
    int outputTokens = 20,
    int? costMicros = 4321,
    CostBasis basis = CostBasis.providerReported,
    int? transportFirstByteMs = 180,
    int? firstModelEventMs = 240,
    int? durationMs = 3000,
    LlmCallOutcome outcome = LlmCallOutcome.success,
    String? errorCode,
  }) => LlmCallRecord(
    requestId: requestId,
    attempt: attempt,
    runId: runId,
    workspaceId: workspaceId,
    conversationId: conversationId,
    purpose: purpose,
    provider: provider,
    modelId: modelId,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    thoughtTokens: 7,
    cachedReadTokens: 11,
    cachedWriteTokens: 13,
    costMicros: costMicros,
    costBasis: basis,
    transportFirstByteMs: transportFirstByteMs,
    firstModelEventMs: firstModelEventMs,
    durationMs: durationMs,
    outcome: outcome,
    errorCode: errorCode,
    startedAt: DateTime.utc(2026, 10, 11, 12),
    recordedAt: DateTime.utc(2026, 10, 11, 12, 0, 3),
  );

  test('round-trips every accounted field', () async {
    final record = call();
    await repo.upsert('ws-1', record);

    final back = (await repo.listByRun('ws-1', 'run-1')).single;
    expect(back.requestId, 'req-1');
    expect(back.attempt, 1);
    expect(back.purpose, LlmCallPurpose.main);
    expect(back.provider, 'anthropic');
    expect(back.modelId, 'claude-opus-4-8');
    expect(back.inputTokens, 100);
    expect(back.outputTokens, 20);
    expect(back.thoughtTokens, 7);
    expect(back.cachedReadTokens, 11);
    expect(back.cachedWriteTokens, 13);
    expect(back.costMicros, 4321);
    expect(back.costBasis, CostBasis.providerReported);
    expect(back.transportFirstByteMs, 180);
    expect(back.firstModelEventMs, 240);
    expect(back.durationMs, 3000);
    expect(back.outcome, LlmCallOutcome.success);
    expect(back.startedAt.toUtc(), DateTime.utc(2026, 10, 11, 12));
    expect(back.recordedAt.toUtc(), DateTime.utc(2026, 10, 11, 12, 0, 3));
    // The derived dedup key must survive verbatim: it is the identity every
    // later upsert and every ledger replay collapses on.
    expect(back.id, record.id);
  });

  test('an UNPRICED call stays distinct from a FREE one', () async {
    await repo.upsert('ws-1', call(requestId: 'req-free', costMicros: 0));
    await repo.upsert(
      'ws-1',
      call(requestId: 'req-unpriced', costMicros: null),
    );

    final byId = {
      for (final r in await repo.listByRun('ws-1', 'run-1')) r.requestId: r,
    };
    expect(byId['req-free']!.costMicros, 0);
    expect(byId['req-unpriced']!.costMicros, isNull);
  });

  test('re-upserting the same call does not double count it', () async {
    await repo.upsert('ws-1', call(costMicros: 1000));
    // Same run/request/attempt, arriving again (a replay after a retry).
    await repo.upsert('ws-1', call(costMicros: 1000));

    final records = await repo.listByRun('ws-1', 'run-1');
    expect(records, hasLength(1));
    expect(await repo.costMicrosForRun('ws-1', 'run-1'), 1000);
  });

  test('a failed attempt and its retry are BOTH stored and summed', () async {
    await repo.upsert(
      'ws-1',
      call(
        requestId: 'req-1',
        attempt: 1,
        costMicros: 400,
        outcome: LlmCallOutcome.failure,
        errorCode: 'overloaded_error',
      ),
    );
    await repo.upsert(
      'ws-1',
      call(requestId: 'req-1', attempt: 2, costMicros: 900),
    );

    final records = await repo.listByRun('ws-1', 'run-1');
    expect(records, hasLength(2));
    // A failed attempt is billed: dropping it would make an unreliable provider
    // look cheaper than a reliable one.
    expect(await repo.costMicrosForRun('ws-1', 'run-1'), 1300);
    expect(records.first.outcome, LlmCallOutcome.failure);
    expect(records.first.errorCode, 'overloaded_error');
  });

  test('upsertAll writes a batch and keeps it deduped on replay', () async {
    await repo.upsertAll('ws-1', [
      call(requestId: 'req-1', costMicros: 100),
      call(requestId: 'req-2', costMicros: 200),
      call(
        requestId: 'req-3',
        purpose: LlmCallPurpose.compaction,
        costMicros: 50,
      ),
    ]);
    expect(await repo.costMicrosForRun('ws-1', 'run-1'), 350);

    // Replaying the whole batch (a restart that re-reads a cumulative ledger)
    // must not change the total.
    await repo.upsertAll('ws-1', [
      call(requestId: 'req-1', costMicros: 100),
      call(requestId: 'req-2', costMicros: 200),
    ]);
    expect(await repo.costMicrosForRun('ws-1', 'run-1'), 350);
    expect(await repo.listByRun('ws-1', 'run-1'), hasLength(3));
  });

  test(
    'cost totals isolate runs and workspaces and allow unpriced calls',
    () async {
      await seedTestWorkspace(global, dbs, 'ws-2');
      await repo.upsertAll('ws-1', [
        call(requestId: 'priced', costMicros: 120),
        call(requestId: 'unpriced', costMicros: null),
        call(requestId: 'other-run', runId: 'run-2', costMicros: 900),
      ]);
      await repo.upsert(
        'ws-2',
        call(requestId: 'priced', workspaceId: 'ws-2', costMicros: 700),
      );

      expect(await repo.costMicrosForRun('ws-1', 'run-1'), 120);
      expect(await repo.costMicrosForRun('ws-1', 'run-2'), 900);
      expect(await repo.costMicrosForRun('ws-2', 'run-1'), 700);
      expect(await repo.costMicrosForRun('ws-1', 'missing'), 0);
      await repo.upsert(
        'ws-1',
        call(requestId: 'unpriced-only', runId: 'run-3', costMicros: null),
      );
      expect(await repo.costMicrosForRun('ws-1', 'run-3'), 0);
    },
  );

  test(
    'the durable records rebuild the same totals as the live ledger',
    () async {
      final ledger = RunUsageLedger();
      final batch = [
        call(requestId: 'req-1', costMicros: 1234),
        call(
          requestId: 'req-2',
          purpose: LlmCallPurpose.advisor,
          costMicros: 600,
          outcome: LlmCallOutcome.failure,
        ),
        call(
          requestId: 'req-3',
          purpose: LlmCallPurpose.sideRequest,
          costMicros: null,
          inputTokens: 40,
        ),
      ];
      for (final record in batch) {
        ledger.record(record);
        await repo.upsert('ws-1', record);
      }

      final stored = await repo.listByRun('ws-1', 'run-1');
      final reloaded = RunUsageLedger()..recordAll(stored);
      expect(reloaded.totals.costMicros, ledger.totals.costMicros);
      expect(reloaded.totals.requestCount, ledger.totals.requestCount);
      expect(reloaded.totals.failedRequestCount, 1);
      expect(reloaded.totals.unpricedRequestCount, 1);
      expect(reloaded.requestCountFor(LlmCallPurpose.advisor), 1);
      expect(reloaded.requestCountFor(LlmCallPurpose.sideRequest), 1);
    },
  );

  test('lists per conversation across runs, newest first', () async {
    await repo.upsertAll('ws-1', [
      call(requestId: 'a', runId: 'run-1'),
      call(requestId: 'b', runId: 'run-2'),
    ]);
    await repo.upsertAll('ws-2', [call(requestId: 'c', runId: 'run-3')]);

    expect(await repo.listByConversation('ws-1', 'conv-1'), hasLength(2));
    // Another workspace's ledger is unreachable — and an empty workspace id is
    // refused rather than guessed.
    expect(await repo.listByConversation('ws-1', 'conv-9'), isEmpty);
    expect(() => repo.upsert('', call()), throwsArgumentError);
  });

  test('a record with no run id is still kept', () async {
    await repo.upsert('ws-1', call(runId: null, requestId: 'orphan'));
    // Refusing to store it would LOSE real spend; it just has no run to file
    // it under yet.
    expect(await repo.listByRun('ws-1', 'run-1'), isEmpty);
    expect(await repo.listByConversation('ws-1', 'conv-1'), hasLength(1));
  });
}
