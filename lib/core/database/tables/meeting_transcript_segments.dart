import 'package:control_center/core/database/tables/meetings.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
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
