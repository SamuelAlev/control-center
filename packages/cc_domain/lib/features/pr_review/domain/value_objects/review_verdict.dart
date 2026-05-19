import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:collection/collection.dart';

/// Overall ship/hold/block verdict produced by the CEO at finalize time.
enum ReviewVerdictOverall {
  /// Ship — no blocking findings; safe to merge.
  ship,

  /// Hold — at least one P1 or a low-confidence P0; needs attention before merge.
  hold,

  /// Block — at least one P0 above the confidence threshold; do not merge.
  block,
}

/// Per-PR review verdict aggregate, posted as part of `review_summary`
/// metadata. Computed by `ComputeReviewVerdictUseCase` from the per-finding
/// [ReviewNodePriority] + [ReviewNodePayload.confidence] axis.
class ReviewVerdict {
  /// Creates a [ReviewVerdict].
  const ReviewVerdict({
    required this.overall,
    required this.confidence,
    required this.explanation,
    required this.counts,
    this.axisResults = const [],
  });

  /// Final ship/hold/block call.
  final ReviewVerdictOverall overall;

  /// Per-axis results (PRD 18 §7). Empty for the legacy single-axis path.
  /// The overall verdict is upgraded (never downgraded) by a blocking axis:
  /// a gated `fail` forces `block`; a gated axis that could not run
  /// (`partial`/`unavailable`) forces at least `hold`.
  final List<ReviewAxisResult> axisResults;

  /// Aggregate confidence in the verdict itself, in `[0.5, 1.0]`.
  /// Higher when contributing findings broadly agree (low confidence stddev).
  final double confidence;

  /// One-paragraph human explanation of the verdict.
  final String explanation;

  /// Count of contributing findings by priority. Always contains all four
  /// keys, with zero defaults.
  final Map<ReviewNodePriority, int> counts;

  /// Number of P0 findings.
  int get p0Count => counts[ReviewNodePriority.p0] ?? 0;

  /// The gated axes that currently block the merge.
  List<ReviewAxisResult> get blockingAxes =>
      axisResults.where((a) => a.blocks).toList();

  /// Returns a copy that folds [results] into the overall verdict, honestly:
  /// a gated `fail` upgrades to `block`; a gated axis that could not run
  /// (`partial`/`unavailable`) upgrades to at least `hold`. The verdict is
  /// only ever made *more* severe — absence of evidence never greens a gate
  /// (PRD 18 §7 / adversarial notes).
  ReviewVerdict withAxisResults(List<ReviewAxisResult> results) {
    var next = overall;
    for (final r in results) {
      if (!r.gated) {
        continue;
      }
      if (r.verdict == ReviewAxisVerdict.fail) {
        next = ReviewVerdictOverall.block;
      } else if (!r.verdict.clearsGate && next == ReviewVerdictOverall.ship) {
        next = ReviewVerdictOverall.hold;
      }
    }
    return ReviewVerdict(
      overall: next,
      confidence: confidence,
      explanation: explanation,
      counts: counts,
      axisResults: results,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewVerdict &&
          runtimeType == other.runtimeType &&
          overall == other.overall &&
          confidence == other.confidence &&
          explanation == other.explanation &&
          const MapEquality<ReviewNodePriority, int>().equals(
            counts,
            other.counts,
          ) &&
          const ListEquality<ReviewAxisResult>().equals(
            axisResults,
            other.axisResults,
          );

  @override
  int get hashCode => Object.hash(
    overall,
    confidence,
    explanation,
    Object.hashAll(counts.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(axisResults),
  );

  /// Number of P1 findings.
  int get p1Count => counts[ReviewNodePriority.p1] ?? 0;

  /// Number of P2 findings.
  int get p2Count => counts[ReviewNodePriority.p2] ?? 0;

  /// Number of P3 findings.
  int get p3Count => counts[ReviewNodePriority.p3] ?? 0;

  /// Serializes this verdict to a flat metadata map for embedding in a
  /// `review_summary` message.
  Map<String, dynamic> toMetadata() {
    return {
      'verdict': _overallToString(overall),
      'verdictConfidence': confidence,
      'verdictExplanation': explanation,
      'priorityCounts': {
        'p0': p0Count,
        'p1': p1Count,
        'p2': p2Count,
        'p3': p3Count,
      },
      if (axisResults.isNotEmpty)
        'axisResults': axisResults.map((a) => a.toJson()).toList(),
    };
  }

  /// Parses a verdict from a `review_summary`-style metadata map. Returns
  /// `null` if the required `verdict` key is missing or unrecognized.
  static ReviewVerdict? fromMetadata(Map<String, dynamic>? meta) {
    if (meta == null) {
      return null;
    }
    final overall = _parseOverall(meta['verdict']);
    if (overall == null) {
      return null;
    }
    final confidence = _parseConfidence(meta['verdictConfidence']);
    final explanation = meta['verdictExplanation'];
    final rawCounts = meta['priorityCounts'];
    final counts = <ReviewNodePriority, int>{
      ReviewNodePriority.p0: 0,
      ReviewNodePriority.p1: 0,
      ReviewNodePriority.p2: 0,
      ReviewNodePriority.p3: 0,
    };
    if (rawCounts is Map) {
      counts[ReviewNodePriority.p0] = (rawCounts['p0'] as num?)?.toInt() ?? 0;
      counts[ReviewNodePriority.p1] = (rawCounts['p1'] as num?)?.toInt() ?? 0;
      counts[ReviewNodePriority.p2] = (rawCounts['p2'] as num?)?.toInt() ?? 0;
      counts[ReviewNodePriority.p3] = (rawCounts['p3'] as num?)?.toInt() ?? 0;
    }
    return ReviewVerdict(
      overall: overall,
      confidence: confidence ?? 1.0,
      explanation: explanation is String ? explanation : '',
      counts: counts,
      axisResults: (meta['axisResults'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ReviewAxisResult.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }

  static ReviewVerdictOverall? _parseOverall(Object? raw) {
    if (raw is! String) {
      return null;
    }
    switch (raw) {
      case 'ship':
        return ReviewVerdictOverall.ship;
      case 'hold':
        return ReviewVerdictOverall.hold;
      case 'block':
        return ReviewVerdictOverall.block;
      default:
        return null;
    }
  }

  static String _overallToString(ReviewVerdictOverall o) {
    switch (o) {
      case ReviewVerdictOverall.ship:
        return 'ship';
      case ReviewVerdictOverall.hold:
        return 'hold';
      case ReviewVerdictOverall.block:
        return 'block';
    }
  }

  static double? _parseConfidence(Object? raw) {
    if (raw is! num) {
      return null;
    }
    final v = raw.toDouble();
    if (v.isNaN || v < 0.0 || v > 1.0) {
      return null;
    }
    return v;
  }
}
