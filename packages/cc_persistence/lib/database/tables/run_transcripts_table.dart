import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:drift/drift.dart';

/// Drift table for one agent run's own activity timeline.
///
/// A run has at most ONE transcript — [runId] is the primary key, so a mid-run
/// flush replaces the prior snapshot. The transcript belongs to exactly one
/// workspace ([workspaceId], the isolation boundary); every read filters by
/// both. Deleting the run log or the workspace cascades the transcript.
///
/// Deliberately its own table rather than a column on `agent_run_logs`:
/// `agent_run_log.watchAll` / `watchRecent` / `watchByConversation`
/// re-materialize and re-encode every row on every write, so a transcript
/// column would put megabytes into each of those emissions — the payload
/// regression `messageToWireLite` exists to prevent. Keeping it separate leaves
/// the run-log list ops byte-identical.
///
/// Primary consumer is the subagent-activity tab, which reads a finished run's
/// timeline here and a live one from the in-memory `ActiveStreamRegistry`.
@TableIndex(name: 'idx_run_transcripts_workspaceId', columns: {#workspaceId})
class RunTranscriptsTable extends Table {
  /// The run this transcript belongs to — one transcript per run.
  TextColumn get runId =>
      text().references(AgentRunLogsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The ordered transcript, as the same encoded `TranscriptSegment` JSON array
  /// channel messages carry in `metadata['segments']`.
  TextColumn get segmentsJson => text().withDefault(const Constant('[]'))();

  /// Number of segments in [segmentsJson], so a caller can tell an empty
  /// transcript from an unrecorded one without decoding.
  IntColumn get segmentCount => integer().withDefault(const Constant(0))();

  /// Running character count of the transcript, for context-window estimates.
  IntColumn get transcriptChars => integer().withDefault(const Constant(0))();

  /// How the run's turn ended (`completed` / `failed` / `interrupted`), or null
  /// while it is still streaming.
  TextColumn get outcome => text().nullable()();

  /// Whether the recording was finalized. False on a row left behind by a crash
  /// mid-run, which is how a reader knows to present still-`running` tool
  /// segments as interrupted rather than live.
  BoolColumn get complete => boolean().withDefault(const Constant(false))();

  /// When the recording started.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the transcript was last flushed.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'run_transcripts';

  @override
  Set<Column> get primaryKey => {runId};
}
