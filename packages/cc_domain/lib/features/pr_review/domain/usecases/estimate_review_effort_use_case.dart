// Estimates how much effort reading a review will take.
//
// Deterministic on purpose. The model already writes the narrative; asking it
// for "about 45 minutes" as well produces a number that varies between runs on
// the same PR and that nobody can check. This computes one from the shape of
// the change and the findings it produced, so two reviews of the same diff
// agree and the arithmetic is inspectable.

import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// The estimate: a 1-5 band plus the minutes behind it.
class ReviewEffortEstimate {
  /// Creates a [ReviewEffortEstimate].
  const ReviewEffortEstimate({required this.score, required this.minutes});

  /// 1 (trivial) to 5 (very complex).
  final int score;

  /// Rough reading time in minutes.
  final int minutes;

  /// A short human label for [score].
  String get band => switch (score) {
    1 => 'Trivial',
    2 => 'Simple',
    3 => 'Moderate',
    4 => 'Complex',
    _ => 'Very complex',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewEffortEstimate &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          minutes == other.minutes;

  @override
  int get hashCode => Object.hash(score, minutes);

  @override
  String toString() => 'ReviewEffortEstimate($score, ${minutes}m)';
}

/// Computes a [ReviewEffortEstimate] from the change's shape and its findings.
class EstimateReviewEffortUseCase {
  /// Creates an [EstimateReviewEffortUseCase].
  const EstimateReviewEffortUseCase();

  /// Estimates effort for a review.
  ///
  /// [fileCount] and [areaCount] describe the change's breadth; [findings]
  /// supplies its difficulty — a small diff that produced two critical
  /// findings is not a five-minute read, and a large mechanical rename is not
  /// an hour's work.
  ReviewEffortEstimate call({
    required int fileCount,
    required int areaCount,
    required Iterable<ReviewNodePayload> findings,
  }) {
    final files = fileCount < 0 ? 0 : fileCount;
    final areas = areaCount < 0 ? 0 : areaCount;

    var weighted = 0;
    for (final f in findings) {
      weighted += switch (f.effectiveSeverity) {
        ReviewFindingSeverity.critical => 8,
        ReviewFindingSeverity.major => 5,
        ReviewFindingSeverity.minor => 2,
        ReviewFindingSeverity.trivial => 1,
        ReviewFindingSeverity.info => 0,
      };
    }

    // Breadth and difficulty are added rather than multiplied: a wide but
    // clean change and a narrow but alarming one should both land mid-scale,
    // and multiplying sends a clean 40-file PR to the top of the range.
    final breadth = files + (areas * 2);
    final raw = breadth + weighted;

    final score = switch (raw) {
      <= 4 => 1,
      <= 12 => 2,
      <= 28 => 3,
      <= 55 => 4,
      _ => 5,
    };

    // Minutes track the raw signal rather than the band, so two "complex"
    // reviews of visibly different size do not both claim the same number.
    final minutes = _roundToFive((5 + raw * 1.6).round().clamp(5, 180));

    return ReviewEffortEstimate(score: score, minutes: minutes);
  }

  // A minute count like 47 implies a precision this estimate does not have.
  static int _roundToFive(int value) => ((value + 2) ~/ 5) * 5;
}
