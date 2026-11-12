import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show AgentRunLog;

/// How a cost figure was obtained.
///
/// A bare money integer could not say this, and the difference is
/// load-bearing: a subscription CLI's `total_cost_usd` is a NOTIONAL
/// list-price figure that bills nobody, an API response's reported cost is
/// what was actually charged, and a locally-priced token count is an estimate.
/// Summing them into one number without recording which is which makes an
/// optimization look cheaper purely by shifting work between bases.
enum CostBasis {
  /// Computed locally from token counts against a price catalog. The only
  /// basis that is a genuine estimate rather than a reported figure.
  estimated,

  /// Reported by the provider for the request (e.g. a gateway's actual charge).
  providerReported,

  /// Derived from a subscription CLI's own cumulative ledger. Notional — the
  /// account is billed a flat fee, not this amount.
  subscription,

  /// A merge of runs or calls recorded under different bases; the total is
  /// exact arithmetic over mixed provenance and MUST NOT be reported as any
  /// single basis.
  mixed,

  /// Some spend was unobservable or unpriced. The numeric total is only the
  /// known lower bound, not a free run or a complete cost estimate.
  unknown;

  /// Parses a wire/storage spelling, accepting both `providerReported` and
  /// `provider_reported`. Unknown values answer [estimated] — the most
  /// conservative basis (it never claims a figure was reported).
  static CostBasis fromWire(String? value) {
    switch (value) {
      case 'providerReported':
      case 'provider_reported':
        return CostBasis.providerReported;
      case 'subscription':
        return CostBasis.subscription;
      case 'mixed':
        return CostBasis.mixed;
      case 'unknown':
        return CostBasis.unknown;
      case 'estimated':
      default:
        return CostBasis.estimated;
    }
  }

  /// Combines two bases for a summed figure.
  ///
  /// Equal bases stay themselves; anything summed with a genuinely different
  /// basis answers [mixed] rather than silently promoting one basis to speak
  /// for the whole — the arithmetic is still exact, only the provenance label
  /// stops being single-valued.
  static CostBasis merge(CostBasis a, CostBasis b) {
    if (a == CostBasis.unknown || b == CostBasis.unknown) {
      return CostBasis.unknown;
    }
    if (a == b) {
      return a;
    }
    return CostBasis.mixed;
  }
}

/// Per-run token usage and cost breakdown.
class RunCost {
  /// Creates a [RunCost] with token usage and cost details.
  const RunCost({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.costMicros = 0,
    this.costBasis = CostBasis.estimated,
    this.durationMs,
    this.timeToFirstTokenMs,
  });

  /// Number of input tokens consumed.
  final int inputTokens;

  /// Number of output tokens produced.
  final int outputTokens;

  /// Tokens used for thinking / reasoning output.
  final int thoughtTokens;

  /// Cache-hit read tokens (discounted by the model provider).
  final int cachedReadTokens;

  /// Cache-hit write tokens (discounted by the model provider).
  final int cachedWriteTokens;

  /// Exact cost in micro-dollars (1 USD = 1,000,000), or `0` when no precise
  /// figure was recorded.
  ///
  /// Micro-dollars are the only money unit: a priced request costing a
  /// fraction of a cent still adds to every total and budget it reaches, so
  /// hundreds of small auxiliary calls sum to what they really cost. Cents
  /// exist only in the display formatter.
  final int costMicros;

  /// How [costMicros] was obtained.
  final CostBasis costBasis;

  /// Cost in US dollars, from [costMicros].
  double get costUsd => costMicros / 1000000;

  /// Total wall-clock duration in milliseconds, if measured.
  final int? durationMs;

  /// Time from request start to the first token/delta in milliseconds, ONLY
  /// when a provider or transport observed it.
  ///
  /// Semantics changed deliberately: rows written before the stage-timing
  /// instrumentation carried a value derived from the first VISIBLE TEXT event
  /// (context assembly + startup included, and unset entirely for a
  /// thinking-first or tool-first run). New rows carry a real provider TTFB/TTFT
  /// or null. A reader averaging old and new rows together is averaging two
  /// different measurements — `RunLatencyProfile` carries the typed boundaries
  /// for anything that must be exact.
  final int? timeToFirstTokenMs;

  /// Unique token count; reasoning is already included in [outputTokens].
  int get totalTokens =>
      inputTokens + outputTokens + cachedReadTokens + cachedWriteTokens;

  /// Merges two [RunCost] instances, summing numeric fields.
  ///
  /// Cost merges exactly (micro-USD integers) and the basis is combined rather
  /// than overwritten, so a total spanning an estimated side request and a
  /// provider-reported main call reads [CostBasis.mixed] instead of
  /// misrepresenting one half.
  RunCost operator +(RunCost other) {
    if (other == zero) {
      return this;
    }
    if (this == zero) {
      return other;
    }
    final micros = costMicros + other.costMicros;
    return RunCost(
      inputTokens: inputTokens + other.inputTokens,
      outputTokens: outputTokens + other.outputTokens,
      thoughtTokens: thoughtTokens + other.thoughtTokens,
      cachedReadTokens: cachedReadTokens + other.cachedReadTokens,
      cachedWriteTokens: cachedWriteTokens + other.cachedWriteTokens,
      costMicros: micros,
      costBasis: _isEmpty
          ? other.costBasis
          : other._isEmpty
          ? costBasis
          : CostBasis.merge(costBasis, other.costBasis),
      durationMs: durationMs != null && other.durationMs != null
          ? durationMs! + other.durationMs!
          : (durationMs ?? other.durationMs),
      timeToFirstTokenMs: timeToFirstTokenMs ?? other.timeToFirstTokenMs,
    );
  }

  bool get _isEmpty =>
      totalTokens == 0 && costMicros == 0 && costBasis != CostBasis.unknown;

  /// Empty [RunCost] with all values at zero.
  static const zero = RunCost();

  /// Returns a copy with the given overrides.
  ///
  /// Deliberately not null-removing: a cost figure that was observed is never
  /// "unobserved" again, so passing null keeps the existing value.
  RunCost copyWith({
    int? inputTokens,
    int? outputTokens,
    int? thoughtTokens,
    int? cachedReadTokens,
    int? cachedWriteTokens,
    int? costMicros,
    CostBasis? costBasis,
    int? durationMs,
    int? timeToFirstTokenMs,
  }) => RunCost(
    inputTokens: inputTokens ?? this.inputTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    thoughtTokens: thoughtTokens ?? this.thoughtTokens,
    cachedReadTokens: cachedReadTokens ?? this.cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens ?? this.cachedWriteTokens,
    costMicros: costMicros ?? this.costMicros,
    costBasis: costBasis ?? this.costBasis,
    durationMs: durationMs ?? this.durationMs,
    timeToFirstTokenMs: timeToFirstTokenMs ?? this.timeToFirstTokenMs,
  );

  @override
  /// Structural equality.
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunCost &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          thoughtTokens == other.thoughtTokens &&
          cachedReadTokens == other.cachedReadTokens &&
          cachedWriteTokens == other.cachedWriteTokens &&
          costMicros == other.costMicros &&
          costBasis == other.costBasis &&
          durationMs == other.durationMs &&
          timeToFirstTokenMs == other.timeToFirstTokenMs;

  @override
  /// Hash based on all fields.
  int get hashCode => Object.hash(
    inputTokens,
    outputTokens,
    thoughtTokens,
    cachedReadTokens,
    cachedWriteTokens,
    costMicros,
    costBasis,
    durationMs,
    timeToFirstTokenMs,
  );
}

/// Structured usage report from an adapter, aggregated into [RunCost]
/// for persistence on [AgentRunLog].
class RunUsage {
  /// Creates a [RunUsage] with token counts from an adapter.
  const RunUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.costMicros = 0,
    this.costBasis = CostBasis.estimated,
  });

  /// Number of input tokens.
  final int inputTokens;

  /// Number of output tokens.
  final int outputTokens;

  /// Tokens used for thinking output.
  final int thoughtTokens;

  /// Cache-hit read tokens.
  final int cachedReadTokens;

  /// Cache-hit write tokens.
  final int cachedWriteTokens;

  /// Exact cost in micro-USD (`1e-6` USD), or `0` when unpriced.
  final int costMicros;

  /// How the cost figures were obtained.
  final CostBasis costBasis;

  /// Unique token count; reasoning is already included in [outputTokens].
  int get totalTokens =>
      inputTokens + outputTokens + cachedReadTokens + cachedWriteTokens;

  /// Merges two reports additively (token axes and exact cost), combining the
  /// cost basis the same way [RunCost.operator+] does.
  RunUsage operator +(RunUsage other) {
    final micros = costMicros + other.costMicros;
    return RunUsage(
      inputTokens: inputTokens + other.inputTokens,
      outputTokens: outputTokens + other.outputTokens,
      thoughtTokens: thoughtTokens + other.thoughtTokens,
      cachedReadTokens: cachedReadTokens + other.cachedReadTokens,
      cachedWriteTokens: cachedWriteTokens + other.cachedWriteTokens,
      costMicros: micros,
      costBasis: _isEmpty
          ? other.costBasis
          : other._isEmpty
          ? costBasis
          : CostBasis.merge(costBasis, other.costBasis),
    );
  }

  bool get _isEmpty =>
      totalTokens == 0 && costMicros == 0 && costBasis != CostBasis.unknown;

  /// Converts to [RunCost] for persistence on [AgentRunLog].
  RunCost toCost({int? durationMs, int? timeToFirstTokenMs}) => RunCost(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    thoughtTokens: thoughtTokens,
    cachedReadTokens: cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens,
    costMicros: costMicros,
    costBasis: costBasis,
    durationMs: durationMs,
    timeToFirstTokenMs: timeToFirstTokenMs,
  );

  /// Empty [RunUsage] with all values at zero.
  static const zero = RunUsage();

  @override
  /// Structural equality.
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunUsage &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          thoughtTokens == other.thoughtTokens &&
          cachedReadTokens == other.cachedReadTokens &&
          cachedWriteTokens == other.cachedWriteTokens &&
          costMicros == other.costMicros &&
          costBasis == other.costBasis;

  @override
  /// Hash based on all fields.
  int get hashCode => Object.hash(
    inputTokens,
    outputTokens,
    thoughtTokens,
    cachedReadTokens,
    cachedWriteTokens,
    costMicros,
    costBasis,
  );
}
