import 'package:cc_domain/features/evals/domain/services/reliability_score.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:test/test.dart';

void main() {
  group('ReliabilityScore.compute', () {
    test('no evidence yields a zero score and propose-only', () {
      final r = ReliabilityScore.compute(const ReliabilityEvidence());
      expect(r.score, 0);
      expect(r.recommended, AutonomyLevel.proposeOnly);
      expect(
        r.rationale.any((line) => line.toLowerCase().contains('history')),
        isTrue,
      );
      expect(r.permits(AutonomyLevel.actFreely), isFalse);
    });

    test('high quality + high volume + zero violations permits act-freely', () {
      final r = ReliabilityScore.compute(
        const ReliabilityEvidence(gradedRuns: 120, gradedPassRate: 0.98),
      );
      expect(r.recommended, AutonomyLevel.actFreely);
      expect(r.permits(AutonomyLevel.actFreely), isTrue);
    });

    test('sandbox violations block act-freely even at a high pass-rate', () {
      final r = ReliabilityScore.compute(
        const ReliabilityEvidence(
          gradedRuns: 120,
          gradedPassRate: 0.98,
          sandboxViolations: 3,
        ),
      );
      expect(r.recommended, isNot(AutonomyLevel.actFreely));
      expect(r.permits(AutonomyLevel.actFreely), isFalse);
    });

    test('mid volume + good quality recommends act-with-approval', () {
      final r = ReliabilityScore.compute(
        const ReliabilityEvidence(gradedRuns: 30, gradedPassRate: 0.9),
      );
      expect(r.recommended, AutonomyLevel.actWithApproval);
      expect(r.permits(AutonomyLevel.actFreely), isFalse);
      expect(r.permits(AutonomyLevel.actWithApproval), isTrue);
    });
  });
}
