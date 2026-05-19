import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:test/test.dart';

final _baseTime = DateTime(2025, 6, 1, 12, 0, 0);

MeetingSegment _seg({
  String id = 'seg-1',
  String meetingId = 'meeting-1',
  String workspaceId = 'ws-1',
  MeetingSpeaker speaker = MeetingSpeaker.me,
  String text = 'Hello',
  int startMs = 0,
  int endMs = 5000,
}) =>
    MeetingSegment(
      id: id,
      meetingId: meetingId,
      workspaceId: workspaceId,
      speaker: speaker,
      text: text,
      startMs: startMs,
      endMs: endMs,
      createdAt: _baseTime,
    );

void main() {
  group('formatMeetingTranscript', () {
    test('empty list returns empty string', () {
      expect(formatMeetingTranscript([]), '');
    });

    test('single ME segment formatted correctly', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 0, endMs: 5000, text: 'Hello world'),
      ]);
      expect(result, '[00:00] ME: Hello world');
    });

    test('single THEM segment formatted correctly', () {
      final result = formatMeetingTranscript([
        _seg(
          speaker: MeetingSpeaker.them,
          startMs: 0,
          endMs: 5000,
          text: 'Hi there',
        ),
      ]);
      expect(result, '[00:00] THEM: Hi there');
    });

    test('multiple segments formatted with timestamps', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 0, endMs: 3000, text: 'First'),
        _seg(
          speaker: MeetingSpeaker.them,
          startMs: 3000,
          endMs: 6000,
          text: 'Second',
        ),
        _seg(startMs: 6000, endMs: 9000, text: 'Third'),
      ]);
      expect(
        result,
        '[00:00] ME: First\n'
        '[00:03] THEM: Second\n'
        '[00:06] ME: Third',
      );
    });

    test('minute rollover at 60s', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 65000, endMs: 70000, text: 'After one minute'),
      ]);
      expect(result, '[01:05] ME: After one minute');
    });

    test('hour boundary at 3600s', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 3665000, endMs: 3666000, text: 'After one hour'),
      ]);
      expect(result, '[61:05] ME: After one hour');
    });

    test('negative startMs clamped to zero', () {
      final result = formatMeetingTranscript([
        _seg(startMs: -1000, endMs: 5000, text: 'Negative'),
      ]);
      expect(result, '[00:00] ME: Negative');
    });

    test('zero milliseconds', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 0, endMs: 0, text: 'Zero'),
      ]);
      expect(result, '[00:00] ME: Zero');
    });

    test('single-digit seconds padded', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 5000, endMs: 9000, text: 'Five seconds'),
      ]);
      expect(result, '[00:05] ME: Five seconds');
    });

    test('large millisecond values', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 7200000, endMs: 7201000, text: 'Two hours'),
      ]);
      expect(result, '[120:00] ME: Two hours');
    });

    test('alternating speakers produce correct labels', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 0, endMs: 2000, speaker: MeetingSpeaker.me, text: 'Q'),
        _seg(
          startMs: 2000,
          endMs: 4000,
          speaker: MeetingSpeaker.them,
          text: 'A',
        ),
        _seg(startMs: 4000, endMs: 6000, speaker: MeetingSpeaker.me, text: 'Q2'),
        _seg(
          startMs: 6000,
          endMs: 8000,
          speaker: MeetingSpeaker.them,
          text: 'A2',
        ),
      ]);
      expect(
        result,
        '[00:00] ME: Q\n'
        '[00:02] THEM: A\n'
        '[00:04] ME: Q2\n'
        '[00:06] THEM: A2',
      );
    });

    test('preserves text with special characters', () {
      final result = formatMeetingTranscript([
        _seg(startMs: 0, endMs: 1000, text: 'Line 1\nLine 2'),
      ]);
      expect(result, '[00:00] ME: Line 1\nLine 2');
    });
  });
}
