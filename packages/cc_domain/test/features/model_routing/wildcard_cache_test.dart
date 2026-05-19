import 'package:cc_domain/features/model_routing/domain/services/wildcard.dart';
import 'package:test/test.dart';

/// `Wildcard` memoizes compiled patterns in a `static` map, and the keys come
/// from OUTSIDE: routing rules, policy globs, allow-list entries typed into
/// settings. Unbounded, that is a slow leak in a server process that runs for
/// weeks — and a space between tests in the same file, since every test
/// shares the one map.
void main() {
  setUp(Wildcard.clearCache);
  tearDown(Wildcard.clearCache);

  test('still matches the way it did', () {
    expect(Wildcard.match('openai/gpt-5', 'openai/*'), isTrue);
    expect(Wildcard.match('openai/gpt-5', 'anthropic/*'), isFalse);
    expect(Wildcard.match('a/b', 'a/?'), isTrue);
    expect(Wildcard.match('a/bc', 'a/?'), isFalse);
    // Regex metacharacters in the pattern are literal.
    expect(Wildcard.match('a.b', 'a.b'), isTrue);
    expect(Wildcard.match('axb', 'a.b'), isFalse);
    // Backslashes normalize to forward slashes on both sides.
    expect(Wildcard.match(r'a\b', 'a/b'), isTrue);
  });

  test('a flood of distinct patterns does not grow without bound', () {
    // Far past the cap; each is a pattern a caller could plausibly supply.
    for (var i = 0; i < 5000; i++) {
      expect(Wildcard.match('provider/model-$i', 'provider/model-$i'), isTrue);
    }
    // The cap is private, so assert the property rather than the number: the
    // map must not have kept one entry per call.
    expect(Wildcard.debugCacheSize, lessThanOrEqualTo(256));
  });

  test('an evicted pattern still matches (the cache is not the answer)', () {
    expect(Wildcard.match('openai/gpt-5', 'openai/*'), isTrue);
    for (var i = 0; i < 5000; i++) {
      Wildcard.match('x', 'pattern-$i');
    }
    expect(
      Wildcard.match('openai/gpt-5', 'openai/*'),
      isTrue,
      reason: 'eviction may cost a recompile; it must never change a verdict',
    );
  });
}
