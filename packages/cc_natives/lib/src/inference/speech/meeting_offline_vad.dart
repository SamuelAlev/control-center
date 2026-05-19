import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_coverage_repair.dart';
import 'package:cc_natives/src/inference/speech/sherpa_bindings.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Runs offline Silero VAD over a complete 16 kHz mono recording and returns the
/// detected speech [Span]s, for post-meeting transcript-coverage repair.
///
/// The native VAD is a synchronous FFI call, so it runs on a throwaway worker
/// isolate via [Isolate.run] — the native handle is created, used, and freed
/// entirely inside the worker; only plain numbers travel back. Best-effort: any
/// failure surfaces as an empty span list to the caller, which then skips repair.
class MeetingOfflineVad {
  /// Creates a [MeetingOfflineVad].
  const MeetingOfflineVad();

  /// Detects speech spans in [samples] using the Silero model at [modelPath].
  Future<List<Span>> detect({
    required Float32List samples,
    required String modelPath,
    int sampleRate = 16000,
  }) async {
    if (samples.isEmpty) {
      return const <Span>[];
    }
    final raw = await Isolate.run(
      () => _detectSync(samples, modelPath, sampleRate),
    );
    return [for (final r in raw) (startMs: r[0], endMs: r[1])];
  }
}

/// Worker body: returns `[startMs, endMs]` pairs (plain ints cross the isolate
/// boundary cleanly).
List<List<int>> _detectSync(
  Float32List samples,
  String modelPath,
  int sampleRate,
) {
  ensureSherpaInitialized();
  final config = sherpa.VadModelConfig(
    sileroVad: sherpa.SileroVadModelConfig(
      model: modelPath,
      threshold: 0.5,
      minSilenceDuration: 0.25,
      minSpeechDuration: 0.1,
    ),
    sampleRate: sampleRate,
    numThreads: 1,
  );
  final vad = sherpa.VoiceActivityDetector(
    config: config,
    bufferSizeInSeconds: 30,
  );
  final out = <List<int>>[];

  void drain() {
    while (!vad.isEmpty()) {
      final seg = vad.front();
      final startMs = (seg.start * 1000 / sampleRate).round();
      final endMs =
          ((seg.start + seg.samples.length) * 1000 / sampleRate).round();
      if (endMs > startMs) {
        out.add([startMs, endMs]);
      }
      vad.pop();
    }
  }

  try {
    const window = 512; // Silero's frame size
    var i = 0;
    while (i < samples.length) {
      final end = (i + window) < samples.length ? i + window : samples.length;
      vad.acceptWaveform(Float32List.sublistView(samples, i, end));
      drain();
      i = end;
    }
    vad.flush();
    drain();
  } finally {
    vad.free();
  }
  return out;
}
