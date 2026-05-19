import 'package:control_center/features/sandboxing/data/runtime/domain_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchesAny', () {
    test('exact match is case-insensitive and ignores whitespace', () {
      expect(matchesAny('Github.com', ['github.com']), isTrue);
      expect(matchesAny('  github.com  '.trim(), ['github.com']), isTrue);
    });

    test('apex does NOT match a wildcard pattern', () {
      // Mirrors the reference runtime: list both forms when you want both.
      expect(matchesAny('example.com', ['*.example.com']), isFalse);
    });

    test('wildcard matches direct + nested subdomains', () {
      expect(matchesAny('api.example.com', ['*.example.com']), isTrue);
      expect(matchesAny('a.b.example.com', ['*.example.com']), isTrue);
    });

    test('wildcard never matches a sibling-host', () {
      expect(matchesAny('badexample.com', ['*.example.com']), isFalse);
    });

    test('empty host or empty pattern list returns false', () {
      expect(matchesAny('', ['github.com']), isFalse);
      expect(matchesAny('github.com', const <String>[]), isFalse);
    });
  });
}
