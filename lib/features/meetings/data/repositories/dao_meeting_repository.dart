import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/database/daos/meeting_dao.dart';
import 'package:control_center/features/meetings/data/mappers/meeting_mapper.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_decision.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:control_center/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for meetings and transcript segments.
class DaoMeetingRepository implements MeetingRepository {
  /// Creates a [DaoMeetingRepository].
  DaoMeetingRepository(this._dao);

  final MeetingDao _dao;
  final MeetingMapper _mapper = const MeetingMapper();

  @override
  Stream<List<Meeting>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<List<Meeting>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<List<Meeting>> getUnfinalized() =>
      _dao.getUnfinalized().then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<Meeting?> getById(String workspaceId, String id) => _dao
      .getById(workspaceId, id)
      .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(Meeting meeting) => _dao.upsertMeeting(
        db.MeetingsTableCompanion(
          id: Value(meeting.id),
          workspaceId: Value(meeting.workspaceId),
          title: Value(meeting.title),
          status: Value(meeting.status.toStorage()),
          mode: Value(meeting.mode.toStorage()),
          sourceApp: Value.absentIfNull(meeting.sourceApp),
          userNotes: Value(meeting.userNotes),
          enhancedNotes: Value.absentIfNull(meeting.enhancedNotes),
          summary: Value.absentIfNull(meeting.summary),
          audioPath: Value.absentIfNull(meeting.audioPath),
          startedAt: Value(meeting.startedAt),
          endedAt: Value.absentIfNull(meeting.endedAt),
          createdAt: Value(meeting.createdAt),
          updatedAt: Value(meeting.updatedAt),
        ),
      );

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao.deleteMeeting(workspaceId, id);

  @override
  Stream<List<MeetingSegment>> watchSegments(
    String workspaceId,
    String meetingId,
  ) =>
      _dao.watchSegments(workspaceId, meetingId).map(
            (rows) => rows.map(_mapper.segmentToDomain).toList(),
          );

  @override
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  ) =>
      _dao.getSegments(workspaceId, meetingId).then(
            (rows) => rows.map(_mapper.segmentToDomain).toList(),
          );

  @override
  Future<void> appendSegment(MeetingSegment segment) => _dao.insertSegment(
        db.MeetingTranscriptSegmentsTableCompanion(
          id: Value(segment.id),
          meetingId: Value(segment.meetingId),
          workspaceId: Value(segment.workspaceId),
          speaker: Value(segment.speaker.toStorage()),
          speakerLabel: Value.absentIfNull(segment.speakerLabel),
          content: Value(segment.text),
          startMs: Value(segment.startMs),
          endMs: Value(segment.endMs),
          createdAt: Value(segment.createdAt),
        ),
      );

  @override
  Future<void> setSegmentSpeakerLabel(
    String workspaceId,
    String segmentId,
    String label,
  ) =>
      _dao.setSegmentSpeakerLabel(workspaceId, segmentId, label);

  @override
  Stream<List<MeetingSpeakerLabel>> watchSpeakers(
    String workspaceId,
    String meetingId,
  ) =>
      _dao.watchSpeakers(workspaceId, meetingId).map(
            (rows) => rows.map(_mapper.speakerToDomain).toList(),
          );

  @override
  Future<List<MeetingSpeakerLabel>> getSpeakers(
    String workspaceId,
    String meetingId,
  ) =>
      _dao.getSpeakers(workspaceId, meetingId).then(
            (rows) => rows.map(_mapper.speakerToDomain).toList(),
          );

  @override
  Future<void> replaceSpeakers(
    String workspaceId,
    String meetingId,
    List<MeetingSpeakerLabel> speakers,
  ) =>
      _dao.replaceSpeakers(
        workspaceId,
        meetingId,
        [
          for (final s in speakers)
            db.MeetingSpeakersTableCompanion(
              id: Value(s.id),
              meetingId: Value(s.meetingId),
              workspaceId: Value(s.workspaceId),
              channel: Value(s.channel.toStorage()),
              label: Value(s.label),
              displayName: Value.absentIfNull(s.displayName),
              createdAt: Value(s.createdAt),
            ),
        ],
      );

  @override
  Future<void> renameSpeaker({
    required String workspaceId,
    required String id,
    required String? displayName,
  }) =>
      _dao.setSpeakerDisplayName(workspaceId, id, displayName);

  @override
  Stream<List<MeetingActionItem>> watchActionItems(
    String workspaceId,
    String meetingId,
  ) =>
      _dao.watchActionItems(workspaceId, meetingId).map(
            (rows) => rows.map(_mapper.actionItemToDomain).toList(),
          );

  @override
  Stream<List<MeetingDecision>> watchDecisions(
    String workspaceId,
    String meetingId,
  ) =>
      _dao.watchDecisions(workspaceId, meetingId).map(
            (rows) => rows.map(_mapper.decisionToDomain).toList(),
          );

  @override
  Stream<Map<String, MeetingActionItemStats>> watchActionItemStats(
    String workspaceId,
  ) =>
      _dao.watchActionItemStats(workspaceId);

  @override
  Stream<Map<String, int>> watchDecisionCounts(String workspaceId) =>
      _dao.watchDecisionCounts(workspaceId);

  @override
  Future<void> replaceActionItems(
    String workspaceId,
    String meetingId,
    List<MeetingActionItem> items,
  ) =>
      _dao.replaceActionItems(
        workspaceId,
        meetingId,
        [
          for (final item in items)
            db.MeetingActionItemsTableCompanion(
              id: Value(item.id),
              meetingId: Value(item.meetingId),
              workspaceId: Value(item.workspaceId),
              content: Value(item.content),
              owner: Value.absentIfNull(item.owner),
              done: Value(item.done),
              ticketId: Value.absentIfNull(item.ticketId),
              sortOrder: Value(item.sortOrder),
              createdAt: Value(item.createdAt),
            ),
        ],
      );

  @override
  Future<void> replaceDecisions(
    String workspaceId,
    String meetingId,
    List<MeetingDecision> decisions,
  ) =>
      _dao.replaceDecisions(
        workspaceId,
        meetingId,
        [
          for (final decision in decisions)
            db.MeetingDecisionsTableCompanion(
              id: Value(decision.id),
              meetingId: Value(decision.meetingId),
              workspaceId: Value(decision.workspaceId),
              content: Value(decision.content),
              sortOrder: Value(decision.sortOrder),
              createdAt: Value(decision.createdAt),
            ),
        ],
      );

  @override
  Future<void> setActionItemDone({
    required String workspaceId,
    required String id,
    required bool done,
  }) =>
      _dao.setActionItemDone(workspaceId, id, done: done);

  @override
  Future<void> setActionItemTicket({
    required String workspaceId,
    required String id,
    required String ticketId,
  }) =>
      _dao.setActionItemTicket(workspaceId, id, ticketId);
}
