import 'package:cc_domain/features/pr_review/domain/usecases/compute_review_verdict_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewNodePayload _node({
  required ReviewNodePriority priority,
  required double confidence,
  ReviewNodeStatus status = ReviewNodeStatus.open,
  ReviewNodeKind kind = ReviewNodeKind.bug,
}) {
  return ReviewNodePayload(
    kind: kind,
    priority: priority,
    confidence: confidence,
    anchor: const ReviewNodeAnchor(),
    status: status,
  );
}

void main() {
  const useCase = ComputeReviewVerdictUseCase();

  group('overall verdict', () {
    test('no findings → ship', () {
      final v = useCase.execute(const []);
      expect(v.overall, ReviewVerdictOverall.ship);
      expect(v.confidence, 1.0);
      expect(v.p0Count, 0);
      expect(v.p1Count, 0);
    });

    test('only P3 findings → ship', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p3, confidence: 0.9),
        _node(priority: ReviewNodePriority.p3, confidence: 0.8),
      ]);
      expect(v.overall, ReviewVerdictOverall.ship);
      expect(v.p3Count, 2);
    });

    test('only P2 findings → ship', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p2, confidence: 0.9),
      ]);
      expect(v.overall, ReviewVerdictOverall.ship);
    });

    test('P1 findings present → hold', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p1, confidence: 0.85),
      ]);
      expect(v.overall, ReviewVerdictOverall.hold);
      expect(v.p1Count, 1);
    });

    test('P0 below threshold → hold', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.4),
      ]);
      expect(v.overall, ReviewVerdictOverall.hold);
      expect(v.p0Count, 1);
    });

    test('P0 at threshold → block', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.7),
      ]);
      expect(v.overall, ReviewVerdictOverall.block);
    });

    test('P0 well above threshold → block', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.95),
      ]);
      expect(v.overall, ReviewVerdictOverall.block);
    });

    test('mixed P0 (some confident) → block', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.4),
        _node(priority: ReviewNodePriority.p0, confidence: 0.85),
        _node(priority: ReviewNodePriority.p1, confidence: 0.9),
      ]);
      expect(v.overall, ReviewVerdictOverall.block);
      expect(v.p0Count, 2);
      expect(v.p1Count, 1);
    });

    test('mixed P0 (none confident) + P2 → hold', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.5),
        _node(priority: ReviewNodePriority.p2, confidence: 0.9),
      ]);
      expect(v.overall, ReviewVerdictOverall.hold);
    });
  });

  group('verdict confidence (stddev math)', () {
    test('single contributing node: confidence is its own value, clamped',
        () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.9),
      ]);
      expect(v.confidence, 0.9);
    });

    test('two highly-agreeing nodes: confidence near 1.0', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.9),
        _node(priority: ReviewNodePriority.p0, confidence: 0.9),
      ]);
      expect(v.confidence, closeTo(1.0, 0.001));
    });

    test('two strongly-disagreeing nodes: confidence drops, clamped to 0.5',
        () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p1, confidence: 1.0),
        _node(priority: ReviewNodePriority.p1, confidence: 0.0),
      ]);
      expect(v.confidence, 0.5);
    });

    test('no contributing findings: confidence = 1.0', () {
      final v = useCase.execute(const []);
      expect(v.confidence, 1.0);
    });
  });

  group('counts', () {
    test('counts always contain all four priorities', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.9),
      ]);
      expect(v.counts[ReviewNodePriority.p0], 1);
      expect(v.counts[ReviewNodePriority.p1], 0);
      expect(v.counts[ReviewNodePriority.p2], 0);
      expect(v.counts[ReviewNodePriority.p3], 0);
    });
  });

  group('explanation', () {
    test('block carries P0 mention', () {
      final v = useCase.execute([
        _node(priority: ReviewNodePriority.p0, confidence: 0.9),
      ]);
      expect(v.explanation, contains('P0'));
    });

    test('ship explicitly mentions no P0 / P1', () {
      final v = useCase.execute(const []);
      expect(v.explanation.toLowerCase(), contains('ship'));
    });
  });
}
