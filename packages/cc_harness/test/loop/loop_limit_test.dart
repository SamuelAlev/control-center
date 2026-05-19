import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

void main() {
  group('parseLoopArgs — limits', () {
    test('a bare integer is an iteration count', () {
      final parsed = parseLoopArgs('10 fix the tests');
      expect(parsed.limit, isA<LoopIterationLimit>());
      expect((parsed.limit! as LoopIterationLimit).iterations, 10);
      expect(parsed.prompt, 'fix the tests');
    });

    test('a compact duration parses', () {
      expect(
        (parseLoopArgs('30m').limit! as LoopDurationLimit).duration,
        const Duration(minutes: 30),
      );
      expect(
        (parseLoopArgs('2h').limit! as LoopDurationLimit).duration,
        const Duration(hours: 2),
      );
      expect(
        (parseLoopArgs('90s').limit! as LoopDurationLimit).duration,
        const Duration(seconds: 90),
      );
    });

    test('a compound duration parses', () {
      expect(
        (parseLoopArgs('1h30m refactor').limit! as LoopDurationLimit).duration,
        const Duration(hours: 1, minutes: 30),
      );
      expect(parseLoopArgs('1h30m refactor').prompt, 'refactor');
    });

    test('a count followed by a unit word is a duration', () {
      final parsed = parseLoopArgs('10 minutes fix the tests');
      expect(parsed.limit, isA<LoopDurationLimit>());
      expect(
        (parsed.limit! as LoopDurationLimit).duration,
        const Duration(minutes: 10),
      );
      expect(
        parsed.prompt,
        'fix the tests',
        reason: 'the unit word must not leak into the prompt',
      );
    });

    test('a limit with no prompt is allowed', () {
      final parsed = parseLoopArgs('5');
      expect((parsed.limit! as LoopIterationLimit).iterations, 5);
      expect(parsed.prompt, isNull);
    });
  });

  group('parseLoopArgs — prose', () {
    test('plain prose is an unbounded loop, not an error', () {
      // This is the rule that makes the command feel right: "keep going" is a
      // perfectly good loop prompt and must not be rejected for not being a
      // number.
      final parsed = parseLoopArgs('keep going until the tests pass');
      expect(parsed.isError, isFalse);
      expect(parsed.limit, isNull);
      expect(parsed.prompt, 'keep going until the tests pass');
    });

    test('empty args is an unbounded loop with no prompt', () {
      final parsed = parseLoopArgs('   ');
      expect(parsed.limit, isNull);
      expect(parsed.prompt, isNull);
      expect(parsed.isError, isFalse);
    });

    test('a prompt that merely starts with a word is untouched', () {
      expect(parseLoopArgs('10x the throughput').isError, isTrue);
      expect(parseLoopArgs('ten more times').prompt, 'ten more times');
    });
  });

  group('parseLoopArgs — errors', () {
    test('a token that looks numeric but is not a limit errors', () {
      // It started like a number, so the user meant a limit and got it wrong.
      for (final bad in ['10x', '-1', '1.5h', '0', '+3q']) {
        expect(
          parseLoopArgs('$bad do something').isError,
          isTrue,
          reason: '"$bad" should be reported, not silently treated as prose',
        );
      }
    });

    test('the error names the usage', () {
      expect(parseLoopArgs('10x').error, contains('/loop'));
    });
  });

  group('LoopBudget', () {
    test('an unbounded budget always allows another', () {
      final budget = LoopBudget();
      for (var i = 0; i < 100; i++) {
        expect(budget.allowsAnother(), isTrue);
        budget.recordIteration();
      }
    });

    test('an iteration budget stops at the count', () {
      final budget = LoopBudget(limit: const LoopIterationLimit(3));
      for (var i = 0; i < 3; i++) {
        expect(budget.allowsAnother(), isTrue);
        budget.recordIteration();
      }
      expect(budget.allowsAnother(), isFalse);
      expect(budget.exhaustedReason, contains('3 iterations'));
    });

    test('a duration budget stops once elapsed', () {
      final start = DateTime(2026, 8, 28, 12);
      final budget = LoopBudget(
        limit: const LoopDurationLimit(Duration(minutes: 10)),
        startedAt: start,
      );
      expect(
        budget.allowsAnother(now: start.add(const Duration(minutes: 9))),
        isTrue,
      );
      expect(
        budget.allowsAnother(now: start.add(const Duration(minutes: 11))),
        isFalse,
      );
    });

    test('a duration budget measures ELAPSED time, not a fixed deadline', () {
      // A loop paused by a restart or a take-over resumes with the wall clock
      // it actually consumed, restored from persistence.
      final start = DateTime(2026, 8, 28, 12);
      final resumed = LoopBudget.resumed(
        limit: const LoopDurationLimit(Duration(minutes: 30)),
        startedAt: start,
        completed: 4,
      );
      expect(resumed.completed, 4);
      expect(
        resumed.allowsAnother(now: start.add(const Duration(minutes: 20))),
        isTrue,
      );
    });

    test('describe reports progress in the units the user chose', () {
      final iterations = LoopBudget(limit: const LoopIterationLimit(5))
        ..recordIteration();
      expect(iterations.describe(), 'iteration 2 of 5');

      final start = DateTime(2026, 8, 28, 12);
      final timed = LoopBudget(
        limit: const LoopDurationLimit(Duration(minutes: 30)),
        startedAt: start,
      );
      expect(
        timed.describe(now: start.add(const Duration(minutes: 10))),
        contains('20 minute'),
      );

      expect(LoopBudget().describe(), contains('unbounded'));
    });
  });
}
