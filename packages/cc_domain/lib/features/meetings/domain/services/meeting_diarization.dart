import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';

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

/// The result of an offline diarization run: the speaker-labeled [spans] plus a
/// representative [embeddings] vector per cluster index (the `speaker` field of
/// [DiarizedSpan]). [embeddings] is empty when the embedding model wasn't
/// available or extraction failed — diarization still succeeds without them.
class DiarizationResult {
  /// Creates a [DiarizationResult].
  const DiarizationResult({required this.spans, this.embeddings = const {}});

  /// An empty result (no spans, no embeddings).
  static const DiarizationResult empty = DiarizationResult(spans: []);

  /// Speaker-labeled spans, sorted by start time.
  final List<DiarizedSpan> spans;

  /// Representative L2-normalized embedding per cluster index.
  final Map<int, List<double>> embeddings;
}

/// Encodes a speaker [embedding] for storage (JSON array), or null when absent.
String? encodeSpeakerEmbedding(List<double>? embedding) =>
    (embedding == null || embedding.isEmpty) ? null : jsonEncode(embedding);

/// Decodes a stored speaker embedding produced by [encodeSpeakerEmbedding].
/// Tolerant of malformed input — returns null rather than throwing.
List<double>? decodeSpeakerEmbedding(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! List) {
    return null;
  }
  final out = <double>[
    for (final e in decoded)
      if (e is num) e.toDouble(),
  ];
  return out.isEmpty ? null : out;
}

/// Resolves ordered candidate display names for a diarized [channel] of a
/// meeting from its linked calendar invitees (in invitee order) — used to
/// pre-seed diarized speaker names as a best-effort default. Returns an empty
/// list when there is no linked event. Injected into the `meeting.diarize` step
/// so the pipelines layer stays decoupled from the calendar feature.
typedef AttendeeNamesResolver = Future<List<String>> Function(
  String workspaceId,
  String meetingId,
  MeetingSpeaker channel,
);

/// Port for offline speaker diarization.
///
/// Diarization runs an FFI/native model (sherpa-onnx) and so its concrete
/// implementation lives in the data layer; the domain depends only on this
/// abstraction. The `meeting_summary` pipeline's `meeting.diarize` step is
/// purely domain orchestration, so it accepts a [MeetingDiarizationPort] and
/// the composition root injects the real implementation.
abstract interface class MeetingDiarizationPort {
  /// Diarizes [samples] (16 kHz mono, normalized `[-1, 1]`) using the
  /// segmentation + embedding models at the given paths. Returns the
  /// speaker-labeled spans (sorted by start time) plus a representative
  /// embedding per cluster. Returns [DiarizationResult.empty] for empty input.
  Future<DiarizationResult> diarize({
    required String segmentationModelPath,
    required String embeddingModelPath,
    required Float32List samples,
    int numThreads,
  });
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

/// The diarization label for a zero-based cluster [index] (`0` → "Person 1").
/// Shared by the `meeting.diarize` step (which persists the speaker identities)
/// and [separateTranscriptBySpeaker] (which labels the segments) so the two use
/// one scheme.
String personLabel(int index) => 'Person ${index + 1}';

/// Encodes diarization [spans] as a compact JSON string so the `meeting.diarize`
/// step can hand them to the parallel `meeting.updateTranscript` step through
/// pipeline state.
String encodeDiarizedSpans(List<DiarizedSpan> spans) => jsonEncode([
      for (final s in spans) [s.startMs, s.endMs, s.speaker],
    ]);

/// Decodes spans produced by [encodeDiarizedSpans]. Tolerant of malformed input
/// — skips any entry that is not a `[startMs, endMs, speaker]` numeric triple.
List<DiarizedSpan> decodeDiarizedSpans(String json) {
  Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return const <DiarizedSpan>[];
  }
  if (decoded is! List) {
    return const <DiarizedSpan>[];
  }
  return [
    for (final e in decoded)
      if (e is List &&
          e.length >= 3 &&
          e[0] is num &&
          e[1] is num &&
          e[2] is num)
        DiarizedSpan(
          startMs: (e[0] as num).toInt(),
          endMs: (e[1] as num).toInt(),
          speaker: (e[2] as num).toInt(),
        ),
  ];
}

/// Re-separates and labels transcript [segments] using diarization [spans] on
/// the diarized [channel], returning a cleaner, time-ordered transcript:
///
///  * each window on [channel] is tagged with the speaker (`Person N`) that
///    dominates it by time overlap, and
///  * adjacent fragments sharing the same speaker (and within [mergeGapMs] of
///    one another) are merged into one coherent turn, so the transcript reads
///    as distinct speaker turns instead of choppy 1.5–5 s windows.
///
/// Segments on the other channel pass through with their `(speaker, label)`
/// unchanged, but are still merged into turns the same way. Windows are NOT
/// split mid-text at a speaker change: Whisper windows carry no word-level
/// timestamps, so a sub-window cut point can't be placed reliably — the
/// dominant speaker is used instead.
///
/// Pure (no I/O) so it is directly unit-testable; `meeting.updateTranscript`
/// persists the result via `replaceSegments`.
List<MeetingSegment> separateTranscriptBySpeaker({
  required List<MeetingSegment> segments,
  required List<DiarizedSpan> spans,
  required MeetingSpeaker channel,
  int mergeGapMs = 2000,
}) {
  // No diarization signal → leave the transcript exactly as captured.
  if (segments.isEmpty || spans.isEmpty) {
    return segments;
  }
  // 1. Label each channel segment by its dominant diarized speaker.
  final labeled = <MeetingSegment>[];
  for (final seg in segments) {
    if (seg.speaker != channel) {
      labeled.add(seg);
      continue;
    }
    final idx = assignSpeakerByOverlap(spans, seg.startMs, seg.endMs);
    labeled.add(idx == null ? seg : _relabel(seg, personLabel(idx)));
  }
  // 2. Merge consecutive same-(speaker, label) fragments into coherent turns.
  labeled.sort((a, b) => a.startMs.compareTo(b.startMs));
  return _mergeTurns(labeled, mergeGapMs);
}

/// Merges consecutive same-speaker transcript [segments] into coherent turns
/// for display, applying the same chunk-boundary de-duplication as
/// [separateTranscriptBySpeaker] — but WITHOUT diarization, so it works on the
/// raw live transcript (where segments carry only their `me`/`them` channel and
/// no diarized `speakerLabel`).
///
/// Used by the live recording view so the rolling 1.5–5 s windows read as
/// merged speaker turns instead of choppy fragments, and so an overlapping
/// chunk boundary doesn't show the same words twice. Pure + sorted, so it is
/// safe to recompute on every rebuild.
List<MeetingSegment> mergeConsecutiveTurns(
  List<MeetingSegment> segments, {
  int mergeGapMs = 2000,
}) {
  if (segments.length <= 1) {
    return segments;
  }
  final sorted = [...segments]..sort((a, b) => a.startMs.compareTo(b.startMs));
  return _mergeTurns(sorted, mergeGapMs);
}

MeetingSegment _relabel(MeetingSegment seg, String label) => MeetingSegment(
      id: seg.id,
      meetingId: seg.meetingId,
      workspaceId: seg.workspaceId,
      speaker: seg.speaker,
      speakerLabel: label,
      text: seg.text,
      startMs: seg.startMs,
      endMs: seg.endMs,
      createdAt: seg.createdAt,
    );

List<MeetingSegment> _mergeTurns(List<MeetingSegment> segments, int mergeGapMs) {
  if (segments.length <= 1) {
    return segments;
  }
  final out = <MeetingSegment>[];
  for (final seg in segments) {
    if (out.isNotEmpty) {
      final prev = out.last;
      final sameSpeaker =
          prev.speaker == seg.speaker && prev.speakerLabel == seg.speakerLabel;
      // Tiny fragments ("okay", "yeah") belong to the adjacent turn even across
      // a slightly longer gap than a full sentence would bridge, so glue them in
      // with a relaxed contiguity window.
      final tinyFragment = _visibleLength(seg.text) <= 8;
      final contiguous =
          seg.startMs - prev.endMs <= (tinyFragment ? mergeGapMs * 2 : mergeGapMs);
      if (sameSpeaker && contiguous) {
        // Chunk-boundary duplicate: rolling windows overlap, so adjacent windows
        // on the same channel sometimes re-transcribe the same words. If one
        // window's tokens are ≥67% contained in the other, treat it as a
        // duplicate and keep only the longer text instead of concatenating
        // (which would otherwise read "ship it ship it on friday").
        final dup = tokenContainment(prev.text, seg.text) >= 0.67 ||
            tokenContainment(seg.text, prev.text) >= 0.67;
        final mergedText = dup
            ? (seg.text.trim().length > prev.text.trim().length
                ? seg.text
                : prev.text)
            : _joinTurnText(prev.text, seg.text);
        // Keep the first fragment's id (ids stay unique across the new set since
        // merged-away fragments are dropped before `replaceSegments` re-inserts).
        out[out.length - 1] = MeetingSegment(
          id: prev.id,
          meetingId: prev.meetingId,
          workspaceId: prev.workspaceId,
          speaker: prev.speaker,
          speakerLabel: prev.speakerLabel,
          text: mergedText,
          startMs: prev.startMs,
          endMs: seg.endMs > prev.endMs ? seg.endMs : prev.endMs,
          createdAt: prev.createdAt,
        );
        continue;
      }
    }
    out.add(seg);
  }
  return out;
}

/// Number of non-whitespace characters in [text] — the "visible length" used to
/// decide whether a window is a tiny fragment worth gluing to its neighbour.
int _visibleLength(String text) =>
    text.replaceAll(RegExp(r'\s+'), '').length;

final RegExp _tokenSplit = RegExp(r'[^a-z0-9]+');

List<String> _normalizedTokens(String s) => s
    .toLowerCase()
    .split(_tokenSplit)
    .where((t) => t.isNotEmpty)
    .toList(growable: false);

/// Fraction of [candidate]'s word tokens that also appear in [reference]
/// (`0`..`1`). `1.0` means every candidate token is present in the reference —
/// i.e. the candidate adds nothing new and is a chunk-boundary duplicate. Pure
/// + top-level so it is directly unit-testable.
double tokenContainment(String reference, String candidate) {
  final cand = _normalizedTokens(candidate);
  if (cand.isEmpty) {
    return 0;
  }
  final ref = _normalizedTokens(reference).toSet();
  if (ref.isEmpty) {
    return 0;
  }
  var hit = 0;
  for (final t in cand) {
    if (ref.contains(t)) {
      hit++;
    }
  }
  return hit / cand.length;
}

String _joinTurnText(String a, String b) {
  final left = a.trimRight();
  final right = b.trimLeft();
  if (left.isEmpty) {
    return right;
  }
  if (right.isEmpty) {
    return left;
  }
  return '$left $right';
}
