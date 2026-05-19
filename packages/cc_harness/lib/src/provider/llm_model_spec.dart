import 'package:cc_harness/src/provider/reasoning_effort.dart';

/// Per-million-token pricing for a model, in USD.
///
/// The kernel's minimal counterpart to Control Center's models.dev-backed
/// catalog entry: enough to price a run and budget a strategy without
/// importing the host's `ModelInfo`. Dispatch maps its catalog type onto this
/// at the boundary.
class LlmModelPricing {
  /// Creates a pricing spec (all rates USD per 1M tokens).
  const LlmModelPricing({
    this.inputPerMTok = 0,
    this.outputPerMTok = 0,
    this.cacheReadPerMTok,
    this.cacheWritePerMTok,
  });

  /// Non-cached input rate.
  final double inputPerMTok;

  /// Output (completion) rate.
  final double outputPerMTok;

  /// Cache-read rate; null falls back to [inputPerMTok].
  final double? cacheReadPerMTok;

  /// Cache-write rate; null falls back to [inputPerMTok].
  final double? cacheWritePerMTok;

  /// Estimated USD cost for a token breakdown (cache-aware).
  double estimateUsd({
    int inputTokens = 0,
    int outputTokens = 0,
    int cacheReadTokens = 0,
    int cacheWriteTokens = 0,
  }) =>
      inputTokens * inputPerMTok / 1e6 +
      outputTokens * outputPerMTok / 1e6 +
      cacheReadTokens * (cacheReadPerMTok ?? inputPerMTok) / 1e6 +
      cacheWriteTokens * (cacheWritePerMTok ?? inputPerMTok) / 1e6;
}

/// The kernel's minimal description of an LLM model: identity, window sizes,
/// supported reasoning effort, and pricing.
///
/// This is deliberately smaller than Control Center's `ModelInfo` (no vendor
/// metadata, no modality flags). The host resolves its catalog entry and maps
/// it onto this spec when handing model knowledge to kernel components
/// (strategies, cost estimation, effort clamping).
class LlmModelSpec {
  /// Creates a model spec.
  const LlmModelSpec({
    required this.qualifiedId,
    this.contextWindow,
    this.maxOutputTokens,
    this.supportedEfforts,
    this.pricing,
  });

  /// The qualified `provider/model` id (e.g. `anthropic/claude-opus-4-8`).
  final String qualifiedId;

  /// Context window in tokens, when known.
  final int? contextWindow;

  /// Output-token ceiling, when known.
  final int? maxOutputTokens;

  /// Reasoning efforts the model accepts; null = unknown (pass unclamped),
  /// empty = the model exposes no reasoning.
  final Set<ReasoningEffort>? supportedEfforts;

  /// Pricing, when known. Null prices to zero (tokens still recorded).
  final LlmModelPricing? pricing;

  /// The provider id segment of [qualifiedId] (empty when unqualified).
  String get providerId {
    final i = qualifiedId.indexOf('/');
    return i <= 0 ? '' : qualifiedId.substring(0, i);
  }

  /// The bare model id segment of [qualifiedId].
  String get modelId {
    final i = qualifiedId.indexOf('/');
    return i < 0 ? qualifiedId : qualifiedId.substring(i + 1);
  }

  /// Clamps [requested] to the nearest supported effort. Returns null when the
  /// model exposes no reasoning; passes [requested] through when support is
  /// unknown.
  ReasoningEffort? resolveEffort(ReasoningEffort requested) {
    final supported = supportedEfforts;
    if (supported == null) {
      return requested;
    }
    if (supported.isEmpty) {
      return null;
    }
    if (supported.contains(requested)) {
      return requested;
    }
    ReasoningEffort? best;
    var bestDistance = 1 << 30;
    for (final e in supported) {
      final d = (e.index - requested.index).abs();
      if (d < bestDistance) {
        best = e;
        bestDistance = d;
      }
    }
    return best;
  }
}
