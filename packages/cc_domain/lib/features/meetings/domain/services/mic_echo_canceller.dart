import 'dart:typed_data';

/// Signal-level acoustic echo cancellation for the meeting recorder: the system
/// loopback ("them") is fed to the far-end reference and the microphone ("me")
/// is cleaned of the remote's speaker bleed before it reaches transcription.
///
/// The concrete implementation drives a native AEC engine and so lives in the
/// data layer; the recorder controller depends only on this abstraction
/// (constructed through a provider factory). When no native engine is available
/// the implementation is an identity passthrough.
abstract interface class MicEchoCanceller {
  /// Returns the microphone stream cleaned of the far-end echo. The far-end
  /// must be supplied concurrently via [referenceTap]. Identity when no native
  /// engine is available.
  Stream<Uint8List> cleanMic(Stream<Uint8List> micRaw);

  /// Taps the system-loopback stream as the AEC far-end reference, re-emitting
  /// it unchanged for the "them" channel.
  Stream<Uint8List> referenceTap(Stream<Uint8List> loopbackRaw);

  /// Releases the native handle and any buffered state.
  Future<void> dispose();
}
