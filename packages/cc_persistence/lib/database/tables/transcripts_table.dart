import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:drift/drift.dart';

/// One agent activity timeline: the facts about it, never its segments (those
/// are rows of `TranscriptSegmentsTable`, one per segment).
///
/// A transcript has exactly ONE owner, and deleting the owner deletes it with
/// its segments:
/// * a space turn's transcript belongs to its message ([messageId]). Its run
///   is not an owner: run logs are swept long before a chat is, and the chat
///   must keep showing the turn's tool calls;
/// * a subagent run, which has no message, owns its own ([runId]).
///
/// [id] is the transcript's own key, so neither owner's id has to double as
/// the other's.
///
/// The retention sweep (`RunTranscriptDao.pruneCompletedBefore`) removes old
/// finished run transcripts only; `idx_transcripts_run_sweep` holds exactly
/// the rows it looks at.
@TableIndex(name: 'idx_transcripts_run_id', columns: {#runId}, unique: true)
@TableIndex(
  name: 'idx_transcripts_message_id',
  columns: {#messageId},
  unique: true,
)
@TableIndex.sql(
  'CREATE INDEX idx_transcripts_run_sweep ON transcripts (updated_at) '
  'WHERE run_id IS NOT NULL AND complete = 1',
)
class TranscriptsTable extends Table {
  /// The transcript's own key, referenced by its segment rows.
  IntColumn get id => integer().autoIncrement()();

  /// The subagent run that owns this transcript, or null when a message owns
  /// it. `ON DELETE CASCADE`: the transcript is part of the run.
  TextColumn get runId => text().nullable().references(
    AgentRunLogsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The space-turn message that owns this transcript, or null when a run
  /// owns it. `ON DELETE CASCADE`: the transcript is part of the message, and
  /// deleting the message, its conversation or its space takes it along.
  TextColumn get messageId => text().nullable().references(
    ConversationMessagesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Number of segments, so a list can say how many a turn holds without
  /// reading them.
  IntColumn get segmentCount => integer().withDefault(const Constant(0))();

  /// Running character count of the transcript, for context-window estimates.
  IntColumn get transcriptChars => integer().withDefault(const Constant(0))();

  /// How the turn ended (a `TurnOutcome` storage string), or null while it is
  /// still streaming.
  TextColumn get outcome =>
      text().nullable()
      // ignore: recursive_getters
      .check(outcome.isIn(AgentsStoredValues.turnOutcome))();

  /// Whether the recording was finalized. False on a row left behind by a
  /// crash mid-run, which is how a reader knows to present still-`running`
  /// tool segments as interrupted rather than live.
  BoolColumn get complete => boolean().withDefault(const Constant(false))();

  /// When the recording started.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the transcript was last flushed.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'transcripts';

  @override
  List<String> get customConstraints => [
    'CHECK ((run_id IS NULL) <> (message_id IS NULL))',
  ];
}
