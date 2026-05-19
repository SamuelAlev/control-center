import 'dart:isolate';
import 'dart:typed_data';

import 'package:control_center/features/meetings/domain/services/meeting_diarization.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Runs offline speaker diarization (sherpa-onnx pyannote segmentation +
/// speaker embedding + clustering) on a complete 16 kHz mono recording.
///
/// Diarization is a *synchronous*, CPU-heavy native (FFI) call, so it runs on a
/// throwaway worker isolate via [Isolate.run] — the native handles cannot cross
/// isolates, so the diarizer is created, used, and freed entirely inside the
/// worker; only plain numbers travel back.
///
/// The pure value object ([DiarizedSpan]) and the span helpers
/// (`assignSpeakerByOverlap`, `separateTranscriptBySpeaker`, …) live in the
/// domain layer (`meeting_diarization.dart`); only the native model invocation
/// lives here.
class MeetingDiarizationService implements MeetingDiarizationPort {
  /// Creates a [MeetingDiarizationService].
  const MeetingDiarizationService();

  @override
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
