import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart' show MessageType;
import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart' show Mode;
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart'
    show turnOutcomeFromString;
import 'package:cc_domain/features/messaging/domain/value_objects/message_lifecycle_states.dart';
import 'package:cc_persistence/database/tables/conversation_activity.dart';
import 'package:cc_persistence/database/tables/conversation_message_embeddings_table.dart';
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/space_participants.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'messaging_dao.g.dart';
part 'messaging_dao_activity.dart';
part 'messaging_dao_branches.dart';
part 'messaging_dao_embeddings.dart';
part 'messaging_dao_spaces.dart';
part 'messaging_dao_stamps.dart';

/// Implicit SQLite `rowid` — a monotonic integer assigned in insertion order
/// for this (normal, not `WITHOUT ROWID`) table. Used as a stable tie-breaker
/// for message ordering: `created_at` is stored at **second** resolution (Drift
/// `currentDateAndTime` truncates to whole seconds), so messages inserted in
/// the same second — e.g. a user message and its immediately-dispatched agent
/// reply — share an identical `created_at` and `ORDER BY created_at` alone
/// returns them in an unspecified order. That surfaced as agent replies
/// rendering *above* the user message that triggered them. The `id` column is a
/// random UUID and is *not* a valid tie-breaker.
// Drift builders in this library spell the tie-break in SQL text now.
// ignore: unused_element
const _rowid = CustomExpression<int>('rowid');

/// Data access object for [SpacesTable], [SpaceParticipantsTable],
/// [ConversationMessagesTable] and the message embeddings.
///
/// A turn's transcript is written and read through `RunTranscriptDao`, in
/// the same transaction as the message row it belongs to.
@DriftAccessor(
  tables: [
    SpacesTable,
    ConversationsTable,
    SpaceParticipantsTable,
    ConversationMessagesTable,
    ConversationActivityTable,
    ConversationMessageEmbeddingsTable,
  ],
)
class MessagingDao extends DatabaseAccessor<WorkspaceDatabase>
    with
        _$MessagingDaoMixin,
        _ConversationActivity,
        _MessageBranches,
        _MessageEmbeddings,
        _SpaceRows {
  /// Creates a [MessagingDao] for the given database.
  MessagingDao(super.attachedDatabase);

  /// Watches this workspace's spaces, most recently updated first.
  ///
  /// Unfiltered and safe: this DAO hangs off one workspace's database, so
  /// "every space in the file" is "every space in the workspace". The
  /// all-workspaces dashboard view merges one of these streams per workspace
  /// through `CrossWorkspaceQueries.mergeStreams` — it does not filter a global
  /// stream in memory, which is how other workspaces' spaces leaked before.
  Stream<List<SpacesTableData>> watchSpaces() =>
      (select(spacesTable)..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch();

  /// Watches participants for a space.
  Stream<List<SpaceParticipantsTableData>> watchParticipants(String spaceId) =>
      (select(spaceParticipantsTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.joinedAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  /// Watches spaces for a specific workspace ordered by most recently updated.
  Stream<List<SpacesTableData>> watchSpacesByWorkspace(String workspaceId) =>
      (select(spacesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.updatedAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  /// What a list read selects: every message column (`m.*`) and the two
  /// facts [ListedMessageRow] reports about the message's transcript, read
  /// off its `transcripts` row through `idx_transcripts_message_id`. No
  /// segment is read.
  ///
  /// The statements name only `conversation_messages` as what they read: a
  /// transcript's facts change on their own only while a subagent run
  /// records, and a space turn's change in the same transaction as its
  /// message row, which re-runs the list anyway. A streaming flush that adds
  /// a segment does not move what the list shows: the count appears once the
  /// turn finished.
  static const listedMessageColumns =
      'm.*, t.id IS NOT NULL AS has_transcript, '
      'CASE WHEN t.complete THEN t.segment_count END AS finished_segment_count';

  /// The `FROM` of a list read: messages as `m`, with their transcript facts.
  static const listedMessagesFrom =
      'FROM conversation_messages m '
      'LEFT JOIN transcripts t ON t.message_id = m.id ';

  ListedMessageRow _listed(QueryRow row) => (
    data: conversationMessagesTable.map(row.data),
    hasTranscript: row.read<bool>('has_transcript'),
    segmentCount: row.readNullable<int>('finished_segment_count'),
  );

  /// Statement behind [watchMessages]: one conversation's list rows.
  static const conversationListSql =
      'SELECT $listedMessageColumns $listedMessagesFrom'
      'WHERE m.conversation_id = ? AND m.reverted = 0 '
      'ORDER BY m.created_at ASC, m.rowid ASC';

  /// Watches the messages of one conversation ordered by creation time.
  /// Reverted messages are hidden (an unrevert restores them).
  Stream<List<ListedMessageRow>> watchMessages(String conversationId) =>
      customSelect(
        conversationListSql,
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map((rows) => rows.map(_listed).toList(growable: false));

  /// Watches the newest [limit] messages of a conversation, returned in
  /// ascending order (oldest-first) for display. Fetches `limit + 1` so the
  /// caller can tell whether older messages exist (the hasMore sentinel). The
  /// `(createdAt desc, rowid desc)` ordering keeps equal-timestamp rows stable.
  Stream<List<ListedMessageRow>> watchMessagesWindow(
    String conversationId, {
    required int limit,
  }) => customSelect(
    'SELECT $listedMessageColumns $listedMessagesFrom'
    'WHERE m.conversation_id = ? AND m.reverted = 0 '
    'ORDER BY m.created_at DESC, m.rowid DESC LIMIT ?',
    variables: [
      Variable.withString(conversationId),
      Variable.withInt(limit + 1),
    ],
    readsFrom: {conversationMessagesTable},
  ).watch().map((rows) => rows.reversed.map(_listed).toList(growable: false));

  /// The newest [limit] plain-text rows [senderId] sent in [conversationId],
  /// newest first. Content and the compacted flag only — recall never needs
  /// the row, its metadata, or anyone else's messages.
  Stream<List<({String content, bool compacted})>> watchRecentUserTexts(
    String conversationId,
    String senderId, {
    required int limit,
  }) =>
      customSelect(
        'SELECT content, compacted FROM conversation_messages '
        'WHERE conversation_id = ? AND sender_id = ? AND message_type = ? '
        'AND reverted = 0 '
        'ORDER BY created_at DESC, rowid DESC LIMIT ?',
        variables: [
          Variable.withString(conversationId),
          Variable.withString(senderId),
          Variable.withString('text'),
          Variable.withInt(limit),
        ],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => [
          for (final row in rows)
            (
              content: row.read<String>('content'),
              compacted: row.read<bool>('compacted'),
            ),
        ],
      );

  /// Statement behind [watchConversationCharCounts].
  ///
  /// Public so a test can `EXPLAIN QUERY PLAN` the exact text. These are
  /// stored integers covered by `idx_conversation_messages_live_chars`: a
  /// streaming flush re-runs the meter without reading message bodies or
  /// transcript JSON.
  static const conversationCharCountsSql = '''
SELECT message_type, content_chars, transcript_chars
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0 AND compacted = 0
''';

  /// Watches the per-message character counts of a conversation's LIVE region
  /// (not reverted, not compacted).
  ///
  /// Three small integers per row instead of the row. The context meters need
  /// a per-message sum (token estimates round per message), and reading whole
  /// messages to produce it meant an unbounded `SELECT` — content, metadata
  /// and every agent turn's transcript blob — re-run on every write.
  Stream<List<({String messageType, int contentChars, int transcriptChars})>>
  watchConversationCharCounts(String conversationId) =>
      customSelect(
        conversationCharCountsSql,
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows
            .map(
              (r) => (
                messageType: r.read<String>('message_type'),
                contentChars: r.read<int>('content_chars'),
                transcriptChars: r.read<int>('transcript_chars'),
              ),
            )
            .toList(growable: false),
      );

  /// Statement behind [latestContextReading].
  ///
  /// Public so a test can `EXPLAIN QUERY PLAN` it: the partial index
  /// `idx_conversation_messages_context_reading` answers it without touching a
  /// message row, so a streaming flush re-reads two integers, not a blob.
  ///
  /// No `rowid` tie-break, unlike the message lists: the index cannot order
  /// by it, and asking makes SQLite walk a non-covering index instead — one
  /// row read per flush, of the turn whose transcript is the largest blob in
  /// the table. Two readings in the same second of one conversation would
  /// need two turns finishing a model call within it.
  static const latestContextReadingSql = '''
SELECT context_tokens, context_window_tokens
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0 AND context_tokens IS NOT NULL
ORDER BY created_at DESC
LIMIT 1
''';

  /// The newest provider-reported context reading in a conversation, or null
  /// when no turn has reported one.
  ///
  /// The newest reading wins even when a later turn reported none (it failed
  /// before its first model call): the last thing the model actually read is
  /// still the best answer to "how full is it".
  Future<({int tokens, int? window})?> latestContextReading(
    String conversationId,
  ) async {
    final row = await customSelect(
      latestContextReadingSql,
      variables: [Variable.withString(conversationId)],
      readsFrom: {conversationMessagesTable},
    ).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (
      tokens: row.read<int>('context_tokens'),
      window: row.read<int?>('context_window_tokens'),
    );
  }

  /// Returns one page of a conversation's messages strictly older than the cursor,
  /// newest-first, each paired with its stable `rowid`.
  ///
  /// Scoped by [spaceId] as well as [conversationId], and that is an AUTHORIZATION predicate,
  /// not a filter.
  /// A conversation belongs to exactly one space, so for a legitimate caller the extra
  /// equality changes nothing — but the caller-supplied conversation id used to be the ONLY
  /// predicate.
  Future<List<({ListedMessageRow listed, int rowid})>> getMessagePageRows(
    String spaceId,
    String conversationId, {
    required int limit,
    int? beforeCreatedAtSeconds,
    int? beforeRowid,
  }) {
    final hasCursor = beforeCreatedAtSeconds != null && beforeRowid != null;
    return customSelect(
      'SELECT $listedMessageColumns, m.rowid AS _rowid $listedMessagesFrom'
      'WHERE m.space_id = ? AND m.conversation_id = ? AND m.reverted = 0 '
      '${hasCursor ? 'AND (m.created_at < ? OR (m.created_at = ? AND m.rowid < ?)) ' : ''}'
      'ORDER BY m.created_at DESC, m.rowid DESC LIMIT ?',
      variables: [
        Variable.withString(spaceId),
        Variable.withString(conversationId),
        if (hasCursor) ...[
          Variable.withInt(beforeCreatedAtSeconds),
          Variable.withInt(beforeCreatedAtSeconds),
          Variable.withInt(beforeRowid),
        ],
        Variable.withInt(limit),
      ],
      readsFrom: {conversationMessagesTable},
    ).map((row) => (listed: _listed(row), rowid: row.read<int>('_rowid'))).get();
  }

  /// Watches every unanswered question in this workspace, including inactive
  /// conversations and questions older than the message feed's page window.
  /// Join the owning space so an orphan or foreign-space row cannot escape.
  Stream<List<ConversationMessagesTableData>> watchPendingQuestions(
    String workspaceId,
  ) =>
      customSelect(
        'SELECT * FROM conversation_messages '
        'WHERE EXISTS (SELECT 1 FROM spaces WHERE spaces.id = conversation_messages.space_id '
        'AND spaces.workspace_id = ?) AND conversation_messages.reverted = 0 '
        "AND conversation_messages.message_type = 'user_question' "
        'AND conversation_messages.answered = 0 '
        'ORDER BY conversation_messages.created_at ASC, conversation_messages.rowid ASC',
        variables: [Variable.withString(workspaceId)],
        readsFrom: {conversationMessagesTable, spacesTable},
      ).watch().map(
        (rows) => [
          for (final row in rows) conversationMessagesTable.map(row.data),
        ],
      );

  /// First answer wins, atomically. Preserve all stored question metadata
  /// instead of replacing it with a stale client's snapshot.
  ///
  /// The conversation's open-question count drops in the same transaction.
  Future<bool> answerQuestion(
    String messageId,
    Map<String, dynamic> answer,
  ) => transaction(() async {
    final changed = await customUpdate(
      // `list_metadata` is the SQL name of the metadata column.
      'UPDATE conversation_messages SET answered = 1, '
      "list_metadata = json_set(COALESCE(list_metadata, '{}'), '\$.answer', json(?)) "
      "WHERE id = ? AND message_type = 'user_question' AND reverted = 0 "
      'AND answered = 0',
      variables: [
        Variable.withString(jsonEncode(answer)),
        Variable.withString(messageId),
      ],
      updates: {conversationMessagesTable},
    );
    if (changed == 1) {
      await _recountOpenQuestions(messageId: messageId);
    }
    return changed == 1;
  });

  /// Closes an unanswered question as expired, atomically: lands only while
  /// the question is still open (`answered = 0`), so an answer that won the
  /// race is never overwritten. Returns whether it closed the question.
  Future<bool> expireQuestion(String messageId) => transaction(() async {
    final changed = await customUpdate(
      'UPDATE conversation_messages SET answered = 1, '
      "list_metadata = json_set(COALESCE(list_metadata, '{}'), '\$.expired', json('true')) "
      "WHERE id = ? AND message_type = 'user_question' AND answered = 0",
      variables: [Variable.withString(messageId)],
      updates: {conversationMessagesTable},
      updateKind: UpdateKind.update,
    );
    if (changed == 1) {
      await _recountOpenQuestions(messageId: messageId);
    }
    return changed == 1;
  });

  /// Closes every question created at or before [before] that is still open.
  /// Boot sweep: question waiters live in server memory, so after a restart
  /// none of these can be answered any more. Returns how many were closed.
  Future<int> expireQuestionsCreatedBefore(
    DateTime before,
  ) => transaction(() async {
    final closed = await customUpdate(
      'UPDATE conversation_messages SET answered = 1, '
      "list_metadata = json_set(COALESCE(list_metadata, '{}'), '\$.expired', json('true')) "
      "WHERE message_type = 'user_question' AND created_at <= ? "
      'AND answered = 0',
      variables: [Variable<DateTime>(before)],
      updates: {conversationMessagesTable},
      updateKind: UpdateKind.update,
    );
    if (closed > 0) {
      await _recountOpenQuestions();
    }
    return closed;
  });

  /// Statement behind [rebuildConversationActivity] for one conversation.
  ///
  /// Every term reads an index: the maximum and the newest non-human message
  /// walk `idx_conversation_messages_conversation_created`, and the count
  /// reads the open-question partial index. No row's metadata is touched.
  static const rebuildActivitySql = """
INSERT INTO conversation_activity (
  conversation_id, space_id, last_message_at, last_agent_message_at,
  last_agent_message_seq, open_question_count
)
SELECT conversation_id, space_id, MAX(created_at),
  (SELECT a.created_at FROM conversation_messages a
    WHERE a.conversation_id = ?1 AND a.reverted = 0 AND a.sender_type <> 'user'
    ORDER BY a.created_at DESC, a.rowid DESC LIMIT 1),
  (SELECT a.rowid FROM conversation_messages a
    WHERE a.conversation_id = ?1 AND a.reverted = 0 AND a.sender_type <> 'user'
    ORDER BY a.created_at DESC, a.rowid DESC LIMIT 1),
  (SELECT COUNT(*) FROM conversation_messages q
    WHERE q.conversation_id = ?1 AND q.message_type = 'user_question'
      AND q.answered = 0 AND q.reverted = 0)
FROM conversation_messages
WHERE conversation_id = ?1 AND reverted = 0
GROUP BY conversation_id, space_id
""";

  /// Statement behind [watchSpaceActivity].
  ///
  /// Public so a test can `EXPLAIN QUERY PLAN` the exact text the watch runs.
  /// It reads one `conversation_activity` row per conversation, never a
  /// message: a streaming transcript flush updates a message and leaves
  /// these rows alone, so it does not even re-run this statement.
  ///
  /// `last_agent_message_at` is the newest non-human message: agent output
  /// and server notices (`sender_type = 'system'`) both raise the dot.
  ///
  /// An agent-only space (`SpaceKind.isAgentOnly`, stored as `'agentPeer'`)
  /// never reports `last_agent_message_at`: agent chatter must not raise a
  /// human unread dot, the same rule the notification wire applies.
  static const spaceActivitySql = r'''
SELECT a.space_id AS space_id,
       a.conversation_id AS conversation_id,
       a.last_message_at AS last_message_at,
       CASE WHEN s.kind = 'agentPeer' THEN NULL
            ELSE a.last_agent_message_at END AS last_agent_message_at,
       CASE WHEN s.kind = 'agentPeer' THEN NULL
            ELSE a.last_agent_message_seq END AS last_agent_message_seq,
       a.open_question_count AS open_question_count
FROM conversation_activity a
JOIN spaces s ON s.id = a.space_id
JOIN conversations c ON c.id = a.conversation_id
WHERE s.workspace_id = ?
  AND s.archived_at IS NULL
''';

  /// Returns a single message by ID or null.
  Future<ConversationMessagesTableData?> getMessageById(String messageId) =>
      (select(
        conversationMessagesTable,
      )..where((t) => t.id.equals(messageId))).getSingleOrNull();

  /// Newest live rows of a conversation, newest first, without bodies.
  ///
  /// Send dispatch only needs the previous message's type (and, for a plan,
  /// its status). [getMessages] would read every transcript to answer that.
  /// Both are columns stored ahead of the metadata, so no transcript is
  /// read or parsed.
  static const recentLiveMessageKindsSql = r'''
SELECT message_type, plan_status
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0
ORDER BY created_at DESC, rowid DESC
LIMIT 2
''';

  /// Two newest live messages, newest first.
  Future<List<({String messageType, String? planStatus})>>
  recentLiveMessageKinds(String conversationId) =>
      customSelect(
        recentLiveMessageKindsSql,
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => [
          for (final row in rows)
            (
              messageType: row.read<String>('message_type'),
              planStatus: row.read<String?>('plan_status'),
            ),
        ],
      );

  /// Sender of the newest live agent text or agent-turn.
  ///
  /// Walks the conversation's created-at index from the newest row and stops
  /// at the first match. It does not read `content` or `metadata`. Steering
  /// and reverted rows are excluded, matching the in-memory scan this
  /// replaces.
  static const latestAgentSenderSql = '''
SELECT sender_id
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0
  AND sender_type = 'agent'
  AND message_type IN ('text', 'agent_turn')
ORDER BY created_at DESC, rowid DESC
LIMIT 1
''';

  /// Null when the conversation has no live agent text or agent-turn.
  Future<String?> latestAgentSenderId(String conversationId) => customSelect(
    latestAgentSenderSql,
    variables: [Variable.withString(conversationId)],
    readsFrom: {conversationMessagesTable},
  ).getSingleOrNull().then((row) => row?.read<String>('sender_id'));

  /// Id of the newest live plan that is still awaiting approval.
  ///
  /// A missing `plan_status` is pending.
  static const latestPendingPlanIdSql = '''
SELECT id
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0 AND message_type = 'plan'
  AND (plan_status IS NULL OR plan_status = 'pending')
ORDER BY created_at DESC, rowid DESC
LIMIT 1
''';

  /// Id of the newest live plan of any status.
  static const latestPlanIdSql = '''
SELECT id
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0 AND message_type = 'plan'
ORDER BY created_at DESC, rowid DESC
LIMIT 1
''';

  /// Newest live plan id, or null.
  ///
  /// [pendingOnly] skips plans that have left the pending state.
  Future<String?> latestPlanMessageId(
    String conversationId, {
    bool pendingOnly = false,
  }) => customSelect(
    pendingOnly ? latestPendingPlanIdSql : latestPlanIdSql,
    variables: [Variable.withString(conversationId)],
    readsFrom: {conversationMessagesTable},
  ).getSingleOrNull().then((row) => row?.read<String>('id'));

  /// Live tail of a conversation, newest first, without transcript blobs.
  ///
  /// Dispatch context only needs recent `content` plus list metadata (for
  /// steering state and summary detection). [getMessages] would read every
  /// older turn's `segments` to decide a window that then discards them.
  /// [hasCursor] pages strictly older than a `(created_at, rowid)` pair.
  String contextTailSql({required bool hasCursor}) =>
      'SELECT *, rowid AS _rowid '
      'FROM conversation_messages '
      'WHERE conversation_id = ? AND reverted = 0 AND compacted = 0 '
      "${hasCursor ? 'AND (created_at < ? OR (created_at = ? AND rowid < ?)) ' : ''}"
      'ORDER BY created_at DESC, rowid DESC '
      'LIMIT ?';

  /// One page of [contextTailSql].
  Future<List<({ConversationMessagesTableData data, int rowid})>>
  contextTailPage(
    String conversationId, {
    required int limit,
    int? beforeCreatedAtSeconds,
    int? beforeRowid,
  }) {
    final hasCursor = beforeCreatedAtSeconds != null && beforeRowid != null;
    return customSelect(
          contextTailSql(hasCursor: hasCursor),
          variables: [
            Variable.withString(conversationId),
            if (hasCursor) ...[
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeRowid),
            ],
            Variable.withInt(limit),
          ],
          readsFrom: {conversationMessagesTable},
        )
        .map(
          (row) => (
            data: conversationMessagesTable.map(row.data),
            rowid: row.read<int>('_rowid'),
          ),
        )
        .get();
  }

  /// Newest-first page for a side-channel prompt, without transcript blobs.
  ///
  /// Unlike [contextTailSql] this keeps compacted rows. `/handoff` and
  /// `/btw` render whatever [getMessages] would have rendered, and that read
  /// only hides reverted rows. The caller stops once the rendered character
  /// budget is crossed, so older blobs stay on disk.
  String sideChannelTailSql({required bool hasCursor}) =>
      'SELECT *, rowid AS _rowid '
      'FROM conversation_messages '
      'WHERE conversation_id = ? AND reverted = 0 '
      "${hasCursor ? 'AND (created_at < ? OR (created_at = ? AND rowid < ?)) ' : ''}"
      'ORDER BY created_at DESC, rowid DESC '
      'LIMIT ?';

  /// One page of [sideChannelTailSql].
  Future<List<({ConversationMessagesTableData data, int rowid})>>
  sideChannelTailPage(
    String conversationId, {
    required int limit,
    int? beforeCreatedAtSeconds,
    int? beforeRowid,
  }) {
    final hasCursor = beforeCreatedAtSeconds != null && beforeRowid != null;
    return customSelect(
          sideChannelTailSql(hasCursor: hasCursor),
          variables: [
            Variable.withString(conversationId),
            if (hasCursor) ...[
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeRowid),
            ],
            Variable.withInt(limit),
          ],
          readsFrom: {conversationMessagesTable},
        )
        .map(
          (row) => (
            data: conversationMessagesTable.map(row.data),
            rowid: row.read<int>('_rowid'),
          ),
        )
        .get();
  }

  /// Every summary row in a conversation, oldest first, without transcripts.
  ///
  /// The compaction messages. A summary whose `compacted` column is set still
  /// has to be returned: the verbatim tail skips that column, and the prompt
  /// would otherwise lose the summary.
  String get contextSummarySql =>
      'SELECT * '
      'FROM conversation_messages '
      "WHERE conversation_id = ? AND reverted = 0 AND message_type = 'compaction' "
      'ORDER BY created_at ASC, rowid ASC';

  /// Summaries for [contextSummarySql].
  Future<List<ConversationMessagesTableData>> contextSummaries(
    String conversationId,
  ) =>
      customSelect(
        contextSummarySql,
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Id of the newest live, non-compacted agent turn.
  ///
  /// The run digest reads that one row's transcript. This statement does not.
  static const latestContextAgentTurnIdSql = '''
SELECT id
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0 AND compacted = 0
  AND message_type = 'agent_turn'
ORDER BY created_at DESC, rowid DESC
LIMIT 1
''';

  /// Null when the conversation has no live agent turn.
  Future<String?> latestContextAgentTurnId(String conversationId) =>
      customSelect(
        latestContextAgentTurnIdSql,
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).getSingleOrNull().then((row) => row?.read<String>('id'));

  /// Queued steering cards in one conversation, without other rows' transcripts.
  ///
  /// Enqueue, reorder, and run-start replay only need these cards. The
  /// `steer_state = 'queued'` literal matches the partial index
  /// `idx_conversation_messages_queued_steering`, which holds only queued
  /// cards, so the read never touches another row.
  String get queuedSteeringSql =>
      'SELECT * '
      'FROM conversation_messages '
      "WHERE steer_state = 'queued' AND conversation_id = ? "
      "AND space_id = ? AND reverted = 0 AND message_type = 'steering'";

  /// Merges [patch] into a steering card's metadata only while the card is
  /// still in [fromState] (its `steer_state`), returning whether it was.
  ///
  /// The steering queue's writers race each other: a reorder, an edit, a
  /// live run draining the card and the run-end conversion can all touch the
  /// same row. Each used to write back a whole metadata map read moments
  /// earlier, so a reorder could quietly revert `injected` to `queued`. Here
  /// the state check, the merge onto the CURRENT metadata and the write share
  /// one transaction, and [content] / [messageType] change with it.
  Future<bool> patchSteering(
    String messageId, {
    required String fromState,
    required Map<String, dynamic> patch,
    String? content,
    String? messageType,
  }) => transaction(() async {
    final row = await getMessageById(messageId);
    if (row == null || row.steerState != fromState) {
      return false;
    }
    final current = switch (row.metadata) {
      final String raw when raw.isNotEmpty => switch (jsonDecode(raw)) {
        final Map<String, dynamic> m => m,
        _ => <String, dynamic>{},
      },
      _ => <String, dynamic>{},
    };
    await updateMessage(
      messageId,
      content: content,
      metadata: {
        ...current,
        if (row.answered) 'answered': true,
        'planStatus': ?row.planStatus,
        'steerState': ?row.steerState,
        ...patch,
      },
      messageType: messageType,
    );
    return true;
  });

  /// Rows for [queuedSteeringSql]. Order is not delivery order; callers sort
  /// by `steerOrder`.
  Future<List<ConversationMessagesTableData>> queuedSteeringMessages(
    String conversationId,
    String spaceId,
  ) =>
      customSelect(
        queuedSteeringSql,
        variables: [
          Variable.withString(conversationId),
          Variable.withString(spaceId),
        ],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Content of the oldest live human message, or null when there is none.
  ///
  /// Conversation titling sends this text to a model. It does not need any
  /// later turn, and it does not need metadata.
  static const firstHumanContentSql = '''
SELECT content
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0 AND sender_type = 'user'
ORDER BY created_at ASC, rowid ASC
LIMIT 1
''';

  /// Null when the conversation has no live human message.
  Future<String?> firstHumanContent(String conversationId) => customSelect(
    firstHumanContentSql,
    variables: [Variable.withString(conversationId)],
    readsFrom: {conversationMessagesTable},
  ).getSingleOrNull().then((row) => row?.read<String>('content'));

  /// Content of the newest live message from one agent.
  ///
  /// Pipeline harvest uses this when a run ends without `submit_output`.
  /// The row's transcript stays on disk.
  static const latestAgentContentSql = '''
SELECT content
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0
  AND sender_type = 'agent' AND sender_id = ?
ORDER BY created_at DESC, rowid DESC
LIMIT 1
''';

  /// Null when [agentId] has no live message in the conversation.
  Future<String?> latestAgentContent(String conversationId, String agentId) =>
      customSelect(
        latestAgentContentSql,
        variables: [
          Variable.withString(conversationId),
          Variable.withString(agentId),
        ],
        readsFrom: {conversationMessagesTable},
      ).getSingleOrNull().then((row) => row?.read<String>('content'));

  /// Returns all (non-reverted) messages for a conversation in creation order.
  Future<List<ConversationMessagesTableData>> getMessages(
    String conversationId,
  ) =>
      customSelect(
        'SELECT * FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Reverts (rolls back) the given messages: marks them hidden and stamps a
  /// shared [revertedAtMs] so [getLatestRevertedBatch] can find this batch.
  ///
  /// If [revertedAtMs] would tie a prior batch's timestamp (rapid reverts
  /// inside one millisecond), it is bumped one past the space's current max
  /// so each batch stays individually addressable for unrevert.
  ///
  /// The conversations' activity rows are recomputed in the same transaction.
  Future<void> revertMessages(List<String> ids, int revertedAtMs) async {
    if (ids.isEmpty) {
      return;
    }
    await transaction(() => _revertMessages(ids, revertedAtMs));
  }

  Future<void> _revertMessages(List<String> ids, int revertedAtMs) async {
    final spaceIds =
        await (selectOnly(conversationMessagesTable)
              ..addColumns([conversationMessagesTable.spaceId])
              ..where(conversationMessagesTable.id.isIn(ids)))
            .map((row) => row.read(conversationMessagesTable.spaceId))
            .get();
    var stamp = revertedAtMs;
    for (final spaceId in spaceIds.whereType<String>().toSet()) {
      final maxRow =
          await (selectOnly(conversationMessagesTable)
                ..addColumns([conversationMessagesTable.revertedAt])
                ..where(
                  conversationMessagesTable.spaceId.equals(spaceId) &
                      conversationMessagesTable.reverted.equals(true) &
                      conversationMessagesTable.revertedAt.isNotNull(),
                ))
              .map((row) => row.read(conversationMessagesTable.revertedAt) ?? 0)
              .get();
      final currentMax = maxRow.isEmpty
          ? 0
          : maxRow.reduce((a, b) => a > b ? a : b);
      if (stamp <= currentMax) {
        stamp = currentMax + 1;
      }
    }
    await (update(
      conversationMessagesTable,
    )..where((t) => t.id.isIn(ids))).write(
      ConversationMessagesTableCompanion(
        reverted: const Value(true),
        revertedAt: Value(stamp),
      ),
    );
    await rebuildConversationActivity(await _conversationsOf(ids));
  }

  /// Clears the reverted flag on the given messages (an unrevert/redo), and
  /// recomputes their conversations' activity rows in the same transaction.
  Future<void> unrevertMessages(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await transaction(() async {
      await (update(
        conversationMessagesTable,
      )..where((t) => t.id.isIn(ids))).write(
        const ConversationMessagesTableCompanion(
          reverted: Value(false),
          revertedAt: Value(null),
        ),
      );
      await rebuildConversationActivity(await _conversationsOf(ids));
    });
  }

  /// Ids of a conversation's live messages, oldest first. Nothing else is
  /// read: a revert only needs to know which rows follow its target.
  Future<List<String>> liveMessageIds(String conversationId) => customSelect(
    'SELECT id FROM conversation_messages '
    'WHERE conversation_id = ? AND reverted = 0 '
    'ORDER BY created_at ASC, rowid ASC',
    variables: [Variable.withString(conversationId)],
    readsFrom: {conversationMessagesTable},
  ).map((row) => row.read<String>('id')).get();

  /// Returns the message ids reverted in the most-recent revert batch for a
  /// space (those sharing the maximum `reverted_at`), for unrevert.
  Future<List<String>> getLatestRevertedBatch(String spaceId) async {
    final rows = await customSelect(
      'SELECT id FROM conversation_messages '
      'WHERE space_id = ? AND reverted = 1 AND reverted_at = '
      '(SELECT MAX(reverted_at) FROM conversation_messages '
      ' WHERE space_id = ? AND reverted = 1)',
      variables: [Variable.withString(spaceId), Variable.withString(spaceId)],
      readsFrom: {conversationMessagesTable},
    ).get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

  /// Marks messages matching [ids] as compacted.
  Future<void> markCompacted(List<String> ids) async {
    await (update(
      conversationMessagesTable,
    )..where((t) => t.id.isIn(ids))).write(
      const ConversationMessagesTableCompanion(compacted: Value(true)),
    );
  }

  /// Inserts a space. Deliberately seeds NO conversation: the standing one is
  /// minted lazily by `ConversationDao.ensureStandingConversation` with its
  /// own uuid on first use — there is no main-conversation id aliasing, and a
  /// space the pipeline fills with named conversations never grows an extra
  /// one. The `conversation_id` FK on [ConversationMessagesTable] still always
  /// resolves because every write path mints the standing row before insert.
  Future<void> insertSpace(SpacesTableCompanion entry) async {
    await into(spacesTable).insert(entry);
  }

  /// Inserts a participant; a principal already in the space is left as it
  /// is (`(space_id, principal_id)` is unique).
  Future<void> insertParticipant(SpaceParticipantsTableCompanion entry) =>
      into(spaceParticipantsTable).insert(
        entry,
        onConflict: DoNothing(
          target: [
            spaceParticipantsTable.spaceId,
            spaceParticipantsTable.principalId,
          ],
        ),
      );

  /// Inserts a message and folds it into its conversation's activity row,
  /// in one transaction.
  ///
  /// Stamps [ConversationMessagesTable.contentChars],
  /// [ConversationMessagesTable.transcriptChars], the context reading and the
  /// promoted metadata keys ([promotedMetadataKeys], removed from the stored
  /// JSON) in the same statement. A follow-up update would fire the sync
  /// trigger a second time and make the message-list watch run twice per
  /// send. A `metadata['segments']` array becomes the message's transcript
  /// rows in the same transaction.
  Future<void> insertMessage(ConversationMessagesTableCompanion entry) {
    final content = entry.content.present ? entry.content.value : '';
    final stamp = _stampMetadataJson(
      entry.metadata.present ? entry.metadata.value : null,
    );
    return transaction(() async {
      await into(conversationMessagesTable).insert(
        entry.copyWith(
          contentChars: Value(_sqliteTextLength(content)),
          transcriptChars: Value(stamp.transcriptChars),
          contextTokens: Value(stamp.context.tokens),
          contextWindowTokens: Value(stamp.context.window),
          answered: Value(stamp.answered),
          planStatus: Value(stamp.planStatus),
          steerState: Value(stamp.steerState),
          metadata: Value(stamp.metadata),
        ),
      );
      final segments = stamp.segments;
      if (segments != null) {
        await attachedDatabase.runTranscriptDao.writeMessageTranscript(
          entry.id.value,
          segments: _segmentBodies(segments),
          segmentCount: segments.length,
          transcriptChars: stamp.transcriptChars,
          replaceAll: true,
          // A whole transcript written without stream state is a finished
          // one (a seeded or copied turn); a streaming turn says so.
          complete: stamp.turn.complete ?? true,
          outcome: stamp.turn.outcome,
        );
      }
      await _foldInsertIntoActivity(entry.id.value);
      await _recordAttachmentHolder(entry.id.value, stamp.metadata);
    });
  }

  /// Records, on each uploaded file a message carries, that this message
  /// holds it (`catalog_files.attached_message_id`).
  ///
  /// Written where the message row is written, in the same transaction, so
  /// every way of sending a message records it and the catalog can answer
  /// "does a message still hold these bytes" without reading a transcript.
  /// The first holder stays: a fork or an edit that repeats the attachment
  /// does not take it over.
  Future<void> _recordAttachmentHolder(
    String messageId,
    String? metadataJson,
  ) async {
    if (metadataJson == null || !metadataJson.contains('"attachments"')) {
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(metadataJson);
    } on FormatException {
      return;
    }
    final attachments = decoded is Map ? decoded['attachments'] : null;
    if (attachments is! List) {
      return;
    }
    final fileIds = <String>{
      for (final attachment in attachments)
        if (attachment is Map)
          if (attachment['fileId'] case final String id when id.isNotEmpty) id,
    };
    if (fileIds.isEmpty) {
      return;
    }
    await customUpdate(
      'UPDATE catalog_files SET attached_message_id = ? '
      'WHERE attached_message_id IS NULL '
      'AND id IN (${List.filled(fileIds.length, '?').join(', ')})',
      variables: [
        Variable<String>(messageId),
        for (final id in fileIds) Variable<String>(id),
      ],
      updates: {attachedDatabase.catalogFilesTable},
    );
  }

  /// Deletes one message row by id.
  ///
  /// Queue-surgery affordance for steering rows only: they never become the
  /// conversation leaf (`DaoMessagingRepository.insertSteeringMessage` skips
  /// `setLeaf`), so no other row's `parent_message_id` can point at one and
  /// the delete cannot orphan the branch tree. Callers must have validated
  /// the row's type/state. The conversation's activity row is recomputed in
  /// the same transaction.
  Future<void> deleteMessageById(String messageId) => transaction(() async {
    final conversations = await _conversationsOf([messageId]);
    await (delete(
      conversationMessagesTable,
    )..where((t) => t.id.equals(messageId))).go();
    await rebuildConversationActivity(conversations);
  });

  /// Deletes one message row by id AND conversation — the ownership-checked
  /// form of `deleteMessageById` so a foreign workspace's row id resolves to
  /// nothing rather than to a hit.
  Future<void> deleteMessageInConversation(
    String conversationId,
    String messageId,
  ) => transaction(() async {
    final deleted =
        await (delete(conversationMessagesTable)
              ..where((t) => t.id.equals(messageId))
              ..where((t) => t.conversationId.equals(conversationId)))
            .go();
    if (deleted > 0) {
      await rebuildConversationActivity([conversationId]);
    }
  });

  /// Statement behind [branchIds] and [branchFrom]: the ancestors of `?2`
  /// in conversation `?1`, leaf first, with their distance from it.
  ///
  /// Each step is one primary-key probe. A corrupt parent chain that loops
  /// is cut at depth `?3`; the callers stop at the first repeated id.
  static const branchSql = '''
WITH RECURSIVE branch(id, parent_message_id, depth) AS (
  SELECT id, parent_message_id, 0 FROM conversation_messages
  WHERE conversation_id = ?1 AND id = ?2
  UNION ALL
  SELECT m.id, m.parent_message_id, b.depth + 1
  FROM conversation_messages m JOIN branch b ON m.id = b.parent_message_id
  WHERE m.conversation_id = ?1 AND b.depth < ?3
)
''';

  /// Longest content prefix [treeNodes] returns: the navigator previews 80
  /// characters after collapsing whitespace, and this leaves room for runs
  /// of it.
  static const treePreviewSourceChars = 400;

  /// Updates the content and/or metadata of an existing message.
  ///
  /// [metadata] replaces the stored map. Its promoted keys
  /// ([promotedMetadataKeys]) go to their columns and are removed from the
  /// stored JSON; a map lacking `planStatus` or `steerState` clears that
  /// column. `answered` is different: a map without it leaves the column
  /// alone, so a rewrite that dropped the key cannot quietly reopen a
  /// question behind the open-question count, and a map carrying it lands
  /// only on a still-open `user_question` (first answer wins).
  ///
  /// A `segments` array in [metadata] is the whole transcript: it is written
  /// as the message's transcript rows, rewriting only the segments whose
  /// content differs from what is stored, and never stored in the JSON. A
  /// map without it leaves the transcript as it is.
  ///
  /// When [content] or [metadata] changes, the meter's stored counts are
  /// written in the same statement. Revert updates do not come through here,
  /// so they do not recompute those counts.
  ///
  /// A write that can open or close a question (an `answered` key or a type
  /// change) recounts the conversation's open questions in the same
  /// transaction.
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
  }) {
    final lifted = metadata == null ? null : _liftPromoted(metadata);
    final encoded = lifted == null ? null : jsonEncode(lifted.rest);
    final answering = metadata?.containsKey('answered') == true;
    final segments = lifted?.segments;
    Future<int> write() => _writeMessageRow(
      messageId,
      content: content,
      metadata: metadata,
      lifted: lifted,
      encoded: encoded,
      messageType: messageType,
    );
    final attaching = metadata?['attachments'] != null;
    if (!answering && messageType == null && !attaching && segments == null) {
      return write();
    }
    return transaction(() async {
      final written = await write();
      if (written == 0) {
        return;
      }
      if (answering || messageType != null) {
        await _recountOpenQuestions(messageId: messageId);
      }
      if (attaching) {
        await _recordAttachmentHolder(messageId, encoded);
      }
      if (segments != null) {
        final turn = _turnStateOf(metadata!);
        await attachedDatabase.runTranscriptDao.writeMessageTranscript(
          messageId,
          segments: _segmentBodies(segments),
          segmentCount: segments.length,
          transcriptChars: _transcriptCharsOf(metadata),
          replaceAll: true,
          complete: turn.complete ?? true,
          outcome: turn.outcome,
        );
      }
    });
  }

  /// One flush of a streaming agent turn, in one transaction.
  ///
  /// Writes only the transcript segments in [changedSegments] (position →
  /// encoded segment; every other segment row is left as it was) and the
  /// transcript's length, [segmentCount]. On the message row it writes the
  /// meter's counts from [metadata] (`transcriptChars`, `context`), [content]
  /// when the visible text changed, and the metadata JSON itself only when
  /// [writeMetadata] is set: that JSON is what a message list shows, and a
  /// flush that only grew the transcript must not change it.
  ///
  /// With [writeMetadata], `streamComplete` and `outcome` in [metadata] also
  /// finish the transcript.
  Future<void> flushStreamingTurn(
    String messageId, {
    String? content,
    required Map<String, dynamic> metadata,
    required bool writeMetadata,
    required Map<int, String> changedSegments,
    required int segmentCount,
  }) => transaction(() async {
    final lifted = _liftPromoted(metadata);
    final written = await _writeMessageRow(
      messageId,
      content: content,
      metadata: metadata,
      lifted: writeMetadata ? lifted : null,
      encoded: writeMetadata ? jsonEncode(lifted.rest) : null,
    );
    if (written == 0) {
      return;
    }
    final turn = writeMetadata
        ? _turnStateOf(metadata)
        : (complete: null, outcome: null);
    await attachedDatabase.runTranscriptDao.writeMessageTranscript(
      messageId,
      segments: changedSegments,
      segmentCount: segmentCount,
      transcriptChars: _transcriptCharsOf(metadata),
      replaceAll: false,
      complete: turn.complete,
      outcome: turn.outcome,
    );
  });

  /// The one `UPDATE` of a message row behind [updateMessage] and
  /// [flushStreamingTurn]. Returns the rows written.
  ///
  /// [metadata] supplies the meter's counts; [lifted] / [encoded] (both null
  /// to leave them) the stored JSON and the promoted columns.
  Future<int> _writeMessageRow(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    ({
      bool answered,
      String? planStatus,
      String? steerState,
      List<Map<dynamic, dynamic>>? segments,
      Map<dynamic, dynamic> rest,
    })?
    lifted,
    String? encoded,
    String? messageType,
  }) {
    final context = metadata == null ? null : _contextOf(metadata);
    final answering =
        lifted != null && metadata?.containsKey('answered') == true;
    return (update(conversationMessagesTable)..where(
          (t) =>
              t.id.equals(messageId) &
              (answering
                  ? (t.messageType.equals('user_question') &
                        t.answered.equals(false))
                  : const Constant(true)),
        ))
        .write(
          ConversationMessagesTableCompanion(
            content: content != null ? Value(content) : const Value.absent(),
            contentChars: content != null
                ? Value(_sqliteTextLength(content))
                : const Value.absent(),
            metadata: encoded != null ? Value(encoded) : const Value.absent(),
            answered: answering ? Value(lifted.answered) : const Value.absent(),
            planStatus: lifted != null
                ? Value(lifted.planStatus)
                : const Value.absent(),
            steerState: lifted != null
                ? Value(lifted.steerState)
                : const Value.absent(),
            transcriptChars: metadata != null
                ? Value(_transcriptCharsOf(metadata))
                : const Value.absent(),
            contextTokens: context != null
                ? Value(context.tokens)
                : const Value.absent(),
            contextWindowTokens: context != null
                ? Value(context.window)
                : const Value.absent(),
            messageType: messageType != null
                ? Value(messageType)
                : const Value.absent(),
          ),
        );
  }

  /// Full-text search within a single space (§8.4). Matches [query] against
  /// message content via the `conversation_messages_fts` index, scoped to
  /// [spaceId] on the content table (the authoritative filter — messages have
  /// no `workspace_id`, so the caller/RPC validates space ownership), newest
  /// results first for ties. Reverted (hidden) messages are excluded. Returns
  /// an empty list when the query has no usable search tokens.
  ///
  /// A hit is a list row: the transcript stays on disk, only its facts are
  /// read.
  Future<List<ListedMessageRow>> searchInSpace(
    String spaceId,
    String query, {
    int limit = 50,
  }) {
    final orQuery = toFtsOrQuery(query);
    if (orQuery.isEmpty) {
      return Future.value(const []);
    }
    return customSelect(
      'SELECT $listedMessageColumns $listedMessagesFrom'
      'JOIN conversation_messages_fts fts ON fts.rowid = m.rowid '
      'WHERE fts.conversation_messages_fts MATCH ? '
      'AND m.space_id = ? '
      'AND m.reverted = 0 '
      'ORDER BY rank, m.rowid DESC '
      'LIMIT ?',
      variables: [
        Variable<String>('content : ($orQuery)'),
        Variable<String>(spaceId),
        Variable<int>(limit),
      ],
      readsFrom: {conversationMessagesTable},
    ).map(_listed).get();
  }

  /// Watches all (non-reverted) messages in a space, across every conversation
  /// it holds, in creation order. Streaming twin of [getMessagesForSpace].
  Stream<List<ListedMessageRow>> watchMessagesForSpace(String spaceId) =>
      customSelect(
        'SELECT $listedMessageColumns $listedMessagesFrom'
        'WHERE m.space_id = ? AND m.reverted = 0 '
        'ORDER BY m.created_at ASC, m.rowid ASC',
        variables: [Variable.withString(spaceId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map((rows) => rows.map(_listed).toList(growable: false));

  /// Returns all (non-reverted) messages in a space, across every conversation
  /// it holds, in creation order.
  ///
  /// The sibling [getMessages] is conversation-scoped. This one exists for the
  /// space-wide readers (the PR review surface), which must see a message
  /// whichever thread it was posted in.
  Future<List<ConversationMessagesTableData>> getMessagesForSpace(
    String spaceId,
  ) =>
      customSelect(
        'SELECT * FROM conversation_messages '
        'WHERE space_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(spaceId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Statement behind [messagesToEmbed].
  ///
  /// "Not embedded yet" is "has no row in `conversation_message_embeddings`":
  /// each candidate costs one probe of that table's primary key, and the
  /// message row is never written to say it was embedded. The walk is in
  /// rowid order from a position, so a backfill reads the table once however
  /// many batches it takes, and a message it could not embed is passed
  /// instead of returned again. `NOT INDEXED` keeps it that walk: by the
  /// message-type index the planner would collect and sort every remaining
  /// message for each batch.
  ///
  /// The types are the ones embedded when they are written: what a person
  /// typed, what an agent answered and a compaction summary. A message with
  /// no text has nothing to embed.
  static final messagesToEmbedSql =
      """
SELECT m.rowid AS position, m.id, m.content
FROM conversation_messages m NOT INDEXED
WHERE m.rowid > ?
  AND m.message_type IN ('${MessageType.text.wire}', '${MessageType.agentTurn.wire}', '${MessageType.compaction.wire}')
  AND m.compacted = 0
  AND m.content <> ''
  AND NOT EXISTS (
    SELECT 1 FROM conversation_message_embeddings e WHERE e.message_id = m.id
  )
ORDER BY m.rowid
LIMIT ?
""";
}
