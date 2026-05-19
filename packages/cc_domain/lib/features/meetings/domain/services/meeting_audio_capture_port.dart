import 'dart:typed_data';

/// Thrown when browser/host audio capture cannot start: input permission
/// denied, the screenshare cancelled, or — per the product decision — no system
/// audio was shared (recording is not allowed without the meeting audio).
class MeetingCaptureException implements Exception {
  /// Creates a [MeetingCaptureException].
  MeetingCaptureException(this.message);

  /// Human-readable reason, surfaced to the user.
  final String message;

  @override
  String toString() => message;
}

/// Captures two 16 kHz mono PCM16 audio channels — the local microphone (`me`)
/// and the system / shared meeting audio (`them`) — for a single recording.
///
/// One instance drives one recording (the underlying capture graph is
/// single-use), so it is obtained from a factory per [start]. The web
/// implementation (`WebAudioCapture`, in the data layer) wraps `getUserMedia` +
/// `getDisplayMedia` + the Web Audio API; the recorder controller depends only
/// on this abstraction so it never names the browser API.
abstract interface class MeetingAudioCapturePort {
  /// Microphone ("me") PCM16 frames (16 kHz mono).
  Stream<Uint8List> get micStream;

  /// System / shared meeting ("them") PCM16 frames (16 kHz mono).
  Stream<Uint8List> get systemStream;

  /// Requests the input devices and starts emitting frames. Throws a
  /// [MeetingCaptureException] when capture cannot begin (denied permission,
  /// cancelled share, or no system-audio track).
  Future<void> start();

  /// Stops capture, releases the devices, and closes the streams.
  Future<void> stop();
}
