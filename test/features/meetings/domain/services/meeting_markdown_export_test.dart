import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_markdown_export.dart';
import 'package:flutter_test/flutter_test.dart';

Meeting _meeting({String? summary, String? enhanced, String userNotes = ''}) =>
    Meeting(
      id: 'm1',
      workspaceId: 'w',
      title: 'Roadmap sync',
      status: MeetingStatus.done,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      startedAt: DateTime(2024),
      summary: summary,
      enhancedNotes: enhanced,
      userNotes: userNotes,
    );

MeetingSegment _seg(MeetingSpeaker who, int s, int e, String text) =>
    MeetingSegment(
      id: '$who-$s',
      meetingId: 'm1',
      workspaceId: 'w',
      speaker: who,
      text: text,
      startMs: s,
      endMs: e,
      createdAt: DateTime(2024),
    );

void main() {
  group('buildMeetingMarkdown', () {
    test('includes every populated section', () {
      final md = buildMeetingMarkdown(
        meeting: _meeting(summary: 'We aligned on Q3.', enhanced: 'Long notes.'),
        segments: [_seg(MeetingSpeaker.me, 0, 1000, 'Hello team')],
        actionItems: [
          MeetingActionItem(
            id: 'a1',
            meetingId: 'm1',
            workspaceId: 'w',
            content: 'Email the client',
            owner: 'Sam',
            sortOrder: 0,
            createdAt: DateTime(2024),
          ),
          MeetingActionItem(
            id: 'a2',
            meetingId: 'm1',
            workspaceId: 'w',
            content: 'Close the ticket',
            done: true,
            sortOrder: 1,
            createdAt: DateTime(2024),
          ),
        ],
        decisions: [
          MeetingDecision(
            id: 'd1',
            meetingId: 'm1',
            workspaceId: 'w',
            content: 'Ship Friday',
            sortOrder: 0,
            createdAt: DateTime(2024),
          ),
        ],
        whenLine: 'Today · 10:00',
      );

      expect(md, startsWith('# Roadmap sync'));
      expect(md, contains('_Today · 10:00_'));
      expect(md, contains('## Summary\n\nWe aligned on Q3.'));
      expect(md, contains('## Notes\n\nLong notes.'));
      expect(md, contains('- [ ] Email the client (@Sam)'));
      expect(md, contains('- [x] Close the ticket'));
      expect(md, contains('## Decisions\n\n- Ship Friday'));
      expect(md, contains('## Transcript'));
      expect(md, contains('ME: Hello team'));
    });

    test('omits empty sections and falls back to user notes', () {
      final md = buildMeetingMarkdown(
        meeting: _meeting(userNotes: 'just my rough notes'),
        segments: const [],
        actionItems: const [],
        decisions: const [],
      );
      expect(md, contains('## Notes\n\njust my rough notes'));
      expect(md, isNot(contains('## Summary')));
      expect(md, isNot(contains('## Action items')));
      expect(md, isNot(contains('## Decisions')));
      expect(md, isNot(contains('## Transcript')));
    });
  });
}
