import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart' show Mode;
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/space_participants.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'messaging_dao.g.dart';


/// Unicode code points in [text], which is what SQLite `LENGTH` counts.
///
/// `String.length` counts UTF-16 code units, so an emoji is 2. The meter used
/// to sum `LENGTH(content)`. This is that count, and it is what the v12
/// backfill stores.
int _sqliteTextLength(String text) => text.runes.length;

/// `transcriptChars` from a metadata JSON object, or 0 when it is absent.
int _transcriptCharsOf(Map<dynamic, dynamic> metadata) {
  final value = metadata['transcriptChars'];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

/// Transcript size and list metadata from one decode of a metadata cell.
///
/// The returned list text is [raw] itself when there is no `segments` array, so a
/// plain message stays byte-identical. An array is removed and replaced with
/// `segments_elided` and `segment_count`.
({int transcriptChars, String? listMetadata}) _stampMetadataJson(String? raw) {
  if (raw == null || raw.isEmpty) {
    return (transcriptChars: 0, listMetadata: raw);
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<dynamic, dynamic>) {
      return (
        transcriptChars: _transcriptCharsOf(decoded),
        listMetadata: _listMetadataOf(decoded, raw),
      );
    }
  } on Object {
    return (transcriptChars: 0, listMetadata: raw);
  }
  return (transcriptChars: 0, listMetadata: raw);
}

/// [fallback] when [metadata] has no segment array, so the list cell does not
/// get a second encoding of JSON that was already stored.
String _listMetadataOf(Map<dynamic, dynamic> metadata, String fallback) {
  final segments = metadata['segments'];
  if (segments is! List<dynamic>) {
    return fallback;
  }
  final lite = Map<dynamic, dynamic>.from(metadata)..remove('segments');
  lite['segments_elided'] = true;
  lite['segment_count'] = segments.length;
  return jsonEncode(lite);
}

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

/// Data access object for [SpacesTable], [SpaceParticipantsTable] and
/// [ConversationMessagesTable].
@DriftAccessor(
  tables: [
    SpacesTable,
    ConversationsTable,
    SpaceParticipantsTable,
    ConversationMessagesTable,
  ],
)
class MessagingDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$MessagingDaoMixin {
  /// Creates a [MessagingDao] for the given database.
  MessagingDao(super.attachedDatabase);

  /// Watches this workspace's spaces, most recently updated first.
  ///
  /// Unfiltered and safe: this DAO hangs off one workspace's database, so
  /// "every space in the file" is "every space in the workspace". The
  /// all-workspaces dashboard view merges one of these streams per workspace
  /// through `CrossWorkspaceQueries.mergeStreams` — it does not filter a global
  /// stream in memory, which is how other workspaces' spaces leaked before.
  Stream<List<SpacesTableData>> watchSpaces() => (select(
    spacesTable,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Watches participants for a space.
  Stream<List<SpaceParticipantsTableData>> watchParticipants(String spaceId) =>
      (select(spaceParticipantsTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .watch();

  /// Watches spaces for a specific workspace ordered by most recently updated.
  Stream<List<SpacesTableData>> watchSpacesByWorkspace(String workspaceId) =>
      (select(spacesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Every `conversation_messages` column except `embedding`, as a SELECT list.
  ///
  /// The embedding is a 1,536-byte FLOAT32 blob per row that exists only for
  /// semantic recall — nothing that reads a message LIST ever looks at it, and
  /// no wire shape carries it. A `SELECT *` over a 10k-message conversation
  /// therefore dragged ~15 MB off disk (and re-read all of it on every write
  /// to the table) to hand back rows whose blob is then dropped.
  ///
  /// Derived from the table's own column list rather than spelled out, so a
  /// column added later is included automatically instead of silently
  /// arriving null.
  late final String _messageColumnsSansEmbedding = conversationMessagesTable
      .$columns
      .where((c) => c.name != 'embedding' && c.name != 'list_metadata')
      .map((c) => c.name)
      .join(', ');

  /// Same columns as [_messageColumnsSansEmbedding], but `metadata` is the
  /// stored [ConversationMessagesTable.listMetadata] column.
  ///
  /// List watches re-run on every write to this table, and a streaming turn
  /// writes its transcript on every chunk. Nothing that renders a list reads
  /// `segments` from this row: a live turn comes from the relay, a finished
  /// one from [getMessageById]. The stripped text is written with the row, so
  /// this select does not parse it. A row that predates that write still
  /// falls through to the JSON strip. [getMessages] and [getMessageById] keep
  /// the array. History pages and in-space search use this list too.
  late final String _messageColumnsLite = _liteColumns();

  /// Column list selected by [watchMessages] and the other list reads.
  ///
  /// Public so a test can assert the fast path reads `list_metadata` instead
  /// of parsing every transcript on each flush.
  String get messageListSelectColumns => _messageColumnsLite;

  /// [qualifier] is a table alias without the dot (`m` produces `m.id`).
  /// Search joins the FTS table, which has its own `content`, so the bare
  /// names would be ambiguous there.
  String _liteColumns([String? qualifier]) {
    final prefix = qualifier == null ? '' : '$qualifier.';
    final metadata = '${_liteMetadataSql(prefix)} AS metadata';
    return conversationMessagesTable.$columns
        .where((c) => c.name != 'embedding' && c.name != 'list_metadata')
        .map((c) => c.name == 'metadata' ? metadata : '$prefix${c.name}')
        .join(', ');
  }

  /// `list_metadata` when the write stamped it. Otherwise the strip the list
  /// used to do in SQL, so a row inserted around the migration still hides
  /// its transcript. SQLite evaluates `CASE` left to right, so a stamped row
  /// never reads the metadata column.
  String _liteMetadataSql(String prefix) {
    final list = '${prefix}list_metadata';
    final meta = '${prefix}metadata';
    return 'CASE WHEN $list IS NOT NULL THEN $list ELSE '
        "CASE WHEN json_type($meta, '\$.segments') IS NULL THEN $meta "
        'ELSE json_set('
        "json_remove($meta, '\$.segments'), "
        "'\$.segments_elided', json('true'), "
        "'\$.segment_count', json_array_length($meta, '\$.segments')"
        ') END END';
  }

  /// Watches the messages of one conversation ordered by creation time.
  /// Reverted messages are hidden (an unrevert restores them).
  Stream<List<ConversationMessagesTableData>> watchMessages(
    String conversationId,
  ) =>
      customSelect(
        'SELECT $_messageColumnsLite FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Watches the newest [limit] messages of a conversation, returned in
  /// ascending order (oldest-first) for display. Fetches `limit + 1` so the
  /// caller can tell whether older messages exist (the hasMore sentinel). The
  /// `(createdAt desc, rowid desc)` ordering keeps equal-timestamp rows stable.
  Stream<List<ConversationMessagesTableData>> watchMessagesWindow(
    String conversationId, {
    required int limit,
  }) =>
      customSelect(
        'SELECT $_messageColumnsLite FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at DESC, rowid DESC LIMIT ?',
        variables: [
          Variable.withString(conversationId),
          Variable.withInt(limit + 1),
        ],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows.reversed
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

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

  /// Returns one page of a conversation's messages strictly older than the cursor,
  /// newest-first, each paired with its stable `rowid`.
  ///
  /// Scoped by [spaceId] as well as [conversationId], and that is an AUTHORIZATION predicate,
  /// not a filter.
  /// A conversation belongs to exactly one space, so for a legitimate caller the extra
  /// equality changes nothing — but the caller-supplied conversation id used to be the ONLY
  /// predicate.
  Future<List<({ConversationMessagesTableData data, int rowid})>>
  getMessagePageRows(
    String spaceId,
    String conversationId, {
    required int limit,
    int? beforeCreatedAtSeconds,
    int? beforeRowid,
  }) {
    final hasCursor = beforeCreatedAtSeconds != null && beforeRowid != null;
    return customSelect(
          'SELECT $_messageColumnsLite, rowid AS _rowid '
          'FROM conversation_messages '
          'WHERE space_id = ? AND conversation_id = ? AND reverted = 0 '
          '${hasCursor ? 'AND (created_at < ? OR (created_at = ? AND rowid < ?)) ' : ''}'
          'ORDER BY created_at DESC, rowid DESC LIMIT ?',
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
        )
        .map(
          (row) => (
            data: conversationMessagesTable.map(row.data),
            rowid: row.read<int>('_rowid'),
          ),
        )
        .get();
  }

  /// Statement behind [watchSpaceActivity].
  ///
  /// Public so a test can `EXPLAIN QUERY PLAN` the exact text the watch runs.
  /// The CTEs are `MATERIALIZED` so SQLite cannot fold them back into one pass
  /// that reads `metadata` for every live message. The maxima use
  /// `idx_conversation_messages_live_activity` (covering: no transcript blob).
  /// The question count uses `idx_conversation_messages_messageType`, so it
  /// reads `metadata` only for `user_question` rows.
  static const spaceActivitySql = r'''
WITH activity AS MATERIALIZED (
  SELECT space_id, conversation_id,
         MAX(created_at) AS last_message_at,
         MAX(CASE WHEN sender_type = 'agent' THEN created_at END)
           AS last_agent_message_at
  FROM conversation_messages
  WHERE reverted = 0
  GROUP BY space_id, conversation_id
),
questions AS MATERIALIZED (
  SELECT space_id, conversation_id, COUNT(*) AS open_question_count
  FROM conversation_messages
  WHERE reverted = 0
    AND message_type = 'user_question'
    AND COALESCE(json_extract(metadata, '$.answered'), 0) != 1
  GROUP BY space_id, conversation_id
)
SELECT activity.space_id AS space_id,
       activity.conversation_id AS conversation_id,
       activity.last_message_at AS last_message_at,
       activity.last_agent_message_at AS last_agent_message_at,
       COALESCE(questions.open_question_count, 0) AS open_question_count
FROM activity
JOIN spaces ON spaces.id = activity.space_id
LEFT JOIN questions
  ON questions.space_id = activity.space_id
 AND questions.conversation_id = activity.conversation_id
WHERE spaces.workspace_id = ?
  AND spaces.archived_at IS NULL
''';

  /// Watches per-space activity signals for one workspace: newest message time, newest
  /// agent-message time (the unread-dot signal) and the open (unanswered) agent-question
  /// count (the needs-input signal).
  ///
  /// Archived spaces are excluded: an archived space's row is gone from the sidebar, so its
  /// unread/needs-input signals would have no visible home — and a hidden room must not keep
  /// demanding attention.
  ///
  /// The statement is [spaceActivitySql]: two materialized aggregates, so a
  /// streaming flush does not re-read every transcript blob just to update
  /// the sidebar dots.
  Stream<
    List<
      ({
        String spaceId,
        String conversationId,
        DateTime? lastMessageAt,
        DateTime? lastAgentMessageAt,
        int openQuestionCount,
      })
    >
  >
  watchSpaceActivity(String workspaceId) =>
      customSelect(
        spaceActivitySql,
        variables: [Variable.withString(workspaceId)],
        readsFrom: {conversationMessagesTable, spacesTable},
      ).watch().map(
        (rows) => [
          for (final row in rows)
            (
              spaceId: row.read<String>('space_id'),
              conversationId: row.read<String>('conversation_id'),
              lastMessageAt: switch (row.readNullable<int>('last_message_at')) {
                final int s => DateTime.fromMillisecondsSinceEpoch(s * 1000),
                null => null,
              },
              lastAgentMessageAt: switch (row.readNullable<int>(
                'last_agent_message_at',
              )) {
                final int s => DateTime.fromMillisecondsSinceEpoch(s * 1000),
                null => null,
              },
              openQuestionCount: row.read<int>('open_question_count'),
            ),
        ],
      );

  /// Returns a single message by ID or null.
  Future<ConversationMessagesTableData?> getMessageById(String messageId) =>
      (select(
        conversationMessagesTable,
      )..where((t) => t.id.equals(messageId))).getSingleOrNull();

  /// Newest live rows of a conversation, newest first, without bodies.
  ///
  /// Send dispatch only needs the previous message's type (and, for a plan,
  /// its status). [getMessages] would read every transcript to answer that.
  /// `json_extract` runs only for `plan` rows, so an agent turn's metadata
  /// blob is never parsed.
  static const recentLiveMessageKindsSql = r'''
SELECT message_type,
  CASE
    WHEN message_type = 'plan' THEN json_extract(metadata, '$.planStatus')
    ELSE NULL
  END AS plan_status
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0
ORDER BY created_at DESC, rowid DESC
LIMIT 2
''';

  /// Two newest live messages, newest first.
  Future<List<({String messageType, String? planStatus})>>
  recentLiveMessageKinds(String conversationId) => customSelect(
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
  /// A missing `planStatus` is pending. Only plan rows are parsed, and only
  /// their status field.
  static const latestPendingPlanIdSql = r'''
SELECT id
FROM conversation_messages
WHERE conversation_id = ? AND reverted = 0 AND message_type = 'plan'
  AND (
    json_extract(metadata, '$.planStatus') IS NULL
    OR json_extract(metadata, '$.planStatus') = 'pending'
  )
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
      'SELECT $_messageColumnsLite, rowid AS _rowid '
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
      'SELECT $_messageColumnsLite, rowid AS _rowid '
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

  /// Full metadata for [ids], so an empty agent turn can contribute its
  /// transcript. Other rows in the side-channel window stay on the lite
  /// select. Empty [ids] does not hit the database.
  Future<List<ConversationMessagesTableData>> messagesByIds(
    List<String> ids,
  ) {
    if (ids.isEmpty) {
      return Future.value(const []);
    }
    final placeholders = List.filled(ids.length, '?').join(', ');
    return customSelect(
      'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
      'WHERE id IN ($placeholders)',
      variables: [for (final id in ids) Variable.withString(id)],
      readsFrom: {conversationMessagesTable},
    ).get().then(
      (rows) => rows
          .map((r) => conversationMessagesTable.map(r.data))
          .toList(growable: false),
    );
  }

  /// Every summary row in a conversation, oldest first, without transcripts.
  ///
  /// Compaction messages, plus legacy system rows whose metadata says
  /// `compacted: true`. The JSON check is only on `system` rows. A summary
  /// whose `compacted` column is set still has to be returned: the verbatim
  /// tail skips that column, and the prompt would otherwise lose the summary.
  String get contextSummarySql =>
      'SELECT $_messageColumnsLite '
      'FROM conversation_messages '
      'WHERE conversation_id = ? AND reverted = 0 AND ('
      "message_type = 'compaction' OR ("
      "message_type = 'system' AND "
      "json_type(metadata, '\$.compacted') = 'true')) "
      'ORDER BY created_at ASC, rowid ASC';

  /// Summaries for [contextSummarySql].
  Future<List<ConversationMessagesTableData>> contextSummaries(
    String conversationId,
  ) => customSelect(
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
  /// message-type index keeps the read off agent turns. `json_extract` runs
  /// only on `steering` rows.
  String get queuedSteeringSql =>
      'SELECT $_messageColumnsLite '
      'FROM conversation_messages INDEXED BY '
      'idx_conversation_messages_messageType '
      "WHERE message_type = 'steering' AND conversation_id = ? "
      'AND space_id = ? AND reverted = 0 AND '
      "json_extract(metadata, '\$.steerState') = 'queued'";

  /// Rows for [queuedSteeringSql]. Order is not delivery order; callers sort
  /// by `steerOrder`.
  Future<List<ConversationMessagesTableData>> queuedSteeringMessages(
    String conversationId,
    String spaceId,
  ) => customSelect(
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
  Future<String?> latestAgentContent(
    String conversationId,
    String agentId,
  ) => customSelect(
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
        'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
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
  Future<void> revertMessages(List<String> ids, int revertedAtMs) async {
    if (ids.isEmpty) {
      return;
    }
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
  }

  /// Clears the reverted flag on the given messages (an unrevert/redo).
  Future<void> unrevertMessages(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await (update(
      conversationMessagesTable,
    )..where((t) => t.id.isIn(ids))).write(
      const ConversationMessagesTableCompanion(
        reverted: Value(false),
        revertedAt: Value(null),
      ),
    );
  }

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

  /// Inserts a participant, ignoring conflicts (prevents duplicates).
  Future<void> insertParticipant(SpaceParticipantsTableCompanion entry) => into(
    spaceParticipantsTable,
  ).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Inserts a message.
  ///
  /// Stamps [ConversationMessagesTable.contentChars],
  /// [ConversationMessagesTable.transcriptChars], and
  /// [ConversationMessagesTable.listMetadata] in the same statement. A
  /// follow-up update would fire the sync trigger a second time and make the
  /// message-list watch run twice per send.
  Future<void> insertMessage(ConversationMessagesTableCompanion entry) {
    final content = entry.content.present ? entry.content.value : '';
    final stamp = _stampMetadataJson(
      entry.metadata.present ? entry.metadata.value : null,
    );
    return into(conversationMessagesTable).insert(
      entry.copyWith(
        contentChars: Value(_sqliteTextLength(content)),
        transcriptChars: Value(stamp.transcriptChars),
        listMetadata: Value(stamp.listMetadata),
      ),
    );
  }

  /// Deletes one message row by id.
  ///
  /// Queue-surgery affordance for steering rows only: they never become the
  /// conversation leaf (`DaoMessagingRepository.insertSteeringMessage` skips
  /// `setLeaf`), so no other row's `parent_message_id` can point at one and
  /// the delete cannot orphan the branch tree. Callers must have validated
  /// the row's type/state.
  Future<void> deleteMessageById(String messageId) => (delete(
    conversationMessagesTable,
  )..where((t) => t.id.equals(messageId))).go();

  /// Deletes one message row by id AND conversation — the ownership-checked
  /// form of `deleteMessageById` so a foreign workspace's row id resolves to
  /// nothing rather than to a hit.
  Future<void> deleteMessageInConversation(
    String conversationId,
    String messageId,
  ) =>
      (delete(conversationMessagesTable)
            ..where((t) => t.id.equals(messageId))
            ..where((t) => t.conversationId.equals(conversationId)))
          .go();

  /// The conversation's current branch tip, or the newest message when the
  /// conversation predates the tree.
  ///
  /// Falls back rather than returning null so an existing conversation joins
  /// the tree on its next message instead of starting a second root beside
  /// its own history.
  Future<String?> currentLeaf(String conversationId) async {
    final row = await (select(
      conversationsTable,
    )..where((t) => t.id.equals(conversationId))).getSingleOrNull();
    final pointer = row?.leafMessageId;
    if (pointer != null && pointer.isNotEmpty) {
      return pointer;
    }
    final newest =
        await (select(conversationMessagesTable)
              ..where((t) => t.conversationId.equals(conversationId))
              ..where((t) => t.reverted.equals(false))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return newest?.id;
  }

  /// Points a conversation at [messageId] (null = the newest message).
  Future<void> setLeaf(String conversationId, String? messageId) =>
      (update(conversationsTable)..where((t) => t.id.equals(conversationId)))
          .write(ConversationsTableCompanion(leafMessageId: Value(messageId)));

  /// Walks from [leafId] back to the root, newest first.
  ///
  /// Depth-capped: a corrupt parent chain that loops would otherwise walk
  /// forever, and a conversation is never legitimately this deep.
  Future<List<ConversationMessagesTableData>> branchFrom(
    String conversationId,
    String leafId, {
    int maxDepth = 10000,
  }) async {
    final all = await (select(
      conversationMessagesTable,
    )..where((t) => t.conversationId.equals(conversationId))).get();
    final byId = {for (final row in all) row.id: row};
    final path = <ConversationMessagesTableData>[];
    final seen = <String>{};
    String? cursor = leafId;
    while (cursor != null && path.length < maxDepth) {
      if (!seen.add(cursor)) {
        break;
      }
      final row = byId[cursor];
      if (row == null) {
        break;
      }
      path.add(row);
      cursor = row.parentMessageId;
    }
    return path.reversed.toList();
  }

  /// Every message in the conversation, whichever branch it is on.
  Future<List<ConversationMessagesTableData>> allMessagesForTree(
    String conversationId,
  ) =>
      (select(conversationMessagesTable)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  /// Updates the updatedAt timestamp for a space.
  Future<void> updateSpaceUpdatedAt(String spaceId, DateTime updatedAt) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(updatedAt: Value(updatedAt)),
      );

  /// Updates the [Mode]-serialized value for a space.
  Future<void> updateSpaceMode(String spaceId, String mode) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(mode: Value(mode)),
      );

  /// Updates the provisioning status for a space. Leaving `provisioning`
  /// also clears the granular step in the same write, so a non-null
  /// `provisioning_step` can never accompany a `ready`/`failed` row.
  Future<void> updateSpaceProvisioningStatus(String spaceId, String status) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(
          provisioningStatus: Value(status),
          provisioningStep: status == 'provisioning'
              ? const Value.absent()
              : const Value(null),
        ),
      );

  /// Updates the granular in-flight provisioning step for a space
  /// (`SpaceProvisioningStep.toDbValue()` JSON, or null to clear).
  Future<void> updateSpaceProvisioningStep(String spaceId, String? step) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(provisioningStep: Value(step)),
      );

  /// This workspace's spaces whose provisioning status equals [status].
  ///
  /// Used by the boot reconciler to re-kick spaces a previous session
  /// stranded in `provisioning` (the flip to ready/failed only ever comes from
  /// the in-flight provisioning future, so a restart mid-provision would leave
  /// them stuck forever). The reconciler visits every workspace's database in
  /// turn, so it reaches all of them without this query spanning any.
  Future<List<SpacesTableData>> spacesByProvisioningStatus(String status) =>
      (select(
        spacesTable,
      )..where((t) => t.provisioningStatus.equals(status))).get();

  /// Updates the content and/or metadata of an existing message.
  ///
  /// When [content] or [metadata] changes, the meter's stored counts are
  /// written in the same statement. A metadata change also rewrites
  /// [ConversationMessagesTable.listMetadata] unless [writeListMetadata] is
  /// false: a tool-only transcript flush still stores the blob (and the
  /// meter counter) but leaves the list projection the feed watches alone.
  /// A content-only edit leaves that column alone. Embedding-only and
  /// revert updates do not come through here, so they do not recompute
  /// those counts.
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    bool writeListMetadata = true,
  }) {
    final meta = metadata;
    final encoded = meta == null ? null : jsonEncode(meta);
    return (update(
      conversationMessagesTable,
    )..where((t) => t.id.equals(messageId))).write(
      ConversationMessagesTableCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        contentChars: content != null
            ? Value(_sqliteTextLength(content))
            : const Value.absent(),
        metadata: encoded != null ? Value(encoded) : const Value.absent(),
        listMetadata: meta == null || !writeListMetadata
            ? const Value.absent()
            : Value(_listMetadataOf(meta, encoded!)),
        transcriptChars: meta != null
            ? Value(_transcriptCharsOf(meta))
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
  /// The hit list is the two lines the search dialog shows, not the
  /// transcript and not the embedding blob. Both used to ride along on
  /// `SELECT m.*` and then get decoded and dropped.
  Future<List<ConversationMessagesTableData>> searchInSpace(
    String spaceId,
    String query, {
    int limit = 50,
  }) {
    final orQuery = toFtsOrQuery(query);
    if (orQuery.isEmpty) {
      return Future.value(const []);
    }
    return customSelect(
      'SELECT ${_liteColumns('m')} FROM conversation_messages m '
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
    ).map((row) => conversationMessagesTable.map(row.data)).get();
  }

  /// Returns the space row by id, or null.
  Future<SpacesTableData?> getSpaceById(String spaceId) => (select(
    spacesTable,
  )..where((t) => t.id.equals(spaceId))).getSingleOrNull();

  /// Returns all participants for a space (for dedup checks).
  Future<List<SpaceParticipantsTableData>> getParticipants(String spaceId) =>
      (select(
        spaceParticipantsTable,
      )..where((t) => t.spaceId.equals(spaceId))).get();

  /// Deletes a space and all its messages and participants.
  ///
  /// The SPACE row goes first and FK `ON DELETE CASCADE` takes the children
  /// with it. Order matters for cost, not correctness: the sync-feed triggers
  /// on the child tables resolve their workspace with
  /// `(SELECT workspace_id FROM spaces WHERE id = OLD.space_id)` and fire
  /// only `WHEN` that is non-null. Deleting children first left the parent in
  /// place, so every one of a 10k-message space's rows ran three statements
  /// plus that subselect and wrote a `sync_changes` row — inside the database's
  /// only write transaction. With the parent gone the guard is false and the
  /// cascade is silent, which is also what delta clients expect: they see the
  /// space's own delete change and cascade child removal locally.
  Future<void> deleteSpaceCascade(String spaceId) => transaction(() async {
    await (delete(spacesTable)..where((t) => t.id.equals(spaceId))).go();
    // Belt and braces for a row whose FK somehow did not cascade (a legacy
    // file created before the constraint, or `foreign_keys` off).
    await (delete(
      conversationMessagesTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
    await (delete(
      spaceParticipantsTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
  });

  /// Updates the space name.
  Future<void> updateSpaceName(String spaceId, String name) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(name: Value(name)),
      );

  /// Stamps (or clears, when [archivedAt] is null) a space's archive time.
  /// `updatedAt` is deliberately untouched: archiving is a hide, not an
  /// activity, so a restored space keeps its recency position in the list.
  Future<void> setSpaceArchived(String spaceId, DateTime? archivedAt) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(archivedAt: Value(archivedAt)),
      );

  /// Sets the space's `no_repos` flag — the only way "explicitly no repos"
  /// is expressible, since zero `space_repos` rows already means "all repos".
  Future<void> updateSpaceNoRepos(String spaceId, bool noRepos) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(noRepos: Value(noRepos)),
      );

  /// Deletes all messages in a space.
  Future<void> clearSpaceMessages(String spaceId) => (delete(
    conversationMessagesTable,
  )..where((t) => t.spaceId.equals(spaceId))).go();

  /// Removes a single participant (agent or user) from a space.
  Future<void> removeParticipant(String spaceId, String principalId) =>
      (delete(spaceParticipantsTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..where((t) => t.principalId.equals(principalId)))
          .go();

  /// Updates [userId]'s read cursor on [spaceId] to now. Idempotent and
  /// cheap (a single write against that user's participant row). Lazily
  /// creates the row the first time a user opens a space they weren't an
  /// original participant of (hidden/pipeline spaces). Powers the sidebar
  /// unread indicator: once set, agent messages newer than this timestamp are
  /// "seen" only until another lands.
  Future<void> markSpaceRead(String spaceId, String userId) async {
    final updated =
        await (update(spaceParticipantsTable)..where(
              (t) =>
                  t.spaceId.equals(spaceId) &
                  t.participantType.equals('user') &
                  t.principalId.equals(userId),
            ))
            .write(
              SpaceParticipantsTableCompanion(
                lastReadAt: Value(DateTime.now()),
              ),
            );
    if (updated == 0) {
      await into(spaceParticipantsTable).insert(
        SpaceParticipantsTableCompanion(
          id: Value('$spaceId-user-$userId'),
          spaceId: Value(spaceId),
          principalId: Value(userId),
          participantType: const Value('user'),
          lastReadAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Watches [userId]'s read cursor on [spaceId], or null when no row
  /// exists yet / it has never been set.
  Stream<DateTime?> watchUserLastReadAt(String spaceId, String userId) {
    return (select(spaceParticipantsTable)..where(
          (t) =>
              t.spaceId.equals(spaceId) &
              t.participantType.equals('user') &
              t.principalId.equals(userId),
        ))
        .watchSingleOrNull()
        .map((row) => row?.lastReadAt);
  }

  /// Updates the embedding blob for a message.
  Future<void> updateMessageEmbedding(String id, Uint8List embedding) =>
      (update(conversationMessagesTable)..where((t) => t.id.equals(id))).write(
        ConversationMessagesTableCompanion(embedding: Value(embedding)),
      );

  /// Watches all (non-reverted) messages in a space, across every conversation
  /// it holds, in creation order. Streaming twin of [getMessagesForSpace].
  Stream<List<ConversationMessagesTableData>> watchMessagesForSpace(
    String spaceId,
  ) =>
      customSelect(
        'SELECT $_messageColumnsLite FROM conversation_messages '
        'WHERE space_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(spaceId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

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
        'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
        'WHERE space_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(spaceId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Messages in a space that have embeddings, ordered by creation.
  ///
  /// Semantic ranking needs the vector and the text, not the transcript.
  /// `list_metadata` stands in for `metadata`, so a space full of embedded
  /// turns does not pull every `segments` blob into the score loop.
  Future<List<ConversationMessagesTableData>> getMessagesWithEmbedding(
    String spaceId,
  ) => customSelect(
    'SELECT $_messageColumnsLite, embedding FROM conversation_messages '
    'WHERE space_id = ? AND embedding IS NOT NULL AND reverted = 0 '
    'ORDER BY created_at ASC, rowid ASC',
    variables: [Variable.withString(spaceId)],
    readsFrom: {conversationMessagesTable},
  ).get().then(
    (rows) => rows
        .map((r) => conversationMessagesTable.map(r.data))
        .toList(growable: false),
  );

  /// This workspace's messages with a NULL embedding, limited for batch
  /// processing.
  ///
  /// The startup embedding backfill must reach every workspace's un-embedded
  /// messages, which it does by visiting each workspace's database in turn —
  /// each embedding is then written back to the file its message came from.
  Future<List<ConversationMessagesTableData>> getMessagesWithoutEmbedding({
    int limit = 200,
  }) =>
      (select(conversationMessagesTable)
            ..where((t) => t.embedding.isNull())
            ..where(
              (t) =>
                  t.messageType.isIn([
                    'text',
                    'system',
                    'agent_turn',
                    'compaction',
                  ]) &
                  t.compacted.equals(false),
            )
            ..limit(limit))
          .get();
}
