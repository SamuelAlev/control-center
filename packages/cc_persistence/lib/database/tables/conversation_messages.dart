import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

/// Drift table definition for messages within a conversation. A message
/// belongs to exactly one conversation; `spaceId` is denormalized from it.
///
/// Addressed by its implicit `rowid` as well as by [id]: the full-text index
/// and every read cursor store the rowid, so the table keeps its text primary
/// key and is never `WITHOUT ROWID`.
///
/// The large values a message can have live beside it, so a list read or a
/// streaming flush never carries them: an agent turn's transcript is a
/// `transcripts` row owned by the message with one `transcript_segments` row
/// per segment, and the semantic-recall vector is a
/// `conversation_message_embeddings` row.
///
/// Partial indexes each hold only the rows one hot query looks for, and each
/// such query repeats the index's `WHERE` terms literally so the planner can
/// use it.
@TableIndex(
  name: 'idx_conversation_messages_messageType',
  columns: {#messageType},
)
// The space-wide history readers (`MessagingDao.getMessagesForSpace`, the
// semantic ranking pool) and the `space_id` foreign key.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_space_created '
  'ON conversation_messages (space_id, created_at)',
)
// Every conversation read: the message window, history pages, a thread's
// replies, the activity recount, and the `conversation_id` foreign key.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_conversation_created '
  'ON conversation_messages (conversation_id, created_at)',
)
// Deleting a message sets its children's parent to NULL: a lookup, not a
// scan of every message.
@TableIndex(
  name: 'idx_conversation_messages_parentMessageId',
  columns: {#parentMessageId},
)
// The sidebar activity maxima need ids, time and sender, never the
// transcript.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_live_activity '
  'ON conversation_messages (space_id, conversation_id, created_at, sender_type) '
  'WHERE reverted = 0',
)
// Covering index for `MessagingDao.conversationCharCountsSql`: the meter's
// sum never reads message bodies or transcript JSON.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_live_chars '
  'ON conversation_messages '
  '(conversation_id, message_type, content_chars, transcript_chars) '
  'WHERE reverted = 0 AND compacted = 0',
)
// Covering index for `MessagingDao.latestContextReadingSql`: one entry per
// agent turn that carries a reading, newest first.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_context_reading '
  'ON conversation_messages '
  '(conversation_id, created_at, context_tokens, context_window_tokens) '
  'WHERE reverted = 0 AND context_tokens IS NOT NULL',
)
// Open questions: `MessagingDao.watchPendingQuestions` and the activity
// recount.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_open_questions '
  'ON conversation_messages (conversation_id) '
  "WHERE message_type = 'user_question' AND answered = 0 AND reverted = 0",
)
// Covering index for `MessagingDaoHistory.conversationOutlineSql`: the whole
// conversation's outline is read from index entries alone, never from a row
// (whose content can run to overflow pages). `revision >= 0` holds for every
// row; only the outline query states it, so no other query's plan can pick
// this wide index over the narrow one meant for it.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_outline '
  'ON conversation_messages '
  '(conversation_id, created_at, space_id, id, sender_id, sender_type, '
  'message_type, content_chars, answered, steer_state, revision) '
  'WHERE reverted = 0 AND revision >= 0',
)
// Queued steering cards: `MessagingDao.queuedSteeringSql`.
@TableIndex.sql(
  'CREATE INDEX idx_conversation_messages_queued_steering '
  'ON conversation_messages (conversation_id, space_id) '
  "WHERE steer_state = 'queued'",
)
class ConversationMessagesTable extends Table {
  /// Message id.
  TextColumn get id => text()();

  /// Space id.
  TextColumn get spaceId => text().customConstraint(
    'NOT NULL REFERENCES spaces (id) ON DELETE CASCADE',
  )();

  /// Conversation (stream) id inside the space. Conversations are flat
  /// equals — each owns its own message history and agent sessions.
  TextColumn get conversationId => text().customConstraint(
    'NOT NULL REFERENCES conversations (id) ON DELETE CASCADE',
  )();

  /// Id of the agent or user that sent the message, or `system`. No foreign
  /// key: a sender is a user (in `global.db`), an agent or the server.
  TextColumn get senderId => text()();

  /// Sender type (`SenderType.wireName`).
  TextColumn get senderType => text().check(
    // ignore: recursive_getters
    senderType.isIn(SpacesStoredValues.senderType),
  )();

  /// The row's change counter: 0 on insert, one more on every `UPDATE`.
  ///
  /// Kept by the `conversation_messages_revision_au` trigger
  /// (`WorkspaceDatabase`), never written by a query: a list subscriber
  /// compares it to reuse the message it decoded last time when the row has
  /// not changed. Declared ahead of [content] so reading it never walks a
  /// long body's overflow pages.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// Content.
  TextColumn get content => text()();

  /// Unicode code points in [content]. SQLite `LENGTH(content)`.
  ///
  /// The context meter sums this on every message write. Reading `content`
  /// itself to measure it pulled every live message body off disk, including
  /// during a streaming flush that did not change those rows.
  IntColumn get contentChars => integer().withDefault(const Constant(0))();

  /// Message type (`MessageType.wire`).
  TextColumn get messageType => text()
      .check(
        // ignore: recursive_getters
        messageType.isIn(SpacesStoredValues.messageType),
      )
      .withDefault(const Constant('text'))();

  /// Whether a `user_question` has been answered or expired.
  ///
  /// Declared ahead of [metadata] on purpose: SQLite stores columns in this
  /// order, and a column behind a large metadata value is only reachable by
  /// walking the row's overflow pages.
  ///
  /// The source of truth for the domain's `metadata['answered']`: the write
  /// path lifts the key out of the JSON into this column and the read path
  /// puts it back. The open-question count and the first-answer-wins guard
  /// filter on it, and must not parse every question's JSON to do so.
  BoolColumn get answered => boolean().withDefault(const Constant(false))();

  /// A `plan` message's approval state (`pending`, `approved`, …), or null
  /// for every other row. The source of truth for `metadata['planStatus']`,
  /// lifted out of the JSON for the same reason as [answered]
  /// (`PlanMessageStatus.wire`).
  TextColumn get planStatus => text().nullable().check(
    // ignore: recursive_getters
    planStatus.isIn(SpacesStoredValues.planStatus),
  )();

  /// A `steering` card's queue state (`queued`, `injected`, …), or null for
  /// every other row. The source of truth for `metadata['steerState']`; the
  /// queue reads and the compare-and-set filter on it
  /// (`SteeringState.wire`).
  TextColumn get steerState => text().nullable().check(
    // ignore: recursive_getters
    steerState.isIn(SpacesStoredValues.steerState),
  )();

  /// Metadata: a JSON object, or null.
  ///
  /// Never holds the turn's transcript: the write path moves a
  /// `metadata['segments']` array into the message's `transcripts` row, and
  /// the reads that render a turn put it back. `segments_elided` and
  /// `segment_count`, which a list read adds, are not stored either.
  ///
  /// Checked because the message queries read it with `json_extract`, which
  /// throws on malformed JSON: one bad row would break every such query.
  ///
  /// Stored under the SQL name `list_metadata`: that column already held each
  /// message's metadata without its transcript, so a converged file keeps it
  /// while the old `metadata` column, which held the transcript as well, is
  /// dropped.
  TextColumn get metadata => text()
      .named('list_metadata')
      .nullable()
      .check(
        // ignore: recursive_getters
        isJsonObject(metadata),
      )();

  /// `metadata['transcriptChars']` as an integer, or 0 when absent.
  ///
  /// Agent turns are measured by this, not by [content]. Keeping it beside
  /// the row means the meter does not parse each turn's transcript JSON on
  /// every flush.
  IntColumn get transcriptChars => integer().withDefault(const Constant(0))();

  /// `metadata['context']['tokens']`: how full the model's window was on the
  /// turn's latest call, as the provider reported it. Null on everything that
  /// is not an agent turn, and on turns whose runner never reported one.
  ///
  /// A column for the same reason as [transcriptChars]: the meter re-reads it
  /// on every streaming flush, which must not parse the turn's metadata JSON.
  IntColumn get contextTokens => integer().nullable()();

  /// `metadata['context']['window']`: the window [contextTokens] was measured
  /// against, when the runner knew it.
  IntColumn get contextWindowTokens => integer().nullable()();

  /// The message this one continues from, or null for the first in a branch.
  ///
  /// **This is what makes the conversation a TREE rather than a list, and it is
  /// the whole session-tree feature in one column.** With a parent on every
  /// message, "branch from here" is a pointer move rather than a delete: the
  /// original path is still reachable, so editing a prompt and re-running does
  /// not destroy the answer you were comparing against. Without it, every form
  /// of going back — rewind, revert, retry — has to hide or delete messages,
  /// and hiding is a lie the next reader cannot see through.
  ///
  /// Nullable, `ON DELETE SET NULL`: a message whose parent was hard deleted
  /// is a root, not an error, and deleting one message neither fails on the
  /// ones that came after it nor takes them with it.
  TextColumn get parentMessageId => text().nullable().customConstraint(
    'REFERENCES conversation_messages(id) ON DELETE SET NULL',
  )();

  /// Compacted.
  BoolColumn get compacted => boolean().withDefault(const Constant(false))();

  /// Whether this message has been reverted (rolled back) and is therefore
  /// hidden from the live conversation. Reverted messages are kept (not
  /// deleted) so an `unrevert` can restore them.
  BoolColumn get reverted => boolean().withDefault(const Constant(false))();

  /// When this message was reverted, in epoch milliseconds. All messages
  /// reverted in one operation share a timestamp, so `unrevert` can restore the
  /// most-recent batch. Null when not reverted.
  IntColumn get revertedAt => integer().nullable()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'conversation_messages';

  @override
  Set<Column> get primaryKey => {id};
}
