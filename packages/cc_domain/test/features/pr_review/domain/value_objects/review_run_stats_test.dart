import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewRunStats rates', () {
    test('action rate counts what was fixed, not what was rejected', () {
      // Folding dismissals into engagement is how a reviewer congratulates
      // itself for being ignored — so the two rates are reported separately.
      const stats = ReviewRunStats(
        findingsTotal: 10,
        resolved: 3,
        dismissed: 5,
        stillOpen: 2,
      );
      expect(stats.actionRate, closeTo(0.3, 1e-9));
      expect(stats.dismissalRate, closeTo(0.5, 1e-9));
      // The combined figure is still available, and still means "a human
      // looked at it" rather than "the review was useful".
      expect(stats.addressed, 8);
    });

    test('a review with no findings reads as zero, not one', () {
      // A clean review should not inflate the average in either direction.
      const stats = ReviewRunStats();
      expect(stats.actionRate, 0);
      expect(stats.dismissalRate, 0);
    });

    test('a review nobody touched has a zero action rate', () {
      const stats = ReviewRunStats(findingsTotal: 4, stillOpen: 4);
      expect(stats.actionRate, 0);
      expect(stats.dismissalRate, 0);
    });

    test('rates survive summing across passes', () {
      const a = ReviewRunStats(findingsTotal: 4, resolved: 2, dismissed: 1);
      const b = ReviewRunStats(findingsTotal: 6, resolved: 1, dismissed: 3);
      final total = a + b;
      expect(total.findingsTotal, 10);
      expect(total.actionRate, closeTo(0.3, 1e-9));
      expect(total.dismissalRate, closeTo(0.4, 1e-9));
    });
  });
}
