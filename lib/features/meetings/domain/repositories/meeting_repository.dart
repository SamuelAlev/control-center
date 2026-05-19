import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_decision.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_speaker_label.dart';

/// Repository for [Meeting], its transcript [MeetingSegment]s, and the
/// structured [MeetingActionItem]s / [MeetingDecision]s produced by the
/// `meeting_summary` pipeline.
///
/// Every method is scoped to a `workspaceId`; a meeting from one workspace must
/// never surface in another.
abstract class MeetingRepository {
  /// Watches all meetings in a workspace, newest first.
  Stream<List<Meeting>> watchByWorkspace(String workspaceId);

  /// Fetches all meetings in a workspace, newest first.
  Future<List<Meeting>> getByWorkspace(String workspaceId);

  /// CROSS-WORKSPACE BY DESIGN: all meetings not yet finalized (`recording` or
  /// `processing`), across every workspace. For the startup reconciler only
  /// (un-sticking meetings stranded by a crash mid-recording, or whose summary
  /// run never started/finalized) — not a workspace-scoped read.
  Future<List<Meeting>> getUnfinalized();

  /// Looks up a meeting by id within [workspaceId]. A meeting owned by another
  /// workspace is not found.
  Future<Meeting?> getById(String workspaceId, String id);

  /// Inserts or updates a meeting.
  Future<void> upsert(Meeting meeting);

  /// Deletes a meeting by id within [workspaceId] (cascades to segments).
  Future<void> delete(String workspaceId, String id);

  /// Watches transcript segments for a meeting, oldest first.
  Stream<List<MeetingSegment>> watchSegments(
    String workspaceId,
    String meetingId,
  );

  /// Fetches transcript segments for a meeting, oldest first.
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  );

  /// Appends a single transcript segment.
  Future<void> appendSegment(MeetingSegment segment);

  /// Replaces a meeting's transcript segments wholesale (delete + insert), so
  /// the diarized, re-separated transcript produced by `meeting.updateTranscript`
  /// fully supersedes the live-captured windows. Idempotent re-run.
  Future<void> replaceSegments(
    String workspaceId,
    String meetingId,
    List<MeetingSegment> segments,
  );

  // --- Diarized speakers ----------------------------------------------------

  /// Sets the diarized [label] on one transcript segment, scoped to
  /// [workspaceId].
  Future<void> setSegmentSpeakerLabel(
    String workspaceId,
    String segmentId,
    String label,
  );

  /// Watches the diarized speakers for a meeting.
  Stream<List<MeetingSpeakerLabel>> watchSpeakers(
    String workspaceId,
    String meetingId,
  );

  /// Fetches the diarized speakers for a meeting.
  Future<List<MeetingSpeakerLabel>> getSpeakers(
    String workspaceId,
    String meetingId,
  );

  /// Replaces a meeting's diarized speakers wholesale, carrying forward any
  /// user-assigned display name for a matching `(channel, label)` (idempotent
  /// re-diarization).
  Future<void> replaceSpeakers(
    String workspaceId,
    String meetingId,
    List<MeetingSpeakerLabel> speakers,
  );

  /// Renames one diarized speaker, scoped to [workspaceId].
  Future<void> renameSpeaker({
    required String workspaceId,
    required String id,
    required String? displayName,
  });

  // --- Action items & decisions (structured summary output) -----------------

  /// Watches a meeting's action items, in the agent's order.
  Stream<List<MeetingActionItem>> watchActionItems(
    String workspaceId,
    String meetingId,
  );

  /// Watches a meeting's decisions, in the agent's order.
  Stream<List<MeetingDecision>> watchDecisions(
    String workspaceId,
    String meetingId,
  );

  /// Watches per-meeting action-item counts (total + done) across [workspaceId],
  /// keyed by meeting id. Powers the list view's signal pills + stats strip.
  Stream<Map<String, MeetingActionItemStats>> watchActionItemStats(
    String workspaceId,
  );

  /// Watches per-meeting decision counts across [workspaceId], keyed by meeting
  /// id.
  Stream<Map<String, int>> watchDecisionCounts(String workspaceId);

  /// Replaces a meeting's agent-extracted action items so a re-run is
  /// idempotent. Rows the user authored or edited (`isManual`) are preserved —
  /// only agent rows are regenerated.
  Future<void> replaceActionItems(
    String workspaceId,
    String meetingId,
    List<MeetingActionItem> items,
  );

  /// Replaces a meeting's agent-extracted decisions. Like
  /// [replaceActionItems], rows the user authored or edited (`isManual`) are
  /// preserved.
  Future<void> replaceDecisions(
    String workspaceId,
    String meetingId,
    List<MeetingDecision> decisions,
  );

  /// Inserts a single user-authored action item (`isManual`).
  Future<void> addActionItem(MeetingActionItem item);

  /// Edits an action item's [content] and [owner], scoped to [workspaceId], and
  /// marks it `isManual` so a later "Re-run summary" won't overwrite the edit.
  Future<void> updateActionItem({
    required String workspaceId,
    required String id,
    required String content,
    String? owner,
  });

  /// Deletes a single action item, scoped to [workspaceId].
  Future<void> deleteActionItem(String workspaceId, String id);

  /// Inserts a single user-authored decision (`isManual`).
  Future<void> addDecision(MeetingDecision decision);

  /// Edits a decision's [content], scoped to [workspaceId], and marks it
  /// `isManual` so a later "Re-run summary" won't overwrite the edit.
  Future<void> updateDecision({
    required String workspaceId,
    required String id,
    required String content,
  });

  /// Deletes a single decision, scoped to [workspaceId].
  Future<void> deleteDecision(String workspaceId, String id);

  /// Sets the persisted done flag on a single action item, scoped to
  /// [workspaceId].
  Future<void> setActionItemDone({
    required String workspaceId,
    required String id,
    required bool done,
  });

  /// Links a created ticket to an action item, scoped to [workspaceId].
  Future<void> setActionItemTicket({
    required String workspaceId,
    required String id,
    required String ticketId,
  });
}
