import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:test/test.dart';

void main() {
  group('GoalContract', () {
    final contract = GoalContract(
      criteria: const ['the tests pass', 'the changelog says why'],
      checks: [
        GoalCheck(run: 'make test'),
        GoalCheck(
          run: 'curl -f localhost:8080/health',
          where: GoalCheckLocation.environment,
          timeoutSeconds: 60,
        ),
      ],
      boundaries: 'leave the public API alone',
      stopWhen: 'half the budget is gone',
    );

    test('round-trips through its column and the strict parser', () {
      expect(GoalContract.tryParse(contract.encode()), contract);
      expect(GoalContract.fromJson(contract.toJson()), contract);
      expect(contract.toJson()['checks'], [
        {'run': 'make test', 'in': 'worktree', 'timeoutSeconds': 300},
        {
          'run': 'curl -f localhost:8080/health',
          'in': 'environment',
          'timeoutSeconds': 60,
        },
      ]);
    });

    test('enforces its limits', () {
      expect(
        () => GoalContract(
          criteria: List.filled(GoalContract.maxCriteria + 1, 'c'),
        ),
        throwsArgumentError,
      );
      expect(
        () => GoalContract(
          criteria: ['x' * (GoalContract.maxCriterionLength + 1)],
        ),
        throwsArgumentError,
      );
      expect(
        () => GoalContract(
          checks: List.filled(GoalContract.maxChecks + 1, GoalCheck(run: 'x')),
        ),
        throwsArgumentError,
      );
      expect(
        () => GoalContract(boundaries: 'x' * (GoalContract.maxTextLength + 1)),
        throwsArgumentError,
      );
      expect(() => GoalCheck(run: '  '), throwsArgumentError);
      expect(() => GoalCheck(run: 'x', timeoutSeconds: 0), throwsArgumentError);
      expect(
        () => GoalCheck(
          run: 'x',
          timeoutSeconds: GoalCheck.maxTimeoutSeconds + 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => GoalCheck(run: 'x' * (GoalCheck.maxRunLength + 1)),
        throwsArgumentError,
      );
    });

    test('the strict parser refuses mistyped keys', () {
      expect(
        () => GoalContract.fromJson({'criteria': 'one'}),
        throwsFormatException,
      );
      expect(
        () => GoalContract.fromJson({
          'checks': [
            {'run': 'x', 'in': 'cloud'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => GoalContract.fromJson({'boundaries': 3}),
        throwsFormatException,
      );
      expect(() => GoalContract.fromJson([1]), throwsFormatException);
    });

    test('the lenient readers never throw', () {
      expect(GoalContract.tryParse(null), isNull);
      expect(GoalContract.tryParse('{'), isNull);
      expect(GoalContract.tryParse('{"criteria": 1}'), isNull);
      expect(
        GoalContract.tryParse(
          jsonEncode({
            'checks': [
              {'run': 'x', 'timeoutSeconds': 99999},
            ],
          }),
        ),
        isNull,
      );
      expect(GoalContract.tryFromJson(null), isNull);
      expect(GoalContract.tryFromJson('text'), isNull);
    });

    test('copyWith and value equality', () {
      expect(contract.copyWith(removeBoundaries: true).boundaries, isNull);
      expect(contract.copyWith(), contract);
      expect(contract.copyWith().hashCode, contract.hashCode);
      expect(GoalContract().hasNoChecks, isTrue);
    });
  });

  group('GoalVerdict', () {
    final verdict = GoalVerdict(
      verdict: GoalVerdictOutcome.fail,
      items: [
        GoalVerdictItem(
          criterion: 'the tests pass',
          state: GoalCriterionState.unmet,
          evidence: 'two failures in auth_test',
        ),
        GoalVerdictItem(criterion: 'docs', state: GoalCriterionState.met),
      ],
      concerns: const ['the migration was not run'],
    );

    test('round-trips and lists what is unmet', () {
      expect(GoalVerdict.fromJson(verdict.toJson()), verdict);
      expect(verdict.unmet.map((i) => i.criterion), ['the tests pass']);
    });

    test('enforces its limits', () {
      expect(
        () => GoalVerdict(
          verdict: GoalVerdictOutcome.pass,
          items: List.filled(
            GoalVerdict.maxItems + 1,
            GoalVerdictItem(criterion: 'c', state: GoalCriterionState.met),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => GoalVerdict(
          verdict: GoalVerdictOutcome.pass,
          concerns: List.filled(GoalVerdict.maxConcerns + 1, 'c'),
        ),
        throwsArgumentError,
      );
      expect(
        () => GoalVerdictItem(
          criterion: 'c',
          state: GoalCriterionState.met,
          evidence: 'x' * (GoalVerdictItem.maxEvidenceLength + 1),
        ),
        throwsArgumentError,
      );
    });

    test('a reviewer answer that is not a verdict reads as null', () {
      expect(GoalVerdict.tryFromJson({'verdict': 'maybe'}), isNull);
      expect(GoalVerdict.tryFromJson('pass'), isNull);
      expect(
        GoalVerdict.tryFromJson({'verdict': 'cannot_verify'})?.verdict,
        GoalVerdictOutcome.cannotVerify,
      );
    });

    test('the output schema names every outcome and state', () {
      final text = jsonEncode(GoalVerdict.outputSchema);
      for (final o in GoalVerdictOutcome.values) {
        expect(text, contains('"${o.wire}"'));
      }
      for (final s in GoalCriterionState.values) {
        expect(text, contains('"${s.wire}"'));
      }
    });
  });

  group('GoalVerification', () {
    final verification = GoalVerification(
      round: 1,
      claimSummary: 'all criteria met',
      claimEvidence: [
        GoalClaimEvidence(criterion: 'the tests pass', evidence: 'ran them'),
      ],
      checks: [
        GoalCheckResult(
          run: 'make test',
          where: GoalCheckLocation.worktree,
          exitCode: 0,
          outputTail: 'ok',
        ),
      ],
      verdict: GoalVerdict(verdict: GoalVerdictOutcome.pass),
      reviewerAgentId: 'checker',
      reviewRunId: 'run-2',
      fingerprint: 'fp',
      at: DateTime(2026, 5, 1, 12),
    );

    test('round-trips through its column', () {
      expect(GoalVerification.tryParse(verification.encode()), verification);
      expect(verification.at.isUtc, isTrue);
    });

    test('derived answers', () {
      expect(verification.checksPassed, isTrue);
      expect(verification.reviewedBySelf('checker'), isTrue);
      expect(verification.reviewedBySelf('builder'), isFalse);
      expect(
        GoalCheckResult(
          run: 'x',
          where: GoalCheckLocation.worktree,
          exitCode: 0,
          timedOut: true,
        ).passed,
        isFalse,
      );
      expect(
        GoalCheckResult(
          run: 'x',
          where: GoalCheckLocation.worktree,
          skippedUnchanged: true,
        ).passed,
        isFalse,
      );
    });

    test('a check that could not run is broken, never passed', () {
      final broken = GoalCheckResult(
        run: 'mkae test',
        where: GoalCheckLocation.worktree,
        exitCode: 127,
        broken: true,
      );
      expect(broken.passed, isFalse);
      expect(
        GoalCheckResult(
          run: 'x',
          where: GoalCheckLocation.environment,
          exitCode: 0,
          broken: true,
        ).passed,
        isFalse,
      );
      expect(broken.toJson()['broken'], isTrue);
      expect(GoalCheckResult.tryFromJson(broken.toJson()), broken);
      final spawnFailure = GoalCheckResult(
        run: 'x',
        where: GoalCheckLocation.worktree,
        broken: true,
      );
      expect(GoalCheckResult.tryFromJson(spawnFailure.toJson()), spawnFailure);
      expect(spawnFailure.exitCode, isNull);
      // Omitted when false, so existing rows read as not broken.
      final ran = GoalCheckResult(
        run: 'x',
        where: GoalCheckLocation.worktree,
        exitCode: 1,
      );
      expect(ran.toJson().containsKey('broken'), isFalse);
      expect(ran.broken, isFalse);
      expect(
        broken.hashCode,
        isNot(
          GoalCheckResult(
            run: 'mkae test',
            where: GoalCheckLocation.worktree,
            exitCode: 127,
          ).hashCode,
        ),
      );

      expect(verification.checksBroken, isFalse);
      final withBroken = verification.copyWith(
        checks: [...verification.checks, broken],
      );
      expect(withBroken.checksBroken, isTrue);
      expect(withBroken.checksPassed, isFalse);
      expect(GoalVerification.tryParse(withBroken.encode()), withBroken);
    });

    test('enforces its limits', () {
      expect(
        () => GoalVerification(round: 0, claimSummary: '', at: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => GoalVerification(
          round: 1,
          claimSummary: 'x' * (GoalVerification.maxSummaryLength + 1),
          at: DateTime(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => GoalCheckResult(
          run: 'x',
          where: GoalCheckLocation.worktree,
          outputTail: 'x' * (GoalCheckResult.maxOutputTail + 1),
        ),
        throwsArgumentError,
      );
    });

    test('malformed input reads as null', () {
      expect(GoalVerification.tryParse(null), isNull);
      expect(GoalVerification.tryParse('{"round": "one"}'), isNull);
      expect(GoalVerification.tryParse('[]'), isNull);
      expect(GoalVerification.tryFromJson({'round': 1}), isNull);
    });

    test('copyWith and value equality', () {
      expect(verification.copyWith(), verification);
      expect(verification.copyWith().hashCode, verification.hashCode);
      expect(verification.copyWith(removeVerdict: true).verdict, isNull);
    });
  });
}
