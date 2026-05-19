import 'package:cc_domain/features/pr_review/domain/usecases/compute_area_risk_use_case.dart';
import 'package:test/test.dart';

void main() {
  const useCase = ComputeAreaRiskUseCase();

  int contributionOf(AreaRisk risk, String id) => risk.factors
      .where((f) => f.id == id)
      .fold(0, (sum, f) => sum + f.contribution);

  group('ComputeAreaRiskUseCase', () {
    test('an empty area scores zero with no factors', () {
      final risk = useCase.execute(const AreaRiskInput());
      expect(risk.score, 0);
      expect(risk.level, AreaRiskLevel.low);
      expect(risk.isEmpty, isTrue);
    });

    test('a docs-sized change stays low', () {
      final risk = useCase.execute(
        const AreaRiskInput(
          locChanged: 12,
          fileCount: 1,
          filePaths: ['docs/readme.md'],
        ),
      );
      expect(risk.level, AreaRiskLevel.low);
    });

    test('critical paths raise the score and are named', () {
      final risk = useCase.execute(
        const AreaRiskInput(
          locChanged: 40,
          fileCount: 2,
          filePaths: ['lib/payment/charge.dart', 'lib/auth/session.dart'],
        ),
      );
      expect(
        contributionOf(risk, AreaRiskFactorIds.criticalPath),
        greaterThan(0),
      );
      expect(
        risk.factors.map((f) => f.id),
        contains(AreaRiskFactorIds.criticalPath),
      );
    });

    test('a P0 outweighs several P1s', () {
      final withP0 = useCase.execute(const AreaRiskInput(p0Count: 1));
      final withP1s = useCase.execute(const AreaRiskInput(p1Count: 2));
      expect(withP0.score, greaterThan(withP1s.score));
    });

    test('factors are ordered by contribution, largest first', () {
      final risk = useCase.execute(
        const AreaRiskInput(
          locChanged: 300,
          fileCount: 1,
          p0Count: 2,
          filePaths: ['lib/payment/charge.dart'],
        ),
      );
      final contributions = risk.factors.map((f) => f.contribution).toList();
      final sorted = [...contributions]..sort((a, b) => b.compareTo(a));
      expect(contributions, sorted);
    });

    test('unknown test coverage contributes nothing in either direction', () {
      final unknown = useCase.execute(
        const AreaRiskInput(locChanged: 50, fileCount: 2),
      );
      expect(
        contributionOf(unknown, AreaRiskFactorIds.noCoveringTests),
        0,
        reason: 'null coveringTestCount means "cannot tell", not "no tests"',
      );
    });

    test('known-zero test coverage does contribute', () {
      final known = useCase.execute(
        const AreaRiskInput(locChanged: 50, fileCount: 2, coveringTestCount: 0),
      );
      expect(
        contributionOf(known, AreaRiskFactorIds.noCoveringTests),
        greaterThan(0),
      );
    });

    test('covered code does not draw the no-tests penalty', () {
      final covered = useCase.execute(
        const AreaRiskInput(locChanged: 50, fileCount: 2, coveringTestCount: 3),
      );
      expect(contributionOf(covered, AreaRiskFactorIds.noCoveringTests), 0);
    });

    test('breaking contract changes push an area to high', () {
      final risk = useCase.execute(
        const AreaRiskInput(
          locChanged: 250,
          fileCount: 9,
          impactScore: 40,
          p0Count: 1,
          contractBreakingCount: 2,
          filePaths: ['lib/api/openapi.yaml', 'lib/core/router.dart'],
        ),
      );
      expect(risk.level, AreaRiskLevel.high);
      expect(risk.score, greaterThanOrEqualTo(55));
    });

    test('the score is capped at 100 no matter how extreme the inputs', () {
      final risk = useCase.execute(
        const AreaRiskInput(
          locChanged: 100000,
          fileCount: 900,
          impactScore: 5000,
          p0Count: 50,
          p1Count: 50,
          contractBreakingCount: 40,
          visualChangedPercentMax: 100,
          dependencyChurn: 500,
          coveringTestCount: 0,
          filePaths: ['lib/payment/a.dart', 'lib/auth/b.dart'],
        ),
      );
      expect(risk.score, lessThanOrEqualTo(100));
      expect(risk.level, AreaRiskLevel.high);
    });

    test('a single factor never exceeds its own cap', () {
      final risk = useCase.execute(const AreaRiskInput(locChanged: 100000));
      expect(contributionOf(risk, AreaRiskFactorIds.linesChanged), 20);
    });
  });
}
