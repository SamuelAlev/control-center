import 'package:meta/meta.dart';

/// A coarse, UI-facing weather condition.
///
/// This is deliberately small — it drives the "soundscapes" ambience, not a
/// forecast readout — so the many Open-Meteo WMO weather codes collapse into a
/// handful of buckets via [fromWmoCode]. [wind] is never produced by
/// [fromWmoCode]: high-wind is derived elsewhere from a measured wind speed,
/// because WMO codes have no dedicated "windy" value.
enum WeatherCondition {
  /// Clear sky.
  clear,

  /// Any amount of cloud cover (mainly clear → overcast).
  clouds,

  /// Drizzle, rain, freezing rain, or rain showers.
  rain,

  /// Snow fall, snow grains, or snow showers.
  snow,

  /// Fog or depositing rime fog.
  fog,

  /// Thunderstorm (with or without hail).
  storm,

  /// High wind (derived from a measured wind speed, not a WMO code).
  wind;

  /// Maps an Open-Meteo WMO weather-interpretation code to a condition bucket.
  ///
  /// - `0` → [clear]
  /// - `1`–`3` → [clouds]
  /// - `45`, `48` → [fog]
  /// - `51`–`67`, `80`–`82` → [rain] (drizzle, freezing drizzle, rain,
  ///   freezing rain, rain showers)
  /// - `71`–`77`, `85`, `86` → [snow] (snow fall, snow grains, snow showers)
  /// - `95`–`99` → [storm] (thunderstorm, with or without hail)
  ///
  /// Any unrecognized code falls back to [clouds] (the neutral default).
  /// [wind] is never returned here — it is derived from a measured wind speed.
  static WeatherCondition fromWmoCode(int code) {
    if (code == 0) {
      return WeatherCondition.clear;
    }
    if (code >= 1 && code <= 3) {
      return WeatherCondition.clouds;
    }
    if (code == 45 || code == 48) {
      return WeatherCondition.fog;
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return WeatherCondition.rain;
    }
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return WeatherCondition.snow;
    }
    if (code >= 95 && code <= 99) {
      return WeatherCondition.storm;
    }
    return WeatherCondition.clouds;
  }

  /// Parses a wire/stored condition name (defaults to [clouds]).
  static WeatherCondition fromName(String? raw) {
    for (final value in WeatherCondition.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return WeatherCondition.clouds;
  }
}

/// A point-in-time weather observation for a workspace's location.
///
/// Fetched host-side from Open-Meteo (keyless) and read by thin clients over
/// RPC — the domain itself is transport- and infrastructure-free. Times are
/// carried as-provided; render with `toLocal()` where a wall-clock is wanted.
@immutable
class WeatherSnapshot {
  /// Creates a [WeatherSnapshot].
  const WeatherSnapshot({
    required this.latitude,
    required this.longitude,
    required this.condition,
    required this.isDay,
    required this.temperatureCelsius,
    required this.windSpeedKmh,
    required this.observedAt,
    this.locationLabel,
    this.sunrise,
    this.sunset,
  });

  /// Observation latitude in decimal degrees.
  final double latitude;

  /// Observation longitude in decimal degrees.
  final double longitude;

  /// Human-friendly place name (e.g. a city), when resolved; null otherwise.
  final String? locationLabel;

  /// The coarse condition bucket driving the ambience.
  final WeatherCondition condition;

  /// Whether it is currently daytime at the location.
  final bool isDay;

  /// Air temperature in degrees Celsius.
  final double temperatureCelsius;

  /// Wind speed in kilometres per hour.
  final double windSpeedKmh;

  /// Sunrise time, when known.
  final DateTime? sunrise;

  /// Sunset time, when known.
  final DateTime? sunset;

  /// When this observation was taken.
  final DateTime observedAt;

  /// Returns a copy with the given fields replaced.
  WeatherSnapshot copyWith({
    double? latitude,
    double? longitude,
    String? locationLabel,
    WeatherCondition? condition,
    bool? isDay,
    double? temperatureCelsius,
    double? windSpeedKmh,
    DateTime? sunrise,
    DateTime? sunset,
    DateTime? observedAt,
  }) {
    return WeatherSnapshot(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      condition: condition ?? this.condition,
      isDay: isDay ?? this.isDay,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      observedAt: observedAt ?? this.observedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherSnapshot &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          locationLabel == other.locationLabel &&
          condition == other.condition &&
          isDay == other.isDay &&
          temperatureCelsius == other.temperatureCelsius &&
          windSpeedKmh == other.windSpeedKmh &&
          sunrise == other.sunrise &&
          sunset == other.sunset &&
          observedAt == other.observedAt;

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    locationLabel,
    condition,
    isDay,
    temperatureCelsius,
    windSpeedKmh,
    sunrise,
    sunset,
    observedAt,
  );
}
