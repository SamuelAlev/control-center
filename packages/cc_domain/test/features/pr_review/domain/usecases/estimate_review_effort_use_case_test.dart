import 'package:cc_domain/features/pr_review/domain/usecases/estimate_review_effort_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:test/test.dart';

ReviewNodePayload _finding(ReviewFindingSeverity severity) => ReviewNodePayload(
  kind: ReviewNodeKind.bug,
  priority: severity.toPriority(),
  confidence: 0.9,
  anchor: const ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 1),
  status: ReviewNodeStatus.open,
  severity: severity,
);

void main() {
  const usecase = EstimateReviewEffortUseCase();

  group('EstimateReviewEffortUseCase', () {
    test('an empty change is the lowest band', () {
      final e = usecase(fileCount: 0, areaCount: 0, findings: const []);
      expect(e.score, 1);
      expect(e.band, 'Trivial');
      expect(e.minutes, greaterThanOrEqualTo(5));
    });

    test('score rises with breadth', () {
      final small = usecase(fileCount: 2, areaCount: 1, findings: const []);
      final large = usecase(fileCount: 60, areaCount: 8, findings: const []);
      expect(large.score, greaterThan(small.score));
      expect(large.minutes, greaterThan(small.minutes));
    });

    test('score rises with finding severity, not just count', () {
      // A small diff that produced two critical findings is not a
      // five-minute read.
      final trivial = usecase(
        fileCount: 3,
        areaCount: 1,
        findings: [
          _finding(ReviewFindingSeverity.trivial),
          _finding(ReviewFindingSeverity.trivial),
        ],
      );
      final critical = usecase(
        fileCount: 3,
        areaCount: 1,
        findings: [
          _finding(ReviewFindingSeverity.critical),
          _finding(ReviewFindingSeverity.critical),
        ],
      );
      expect(critical.score, greaterThan(trivial.score));
    });

    test('info findings add nothing', () {
      final without = usecase(fileCount: 4, areaCount: 2, findings: const []);
      final with_ = usecase(
        fileCount: 4,
        areaCount: 2,
        findings: [_finding(ReviewFindingSeverity.info)],
      );
      expect(with_, without);
    });

    test('a legacy priority-only finding still contributes', () {
      // No severity stored: the payload falls back to its priority mapping,
      // so old findings do not silently weigh zero.
      const legacy = ReviewNodePayload(
        kind: ReviewNodeKind.bug,
        priority: ReviewNodePriority.p0,
        confidence: 0.9,
        anchor: ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 1),
        status: ReviewNodeStatus.open,
      );
      final without = usecase(fileCount: 2, areaCount: 1, findings: const []);
      final with_ = usecase(fileCount: 2, areaCount: 1, findings: [legacy]);
      expect(with_.minutes, greaterThan(without.minutes));
    });

    test('score is clamped to 1..5 and minutes to a readable range', () {
      final huge = usecase(
        fileCount: 5000,
        areaCount: 400,
        findings: List.generate(
          200,
          (_) => _finding(ReviewFindingSeverity.critical),
        ),
      );
      expect(huge.score, 5);
      expect(huge.minutes, lessThanOrEqualTo(180));
      // Rounded to five, because a count like 47 implies a precision this
      // estimate does not have.
      expect(huge.minutes % 5, 0);
    });

    test('negative inputs are treated as zero rather than throwing', () {
      final e = usecase(fileCount: -3, areaCount: -1, findings: const []);
      expect(e.score, 1);
    });
  });
}
