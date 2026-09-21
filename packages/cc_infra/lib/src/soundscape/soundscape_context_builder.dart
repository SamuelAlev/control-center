import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';

/// Folds the ambient inputs the server owns — the live weather and the clock —
/// together with the listener's chosen [SoundscapeMood] into the immutable
/// [SoundscapeContext] the generative engine renders from.
///
/// This is where "adapt to weather and time of day" actually happens: the
/// weather condition maps to the soundscape's weather palette (a strong wind
/// overrides an otherwise calm sky) and the local clock — refined by the real
/// sunrise/sunset when the snapshot carries them — resolves the daypart. Pure
/// and side-effect-free so it is trivially unit-testable.
class SoundscapeContextBuilder {
  /// Creates a builder. [windThresholdKmh] is the sustained wind speed above
  /// which an otherwise clear/cloudy sky is treated as [SoundscapeWeather.wind].
  const SoundscapeContextBuilder({this.windThresholdKmh = 35.0});

  /// Wind speed (km/h) above which the weather palette becomes `wind`.
  final double windThresholdKmh;

  /// Builds the context for [mood] given the current [weather] (nullable before
  /// the first fetch) and the current local time [now].
  SoundscapeContext build({
    required SoundscapeMood mood,
    required WeatherSnapshot? weather,
    required DateTime now,
  }) {
    final daypart = _daypart(now, weather);
    final isDay = weather?.isDay ?? (daypart != SoundscapeDaypart.night);
    return SoundscapeContext(
      mood: mood,
      daypart: daypart,
      weather: _weather(weather),
      isDay: isDay,
      temperatureCelsius: weather?.temperatureCelsius ?? 15.0,
      dayLengthHours: _dayLengthHours(weather),
    );
  }

  /// Sunset − sunrise in hours.
  ///
  /// Unknown weather (no snapshot at all) is a temperate 12 h so Rise does
  /// not guess at seasonal energy. A snapshot with no sun times, or a
  /// non-positive interval, is polar night / no daylight (0 h) — Open-Meteo
  /// omits sunrise/sunset when the sun does not rise. Overflow past a solar
  /// day is clamped to 24 h (polar day).
  static double _dayLengthHours(WeatherSnapshot? w) {
    if (w == null) {
      return 12.0;
    }
    final sunrise = w.sunrise;
    final sunset = w.sunset;
    if (sunrise == null || sunset == null) {
      return 0.0;
    }
    final hours =
        sunset.difference(sunrise).inMicroseconds /
        Duration.microsecondsPerHour;
    if (hours <= 0) {
      return 0.0;
    }
    if (hours > 24) {
      return 24.0;
    }
    return hours;
  }

  SoundscapeWeather _weather(WeatherSnapshot? w) {
    if (w == null) {
      return SoundscapeWeather.clear;
    }
    // A strong sustained wind dominates a calm sky.
    if (w.windSpeedKmh >= windThresholdKmh &&
        (w.condition == WeatherCondition.clear ||
            w.condition == WeatherCondition.clouds)) {
      return SoundscapeWeather.wind;
    }
    // The two enums share member names by construction; map by name with a
    // safe fallback so a future WeatherCondition never crashes the mapping.
    return SoundscapeWeather.values.firstWhere(
      (s) => s.name == w.condition.name,
      orElse: () => SoundscapeWeather.clouds,
    );
  }

  SoundscapeDaypart _daypart(DateTime now, WeatherSnapshot? w) {
    final sunrise = w?.sunrise?.toLocal();
    final sunset = w?.sunset?.toLocal();
    if (sunrise != null && sunset != null) {
      const dawn = Duration(minutes: 60);
      const morning = Duration(minutes: 150);
      const dusk = Duration(minutes: 60);
      if (now.isBefore(sunrise.subtract(const Duration(minutes: 30))) ||
          now.isAfter(sunset.add(const Duration(minutes: 30)))) {
        return SoundscapeDaypart.night;
      }
      if (now.isBefore(sunrise.add(dawn))) {
        return SoundscapeDaypart.dawn;
      }
      if (now.isBefore(sunrise.add(dawn + morning))) {
        return SoundscapeDaypart.morning;
      }
      if (now.isAfter(sunset.subtract(dusk))) {
        return SoundscapeDaypart.dusk;
      }
      return SoundscapeDaypart.day;
    }
    // No sun data: bucket by local hour.
    final h = now.hour;
    if (h >= 5 && h < 7) {
      return SoundscapeDaypart.dawn;
    }
    if (h >= 7 && h < 11) {
      return SoundscapeDaypart.morning;
    }
    if (h >= 11 && h < 17) {
      return SoundscapeDaypart.day;
    }
    if (h >= 17 && h < 20) {
      return SoundscapeDaypart.dusk;
    }
    return SoundscapeDaypart.night;
  }
}
