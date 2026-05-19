import 'package:cc_domain/features/evals/domain/services/eval_graders.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_outcome.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_scorecard.dart';
import 'package:test/test.dart';

EvalRepetitionResult _rep({required bool g1, required bool g2}) =>
    EvalRepetitionResult(
      outcome: const EvalOutcome(
        completed: true,
        costCents: 10,
        turnCount: 5,
        durationMs: 100,
      ),
      grades: [
        GradeResult(graderId: 'g1', passed: g1, score: g1 ? 1 : 0),
        GradeResult(graderId: 'g2', passed: g2, score: g2 ? 1 : 0),
      ],
    );

void main() {
  group('EvalScorecard.fromReps', () {
    test('8 of 10 reps passing every grader yields passRate 0.8', () {
      final reps = <EvalRepetitionResult>[
        for (var i = 0; i < 8; i++) _rep(g1: true, g2: true),
        for (var i = 0; i < 2; i++) _rep(g1: true, g2: false),
      ];
      final card = EvalScorecard.fromReps(reps);
      expect(card.batchSize, 10);
      expect(card.repsPassed, 8);
      expect(card.passRate, closeTo(0.8, 1e-9));
    });

    test('perGraderPassRate is computed per grader id', () {
      final reps = <EvalRepetitionResult>[
        for (var i = 0; i < 8; i++) _rep(g1: true, g2: true),
        for (var i = 0; i < 2; i++) _rep(g1: true, g2: false),
      ];
      final card = EvalScorecard.fromReps(reps);
      expect(card.perGraderPassRate['g1'], closeTo(1, 1e-9));
      expect(card.perGraderPassRate['g2'], closeTo(0.8, 1e-9));
    });

    test('an all-pass batch has zero pass-rate variance', () {
      final reps = <EvalRepetitionResult>[
        for (var i = 0; i < 6; i++) _rep(g1: true, g2: true),
      ];
      expect(EvalScorecard.fromReps(reps).passRateStdDev, 0);
    });

    test('a mixed batch has positive pass-rate variance', () {
      final reps = <EvalRepetitionResult>[
        for (var i = 0; i < 8; i++) _rep(g1: true, g2: true),
        for (var i = 0; i < 2; i++) _rep(g1: true, g2: false),
      ];
      expect(EvalScorecard.fromReps(reps).passRateStdDev, greaterThan(0));
    });

    test('isGreen(0.9) is false at 0.8 and true at 0.95', () {
      final low = EvalScorecard.fromReps(<EvalRepetitionResult>[
        for (var i = 0; i < 8; i++) _rep(g1: true, g2: true),
        for (var i = 0; i < 2; i++) _rep(g1: true, g2: false),
      ]);
      expect(low.isGreen(threshold: 0.9), isFalse);

      final high = EvalScorecard.fromReps(<EvalRepetitionResult>[
        for (var i = 0; i < 19; i++) _rep(g1: true, g2: true),
        _rep(g1: false, g2: true),
      ]);
      expect(high.passRate, closeTo(0.95, 1e-9));
      expect(high.isGreen(threshold: 0.9), isTrue);
    });

    test('toJson/fromJson round-trip preserves passRate and batchSize', () {
      final card = EvalScorecard.fromReps(<EvalRepetitionResult>[
        for (var i = 0; i < 8; i++) _rep(g1: true, g2: true),
        for (var i = 0; i < 2; i++) _rep(g1: true, g2: false),
      ]);
      final back = EvalScorecard.fromJson(card.toJson());
      expect(back.passRate, card.passRate);
      expect(back.batchSize, card.batchSize);
    });
  });
}
