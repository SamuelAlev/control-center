import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:cc_natives/src/inference/speech/sherpa_bindings.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// A [SpeechActivityDetector] backed by Silero VAD via sherpa-onnx. Feeds PCM16
/// chunks into a streaming [sherpa.VoiceActivityDetector] and reports its live
/// `isDetected()` state, replacing the RMS energy gate with a learned model.
///
/// Created through [SileroVadDetector.create] once the model is installed; the
/// transcription service disposes it when the recording stops. Falls back to
/// [RmsSpeechActivityDetector] elsewhere when the model is absent.
class SileroVadDetector implements SpeechActivityDetector {
  SileroVadDetector._(this._vad);

  /// Builds a detector from the model at [modelPath].
  ///
  /// Runs on whatever isolate constructs it (the recorder builds it on the main
  /// isolate), so it initializes sherpa-onnx for *this* isolate first — the
  /// transcriber's worker-isolate init does not carry over (see
  /// [ensureSherpaInitialized]). Without it `VoiceActivityDetector` throws
  /// "Please initialize sherpa-onnx first".
  factory SileroVadDetector.create({
    required String modelPath,
    int sampleRate = 16000,
    double threshold = 0.5,
    double minSilenceDuration = 0.25,
    double minSpeechDuration = 0.1,
  }) {
    ensureSherpaInitialized();
    final config = sherpa.VadModelConfig(
      sileroVad: sherpa.SileroVadModelConfig(
        model: modelPath,
        threshold: threshold,
        minSilenceDuration: minSilenceDuration,
        minSpeechDuration: minSpeechDuration,
      ),
      sampleRate: sampleRate,
      numThreads: 1,
    );
    final vad = sherpa.VoiceActivityDetector(
      config: config,
      bufferSizeInSeconds: 30,
    );
    return SileroVadDetector._(vad);
  }

  final sherpa.VoiceActivityDetector _vad;

  @override
  bool isSpeech(Uint8List pcm16) {
    _vad.acceptWaveform(_toFloat32(pcm16));
    final detected = _vad.isDetected();
    // We only use the live detection flag, not the segment queue — drain it so
    // it never grows for a long recording.
    while (!_vad.isEmpty()) {
      _vad.pop();
    }
    return detected;
  }

  @override
  void reset() => _vad.clear();

  @override
  void dispose() => _vad.free();

  static Float32List _toFloat32(Uint8List pcm16) {
    final view = ByteData.sublistView(pcm16);
    final n = pcm16.length ~/ 2;
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      out[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }
}
