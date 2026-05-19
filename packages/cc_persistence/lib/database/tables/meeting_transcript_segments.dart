import 'package:cc_persistence/database/tables/meetings.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_meeting_segments_meetingId', columns: {#meetingId})
@TableIndex(name: 'idx_meeting_segments_workspaceId', columns: {#workspaceId})
/// Drift table for live transcript segments within a meeting.
///
/// Each row is one transcribed window tagged with a [speaker] (`me` from the
/// microphone, `them` from the system-output capture). Workspace-scoped via
/// [workspaceId] in addition to the [meetingId] foreign key.
class MeetingTranscriptSegmentsTable extends Table {
  /// Unique segment identifier.
  TextColumn get id => text()();

  /// Parent meeting.
  TextColumn get meetingId =>
      text().references(MeetingsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace (denormalized for workspace-scoped reads).
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// Speaker channel: `me` (microphone) or `them` (system audio).
  TextColumn get speaker => text()();

  /// Diarized speaker label (e.g. `Person 1`), assigned by the post-recording
  /// diarization pipeline step. Null until/unless diarization runs. The coarse
  /// [speaker] channel is always present; this refines the `them` (or in-person
  /// mic) side into individual speakers.
  TextColumn get speakerLabel => text().nullable()();

  /// A per-segment speaker-name override: the name to show for THIS line only,
  /// independent of the diarized speaker's group display name (the
  /// `meeting_speakers_table.display_name`). Set when the user renames a single
  /// transcript block instead of the whole speaker; null means the line inherits
  /// the group's display name (or its `Person N` label).
  ///
  /// Lost on a "Re-run summary" (the diarization step rebuilds segments via
  /// `replaceSegments`) — a deliberate, documented limitation, since re-running
  /// regenerates the transcript from scratch. The group's display name and
  /// voice-profile enrollment do survive (carried forward by `(channel, label)`).
  TextColumn get speakerNameOverride => text().nullable()();

  /// Transcribed text for this window.
  TextColumn get content => text()();

  /// Window start offset from the meeting start, in milliseconds.
  IntColumn get startMs => integer()();

  /// Window end offset from the meeting start, in milliseconds.
  IntColumn get endMs => integer()();

  /// When the segment was recorded.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
