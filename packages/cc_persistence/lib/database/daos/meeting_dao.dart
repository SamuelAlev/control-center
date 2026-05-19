import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/meeting_action_items.dart';
import 'package:cc_persistence/database/tables/meeting_decisions.dart';
import 'package:cc_persistence/database/tables/meeting_speakers.dart';
import 'package:cc_persistence/database/tables/meeting_transcript_segments.dart';
import 'package:cc_persistence/database/tables/meetings.dart';
import 'package:drift/drift.dart';

part 'meeting_dao.g.dart';

@DriftAccessor(
  tables: [
    MeetingsTable,
    MeetingTranscriptSegmentsTable,
    MeetingActionItemsTable,
    MeetingDecisionsTable,
    MeetingSpeakersTable,
  ],
)
/// Data access for meetings and their transcript segments.
///
/// Every query is scoped to a `workspaceId` (a meeting from one workspace must
/// never surface in another); ids are global UUIDs, so the workspace clause —
/// not id uniqueness — is the isolation boundary.
class MeetingDao extends DatabaseAccessor<AppDatabase> with _$MeetingDaoMixin {
  /// Creates a [MeetingDao].
  MeetingDao(super.attachedDatabase);

  /// Watches meetings in a workspace, newest first.
  Stream<List<MeetingsTableData>> watchByWorkspace(String workspaceId) =>
      (select(meetingsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Reads meetings in a workspace, newest first.
  Future<List<MeetingsTableData>> getByWorkspace(String workspaceId) =>
      (select(meetingsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Looks up a meeting by id, scoped to [workspaceId]. A meeting owned by
  /// another workspace is simply not found.
  Future<MeetingsTableData?> getById(String workspaceId, String id) =>
      (select(meetingsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .getSingleOrNull();

  /// CROSS-WORKSPACE BY DESIGN: every meeting not yet in a terminal state
  /// (`recording` or `processing`), across all workspaces. Used only by the
  /// startup reconciler (MeetingSummaryReconciler) to un-stick meetings stranded
  /// by a crash mid-recording (`recording`) or a summary run that never started
  /// / never finalized (`processing`) — a global sweep, like the pipeline
  /// orphan-run reaper. Do NOT use this for workspace-scoped reads; use
  /// [getByWorkspace]/[getById] (which filter on `workspaceId`) instead.
  Future<List<MeetingsTableData>> getUnfinalized() => (select(meetingsTable)
        ..where((t) => t.status.isIn(['recording', 'processing'])))
      .get();

  /// Inserts or updates a meeting.
  Future<void> upsertMeeting(MeetingsTableCompanion entry) =>
      into(meetingsTable).insertOnConflictUpdate(entry);

  /// Updates only a meeting's [title] (and bumps `updatedAt`), scoped to
  /// [workspaceId]. Leaves `titleIsCustom` and the recorder-owned fields
  /// untouched; a foreign/missing row matches nothing (no-op).
  Future<void> updateMeetingTitle(
    String workspaceId,
    String id,
    String title,
  ) =>
      (update(meetingsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        MeetingsTableCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Updates only a meeting's user [notes] (and bumps `updatedAt`), scoped to
  /// [workspaceId]. Leaves the recorder-owned fields untouched; a foreign/
  /// missing row matches nothing (no-op).
  Future<void> updateMeetingNotes(
    String workspaceId,
    String id,
    String notes,
  ) =>
      (update(meetingsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        MeetingsTableCompanion(
          userNotes: Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes a meeting by id, scoped to [workspaceId] (cascades to segments).
  Future<void> deleteMeeting(String workspaceId, String id) =>
      (delete(meetingsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();

  /// Watches transcript segments for a meeting, oldest first.
  Stream<List<MeetingTranscriptSegmentsTableData>> watchSegments(
    String workspaceId,
    String meetingId,
  ) =>
      (select(meetingTranscriptSegmentsTable)
            ..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
          .watch();

  /// Reads transcript segments for a meeting, oldest first.
  Future<List<MeetingTranscriptSegmentsTableData>> getSegments(
    String workspaceId,
    String meetingId,
  ) =>
      (select(meetingTranscriptSegmentsTable)
            ..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
          .get();

  /// Appends a single transcript segment.
  Future<void> insertSegment(MeetingTranscriptSegmentsTableCompanion entry) =>
      into(meetingTranscriptSegmentsTable).insertOnConflictUpdate(entry);

  /// Replaces a meeting's transcript segments wholesale (delete + insert) in one
  /// transaction. Used by `meeting.updateTranscript` to persist the diarized,
  /// re-separated transcript (windows straddling a speaker change are split,
  /// consecutive same-speaker fragments merged into turns). Idempotent: a re-run
  /// regenerates the rows from the current segments + diarization spans.
  Future<void> replaceSegments(
    String workspaceId,
    String meetingId,
    List<MeetingTranscriptSegmentsTableCompanion> segments,
  ) =>
      transaction(() async {
        await (delete(meetingTranscriptSegmentsTable)..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            ))
            .go();
        if (segments.isNotEmpty) {
          await batch(
            (b) => b.insertAll(meetingTranscriptSegmentsTable, segments),
          );
        }
      });

  // --- Action items ---------------------------------------------------------

  /// Watches a meeting's action items, ordered by the agent's `sortOrder`.
  Stream<List<MeetingActionItemsTableData>> watchActionItems(
    String workspaceId,
    String meetingId,
  ) =>
      (select(meetingActionItemsTable)
            ..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Watches per-meeting action-item counts (total + done) for a workspace.
  Stream<Map<String, ({int total, int done})>> watchActionItemStats(
    String workspaceId,
  ) {
    final total = meetingActionItemsTable.id.count();
    final done = meetingActionItemsTable.id
        .count(filter: meetingActionItemsTable.done.equals(true));
    final query = selectOnly(meetingActionItemsTable)
      ..addColumns([meetingActionItemsTable.meetingId, total, done])
      ..where(meetingActionItemsTable.workspaceId.equals(workspaceId))
      ..groupBy([meetingActionItemsTable.meetingId]);
    return query.watch().map((rows) {
      final map = <String, ({int total, int done})>{};
      for (final row in rows) {
        final meetingId = row.read(meetingActionItemsTable.meetingId);
        if (meetingId == null) {
          continue;
        }
        map[meetingId] = (total: row.read(total) ?? 0, done: row.read(done) ?? 0);
      }
      return map;
    });
  }

  /// Replaces a meeting's AGENT-extracted action items, but carries the user's
  /// triage state forward and preserves the user's own rows:
  ///
  ///  * Rows the user authored or edited (`isManual`) are left untouched — a
  ///    "Re-run summary" never wipes a manual item or a user-edited one.
  ///  * Only the agent rows (`isManual = false`) are regenerated. For each, the
  ///    persisted `done` flag + `ticketId` link are carried forward from the
  ///    prior agent row with the same `content` (matched by content because ids
  ///    are fresh on every run).
  Future<void> replaceActionItems(
    String workspaceId,
    String meetingId,
    List<MeetingActionItemsTableCompanion> items,
  ) =>
      transaction(() async {
        final priorAgent = await (select(meetingActionItemsTable)..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId) &
                  t.isManual.equals(false),
            ))
            .get();
        final byContent = <String, MeetingActionItemsTableData>{
          for (final row in priorAgent) row.content: row,
        };
        // Delete only the agent rows; manual rows survive re-summarization.
        await (delete(meetingActionItemsTable)..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId) &
                  t.isManual.equals(false),
            ))
            .go();
        if (items.isEmpty) {
          return;
        }
        final merged = <MeetingActionItemsTableCompanion>[
          for (final c in items)
            if (c.content.present && byContent[c.content.value] != null)
              c.copyWith(
                done: Value(byContent[c.content.value]!.done),
                ticketId: byContent[c.content.value]!.ticketId != null
                    ? Value(byContent[c.content.value]!.ticketId)
                    : c.ticketId,
              )
            else
              c,
        ];
        await batch((b) => b.insertAll(meetingActionItemsTable, merged));
      });

  /// Inserts a single action item (used for user-authored rows).
  Future<void> insertActionItem(MeetingActionItemsTableCompanion entry) =>
      into(meetingActionItemsTable).insert(entry);

  /// Edits an action item's content + owner, scoped to [workspaceId]. Marks the
  /// row `isManual` so a later [replaceActionItems] re-run won't overwrite the
  /// user's edit.
  Future<void> updateActionItemContent(
    String workspaceId,
    String id, {
    required String content,
    String? owner,
  }) =>
      (update(meetingActionItemsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        MeetingActionItemsTableCompanion(
          content: Value(content),
          owner: Value(owner),
          isManual: const Value(true),
        ),
      );

  /// Deletes a single action item, scoped to [workspaceId].
  Future<void> deleteActionItem(String workspaceId, String id) =>
      (delete(meetingActionItemsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();

  /// Sets the done flag on one action item, scoped to [workspaceId].
  Future<void> setActionItemDone(
    String workspaceId,
    String id, {
    required bool done,
  }) =>
      (update(meetingActionItemsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(MeetingActionItemsTableCompanion(done: Value(done)));

  /// Links a ticket to one action item, scoped to [workspaceId].
  Future<void> setActionItemTicket(
    String workspaceId,
    String id,
    String ticketId,
  ) =>
      (update(meetingActionItemsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(MeetingActionItemsTableCompanion(ticketId: Value(ticketId)));

  // --- Decisions ------------------------------------------------------------

  /// Watches a meeting's decisions, ordered by the agent's `sortOrder`.
  Stream<List<MeetingDecisionsTableData>> watchDecisions(
    String workspaceId,
    String meetingId,
  ) =>
      (select(meetingDecisionsTable)
            ..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Watches per-meeting decision counts for a workspace.
  Stream<Map<String, int>> watchDecisionCounts(String workspaceId) {
    final count = meetingDecisionsTable.id.count();
    final query = selectOnly(meetingDecisionsTable)
      ..addColumns([meetingDecisionsTable.meetingId, count])
      ..where(meetingDecisionsTable.workspaceId.equals(workspaceId))
      ..groupBy([meetingDecisionsTable.meetingId]);
    return query.watch().map((rows) {
      final map = <String, int>{};
      for (final row in rows) {
        final meetingId = row.read(meetingDecisionsTable.meetingId);
        if (meetingId == null) {
          continue;
        }
        map[meetingId] = row.read(count) ?? 0;
      }
      return map;
    });
  }

  /// Replaces a meeting's AGENT-extracted decisions (idempotent re-run). Rows
  /// the user authored or edited (`isManual`) are preserved — only agent rows
  /// (`isManual = false`) are deleted and regenerated.
  Future<void> replaceDecisions(
    String workspaceId,
    String meetingId,
    List<MeetingDecisionsTableCompanion> decisions,
  ) =>
      transaction(() async {
        await (delete(meetingDecisionsTable)..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId) &
                  t.isManual.equals(false),
            ))
            .go();
        if (decisions.isNotEmpty) {
          await batch((b) => b.insertAll(meetingDecisionsTable, decisions));
        }
      });

  /// Inserts a single decision (used for user-authored rows).
  Future<void> insertDecision(MeetingDecisionsTableCompanion entry) =>
      into(meetingDecisionsTable).insert(entry);

  /// Edits a decision's content, scoped to [workspaceId]. Marks the row
  /// `isManual` so a later [replaceDecisions] re-run won't overwrite the edit.
  Future<void> updateDecisionContent(
    String workspaceId,
    String id, {
    required String content,
  }) =>
      (update(meetingDecisionsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        MeetingDecisionsTableCompanion(
          content: Value(content),
          isManual: const Value(true),
        ),
      );

  /// Deletes a single decision, scoped to [workspaceId].
  Future<void> deleteDecision(String workspaceId, String id) =>
      (delete(meetingDecisionsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();

  // --- Diarized speakers -----------------------------------------------------

  /// Sets the diarized [label] (e.g. `Person 1`) on one transcript segment,
  /// scoped to [workspaceId].
  Future<void> setSegmentSpeakerLabel(
    String workspaceId,
    String segmentId,
    String label,
  ) =>
      (update(meetingTranscriptSegmentsTable)..where(
            (t) => t.id.equals(segmentId) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        MeetingTranscriptSegmentsTableCompanion(speakerLabel: Value(label)),
      );

  /// Sets (or clears, when null) the per-segment [name] override on one
  /// transcript segment, scoped to [workspaceId] — used to rename a single
  /// transcript block without touching the rest of the speaker's lines.
  Future<void> setSegmentSpeakerNameOverride(
    String workspaceId,
    String segmentId,
    String? name,
  ) =>
      (update(meetingTranscriptSegmentsTable)..where(
            (t) => t.id.equals(segmentId) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        MeetingTranscriptSegmentsTableCompanion(
          speakerNameOverride: Value(name),
        ),
      );

  /// Clears every per-segment name override for the speaker identified by its
  /// [channel]+[label] within a meeting, scoped to [workspaceId]. Run when the
  /// user renames the whole speaker ("apply to all blocks"), so per-block
  /// overrides stop shadowing the new group name.
  Future<void> clearSpeakerNameOverridesForLabel({
    required String workspaceId,
    required String meetingId,
    required String channel,
    required String label,
  }) =>
      (update(meetingTranscriptSegmentsTable)..where(
            (t) =>
                t.meetingId.equals(meetingId) &
                t.workspaceId.equals(workspaceId) &
                t.speaker.equals(channel) &
                t.speakerLabel.equals(label),
          ))
          .write(
        const MeetingTranscriptSegmentsTableCompanion(
          speakerNameOverride: Value(null),
        ),
      );

  /// Watches the diarized speakers for a meeting, ordered by label.
  Stream<List<MeetingSpeakersTableData>> watchSpeakers(
    String workspaceId,
    String meetingId,
  ) =>
      (select(meetingSpeakersTable)
            ..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.label)]))
          .watch();

  /// Reads the diarized speakers for a meeting, ordered by label.
  Future<List<MeetingSpeakersTableData>> getSpeakers(
    String workspaceId,
    String meetingId,
  ) =>
      (select(meetingSpeakersTable)
            ..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.label)]))
          .get();

  /// Replaces a meeting's diarized speakers wholesale (idempotent re-run),
  /// carrying forward — for a speaker whose `(channel, label)` matches a prior
  /// row — any user-assigned [MeetingSpeakersTable.displayName] and its
  /// [MeetingSpeakersTable.enrolledProfileName] voice-profile provenance, so a
  /// re-diarization keeps both the name and the un-enrollment bookkeeping.
  Future<void> replaceSpeakers(
    String workspaceId,
    String meetingId,
    List<MeetingSpeakersTableCompanion> speakers,
  ) =>
      transaction(() async {
        final prior = await (select(meetingSpeakersTable)..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            ))
            .get();
        final byKey = <String, MeetingSpeakersTableData>{
          for (final row in prior) '${row.channel}::${row.label}': row,
        };
        await (delete(meetingSpeakersTable)..where(
              (t) =>
                  t.meetingId.equals(meetingId) &
                  t.workspaceId.equals(workspaceId),
            ))
            .go();
        if (speakers.isEmpty) {
          return;
        }
        final merged = <MeetingSpeakersTableCompanion>[
          for (final c in speakers)
            if (c.channel.present && c.label.present)
              () {
                final priorRow = byKey['${c.channel.value}::${c.label.value}'];
                if (priorRow == null) {
                  return c;
                }
                return c.copyWith(
                  displayName: priorRow.displayName != null
                      ? Value(priorRow.displayName)
                      : c.displayName,
                  enrolledProfileName: priorRow.enrolledProfileName != null
                      ? Value(priorRow.enrolledProfileName)
                      : c.enrolledProfileName,
                );
              }()
            else
              c,
        ];
        await batch((b) => b.insertAll(meetingSpeakersTable, merged));
      });

  /// Renames one diarized speaker, scoped to [workspaceId].
  Future<void> setSpeakerDisplayName(
    String workspaceId,
    String id,
    String? displayName,
  ) =>
      (update(meetingSpeakersTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        MeetingSpeakersTableCompanion(displayName: Value(displayName)),
      );

  /// Sets [displayName] for the speaker identified by its [channel]+[label]
  /// within a meeting, inserting a speaker row (with [newId]/[createdAt], no
  /// embedding) when none exists yet. `(meeting, channel, label)` is a speaker's
  /// stable identity, so this is the by-label counterpart to
  /// [setSpeakerDisplayName]'s by-id rename. The transcript rename UI uses it so
  /// a `Person N` that diarization labeled on a segment but never (fully)
  /// persisted a speaker row for is still renameable. Workspace-scoped: the
  /// lookup and the inserted row both carry [workspaceId].
  Future<void> upsertSpeakerDisplayName({
    required String workspaceId,
    required String meetingId,
    required String channel,
    required String label,
    required String? displayName,
    required String newId,
    required DateTime createdAt,
  }) =>
      transaction(() async {
        final existing = await (select(meetingSpeakersTable)
              ..where(
                (t) =>
                    t.meetingId.equals(meetingId) &
                    t.workspaceId.equals(workspaceId) &
                    t.channel.equals(channel) &
                    t.label.equals(label),
              ))
            .getSingleOrNull();
        if (existing != null) {
          await (update(meetingSpeakersTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(
            MeetingSpeakersTableCompanion(displayName: Value(displayName)),
          );
          return;
        }
        await into(meetingSpeakersTable).insert(
          MeetingSpeakersTableCompanion.insert(
            id: newId,
            meetingId: meetingId,
            workspaceId: workspaceId,
            channel: channel,
            label: label,
            displayName: Value(displayName),
            createdAt: Value(createdAt),
          ),
        );
      });

  /// Records (or clears, when null) the voice [profileName] this speaker's
  /// voiceprint was enrolled into, for the speaker identified by its
  /// [channel]+[label] within a meeting, scoped to [workspaceId]. A no-op when
  /// the speaker row doesn't exist yet (the rename path always upserts the row
  /// first). Provenance for un-enrolling the voiceprint on a later rename.
  Future<void> setSpeakerEnrolledProfileByLabel({
    required String workspaceId,
    required String meetingId,
    required String channel,
    required String label,
    required String? profileName,
  }) =>
      (update(meetingSpeakersTable)..where(
            (t) =>
                t.meetingId.equals(meetingId) &
                t.workspaceId.equals(workspaceId) &
                t.channel.equals(channel) &
                t.label.equals(label),
          ))
          .write(
        MeetingSpeakersTableCompanion(
          enrolledProfileName: Value(profileName),
        ),
      );
}
