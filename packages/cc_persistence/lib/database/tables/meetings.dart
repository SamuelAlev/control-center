import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_meetings_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_meetings_createdAt', columns: {#createdAt})
/// Drift table for recorded meetings (local meeting notes).
///
/// Workspace-scoped: every row carries a non-null [workspaceId] and all reads
/// filter on it (a meeting from one workspace must never surface in another).
class MeetingsTable extends Table {
  /// Unique meeting identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// Meeting title (user-edited, defaults to a timestamped name).
  TextColumn get title => text()();

  /// Whether the user has manually renamed the meeting. While `false`, a linked
  /// calendar event's title keeps this in sync; once `true`, the calendar never
  /// overwrites it again.
  BoolColumn get titleIsCustom =>
      boolean().withDefault(const Constant(false))();

  /// Lifecycle status: `recording`, `processing`, `done`, or `failed`.
  TextColumn get status =>
      text().withDefault(const Constant('recording'))();

  /// Detected source application (e.g. "Google Meet"), when known.
  TextColumn get sourceApp => text().nullable()();

  /// The sparse notes the user typed live during the meeting.
  TextColumn get userNotes => text().withDefault(const Constant(''))();

  /// AI-augmented notes produced from [userNotes] + the transcript.
  TextColumn get enhancedNotes => text().nullable()();

  /// The summary template's instructions captured at the moment summarization
  /// first ran, so a later "Re-run summary" reproduces the original template
  /// even if the user has since switched or edited their active template. Null
  /// for meetings recorded before this snapshot existed (they fall back to the
  /// current template).
  TextColumn get summaryInstructions => text().nullable()();

  /// Short executive summary produced by the summarizer agent.
  TextColumn get summary => text().nullable()();

  /// On-disk path to the retained raw audio, when retention is enabled.
  TextColumn get audioPath => text().nullable()();

  /// Capture mode: `remote` (mic = you, system output = the others) or
  /// `inPerson` (one shared mic; diarization splits the in-room speakers).
  TextColumn get mode => text().withDefault(const Constant('remote'))();

  /// When recording began.
  DateTimeColumn get startedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// When recording stopped.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// When the row was created.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// When the row was last updated.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
