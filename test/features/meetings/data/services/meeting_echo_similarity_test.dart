import 'package:control_center/features/meetings/data/services/meeting_echo_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('echoTokens', () {
    test('lowercases, folds punctuation to spaces, splits on whitespace', () {
      expect(
        echoTokens("I've been looking into that too."),
        ['i', 've', 'been', 'looking', 'into', 'that', 'too'],
      );
    });

    test('drops empty tokens from collapsed punctuation', () {
      expect(echoTokens('  Hello,   world!  '), ['hello', 'world']);
    });

    test('empty / punctuation-only text yields no tokens', () {
      expect(echoTokens(''), isEmpty);
      expect(echoTokens('... -- ??'), isEmpty);
    });
  });

  group('echoSimilarity (containment)', () {
    Set<String> toks(String s) => echoTokens(s).toSet();

    test('a clean fragment of the longer line scores 1.0', () {
      final me = toks("I've been looking into that");
      final them =
          toks("I've been looking into that too. Seems like a token management");
      expect(echoSimilarity(me, them), 1.0);
    });

    test('containment is symmetric in argument order', () {
      final shorter = toks('seems like a token management');
      final longer = toks('and it seems like a token management bug today');
      expect(echoSimilarity(shorter, longer), 1.0);
      expect(echoSimilarity(longer, shorter), 1.0);
    });

    test('one differing word still scores above the default threshold', () {
      // "managment" (typo) vs "management" — 4 of 5 shared.
      final me = toks('seems like a token managment');
      final them = toks('seems like a token management bug');
      expect(echoSimilarity(me, them), closeTo(0.8, 1e-9));
    });

    test('unrelated sentences score near zero', () {
      final a = toks('the weather is rather nice today');
      final b = toks('we should ship the release tomorrow');
      expect(echoSimilarity(a, b), lessThan(0.3));
    });

    test('empty sets score zero', () {
      expect(echoSimilarity(<String>{}, toks('anything at all')), 0);
      expect(echoSimilarity(toks('anything at all'), <String>{}), 0);
    });
  });

  group('isEchoMatch', () {
    Set<String> toks(String s) => echoTokens(s).toSet();

    test('matches a fragment at the default threshold', () {
      expect(
        isEchoMatch(
          toks("I've been looking into that"),
          toks("I've been looking into that too seems like a token management"),
        ),
        isTrue,
      );
    });

    test('does not match unrelated text', () {
      expect(
        isEchoMatch(
          toks('lets discuss the budget'),
          toks('the deployment finished successfully'),
        ),
        isFalse,
      );
    });

    test('respects a custom threshold', () {
      final a = toks('alpha beta gamma delta');
      final b = toks('alpha beta epsilon zeta'); // 2/4 = 0.5 overlap
      expect(isEchoMatch(a, b, threshold: 0.6), isFalse);
      expect(isEchoMatch(a, b, threshold: 0.5), isTrue);
    });
  });
}
