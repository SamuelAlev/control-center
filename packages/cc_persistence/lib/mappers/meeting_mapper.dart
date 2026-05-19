import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps Drift rows to meeting domain entities.
class MeetingMapper {
  /// Creates a const [MeetingMapper].
  const MeetingMapper();

  /// Converts a [db.MeetingsTableData] row to a [Meeting].
  Meeting toDomain(db.MeetingsTableData row) {
    return Meeting(
      id: row.id,
      workspaceId: row.workspaceId,
      title: row.title,
      titleIsCustom: row.titleIsCustom,
      status: MeetingStatus.fromStorage(row.status),
      mode: MeetingMode.fromStorage(row.mode),
      sourceApp: row.sourceApp,
      userNotes: row.userNotes,
      enhancedNotes: row.enhancedNotes,
      summary: row.summary,
      summaryInstructions: row.summaryInstructions,
      audioPath: row.audioPath,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a [db.MeetingTranscriptSegmentsTableData] row to a
  /// [MeetingSegment].
  MeetingSegment segmentToDomain(db.MeetingTranscriptSegmentsTableData row) {
    return MeetingSegment(
      id: row.id,
      meetingId: row.meetingId,
      workspaceId: row.workspaceId,
      speaker: MeetingSpeaker.fromStorage(row.speaker),
      speakerLabel: row.speakerLabel,
      speakerNameOverride: row.speakerNameOverride,
      text: row.content,
      startMs: row.startMs,
      endMs: row.endMs,
      createdAt: row.createdAt,
    );
  }

  /// Converts a [db.MeetingSpeakersTableData] row to a [MeetingSpeakerLabel].
  MeetingSpeakerLabel speakerToDomain(db.MeetingSpeakersTableData row) {
    return MeetingSpeakerLabel(
      id: row.id,
      meetingId: row.meetingId,
      workspaceId: row.workspaceId,
      channel: MeetingSpeaker.fromStorage(row.channel),
      label: row.label,
      displayName: row.displayName,
      embedding: decodeSpeakerEmbedding(row.embedding),
      enrolledProfileName: row.enrolledProfileName,
      createdAt: row.createdAt,
    );
  }

  /// Converts a [db.MeetingActionItemsTableData] row to a [MeetingActionItem].
  MeetingActionItem actionItemToDomain(db.MeetingActionItemsTableData row) {
    return MeetingActionItem(
      id: row.id,
      meetingId: row.meetingId,
      workspaceId: row.workspaceId,
      content: row.content,
      owner: row.owner,
      done: row.done,
      ticketId: row.ticketId,
      sortOrder: row.sortOrder,
      isManual: row.isManual,
      createdAt: row.createdAt,
    );
  }

  /// Converts a [db.MeetingDecisionsTableData] row to a [MeetingDecision].
  MeetingDecision decisionToDomain(db.MeetingDecisionsTableData row) {
    return MeetingDecision(
      id: row.id,
      meetingId: row.meetingId,
      workspaceId: row.workspaceId,
      content: row.content,
      sortOrder: row.sortOrder,
      isManual: row.isManual,
      createdAt: row.createdAt,
    );
  }
}
