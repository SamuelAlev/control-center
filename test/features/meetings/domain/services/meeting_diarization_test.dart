import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/services/meeting_diarization.dart';
import 'package:flutter_test/flutter_test.dart';

MeetingSegment _seg(
  MeetingSpeaker speaker,
  int start,
  int end,
  String text, {
  String? label,
}) =>
    MeetingSegment(
      id: '$speaker-$start-$end',
      meetingId: 'm',
      workspaceId: 'w',
      speaker: speaker,
      text: text,
      startMs: start,
      endMs: end,
      createdAt: DateTime(2024),
      speakerLabel: label,
    );

void main() {
  group('personLabel', () {
    test('maps a zero-based cluster index to a 1-based Person label', () {
      expect(personLabel(0), 'Person 1');
      expect(personLabel(2), 'Person 3');
    });
  });

  group('encode/decodeDiarizedSpans', () {
    test('round-trips spans', () {
      const spans = [
        DiarizedSpan(startMs: 0, endMs: 1000, speaker: 0),
        DiarizedSpan(startMs: 1000, endMs: 2500, speaker: 1),
      ];
      final decoded = decodeDiarizedSpans(encodeDiarizedSpans(spans));
      expect(decoded.length, 2);
      expect(decoded[1].startMs, 1000);
      expect(decoded[1].endMs, 2500);
      expect(decoded[1].speaker, 1);
    });

    test('decode tolerates malformed entries', () {
      expect(decodeDiarizedSpans('not json'), isEmpty);
      expect(decodeDiarizedSpans('{}'), isEmpty);
      // Skips a non-triple entry, keeps the valid one.
      final decoded = decodeDiarizedSpans('[[0,1000,0],["x"],[2000,3000,1]]');
      expect(decoded.map((s) => s.speaker), [0, 1]);
    });
  });

  group('separateTranscriptBySpeaker', () {
    const spans = [
      DiarizedSpan(startMs: 0, endMs: 5000, speaker: 0),
      DiarizedSpan(startMs: 5000, endMs: 10000, speaker: 1),
    ];

    test('labels the diarized channel and merges adjacent same-speaker turns',
        () {
      final out = separateTranscriptBySpeaker(
        segments: [
          _seg(MeetingSpeaker.them, 0, 1000, 'hello'),
          _seg(MeetingSpeaker.them, 1000, 2000, 'world'),
          _seg(MeetingSpeaker.them, 6000, 7000, 'bye'),
        ],
        spans: spans,
        channel: MeetingSpeaker.them,
      );
      expect(out.length, 2);
      expect(out[0].speakerLabel, 'Person 1');
      expect(out[0].text, 'hello world');
      expect(out[0].startMs, 0);
      expect(out[0].endMs, 2000);
      expect(out[1].speakerLabel, 'Person 2');
      expect(out[1].text, 'bye');
    });

    test('does not merge across a speaker change even within the gap window',
        () {
      const closeSpans = [
        DiarizedSpan(startMs: 0, endMs: 2000, speaker: 0),
        DiarizedSpan(startMs: 2000, endMs: 4000, speaker: 1),
      ];
      final out = separateTranscriptBySpeaker(
        segments: [
          _seg(MeetingSpeaker.them, 0, 1000, 'a'),
          _seg(MeetingSpeaker.them, 2500, 3500, 'b'),
        ],
        spans: closeSpans,
        channel: MeetingSpeaker.them,
      );
      expect(out.length, 2);
      expect(out[0].speakerLabel, 'Person 1');
      expect(out[1].speakerLabel, 'Person 2');
    });

    test('passes the other channel through unlabeled but still merges it', () {
      final out = separateTranscriptBySpeaker(
        segments: [
          _seg(MeetingSpeaker.me, 0, 1000, 'a'),
          _seg(MeetingSpeaker.me, 1200, 2000, 'b'),
        ],
        spans: spans,
        channel: MeetingSpeaker.them,
      );
      expect(out.length, 1);
      expect(out[0].speaker, MeetingSpeaker.me);
      expect(out[0].speakerLabel, isNull);
      expect(out[0].text, 'a b');
    });

    test('returns the input unchanged when there are no spans', () {
      final segs = [_seg(MeetingSpeaker.them, 0, 1000, 'a')];
      expect(
        separateTranscriptBySpeaker(
          segments: segs,
          spans: const [],
          channel: MeetingSpeaker.them,
        ),
        same(segs),
      );
    });
  });

  group('assignSpeakerByOverlap', () {
    const spans = [
      DiarizedSpan(startMs: 0, endMs: 5000, speaker: 0),
      DiarizedSpan(startMs: 5000, endMs: 10000, speaker: 1),
    ];

    test('returns the speaker whose span the window overlaps most', () {
      // 0–800 is fully inside speaker 0's span.
      expect(assignSpeakerByOverlap(spans, 0, 800), 0);
      // 6000–7000 is fully inside speaker 1's span.
      expect(assignSpeakerByOverlap(spans, 6000, 7000), 1);
    });

    test('a window straddling two spans goes to the dominant one', () {
      // 4000–6000: 1000ms with speaker 0, 1000ms with speaker 1 → tie broken by
      // the first-seen maximum (speaker 0). Shift it so one clearly dominates:
      expect(assignSpeakerByOverlap(spans, 4500, 6000), 1); // 500 vs 1000
      expect(assignSpeakerByOverlap(spans, 4000, 5500), 0); // 1000 vs 500
    });

    test('returns null when nothing overlaps', () {
      expect(assignSpeakerByOverlap(spans, 20000, 21000), isNull);
    });

    test('returns null for empty spans', () {
      expect(assignSpeakerByOverlap(const [], 0, 1000), isNull);
    });

    test('touching-but-not-overlapping boundaries do not count', () {
      // Window [10000,11000) starts exactly where the last span ends.
      expect(assignSpeakerByOverlap(spans, 10000, 11000), isNull);
    });
  });
}
