import 'dart:ffi';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/inference/inference_library.dart';
import 'package:ffi/ffi.dart';

/// Runs offline speaker diarization (pyannote segmentation + WeSpeaker
/// embedding + clustering, via the `cc_inference` native) on a complete 16 kHz
/// mono recording, and extracts a representative embedding per detected speaker.
///
/// Diarization is a *synchronous*, CPU-heavy native (FFI) call, so it runs on a
/// throwaway worker isolate via [Isolate.run] — the native handles cannot cross
/// isolates, so the diarizer + embedding extractor are created, used, and freed
/// entirely inside the worker; only plain numbers travel back.
///
/// The pure value object ([DiarizedSpan]) and the span helpers
/// (`assignSpeakerByOverlap`, `separateTranscriptBySpeaker`, …) live in the
/// domain layer (`meeting_diarization.dart`); only the native model invocation
/// lives here.
class MeetingDiarizationService implements MeetingDiarizationPort {
  /// Creates a [MeetingDiarizationService].
  ///
  /// [libPath] is the `cc_inference` dylib path. The worker isolate cannot see
  /// the host's preferred-path static, so it is resolved on the calling isolate
  /// and captured into the worker closure.
  const MeetingDiarizationService({this.libPath});

  /// Absolute path of the `cc_inference` dylib; null resolves it per call.
  final String? libPath;

  @override
  Future<DiarizationResult> diarize({
    required String segmentationModelPath,
    required String embeddingModelPath,
    required Float32List samples,
    int numThreads = 2,
  }) async {
    if (samples.isEmpty) {
      return DiarizationResult.empty;
    }
    final resolved = libPath ?? resolveInferenceLibraryPath();
    final raw = await Isolate.run(
      () => _diarizeSync(
        segmentationModelPath,
        embeddingModelPath,
        samples,
        numThreads,
        resolved,
      ),
    );
    return DiarizationResult(
      spans: [
        for (final r in raw.$1)
          DiarizedSpan(startMs: r[0], endMs: r[1], speaker: r[2]),
      ],
      embeddings: raw.$2,
    );
  }
}

/// Worker body: returns `([startMs, endMs, speaker] triples, embeddings)`. Plain
/// collections + typed data cross the isolate boundary cleanly.
(List<List<int>>, Map<int, List<double>>) _diarizeSync(
  String segmentationModelPath,
  String embeddingModelPath,
  Float32List samples,
  int numThreads,
  String? libPath,
) {
  final bindings = ensureInferenceBindings(explicitPath: libPath);
  if (bindings == null) {
    throw StateError(inferenceLibraryUnavailableMessage(searchedPath: libPath));
  }

  final segModel = segmentationModelPath.toNativeUtf8(allocator: calloc);
  final embModel = embeddingModelPath.toNativeUtf8(allocator: calloc);
  final Pointer<Void> diarizer;
  try {
    diarizer = bindings.diarCreate(
      segModel.cast<Uint8>(),
      embModel.cast<Uint8>(),
      numThreads,
      // numClusters is fixed at -1 inside the native → infer the speaker count
      // from the audio via this threshold (we don't know it ahead of time).
      0.5,
      0.3,
      0.5,
    );
  } finally {
    calloc.free(segModel);
    calloc.free(embModel);
  }
  if (diarizer == nullptr) {
    throw StateError(
      readInferenceError(bindings, fallback: 'Failed to create the diarizer.'),
    );
  }

  final List<List<int>> spans;
  final audio = calloc<Float>(samples.length);
  final outSegments = calloc<Pointer<CcDiarSegment>>();
  final outCount = calloc<IntPtr>();
  try {
    audio.asTypedList(samples.length).setAll(0, samples);
    final rc = bindings.diarProcess(
      diarizer,
      audio,
      samples.length,
      outSegments,
      outCount,
    );
    if (rc != 0) {
      throw StateError(
        readInferenceError(bindings, fallback: 'Diarization failed.'),
      );
    }
    final count = outCount.value;
    final segments = outSegments.value;
    spans = <List<int>>[];
    if (count > 0 && segments != nullptr) {
      try {
        for (var i = 0; i < count; i++) {
          final s = segments[i];
          spans.add([
            (s.startS * 1000).round(),
            (s.endS * 1000).round(),
            s.speaker,
          ]);
        }
      } finally {
        bindings.diarSegmentsDestroy(segments, count);
      }
    }
  } finally {
    calloc.free(audio);
    calloc.free(outSegments);
    calloc.free(outCount);
    bindings.diarDestroy(diarizer);
  }

  final embeddings = _computeSpeakerEmbeddings(
    bindings,
    embeddingModelPath,
    samples,
    spans,
    numThreads,
  );
  return (spans, embeddings);
}

/// Computes one L2-normalized representative embedding per speaker cluster by
/// feeding (up to [_maxEmbeddingSamplesPerSpeaker] of) that speaker's own audio
/// through the WeSpeaker extractor. Runs inside the diarization worker isolate
/// so the native extractor never crosses an isolate boundary. Best-effort: a
/// failure for any speaker leaves that cluster without an embedding rather than
/// failing the whole run.
Map<int, List<double>> _computeSpeakerEmbeddings(
  CcInferenceBindings bindings,
  String embeddingModelPath,
  Float32List samples,
  List<List<int>> spans,
  int numThreads,
) {
  if (spans.isEmpty) {
    return const <int, List<double>>{};
  }
  const sampleRate = ccInferenceSampleRate;

  // Gather each speaker's sample ranges (in time order), capping the total per
  // speaker so the extractor cost stays bounded on long meetings.
  final chunks = <int, List<Float32List>>{};
  final taken = <int, int>{};
  for (final s in spans) {
    final speaker = s[2];
    if ((taken[speaker] ?? 0) >= _maxEmbeddingSamplesPerSpeaker) {
      continue;
    }
    final startIdx = (s[0] * sampleRate / 1000).floor().clamp(
      0,
      samples.length,
    );
    var endIdx = (s[1] * sampleRate / 1000).ceil().clamp(0, samples.length);
    if (endIdx <= startIdx) {
      continue;
    }
    final remaining = _maxEmbeddingSamplesPerSpeaker - (taken[speaker] ?? 0);
    if (endIdx - startIdx > remaining) {
      endIdx = startIdx + remaining;
    }
    (chunks[speaker] ??= <Float32List>[]).add(
      samples.sublist(startIdx, endIdx),
    );
    taken[speaker] = (taken[speaker] ?? 0) + (endIdx - startIdx);
  }
  if (chunks.isEmpty) {
    return const <int, List<double>>{};
  }

  final model = embeddingModelPath.toNativeUtf8(allocator: calloc);
  final Pointer<Void> extractor;
  try {
    extractor = bindings.spkCreate(model.cast<Uint8>(), numThreads);
  } finally {
    calloc.free(model);
  }
  if (extractor == nullptr) {
    return const <int, List<double>>{};
  }

  final out = <int, List<double>>{};
  try {
    final dim = bindings.spkDim(extractor);
    if (dim <= 0) {
      return const <int, List<double>>{};
    }
    final embedding = calloc<Float>(dim);
    try {
      for (final entry in chunks.entries) {
        final audio = _concat(entry.value, taken[entry.key] ?? 0);
        if (audio.isEmpty) {
          continue;
        }
        final buffer = calloc<Float>(audio.length);
        try {
          buffer.asTypedList(audio.length).setAll(0, audio);
          final rc = bindings.spkCompute(
            extractor,
            buffer,
            audio.length,
            sampleRate,
            embedding,
            dim,
          );
          // 1 = not enough audio for a voiceprint; skip that speaker rather
          // than failing the run.
          if (rc == 0) {
            out[entry.key] = _l2normalize(embedding.asTypedList(dim));
          }
        } finally {
          calloc.free(buffer);
        }
      }
    } finally {
      calloc.free(embedding);
    }
  } finally {
    bindings.spkDestroy(extractor);
  }
  return out;
}

/// Cap (30 s at 16 kHz) on how much audio per speaker is fed to the embedding
/// extractor — plenty for a stable voiceprint without scanning whole meetings.
const int _maxEmbeddingSamplesPerSpeaker = ccInferenceSampleRate * 30;

Float32List _concat(List<Float32List> parts, int totalLength) {
  final out = Float32List(totalLength);
  var offset = 0;
  for (final part in parts) {
    if (offset + part.length > totalLength) {
      out.setRange(offset, totalLength, part);
      break;
    }
    out.setRange(offset, offset + part.length, part);
    offset += part.length;
  }
  return out;
}

List<double> _l2normalize(Float32List v) {
  var sumSq = 0.0;
  for (final x in v) {
    sumSq += x * x;
  }
  final norm = math.sqrt(sumSq);
  if (norm == 0) {
    return [for (final x in v) x.toDouble()];
  }
  return [for (final x in v) x / norm];
}
