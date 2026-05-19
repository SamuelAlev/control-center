/// The listening mood a soundscape is generated for.
///
/// Drives the harmonic content (scale/register) and the balance between the
/// ambient noise bed, the pad and the sparse FM accents.
enum SoundscapeMood {
  /// Gentle, alert ambience meant to stay in the background while working.
  focus,

  /// Warmer, more consonant ambience for unwinding.
  relax,

  /// Low drones, near-zero accents, deep reverb — for winding down.
  sleep,
}

/// The part of the day a soundscape is generated for.
///
/// Shifts brightness (filter cutoff) and reverb depth: nights are darker and
/// more spacious than midday.
enum SoundscapeDaypart {
  /// First light.
  dawn,

  /// Mid-morning.
  morning,

  /// Full daylight.
  day,

  /// Fading light.
  dusk,

  /// After dark.
  night,
}

/// The weather condition a soundscape is generated for.
///
/// Primarily shapes the noise bed (level, color, brightness) and nudges the
/// reverb: rain is bright and busy, storms are loud and dark, fog is muffled.
enum SoundscapeWeather {
  /// Clear skies.
  clear,

  /// Overcast.
  clouds,

  /// Rainfall.
  rain,

  /// Snowfall.
  snow,

  /// Fog / haze.
  fog,

  /// Thunderstorm.
  storm,

  /// Strong wind.
  wind,
}

/// An immutable description of the environment a soundscape renders for.
///
/// The engine is fully deterministic in this value: the same
/// [SoundscapeContext] always seeds the PRNG with the same [seed], so every
/// render of the same context is sample-identical. Only the fields that a
/// listener would perceptibly hear are folded into [contextHash] — the
/// temperature is bucketed into ~3 degC bins so that trivially close readings
/// (20.1 degC vs 21.9 degC) collapse to the same seed and do not restart the
/// generator.
class SoundscapeContext {
  /// Creates a [SoundscapeContext].
  const SoundscapeContext({
    required this.mood,
    required this.daypart,
    required this.weather,
    required this.isDay,
    required this.temperatureCelsius,
  });

  /// The listening mood.
  final SoundscapeMood mood;

  /// The part of the day.
  final SoundscapeDaypart daypart;

  /// The current weather condition.
  final SoundscapeWeather weather;

  /// Whether it is daytime (independent of [daypart] so the two can be sourced
  /// from different signals, e.g. a solar-elevation flag vs. a clock bucket).
  final bool isDay;

  /// The outdoor temperature in degrees Celsius.
  final double temperatureCelsius;

  /// Returns a copy with the given fields replaced.
  SoundscapeContext copyWith({
    SoundscapeMood? mood,
    SoundscapeDaypart? daypart,
    SoundscapeWeather? weather,
    bool? isDay,
    double? temperatureCelsius,
  }) {
    return SoundscapeContext(
      mood: mood ?? this.mood,
      daypart: daypart ?? this.daypart,
      weather: weather ?? this.weather,
      isDay: isDay ?? this.isDay,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
    );
  }

  /// The temperature bucket (~3 degC bins) folded into [contextHash].
  int get _temperatureBucket => (temperatureCelsius / 3.0).round();

  /// The canonical, perceptually-significant string this context hashes to.
  String get _canonical =>
      '${mood.name}|${daypart.name}|${weather.name}|$isDay|$_temperatureBucket';

  /// A stable, deterministic hash of the perceptually-significant fields.
  ///
  /// Two contexts that would sound the same (e.g. temperatures inside the same
  /// ~3 degC bin) share the same hash. Never uses wall-clock time or a random
  /// source, so it is reproducible across processes and platforms.
  String get contextHash =>
      _fnv1a(_canonical).toRadixString(16).padLeft(8, '0');

  /// A deterministic PRNG seed derived from [contextHash].
  ///
  /// Used to seed the synthesis PRNG so every render of the same context is
  /// sample-identical.
  int get seed => _fnv1a(_canonical);

  /// FNV-1a (32-bit) over the UTF-16 code units of [input].
  ///
  /// The multiply is split into 16-bit halves so the result is identical on
  /// the native VM and on the web (where ints are 53-bit doubles), rather than
  /// silently losing precision above 2^53.
  static int _fnv1a(String input) {
    const prime = 0x01000193;
    var hash = 0x811C9DC5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      final lo = hash & 0xFFFF;
      final hi = hash >>> 16;
      hash = ((lo * prime) + (((hi * prime) & 0xFFFF) << 16)) & 0xFFFFFFFF;
    }
    return hash;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundscapeContext &&
          runtimeType == other.runtimeType &&
          mood == other.mood &&
          daypart == other.daypart &&
          weather == other.weather &&
          isDay == other.isDay &&
          temperatureCelsius == other.temperatureCelsius;

  @override
  int get hashCode =>
      Object.hash(mood, daypart, weather, isDay, temperatureCelsius);

  @override
  String toString() =>
      'SoundscapeContext(mood: ${mood.name}, daypart: ${daypart.name}, '
      'weather: ${weather.name}, isDay: $isDay, '
      'temperatureCelsius: $temperatureCelsius)';
}
