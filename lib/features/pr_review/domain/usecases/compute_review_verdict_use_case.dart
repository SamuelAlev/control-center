import 'dart:math' as math;

import 'package:control_center/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_verdict.dart';

/// Computes a per-PR [ReviewVerdict] from the open / consensus-ready
/// findings of a review channel.
///
/// Algorithm (decided in the plan):
/// 1. Bucket findings by priority.
/// 2. Any P0 with confidence ≥ [_blockThreshold] → block.
/// 3. Else any P0 (low-confidence) or any P1 → hold.
/// 4. Else → ship.
/// 5. Verdict confidence = `1 - stddev(contributing confidences)`,
///    clamped to `[0.5, 1.0]`. No contributing nodes → 1.0.
class ComputeReviewVerdictUseCase {
  /// Creates a [ComputeReviewVerdictUseCase].
  const ComputeReviewVerdictUseCase();

  static const double _blockThreshold = 0.7;

  /// Runs the algorithm on [openNodes] (findings with `status ∈ {open,
  /// consensusReady}`). Returns a [ReviewVerdict].
  ReviewVerdict execute(List<ReviewNodePayload> openNodes) {
    final counts = <ReviewNodePriority, int>{
      ReviewNodePriority.p0: 0,
      ReviewNodePriority.p1: 0,
      ReviewNodePriority.p2: 0,
      ReviewNodePriority.p3: 0,
    };
    for (final n in openNodes) {
      counts[n.priority] = (counts[n.priority] ?? 0) + 1;
    }

    final p0Confident = openNodes
        .where(
          (n) =>
              n.priority == ReviewNodePriority.p0 &&
              n.confidence >= _blockThreshold,
        )
        .toList(growable: false);
    final p0Any = openNodes
        .where((n) => n.priority == ReviewNodePriority.p0)
        .toList(growable: false);
    final p1Any = openNodes
        .where((n) => n.priority == ReviewNodePriority.p1)
        .toList(growable: false);

    final ReviewVerdictOverall overall;
    final List<ReviewNodePayload> contributing;
    if (p0Confident.isNotEmpty) {
      overall = ReviewVerdictOverall.block;
      contributing = p0Confident;
    } else if (p0Any.isNotEmpty || p1Any.isNotEmpty) {
      overall = ReviewVerdictOverall.hold;
      contributing = [...p0Any, ...p1Any];
    } else {
      overall = ReviewVerdictOverall.ship;
      contributing = const [];
    }

    final confidence = _aggregateConfidence(contributing);
    final explanation = _explain(overall, counts);

    return ReviewVerdict(
      overall: overall,
      confidence: confidence,
      explanation: explanation,
      counts: counts,
    );
  }

  double _aggregateConfidence(List<ReviewNodePayload> contributing) {
    if (contributing.isEmpty) {
      return 1.0;
    }
    if (contributing.length == 1) {
      return contributing.first.confidence.clamp(0.5, 1.0);
    }
    final values =
        contributing.map((n) => n.confidence).toList(growable: false);
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final stddev = math.sqrt(variance);
    return (1.0 - stddev).clamp(0.5, 1.0);
  }

  String _explain(
    ReviewVerdictOverall overall,
    Map<ReviewNodePriority, int> counts,
  ) {
    final p0 = counts[ReviewNodePriority.p0] ?? 0;
    final p1 = counts[ReviewNodePriority.p1] ?? 0;
    final p2 = counts[ReviewNodePriority.p2] ?? 0;
    final p3 = counts[ReviewNodePriority.p3] ?? 0;
    final counts4 = 'P0=$p0, P1=$p1, P2=$p2, P3=$p3';
    switch (overall) {
      case ReviewVerdictOverall.block:
        return 'Blocking issues found ($counts4). At least one P0 finding '
            'meets the release-blocking confidence threshold.';
      case ReviewVerdictOverall.hold:
        if (p0 > 0) {
          return 'On hold ($counts4). P0 findings present but below the '
              'blocking confidence threshold; review them before merging.';
        }
        return 'On hold ($counts4). P1 findings should be addressed before '
            'this PR ships.';
      case ReviewVerdictOverall.ship:
        return 'Ready to ship ($counts4). No P0 or P1 findings; remaining '
            'items are non-blocking.';
    }
  }
}
