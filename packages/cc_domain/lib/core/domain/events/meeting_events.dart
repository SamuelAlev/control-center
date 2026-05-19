import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Fired when a meeting recording is stopped and is ready to be summarized.
///
/// Triggers the built-in `meeting_summary` pipeline (via its
/// `MeetingRecordingStopped` event trigger). Carries everything that pipeline's
/// prompt needs in its trigger payload (`{{title}}`, `{{userNotes}}`,
/// `{{transcript}}`, plus the `{{workspaceId}}` / `{{meetingId}}` the agent
/// passes to `save_meeting_notes`), so the recorder stays decoupled from the
/// pipeline engine — it just announces that a recording finished.
class MeetingRecordingStopped implements DomainEvent {
  /// Creates a [MeetingRecordingStopped].
  const MeetingRecordingStopped({
    required this.workspaceId,
    required this.meetingId,
    required this.title,
    required this.userNotes,
    required this.transcript,
    required this.occurredAt,
    this.summaryInstructions,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The meeting whose recording stopped.
  final String meetingId;

  /// The meeting's (user-edited) title.
  final String title;

  /// The user's rough live notes at stop time.
  final String userNotes;

  /// The speaker-tagged transcript text (see `formatMeetingTranscript`).
  final String transcript;

  /// Optional extra instructions (from the selected meeting-note template)
  /// injected into the summarize prompt; null/empty for the default template.
  final String? summaryInstructions;

  @override
  final DateTime occurredAt;
}
