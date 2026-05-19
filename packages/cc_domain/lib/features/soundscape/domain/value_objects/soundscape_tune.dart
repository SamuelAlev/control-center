/// The listener's 2D soundscape tune — the puck position on the tune pad.
///
/// Two normalized axes to tune style: [energy] runs mellow (0) to energetic (1) and scales intensity — melodic density, neural-AM depth, gusts;
/// [brightness] runs spacy (0) to bright (1) and trades space for sheen — reverb depth against filter openness and noise color. `(0.5, 0.5)` is the neutral center: the engine sounds exactly as if no tune existed.
/// A tune is a *listener preference*, not part of `SoundscapeContext`
/// (environment): it never re-seeds a session — it glides live into the
/// running mix through short parameter ramps.
class SoundscapeTune {
  /// Creates a tune; both axes are clamped to `[0, 1]`.
  SoundscapeTune({required double energy, required double brightness})
    : energy = energy.clamp(0.0, 1.0),
      brightness = brightness.clamp(0.0, 1.0);

  /// The neutral pad center — audibly identical to an untuned engine.
  static final SoundscapeTune neutral = SoundscapeTune(
    energy: 0.5,
    brightness: 0.5,
  );

  /// Mellow (0) to energetic (1).
  final double energy;

  /// Spacy (0) to bright (1).
  final double brightness;

  /// Returns a copy with the given fields replaced (and clamped).
  SoundscapeTune copyWith({double? energy, double? brightness}) =>
      SoundscapeTune(
        energy: energy ?? this.energy,
        brightness: brightness ?? this.brightness,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundscapeTune &&
          runtimeType == other.runtimeType &&
          energy == other.energy &&
          brightness == other.brightness;

  @override
  int get hashCode => Object.hash(energy, brightness);

  @override
  String toString() =>
      'SoundscapeTune(energy: $energy, brightness: $brightness)';
}
