import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_natives/src/inference/speech/sherpa_bindings.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Runs offline speaker diarization (sherpa-onnx pyannote segmentation +
/// speaker embedding + clustering) on a complete 16 kHz mono recording, and
/// extracts a representative WeSpeaker embedding per detected speaker.
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
  const MeetingDiarizationService();

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
    final raw = await Isolate.run(
      () => _diarizeSync(
        segmentationModelPath,
        embeddingModelPath,
        samples,
        numThreads,
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
) {
  ensureSherpaInitialized();
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
  final List<List<int>> spans;
  try {
    final segments = diarizer.process(samples: samples);
    spans = [
      for (final s in segments)
        [(s.start * 1000).round(), (s.end * 1000).round(), s.speaker],
    ];
  } finally {
    diarizer.free();
  }

  final embeddings = _computeSpeakerEmbeddings(
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
  String embeddingModelPath,
  Float32List samples,
  List<List<int>> spans,
  int numThreads,
) {
  if (spans.isEmpty) {
    return const <int, List<double>>{};
  }
  const sampleRate = 16000;

  // Gather each speaker's sample ranges (in time order), capping the total per
  // speaker so the extractor cost stays bounded on long meetings.
  final chunks = <int, List<Float32List>>{};
  final taken = <int, int>{};
  for (final s in spans) {
    final speaker = s[2];
    if ((taken[speaker] ?? 0) >= _maxEmbeddingSamplesPerSpeaker) {
      continue;
    }
    final startIdx =
        (s[0] * sampleRate / 1000).floor().clamp(0, samples.length);
    var endIdx = (s[1] * sampleRate / 1000).ceil().clamp(0, samples.length);
    if (endIdx <= startIdx) {
      continue;
    }
    final remaining = _maxEmbeddingSamplesPerSpeaker - (taken[speaker] ?? 0);
    if (endIdx - startIdx > remaining) {
      endIdx = startIdx + remaining;
    }
    (chunks[speaker] ??= <Float32List>[]).add(samples.sublist(startIdx, endIdx));
    taken[speaker] = (taken[speaker] ?? 0) + (endIdx - startIdx);
  }
  if (chunks.isEmpty) {
    return const <int, List<double>>{};
  }

  final extractor = sherpa.SpeakerEmbeddingExtractor(
    config: sherpa.SpeakerEmbeddingExtractorConfig(
      model: embeddingModelPath,
      numThreads: numThreads,
      debug: false,
    ),
  );
  final out = <int, List<double>>{};
  try {
    for (final entry in chunks.entries) {
      final audio = _concat(entry.value, taken[entry.key] ?? 0);
      if (audio.isEmpty) {
        continue;
      }
      final stream = extractor.createStream();
      try {
        stream.acceptWaveform(samples: audio, sampleRate: sampleRate);
        stream.inputFinished();
        if (!extractor.isReady(stream)) {
          continue;
        }
        final emb = extractor.compute(stream);
        if (emb.isNotEmpty) {
          out[entry.key] = _l2normalize(emb);
        }
      } finally {
        stream.free();
      }
    }
  } finally {
    extractor.free();
  }
  return out;
}

/// Cap (30 s at 16 kHz) on how much audio per speaker is fed to the embedding
/// extractor — plenty for a stable voiceprint without scanning whole meetings.
const int _maxEmbeddingSamplesPerSpeaker = 16000 * 30;

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
