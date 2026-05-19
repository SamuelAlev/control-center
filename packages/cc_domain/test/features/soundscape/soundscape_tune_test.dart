import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';
import 'package:test/test.dart';

void main() {
  group('SoundscapeTune', () {
    test('clamps both axes to [0, 1]', () {
      final tune = SoundscapeTune(energy: -0.4, brightness: 1.8);
      expect(tune.energy, 0.0);
      expect(tune.brightness, 1.0);
    });

    test('neutral is the pad center', () {
      expect(SoundscapeTune.neutral.energy, 0.5);
      expect(SoundscapeTune.neutral.brightness, 0.5);
    });

    test('value semantics', () {
      final a = SoundscapeTune(energy: 0.2, brightness: 0.7);
      final b = SoundscapeTune(energy: 0.2, brightness: 0.7);
      final c = SoundscapeTune(energy: 0.3, brightness: 0.7);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces and clamps', () {
      final tune = SoundscapeTune(
        energy: 0.2,
        brightness: 0.7,
      ).copyWith(energy: 2.0);
      expect(tune.energy, 1.0);
      expect(tune.brightness, 0.7);
    });
  });
}
