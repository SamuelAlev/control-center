/// Provider-usage calibration for the harness token estimator.
///
/// The estimator is a fixed character heuristic (TokenEstimator, ~3.8
/// chars/token) plus a flat per-image constant. Neither is accurate across
/// code, languages, punctuation-dense output and image sizes, and compaction
/// decides whether to rewrite history from those estimates. Report 3D is
/// explicit: *calibrate the estimator against provider-reported prompt usage*.
///
/// This records, per (provider, model, purpose), the ratio of what the provider
/// billed for the prompt to what the harness estimated, and exposes a clamped
/// factor the harness multiplies its estimate by. A bucket with too few
/// observations reports 1.0 (no correction) rather than guessing from noise.
library;

import 'package:cc_harness/src/provider/llm_provider_port.dart';

/// A running estimate of `observed / estimated` prompt tokens for one context.
class TokenCalibrationBucket {
  /// Creates an empty bucket.
  TokenCalibrationBucket();

  int _samples = 0;
  double _ratioSum = 0;

  /// Number of observations folded into this bucket.
  int get samples => _samples;

  /// Mean observed/estimated ratio, or null when no usable sample exists.
  double? get meanRatio => _samples == 0 ? null : _ratioSum / _samples;

  /// Folds one observation into the bucket.
  void add(double ratio) {
    if (!ratio.isFinite || ratio <= 0) {
      return;
    }
    _samples++;
    _ratioSum += ratio;
  }

  /// Clears the bucket.
  void reset() {
    _samples = 0;
    _ratioSum = 0;
  }
}

/// Records provider-reported prompt usage against the harness estimate and
/// yields a correction factor.
///
/// Keyed by `providerId|modelId|purpose` (using [LlmCallPurpose.wire]), with a
/// fallback to `providerId|modelId|*` (all purposes) and then to no correction,
/// so a run whose compaction calls are still rare is corrected by its main-turn
/// observations rather than left at 1.0.
class TokenCalibration {
  /// Creates a calibration store.
  ///
  /// [minSamples] is how many observations a bucket needs before it is trusted;
  /// below it the factor is 1.0. [minFactor] and [maxFactor] clamp the
  /// correction so one pathological sample (a request with a huge system prompt
  /// the estimator never saw) cannot halve or triple the effective window.
  TokenCalibration({
    this.minSamples = 3,
    this.minFactor = 0.5,
    this.maxFactor = 4.0,
  }) {
    if (minSamples < 1) {
      throw ArgumentError.value(minSamples, 'minSamples', 'must be at least 1');
    }
    if (!minFactor.isFinite || minFactor <= 0 || minFactor > 1) {
      throw ArgumentError.value(minFactor, 'minFactor', 'must be in (0, 1]');
    }
    if (!maxFactor.isFinite || maxFactor < 1) {
      throw ArgumentError.value(
        maxFactor,
        'maxFactor',
        'must be finite and at least 1',
      );
    }
  }

  /// Observations a bucket needs before it is trusted.
  final int minSamples;

  /// Lower clamp on the correction factor.
  final double minFactor;

  /// Upper clamp on the correction factor.
  final double maxFactor;

  final Map<String, TokenCalibrationBucket> _buckets = {};

  static String _key(String providerId, String modelId, String purpose) =>
      '$providerId|$modelId|$purpose';

  static const String _anyPurpose = '*';

  /// Records one completed request.
  ///
  /// [estimatedTokens] is the harness estimate for the prompt that was sent
  /// (history + overhead), so the caller must measure it against the SAME
  /// content the provider billed. [observedPromptTokens] is the provider's
  /// total prompt tokens — non-cached input + cache reads + cache writes.
  /// Non-positive or non-finite inputs are ignored rather than poisoning the
  /// bucket.
  void observe({
    required String providerId,
    required String modelId,
    LlmCallPurpose purpose = LlmCallPurpose.main,
    required int estimatedTokens,
    required int observedPromptTokens,
  }) {
    if (estimatedTokens <= 0 || observedPromptTokens <= 0) {
      return;
    }
    final ratio = observedPromptTokens / estimatedTokens;
    if (!ratio.isFinite) {
      return;
    }
    _bucketFor(_key(providerId, modelId, purpose.wire)).add(ratio);
    _bucketFor(_key(providerId, modelId, _anyPurpose)).add(ratio);
  }

  TokenCalibrationBucket _bucketFor(String key) =>
      _buckets.putIfAbsent(key, TokenCalibrationBucket.new);

  /// The correction factor for a context. 1.0 when not enough is known.
  double factorFor({
    required String providerId,
    required String modelId,
    LlmCallPurpose purpose = LlmCallPurpose.main,
  }) {
    final specific = _buckets[_key(providerId, modelId, purpose.wire)];
    final specificMean = specific?.meanRatio;
    if (specificMean != null && (specific?.samples ?? 0) >= minSamples) {
      return specificMean.clamp(minFactor, maxFactor);
    }
    final any = _buckets[_key(providerId, modelId, _anyPurpose)];
    final anyMean = any?.meanRatio;
    if (anyMean != null && (any?.samples ?? 0) >= minSamples) {
      return anyMean.clamp(minFactor, maxFactor);
    }
    return 1.0;
  }

  /// Applies the correction factor to [estimatedTokens].
  int calibrate(
    int estimatedTokens, {
    required String providerId,
    required String modelId,
    LlmCallPurpose purpose = LlmCallPurpose.main,
  }) {
    if (estimatedTokens <= 0) {
      return estimatedTokens;
    }
    final factor = factorFor(
      providerId: providerId,
      modelId: modelId,
      purpose: purpose,
    );
    return (estimatedTokens * factor).round();
  }

  /// Whether any bucket has enough samples to correct an estimate.
  bool get isCalibrated => _buckets.values.any((b) => b.samples >= minSamples);

  /// Sample count for a context, for tests and telemetry.
  int samplesFor({
    required String providerId,
    required String modelId,
    LlmCallPurpose purpose = LlmCallPurpose.main,
  }) => _buckets[_key(providerId, modelId, purpose.wire)]?.samples ?? 0;

  /// Whether the given context has enough samples to be trusted.
  bool isCalibratedFor({
    required String providerId,
    required String modelId,
    LlmCallPurpose purpose = LlmCallPurpose.main,
  }) {
    final specific = _buckets[_key(providerId, modelId, purpose.wire)];
    if (specific != null && specific.samples >= minSamples) {
      return true;
    }
    final any = _buckets[_key(providerId, modelId, _anyPurpose)];
    return any != null && any.samples >= minSamples;
  }

  /// Clears every bucket.
  void reset() => _buckets.clear();
}
