import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_coverage_repair.dart';
import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/inference/inference_library.dart';
import 'package:ffi/ffi.dart';

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
  ///
  /// [libPath] is the `cc_inference` dylib path; the worker isolate must be told
  /// explicitly because it cannot see the host's preferred-path static.
  Future<List<Span>> detect({
    required Float32List samples,
    required String modelPath,
    int sampleRate = ccInferenceSampleRate,
    String? libPath,
  }) async {
    if (samples.isEmpty) {
      return const <Span>[];
    }
    final resolved = libPath ?? resolveInferenceLibraryPath();
    final raw = await Isolate.run(
      () => _detectSync(samples, modelPath, sampleRate, resolved),
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
  String? libPath,
) {
  final bindings = ensureInferenceBindings(explicitPath: libPath);
  if (bindings == null) {
    throw StateError(inferenceLibraryUnavailableMessage(searchedPath: libPath));
  }
  final model = modelPath.toNativeUtf8(allocator: calloc);
  final Pointer<Void> vad;
  try {
    vad = bindings.vadCreate(
      model.cast<Uint8>(),
      0.5,
      0.25,
      0.1,
      sampleRate,
      30,
    );
  } finally {
    calloc.free(model);
  }
  if (vad == nullptr) {
    throw StateError(
      readInferenceError(
        bindings,
        fallback: 'Failed to create the Silero VAD from $modelPath.',
      ),
    );
  }

  final out = <List<int>>[];
  final start = calloc<Int32>();
  final len = calloc<Int32>();
  final window = calloc<Float>(_windowSamples);

  void drain() {
    while (bindings.vadFront(vad, start, len) == 1) {
      final startMs = (start.value * 1000 / sampleRate).round();
      final endMs = ((start.value + len.value) * 1000 / sampleRate).round();
      if (endMs > startMs) {
        out.add([startMs, endMs]);
      }
      bindings.vadPop(vad);
    }
  }

  try {
    var i = 0;
    while (i < samples.length) {
      final end = (i + _windowSamples) < samples.length
          ? i + _windowSamples
          : samples.length;
      final count = end - i;
      window.asTypedList(count).setRange(0, count, samples, i);
      bindings.vadAccept(vad, window, count);
      drain();
      i = end;
    }
    bindings.vadFlush(vad);
    drain();
  } finally {
    calloc.free(window);
    calloc.free(start);
    calloc.free(len);
    bindings.vadDestroy(vad);
  }
  return out;
}

/// Silero's frame size.
const int _windowSamples = 512;
