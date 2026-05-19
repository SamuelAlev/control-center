import 'package:cc_infra/src/sandboxing/domain_matcher.dart';
import 'package:test/test.dart';

/// Pins the sandbox egress allow/deny host matcher. A single leading `*.`
/// wildcard matches subdomains (not the apex); everything else is an exact,
/// case-insensitive match. This is the gate the in-process proxy uses to
/// decide whether an agent's outbound connection is allowed.
void main() {
  group('matchesAny — exact host matching', () {
    test('exact match (case-insensitive)', () {
      expect(matchesAny('api.github.com', ['api.github.com']), isTrue);
      expect(matchesAny('API.GitHub.com', ['api.github.com']), isTrue);
      expect(matchesAny('api.github.com ', ['  api.github.com  ']), isTrue);
    });

    test('non-matching host returns false', () {
      expect(matchesAny('api.gitlab.com', ['api.github.com']), isFalse);
    });

    test('returns the first hit among several patterns', () {
      expect(
        matchesAny('b.example.com', ['a.example.com', 'b.example.com']),
        isTrue,
      );
    });
  });

  group('matchesAny — empty / edge inputs', () {
    test('empty host never matches', () {
      expect(matchesAny('', ['example.com']), isFalse);
    });

    test('empty pattern never matches', () {
      expect(matchesAny('example.com', ['']), isFalse);
    });

    test('empty pattern list never matches', () {
      expect(matchesAny('example.com', <String>[]), isFalse);
    });
  });

  group('matchesAny — *.<apex> wildcard', () {
    test('matches a one-level subdomain', () {
      expect(matchesAny('foo.example.com', ['*.example.com']), isTrue);
    });

    test('matches a multi-level subdomain', () {
      expect(matchesAny('a.b.example.com', ['*.example.com']), isTrue);
    });

    test('does NOT match the apex itself', () {
      expect(matchesAny('example.com', ['*.example.com']), isFalse);
    });

    test('does not match a sibling suffix that merely ends the same way', () {
      // `.example.com` suffix guard: `evilexample.com` must not match.
      expect(matchesAny('evilexample.com', ['*.example.com']), isFalse);
      expect(matchesAny('foo.evilexample.com', ['*.example.com']), isFalse);
    });

    test('wildcard is case-insensitive', () {
      expect(matchesAny('Foo.Example.COM', ['*.EXAMPLE.com']), isTrue);
    });
  });
}
