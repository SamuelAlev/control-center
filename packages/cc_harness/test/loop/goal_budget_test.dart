import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

void main() {
  group('goalTokenDelta', () {
    test('counts fresh input and output', () {
      expect(
        goalTokenDelta(
          const GoalTokenUsage(input: 100, output: 50),
          const GoalTokenUsage(input: 40, output: 10),
        ),
        100,
      );
    });

    test('counts cache WRITES — they are real and large', () {
      // Rotating an expiring cache or re-anchoring a changed system prompt can
      // write six figures of tokens; a budget blind to that silently
      // overshoots, which is the one thing a budget exists to prevent.
      expect(
        goalTokenDelta(
          const GoalTokenUsage(cacheWrite: 120000),
          const GoalTokenUsage(),
        ),
        120000,
      );
    });

    test('excludes cache READS — the goal already paid for that prefix', () {
      expect(
        goalTokenDelta(
          const GoalTokenUsage(cacheRead: 500000),
          const GoalTokenUsage(),
        ),
        0,
      );
    });

    test('a counter reset never credits tokens back', () {
      // A provider that resets a counter mid-run must not make the goal richer.
      expect(
        goalTokenDelta(
          const GoalTokenUsage(input: 5),
          const GoalTokenUsage(input: 900),
        ),
        0,
      );
    });
  });

  group('GoalBudget', () {
    test('accumulates deltas across segments', () {
      final budget = GoalBudget(tokenBudget: 1000)
        ..record(
          const GoalTokenUsage(input: 200, output: 100),
          const GoalTokenUsage(),
        )
        ..record(
          const GoalTokenUsage(input: 400, output: 200),
          const GoalTokenUsage(input: 200, output: 100),
        );
      expect(budget.tokensUsed, 600);
      expect(budget.tokensRemaining, 400);
      expect(budget.isExhausted(), isFalse);
    });

    test('exhausts on tokens', () {
      final budget = GoalBudget(tokenBudget: 100)..addTokens(150);
      expect(budget.isExhausted(), isTrue);
      expect(
        budget.tokensRemaining,
        0,
        reason: 'never negative — the UI would render nonsense',
      );
    });

    test('exhausts on time', () {
      final start = DateTime(2026, 8, 28, 12);
      final budget = GoalBudget(
        timeBudget: const Duration(minutes: 30),
        startedAt: start,
      );
      expect(
        budget.isExhausted(now: start.add(const Duration(minutes: 20))),
        isFalse,
      );
      expect(
        budget.isExhausted(now: start.add(const Duration(minutes: 31))),
        isTrue,
      );
    });

    test('an unbounded budget never exhausts', () {
      final budget = GoalBudget()..addTokens(10000000);
      expect(budget.isExhausted(), isFalse);
      expect(budget.tokensRemaining, isNull);
    });

    test('the limit steer fires exactly once', () {
      // Repeating "you are out of budget" every turn spends the remaining
      // budget saying so.
      final budget = GoalBudget(tokenBudget: 10)..addTokens(50);
      expect(budget.shouldReportLimit(), isTrue);
      expect(budget.shouldReportLimit(), isFalse);
      expect(budget.shouldReportLimit(), isFalse);
    });

    test('the limit steer does not fire while within budget', () {
      final budget = GoalBudget(tokenBudget: 100)..addTokens(50);
      expect(budget.shouldReportLimit(), isFalse);
    });

    test('describe reports both dimensions', () {
      final start = DateTime(2026, 8, 28, 12);
      final budget = GoalBudget(tokenBudget: 500, startedAt: start)
        ..addTokens(120);
      final line = budget.describe(
        now: start.add(const Duration(minutes: 7)),
      );
      expect(line, contains('120 / 500 tokens'));
      expect(line, contains('7 min'));
    });
  });

  group('prompts', () {
    test('the budget steer refuses to equate exhaustion with completion', () {
      final steer = goalBudgetLimitSteer(
        objective: 'make the tests pass',
        budgetLine: '500 / 500 tokens',
      );
      expect(steer, contains('make the tests pass'));
      expect(
        steer,
        contains('Budget exhaustion is not completion'),
        reason: 'a goal that reports success because it ran out of money is a '
            'lie the user acts on',
      );
    });

    test('the completion audit demands current-state evidence', () {
      expect(goalCompletionAudit, contains('CURRENT state'));
      expect(
        goalCompletionAudit,
        contains('rely on your memory'),
        reason: 'the repo may have changed since, including by the agent',
      );
      expect(goalCompletionAudit, contains('Treat uncertainty as not-yet-done'));
      expect(goalCompletionAudit, contains('scope to claim scope'));
    });

    test('the continuation carries the objective and the audit', () {
      final steer = goalContinuationSteer(
        objective: 'ship the migration',
        budgetLine: '10 / 100 tokens',
      );
      expect(steer, contains('ship the migration'));
      expect(steer, contains('10 / 100 tokens'));
      expect(steer, contains('never redefine success'));
      expect(
        steer,
        contains('Do not narrate'),
        reason: 'a continuation that announces itself burns a turn on nothing',
      );
    });
  });
}
