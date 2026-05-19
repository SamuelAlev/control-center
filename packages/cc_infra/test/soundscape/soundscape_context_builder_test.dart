import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_infra/src/soundscape/soundscape_context_builder.dart';
import 'package:test/test.dart';

void main() {
  const builder = SoundscapeContextBuilder();

  WeatherSnapshot snapshot({
    WeatherCondition condition = WeatherCondition.clear,
    bool isDay = true,
    double temperatureCelsius = 18,
    double windSpeedKmh = 5,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    return WeatherSnapshot(
      latitude: 47.4,
      longitude: 8.5,
      condition: condition,
      isDay: isDay,
      temperatureCelsius: temperatureCelsius,
      windSpeedKmh: windSpeedKmh,
      sunrise: sunrise,
      sunset: sunset,
      observedAt: DateTime.utc(2026, 7, 13, 12),
    );
  }

  group('SoundscapeContextBuilder', () {
    test('maps weather condition by name', () {
      final ctx = builder.build(
        mood: SoundscapeMood.relax,
        weather: snapshot(condition: WeatherCondition.rain),
        now: DateTime(2026, 7, 13, 13),
      );
      expect(ctx.weather, SoundscapeWeather.rain);
      expect(ctx.mood, SoundscapeMood.relax);
    });

    test('a strong wind overrides an otherwise clear sky', () {
      final ctx = builder.build(
        mood: SoundscapeMood.focus,
        weather: snapshot(condition: WeatherCondition.clear, windSpeedKmh: 60),
        now: DateTime(2026, 7, 13, 13),
      );
      expect(ctx.weather, SoundscapeWeather.wind);
    });

    test('a strong wind does NOT override rain/storm', () {
      final ctx = builder.build(
        mood: SoundscapeMood.focus,
        weather: snapshot(condition: WeatherCondition.storm, windSpeedKmh: 80),
        now: DateTime(2026, 7, 13, 13),
      );
      expect(ctx.weather, SoundscapeWeather.storm);
    });

    test('null weather yields a safe default context', () {
      final ctx = builder.build(
        mood: SoundscapeMood.sleep,
        weather: null,
        now: DateTime(2026, 7, 13, 3),
      );
      expect(ctx.weather, SoundscapeWeather.clear);
      expect(ctx.temperatureCelsius, 15.0);
      // 3am with no sun data buckets to night.
      expect(ctx.daypart, SoundscapeDaypart.night);
      expect(ctx.isDay, isFalse);
    });

    test('daypart buckets by local hour when no sun data', () {
      SoundscapeDaypart at(int hour) => builder
          .build(
            mood: SoundscapeMood.focus,
            weather: null,
            now: DateTime(2026, 7, 13, hour),
          )
          .daypart;
      expect(at(6), SoundscapeDaypart.dawn);
      expect(at(9), SoundscapeDaypart.morning);
      expect(at(14), SoundscapeDaypart.day);
      expect(at(18), SoundscapeDaypart.dusk);
      expect(at(23), SoundscapeDaypart.night);
    });

    test('daypart uses sunrise/sunset when present', () {
      final sunrise = DateTime(2026, 7, 13, 6);
      final sunset = DateTime(2026, 7, 13, 21);
      SoundscapeDaypart at(DateTime now) => builder
          .build(
            mood: SoundscapeMood.focus,
            weather: snapshot(sunrise: sunrise, sunset: sunset),
            now: now,
          )
          .daypart;
      // Well before sunrise → night.
      expect(at(DateTime(2026, 7, 13, 4)), SoundscapeDaypart.night);
      // Just after sunrise → dawn.
      expect(at(DateTime(2026, 7, 13, 6, 30)), SoundscapeDaypart.dawn);
      // Midday → day.
      expect(at(DateTime(2026, 7, 13, 13)), SoundscapeDaypart.day);
      // Just before sunset → dusk.
      expect(at(DateTime(2026, 7, 13, 20, 30)), SoundscapeDaypart.dusk);
      // Well after sunset → night.
      expect(at(DateTime(2026, 7, 13, 23)), SoundscapeDaypart.night);
    });

    test('isDay prefers the snapshot flag', () {
      final ctx = builder.build(
        mood: SoundscapeMood.focus,
        weather: snapshot(isDay: false),
        now: DateTime(2026, 7, 13, 13),
      );
      expect(ctx.isDay, isFalse);
    });
  });
}
