import 'dart:typed_data';

import 'package:control_center/features/meetings/domain/services/transcribed_window.dart';

/// Drives rolling-window transcription over a continuous 16 kHz mono PCM16
/// stream (one audio channel — e.g. the microphone, or the system output),
/// emitting a [TranscribedWindow] per decoded window.
///
/// The concrete implementation wraps the platform speech recognizer and so
/// lives in the data layer; the recorder controller depends only on this
/// abstraction (resolved through a provider factory).
abstract interface class MeetingTranscriptionPort {
  /// Transcribes [pcm] (16 kHz mono PCM16), emitting one [TranscribedWindow]
  /// per decoded window with offsets measured from the first sample.
  Stream<TranscribedWindow> transcribe(Stream<Uint8List> pcm);
}
