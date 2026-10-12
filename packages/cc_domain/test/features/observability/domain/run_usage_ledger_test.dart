import 'package:cc_domain/core/domain/entities/llm_call_record.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/run_usage_ledger.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 1, 1, 12);

/// Builds a call record for the ledger with only the axes a test cares about
/// overridden.
LlmCallRecord _call({
  required String requestId,
  LlmCallPurpose purpose = LlmCallPurpose.main,
  DateTime? startedAt,
  int attempt = 1,
  int inputTokens = 0,
  int outputTokens = 0,
  int thoughtTokens = 0,
  int cachedReadTokens = 0,
  int cachedWriteTokens = 0,
  int? costMicros,
  CostBasis costBasis = CostBasis.estimated,
  LlmCallOutcome outcome = LlmCallOutcome.success,
  int? durationMs,
}) {
  final start = startedAt ?? _t0;
  return LlmCallRecord(
    requestId: requestId,
    purpose: purpose,
    provider: 'anthropic',
    modelId: 'claude-sonnet',
    startedAt: start,
    recordedAt: start,
    runId: 'run-1',
    attempt: attempt,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    thoughtTokens: thoughtTokens,
    cachedReadTokens: cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens,
    costMicros: costMicros,
    costBasis: costBasis,
    outcome: outcome,
    durationMs: durationMs,
  );
}

/// Covers [RunUsageLedger]: exactly-once accounting, counting of failures and
/// cancellations, unpriced-but-observed tokens, per-purpose attribution, basis
/// merging and the oldest-first `records` ordering.
void main() {
  // ---------------------------------------------------------------------------
  // exactly-once accounting
  // ---------------------------------------------------------------------------
  group('RunUsageLedger.record', () {
    // Protects: a call delivered twice is counted once — the whole point of the
    // deterministic dedup key.
    test('recording the same call twice returns true then false', () {
      final ledger = RunUsageLedger();
      final call = _call(requestId: 'req-1', inputTokens: 100, costMicros: 500);

      expect(ledger.record(call), isTrue);
      expect(ledger.record(call), isFalse);
      expect(ledger.length, 1);
      expect(ledger.totals.requestCount, 1);
      expect(ledger.totals.inputTokens, 100);
      expect(ledger.totals.costMicros, 500);
    });

    // Protects: a re-report with richer data replaces that one call (latest
    // report wins) but is never ADDED a second time — no double billing.
    test('a re-report replaces the record without double-counting', () {
      final ledger = RunUsageLedger();
      final first = _call(
        requestId: 'req-1',
        inputTokens: 100,
        costMicros: 500,
      );
      final richer = _call(
        requestId: 'req-1',
        inputTokens: 100,
        outputTokens: 10,
        costMicros: 500,
      );

      expect(ledger.record(first), isTrue);
      expect(ledger.record(richer), isFalse);
      expect(ledger.length, 1);
      expect(ledger.totals.requestCount, 1);
      expect(ledger.totals.inputTokens, 100);
      expect(ledger.totals.outputTokens, 10);
      expect(ledger.totals.costMicros, 500);
      expect(ledger.records.single, richer);
    });

    // Protects: a retry is a distinct billable call, not a deduped duplicate.
    test('a distinct attempt is counted separately', () {
      final ledger = RunUsageLedger();
      expect(ledger.record(_call(requestId: 'req-1', costMicros: 100)), isTrue);
      expect(
        ledger.record(_call(requestId: 'req-1', attempt: 2, costMicros: 100)),
        isTrue,
      );
      expect(ledger.totals.requestCount, 2);
      expect(ledger.totals.costMicros, 200);
    });

    // Protects: recordAll reports how many calls were new and dedups within the
    // batch itself.
    test('recordAll counts new calls and dedups within the batch', () {
      final ledger = RunUsageLedger();
      final a = _call(requestId: 'a');
      final b = _call(requestId: 'b');
      expect(ledger.recordAll([a, b, a]), 2);
      expect(ledger.totals.requestCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // failures and cancellations
  // ---------------------------------------------------------------------------
  group('RunUsageLedger failure accounting', () {
    // Protects: a failed or cancelled call still spent real money and is
    // counted, with its partial tokens still summed.
    test('failed and cancelled calls are counted and keep their tokens', () {
      final ledger = RunUsageLedger();
      final added = ledger.recordAll([
        _call(
          requestId: 'ok',
          inputTokens: 10,
          outputTokens: 5,
          costMicros: 100,
        ),
        _call(
          requestId: 'boom',
          inputTokens: 20,
          costMicros: 50,
          outcome: LlmCallOutcome.failure,
        ),
        _call(
          requestId: 'stop',
          inputTokens: 4,
          costMicros: 25,
          outcome: LlmCallOutcome.cancelled,
        ),
      ]);

      final totals = ledger.totals;
      expect(added, 3);
      expect(totals.requestCount, 3);
      expect(totals.failedRequestCount, 1);
      expect(totals.cancelledRequestCount, 1);
      expect(totals.totalTokens, 39);
      expect(totals.inputTokens, 34);
      expect(totals.costMicros, 175);
    });
  });

  // ---------------------------------------------------------------------------
  // unpriced calls
  // ---------------------------------------------------------------------------
  group('RunUsageLedger unpriced calls', () {
    // Protects: an unknown price is not a zero price — the tokens still count,
    // the cost is 0, and the call is flagged as unpriced.
    test('an unpriced call adds tokens but no cost', () {
      final ledger = RunUsageLedger();
      ledger.record(
        _call(requestId: 'priced', inputTokens: 10, costMicros: 40),
      );
      ledger.record(_call(requestId: 'unpriced', inputTokens: 12));

      final totals = ledger.totals;
      expect(totals.requestCount, 2);
      expect(totals.unpricedRequestCount, 1);
      expect(totals.inputTokens, 22);
      expect(totals.costMicros, 40);
      expect(totals.costBasis, CostBasis.estimated);
    });

    // Protects: a genuinely free call (cost 0) is priced, not unpriced —
    // null and zero must stay distinguishable in the rollup.
    test('a genuinely free call is priced, not unpriced', () {
      final ledger = RunUsageLedger();
      ledger.record(_call(requestId: 'free', costMicros: 0));

      expect(ledger.totals.requestCount, 1);
      expect(ledger.totals.unpricedRequestCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // per-purpose attribution
  // ---------------------------------------------------------------------------
  group('RunUsageLedger totalsFor', () {
    // Protects: work moved off the main thread (compaction, advisor, side
    // request, subagent) is attributed to its own purpose, not folded into main.
    test('attributes each purpose separately from main', () {
      final ledger = RunUsageLedger();
      ledger.recordAll([
        _call(
          requestId: 'main-1',
          purpose: LlmCallPurpose.main,
          inputTokens: 1,
        ),
        _call(
          requestId: 'comp',
          purpose: LlmCallPurpose.compaction,
          inputTokens: 2,
        ),
        _call(
          requestId: 'adv',
          purpose: LlmCallPurpose.advisor,
          inputTokens: 3,
        ),
        _call(
          requestId: 'side',
          purpose: LlmCallPurpose.sideRequest,
          inputTokens: 4,
        ),
        _call(
          requestId: 'sub',
          purpose: LlmCallPurpose.subagent,
          inputTokens: 5,
        ),
      ]);

      expect(ledger.totalsFor(LlmCallPurpose.main).totalTokens, 1);
      expect(ledger.totalsFor(LlmCallPurpose.compaction).totalTokens, 2);
      expect(ledger.totalsFor(LlmCallPurpose.advisor).totalTokens, 3);
      expect(ledger.totalsFor(LlmCallPurpose.sideRequest).totalTokens, 4);
      expect(ledger.totalsFor(LlmCallPurpose.subagent).totalTokens, 5);
      expect(ledger.requestCountFor(LlmCallPurpose.sideRequest), 1);
      expect(ledger.totals.requestCount, 5);
      expect(ledger.totals.totalTokens, 15);
    });

    // Protects: a purpose with no calls is empty, not a share of another
    // purpose's totals.
    test('a purpose with no calls reports empty totals', () {
      final ledger = RunUsageLedger();
      ledger.record(
        _call(
          requestId: 'main-1',
          purpose: LlmCallPurpose.main,
          inputTokens: 7,
        ),
      );

      expect(ledger.totalsFor(LlmCallPurpose.advisor), RunUsageTotals.empty);
      expect(ledger.requestCountFor(LlmCallPurpose.advisor), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // costBasis merging
  // ---------------------------------------------------------------------------
  group('RunUsageLedger costBasis', () {
    // Protects: a total spanning an estimate and a subscription ledger is
    // labeled mixed, so it is never reported as either basis alone.
    test('an estimated and a subscription call merge to mixed', () {
      final ledger = RunUsageLedger();
      ledger.record(
        _call(requestId: 'est', costMicros: 10, costBasis: CostBasis.estimated),
      );
      ledger.record(
        _call(
          requestId: 'sub',
          costMicros: 20,
          costBasis: CostBasis.subscription,
        ),
      );

      expect(ledger.totals.costBasis, CostBasis.mixed);
      expect(ledger.totals.costMicros, 30);
    });

    // Protects: like bases do not spuriously degrade to mixed.
    test('all-estimated calls keep the estimated basis', () {
      final ledger = RunUsageLedger();
      ledger.record(_call(requestId: 'a', costMicros: 10));
      ledger.record(_call(requestId: 'b', costMicros: 20));

      expect(ledger.totals.costBasis, CostBasis.estimated);
    });

    // Protects: an empty ledger makes no claim — it reports the conservative
    // estimated basis rather than a fabricated mixed.
    test('an empty ledger reports the estimated basis', () {
      final ledger = RunUsageLedger();
      expect(ledger.isEmpty, isTrue);
      expect(ledger.length, 0);
      expect(ledger.totals.requestCount, 0);
      expect(ledger.totals.costBasis, CostBasis.estimated);
    });
  });

  // ---------------------------------------------------------------------------
  // auxiliary timings
  // ---------------------------------------------------------------------------
  group('RunUsageLedger auxiliary timings', () {
    // Protects: compaction and advisor TIME is attributable separately from
    // main-thread time, and a call that measured nothing does not enter the
    // denominator.
    test('sums durations per purpose and counts only measured calls', () {
      final ledger = RunUsageLedger();
      ledger.record(_call(requestId: 'main-1', durationMs: 1000));
      ledger.record(
        _call(
          requestId: 'compact-1',
          purpose: LlmCallPurpose.compaction,
          durationMs: 4200,
        ),
      );
      ledger.record(
        _call(
          requestId: 'compact-2',
          purpose: LlmCallPurpose.compaction,
          durationMs: 800,
        ),
      );
      // No duration reported: it must not be counted as a zero-length call.
      ledger.record(
        _call(requestId: 'compact-3', purpose: LlmCallPurpose.compaction),
      );

      expect(ledger.totals.durationMs, 6000);
      expect(ledger.totals.timedRequestCount, 3);
      expect(ledger.totalsFor(LlmCallPurpose.compaction).durationMs, 5000);
      expect(ledger.totalsFor(LlmCallPurpose.compaction).timedRequestCount, 2);
      expect(ledger.totalsFor(LlmCallPurpose.main).durationMs, 1000);
      // The unmeasured call is still counted as a REQUEST, just not as time.
      expect(ledger.requestCountFor(LlmCallPurpose.compaction), 3);
    });
  });

  // ---------------------------------------------------------------------------
  // ordering
  // ---------------------------------------------------------------------------
  group('RunUsageLedger.records', () {
    // Protects: a replay/display sees the calls oldest-first regardless of the
    // order they were reported in.
    test('orders records by startedAt, oldest first', () {
      final ledger = RunUsageLedger();
      ledger.record(
        _call(
          requestId: 'late',
          startedAt: DateTime.utc(2026, 1, 1, 12, 0, 30),
        ),
      );
      ledger.record(
        _call(
          requestId: 'early',
          startedAt: DateTime.utc(2026, 1, 1, 12, 0, 0),
        ),
      );
      ledger.record(
        _call(
          requestId: 'middle',
          startedAt: DateTime.utc(2026, 1, 1, 12, 0, 10),
        ),
      );

      expect(ledger.records.map((r) => r.requestId).toList(), [
        'early',
        'middle',
        'late',
      ]);
    });
  });
}
