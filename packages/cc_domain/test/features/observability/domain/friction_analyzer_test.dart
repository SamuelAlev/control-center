import 'package:cc_domain/features/observability/domain/friction_analyzer.dart';
import 'package:test/test.dart';

void main() {
  const analyzer = FrictionAnalyzer();

  group('FrictionMetrics', () {
    test('empty has all fields zero', () {
      expect(FrictionMetrics.empty.chars, 0);
      expect(FrictionMetrics.empty.words, 0);
      expect(FrictionMetrics.empty.yelling, 0);
      expect(FrictionMetrics.empty.profanity, 0);
      expect(FrictionMetrics.empty.anguish, 0);
      expect(FrictionMetrics.empty.negation, 0);
      expect(FrictionMetrics.empty.repetition, 0);
      expect(FrictionMetrics.empty.blame, 0);
      expect(FrictionMetrics.empty.totalSignals, 0);
    });

    test('totalSignals sums the six signals only', () {
      const m = FrictionMetrics(
        chars: 100,
        words: 20,
        yelling: 1,
        profanity: 2,
        anguish: 3,
        negation: 4,
        repetition: 5,
        blame: 6,
      );
      expect(m.totalSignals, 21);
    });

    test('equality and hashCode are structural', () {
      const a = FrictionMetrics(chars: 5, words: 1, profanity: 2);
      const b = FrictionMetrics(chars: 5, words: 1, profanity: 2);
      const c = FrictionMetrics(chars: 5, words: 1, profanity: 3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('empty equals a default-constructed instance', () {
      expect(FrictionMetrics.empty, equals(const FrictionMetrics()));
    });
  });

  group('chars and words', () {
    test('empty string yields all zero', () {
      final m = analyzer.analyze('');
      expect(m, equals(FrictionMetrics.empty));
      expect(m.chars, 0);
      expect(m.words, 0);
      expect(m.totalSignals, 0);
    });

    test('whitespace-only string has chars but zero words', () {
      final m = analyzer.analyze('   \n  \t ');
      expect(m.chars, '   \n  \t '.length);
      expect(m.words, 0);
      expect(m.totalSignals, 0);
    });

    test('chars is raw length, words is whitespace-split', () {
      const text = 'hello there friend';
      final m = analyzer.analyze(text);
      expect(m.chars, text.length);
      expect(m.words, 3);
    });

    test('multiple whitespace between words counts words correctly', () {
      final m = analyzer.analyze('one   two\tthree\nfour');
      expect(m.words, 4);
    });
  });

  group('yelling', () {
    test('all-caps shout is counted', () {
      final m = analyzer.analyze('THIS IS BROKEN');
      expect(m.yelling, greaterThanOrEqualTo(1));
    });

    test('lowercase calm sentence is not yelling', () {
      final m = analyzer.analyze('this is fine and calm');
      expect(m.yelling, 0);
    });

    test('short all-caps token below min letters is ignored', () {
      // "OK" has only 2 letters, below MIN_LETTERS=4.
      final m = analyzer.analyze('OK');
      expect(m.yelling, 0);
    });

    test('sentence just at the letter floor counts when all caps', () {
      // "WHYY" = 4 letters, all uppercase.
      final m = analyzer.analyze('WHYY');
      expect(m.yelling, greaterThanOrEqualTo(1));
    });

    test('mostly-lowercase sentence under threshold is not yelling', () {
      // "Hello world" -> 2 uppercase of 10 letters = 0.2, under 0.5.
      final m = analyzer.analyze('Hello world');
      expect(m.yelling, 0);
    });

    test('exactly half uppercase does NOT count (threshold is strict >)', () {
      // "AAbb" -> 2 upper of 4 letters = 0.5, which is not strictly > 0.5.
      // Pins the boundary so flipping `>` to `>=` is caught.
      final m = analyzer.analyze('AAbb');
      expect(m.yelling, 0);
    });

    test('just over half uppercase counts', () {
      // "AAAb" -> 3 upper of 4 letters = 0.75, > 0.5.
      final m = analyzer.analyze('AAAb');
      expect(m.yelling, 1);
    });

    test('uppercase run below the letter floor is ignored even at 100%', () {
      // "I AM" -> 3 letters total, below MIN_LETTERS=4, so never yelling.
      final m = analyzer.analyze('I AM');
      expect(m.yelling, 0);
    });
  });

  group('profanity', () {
    test('single profanity word counts once', () {
      final m = analyzer.analyze('this is shit');
      expect(m.profanity, 1);
    });

    test('case-insensitive matching', () {
      final m = analyzer.analyze('DAMN this');
      expect(m.profanity, greaterThanOrEqualTo(1));
    });

    test('multiple profanity occurrences each count', () {
      final m = analyzer.analyze('damn it crap fml');
      expect(m.profanity, 3);
    });

    test('grr frustration grunt counts as profanity', () {
      final m = analyzer.analyze('grr');
      expect(m.profanity, 1);
    });

    test('word boundary prevents substring false positives', () {
      // "class" contains "ass" but should not match on a boundary.
      final m = analyzer.analyze('a tidy class');
      expect(m.profanity, 0);
    });
  });

  group('anguish', () {
    test('elongated nooo and ughhh and ellipsis are counted', () {
      final m = analyzer.analyze('nooo ughhh ...');
      // nooo (interjection) + ughhh (interjection) + ... (ellipsis) = 3
      expect(m.anguish, 3);
    });

    test('drama run of punctuation counts', () {
      final m = analyzer.analyze('what?!?!');
      expect(m.anguish, greaterThanOrEqualTo(1));
    });

    test('dude is counted as anguish', () {
      final m = analyzer.analyze('dude');
      expect(m.anguish, 1);
    });

    test('plain calm sentence has no anguish', () {
      final m = analyzer.analyze('please update the readme');
      expect(m.anguish, 0);
    });

    test('a run of dots counts once, not once per dot', () {
      // "...." is a single ellipsis match (greedy run), not four.
      final m = analyzer.analyze('hey ....');
      expect(m.anguish, 1);
    });

    test('short "ugh" without a doubled h is not an interjection', () {
      // The pattern requires u+g+h{2,}; a single trailing h must not match.
      final m = analyzer.analyze('ugh');
      expect(m.anguish, 0);
    });
  });

  group('negation', () {
    test("no, that's not what i meant counts both lead and phrase", () {
      final m = analyzer.analyze("no, that's not what i meant");
      // line-leading "no" + phrase "not what i meant" = 2
      expect(m.negation, 2);
    });

    test('line-leading nope counts', () {
      final m = analyzer.analyze('nope');
      expect(m.negation, 1);
    });

    test("that's not right counts as a phrase", () {
      final m = analyzer.analyze("that's not right");
      expect(m.negation, greaterThanOrEqualTo(1));
    });

    test('agreeable sentence has no negation', () {
      final m = analyzer.analyze('yes please proceed');
      expect(m.negation, 0);
    });
  });

  group('repetition', () {
    test('like i said counts', () {
      final m = analyzer.analyze('like i said earlier');
      expect(m.repetition, 1);
    });

    test("still doesn't work counts", () {
      final m = analyzer.analyze("still doesn't work");
      expect(m.repetition, 1);
    });

    test('i already told you counts', () {
      final m = analyzer.analyze('i already told you this');
      expect(m.repetition, greaterThanOrEqualTo(1));
    });

    test('fresh instruction has no repetition cue', () {
      final m = analyzer.analyze('add a button to the page');
      expect(m.repetition, 0);
    });
  });

  group('blame', () {
    test('you forgot to ... counts', () {
      final m = analyzer.analyze('you forgot to save the file');
      expect(m.blame, 1);
    });

    test('imperative stop doing X counts', () {
      final m = analyzer.analyze('stop deleting things');
      expect(m.blame, greaterThanOrEqualTo(1));
    });

    test("you didn't even try counts", () {
      final m = analyzer.analyze("you didn't even try");
      expect(m.blame, greaterThanOrEqualTo(1));
    });

    test('neutral request has no blame', () {
      final m = analyzer.analyze('please add tests');
      expect(m.blame, 0);
    });

    test('mid-sentence "stop ...ing" is not blame (needs sentence start)', () {
      // The imperative-stop pattern is anchored to ^/.!?\n; an inline "stop"
      // must not match, so flipping the anchor off is caught here.
      final m = analyzer.analyze('please stop running');
      expect(m.blame, 0);
    });

    test('word-boundary keeps "hell" out of "hello" but counts standalone', () {
      expect(analyzer.analyze('hello world').profanity, 0);
      expect(analyzer.analyze('what the hell').profanity, 1);
    });
  });

  group('line gate', () {
    test('calm 5-line formatted prompt suppresses all signals', () {
      const prompt =
          'Please do the following:\n'
          'First, you forgot the imports.\n'
          'Second, this is SHIT and BROKEN.\n'
          "Third, no that's not what i meant.\n"
          'Fourth, like i said before, fix it.';
      final m = analyzer.analyze(prompt);
      expect(m.chars, prompt.length);
      expect(m.words, greaterThan(0));
      // Gated: every signal forced to zero despite the loaded content.
      expect(m.yelling, 0);
      expect(m.profanity, 0);
      expect(m.anguish, 0);
      expect(m.negation, 0);
      expect(m.repetition, 0);
      expect(m.blame, 0);
      expect(m.totalSignals, 0);
    });

    test('two non-empty lines are below the gate and still scored', () {
      const text = 'you forgot the tests\nthis is SHIT';
      final m = analyzer.analyze(text);
      expect(m.totalSignals, greaterThan(0));
    });

    test('blank lines between content do not push past the gate', () {
      // Two non-empty lines separated by a blank line: still under the gate.
      const text = 'you forgot something\n\nyou broke the build';
      final m = analyzer.analyze(text);
      expect(m.blame, greaterThanOrEqualTo(2));
    });

    test('three non-empty lines hit the gate exactly', () {
      const text = 'you forgot a\nyou forgot b\nyou forgot c';
      final m = analyzer.analyze(text);
      expect(m.totalSignals, 0);
    });
  });

  group('preprocessing strips structured noise before scoring', () {
    test('fenced code block content does not count as yelling', () {
      const text = '```\nSELECT * FROM USERS WHERE ID = 1\n```';
      final m = analyzer.analyze(text);
      expect(m.yelling, 0);
    });

    test('inline code is stripped before profanity scan', () {
      final m = analyzer.analyze('run `damn_tool --shit` now');
      expect(m.profanity, 0);
    });

    test('urls are stripped so their text does not score', () {
      final m = analyzer.analyze('see https://example.com/STOP/NOW for info');
      expect(m.yelling, 0);
    });

    test('quote lines are removed entirely', () {
      // The quoted line carries blame; once removed nothing remains to score.
      const text = '> you forgot the imports';
      final m = analyzer.analyze(text);
      expect(m.blame, 0);
    });

    test('file mentions are stripped', () {
      final m = analyzer.analyze('look at @src/STOP/now.dart');
      // The @-mention is replaced with a space; no all-caps sentence survives.
      expect(m.yelling, 0);
    });

    test('image markers are stripped', () {
      final m = analyzer.analyze('[Image #1] looks fine');
      expect(m.totalSignals, 0);
    });

    test('paired html tags collapse and do not leave yelling content', () {
      const text = '<b>THIS IS LOUD</b>';
      final m = analyzer.analyze(text);
      expect(m.yelling, 0);
    });
  });

  group('combined realistic frustrated message', () {
    test('single line with several signals accumulates totals', () {
      const text = 'no you forgot it AGAIN, this is SHIT ugh dude...';
      final m = analyzer.analyze(text);
      expect(m.negation, greaterThanOrEqualTo(1));
      expect(m.blame, greaterThanOrEqualTo(1));
      expect(m.profanity, greaterThanOrEqualTo(1));
      expect(m.anguish, greaterThanOrEqualTo(1));
      expect(m.totalSignals, greaterThan(3));
    });
  });
}
