import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

const _complete = '''
## Objective
Make the auth tests pass.

## Success criteria
`fvm dart test test/auth/` exits 0 with no skipped tests.

## Verification
Run `fvm dart test test/auth/ --concurrency=2` and check the exit code.

## Attempt cap
Stop after 5 attempts.

## Boundaries
Only modify files under lib/auth/ and test/auth/. Do not touch lib/billing/.

## Stop conditions
Escalate if the failure is in a dependency rather than our code.
''';

void main() {
  group('reviewGoalObjective — a complete objective', () {
    test('passes', () {
      final review = reviewGoalObjective(_complete);
      expect(review.missing, isEmpty);
      expect(review.weaknesses, isEmpty);
      expect(review.isReady, isTrue);
      expect(review.nextQuestion, isNull);
    });
  });

  group('reviewGoalObjective — missing requirements', () {
    test('a bare request is missing everything', () {
      // The expensive case: an autonomous loop runs for hours on an objective
      // whose "done" nobody defined, then reports success on its own terms.
      final review = reviewGoalObjective('Fix the bug.');
      expect(review.missing, hasLength(GoalObjectiveRequirement.values.length));
      expect(review.isReady, isFalse);
      expect(review.nextQuestion, isNotNull);
    });

    test('names the FIRST missing requirement, not all of them', () {
      // One question per turn — an interview that asks five at once gets one
      // answer covering none of them properly.
      final review = reviewGoalObjective('Fix the bug.');
      expect(
        review.nextQuestion,
        GoalObjectiveRequirement.successCriteria.question,
      );
    });

    test('detects each requirement independently', () {
      final noCap = _complete.replaceAll('Stop after 5 attempts.', '');
      expect(
        reviewGoalObjective(noCap.replaceAll('## Attempt cap', '')).missing,
        contains(GoalObjectiveRequirement.attemptCap),
      );

      final noBounds = _complete
          .replaceAll('## Boundaries', '')
          .replaceAll(
            'Only modify files under lib/auth/ and test/auth/. '
                'Do not touch lib/billing/.',
            '',
          );
      expect(
        reviewGoalObjective(noBounds).missing,
        contains(GoalObjectiveRequirement.boundaries),
      );
    });
  });

  group('reviewGoalObjective — anti-patterns', () {
    test('rejects success criteria that are judgment calls', () {
      // There is no command that returns whether the code is "clean", so an
      // agent resting on one declares done whenever it feels finished.
      final review = reviewGoalObjective(
        '$_complete\nAlso make sure the code is clean and works well.',
      );
      expect(review.isReady, isFalse);
      expect(review.weaknesses, isNotEmpty);
      expect(review.weaknesses.join(' '), contains('clean'));
    });

    test('rejects uncapped iteration', () {
      // "Until it works" has no floor if it cannot work; the only thing that
      // stops it is a budget wall hours later.
      final review = reviewGoalObjective(
        '$_complete\nKeep going until it works.',
      );
      expect(review.isReady, isFalse);
      expect(review.weaknesses.join(' '), contains('attempts'));
    });

    test('an anti-pattern is asked about once the sections are present', () {
      final review = reviewGoalObjective('$_complete\nMake it better.');
      expect(review.missing, isEmpty);
      expect(review.nextQuestion, review.weaknesses.first);
    });
  });

  group('requirement metadata', () {
    test('every requirement has a question and a heading', () {
      for (final requirement in GoalObjectiveRequirement.values) {
        expect(requirement.question, isNotEmpty);
        expect(requirement.heading, startsWith('## '));
      }
    });
  });

  group('prompts', () {
    test('the system prompt names all five requirements', () {
      expect(guidedGoalSystemPrompt, contains('Success criteria'));
      expect(guidedGoalSystemPrompt, contains('Verification'));
      expect(guidedGoalSystemPrompt, contains('attempt cap'));
      expect(guidedGoalSystemPrompt, contains('Boundaries'));
      expect(guidedGoalSystemPrompt, contains('Stop conditions'));
    });

    test('the system prompt names the three anti-patterns', () {
      expect(guidedGoalSystemPrompt, contains('no checkable signal'));
      expect(guidedGoalSystemPrompt, contains('uncapped iteration'));
      expect(guidedGoalSystemPrompt, contains('self-graded'));
    });

    test('the system prompt asks one question at a time', () {
      expect(guidedGoalSystemPrompt, contains('ONE question per turn'));
      expect(
        guidedGoalSystemPrompt,
        contains('running draft'),
        reason: 'a long interview must never lose progress',
      );
    });

    test('the turn prompt carries the rough request and the transcript', () {
      final prompt = guidedGoalTurnPrompt(
        roughObjective: 'make auth work',
        transcript: ['Q: what tests?', 'A: the auth ones'],
      );
      expect(prompt, contains('make auth work'));
      expect(prompt, contains('the auth ones'));
    });

    test('the first turn has no interview section', () {
      final prompt = guidedGoalTurnPrompt(
        roughObjective: 'x',
        transcript: const [],
      );
      expect(prompt, isNot(contains('Interview so far')));
    });
  });
}
