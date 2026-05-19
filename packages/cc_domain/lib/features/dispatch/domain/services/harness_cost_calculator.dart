/// Prices harness token usage into a [RunCost] using the models.dev catalog.
///
/// Pure domain: the catalog lookup is injected as a function so this never
/// imports the infrastructure catalog. Reuses [ModelCost.estimate] (cache-aware)
/// for the USD math and [RunCost] as the transport the transcript / run log
/// already render.
library;

import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_harness/provider.dart';

/// Computes per-turn cost for the built-in harness.
class HarnessCostCalculator {
  /// Creates a calculator over a [priceLookup] mapping `(providerId, modelId)`
  /// to that model's [ModelCost], or null when the model is unknown.
  const HarnessCostCalculator(this.priceLookup);

  /// Resolves the pricing for a provider + model, or null when unpriced.
  final ModelCost? Function(String providerId, String modelId) priceLookup;

  /// Builds a [RunCost] for [usage] against `providerId/modelId`.
  ///
  /// Thinking tokens are folded into `outputTokens` by the providers we target,
  /// so only input/output/cache tokens are priced (avoids double counting); the
  /// thought-token count is still recorded on the returned [RunCost]. When the
  /// model is unpriced the cost is zero but the token breakdown is preserved.
  RunCost cost({
    required String providerId,
    required String modelId,
    required LlmUsage usage,
  }) {
    final usd =
        priceLookup(providerId, modelId)?.estimate(
          inputTokens: usage.inputTokens,
          outputTokens: usage.outputTokens,
          cacheReadTokens: usage.cacheReadTokens,
          cacheWriteTokens: usage.cacheWriteTokens,
        ) ??
        0.0;
    return RunCost(
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      thoughtTokens: usage.thoughtTokens,
      cachedReadTokens: usage.cacheReadTokens,
      cachedWriteTokens: usage.cacheWriteTokens,
      estimatedCostCents: (usd * 100).round(),
    );
  }
}
