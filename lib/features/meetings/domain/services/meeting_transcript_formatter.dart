import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';

/// Formats transcript [segments] into the speaker-tagged plain text fed to the
/// summarizer and used as a fallback when no enhanced notes are produced.
///
/// Each line is `[mm:ss] <speaker>: text`, oldest first. Once the diarization
/// step has run, a segment carries a [MeetingSegment.speakerLabel]
/// (e.g. `Person 1`) which is used in place of the coarse `THEM`, giving the
/// summarizer per-speaker context. An optional [displayNames] map (diarization
/// label → user-assigned name) overrides the label when the user has renamed a
/// speaker. Pure (no I/O) so the recorder controller, the diarization step, and
/// the reconciler can share one canonical format.
String formatMeetingTranscript(
  List<MeetingSegment> segments, {
  Map<String, String> displayNames = const {},
}) {
  final buffer = StringBuffer();
  for (final s in segments) {
    final label = s.speakerLabel;
    final who = label != null
        ? (displayNames[label] ?? label)
        : (s.speaker == MeetingSpeaker.me ? 'ME' : 'THEM');
    buffer.writeln('[${_stamp(s.startMs)}] $who: ${s.text}');
  }
  return buffer.toString().trim();
}

String _stamp(int ms) {
  final totalSeconds = (ms < 0 ? 0 : ms) ~/ 1000;
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
