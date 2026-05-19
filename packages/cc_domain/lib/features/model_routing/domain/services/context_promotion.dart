import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/model_routing/domain/services/model_catalog.dart';

/// The outcome of a context-promotion check.
class ContextPromotionDecision {
  /// Creates a [ContextPromotionDecision].
  const ContextPromotionDecision({
    required this.shouldPromote,
    required this.pressure,
    this.target,
    this.reason,
  });

  /// No-promotion result with the computed [pressure].
  const ContextPromotionDecision.keep(this.pressure)
    : shouldPromote = false,
      target = null,
      reason = null;

  /// Whether the session should switch to a larger-context model.
  final bool shouldPromote;

  /// Estimated context utilisation `estimatedTokens / contextWindow` [0..∞).
  final double pressure;

  /// The model to promote to, if [shouldPromote].
  final ModelInfo? target;

  /// Why the decision was made (for telemetry / UI).
  final String? reason;
}

/// Decides when a long session should be **promoted** to a larger-context model
/// rather than truncated (feature #7). Combined with compaction: as a worktree
/// session grows, escalate Sonnet→Opus or short-context→1M-context.
class ContextPromoter {
  /// Creates a [ContextPromoter].
  const ContextPromoter({this.pressureThreshold = 0.9});

  /// The utilisation at which promotion triggers (default 90%).
  final double pressureThreshold;

  /// Decides whether to promote [current] given [estimatedTokens] of context,
  /// resolving the target against [catalog].
  ///
  /// Prefers the model's declared [ModelInfo.contextPromotionTarget] chain;
  /// falls back to the smallest same-provider model whose window is strictly
  /// larger and can hold the estimate with headroom.
  ContextPromotionDecision decide(
    ModelInfo current,
    int estimatedTokens,
    ModelCatalog catalog,
  ) {
    final window = current.limits.context;
    if (window == null || window <= 0) {
      return const ContextPromotionDecision.keep(0);
    }
    final pressure = estimatedTokens / window;
    if (pressure < pressureThreshold) {
      return ContextPromotionDecision.keep(pressure);
    }

    // 1) Follow the declared promotion-target chain.
    final declared = _followTargetChain(current, estimatedTokens, catalog);
    if (declared != null) {
      return ContextPromotionDecision(
        shouldPromote: true,
        pressure: pressure,
        target: declared,
        reason:
            'Context ${(pressure * 100).round()}% full — promoting to declared '
            'target ${declared.qualifiedId} (${declared.limits.context} ctx).',
      );
    }

    // 2) Fall back to the smallest larger-window model in the same provider.
    final fallback = _smallestLargerWindow(current, estimatedTokens, catalog);
    if (fallback != null) {
      return ContextPromotionDecision(
        shouldPromote: true,
        pressure: pressure,
        target: fallback,
        reason:
            'Context ${(pressure * 100).round()}% full — promoting to '
            '${fallback.qualifiedId} (${fallback.limits.context} ctx).',
      );
    }

    return ContextPromotionDecision.keep(pressure);
  }

  ModelInfo? _followTargetChain(
    ModelInfo start,
    int estimatedTokens,
    ModelCatalog catalog,
  ) {
    final seen = <String>{start.qualifiedId};
    var node = start;
    while (node.contextPromotionTarget != null) {
      final next = catalog.resolve(node.contextPromotionTarget!);
      if (next == null || !seen.add(next.qualifiedId)) {
        return null; // dangling or cyclic
      }
      final nextWindow = next.limits.context ?? 0;
      final currentWindow = node.limits.context ?? 0;
      if (next.enabled &&
          nextWindow > currentWindow &&
          estimatedTokens < nextWindow * pressureThreshold) {
        return next;
      }
      node = next;
    }
    return null;
  }

  ModelInfo? _smallestLargerWindow(
    ModelInfo current,
    int estimatedTokens,
    ModelCatalog catalog,
  ) {
    final currentWindow = current.limits.context ?? 0;
    ModelInfo? best;
    for (final m in catalog.modelsForProvider(current.providerId)) {
      if (m.qualifiedId == current.qualifiedId || !m.enabled) {
        continue;
      }
      final w = m.limits.context;
      if (w == null || w <= currentWindow) {
        continue;
      }
      if (estimatedTokens >= w * pressureThreshold) {
        continue; // wouldn't relieve pressure
      }
      if (best == null || (best.limits.context ?? 0) > w) {
        best = m; // keep the smallest window that fits
      }
    }
    return best;
  }
}
