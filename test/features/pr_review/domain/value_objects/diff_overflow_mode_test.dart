import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiffOverflowMode', () {
    test('has wrap and scroll values', timeout: const Timeout.factor(2), () {
      expect(DiffOverflowMode.values, containsAll([
        DiffOverflowMode.wrap,
        DiffOverflowMode.scroll,
      ]));
    });

    test('fromName parses wrap', timeout: const Timeout.factor(2), () {
      expect(DiffOverflowMode.fromName('wrap'), DiffOverflowMode.wrap);
    });

    test('fromName parses scroll', timeout: const Timeout.factor(2), () {
      expect(DiffOverflowMode.fromName('scroll'), DiffOverflowMode.scroll);
    });

    test('fromName defaults to wrap for null', timeout: const Timeout.factor(2), () {
      expect(DiffOverflowMode.fromName(null), DiffOverflowMode.wrap);
    });

    test('fromName defaults to wrap for unknown values', timeout: const Timeout.factor(2), () {
      expect(DiffOverflowMode.fromName('unknown'), DiffOverflowMode.wrap);
      expect(DiffOverflowMode.fromName(''), DiffOverflowMode.wrap);
      expect(DiffOverflowMode.fromName('WRAP'), DiffOverflowMode.wrap);
    });
  });
}
