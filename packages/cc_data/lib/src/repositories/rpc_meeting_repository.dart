import 'package:cc_data/src/repositories/remote_meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MeetingRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `meeting.*` ops + the
/// `meeting.watch*` subscriptions, mapping the wire shapes back to the meeting
/// entities. The host is the single source of truth and owns all persistence;
/// this client never touches a database.
///
/// Reads, watches, and the user-facing edits the web meeting screens reach
/// (per-segment / whole-speaker rename, voice-profile provenance, action-item /
/// decision CRUD) are all served. The recorder-only writes — `upsert`,
/// `appendSegment`, `replaceSegments`, `replaceSpeakers`, `replaceActionItems`,
/// `replaceDecisions`, `renameSpeaker` (by id), and the startup reconciler's
/// `getUnfinalized` — are host-side only (live recording + summarization run on
/// the desktop host, the web client never reaches them) and throw
/// [UnsupportedError].
class RpcMeetingRepository implements MeetingRepository {
  /// Creates an [RpcMeetingRepository] over [client].
  RpcMeetingRepository(RemoteRpcClient client)
    : _remote = RemoteMeetingRepository(client);

  final RemoteMeetingRepository _remote;

  static DateTime _parse(Object? iso) => iso is String
      ? DateTime.parse(iso)
      : DateTime.fromMillisecondsSinceEpoch(0);

  /// Rebuilds a [Meeting] from its wire map.
  static Meeting _meetingFromWire(Map<String, dynamic> w) => Meeting(
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
    startedAt: _parse(w['started_at']),
    endedAt: w['ended_at'] is String
        ? DateTime.parse(w['ended_at'] as String)
        : null,
    createdAt: _parse(w['created_at']),
    updatedAt: _parse(w['updated_at']),
  );

  /// Rebuilds a [MeetingSegment] from its wire map.
  static MeetingSegment _segmentFromWire(Map<String, dynamic> w) =>
      MeetingSegment(
        id: w['id'] as String,
        meetingId: w['meeting_id'] as String? ?? '',
        workspaceId: w['workspace_id'] as String? ?? '',
        speaker: MeetingSpeaker.fromStorage(w['speaker'] as String?),
        speakerLabel: w['speaker_label'] as String?,
        speakerNameOverride: w['speaker_name_override'] as String?,
        text: w['text'] as String? ?? '',
        startMs: (w['start_ms'] as num?)?.toInt() ?? 0,
        endMs: (w['end_ms'] as num?)?.toInt() ?? 0,
        createdAt: _parse(w['created_at']),
      );

  /// Rebuilds a [MeetingSpeakerLabel] from its wire map.
  static MeetingSpeakerLabel _speakerFromWire(Map<String, dynamic> w) =>
      MeetingSpeakerLabel(
        id: w['id'] as String,
        meetingId: w['meeting_id'] as String? ?? '',
        workspaceId: w['workspace_id'] as String? ?? '',
        channel: MeetingSpeaker.fromStorage(w['channel'] as String?),
        label: w['label'] as String? ?? '',
        displayName: w['display_name'] as String?,
        embedding: (w['embedding'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
        enrolledProfileName: w['enrolled_profile_name'] as String?,
        createdAt: _parse(w['created_at']),
      );

  /// Rebuilds a [MeetingActionItem] from its wire map.
  static MeetingActionItem _actionItemFromWire(Map<String, dynamic> w) =>
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
        createdAt: _parse(w['created_at']),
      );

  /// Serializes a [MeetingActionItem] to its wire map (the inverse of
  /// [_actionItemFromWire]), for the `meeting.addActionItem` op.
  static Map<String, dynamic> _actionItemToWire(MeetingActionItem a) => {
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

  /// Rebuilds a [MeetingDecision] from its wire map.
  static MeetingDecision _decisionFromWire(Map<String, dynamic> w) =>
      MeetingDecision(
        id: w['id'] as String,
        meetingId: w['meeting_id'] as String? ?? '',
        workspaceId: w['workspace_id'] as String? ?? '',
        content: w['content'] as String? ?? '',
        sortOrder: (w['sort_order'] as num?)?.toInt() ?? 0,
        isManual: w['is_manual'] as bool? ?? false,
        createdAt: _parse(w['created_at']),
      );

  /// Serializes a [MeetingDecision] to its wire map, for `meeting.addDecision`.
  static Map<String, dynamic> _decisionToWire(MeetingDecision d) => {
    'id': d.id,
    'meeting_id': d.meetingId,
    'workspace_id': d.workspaceId,
    'content': d.content,
    'sort_order': d.sortOrder,
    'is_manual': d.isManual,
    'created_at': d.createdAt.toIso8601String(),
  };

  // ---- Reads & watches ----

  @override
  Stream<List<Meeting>> watchByWorkspace(String workspaceId) =>
      _remote.watchByWorkspace().map(
        (list) => list.map(_meetingFromWire).toList(),
      );

  @override
  Future<List<Meeting>> getByWorkspace(String workspaceId) async {
    final list = await _remote.getByWorkspace();
    return list.map(_meetingFromWire).toList();
  }

  @override
  Future<Meeting?> getById(String workspaceId, String id) async {
    final w = await _remote.getById(id);
    return w == null ? null : _meetingFromWire(w);
  }

  @override
  Stream<List<MeetingSegment>> watchSegments(
    String workspaceId,
    String meetingId,
  ) => _remote
      .watchSegments(meetingId)
      .map((list) => list.map(_segmentFromWire).toList());

  @override
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  ) async {
    final list = await _remote.getSegments(meetingId);
    return list.map(_segmentFromWire).toList();
  }

  @override
  Stream<List<MeetingSpeakerLabel>> watchSpeakers(
    String workspaceId,
    String meetingId,
  ) => _remote
      .watchSpeakers(meetingId)
      .map((list) => list.map(_speakerFromWire).toList());

  @override
  Future<List<MeetingSpeakerLabel>> getSpeakers(
    String workspaceId,
    String meetingId,
  ) async {
    final list = await _remote.getSpeakers(meetingId);
    return list.map(_speakerFromWire).toList();
  }

  @override
  Stream<List<MeetingActionItem>> watchActionItems(
    String workspaceId,
    String meetingId,
  ) => _remote
      .watchActionItems(meetingId)
      .map((list) => list.map(_actionItemFromWire).toList());

  @override
  Stream<List<MeetingDecision>> watchDecisions(
    String workspaceId,
    String meetingId,
  ) => _remote
      .watchDecisions(meetingId)
      .map((list) => list.map(_decisionFromWire).toList());

  @override
  Stream<Map<String, MeetingActionItemStats>> watchActionItemStats(
    String workspaceId,
  ) => _remote.watchActionItemStats().map((object) {
    final out = <String, MeetingActionItemStats>{};
    for (final entry in object.entries) {
      final value = entry.value;
      if (value is Map) {
        out[entry.key] = (
          total: (value['total'] as num?)?.toInt() ?? 0,
          done: (value['done'] as num?)?.toInt() ?? 0,
        );
      }
    }
    return out;
  });

  @override
  Stream<Map<String, int>> watchDecisionCounts(String workspaceId) =>
      _remote.watchDecisionCounts().map((object) {
        final out = <String, int>{};
        for (final entry in object.entries) {
          out[entry.key] = (entry.value as num?)?.toInt() ?? 0;
        }
        return out;
      });

  // ---- User-facing mutations (served over RPC) ----

  @override
  Future<void> delete(String workspaceId, String id) => _remote.delete(id);

  @override
  Future<void> updateTitle({
    required String workspaceId,
    required String meetingId,
    required String title,
  }) => _remote.updateTitle(meetingId, title);

  @override
  Future<void> updateNotes({
    required String workspaceId,
    required String meetingId,
    required String notes,
  }) => _remote.updateNotes(meetingId, notes);

  @override
  Future<void> setSegmentSpeakerName(
    String workspaceId,
    String segmentId,
    String? name,
  ) => _remote.setSegmentSpeakerName(segmentId, name);

  @override
  Future<void> clearSpeakerNameOverridesForLabel({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
  }) => _remote.clearSpeakerNameOverridesForLabel(
    meetingId: meetingId,
    channel: channel.name,
    label: label,
  );

  @override
  Future<void> setSpeakerEnrolledProfile({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
    required String? profileName,
  }) => _remote.setSpeakerEnrolledProfile(
    meetingId: meetingId,
    channel: channel.name,
    label: label,
    profileName: profileName,
  );

  @override
  Future<void> renameSpeakerByLabel({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
    required String? displayName,
  }) => _remote.renameSpeakerByLabel(
    meetingId: meetingId,
    channel: channel.name,
    label: label,
    displayName: displayName,
  );

  @override
  Future<void> addActionItem(MeetingActionItem item) =>
      _remote.addActionItem(_actionItemToWire(item));

  @override
  Future<void> updateActionItem({
    required String workspaceId,
    required String id,
    required String content,
    String? owner,
  }) => _remote.updateActionItem(id: id, content: content, owner: owner);

  @override
  Future<void> deleteActionItem(String workspaceId, String id) =>
      _remote.deleteActionItem(id);

  @override
  Future<void> setActionItemDone({
    required String workspaceId,
    required String id,
    required bool done,
  }) => _remote.setActionItemDone(id: id, done: done);

  @override
  Future<void> setActionItemTicket({
    required String workspaceId,
    required String id,
    required String ticketId,
  }) => _remote.setActionItemTicket(id: id, ticketId: ticketId);

  @override
  Future<void> addDecision(MeetingDecision decision) =>
      _remote.addDecision(_decisionToWire(decision));

  @override
  Future<void> updateDecision({
    required String workspaceId,
    required String id,
    required String content,
  }) => _remote.updateDecision(id: id, content: content);

  @override
  Future<void> deleteDecision(String workspaceId, String id) =>
      _remote.deleteDecision(id);

  // ---- Host-owned surface: live recording + summarization run on the desktop
  // host, so the recorder-only writes + the startup reconciler's unfinalized
  // sweep are never reached by a thin client. ----

  @override
  Future<List<Meeting>> getUnfinalized() =>
      throw UnsupportedError('getUnfinalized is host-side only');

  @override
  Future<void> upsert(Meeting meeting) =>
      throw UnsupportedError('upsert is host-side only');

  @override
  Future<void> appendSegment(MeetingSegment segment) =>
      throw UnsupportedError('appendSegment is host-side only');

  @override
  Future<void> replaceSegments(
    String workspaceId,
    String meetingId,
    List<MeetingSegment> segments,
  ) => throw UnsupportedError('replaceSegments is host-side only');

  @override
  Future<void> setSegmentSpeakerLabel(
    String workspaceId,
    String segmentId,
    String label,
  ) => throw UnsupportedError('setSegmentSpeakerLabel is host-side only');

  @override
  Future<void> replaceSpeakers(
    String workspaceId,
    String meetingId,
    List<MeetingSpeakerLabel> speakers,
  ) => throw UnsupportedError('replaceSpeakers is host-side only');

  @override
  Future<void> renameSpeaker({
    required String workspaceId,
    required String id,
    required String? displayName,
  }) => throw UnsupportedError('renameSpeaker (by id) is host-side only');

  @override
  Future<void> replaceActionItems(
    String workspaceId,
    String meetingId,
    List<MeetingActionItem> items,
  ) => throw UnsupportedError('replaceActionItems is host-side only');

  @override
  Future<void> replaceDecisions(
    String workspaceId,
    String meetingId,
    List<MeetingDecision> decisions,
  ) => throw UnsupportedError('replaceDecisions is host-side only');
}
