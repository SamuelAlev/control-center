import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/meeting_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/meeting_mapper.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// DAO-based repository for meetings and transcript segments.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).meetingDao` per call: a meeting and its transcript,
/// speakers, action items and decisions all live in the workspace's own
/// database file, so the workspace id picks the file before any SQL runs.
/// [getUnfinalized] is the one read that spans files.
class DaoMeetingRepository implements MeetingRepository {
  /// Creates a [DaoMeetingRepository] over the per-workspace databases.
  DaoMeetingRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final MeetingMapper _mapper = const MeetingMapper();
  final Uuid _uuid = const Uuid();

  MeetingDao _dao(String workspaceId) => _dbs.of(workspaceId).meetingDao;

  @override
  Stream<List<Meeting>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<Meeting>> getByWorkspace(String workspaceId) => _dao(workspaceId)
      .getByWorkspace(workspaceId)
      .then((rows) => rows.map(_mapper.toDomain).toList());

  /// CROSS-WORKSPACE BY DESIGN: the startup reconciler un-sticks meetings left
  /// `recording`/`processing` by a crash, wherever they live, so completeness
  /// across every workspace file is the point. Workspace-scoped surfaces use
  /// [getByWorkspace].
  @override
  Future<List<Meeting>> getUnfinalized() async {
    final perWorkspace = await _cross.fanOut(
      (workspaceDb) => workspaceDb.meetingDao.getUnfinalized(),
    );
    return [
      for (final rows in perWorkspace)
        for (final row in rows) _mapper.toDomain(row),
    ];
  }

  @override
  Future<Meeting?> getById(String workspaceId, String id) => _dao(workspaceId)
      .getById(workspaceId, id)
      .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(Meeting meeting) =>
      _dao(meeting.workspaceId).upsertMeeting(
        db.MeetingsTableCompanion(
          id: Value(meeting.id),
          workspaceId: Value(meeting.workspaceId),
          title: Value(meeting.title),
          titleIsCustom: Value(meeting.titleIsCustom),
          status: Value(meeting.status.toStorage()),
          mode: Value(meeting.mode.toStorage()),
          sourceApp: Value.absentIfNull(meeting.sourceApp),
          userNotes: Value(meeting.userNotes),
          enhancedNotes: Value.absentIfNull(meeting.enhancedNotes),
          summary: Value.absentIfNull(meeting.summary),
          summaryInstructions: Value.absentIfNull(meeting.summaryInstructions),
          audioPath: Value.absentIfNull(meeting.audioPath),
          startedAt: Value(meeting.startedAt),
          endedAt: Value.absentIfNull(meeting.endedAt),
          createdAt: Value(meeting.createdAt),
          updatedAt: Value(meeting.updatedAt),
        ),
      );

  @override
  Future<void> updateTitle({
    required String workspaceId,
    required String meetingId,
    required String title,
  }) => _dao(workspaceId).updateMeetingTitle(workspaceId, meetingId, title);

  @override
  Future<void> updateNotes({
    required String workspaceId,
    required String meetingId,
    required String notes,
  }) => _dao(workspaceId).updateMeetingNotes(workspaceId, meetingId, notes);

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteMeeting(workspaceId, id);

  @override
  Stream<List<MeetingSegment>> watchSegments(
    String workspaceId,
    String meetingId,
  ) => _dao(workspaceId)
      .watchSegments(workspaceId, meetingId)
      .map((rows) => rows.map(_mapper.segmentToDomain).toList());

  @override
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  ) => _dao(workspaceId)
      .getSegments(workspaceId, meetingId)
      .then((rows) => rows.map(_mapper.segmentToDomain).toList());

  @override
  Future<void> appendSegment(MeetingSegment segment) =>
      _dao(segment.workspaceId).insertSegment(
        db.MeetingTranscriptSegmentsTableCompanion(
          id: Value(segment.id),
          meetingId: Value(segment.meetingId),
          workspaceId: Value(segment.workspaceId),
          speaker: Value(segment.speaker.toStorage()),
          speakerLabel: Value.absentIfNull(segment.speakerLabel),
          speakerNameOverride: Value.absentIfNull(segment.speakerNameOverride),
          content: Value(segment.text),
          startMs: Value(segment.startMs),
          endMs: Value(segment.endMs),
          createdAt: Value(segment.createdAt),
        ),
      );

  @override
  Future<void> replaceSegments(
    String workspaceId,
    String meetingId,
    List<MeetingSegment> segments,
  ) => _dao(workspaceId).replaceSegments(workspaceId, meetingId, [
    for (final s in segments)
      db.MeetingTranscriptSegmentsTableCompanion(
        id: Value(s.id),
        meetingId: Value(s.meetingId),
        workspaceId: Value(s.workspaceId),
        speaker: Value(s.speaker.toStorage()),
        speakerLabel: Value.absentIfNull(s.speakerLabel),
        speakerNameOverride: Value.absentIfNull(s.speakerNameOverride),
        content: Value(s.text),
        startMs: Value(s.startMs),
        endMs: Value(s.endMs),
        createdAt: Value(s.createdAt),
      ),
  ]);

  @override
  Future<void> setSegmentSpeakerLabel(
    String workspaceId,
    String segmentId,
    String label,
  ) => _dao(workspaceId).setSegmentSpeakerLabel(workspaceId, segmentId, label);

  @override
  Future<void> setSegmentSpeakerName(
    String workspaceId,
    String segmentId,
    String? name,
  ) => _dao(
    workspaceId,
  ).setSegmentSpeakerNameOverride(workspaceId, segmentId, name);

  @override
  Future<void> clearSpeakerNameOverridesForLabel({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
  }) => _dao(workspaceId).clearSpeakerNameOverridesForLabel(
    workspaceId: workspaceId,
    meetingId: meetingId,
    channel: channel.toStorage(),
    label: label,
  );

  @override
  Future<void> setSpeakerEnrolledProfile({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
    required String? profileName,
  }) => _dao(workspaceId).setSpeakerEnrolledProfileByLabel(
    workspaceId: workspaceId,
    meetingId: meetingId,
    channel: channel.toStorage(),
    label: label,
    profileName: profileName,
  );

  @override
  Stream<List<MeetingSpeakerLabel>> watchSpeakers(
    String workspaceId,
    String meetingId,
  ) => _dao(workspaceId)
      .watchSpeakers(workspaceId, meetingId)
      .map((rows) => rows.map(_mapper.speakerToDomain).toList());

  @override
  Future<List<MeetingSpeakerLabel>> getSpeakers(
    String workspaceId,
    String meetingId,
  ) => _dao(workspaceId)
      .getSpeakers(workspaceId, meetingId)
      .then((rows) => rows.map(_mapper.speakerToDomain).toList());

  @override
  Future<void> replaceSpeakers(
    String workspaceId,
    String meetingId,
    List<MeetingSpeakerLabel> speakers,
  ) => _dao(workspaceId).replaceSpeakers(workspaceId, meetingId, [
    for (final s in speakers)
      db.MeetingSpeakersTableCompanion(
        id: Value(s.id),
        meetingId: Value(s.meetingId),
        workspaceId: Value(s.workspaceId),
        channel: Value(s.channel.toStorage()),
        label: Value(s.label),
        displayName: Value.absentIfNull(s.displayName),
        embedding: Value.absentIfNull(encodeSpeakerEmbedding(s.embedding)),
        enrolledProfileName: Value.absentIfNull(s.enrolledProfileName),
        createdAt: Value(s.createdAt),
      ),
  ]);

  @override
  Future<void> renameSpeaker({
    required String workspaceId,
    required String id,
    required String? displayName,
  }) => _dao(workspaceId).setSpeakerDisplayName(workspaceId, id, displayName);

  @override
  Future<void> renameSpeakerByLabel({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
    required String? displayName,
  }) => _dao(workspaceId).upsertSpeakerDisplayName(
    workspaceId: workspaceId,
    meetingId: meetingId,
    channel: channel.toStorage(),
    label: label,
    displayName: displayName,
    newId: _uuid.v4(),
    createdAt: DateTime.now(),
  );

  @override
  Stream<List<MeetingActionItem>> watchActionItems(
    String workspaceId,
    String meetingId,
  ) => _dao(workspaceId)
      .watchActionItems(workspaceId, meetingId)
      .map((rows) => rows.map(_mapper.actionItemToDomain).toList());

  @override
  Stream<List<MeetingDecision>> watchDecisions(
    String workspaceId,
    String meetingId,
  ) => _dao(workspaceId)
      .watchDecisions(workspaceId, meetingId)
      .map((rows) => rows.map(_mapper.decisionToDomain).toList());

  @override
  Stream<Map<String, MeetingActionItemStats>> watchActionItemStats(
    String workspaceId,
  ) => _dao(workspaceId).watchActionItemStats(workspaceId);

  @override
  Stream<Map<String, int>> watchDecisionCounts(String workspaceId) =>
      _dao(workspaceId).watchDecisionCounts(workspaceId);

  @override
  Future<void> replaceActionItems(
    String workspaceId,
    String meetingId,
    List<MeetingActionItem> items,
  ) => _dao(workspaceId).replaceActionItems(workspaceId, meetingId, [
    for (final item in items) _actionItemCompanion(item),
  ]);

  @override
  Future<void> replaceDecisions(
    String workspaceId,
    String meetingId,
    List<MeetingDecision> decisions,
  ) => _dao(workspaceId).replaceDecisions(workspaceId, meetingId, [
    for (final decision in decisions) _decisionCompanion(decision),
  ]);

  @override
  Future<void> addActionItem(MeetingActionItem item) =>
      _dao(item.workspaceId).insertActionItem(_actionItemCompanion(item));

  @override
  Future<void> updateActionItem({
    required String workspaceId,
    required String id,
    required String content,
    String? owner,
  }) => _dao(
    workspaceId,
  ).updateActionItemContent(workspaceId, id, content: content, owner: owner);

  @override
  Future<void> deleteActionItem(String workspaceId, String id) =>
      _dao(workspaceId).deleteActionItem(workspaceId, id);

  @override
  Future<void> addDecision(MeetingDecision decision) =>
      _dao(decision.workspaceId).insertDecision(_decisionCompanion(decision));

  @override
  Future<void> updateDecision({
    required String workspaceId,
    required String id,
    required String content,
  }) => _dao(
    workspaceId,
  ).updateDecisionContent(workspaceId, id, content: content);

  @override
  Future<void> deleteDecision(String workspaceId, String id) =>
      _dao(workspaceId).deleteDecision(workspaceId, id);

  db.MeetingActionItemsTableCompanion _actionItemCompanion(
    MeetingActionItem item,
  ) => db.MeetingActionItemsTableCompanion(
    id: Value(item.id),
    meetingId: Value(item.meetingId),
    workspaceId: Value(item.workspaceId),
    content: Value(item.content),
    owner: Value.absentIfNull(item.owner),
    done: Value(item.done),
    ticketId: Value.absentIfNull(item.ticketId),
    sortOrder: Value(item.sortOrder),
    isManual: Value(item.isManual),
    createdAt: Value(item.createdAt),
  );

  db.MeetingDecisionsTableCompanion _decisionCompanion(
    MeetingDecision decision,
  ) => db.MeetingDecisionsTableCompanion(
    id: Value(decision.id),
    meetingId: Value(decision.meetingId),
    workspaceId: Value(decision.workspaceId),
    content: Value(decision.content),
    sortOrder: Value(decision.sortOrder),
    isManual: Value(decision.isManual),
    createdAt: Value(decision.createdAt),
  );

  @override
  Future<void> setActionItemDone({
    required String workspaceId,
    required String id,
    required bool done,
  }) => _dao(workspaceId).setActionItemDone(workspaceId, id, done: done);

  @override
  Future<void> setActionItemTicket({
    required String workspaceId,
    required String id,
    required String ticketId,
  }) => _dao(workspaceId).setActionItemTicket(workspaceId, id, ticketId);
}
