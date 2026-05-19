import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// A speaker-labeled time span produced by diarization.
class DiarizedSpan {
  /// Creates a [DiarizedSpan].
  const DiarizedSpan({
    required this.startMs,
    required this.endMs,
    required this.speaker,
  });

  /// Span start offset from the audio start, in milliseconds.
  final int startMs;

  /// Span end offset from the audio start, in milliseconds.
  final int endMs;

  /// Zero-based diarization cluster index (`0` → "Person 1", etc.).
  final int speaker;
}

/// Runs offline speaker diarization (sherpa-onnx pyannote segmentation +
/// speaker embedding + clustering) on a complete 16 kHz mono recording.
///
/// Diarization is a *synchronous*, CPU-heavy native (FFI) call, so it runs on a
/// throwaway worker isolate via [Isolate.run] — the native handles cannot cross
/// isolates, so the diarizer is created, used, and freed entirely inside the
/// worker; only plain numbers travel back.
class MeetingDiarizationService {
  /// Creates a [MeetingDiarizationService].
  const MeetingDiarizationService();

  /// Diarizes [samples] (16 kHz mono, normalized `[-1, 1]`) using the segmentation
  /// + embedding models at the given paths. Returns the speaker-labeled spans,
  /// sorted by start time. Returns an empty list for empty input.
  Future<List<DiarizedSpan>> diarize({
    required String segmentationModelPath,
    required String embeddingModelPath,
    required Float32List samples,
    int numThreads = 2,
  }) async {
    if (samples.isEmpty) {
      return const <DiarizedSpan>[];
    }
    final raw = await Isolate.run(
      () => _diarizeSync(
        segmentationModelPath,
        embeddingModelPath,
        samples,
        numThreads,
      ),
    );
    return [
      for (final r in raw)
        DiarizedSpan(startMs: r[0], endMs: r[1], speaker: r[2]),
    ];
  }
}

/// Worker body: returns `[startMs, endMs, speaker]` triples (plain ints cross
/// the isolate boundary cleanly).
List<List<int>> _diarizeSync(
  String segmentationModelPath,
  String embeddingModelPath,
  Float32List samples,
  int numThreads,
) {
  sherpa.initBindings();
  final config = sherpa.OfflineSpeakerDiarizationConfig(
    segmentation: sherpa.OfflineSpeakerSegmentationModelConfig(
      pyannote: sherpa.OfflineSpeakerSegmentationPyannoteModelConfig(
        model: segmentationModelPath,
      ),
      numThreads: numThreads,
      debug: false,
    ),
    embedding: sherpa.SpeakerEmbeddingExtractorConfig(
      model: embeddingModelPath,
      numThreads: numThreads,
      debug: false,
    ),
    // numClusters: -1 → infer the speaker count from the audio via the
    // clustering threshold (we don't know it ahead of time).
    clustering: const sherpa.FastClusteringConfig(numClusters: -1, threshold: 0.5),
    minDurationOn: 0.3,
    minDurationOff: 0.5,
  );
  final diarizer = sherpa.OfflineSpeakerDiarization(config);
  try {
    final segments = diarizer.process(samples: samples);
    return [
      for (final s in segments)
        [(s.start * 1000).round(), (s.end * 1000).round(), s.speaker],
    ];
  } finally {
    diarizer.free();
  }
}

/// Assigns the diarization speaker index whose span overlaps the transcript
/// window `[startMs, endMs)` the most, or null when nothing overlaps.
///
/// Transcript windows and diarization spans are cut independently, so a window
/// rarely lines up with one span exactly; the maximum-overlap rule picks the
/// dominant speaker for the window. Pure + top-level so it is directly unit
/// testable.
int? assignSpeakerByOverlap(
  List<DiarizedSpan> spans,
  int startMs,
  int endMs,
) {
  var bestSpeaker = -1;
  var bestOverlap = 0;
  for (final span in spans) {
    final overlap =
        (endMs < span.endMs ? endMs : span.endMs) -
            (startMs > span.startMs ? startMs : span.startMs);
    if (overlap > bestOverlap) {
      bestOverlap = overlap;
      bestSpeaker = span.speaker;
    }
  }
  return bestSpeaker >= 0 ? bestSpeaker : null;
}
