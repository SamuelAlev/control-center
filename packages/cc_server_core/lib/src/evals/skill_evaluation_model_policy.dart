import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_harness/provider.dart';

/// Builds a pinned, fail-closed per-call budget for an authenticated built-in
/// harness model. The caller MUST authenticate [providerId] first. Catalog
/// enablement uses environment/account signals distinct from stored harness
/// credentials; it cannot reject a verified built-in account. Only the exact
/// model identity may inherit catalog metadata, including a declared provider
/// alias such as Codex → OpenAI.
///
/// Codex OAuth is a subscription with no reliable hard per-request USD cap.
/// Its USD budget is an explicitly selected usage stopping threshold: observed
/// API-equivalent usage is checked after each physical call, and one in-flight
/// call may exceed it. API keys retain strict pre-call reservation.
Map<String, dynamic> admitSkillEvaluationModel({
  required String providerId,
  required String modelId,
  required ModelInfo? model,
  required int budgetMicros,
  required HarnessAuthMethod credentialMethod,
}) {
  final qualified = '$providerId/$modelId';
  if (budgetMicros <= 0) {
    throw ValidationException('$qualified needs a positive usage budget.');
  }
  if (providerId.isEmpty || modelId.isEmpty || model == null) {
    throw ValidationException(
      '$qualified has no catalog metadata. Sync the models.dev catalog before evaluating.',
    );
  }
  final sourceProvider = harnessProviderMetas[providerId]?.catalogProviderId;
  final aliased =
      sourceProvider != null &&
      sourceProvider != providerId &&
      model.providerId == sourceProvider;
  if (model.id != modelId || (!aliased && model.providerId != providerId)) {
    throw ValidationException(
      '$qualified resolved to ${model.qualifiedId}, not the selected model.',
    );
  }
  if (!model.supportsTools) {
    throw ValidationException(
      '$qualified does not document tool-call support.',
    );
  }
  final inputLimit = model.limits.maxInput ?? model.limits.context;
  final outputLimit = model.limits.maxOutput;
  if (inputLimit == null ||
      inputLimit <= 0 ||
      outputLimit == null ||
      outputLimit <= 0) {
    throw ValidationException(
      '$qualified has no documented positive input/output token limits.',
    );
  }
  final published = model.cost;
  if (published == null || !published.pricingComplete) {
    throw ValidationException(
      '$qualified has unknown or incomplete published pricing; evaluation cannot assume free spend.',
    );
  }
  final cost = published.reservationRates;
  if (!cost.input.isFinite ||
      cost.input <= 0 ||
      !cost.output.isFinite ||
      cost.output <= 0 ||
      !cost.cacheRead.isFinite ||
      cost.cacheRead < 0 ||
      !cost.cacheWrite.isFinite ||
      cost.cacheWrite < 0) {
    throw ValidationException(
      '$qualified needs positive input/output prices and known nonnegative cache prices.',
    );
  }
  final stopAfterCall =
      providerId == 'codex' && credentialMethod == HarnessAuthMethod.oauth;
  int? reserve;
  if (!stopAfterCall) {
    // Rates are USD per million tokens: count × rate equals micro-USD.
    // Accounting can overlap input and cache categories, so add them all.
    // Highest documented context-tier rates cover the full input window.
    final rawReserve =
        inputLimit * (cost.input + cost.cacheRead + cost.cacheWrite) +
        outputLimit * cost.output;
    if (!rawReserve.isFinite ||
        rawReserve <= 0 ||
        rawReserve > 0x7fffffffffffffff) {
      throw ValidationException(
        '$qualified has an unbounded cost reservation.',
      );
    }
    reserve = rawReserve.ceil();
    if (budgetMicros < reserve) {
      final minimum = (reserve / 1000000).toStringAsFixed(6);
      throw ValidationException(
        '$qualified needs at least USD $minimum for one safely reserved call '
        'at its documented input/output and highest context-tier rates; '
        'increase the budget or choose a lower-cost model.',
      );
    }
  }
  return {
    'pricingPolicyVersion': 3,
    'providerId': providerId,
    'modelId': modelId,
    'inputLimit': inputLimit,
    'outputLimit': outputLimit,
    'inputPrice': published.input,
    'outputPrice': published.output,
    'cacheReadPrice': published.cacheRead,
    'cacheWritePrice': published.cacheWrite,
    'contextPriceTiers': [
      for (final tier in published.contextTiers)
        {
          'thresholdTokens': tier.thresholdTokens,
          'inputPrice': tier.cost.input,
          'outputPrice': tier.cost.output,
          'cacheReadPrice': tier.cost.cacheRead,
          'cacheWritePrice': tier.cost.cacheWrite,
        },
    ],
    'budgetEnforcement': stopAfterCall ? 'stop_after_call' : 'reserved_call',
    'maxCallMicros': reserve,
    'priceBasis': 'catalog_estimate',
  };
}

/// Reconstructs the pinned published prices (rather than the conservative
/// admission ceiling) for observed, post-call usage estimates.
ModelCost skillEvaluationModelCostFromPin(Map<String, dynamic> pin) {
  if (pin['pricingPolicyVersion'] != 3 ||
      (pin['budgetEnforcement'] != 'stop_after_call' &&
          pin['budgetEnforcement'] != 'reserved_call')) {
    throw StateError(
      'Evaluation model pin predates explicit budget enforcement',
    );
  }
  return ModelCost(
    input: (pin['inputPrice'] as num).toDouble(),
    output: (pin['outputPrice'] as num).toDouble(),
    cacheRead: (pin['cacheReadPrice'] as num).toDouble(),
    cacheWrite: (pin['cacheWritePrice'] as num).toDouble(),
    contextTiers: [
      for (final entry in (pin['contextPriceTiers'] as List?) ?? const [])
        if (entry is Map)
          ModelContextCostTier(
            thresholdTokens: (entry['thresholdTokens'] as num).toInt(),
            cost: ModelCost(
              input: (entry['inputPrice'] as num).toDouble(),
              output: (entry['outputPrice'] as num).toDouble(),
              cacheRead: (entry['cacheReadPrice'] as num).toDouble(),
              cacheWrite: (entry['cacheWritePrice'] as num).toDouble(),
            ),
          ),
    ],
  );
}
