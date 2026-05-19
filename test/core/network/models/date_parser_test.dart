import 'package:cc_infra/src/network/models/date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDate', () {
    test('parses valid ISO 8601 date string', () {
      final result = parseDate('2024-01-15T10:30:00Z');
      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('parses date-only string', () {
      final result = parseDate('2024-01-15');
      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('returns null for empty string', () {
      expect(parseDate(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(parseDate('   '), isNull);
    });

    test('returns null for invalid date string', () {
      expect(parseDate('not-a-date'), isNull);
    });

    test('returns null for null input', () {
      expect(parseDate(null), isNull);
    });

    test('returns null for non-string input', () {
      expect(parseDate(42), isNull);
    });

    test('returns null for list input', () {
      expect(parseDate([1, 2, 3]), isNull);
    });

    test('returns null for map input', () {
      expect(parseDate({'date': '2024-01-15'}), isNull);
    });

    test('parses date with timezone offset', () {
      final result = parseDate('2024-06-20T15:45:00+02:00');
      expect(result, isNotNull);
      expect(result!.hour, 13);
    });

    test('parses date with milliseconds', () {
      final result = parseDate('2024-12-31T23:59:59.999Z');
      expect(result, isNotNull);
      expect(result!.millisecond, 999);
    });
  });
}
