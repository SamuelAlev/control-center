/// Cache-rebuild economics for history rewrites.
///
/// A compaction or masking pass edits messages IN PLACE, and any byte change
/// invalidates the provider's cached prefix from the first edited block onward.
/// The reclaimed tokens are only half the ledger: the other half is the prefix
/// that must be re-sent (and re-written into the cache) on the next request,
/// plus any tokens the model spends reading an observation back that a mask
/// replaced with a reference.
///
/// *Token Reduction Is Not Cost Reduction* (arxiv 2607.12161) is the cautionary
/// case: a configuration that removed 38.4% of delivered tool-output tokens
/// still raised reported cost 6.8%, because retrieval and changed execution
/// paths more than offset the saving. A fixed reclaimed-token threshold cannot
/// see that; this model can.
///
/// Prices here are RELATIVE, not dollars: the decision only depends on ratios
/// between uncached input, a cache read, a cache write and a retrieval read.
/// The Anthropic-shaped defaults (read ≈ 0.1×, write ≈ 1.25× input) are the
/// conservative reference; a provider whose cache is cheaper makes rewriting
/// more attractive, and the model is passed in rather than hard-coded.
library;

/// Relative prompt-cache pricing used to decide whether a rewrite pays.
///
/// Every field is a multiple of the UNCACHED input price (which is 1.0 by
/// definition). They are ratios, so the absolute token price cancels out.
class ProviderCacheEconomics {
  /// Creates a cache price model.
  ///
  /// [retrievalFirstPrice] is what the FIRST re-ingestion of a masked
  /// observation costs. It is deliberately NOT a cache read: a `read_output`
  /// result is appended as a NEW tool-result message, so it is billed as newly
  /// ingested input (and written into the cache). Null resolves to
  /// [cacheWritePrice], which is the uncached price for providers with no write
  /// premium. [retrievalReusePrice] is what later requests that still carry
  /// that appended result pay; null resolves to [cacheReadPrice].
  const ProviderCacheEconomics({
    this.uncachedInputPrice = 1.0,
    this.cacheReadPrice = 0.1,
    this.cacheWritePrice = 1.25,
    this.retrievalFirstPrice,
    this.retrievalReusePrice,
  }) : assert(cacheReadPrice >= 0, 'cache read price must be >= 0'),
       assert(cacheWritePrice >= 0, 'cache write price must be >= 0');

  /// Price of a prompt token that is NOT served from cache (the unit).
  final double uncachedInputPrice;

  /// Price of a prompt token served from a cache hit.
  final double cacheReadPrice;

  /// Price of a prompt token written into the cache.
  final double cacheWritePrice;

  /// Price of the FIRST retrieval ingestion of a masked observation. Null means
  /// [cacheWritePrice].
  final double? retrievalFirstPrice;

  /// Price of a prompt token on LATER requests that still carry a retrieved
  /// result. Null means [cacheReadPrice].
  final double? retrievalReusePrice;

  /// The resolved first-ingestion price.
  double get effectiveRetrievalFirstPrice =>
      retrievalFirstPrice ?? cacheWritePrice;

  /// The resolved later-reuse price.
  double get effectiveRetrievalReusePrice =>
      retrievalReusePrice ?? cacheReadPrice;

  /// The Anthropic-shaped reference model, used when nothing else is known.
  static const ProviderCacheEconomics defaults = ProviderCacheEconomics();

  /// A model whose cache reads are free (some local servers) — rewriting is
  /// then only judged on the retrieval cost it causes.
  static const ProviderCacheEconomics freeCache = ProviderCacheEconomics(
    cacheReadPrice: 0,
    cacheWritePrice: 1.0,
    retrievalFirstPrice: 1.0,
    retrievalReusePrice: 0,
  );

  /// A per-provider-family guess, so the harness has a sane default without a
  /// pricing table. Matches on the display id the way the provider resolves it.
  static ProviderCacheEconomics forProvider(String? providerId) {
    final id = (providerId ?? '').toLowerCase();
    if (id.isEmpty) {
      return defaults;
    }
    // Long explicit cache with a write premium and a discounted read.
    if (id.contains('anthropic') ||
        id.contains('claude') ||
        id.contains('bedrock') ||
        id.contains('vertex')) {
      return defaults;
    }
    // OpenAI-style automatic prefix caching: reads are discounted, writes are
    // not charged a premium (the write is just an uncached prompt).
    if (id.contains('openai') || id.contains('azure') || id.contains('codex')) {
      return const ProviderCacheEconomics(
        cacheReadPrice: 0.25,
        cacheWritePrice: 1.0,
        retrievalFirstPrice: 1.0,
        retrievalReusePrice: 0.25,
      );
    }
    // Unknown/local: assume caching is available and cheap but not free.
    return const ProviderCacheEconomics(
      cacheReadPrice: 0.25,
      cacheWritePrice: 1.0,
      retrievalFirstPrice: 1.0,
      retrievalReusePrice: 0.25,
    );
  }

  /// Returns a copy with selected fields overridden.
  ProviderCacheEconomics copyWith({
    double? uncachedInputPrice,
    double? cacheReadPrice,
    double? cacheWritePrice,
    double? retrievalFirstPrice,
    double? retrievalReusePrice,
  }) => ProviderCacheEconomics(
    uncachedInputPrice: uncachedInputPrice ?? this.uncachedInputPrice,
    cacheReadPrice: cacheReadPrice ?? this.cacheReadPrice,
    cacheWritePrice: cacheWritePrice ?? this.cacheWritePrice,
    retrievalFirstPrice: retrievalFirstPrice ?? this.retrievalFirstPrice,
    retrievalReusePrice: retrievalReusePrice ?? this.retrievalReusePrice,
  );
}

/// The economics verdict for one candidate rewrite, with the numbers behind it.
///
/// Carried on a compaction/prune result so an experiment can log WHY a pass ran
/// or was skipped rather than re-deriving it from the config.
class HarnessRewriteDecision {
  /// Creates a decision.
  const HarnessRewriteDecision({
    required this.shouldRewrite,
    required this.reclaimedTokens,
    required this.rebuildTokens,
    required this.retrievalTokens,
    required this.expectedSaving,
    required this.expectedCost,
    required this.reason,
  });

  /// No rewrite: nothing to reclaim.
  static const HarnessRewriteDecision nothing = HarnessRewriteDecision(
    shouldRewrite: false,
    reclaimedTokens: 0,
    rebuildTokens: 0,
    retrievalTokens: 0,
    expectedSaving: 0,
    expectedCost: 0,
    reason: 'nothing to reclaim',
  );

  /// Whether the pass should proceed.
  final bool shouldRewrite;

  /// Tokens removed from the live prompt by the pass.
  final int reclaimedTokens;

  /// Tokens of the cached prefix invalidated by the earliest edit, which must
  /// be re-sent and re-written on the next request.
  final int rebuildTokens;

  /// Extra prompt tokens the model is expected to spend reading observations
  /// back through their references.
  final int retrievalTokens;

  /// Expected saving over the remaining calls, in relative price units.
  final double expectedSaving;

  /// Expected cost of the rewrite, in relative price units.
  final double expectedCost;

  /// Human-readable reason, for logs and experiment output.
  final String reason;

  @override
  String toString() =>
      'HarnessRewriteDecision(${shouldRewrite ? 'rewrite' : 'skip'}: '
      'reclaim=$reclaimedTokens rebuild=$rebuildTokens '
      'retrieval=$retrievalTokens saving=${expectedSaving.toStringAsFixed(1)} '
      'cost=${expectedCost.toStringAsFixed(1)} — $reason)';
}

/// Decides whether rewriting history now is worth the cached prefix it breaks.
class CompactionEconomics {
  /// Creates an economics model.
  const CompactionEconomics({
    this.cache = ProviderCacheEconomics.defaults,
    this.assumedRemainingCalls = 8,
    this.minSavingRatio = 1.0,
    this.maskRetrievalFraction = 0.25,
  }) : assert(assumedRemainingCalls >= 0, 'remaining calls must be >= 0'),
       assert(minSavingRatio >= 0, 'min saving ratio must be >= 0'),
       assert(
         maskRetrievalFraction >= 0 && maskRetrievalFraction <= 1,
         'mask retrieval fraction must be in [0, 1]',
       );

  /// The cache price model.
  final ProviderCacheEconomics cache;

  /// How many model calls are expected to remain when a pass runs at a turn
  /// boundary. A rewrite pays back on every subsequent call, so a run near its
  /// end should rewrite less. 8 is a deliberately modest default — long-horizon
  /// coding runs make many more, which makes a rewrite MORE attractive, never
  /// less.
  final int assumedRemainingCalls;

  /// How many times the expected saving must cover the cost before a rewrite is
  /// allowed. 1.0 means break-even; higher is more conservative.
  final double minSavingRatio;

  /// Fraction of a masked observation the model is assumed to re-read through
  /// its handle (0.25 = a quarter of the masked text). Masks are cheaper than
  /// elision precisely because the text is still reachable, so the model may
  /// pay to reach it; the retrieval cost is a fraction of the reclaim, never
  /// the whole of it.
  final double maskRetrievalFraction;

  /// The default model.
  static const CompactionEconomics defaults = CompactionEconomics();

  /// Returns a copy with the cache model narrowed to [providerId].
  CompactionEconomics forProvider(String? providerId) =>
      copyWith(cache: ProviderCacheEconomics.forProvider(providerId));

  /// Returns a copy with selected fields overridden.
  CompactionEconomics copyWith({
    ProviderCacheEconomics? cache,
    int? assumedRemainingCalls,
    double? minSavingRatio,
    double? maskRetrievalFraction,
  }) => CompactionEconomics(
    cache: cache ?? this.cache,
    assumedRemainingCalls: assumedRemainingCalls ?? this.assumedRemainingCalls,
    minSavingRatio: minSavingRatio ?? this.minSavingRatio,
    maskRetrievalFraction: maskRetrievalFraction ?? this.maskRetrievalFraction,
  );

  /// Evaluates a candidate rewrite.
  ///
  /// [reclaimedTokens] is what the pass removes from the live prompt.
  /// [rebuildTokens] is the cache prefix that SURVIVES the rewrite — the
  /// post-rewrite suffix the next request must re-send — not the pre-rewrite
  /// suffix, which would charge a write premium for the tokens being deleted.
  /// [retrievalTokens] estimates re-reads caused by masks.
  /// [remainingCalls] overrides [assumedRemainingCalls] when the caller knows
  /// better (e.g. a run with a known turn ceiling); null uses the default.
  /// [force] bypasses the verdict — set only when the cached prefix is being
  /// rewritten anyway (a compaction that has already paid for the rewrite).
  ///
  /// ASSUMED HORIZON: [remainingCalls] calls still to come; a retrieval lands on
  /// the next one and its appended result persists for the rest.
  HarnessRewriteDecision evaluate({
    required int reclaimedTokens,
    int rebuildTokens = 0,
    int retrievalTokens = 0,
    int? remainingCalls,
    bool force = false,
  }) {
    if (reclaimedTokens <= 0) {
      return HarnessRewriteDecision.nothing;
    }
    final calls = remainingCalls ?? assumedRemainingCalls;
    // The reclaimed tokens would have been billed at the cache-read price on
    // each remaining call (they lived inside the cached prefix); removing them
    // saves that much per call.
    final perCallSaving = cache.cacheReadPrice * reclaimedTokens;
    final saving = perCallSaving * calls;
    // Rebuilding the invalidated prefix costs the write premium minus the read
    // discount it would have cost had nothing changed, paid once, on the tokens
    // that SURVIVE.
    final rebuildCost =
        (cache.cacheWritePrice - cache.cacheReadPrice) * rebuildTokens;
    // A retrieved observation is appended as a NEW result, so its first
    // ingestion is priced as newly written input, not as a cache read; only
    // later requests that still carry it pay the reuse (cache-read) price.
    final retrievalCost =
        retrievalTokens * cache.effectiveRetrievalFirstPrice +
        retrievalTokens * cache.effectiveRetrievalReusePrice * (calls - 1);
    final cost = (rebuildCost > 0 ? rebuildCost : 0.0) + retrievalCost;

    if (force) {
      return HarnessRewriteDecision(
        shouldRewrite: true,
        reclaimedTokens: reclaimedTokens,
        rebuildTokens: rebuildTokens,
        retrievalTokens: retrievalTokens,
        expectedSaving: saving,
        expectedCost: cost,
        reason: 'forced (prefix already being rewritten)',
      );
    }
    final should = saving >= cost * minSavingRatio;
    return HarnessRewriteDecision(
      shouldRewrite: should,
      reclaimedTokens: reclaimedTokens,
      rebuildTokens: rebuildTokens,
      retrievalTokens: retrievalTokens,
      expectedSaving: saving,
      expectedCost: cost,
      reason: should
          ? 'saving ${saving.toStringAsFixed(0)} >= '
                'cost ${cost.toStringAsFixed(0)} over $calls calls'
          : 'saving ${saving.toStringAsFixed(0)} < '
                'cost ${cost.toStringAsFixed(0)} over $calls calls',
    );
  }
}
