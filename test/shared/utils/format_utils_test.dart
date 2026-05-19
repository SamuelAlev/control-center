import 'package:control_center/shared/utils/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTime', () {
    test('formats morning time with zero padding', () {
      expect(formatTime(DateTime(2024, 1, 15, 9, 5)), '09:05');
    });

    test('formats midday time', () {
      expect(formatTime(DateTime(2024, 1, 15, 12, 30)), '12:30');
    });

    test('formats evening time', () {
      expect(formatTime(DateTime(2024, 1, 15, 23, 59)), '23:59');
    });

    test('formats midnight', () {
      expect(formatTime(DateTime(2024, 1, 15, 0, 0)), '00:00');
    });

    test('formats single-digit hour', () {
      expect(formatTime(DateTime(2024, 1, 15, 3, 15)), '03:15');
    });

    test('formats single-digit minute', () {
      expect(formatTime(DateTime(2024, 1, 15, 10, 7)), '10:07');
    });

    test('formats hour 23', () {
      expect(formatTime(DateTime(2024, 6, 20, 23, 0)), '23:00');
    });

    test('formats time with seconds ignored', () {
      expect(formatTime(DateTime(2024, 1, 15, 14, 45, 30)), '14:45');
    });

    test('formats different dates consistently', () {
      expect(formatTime(DateTime(2023, 12, 31, 0, 1)), '00:01');
      expect(formatTime(DateTime(2025, 6, 1, 18, 30)), '18:30');
    });
  });
}
