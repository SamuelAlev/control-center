import 'package:cc_domain/features/observability/domain/goal_budget.dart';
import 'package:test/test.dart';

Goal _goal({
  int? tokenBudget,
  int tokensUsed = 0,
  int timeUsedSeconds = 0,
  GoalStatus status = GoalStatus.active,
}) {
  final created = DateTime.utc(2026, 1, 1);
  return Goal(
    id: 'g1',
    workspaceId: 'ws1',
    objective: 'Ship the thing',
    status: status,
    tokenBudget: tokenBudget,
    tokensUsed: tokensUsed,
    timeUsedSeconds: timeUsedSeconds,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  group('goalTokenDelta', () {
    test('sums input + output + cacheWrite', () {
      expect(goalTokenDelta(input: 10, output: 20, cacheWrite: 5), 35);
    });

    test('EXCLUDES cacheRead — only the three new-work categories count', () {
      // There is no cacheRead parameter; reused-prefix reads are never charged.
      // Two calls with identical new-work but (conceptually) different cache
      // reads must produce the same delta, proving reads are not part of it.
      expect(goalTokenDelta(input: 100, output: 200, cacheWrite: 0), 300);
      expect(goalTokenDelta(input: 100, output: 200, cacheWrite: 0), 300);
    });

    test('clamps negative inputs at 0 (never credits the budget)', () {
      expect(goalTokenDelta(input: -50, output: 20, cacheWrite: -5), 20);
      expect(goalTokenDelta(input: -1, output: -1, cacheWrite: -1), 0);
    });

    test('all zero -> 0', () {
      expect(goalTokenDelta(input: 0, output: 0, cacheWrite: 0), 0);
    });

    test('large values do not overflow into negatives', () {
      const big = 1 << 40;
      expect(goalTokenDelta(input: big, output: big, cacheWrite: big), big * 3);
    });
  });

  group('Goal.budgetFraction', () {
    test('null when no budget', () {
      expect(_goal(tokenBudget: null, tokensUsed: 999).budgetFraction, isNull);
    });

    test('used/budget for a normal budget', () {
      expect(_goal(tokenBudget: 1000, tokensUsed: 250).budgetFraction, 0.25);
    });

    test('can exceed 1.0 when over budget', () {
      expect(_goal(tokenBudget: 100, tokensUsed: 150).budgetFraction, 1.5);
    });

    test('zero budget with no usage -> 0', () {
      expect(_goal(tokenBudget: 0, tokensUsed: 0).budgetFraction, 0);
    });

    test('zero budget with usage -> infinity (no headroom)', () {
      expect(
        _goal(tokenBudget: 0, tokensUsed: 1).budgetFraction,
        double.infinity,
      );
    });
  });

  group('Goal.remainingTokens', () {
    test('null when no budget', () {
      expect(_goal(tokenBudget: null).remainingTokens, isNull);
    });

    test('budget - used while under', () {
      expect(_goal(tokenBudget: 1000, tokensUsed: 300).remainingTokens, 700);
    });

    test('clamps at 0 when over budget (never negative)', () {
      expect(_goal(tokenBudget: 100, tokensUsed: 250).remainingTokens, 0);
    });

    test('exactly 0 when fully spent', () {
      expect(_goal(tokenBudget: 100, tokensUsed: 100).remainingTokens, 0);
    });
  });

  group('Goal.copyWith', () {
    test('updates status, tokensUsed, timeUsedSeconds, updatedAt', () {
      final g = _goal(tokenBudget: 100);
      final stamp = DateTime.utc(2026, 6, 29);
      final updated = g.copyWith(
        status: GoalStatus.budgetLimited,
        tokensUsed: 80,
        timeUsedSeconds: 42,
        updatedAt: stamp,
      );
      expect(updated.status, GoalStatus.budgetLimited);
      expect(updated.tokensUsed, 80);
      expect(updated.timeUsedSeconds, 42);
      expect(updated.updatedAt, stamp);
      // Unchanged fields preserved.
      expect(updated.id, g.id);
      expect(updated.workspaceId, g.workspaceId);
      expect(updated.objective, g.objective);
      expect(updated.tokenBudget, g.tokenBudget);
      expect(updated.createdAt, g.createdAt);
    });

    test('no-arg copy equals original', () {
      final g = _goal(tokenBudget: 500, tokensUsed: 10);
      expect(g.copyWith(), g);
    });
  });

  group('Goal equality', () {
    test('structural == and hashCode', () {
      final a = _goal(tokenBudget: 100, tokensUsed: 5);
      final b = _goal(tokenBudget: 100, tokensUsed: 5);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs on any field', () {
      final a = _goal(tokenBudget: 100, tokensUsed: 5);
      expect(a == a.copyWith(tokensUsed: 6), isFalse);
      expect(a == a.copyWith(status: GoalStatus.paused), isFalse);
    });
  });

  group('GoalBudgetTracker.applyTurn', () {
    const tracker = GoalBudgetTracker();

    test('accumulates tokensUsed via goalTokenDelta (excludes cacheRead)', () {
      final g = _goal(tokenBudget: 10000, tokensUsed: 100);
      final update = tracker.applyTurn(
        g,
        input: 30,
        output: 20,
        cacheWrite: 10,
      );
      expect(update.goal.tokensUsed, 100 + 60);
    });

    test('accumulates wall-clock time, clamping negatives at 0', () {
      final g = _goal(tokenBudget: 10000, timeUsedSeconds: 5);
      final pos = tracker.applyTurn(
        g,
        input: 1,
        output: 1,
        cacheWrite: 0,
        wallClockSecondsDelta: 7,
      );
      expect(pos.goal.timeUsedSeconds, 12);
      final neg = tracker.applyTurn(
        g,
        input: 1,
        output: 1,
        cacheWrite: 0,
        wallClockSecondsDelta: -100,
      );
      expect(neg.goal.timeUsedSeconds, 5);
    });

    test('leaves updatedAt unchanged (caller stamps)', () {
      final g = _goal(tokenBudget: 10000);
      final update = tracker.applyTurn(g, input: 5, output: 5, cacheWrite: 0);
      expect(update.goal.updatedAt, g.updatedAt);
    });

    test('does not mutate the input goal', () {
      final g = _goal(tokenBudget: 100, tokensUsed: 0);
      tracker.applyTurn(g, input: 50, output: 50, cacheWrite: 50);
      expect(g.tokensUsed, 0);
      expect(g.status, GoalStatus.active);
    });

    group('budget flip to budgetLimited', () {
      test('flips when usage exactly meets the budget', () {
        final g = _goal(tokenBudget: 100, tokensUsed: 40);
        final update = tracker.applyTurn(
          g,
          input: 60,
          output: 0,
          cacheWrite: 0,
        );
        expect(update.goal.tokensUsed, 100);
        expect(update.goal.status, GoalStatus.budgetLimited);
        expect(update.budgetExhausted, isTrue);
        expect(update.shouldSteer, isTrue);
      });

      test('flips when usage exceeds the budget', () {
        final g = _goal(tokenBudget: 100, tokensUsed: 90);
        final update = tracker.applyTurn(
          g,
          input: 100,
          output: 0,
          cacheWrite: 0,
        );
        expect(update.goal.status, GoalStatus.budgetLimited);
        expect(update.budgetExhausted, isTrue);
        expect(update.shouldSteer, isTrue);
      });

      test('does not flip while under budget', () {
        final g = _goal(tokenBudget: 1000, tokensUsed: 0);
        final update = tracker.applyTurn(
          g,
          input: 100,
          output: 0,
          cacheWrite: 0,
        );
        expect(update.goal.status, GoalStatus.active);
        expect(update.budgetExhausted, isFalse);
      });

      test(
        'only flips from active — already-limited stays limited, no re-flip',
        () {
          final g = _goal(
            tokenBudget: 100,
            tokensUsed: 100,
            status: GoalStatus.budgetLimited,
          );
          final update = tracker.applyTurn(
            g,
            input: 50,
            output: 0,
            cacheWrite: 0,
          );
          expect(update.goal.status, GoalStatus.budgetLimited);
          // Already-limited goals report exhausted=false (no fresh flip this turn).
          expect(update.budgetExhausted, isFalse);
          // ...and are not actively steered (status is not active).
          expect(update.shouldSteer, isFalse);
        },
      );

      test('paused goal at/over budget does not flip and does not steer', () {
        final g = _goal(
          tokenBudget: 100,
          tokensUsed: 50,
          status: GoalStatus.paused,
        );
        final update = tracker.applyTurn(
          g,
          input: 100,
          output: 0,
          cacheWrite: 0,
        );
        expect(update.goal.status, GoalStatus.paused);
        expect(update.budgetExhausted, isFalse);
        expect(update.shouldSteer, isFalse);
      });
    });

    group('shouldSteer threshold', () {
      test('true exactly at 88% (default threshold)', () {
        final g = _goal(tokenBudget: 1000, tokensUsed: 0);
        final update = tracker.applyTurn(
          g,
          input: 880,
          output: 0,
          cacheWrite: 0,
        );
        expect(update.goal.budgetFraction, 0.88);
        expect(update.goal.status, GoalStatus.active);
        expect(update.shouldSteer, isTrue);
        // Steering at the threshold is not exhaustion.
        expect(update.budgetExhausted, isFalse);
      });

      test('false just below the threshold', () {
        final g = _goal(tokenBudget: 1000, tokensUsed: 0);
        final update = tracker.applyTurn(
          g,
          input: 879,
          output: 0,
          cacheWrite: 0,
        );
        expect(update.goal.budgetFraction, 0.879);
        expect(update.shouldSteer, isFalse);
        expect(update.budgetExhausted, isFalse);
      });

      test('custom threshold is honored', () {
        const lenient = GoalBudgetTracker(steerThresholdFraction: 0.5);
        final g = _goal(tokenBudget: 1000, tokensUsed: 0);
        final atHalf = lenient.applyTurn(
          g,
          input: 500,
          output: 0,
          cacheWrite: 0,
        );
        expect(atHalf.shouldSteer, isTrue);
        final belowHalf = lenient.applyTurn(
          g,
          input: 499,
          output: 0,
          cacheWrite: 0,
        );
        expect(belowHalf.shouldSteer, isFalse);
      });
    });

    group('no-budget goal', () {
      test('never flips, never steers, never reports exhaustion', () {
        final g = _goal(tokenBudget: null, tokensUsed: 0);
        final update = tracker.applyTurn(
          g,
          input: 1000000,
          output: 1000000,
          cacheWrite: 1000000,
        );
        expect(update.goal.status, GoalStatus.active);
        expect(update.goal.tokensUsed, 3000000);
        expect(update.shouldSteer, isFalse);
        expect(update.budgetExhausted, isFalse);
        expect(update.goal.budgetFraction, isNull);
        expect(update.goal.remainingTokens, isNull);
      });
    });
  });

  group('GoalUpdate value semantics', () {
    test('structural == and hashCode', () {
      final g = _goal(tokenBudget: 100, tokensUsed: 50);
      final x = GoalUpdate(goal: g, shouldSteer: true, budgetExhausted: false);
      final y = GoalUpdate(goal: g, shouldSteer: true, budgetExhausted: false);
      final z = GoalUpdate(goal: g, shouldSteer: false, budgetExhausted: false);
      expect(x, y);
      expect(x.hashCode, y.hashCode);
      expect(x == z, isFalse);
    });
  });

  group('goalSteerNotice', () {
    test('budgeted goal includes used/total and percent', () {
      final g = _goal(tokenBudget: 1000, tokensUsed: 920);
      final notice = goalSteerNotice(g);
      expect(notice, contains('920 of 1000 tokens'));
      expect(notice, contains('92%'));
      expect(notice, contains('Ship the thing'));
      expect(notice, contains('Wrap up'));
    });

    test('rounds the percent', () {
      final g = _goal(tokenBudget: 1000, tokensUsed: 885);
      expect(goalSteerNotice(g), contains('89%'));
    });

    test('unbounded goal omits budget figures', () {
      final g = _goal(tokenBudget: null, tokensUsed: 5000);
      final notice = goalSteerNotice(g);
      expect(notice, isNot(contains('tokens')));
      expect(notice, contains('Ship the thing'));
      expect(notice, contains('Wrap up'));
    });
  });
}
