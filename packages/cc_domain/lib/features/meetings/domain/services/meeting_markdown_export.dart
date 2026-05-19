import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_transcript_formatter.dart';

/// Builds a complete, shareable Markdown document for a meeting: title, an
/// optional date/duration line, summary, notes, action items (as a task list),
/// decisions, and the full speaker-tagged transcript.
///
/// Pure (no I/O) so it is unit-testable and reusable by both the in-app export
/// (clipboard / file save) and any future agent/CLI export. Empty sections are
/// omitted so a thin meeting still produces clean output.
String buildMeetingMarkdown({
  required Meeting meeting,
  required List<MeetingSegment> segments,
  required List<MeetingActionItem> actionItems,
  required List<MeetingDecision> decisions,
  Map<String, String> speakerDisplayNames = const {},
  String? whenLine,
}) {
  final b = StringBuffer()..writeln('# ${meeting.title}');
  if (whenLine != null && whenLine.trim().isNotEmpty) {
    b
      ..writeln()
      ..writeln('_${whenLine.trim()}_');
  }

  final summary = meeting.summary?.trim();
  if (summary != null && summary.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Summary')
      ..writeln()
      ..writeln(summary);
  }

  final notes = meeting.enhancedNotes?.trim().isNotEmpty == true
      ? meeting.enhancedNotes!.trim()
      : meeting.userNotes.trim();
  if (notes.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Notes')
      ..writeln()
      ..writeln(notes);
  }

  if (actionItems.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Action items')
      ..writeln();
    for (final a in actionItems) {
      final box = a.done ? '[x]' : '[ ]';
      final owner = (a.owner != null && a.owner!.trim().isNotEmpty)
          ? ' (@${a.owner!.trim()})'
          : '';
      b.writeln('- $box ${a.content.trim()}$owner');
    }
  }

  if (decisions.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Decisions')
      ..writeln();
    for (final d in decisions) {
      b.writeln('- ${d.content.trim()}');
    }
  }

  final transcript =
      formatMeetingTranscript(segments, displayNames: speakerDisplayNames);
  if (transcript.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Transcript')
      ..writeln()
      ..writeln(transcript);
  }

  return b.toString().trimRight();
}
