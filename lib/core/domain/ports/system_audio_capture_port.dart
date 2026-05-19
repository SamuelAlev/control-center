import 'dart:typed_data';

/// The kind of system-audio source a [SystemAudioCapturePort] can tap.
enum SystemAudioSourceKind {
  /// The full system output mixdown.
  system,

  /// A single application's audio (per-process tap).
  process,

  /// A PipeWire/PulseAudio monitor of an output sink.
  monitor,

  /// Unrecognized kind from a newer backend.
  unknown,
}

/// A tappable system-audio source.
class SystemAudioSource {
  /// Creates a [SystemAudioSource].
  const SystemAudioSource({
    required this.id,
    required this.name,
    required this.kind,
  });

  /// Stable id passed back to [SystemAudioCapturePort.capture]. The sentinel
  /// `'system'` means the full system mixdown.
  final String id;

  /// Human-readable label.
  final String name;

  /// What this source represents.
  final SystemAudioSourceKind kind;
}

/// Driver-free capture of system **output** audio (loopback) — the audio that
/// plays through the speakers (e.g. the other participants in a meeting).
///
/// Implementations deliver **16 kHz, mono, signed 16-bit little-endian PCM**
/// frames so the bytes feed straight into the on-device Whisper transcriber.
///
/// This port lives in the domain layer; the adapter that fulfils it (wrapping
/// the `system_audio_capture` plugin) lives in the meetings feature data layer.
abstract class SystemAudioCapturePort {
  /// Whether the running OS supports driver-free capture (macOS 14.4+, Windows
  /// 10 1703+, or a working PipeWire/PulseAudio stack on Linux).
  Future<bool> isSupported();

  /// Requests the OS audio-capture permission (macOS). Returns true when
  /// granted; a no-op returning true on platforms without a prompt.
  Future<bool> requestPermission();

  /// Lists the sources that can be tapped.
  Future<List<SystemAudioSource>> listSources();

  /// Begins capturing [sourceId] (null/`'system'` = full mixdown) and returns a
  /// stream of 16 kHz mono PCM16 frames. The stream ends on [stop].
  Stream<Uint8List> capture({String? sourceId});

  /// Stops the in-flight capture and releases OS resources.
  Future<void> stop();
}
