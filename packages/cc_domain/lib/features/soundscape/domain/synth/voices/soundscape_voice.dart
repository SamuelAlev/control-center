import 'dart:typed_data';

/// A single generative layer of a soundscape.
///
/// A voice never owns the output buffer; it mixes its contribution
/// ADDITIVELY into an interleaved stereo `Float32List` (`[L0, R0, L1, R1, …]`)
/// of length `frames * 2`, scaled by a per-call gain. Callers zero the buffer
/// once and let every voice add into it, which keeps the mix wiring trivial
/// and lets a composer cross-fade voices simply by ramping each gain.
abstract class SoundscapeVoice {
  /// Adds [frames] stereo frames of this voice into [outStereo], scaled by
  /// [gain]. Never clears the buffer.
  void renderAdd(Float32List outStereo, int frames, double gain);
}
