import 'dart:ffi';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/inference/inference_library.dart';
import 'package:ffi/ffi.dart';

/// A [SpeechActivityDetector] backed by Silero VAD via the `cc_inference`
/// native. Feeds PCM16 chunks into a streaming detector and reports its live
/// `isDetected` state, replacing the RMS energy gate with a learned model.
///
/// Created through [SileroVadDetector.create] once the model is installed; the
/// transcription service disposes it when the recording stops. Falls back to
/// [RmsSpeechActivityDetector] elsewhere when the model is absent.
class SileroVadDetector implements SpeechActivityDetector {
  SileroVadDetector._(this._bindings, this._handle);

  /// Builds a detector from the model at [modelPath].
  ///
  /// Binds the native for whatever isolate constructs it (the recorder builds it
  /// on the main isolate) — FFI bindings are per-isolate, so another isolate's
  /// binding does not carry over.
  factory SileroVadDetector.create({
    required String modelPath,
    int sampleRate = ccInferenceSampleRate,
    double threshold = 0.5,
    double minSilenceDuration = 0.25,
    double minSpeechDuration = 0.1,
    String? libPath,
  }) {
    final bindings = ensureInferenceBindings(explicitPath: libPath);
    if (bindings == null) {
      throw StateError(
        inferenceLibraryUnavailableMessage(searchedPath: libPath),
      );
    }
    final model = modelPath.toNativeUtf8(allocator: calloc);
    final Pointer<Void> handle;
    try {
      handle = bindings.vadCreate(
        model.cast<Uint8>(),
        threshold,
        minSilenceDuration,
        minSpeechDuration,
        sampleRate,
        _bufferSizeSeconds,
      );
    } finally {
      calloc.free(model);
    }
    if (handle == nullptr) {
      throw StateError(
        readInferenceError(
          bindings,
          fallback: 'Failed to create the Silero VAD from $modelPath.',
        ),
      );
    }
    return SileroVadDetector._(bindings, handle);
  }

  /// Ring-buffer depth the detector keeps for queued segments.
  static const double _bufferSizeSeconds = 30;

  final CcInferenceBindings _bindings;
  Pointer<Void> _handle;

  @override
  bool isSpeech(Uint8List pcm16) {
    if (_handle == nullptr) {
      return false;
    }
    final samples = _toFloat32(pcm16);
    if (samples.isNotEmpty) {
      final buffer = calloc<Float>(samples.length);
      try {
        buffer.asTypedList(samples.length).setAll(0, samples);
        _bindings.vadAccept(_handle, buffer, samples.length);
      } finally {
        calloc.free(buffer);
      }
    }
    final detected = _bindings.vadIsDetected(_handle) != 0;
    // We only use the live detection flag, not the segment queue — drain it so
    // it never grows for a long recording.
    while (_bindings.vadIsEmpty(_handle) == 0) {
      _bindings.vadPop(_handle);
    }
    return detected;
  }

  @override
  void reset() {
    if (_handle != nullptr) {
      _bindings.vadClear(_handle);
    }
  }

  @override
  void dispose() {
    if (_handle != nullptr) {
      _bindings.vadDestroy(_handle);
      _handle = nullptr;
    }
  }

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
