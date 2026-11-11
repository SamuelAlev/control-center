// Meetings are workspace-scoped at the repository. Enums travel as `.name`,
// timestamps as ISO-8601 and the speaker embedding as a raw `List<double>`.
// The reads/user-facing edits travel over RPC; the recorder-only writes
// (upsert/appendSegment/replace*) stay host-side, so only the wire SHAPES the
// thin client parses back are mapped here (entity → wire).

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';

/// Maps a [Meeting] to its wire map (the inverse is [meetingFromWire]).
Map<String, dynamic> meetingToWire(Meeting m) => {
  'id': m.id,
  'workspace_id': m.workspaceId,
  'title': m.title,
  'status': m.status.name,
  'mode': m.mode.name,
  'source_app': ?m.sourceApp,
  'user_notes': m.userNotes,
  'enhanced_notes': ?m.enhancedNotes,
  'summary': ?m.summary,
  'summary_instructions': ?m.summaryInstructions,
  'audio_path': ?m.audioPath,
  'title_is_custom': m.titleIsCustom,
  'started_at': m.startedAt.toIso8601String(),
  'ended_at': ?m.endedAt?.toIso8601String(),
  'created_at': m.createdAt.toIso8601String(),
  'updated_at': m.updatedAt.toIso8601String(),
};

/// Reconstructs a [Meeting] from its wire map (the inverse of [meetingToWire]).
Meeting meetingFromWire(Map<String, dynamic> w) {
  DateTime parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);
  return Meeting(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    title: w['title'] as String? ?? '',
    status: MeetingStatus.fromStorage(w['status'] as String?),
    mode: MeetingMode.fromStorage(w['mode'] as String?),
    sourceApp: w['source_app'] as String?,
    userNotes: w['user_notes'] as String? ?? '',
    enhancedNotes: w['enhanced_notes'] as String?,
    summary: w['summary'] as String?,
    summaryInstructions: w['summary_instructions'] as String?,
    audioPath: w['audio_path'] as String?,
    titleIsCustom: w['title_is_custom'] as bool? ?? false,
    startedAt: parse(w['started_at']),
    endedAt: w['ended_at'] is String
        ? DateTime.parse(w['ended_at'] as String)
        : null,
    createdAt: parse(w['created_at']),
    updatedAt: parse(w['updated_at']),
  );
}

/// Maps a [MeetingSegment] to its wire map.
Map<String, dynamic> meetingSegmentToWire(MeetingSegment s) => {
  'id': s.id,
  'meeting_id': s.meetingId,
  'workspace_id': s.workspaceId,
  'speaker': s.speaker.name,
  'speaker_label': ?s.speakerLabel,
  'speaker_name_override': ?s.speakerNameOverride,
  'text': s.text,
  'start_ms': s.startMs,
  'end_ms': s.endMs,
  'created_at': s.createdAt.toIso8601String(),
};

/// Maps a [MeetingSpeakerLabel] to its wire map (embedding as a `List<double>`).
Map<String, dynamic> meetingSpeakerLabelToWire(MeetingSpeakerLabel s) => {
  'id': s.id,
  'meeting_id': s.meetingId,
  'workspace_id': s.workspaceId,
  'channel': s.channel.name,
  'label': s.label,
  'display_name': ?s.displayName,
  'embedding': ?s.embedding,
  'enrolled_profile_name': ?s.enrolledProfileName,
  'created_at': s.createdAt.toIso8601String(),
};

/// Maps a [MeetingActionItem] to its wire map.
Map<String, dynamic> meetingActionItemToWire(MeetingActionItem a) => {
  'id': a.id,
  'meeting_id': a.meetingId,
  'workspace_id': a.workspaceId,
  'content': a.content,
  'owner': ?a.owner,
  'done': a.done,
  'ticket_id': ?a.ticketId,
  'sort_order': a.sortOrder,
  'is_manual': a.isManual,
  'created_at': a.createdAt.toIso8601String(),
};

/// Reconstructs a [MeetingActionItem] from its wire map (the inverse of
/// [meetingActionItemToWire]), used by the `meeting.addActionItem` op.
MeetingActionItem meetingActionItemFromWire(Map<String, dynamic> w) =>
    MeetingActionItem(
      id: w['id'] as String,
      meetingId: w['meeting_id'] as String? ?? '',
      workspaceId: w['workspace_id'] as String? ?? '',
      content: w['content'] as String? ?? '',
      owner: w['owner'] as String?,
      done: w['done'] as bool? ?? false,
      ticketId: w['ticket_id'] as String?,
      sortOrder: (w['sort_order'] as num?)?.toInt() ?? 0,
      isManual: w['is_manual'] as bool? ?? false,
      createdAt: w['created_at'] is String
          ? DateTime.parse(w['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Maps a [MeetingDecision] to its wire map.
Map<String, dynamic> meetingDecisionToWire(MeetingDecision d) => {
  'id': d.id,
  'meeting_id': d.meetingId,
  'workspace_id': d.workspaceId,
  'content': d.content,
  'sort_order': d.sortOrder,
  'is_manual': d.isManual,
  'created_at': d.createdAt.toIso8601String(),
};

/// Reconstructs a [MeetingDecision] from its wire map (the inverse of
/// [meetingDecisionToWire]), used by the `meeting.addDecision` op.
MeetingDecision meetingDecisionFromWire(Map<String, dynamic> w) =>
    MeetingDecision(
      id: w['id'] as String,
      meetingId: w['meeting_id'] as String? ?? '',
      workspaceId: w['workspace_id'] as String? ?? '',
      content: w['content'] as String? ?? '',
      sortOrder: (w['sort_order'] as num?)?.toInt() ?? 0,
      isManual: w['is_manual'] as bool? ?? false,
      createdAt: w['created_at'] is String
          ? DateTime.parse(w['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Maps a `(meetingId → MeetingActionItemStats)` map to its wire object: a JSON
/// object keyed by meeting id whose values are `{total, done}`.
Map<String, dynamic> meetingActionItemStatsToWire(
  Map<String, MeetingActionItemStats> stats,
) => {
  for (final entry in stats.entries)
    entry.key: {'total': entry.value.total, 'done': entry.value.done},
};
