import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatRelative', () {
    final DateTime now = DateTime(2024, 6, 15, 12, 0, 0);

    test('returns empty string for null', () {
      expect(formatRelative(null, now: now), '');
    });

    test('returns just now for future date', () {
      expect(
        formatRelative(now.add(const Duration(seconds: 10)), now: now),
        'just now',
      );
    });

    test('returns just now for same time', () {
      expect(formatRelative(now, now: now), 'just now');
    });

    test('returns just now for less than 30 seconds', () {
      expect(
        formatRelative(now.subtract(const Duration(seconds: 10)), now: now),
        'just now',
      );
      expect(
        formatRelative(now.subtract(const Duration(seconds: 29)), now: now),
        'just now',
      );
    });

    test('returns seconds ago for 30+ seconds', () {
      expect(
        formatRelative(now.subtract(const Duration(seconds: 30)), now: now),
        '30s ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(seconds: 45)), now: now),
        '45s ago',
      );
    });

    test('returns minutes ago for 1-59 minutes', () {
      expect(
        formatRelative(now.subtract(const Duration(minutes: 1)), now: now),
        '1m ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(minutes: 30)), now: now),
        '30m ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(minutes: 59)), now: now),
        '59m ago',
      );
    });

    test('returns hours ago for 1-23 hours', () {
      expect(
        formatRelative(now.subtract(const Duration(hours: 1)), now: now),
        '1h ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(hours: 6)), now: now),
        '6h ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(hours: 23)), now: now),
        '23h ago',
      );
    });

    test('returns yesterday for exactly 1 day ago', () {
      expect(
        formatRelative(now.subtract(const Duration(days: 1)), now: now),
        'yesterday',
      );
    });

    test('returns days ago for 2-29 days', () {
      expect(
        formatRelative(now.subtract(const Duration(days: 2)), now: now),
        '2 days ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 14)), now: now),
        '14 days ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 29)), now: now),
        '29 days ago',
      );
    });

    test('returns months ago for 30-364 days', () {
      expect(
        formatRelative(now.subtract(const Duration(days: 30)), now: now),
        '1 months ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 60)), now: now),
        '2 months ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 180)), now: now),
        '6 months ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 364)), now: now),
        '12 months ago',
      );
    });

    test('returns years ago for 365+ days', () {
      expect(
        formatRelative(now.subtract(const Duration(days: 365)), now: now),
        '1 years ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 730)), now: now),
        '2 years ago',
      );
    });

    test('uses DateTime.now() when now parameter is not provided', () {
      final result = formatRelative(
        DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(result, contains('m ago'));
    });

    test('returns minutes ago for exactly 60 seconds', () {
      expect(
        formatRelative(now.subtract(const Duration(seconds: 60)), now: now),
        '1m ago',
      );
    });

    test('returns hours ago for exactly 60 minutes', () {
      expect(
        formatRelative(now.subtract(const Duration(minutes: 60)), now: now),
        '1h ago',
      );
    });

    test('returns days ago for exactly 24 hours', () {
      expect(
        formatRelative(now.subtract(const Duration(hours: 24)), now: now),
        'yesterday',
      );
    });

    test('handles DateTime at epoch start', () {
      expect(
        formatRelative(
          DateTime.fromMillisecondsSinceEpoch(0),
          now: now,
        ),
        '54 years ago',
      );
    });
  });
}
