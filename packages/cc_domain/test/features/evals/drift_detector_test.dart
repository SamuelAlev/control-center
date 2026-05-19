import 'package:cc_domain/features/evals/domain/services/drift_detector.dart';
import 'package:test/test.dart';

DriftWindow _window({
  required double cost,
  required double turns,
  int samples = 12,
  Map<String, int> failures = const {},
}) => DriftWindow(
  costs: List<double>.filled(samples, cost),
  turnCounts: List<double>.filled(samples, turns),
  failureFamilyCounts: failures,
);

void main() {
  group('DriftDetector.compare', () {
    const detector = DriftDetector();

    test('too few samples in a window never fires a drift alarm', () {
      final verdict = detector.compare(
        _window(cost: 10, turns: 5, samples: 3),
        _window(cost: 30, turns: 5, samples: 3),
      );
      expect(verdict.drifted, isFalse);
    });

    test('a 2x cost-mean jump is flagged as a cost drift', () {
      final verdict = detector.compare(
        _window(cost: 10, turns: 5),
        _window(cost: 30, turns: 5),
      );
      expect(verdict.drifted, isTrue);
      expect(verdict.shifts.any((s) => s.dimension == 'cost'), isTrue);
    });

    test('stable windows are not drifted', () {
      final verdict = detector.compare(
        _window(cost: 10, turns: 5),
        _window(cost: 10, turns: 5),
      );
      expect(verdict.drifted, isFalse);
      expect(verdict.shifts, isEmpty);
    });

    test('a failure-rate jump is flagged as a failure_mix drift', () {
      final verdict = detector.compare(
        _window(cost: 10, turns: 5),
        _window(cost: 10, turns: 5, failures: const {'timeout': 6, 'crash': 3}),
      );
      expect(verdict.drifted, isTrue);
      expect(verdict.shifts.any((s) => s.dimension == 'failure_mix'), isTrue);
    });

    test('a rise from a zero baseline is flagged (regression)', () {
      // Previously the relative-threshold check early-returned on a zero
      // baseline, silently missing exactly the upstream-drift case the alarm
      // exists for (cost 0 -> 50).
      final verdict = detector.compare(
        _window(cost: 0, turns: 5),
        _window(cost: 50, turns: 5),
      );
      expect(verdict.drifted, isTrue);
      expect(verdict.shifts.any((s) => s.dimension == 'cost'), isTrue);
    });
  });
}
