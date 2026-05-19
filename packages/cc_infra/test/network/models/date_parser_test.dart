import 'package:cc_infra/src/network/models/date_parser.dart';
import 'package:test/test.dart';

/// Pins [parseDate] — the three branches (non-string, empty string, real
/// ISO date) gate every timestamp the GitHub/Calendar models read.
void main() {
  test('parses a valid ISO-8601 string', () {
    expect(
      parseDate('2026-01-02T03:04:05Z'),
      DateTime.utc(2026, 1, 2, 3, 4, 5),
    );
  });

  test('returns null for null', () {
    expect(parseDate(null), isNull);
  });

  test('returns null for non-string values', () {
    expect(parseDate(42), isNull);
    expect(parseDate(<String, dynamic>{}), isNull);
    expect(parseDate(['2026-01-01']), isNull);
  });

  test('returns null for an empty string', () {
    expect(parseDate(''), isNull);
  });

  test('returns null for a malformed string', () {
    expect(parseDate('not-a-date'), isNull);
  });

  test('parses a date-only string', () {
    expect(parseDate('2026-02-03'), DateTime(2026, 2, 3));
  });
}
