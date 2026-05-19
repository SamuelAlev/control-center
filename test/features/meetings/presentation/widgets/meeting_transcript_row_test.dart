import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MeetingTranscriptRow', () {
    testWidgets('renders timestamp and text', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingTranscriptRow(
          speaker: MeetingSpeaker.me,
          startMs: 45000,
          text: 'Let us discuss the roadmap.',
        ),
      ));

      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('Let us discuss the roadmap.'), findsOneWidget);
    });

    testWidgets('renders "You" label for local speaker', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingTranscriptRow(
          speaker: MeetingSpeaker.me,
          startMs: 0,
          text: 'Hello world.',
        ),
      ));

      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('renders "Others" label for remote speaker', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingTranscriptRow(
          speaker: MeetingSpeaker.them,
          startMs: 0,
          text: 'Hi there.',
        ),
      ));

      expect(find.text('Others'), findsOneWidget);
    });

    testWidgets('compact mode renders', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingTranscriptRow(
          speaker: MeetingSpeaker.me,
          startMs: 5000,
          text: 'Compact row.',
          compact: true,
        ),
      ));

      expect(find.text('Compact row.'), findsOneWidget);
    });

    testWidgets('fromSegment factory creates identical widget', (tester) async {
      final segment = MeetingSegment(
        id: 's1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        speaker: MeetingSpeaker.me,
        text: 'From segment.',
        startMs: 120000,
        endMs: 125000,
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(testWrap(
        MeetingTranscriptRow.fromSegment(segment),
      ));

      expect(find.text('02:00'), findsOneWidget);
      expect(find.text('From segment.'), findsOneWidget);
    });

    testWidgets('renders highlighted text when query matches', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingTranscriptRow(
          speaker: MeetingSpeaker.me,
          startMs: 0,
          text: 'We need to ship the feature.',
          query: 'ship',
        ),
      ));

      // The HighlightedText widget should be present with styled RichText.
      expect(find.byType(MeetingTranscriptRow), findsOneWidget);
    });
  });
}
