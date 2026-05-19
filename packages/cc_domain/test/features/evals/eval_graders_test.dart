import 'package:cc_domain/features/evals/domain/services/eval_graders.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_outcome.dart';
import 'package:test/test.dart';

EvalOutcome _outcome({
  bool completed = true,
  int costCents = 0,
  int turnCount = 0,
  int sandboxViolations = 0,
  Map<String, Object> signals = const {},
  String? error,
}) => EvalOutcome(
  completed: completed,
  costCents: costCents,
  turnCount: turnCount,
  sandboxViolations: sandboxViolations,
  signals: signals,
  error: error,
);

void main() {
  group('CostBudgetGrader', () {
    const grader = CostBudgetGrader(100);

    test('passes at the ceiling', () {
      expect(grader.grade(_outcome(costCents: 100)).passed, isTrue);
    });

    test('fails one cent over the ceiling', () {
      expect(grader.grade(_outcome(costCents: 101)).passed, isFalse);
    });
  });

  group('NoSandboxViolationsGrader', () {
    const grader = NoSandboxViolationsGrader();

    test('passes with zero violations', () {
      expect(grader.grade(_outcome()).passed, isTrue);
    });

    test('fails with any violation', () {
      expect(grader.grade(_outcome(sandboxViolations: 1)).passed, isFalse);
    });
  });

  group('MaxTurnsGrader', () {
    const grader = MaxTurnsGrader(20);

    test('passes at the ceiling', () {
      expect(grader.grade(_outcome(turnCount: 20)).passed, isTrue);
    });

    test('fails one turn over the ceiling', () {
      expect(grader.grade(_outcome(turnCount: 21)).passed, isFalse);
    });
  });

  group('SignalTrueGrader', () {
    const grader = SignalTrueGrader('testsPassed', id: 'tests');

    test('passes only when the signal is true', () {
      expect(
        grader.grade(_outcome(signals: {'testsPassed': true})).passed,
        isTrue,
      );
    });

    test('fails when the signal is false', () {
      expect(
        grader.grade(_outcome(signals: {'testsPassed': false})).passed,
        isFalse,
      );
    });

    test('fails when the signal is missing', () {
      expect(grader.grade(_outcome()).passed, isFalse);
    });
  });

  group('OutcomeSuccessGrader', () {
    const grader = OutcomeSuccessGrader();

    test('reflects a completed outcome', () {
      expect(grader.grade(_outcome(completed: true)).passed, isTrue);
    });

    test('reflects a failed outcome', () {
      expect(
        grader.grade(_outcome(completed: false, error: 'boom')).passed,
        isFalse,
      );
    });
  });

  group('GraderSpec', () {
    test('toJson/fromJson round-trips', () {
      const spec = GraderSpec(
        type: 'cost_budget',
        id: 'c1',
        params: {'maxCents': 80},
      );
      final back = GraderSpec.fromJson(spec.toJson());
      expect(back.type, spec.type);
      expect(back.id, spec.id);
      expect(back.kind, spec.kind);
      expect(back.params['maxCents'], 80);
    });

    test('build() materializes the right deterministic grader', () {
      expect(
        const GraderSpec(type: 'cost_budget', id: 'c').build(),
        isA<CostBudgetGrader>(),
      );
      expect(
        const GraderSpec(type: 'no_sandbox_violations', id: 'n').build(),
        isA<NoSandboxViolationsGrader>(),
      );
      expect(
        const GraderSpec(type: 'max_turns', id: 't').build(),
        isA<MaxTurnsGrader>(),
      );
      expect(
        const GraderSpec(type: 'signal', id: 's').build(),
        isA<SignalTrueGrader>(),
      );
      expect(
        const GraderSpec(type: 'outcome_success', id: 'o').build(),
        isA<OutcomeSuccessGrader>(),
      );
    });

    test('build() returns null for a judge-kind spec', () {
      const spec = GraderSpec(
        type: 'judge',
        id: 'j',
        kind: GraderKind.judge,
        rubric: 'Is the answer correct?',
      );
      expect(spec.build(), isNull);
    });
  });
}
