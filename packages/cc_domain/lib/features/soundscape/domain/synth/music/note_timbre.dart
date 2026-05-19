/// One instrument color a note layer can speak in.
///
/// Functional-music services build their note streams from sampled
/// instrument libraries (piano, guitar, winds) and a large part of what
/// reads as "richness" is the *rotation* of those colors phrase by phrase.
/// This type is the additive-synthesis equivalent: a harmonic recipe plus
/// envelope/level scaling and an optional vibrato — enough to evoke pluck,
/// breath, or reed without leaving the anti-salience envelope (soft attacks,
/// low-passed stems, pure harmonic series).
class NoteTimbre {
  /// Creates an instrument color.
  const NoteTimbre({
    required this.partialGains,
    required this.cutoffHz,
    this.attackScale = 1.0,
    this.releaseScale = 1.0,
    this.gainScale = 1.0,
    this.vibratoRateHz = 0.0,
    this.vibratoCents = 0.0,
  });

  /// Gains of the harmonic partials (1f, 2f, …), fundamental first.
  final List<double> partialGains;

  /// The stem low-pass corner for this color.
  final double cutoffHz;

  /// Multiplier on the scheduled attack seconds (winds swell, plucks bite).
  final double attackScale;

  /// Multiplier on the scheduled release time constant.
  final double releaseScale;

  /// Loudness trim so all colors sit at the same perceived level.
  final double gainScale;

  /// Vibrato rate in Hz; `0` disables vibrato (plucked/struck colors).
  final double vibratoRateHz;

  /// Peak vibrato depth in cents (kept small: expression, not warble).
  final double vibratoCents;

  /// The original soft bloom — fundamental-heavy swell, no vibrato.
  static const NoteTimbre bloom = NoteTimbre(
    partialGains: <double>[1.0, 0.32, 0.1],
    cutoffHz: 2200.0,
  );

  /// Piano-like pluck: tall stack with gentle rolloff, quick soft attack.
  /// The upper partials exist so the stem has something to open into when
  /// the energy axis raises its cutoff.
  static const NoteTimbre piano = NoteTimbre(
    partialGains: <double>[1.0, 0.55, 0.34, 0.22, 0.15, 0.1, 0.07, 0.05],
    cutoffHz: 2600.0,
  );

  /// Nylon-guitar-like pluck: warmer, string-flavoured rolloff, shorter
  /// ring than the piano.
  static const NoteTimbre guitar = NoteTimbre(
    partialGains: <double>[1.0, 0.62, 0.4, 0.25, 0.15, 0.08, 0.04],
    cutoffHz: 2300.0,
    attackScale: 0.8,
    releaseScale: 0.75,
  );

  /// Flute-like breath tone: near-pure fundamental, slow swell, singing
  /// vibrato that fades in after the onset.
  static const NoteTimbre flute = NoteTimbre(
    partialGains: <double>[1.0, 0.22, 0.05],
    cutoffHz: 3000.0,
    attackScale: 1.5,
    releaseScale: 1.3,
    gainScale: 1.15,
    vibratoRateHz: 5.0,
    vibratoCents: 9.0,
  );

  /// Reed (soft sax/clarinet) color: odd-harmonic-leaning stack, moderate
  /// swell, slower and shallower vibrato than the flute.
  static const NoteTimbre reed = NoteTimbre(
    partialGains: <double>[1.0, 0.4, 0.7, 0.28, 0.35, 0.14, 0.1],
    cutoffHz: 2400.0,
    attackScale: 1.2,
    releaseScale: 1.1,
    gainScale: 0.9,
    vibratoRateHz: 4.6,
    vibratoCents: 6.0,
  );
}
