import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:test/test.dart';

void main() {
  group('SeededPrng', () {
    test('the same seed yields the identical sequence', () {
      final a = SeededPrng(12345);
      final b = SeededPrng(12345);
      final seqA = List<double>.generate(1000, (_) => a.nextDouble());
      final seqB = List<double>.generate(1000, (_) => b.nextDouble());
      expect(seqA, equals(seqB));
    });

    test('different seeds yield different sequences', () {
      final a = SeededPrng(1);
      final b = SeededPrng(2);
      final seqA = List<double>.generate(256, (_) => a.nextDouble());
      final seqB = List<double>.generate(256, (_) => b.nextDouble());
      expect(seqA, isNot(equals(seqB)));
    });

    test('nextDouble stays within [0, 1)', () {
      final prng = SeededPrng(99);
      for (var i = 0; i < 10000; i++) {
        final value = prng.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextRange stays within the requested bounds', () {
      final prng = SeededPrng(7);
      for (var i = 0; i < 10000; i++) {
        final value = prng.nextRange(-3.0, 5.0);
        expect(value, greaterThanOrEqualTo(-3.0));
        expect(value, lessThan(5.0));
      }
    });

    test('nextInt stays within [0, max)', () {
      final prng = SeededPrng(42);
      for (var i = 0; i < 10000; i++) {
        final value = prng.nextInt(6);
        expect(value, inInclusiveRange(0, 5));
      }
    });

    test('nextInt rejects a non-positive bound', () {
      final prng = SeededPrng(1);
      expect(() => prng.nextInt(0), throwsArgumentError);
      expect(() => prng.nextInt(-4), throwsArgumentError);
    });

    test('nextBool respects extreme probabilities', () {
      final prng = SeededPrng(3);
      for (var i = 0; i < 1000; i++) {
        expect(prng.nextBool(0.0), isFalse);
      }
      for (var i = 0; i < 1000; i++) {
        expect(prng.nextBool(1.0), isTrue);
      }
    });

    test('a zero seed still produces a usable, varying sequence', () {
      final prng = SeededPrng(0);
      final values = List<double>.generate(64, (_) => prng.nextDouble());
      expect(values.toSet().length, greaterThan(1));
    });

    test('the sequence is stable across construction order', () {
      final a = SeededPrng(555);
      // Draw from a second generator in between; the first must be unaffected.
      final noise = SeededPrng(777);
      noise.nextDouble();
      final first = a.nextDouble();
      final control = SeededPrng(555).nextDouble();
      expect(first, equals(control));
    });
  });
}
