import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:test/test.dart';

void main() {
  test('a script may ask ${CodeModeLimits.maxApprovalAsks} times, and the '
      'refusal names the limit', () {
    final budget = ScriptApprovalBudget();
    for (var i = 0; i < CodeModeLimits.maxApprovalAsks; i++) {
      expect(budget.refusal, isNull, reason: 'ask ${i + 1}');
      budget
        ..asking()
        ..answered(approved: true, unanswered: false);
    }
    expect(budget.asked, CodeModeLimits.maxApprovalAsks);
    expect(budget.refusal, ScriptApprovalBudget.exhaustedReason);
    expect(
      ScriptApprovalBudget.exhaustedReason,
      allOf(
        contains('${CodeModeLimits.maxApprovalAsks}'),
        contains('maxApprovalAsks'),
      ),
    );
  });

  test('one declined ask refuses the rest', () {
    final budget = ScriptApprovalBudget()
      ..asking()
      ..answered(approved: false, unanswered: false);
    expect(budget.declined, isTrue);
    expect(budget.refusal, ScriptApprovalBudget.declinedReason);
  });

  test('a card nobody answered is no decision: the ask stays counted, and '
      'the next call asks again', () {
    final budget = ScriptApprovalBudget()
      ..asking()
      ..answered(approved: false, unanswered: true);
    expect(budget.declined, isFalse);
    expect(budget.asked, 1);
    expect(budget.refusal, isNull);
    // A person's decline after it still refuses the rest.
    budget
      ..asking()
      ..answered(approved: false, unanswered: false);
    expect(budget.refusal, ScriptApprovalBudget.declinedReason);
  });

  test('unanswered cards still count toward the limit', () {
    final budget = ScriptApprovalBudget();
    for (var i = 0; i < CodeModeLimits.maxApprovalAsks; i++) {
      budget
        ..asking()
        ..answered(approved: false, unanswered: true);
    }
    expect(budget.refusal, ScriptApprovalBudget.exhaustedReason);
  });

  test('an ask that was withdrawn counts, but is no decline', () {
    // A gate records the ask and never an answer for a withdrawn card.
    final budget = ScriptApprovalBudget()..asking();
    expect(budget.asked, 1);
    expect(budget.declined, isFalse);
    expect(budget.refusal, isNull);
  });

  test('an ask given back because no card went up frees its place', () {
    final budget = ScriptApprovalBudget();
    for (var i = 0; i < CodeModeLimits.maxApprovalAsks; i++) {
      budget.asking();
    }
    expect(budget.refusal, ScriptApprovalBudget.exhaustedReason);
    budget.release();
    expect(budget.asked, CodeModeLimits.maxApprovalAsks - 1);
    expect(budget.refusal, isNull);
    // Nothing to give back never goes below zero.
    final fresh = ScriptApprovalBudget()..release();
    expect(fresh.asked, 0);
  });

  test('the cap sits beside the question cap', () {
    expect(CodeModeLimits.maxApprovalAsks, 10);
    expect(CodeModeLimits.maxQuestions, isPositive);
  });
}
