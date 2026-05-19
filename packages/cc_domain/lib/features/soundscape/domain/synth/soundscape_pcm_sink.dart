import 'dart:typed_data';

/// The seam a soundscape renderer pushes finished audio blocks through.
///
/// The pure-Dart engine only ever produces interleaved stereo `Float32List`
/// blocks; the concrete sink (an Opus/AAC encoder, a WAV writer, a WebRTC
/// track, …) lives in the server/infra layer and implements this interface.
/// Keeping the abstraction in the shared kernel lets the composer stay pure
/// Dart while the encoder stays platform-specific.
abstract class SoundscapePcmSink {
  /// Consumes [frames] interleaved stereo frames (`[L0, R0, L1, R1, …]`, length
  /// `frames * 2`) of [interleavedStereo].
  void writeBlock(Float32List interleavedStereo, int frames);
}
