import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';

/// The complete set of glidable synth target values a [SoundscapeContext]
/// maps to.
///
/// A flat, immutable data bag of numbers the composer feeds into its voices
/// as ramp targets. Produced purely from a context by
/// [SoundscapeArrangement.resolve] / [SoundscapeTargets.fromContext] — there
/// is no hidden state, so the same context always yields equal targets.
/// Mood-fixed *musical* identity (scale, voicing, tempo, AM rate) lives in
/// `MoodMusic`, not here: mood is part of the session key and never glides.
class SoundscapeTargets {
  /// Creates a fully-specified set of targets.
  const SoundscapeTargets({
    required this.noiseGain,
    required this.noiseColor,
    required this.noiseCutoffHz,
    required this.gustDepthDb,
    required this.padGain,
    required this.padCutoffHz,
    required this.padDetuneCents,
    required this.motifGain,
    required this.motifNotesPerMinute,
    required this.motifAttackSeconds,
    required this.motifReleaseSeconds,
    required this.arpGain,
    required this.arpFill,
    required this.arpAttackSeconds,
    required this.arpReleaseSeconds,
    required this.pulseGain,
    required this.pulseFill,
    required this.subGain,
    required this.amDepth,
    required this.reverbWet,
    required this.reverbDecay,
    required this.reverbDamp,
    required this.preDelayMs,
    required this.wetHighPassHz,
  });

  /// Derives targets from [context]. Convenience for
  /// `const SoundscapeArrangement().resolve(context)`.
  factory SoundscapeTargets.fromContext(SoundscapeContext context) =>
      const SoundscapeArrangement().resolve(context);

  /// Output gain of the noise bed.
  final double noiseGain;

  /// Noise pink/brown blend, 0 = pink-ish, 1 = brown-ish.
  final double noiseColor;

  /// Noise-bed low-pass corner in Hz (the gust drift wanders around it).
  final double noiseCutoffHz;

  /// Peak noise-bed gain wander ("gusts") in dB.
  final double gustDepthDb;

  /// Output gain of the pad.
  final double padGain;

  /// Pad low-pass corner in Hz.
  final double padCutoffHz;

  /// Pad unison detune in cents (applied at build; kept small so beating stays below ~10 Hz, out of the roughness band).
  final double padDetuneCents;

  /// Output gain of the motif voice.
  final double motifGain;

  /// Melodic density target in notes per minute (0 silences the melody).
  final double motifNotesPerMinute;

  /// Motif amplitude-envelope attack in seconds (soft onsets only).
  final double motifAttackSeconds;

  /// Motif exponential release time constant in seconds.
  final double motifReleaseSeconds;

  /// Output gain of the broken-chord arp layer (0 silences it).
  final double arpGain;

  /// Base step-fill probability of the arp's eighth-note grid, in `[0, 1]`.
  final double arpFill;

  /// Arp amplitude-envelope attack in seconds (soft plucks, never clicks).
  final double arpAttackSeconds;

  /// Arp exponential release time constant in seconds.
  final double arpReleaseSeconds;

  /// Output gain of the bass pulse layer at full tune energy (the energy axis gates it in from silence at the neutral center).
  final double pulseGain;

  /// Base beat-fill of the pulse pattern, in `[0, 1]`.
  final double pulseFill;

  /// Output gain of the grounding sub drone.
  final double subGain;

  /// Amplitude-modulation depth target in `[0, 1]` (rate is mood-fixed).
  final double amDepth;

  /// Reverb wet mix, in `[0, 1]`.
  final double reverbWet;

  /// Reverb tail length, in `[0, 1]`.
  final double reverbDecay;

  /// Reverb high-frequency damping, in `[0, 1]`.
  final double reverbDamp;

  /// Reverb pre-delay in milliseconds (mood-fixed in practice).
  final double preDelayMs;

  /// Wet high-pass corner in Hz (mood-fixed in practice).
  final double wetHighPassHz;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundscapeTargets &&
          runtimeType == other.runtimeType &&
          noiseGain == other.noiseGain &&
          noiseColor == other.noiseColor &&
          noiseCutoffHz == other.noiseCutoffHz &&
          gustDepthDb == other.gustDepthDb &&
          padGain == other.padGain &&
          padCutoffHz == other.padCutoffHz &&
          padDetuneCents == other.padDetuneCents &&
          motifGain == other.motifGain &&
          motifNotesPerMinute == other.motifNotesPerMinute &&
          motifAttackSeconds == other.motifAttackSeconds &&
          motifReleaseSeconds == other.motifReleaseSeconds &&
          arpGain == other.arpGain &&
          arpFill == other.arpFill &&
          arpAttackSeconds == other.arpAttackSeconds &&
          arpReleaseSeconds == other.arpReleaseSeconds &&
          pulseGain == other.pulseGain &&
          pulseFill == other.pulseFill &&
          subGain == other.subGain &&
          amDepth == other.amDepth &&
          reverbWet == other.reverbWet &&
          reverbDecay == other.reverbDecay &&
          reverbDamp == other.reverbDamp &&
          preDelayMs == other.preDelayMs &&
          wetHighPassHz == other.wetHighPassHz;

  @override
  int get hashCode => Object.hashAll(<double>[
    noiseGain,
    noiseColor,
    noiseCutoffHz,
    gustDepthDb,
    padGain,
    padCutoffHz,
    padDetuneCents,
    motifGain,
    motifNotesPerMinute,
    motifAttackSeconds,
    motifReleaseSeconds,
    arpGain,
    arpFill,
    arpAttackSeconds,
    arpReleaseSeconds,
    pulseGain,
    pulseFill,
    subGain,
    amDepth,
    reverbWet,
    reverbDecay,
    reverbDamp,
    preDelayMs,
    wetHighPassHz,
  ]);
}

/// The pure arrangement engine: maps a [SoundscapeContext] to
/// [SoundscapeTargets].
///
/// Mood sets the balance and the functional profile (focus = drier, gently
/// modulated at beta rate, sparse mid-register motifs; relax = warmer,
/// wetter, alpha rate, sparser and lower; sleep = dark drones, no motifs,
/// deep slow space). Weather shapes the noise bed (rain is bright and busy,
/// storms loud, dark and gusty, fog muffled) and thins the melody; daypart
/// and the day/temperature flags nudge brightness, density and reverb
/// depth. It is a total, side-effect-free function — no clocks, no
/// randomness.
class SoundscapeArrangement {
  /// Creates the (stateless) arrangement engine.
  const SoundscapeArrangement();

  /// Maps [context] to a concrete set of synth targets.
  SoundscapeTargets resolve(SoundscapeContext context) {
    final mood = _MoodProfile.of(context.mood);
    final weather = _WeatherProfile.of(context.weather);
    final daypart = _DaypartProfile.of(context.daypart);

    // Noise bed: level scales with weather, dampened a little by calmer moods.
    final noiseGain = (weather.noiseGain * mood.noiseMultiplier).clamp(
      0.0,
      0.6,
    );
    final noiseColor = weather.noiseColor.clamp(0.0, 1.0);
    final tempWarmth = ((context.temperatureCelsius - 15.0) * 0.005).clamp(
      -0.15,
      0.15,
    );
    final dayBrightness = context.isDay ? 1.0 : 0.9;
    final noiseCutoff =
        (weather.noiseCutoffHz *
                mood.cutoffMultiplier *
                daypart.cutoffMultiplier *
                (1.0 + tempWarmth) *
                dayBrightness)
            .clamp(200.0, 16000.0);
    final gustDepth = weather.gustDepthDb.clamp(0.0, 4.0);

    // Pad: rain and storms pull the pad down and darker.
    final padGain = (mood.padGain * weather.padMultiplier).clamp(0.0, 0.5);
    final padCutoff = (mood.padCutoffHz * weather.padMultiplier).clamp(
      120.0,
      6000.0,
    );
    final padDetune = (mood.padDetuneCents + tempWarmth * 40.0).clamp(
      3.0,
      12.0,
    );

    // Motifs: sleep silences them; storms/rain/night thin them out.
    final motifNotesPerMinute =
        (mood.motifNotesPerMinute *
                weather.motifMultiplier *
                daypart.motifMultiplier *
                (context.isDay ? 1.0 : 0.85))
            .clamp(0.0, 12.0);

    // Arp: same environmental thinning as the motifs, but softened — the
    // density layer recedes in rough weather / at night without vanishing.
    final arpFill =
        (mood.arpFill *
                (0.6 + 0.4 * weather.motifMultiplier * daypart.motifMultiplier))
            .clamp(0.0, 0.9);

    // Neural AM: slightly shallower at night.
    final amDepth = (mood.amDepth * (context.isDay ? 1.0 : 0.9)).clamp(
      0.0,
      0.5,
    );

    // Reverb: mood sets the floor, fog/storm and night deepen it.
    final reverbWet =
        (mood.reverbWet +
                weather.reverbAdd +
                daypart.reverbAdd +
                (context.isDay ? 0.0 : 0.02))
            .clamp(0.0, 0.6);
    final reverbDecay = (mood.reverbDecay + weather.decayAdd + daypart.decayAdd)
        .clamp(0.0, 0.95);
    final reverbDamp = (mood.reverbDamp + (context.isDay ? 0.0 : 0.1)).clamp(
      0.0,
      1.0,
    );

    return SoundscapeTargets(
      noiseGain: noiseGain.toDouble(),
      noiseColor: noiseColor.toDouble(),
      noiseCutoffHz: noiseCutoff.toDouble(),
      gustDepthDb: gustDepth.toDouble(),
      padGain: padGain.toDouble(),
      padCutoffHz: padCutoff.toDouble(),
      padDetuneCents: padDetune.toDouble(),
      motifGain: mood.motifGain,
      motifNotesPerMinute: motifNotesPerMinute.toDouble(),
      motifAttackSeconds: mood.motifAttackSeconds,
      motifReleaseSeconds: mood.motifReleaseSeconds,
      arpGain: mood.arpGain,
      arpFill: arpFill.toDouble(),
      arpAttackSeconds: mood.arpAttackSeconds,
      arpReleaseSeconds: mood.arpReleaseSeconds,
      pulseGain: mood.pulseGain,
      pulseFill: mood.pulseFill,
      subGain: mood.subGain,
      amDepth: amDepth.toDouble(),
      reverbWet: reverbWet.toDouble(),
      reverbDecay: reverbDecay.toDouble(),
      reverbDamp: reverbDamp.toDouble(),
      preDelayMs: mood.preDelayMs,
      wetHighPassHz: mood.wetHighPassHz,
    );
  }
}

/// Per-mood balance and functional profile.
class _MoodProfile {
  const _MoodProfile({
    required this.padGain,
    required this.padCutoffHz,
    required this.padDetuneCents,
    required this.noiseMultiplier,
    required this.cutoffMultiplier,
    required this.motifGain,
    required this.motifNotesPerMinute,
    required this.motifAttackSeconds,
    required this.motifReleaseSeconds,
    required this.arpGain,
    required this.arpFill,
    required this.arpAttackSeconds,
    required this.arpReleaseSeconds,
    required this.pulseGain,
    required this.pulseFill,
    required this.subGain,
    required this.amDepth,
    required this.reverbWet,
    required this.reverbDecay,
    required this.reverbDamp,
    required this.preDelayMs,
    required this.wetHighPassHz,
  });

  factory _MoodProfile.of(SoundscapeMood mood) {
    switch (mood) {
      case SoundscapeMood.focus:
        // focus is "beat-driven, stable, even ... less reverb, more nuanced".
        // Drier, slightly brighter and dense in *events*: a three-octave
        // broken-chord arp over the motifs (the reference focus tracks carry
        // ~40 note events/min; motifs + a ~0.24-fill eighth grid at 96 BPM
        // land in that zone), a bass pulse the tune's energy axis gates in,
        // and a real sub floor — energy through rhythm and register, never
        // brightness.
        return const _MoodProfile(
          padGain: 0.22,
          padCutoffHz: 2200.0,
          padDetuneCents: 6.0,
          // The reference focus tracks carry almost no exposed hiss: their
          // noise floor is dark and low. Halve the bed and pull its corner
          // down so it reads as room-tone, not white noise — the note layers
          // carry the spectrum above it.
          noiseMultiplier: 0.55,
          cutoffMultiplier: 0.5,
          motifGain: 0.22,
          motifNotesPerMinute: 9.0,
          motifAttackSeconds: 0.25,
          motifReleaseSeconds: 2.5,
          arpGain: 0.2,
          arpFill: 0.2,
          arpAttackSeconds: 0.03,
          arpReleaseSeconds: 1.5,
          pulseGain: 0.3,
          pulseFill: 0.5,
          subGain: 0.05,
          amDepth: 0.35,
          reverbWet: 0.18,
          reverbDecay: 0.45,
          reverbDamp: 0.45,
          preDelayMs: 25.0,
          wetHighPassHz: 350.0,
        );
      case SoundscapeMood.relax:
        // "More movement, but never a beat or pulse": wetter, warmer, slower swells, lower register, sparser melody.
        return const _MoodProfile(
          padGain: 0.26,
          padCutoffHz: 1000.0,
          padDetuneCents: 7.0,
          noiseMultiplier: 0.9,
          cutoffMultiplier: 0.9,
          motifGain: 0.22,
          motifNotesPerMinute: 4.0,
          motifAttackSeconds: 0.8,
          motifReleaseSeconds: 4.0,
          arpGain: 0.0,
          arpFill: 0.0,
          arpAttackSeconds: 0.3,
          arpReleaseSeconds: 2.0,
          pulseGain: 0.0,
          pulseFill: 0.0,
          subGain: 0.09,
          amDepth: 0.20,
          reverbWet: 0.32,
          reverbDecay: 0.70,
          reverbDamp: 0.35,
          preDelayMs: 40.0,
          wetHighPassHz: 280.0,
        );
      case SoundscapeMood.sleep:
        // "Homogenous and even": dark drones, zero melodic events, deep slow space, strong grounding sub.
        return const _MoodProfile(
          padGain: 0.30,
          padCutoffHz: 500.0,
          padDetuneCents: 4.0,
          noiseMultiplier: 0.7,
          cutoffMultiplier: 0.55,
          motifGain: 0.0,
          motifNotesPerMinute: 0.0,
          motifAttackSeconds: 1.5,
          motifReleaseSeconds: 6.0,
          arpGain: 0.0,
          arpFill: 0.0,
          arpAttackSeconds: 0.3,
          arpReleaseSeconds: 2.0,
          pulseGain: 0.0,
          pulseFill: 0.0,
          subGain: 0.14,
          amDepth: 0.12,
          reverbWet: 0.42,
          reverbDecay: 0.85,
          reverbDamp: 0.55,
          preDelayMs: 60.0,
          wetHighPassHz: 160.0,
        );
    }
  }

  final double padGain;
  final double padCutoffHz;
  final double padDetuneCents;
  final double noiseMultiplier;
  final double cutoffMultiplier;
  final double motifGain;
  final double motifNotesPerMinute;
  final double motifAttackSeconds;
  final double motifReleaseSeconds;
  final double arpGain;
  final double arpFill;
  final double arpAttackSeconds;
  final double arpReleaseSeconds;
  final double pulseGain;
  final double pulseFill;
  final double subGain;
  final double amDepth;
  final double reverbWet;
  final double reverbDecay;
  final double reverbDamp;
  final double preDelayMs;
  final double wetHighPassHz;
}

/// Per-weather noise/pad/reverb profile.
class _WeatherProfile {
  const _WeatherProfile({
    required this.noiseGain,
    required this.noiseColor,
    required this.noiseCutoffHz,
    required this.gustDepthDb,
    required this.padMultiplier,
    required this.motifMultiplier,
    required this.reverbAdd,
    required this.decayAdd,
  });

  factory _WeatherProfile.of(SoundscapeWeather weather) {
    switch (weather) {
      case SoundscapeWeather.clear:
        return const _WeatherProfile(
          noiseGain: 0.10,
          noiseColor: 0.30,
          noiseCutoffHz: 6000.0,
          gustDepthDb: 0.8,
          padMultiplier: 1.0,
          motifMultiplier: 1.0,
          reverbAdd: 0.0,
          decayAdd: 0.0,
        );
      case SoundscapeWeather.clouds:
        return const _WeatherProfile(
          noiseGain: 0.14,
          noiseColor: 0.35,
          noiseCutoffHz: 5000.0,
          gustDepthDb: 1.2,
          padMultiplier: 1.0,
          motifMultiplier: 0.9,
          reverbAdd: 0.02,
          decayAdd: 0.0,
        );
      case SoundscapeWeather.rain:
        return const _WeatherProfile(
          noiseGain: 0.28,
          noiseColor: 0.12,
          noiseCutoffHz: 9000.0,
          gustDepthDb: 1.5,
          padMultiplier: 0.7,
          motifMultiplier: 0.6,
          reverbAdd: 0.05,
          decayAdd: 0.0,
        );
      case SoundscapeWeather.snow:
        return const _WeatherProfile(
          noiseGain: 0.12,
          noiseColor: 0.40,
          noiseCutoffHz: 7000.0,
          gustDepthDb: 1.0,
          padMultiplier: 0.95,
          motifMultiplier: 0.8,
          reverbAdd: 0.05,
          decayAdd: 0.02,
        );
      case SoundscapeWeather.fog:
        return const _WeatherProfile(
          noiseGain: 0.16,
          noiseColor: 0.50,
          noiseCutoffHz: 3000.0,
          gustDepthDb: 1.0,
          padMultiplier: 0.9,
          motifMultiplier: 0.7,
          reverbAdd: 0.12,
          decayAdd: 0.05,
        );
      case SoundscapeWeather.storm:
        return const _WeatherProfile(
          noiseGain: 0.40,
          noiseColor: 0.60,
          noiseCutoffHz: 2600.0,
          gustDepthDb: 2.5,
          padMultiplier: 0.7,
          motifMultiplier: 0.4,
          reverbAdd: 0.08,
          decayAdd: 0.03,
        );
      case SoundscapeWeather.wind:
        return const _WeatherProfile(
          noiseGain: 0.24,
          noiseColor: 0.30,
          noiseCutoffHz: 4200.0,
          gustDepthDb: 3.0,
          padMultiplier: 0.9,
          motifMultiplier: 0.9,
          reverbAdd: 0.03,
          decayAdd: 0.0,
        );
    }
  }

  final double noiseGain;
  final double noiseColor;
  final double noiseCutoffHz;
  final double gustDepthDb;
  final double padMultiplier;
  final double motifMultiplier;
  final double reverbAdd;
  final double decayAdd;
}

/// Per-daypart brightness/density/reverb profile.
class _DaypartProfile {
  const _DaypartProfile({
    required this.cutoffMultiplier,
    required this.motifMultiplier,
    required this.reverbAdd,
    required this.decayAdd,
  });

  factory _DaypartProfile.of(SoundscapeDaypart daypart) {
    switch (daypart) {
      case SoundscapeDaypart.dawn:
        return const _DaypartProfile(
          cutoffMultiplier: 0.9,
          motifMultiplier: 0.8,
          reverbAdd: 0.03,
          decayAdd: 0.0,
        );
      case SoundscapeDaypart.morning:
        return const _DaypartProfile(
          cutoffMultiplier: 1.0,
          motifMultiplier: 1.0,
          reverbAdd: 0.0,
          decayAdd: 0.0,
        );
      case SoundscapeDaypart.day:
        return const _DaypartProfile(
          cutoffMultiplier: 1.0,
          motifMultiplier: 1.0,
          reverbAdd: 0.0,
          decayAdd: 0.0,
        );
      case SoundscapeDaypart.dusk:
        return const _DaypartProfile(
          cutoffMultiplier: 0.85,
          motifMultiplier: 0.7,
          reverbAdd: 0.05,
          decayAdd: 0.02,
        );
      case SoundscapeDaypart.night:
        return const _DaypartProfile(
          cutoffMultiplier: 0.7,
          motifMultiplier: 0.4,
          reverbAdd: 0.10,
          decayAdd: 0.04,
        );
    }
  }

  final double cutoffMultiplier;
  final double motifMultiplier;
  final double reverbAdd;
  final double decayAdd;
}
