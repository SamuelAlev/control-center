import 'package:cc_domain/core/domain/entities/llm_call_record.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';

/// Exact totals over a set of [LlmCallRecord]s.
///
/// Every figure is an INTEGER (token counts and micro-USD) so a long run that
/// makes hundreds of sub-cent calls sums without drift; the only floating
/// conversion happens at the display edge.
class RunUsageTotals {
  /// Creates totals.
  const RunUsageTotals({
    this.requestCount = 0,
    this.failedRequestCount = 0,
    this.cancelledRequestCount = 0,
    this.unpricedRequestCount = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.costMicros = 0,
    this.costBasis = CostBasis.estimated,
    this.durationMs = 0,
    this.timedRequestCount = 0,
    this.byPurpose = const <LlmCallPurpose, RunUsageTotals>{},
  });

  /// Totals with nothing recorded.
  static const empty = RunUsageTotals();

  /// Number of recorded requests (including failures).
  final int requestCount;

  /// Requests that ended in failure (their partial usage is still counted).
  final int failedRequestCount;

  /// Requests cancelled before completion.
  final int cancelledRequestCount;

  /// Requests with no price available (cost unknown, not zero).
  final int unpricedRequestCount;

  /// Non-cached input tokens.
  final int inputTokens;

  /// Output tokens.
  final int outputTokens;

  /// Reasoning tokens.
  final int thoughtTokens;

  /// Cache-hit read tokens.
  final int cachedReadTokens;

  /// Cache-write tokens.
  final int cachedWriteTokens;

  /// Exact cost in micro-USD over priced requests.
  final int costMicros;

  /// Combined basis of [costMicros].
  final CostBasis costBasis;

  /// Summed call duration in milliseconds over the requests that MEASURED one.
  ///
  /// A sum over auxiliary calls is what makes "compaction spent 42s of this
  /// run" answerable — the thing per-call latency percentiles cannot express.
  /// Divided by [timedRequestCount] it is a mean, never presented as a
  /// percentile.
  final int durationMs;

  /// Requests that reported a duration (the denominator of [durationMs]).
  final int timedRequestCount;

  /// Same totals restricted to one purpose, appended here for the rollup.
  final Map<LlmCallPurpose, RunUsageTotals> byPurpose;

  /// Sum of all token axes.
  int get totalTokens =>
      inputTokens +
      outputTokens +
      thoughtTokens +
      cachedReadTokens +
      cachedWriteTokens;

  /// Cost in US dollars.
  double get costUsd => costMicros / 1000000;

  /// Totals for one purpose, or [empty] when that purpose made no calls.
  RunUsageTotals forPurpose(LlmCallPurpose purpose) =>
      byPurpose[purpose] ?? RunUsageTotals.empty;

  /// Totals as a [RunUsage] (cost carried at exact precision).
  RunUsage toUsage() => RunUsage(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    thoughtTokens: thoughtTokens,
    cachedReadTokens: cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens,
    estimatedCostCents: (costMicros / 10000).round(),
    costMicros: costMicros,
    costBasis: costBasis,
  );

  /// Totals as a [RunCost], with optional latency axes carried through.
  RunCost toRunCost({int? durationMs, int? timeToFirstTokenMs}) => toUsage()
      .toCost(durationMs: durationMs, timeToFirstTokenMs: timeToFirstTokenMs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunUsageTotals &&
          requestCount == other.requestCount &&
          failedRequestCount == other.failedRequestCount &&
          cancelledRequestCount == other.cancelledRequestCount &&
          unpricedRequestCount == other.unpricedRequestCount &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          thoughtTokens == other.thoughtTokens &&
          cachedReadTokens == other.cachedReadTokens &&
          cachedWriteTokens == other.cachedWriteTokens &&
          costMicros == other.costMicros &&
          costBasis == other.costBasis &&
          durationMs == other.durationMs &&
          timedRequestCount == other.timedRequestCount &&
          byPurpose.length == other.byPurpose.length &&
          byPurpose.entries.every((e) => other.byPurpose[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    requestCount,
    failedRequestCount,
    cancelledRequestCount,
    unpricedRequestCount,
    inputTokens,
    outputTokens,
    thoughtTokens,
    cachedReadTokens,
    cachedWriteTokens,
    costMicros,
    costBasis,
    durationMs,
    timedRequestCount,
    Object.hashAll(
      LlmCallPurpose.values.map((p) => Object.hash(p, byPurpose[p])),
    ),
  );
}

/// In-run accumulator of [LlmCallRecord]s with EXACTLY-ONCE accounting.
///
/// The loop holds one ledger per run. Every completed, failed, retried or
/// auxiliary call is recorded here at the boundary, and [record] answers
/// whether the call was new — a duplicate delivery (a replayed adapter result,
/// a cumulative CLI ledger re-emitted on resume) is refused rather than added,
/// so a request is never counted twice on its way to the run's cost.
///
/// Deterministic-key dedup is by [LlmCallRecord.id], not by object identity:
/// the same call re-reported with richer data still counts once.
class RunUsageLedger {
  /// Creates an empty ledger.
  RunUsageLedger();

  final Map<String, LlmCallRecord> _records = <String, LlmCallRecord>{};
  RunUsageTotals? _cachedTotals;

  /// Records [record], returning true when it was new.
  ///
  /// A duplicate id replaces the stored record (last report wins for that ONE
  /// call — e.g. a failure report upgraded by a late cumulative reading) but
  /// does not add to the totals a second time.
  bool record(LlmCallRecord record) {
    final isNew = !_records.containsKey(record.id);
    _records[record.id] = record;
    _cachedTotals = null;
    return isNew;
  }

  /// Records every record in [records], returning how many were new.
  int recordAll(Iterable<LlmCallRecord> records) {
    var added = 0;
    for (final call in records) {
      if (record(call)) {
        added++;
      }
    }
    return added;
  }

  /// True when nothing was recorded.
  bool get isEmpty => _records.isEmpty;

  /// Number of distinct calls recorded.
  int get length => _records.length;

  /// The recorded calls, oldest first.
  List<LlmCallRecord> get records {
    final list = _records.values.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return List.unmodifiable(list);
  }

  /// Exact totals over every recorded call (failures and retries included).
  RunUsageTotals get totals => _cachedTotals ??= _compute();

  /// Totals for one purpose.
  RunUsageTotals totalsFor(LlmCallPurpose purpose) =>
      totals.forPurpose(purpose);

  /// Requests recorded under one purpose.
  int requestCountFor(LlmCallPurpose purpose) =>
      totals.forPurpose(purpose).requestCount;

  /// The run's usage as a [RunCost] (no latency axes: those are read off the
  /// run's `RunLatencyProfile`).
  RunCost toRunCost({int? durationMs, int? timeToFirstTokenMs}) =>
      totals.toRunCost(
        durationMs: durationMs,
        timeToFirstTokenMs: timeToFirstTokenMs,
      );

  RunUsageTotals _compute() {
    var requestCount = 0;
    var failed = 0;
    var cancelled = 0;
    var unpriced = 0;
    var input = 0;
    var output = 0;
    var thought = 0;
    var cacheRead = 0;
    var cacheWrite = 0;
    var costMicros = 0;
    CostBasis? basis;
    var durationMs = 0;
    var timedCount = 0;
    final perPurpose = <LlmCallPurpose, _PurposeAccumulator>{};

    for (final call in _records.values) {
      requestCount++;
      if (call.outcome == LlmCallOutcome.failure) {
        failed++;
      } else if (call.outcome == LlmCallOutcome.cancelled) {
        cancelled++;
      }
      if (call.costMicros == null) {
        unpriced++;
      }
      input += call.inputTokens;
      output += call.outputTokens;
      thought += call.thoughtTokens;
      cacheRead += call.cachedReadTokens;
      cacheWrite += call.cachedWriteTokens;
      // An unpriced call contributes no cost, but its TOKENS still count — the
      // text it processed was real even when the price is unknown.
      costMicros += call.costMicros ?? 0;
      basis = basis == null
          ? call.costBasis
          : CostBasis.merge(basis, call.costBasis);
      final callDuration = call.durationMs;
      if (callDuration != null) {
        durationMs += callDuration;
        timedCount++;
      }
      perPurpose.putIfAbsent(call.purpose, _PurposeAccumulator.new).add(call);
    }

    return RunUsageTotals(
      requestCount: requestCount,
      failedRequestCount: failed,
      cancelledRequestCount: cancelled,
      unpricedRequestCount: unpriced,
      inputTokens: input,
      outputTokens: output,
      thoughtTokens: thought,
      cachedReadTokens: cacheRead,
      cachedWriteTokens: cacheWrite,
      costMicros: costMicros,
      costBasis: basis ?? CostBasis.estimated,
      durationMs: durationMs,
      timedRequestCount: timedCount,
      byPurpose: {
        for (final entry in perPurpose.entries) entry.key: entry.value.build(),
      },
    );
  }
}

/// Mutable per-purpose accumulator, folded into an immutable [RunUsageTotals].
class _PurposeAccumulator {
  int requestCount = 0;
  int failed = 0;
  int cancelled = 0;
  int unpriced = 0;
  int input = 0;
  int output = 0;
  int thought = 0;
  int cacheRead = 0;
  int cacheWrite = 0;
  int costMicros = 0;
  CostBasis? basis;
  int durationMs = 0;
  int timedRequestCount = 0;

  void add(LlmCallRecord record) {
    requestCount++;
    if (record.outcome == LlmCallOutcome.failure) {
      failed++;
    } else if (record.outcome == LlmCallOutcome.cancelled) {
      cancelled++;
    }
    if (record.costMicros == null) {
      unpriced++;
    }
    input += record.inputTokens;
    output += record.outputTokens;
    thought += record.thoughtTokens;
    cacheRead += record.cachedReadTokens;
    cacheWrite += record.cachedWriteTokens;
    costMicros += record.costMicros ?? 0;
    basis = basis == null
        ? record.costBasis
        : CostBasis.merge(basis!, record.costBasis);
    final callDuration = record.durationMs;
    if (callDuration != null) {
      durationMs += callDuration;
      timedRequestCount++;
    }
  }

  RunUsageTotals build() => RunUsageTotals(
    requestCount: requestCount,
    failedRequestCount: failed,
    cancelledRequestCount: cancelled,
    unpricedRequestCount: unpriced,
    inputTokens: input,
    outputTokens: output,
    thoughtTokens: thought,
    cachedReadTokens: cacheRead,
    cachedWriteTokens: cacheWrite,
    costMicros: costMicros,
    costBasis: basis ?? CostBasis.estimated,
    durationMs: durationMs,
    timedRequestCount: timedRequestCount,
  );
}
