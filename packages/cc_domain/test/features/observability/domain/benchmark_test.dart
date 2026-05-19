import 'package:cc_domain/features/observability/domain/benchmark.dart';
import 'package:test/test.dart';

void main() {
  group('BenchmarkTrial.passed', () {
    test('reward of exactly 1.0 passes', () {
      const trial = BenchmarkTrial(
        name: 't',
        status: TrialStatus.pass,
        reward: 1.0,
      );
      expect(trial.passed, isTrue);
    });

    test('reward just below 1.0 within epsilon passes', () {
      const trial = BenchmarkTrial(
        name: 't',
        status: TrialStatus.pass,
        reward: 0.9999999999,
      );
      expect(trial.passed, isTrue);
    });

    test('reward of 0.5 does not pass', () {
      const trial = BenchmarkTrial(
        name: 't',
        status: TrialStatus.fail,
        reward: 0.5,
      );
      expect(trial.passed, isFalse);
    });

    test('null reward (running) does not pass', () {
      const trial = BenchmarkTrial(name: 't', status: TrialStatus.running);
      expect(trial.passed, isFalse);
    });

    test('reward clearly below epsilon tolerance does not pass', () {
      const trial = BenchmarkTrial(
        name: 't',
        status: TrialStatus.fail,
        reward: 0.99,
      );
      expect(trial.passed, isFalse);
    });
  });

  group('BenchmarkTrial value-object semantics', () {
    test('structural equality and hashCode', () {
      const a = BenchmarkTrial(
        name: 't',
        status: TrialStatus.pass,
        reward: 1.0,
        costCents: 12,
        tokIn: 100,
      );
      const b = BenchmarkTrial(
        name: 't',
        status: TrialStatus.pass,
        reward: 1.0,
        costCents: 12,
        tokIn: 100,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const BenchmarkTrial(name: 't', status: TrialStatus.fail)),
      );
    });

    test('copyWith replaces only the given fields', () {
      const trial = BenchmarkTrial(
        name: 't',
        status: TrialStatus.running,
        costCents: 5,
      );
      final updated = trial.copyWith(status: TrialStatus.pass, reward: 1.0);
      expect(updated.status, TrialStatus.pass);
      expect(updated.reward, 1.0);
      expect(updated.name, 't');
      expect(updated.costCents, 5);
    });
  });

  group('BenchmarkRun counts', () {
    BenchmarkRun runWith(List<BenchmarkTrial> trials, {int expectedTotal = 5}) {
      return BenchmarkRun(
        id: 'run-1',
        dataset: 'terminal-bench',
        trials: trials,
        expectedTotal: expectedTotal,
        startedAt: DateTime(2026, 6, 29, 12),
      );
    }

    test('done counts resolved trials, excludes running', () {
      final run = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'b', status: TrialStatus.fail, reward: 0.0),
        const BenchmarkTrial(name: 'c', status: TrialStatus.error),
        const BenchmarkTrial(name: 'd', status: TrialStatus.running),
      ]);
      expect(run.done, 3);
      expect(run.passCount, 1);
      expect(run.failCount, 1);
      expect(run.errorCount, 1);
      expect(run.runningCount, 1);
    });

    test('pendingCount is expectedTotal minus done and running', () {
      final run = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'b', status: TrialStatus.running),
      ], expectedTotal: 5);
      // done=1, running=1 -> pending = 5 - 1 - 1 = 3.
      expect(run.pendingCount, 3);
    });

    test('pendingCount clamps to zero when more work seen than expected', () {
      final run = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'b', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'c', status: TrialStatus.running),
      ], expectedTotal: 1);
      expect(run.pendingCount, 0);
    });

    test('successPct is passCount over done as a percentage', () {
      final run = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'b', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'c', status: TrialStatus.fail, reward: 0.0),
        const BenchmarkTrial(name: 'd', status: TrialStatus.error),
      ]);
      // 2 passed of 4 resolved.
      expect(run.successPct, 50.0);
    });

    test('successPct is zero when nothing resolved', () {
      final run = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.running),
      ]);
      expect(run.successPct, 0);
    });

    test('cost and token totals sum across trials', () {
      final run = runWith([
        const BenchmarkTrial(
          name: 'a',
          status: TrialStatus.pass,
          reward: 1.0,
          costCents: 100,
          advisorCostCents: 10,
          tokIn: 1000,
          tokOut: 200,
          tokCache: 50,
        ),
        const BenchmarkTrial(
          name: 'b',
          status: TrialStatus.fail,
          reward: 0.0,
          costCents: 50,
          advisorCostCents: 5,
          tokIn: 500,
          tokOut: 100,
          tokCache: 25,
        ),
      ]);
      expect(run.totalCostCents, 150);
      expect(run.totalAdvisorCostCents, 15);
      expect(run.totalTokIn, 1500);
      expect(run.totalTokOut, 300);
      expect(run.totalTokCache, 75);
    });

    test('structural equality and hashCode over trial list', () {
      final a = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
      ]);
      final b = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
      ]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      final different = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.fail, reward: 0.0),
      ]);
      expect(a, isNot(different));
    });
  });

  group('BenchmarkScorer.passAtK', () {
    const scorer = BenchmarkScorer();

    BenchmarkRun runWith(List<BenchmarkTrial> trials) => BenchmarkRun(
      id: 'r',
      dataset: 'd',
      trials: trials,
      expectedTotal: trials.length,
      startedAt: DateTime(2026, 6, 29, 12),
    );

    test('is passCount over done', () {
      final run = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'b', status: TrialStatus.pass, reward: 1.0),
        const BenchmarkTrial(name: 'c', status: TrialStatus.fail, reward: 0.0),
      ]);
      expect(scorer.passAtK(run), closeTo(2 / 3, 1e-9));
    });

    test('is zero when nothing resolved', () {
      final run = runWith([
        const BenchmarkTrial(name: 'a', status: TrialStatus.running),
      ]);
      expect(scorer.passAtK(run), 0);
    });
  });

  group('BenchmarkScorer.etaFrom', () {
    const scorer = BenchmarkScorer();
    final start = DateTime(2026, 6, 29, 12);

    test('is zero when nothing has resolved', () {
      final run = BenchmarkRun(
        id: 'r',
        dataset: 'd',
        trials: const [BenchmarkTrial(name: 'a', status: TrialStatus.running)],
        expectedTotal: 4,
        startedAt: start,
      );
      expect(
        scorer.etaFrom(run, start.add(const Duration(minutes: 1))),
        Duration.zero,
      );
    });

    test('is zero when the run is complete', () {
      final run = BenchmarkRun(
        id: 'r',
        dataset: 'd',
        trials: const [
          BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
          BenchmarkTrial(name: 'b', status: TrialStatus.fail, reward: 0.0),
        ],
        expectedTotal: 2,
        startedAt: start,
      );
      expect(
        scorer.etaFrom(run, start.add(const Duration(minutes: 2))),
        Duration.zero,
      );
    });

    test('extrapolates from the per-trial rate', () {
      // 2 of 4 done in 2 minutes -> 1 min/trial -> 2 remaining -> 2 min eta.
      final run = BenchmarkRun(
        id: 'r',
        dataset: 'd',
        trials: const [
          BenchmarkTrial(name: 'a', status: TrialStatus.pass, reward: 1.0),
          BenchmarkTrial(name: 'b', status: TrialStatus.fail, reward: 0.0),
          BenchmarkTrial(name: 'c', status: TrialStatus.running),
        ],
        expectedTotal: 4,
        startedAt: start,
      );
      final eta = scorer.etaFrom(run, start.add(const Duration(minutes: 2)));
      expect(eta, const Duration(minutes: 2));
    });
  });

  group('BenchmarkScorer.markdownReport', () {
    const scorer = BenchmarkScorer();

    test('contains the header and a pass row with the check icon', () {
      final run = BenchmarkRun(
        id: 'r',
        dataset: 'terminal-bench',
        trials: const [
          BenchmarkTrial(
            name: 'fix-build',
            status: TrialStatus.pass,
            reward: 1.0,
            costCents: 123,
            durationMs: 4500,
          ),
          BenchmarkTrial(
            name: 'flaky-test',
            status: TrialStatus.fail,
            reward: 0.0,
            costCents: 50,
            durationMs: 90000,
          ),
          BenchmarkTrial(
            name: 'setup-crash',
            status: TrialStatus.error,
            detail: 'docker pull failed',
          ),
          BenchmarkTrial(name: 'in-progress', status: TrialStatus.running),
        ],
        expectedTotal: 4,
        startedAt: DateTime(2026, 6, 29, 12),
      );

      final report = scorer.markdownReport(run);

      // Header line is present.
      expect(
        report,
        contains('| task | result | reward | cost | duration | detail |'),
      );
      // The passing trial renders with the check icon, its reward and cost.
      expect(report, contains('| fix-build | ✅ | 1.00 | \$1.23 | 4.5s |'));
      // Other status icons are present.
      expect(report, contains('❌'));
      expect(report, contains('⚠️'));
      expect(report, contains('⏳'));
      // A null-reward trial renders as the em dash placeholder.
      expect(report, contains('| in-progress | ⏳ | — |'));
      // Duration over a minute uses m:ss.
      expect(report, contains('1:30'));
      // Summary line.
      expect(
        report,
        contains('**1/3 passed (33%)** · fail 1 · error 1 · spend \$1.73'),
      );
      // Tokens line.
      expect(report, contains('tokens:'));
    });

    test('escapes pipes and newlines in cell values', () {
      final run = BenchmarkRun(
        id: 'r',
        dataset: 'd',
        trials: const [
          BenchmarkTrial(
            name: 'weird',
            status: TrialStatus.error,
            detail: 'a | b\nsecond line',
          ),
        ],
        expectedTotal: 1,
        startedAt: DateTime(2026, 6, 29, 12),
      );

      final report = scorer.markdownReport(run);
      expect(report, contains(r'a \| b second line'));
      // No raw newline survives inside a table row.
      expect(report, isNot(contains('a | b\nsecond line')));
    });
  });
}
