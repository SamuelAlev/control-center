import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:test/test.dart';

SoundscapeContext _context({
  SoundscapeMood mood = SoundscapeMood.focus,
  SoundscapeDaypart daypart = SoundscapeDaypart.day,
  SoundscapeWeather weather = SoundscapeWeather.clear,
  bool isDay = true,
  double temperatureCelsius = 20.0,
}) => SoundscapeContext(
  mood: mood,
  daypart: daypart,
  weather: weather,
  isDay: isDay,
  temperatureCelsius: temperatureCelsius,
);

void main() {
  group('SoundscapeContext.contextHash', () {
    test('is deterministic across repeated reads', () {
      final ctx = _context();
      expect(ctx.contextHash, equals(ctx.contextHash));
      expect(ctx.seed, equals(ctx.seed));
    });

    test('is stable across independent equal instances', () {
      expect(_context().contextHash, equals(_context().contextHash));
      expect(_context().seed, equals(_context().seed));
    });

    test('temperature bucketing collapses nearby values', () {
      final a = _context(temperatureCelsius: 20.1);
      final b = _context(temperatureCelsius: 21.9);
      expect(a.contextHash, equals(b.contextHash));
      expect(a.seed, equals(b.seed));
    });

    test('far-apart temperatures fall into different buckets', () {
      final cold = _context(temperatureCelsius: 2.0);
      final hot = _context(temperatureCelsius: 30.0);
      expect(cold.contextHash, isNot(equals(hot.contextHash)));
    });

    test('differs when the mood differs', () {
      final focus = _context(mood: SoundscapeMood.focus);
      final sleep = _context(mood: SoundscapeMood.sleep);
      expect(focus.contextHash, isNot(equals(sleep.contextHash)));
      expect(focus.seed, isNot(equals(sleep.seed)));
    });

    test('differs when the weather differs', () {
      final clear = _context(weather: SoundscapeWeather.clear);
      final storm = _context(weather: SoundscapeWeather.storm);
      expect(clear.contextHash, isNot(equals(storm.contextHash)));
    });

    test('differs when the daypart or day flag differs', () {
      final day = _context(daypart: SoundscapeDaypart.day, isDay: true);
      final night = _context(daypart: SoundscapeDaypart.night, isDay: false);
      expect(day.contextHash, isNot(equals(night.contextHash)));
    });

    test('is an 8-char lowercase hex string', () {
      expect(_context().contextHash, matches(RegExp(r'^[0-9a-f]{8}$')));
    });
  });

  group('SoundscapeContext value semantics', () {
    test('equal contexts compare equal and share a hashCode', () {
      expect(_context(), equals(_context()));
      expect(_context().hashCode, equals(_context().hashCode));
    });

    test('equal contexts share hash and seed', () {
      final a = _context();
      final b = _context();
      expect(a.contextHash, equals(b.contextHash));
      expect(a.seed, equals(b.seed));
    });

    test(
      'exact temperature is part of equality even when buckets collapse',
      () {
        final a = _context(temperatureCelsius: 20.1);
        final b = _context(temperatureCelsius: 21.9);
        // Same audible bucket, but not the same value object.
        expect(a, isNot(equals(b)));
        expect(a.contextHash, equals(b.contextHash));
      },
    );

    test('copyWith replaces only the given fields', () {
      final base = _context();
      final updated = base.copyWith(weather: SoundscapeWeather.rain);
      expect(updated.weather, SoundscapeWeather.rain);
      expect(updated.mood, base.mood);
      expect(updated.daypart, base.daypart);
      expect(updated.isDay, base.isDay);
      expect(updated.temperatureCelsius, base.temperatureCelsius);
    });
  });
}
