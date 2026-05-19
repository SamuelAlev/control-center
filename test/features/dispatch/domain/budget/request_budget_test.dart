import 'package:cc_domain/features/dispatch/domain/budget/request_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('softRequestBudgetForAgentType', () {
    test('explore caps at 40', () {
      expect(softRequestBudgetForAgentType('explore'), 40);
      expect(softRequestBudgetForAgentType('explore'), kExploreRequestBudget);
    });

    test('quick_task caps at 40', () {
      expect(softRequestBudgetForAgentType('quick_task'), 40);
      expect(
        softRequestBudgetForAgentType('quick_task'),
        kQuickTaskRequestBudget,
      );
    });

    test('default agent types cap at 90', () {
      expect(softRequestBudgetForAgentType('architect'), 90);
      expect(softRequestBudgetForAgentType('architect'), kDefaultRequestBudget);
    });

    test('null agent type falls back to default', () {
      expect(softRequestBudgetForAgentType(null), 90);
    });

    test('unknown agent type falls back to default', () {
      expect(softRequestBudgetForAgentType('reviewer'), 90);
    });
  });

  group('RequestBudgetTracker', () {
    test('forAgentType derives the budget from the agent type', () {
      expect(RequestBudgetTracker.forAgentType('explore').softBudget, 40);
      expect(RequestBudgetTracker.forAgentType('quick_task').softBudget, 40);
      expect(RequestBudgetTracker.forAgentType('architect').softBudget, 90);
      expect(RequestBudgetTracker.forAgentType(null).softBudget, 90);
    });

    test('returns none before the soft budget is reached', () {
      final tracker = RequestBudgetTracker(5);
      for (var i = 0; i < 4; i++) {
        expect(tracker.record(), BudgetDecision.none);
      }
      expect(tracker.requests, 4);
    });

    test('steers exactly once at the soft cap, then none until abort', () {
      final tracker = RequestBudgetTracker(4);
      // Counts 1..3 -> none.
      expect(tracker.record(), BudgetDecision.none);
      expect(tracker.record(), BudgetDecision.none);
      expect(tracker.record(), BudgetDecision.none);
      // Count 4 == budget -> steer (exactly once).
      expect(tracker.record(), BudgetDecision.steer);
      // Count 5 still below 1.5x (==6) -> none, steer does not refire.
      expect(tracker.record(), BudgetDecision.none);
      expect(tracker.requests, 5);
    });

    test('aborts at 1.5x the soft budget', () {
      final tracker = RequestBudgetTracker(4);
      // 1.5x of 4 is 6.
      for (var i = 0; i < 5; i++) {
        tracker.record();
      }
      expect(tracker.requests, 5);
      // 6th request reaches the abort threshold.
      expect(tracker.record(), BudgetDecision.abort);
      expect(tracker.requests, 6);
    });

    test('abort takes precedence and steer never fires for tiny budgets', () {
      // softBudget 1: 1.5x rounds down so the threshold is 1.5; first request
      // (count 1) is below it -> steer, second (count 2) -> abort.
      final tracker = RequestBudgetTracker(1);
      expect(tracker.record(), BudgetDecision.steer);
      expect(tracker.record(), BudgetDecision.abort);
    });

    test('softBudget of 0 disables the guard (always none)', () {
      final tracker = RequestBudgetTracker(0);
      for (var i = 0; i < 200; i++) {
        expect(tracker.record(), BudgetDecision.none);
      }
      expect(tracker.requests, 200);
    });

    test('negative softBudget disables the guard (always none)', () {
      final tracker = RequestBudgetTracker(-5);
      for (var i = 0; i < 50; i++) {
        expect(tracker.record(), BudgetDecision.none);
      }
    });
  });

  group('budgetSteerNotice', () {
    test('produces the exact verbatim notice', () {
      expect(
        budgetSteerNotice(42),
        '[budget notice] You have used 42 requests in this run. '
            'Wrap up now: finish the current step and yield your final report.',
      );
    });
  });
}
