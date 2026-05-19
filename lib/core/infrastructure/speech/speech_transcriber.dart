import 'package:flutter/foundation.dart';

/// One chunk of transcribed audio.
@immutable
class TranscriptionResult {
  /// Creates a [TranscriptionResult].
  const TranscriptionResult({
    required this.text,
    required this.isFinal,
  });

  /// Transcribed text.
  final String text;

  /// True when the engine considers this the final result for the utterance.
  final bool isFinal;
}

/// Local (on-device) speech-to-text.
///
/// Implementations:
/// - `SherpaOnnxTranscriber` — uses sherpa-onnx with a local model.
///
/// The transcriber lifecycle:
/// ```
/// final t = SherpaOnnxTranscriber();
/// await t.initialize();
/// final sub = t.transcribe(audioStream).listen(...);
/// ...
/// sub.cancel();
/// await t.dispose();
/// ```
abstract class SpeechTranscriber {
  /// Load models, allocate decoder state. Idempotent.
  Future<void> initialize();

  /// Emits partial + final transcripts as audio flows in. The input is a
  /// stream of mono 16-bit PCM frames (Int16List bytes) at 16 kHz.
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio);

  /// Release native resources.
  Future<void> dispose();

  /// True when [initialize] has succeeded and the transcriber is usable.
  bool get isReady;

  /// Human-readable name shown in settings ("sherpa-onnx", "whisper.cpp").
  String get displayName;
}
