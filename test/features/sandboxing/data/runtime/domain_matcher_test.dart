import 'package:cc_infra/src/sandboxing/domain_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchesAny', () {
    group('empty host', () {
      test('returns false for empty string', () {
        expect(matchesAny('', ['example.com']), false);
      });

      test('returns false even when patterns is empty', () {
        expect(matchesAny('', <String>[]), false);
      });
    });

    group('exact match', () {
      test('returns true when host equals pattern exactly', () {
        expect(matchesAny('example.com', ['example.com']), true);
      });

      test('returns true case-insensitively', () {
        expect(matchesAny('EXAMPLE.COM', ['example.com']), true);
      });

      test('returns true when host has mixed case', () {
        expect(matchesAny('Example.Com', ['example.com']), true);
      });

      test('returns false when no pattern matches', () {
        expect(matchesAny('example.com', ['other.com']), false);
      });
    });

    group('wildcard patterns', () {
      test('matches subdomain with *. prefix', () {
        expect(matchesAny('foo.example.com', ['*.example.com']), true);
      });

      test('matches deep subdomain with *. prefix', () {
        expect(matchesAny('a.b.example.com', ['*.example.com']), true);
      });

      test('does not match apex domain with wildcard alone', () {
        expect(matchesAny('example.com', ['*.example.com']), false);
      });

      test('matches apex when both apex and wildcard listed', () {
        expect(
          matchesAny('example.com', ['example.com', '*.example.com']),
          true,
        );
      });

      test('matches subdomain when both apex and wildcard listed', () {
        expect(
          matchesAny('sub.example.com', ['example.com', '*.example.com']),
          true,
        );
      });
    });

    group('whitespace trimming', () {
      test('trims whitespace from host', () {
        expect(matchesAny('  example.com  ', ['example.com']), true);
      });

      test('trims whitespace from pattern', () {
        expect(matchesAny('example.com', ['  example.com  ']), true);
      });
    });

    group('multiple patterns', () {
      test('returns true when any pattern matches', () {
        expect(
          matchesAny('example.com', ['other.com', 'example.com']),
          true,
        );
      });

      test('returns false when no pattern matches among many', () {
        expect(
          matchesAny('example.com', ['a.com', 'b.com', 'c.com']),
          false,
        );
      });

      test('short-circuits on first match', () {
        expect(
          matchesAny('example.com', ['example.com', 'nonexistent.com']),
          true,
        );
      });
    });

    group('empty patterns list', () {
      test('returns false', () {
        expect(matchesAny('example.com', <String>[]), false);
      });
    });

    group('empty pattern string', () {
      test('skips empty pattern entries', () {
        expect(matchesAny('example.com', ['']), false);
      });

      test('skips empty pattern but matches another', () {
        expect(matchesAny('example.com', ['', 'example.com']), true);
      });
    });

    group('partial substring', () {
      test('does not match partial host as suffix match', () {
        // example.com should not match "ample.com" even as wildcard
        expect(matchesAny('example.com', ['*.ample.com']), false);
      });

      test('does not match pattern that is substring of host', () {
        expect(matchesAny('sub.example.com', ['example.com']), false);
      });

      test('does not match host that is substring of pattern', () {
        expect(matchesAny('example.com', ['sub.example.com']), false);
      });
    });
  });
}
