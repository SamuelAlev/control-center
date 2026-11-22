import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
import 'package:drift/drift.dart';

/// The bounded reads behind `DaoTranscriptStore`: a conversation's live
/// messages and a transcript's segments by position, without their text,
/// and one stretch of one row's text. Each statement returns at most the
/// rows its `LIMIT` names, or one row; texts are cut by SQLite (`substr`
/// counts code points), so no read materialises a whole conversation or a
/// whole tool output.
extension TranscriptPageQueries on RunTranscriptDao {
  /// A segment's row text: a text segment's text, a tool call's
  /// `input: <json>\noutput: <output>`, an error's message; NULL for any
  /// other segment.
  static const String rowTextSql =
      "CASE json_extract(s.body, '\$.type') "
      "WHEN 'text' THEN coalesce(json_extract(s.body, '\$.text'), '') "
      "WHEN 'tool' THEN 'input: ' || "
      "coalesce(json_extract(s.body, '\$.inputs'), '{}') || char(10) || "
      "'output: ' || coalesce(json_extract(s.body, '\$.outputs'), '') "
      "WHEN 'error' THEN coalesce(json_extract(s.body, '\$.message'), '') "
      'END';

  /// How many live messages [conversationId] holds.
  Future<int> liveMessageCount(String conversationId) async {
    final row = await customSelect(
      'SELECT count(*) AS n FROM conversation_messages '
      'WHERE conversation_id = ? AND reverted = 0',
      variables: [Variable.withString(conversationId)],
    ).getSingle();
    return row.read<int>('n');
  }

  /// Columns of [pageMessages]. Content is never read into the result,
  /// only its length; whether the message expands into its transcript's
  /// segments is one probe of `idx_transcripts_message_id` and the
  /// segments' primary key.
  static const String _pageColumns =
      'SELECT m.id, m.rowid AS row_id, m.message_type, m.sender_type, '
      "m.sender_id, json_extract(m.list_metadata, '\$.runId') AS run_id, "
      'm.compacted, m.created_at, length(m.content) AS text_length, '
      '(m.message_type = ? AND EXISTS (SELECT 1 FROM transcripts t '
      'JOIN transcript_segments s ON s.transcript_id = t.id '
      'WHERE t.message_id = m.id)) AS has_segments '
      'FROM conversation_messages m '
      'WHERE m.conversation_id = ? AND m.reverted = 0 ';

  /// At most [limit] live messages of [conversationId], oldest first, from
  /// the place [from] (a stored `created_at` and a row id) on: every
  /// message whose pair is not less than it, so a message deleted or
  /// reverted there since moves nothing. From the first when null.
  /// [agentTurn] is the stored type whose transcript expands.
  Future<List<QueryRow>> pageMessages({
    required String conversationId,
    required String agentTurn,
    required ({int orderAt, int rowId})? from,
    required int limit,
  }) => customSelect(
    '$_pageColumns'
    '${from == null ? '' : 'AND (m.created_at, m.rowid) >= (?, ?) '}'
    'ORDER BY m.created_at ASC, m.rowid ASC LIMIT ?',
    variables: [
      Variable.withString(agentTurn),
      Variable.withString(conversationId),
      if (from != null) ...[
        Variable.withInt(from.orderAt),
        Variable.withInt(from.rowId),
      ],
      Variable.withInt(limit),
    ],
  ).get();

  /// The transcript a segment read starts from: a message's or a run's.
  static String _owner({required bool run}) => run
      ? 'SELECT id FROM transcripts WHERE run_id = ?'
      : 'SELECT id FROM transcripts WHERE message_id = ?';

  /// At most [limit] row segments (a visible text, a tool call, an error)
  /// of the transcript of message [ownerId] (or of run [ownerId] when [run])
  /// with `seq >= fromSeq` and a type in [types], in order, without their
  /// text. [types] and [tools] filter in the statement.
  Future<List<QueryRow>> pageSegments({
    required String ownerId,
    required bool run,
    required int fromSeq,
    required int limit,
    required List<String> types,
    required List<String>? tools,
  }) {
    final typeFilter =
        "AND json_extract(s.body, '\$.type') IN "
        '(${List.filled(types.length, '?').join(', ')}) '
        "AND NOT (json_extract(s.body, '\$.type') = 'text' AND "
        "trim(coalesce(json_extract(s.body, '\$.text'), '')) = '') ";
    final toolFilter = tools == null
        ? ''
        : "AND json_extract(s.body, '\$.type') = 'tool' "
              "AND json_extract(s.body, '\$.toolName') IN "
              '(${List.filled(tools.length, '?').join(', ')}) ';
    return customSelect(
      "SELECT s.seq, json_extract(s.body, '\$.type') AS type, "
      "json_extract(s.body, '\$.toolName') AS tool, "
      "json_extract(s.body, '\$.ts') AS ts, "
      "json_extract(s.body, '\$.prunedAt') IS NOT NULL AS pruned "
      'FROM transcript_segments s '
      'WHERE s.transcript_id = (${_owner(run: run)}) AND s.seq >= ? '
      '$typeFilter$toolFilter'
      'ORDER BY s.seq LIMIT ?',
      variables: [
        Variable.withString(ownerId),
        Variable.withInt(fromSeq),
        for (final type in types) Variable.withString(type),
        for (final tool in tools ?? const <String>[]) Variable.withString(tool),
        Variable.withInt(limit),
      ],
    ).get();
  }

  /// [chars] code points from [from] of message [messageId]'s content, when
  /// it is a live message of [conversationId], with the content's length.
  Future<QueryRow?> messageStretch({
    required String conversationId,
    required String messageId,
    required int from,
    required int chars,
  }) => customSelect(
    'SELECT substr(content, ?, ?) AS text, length(content) AS length '
    'FROM conversation_messages '
    'WHERE id = ? AND conversation_id = ? AND reverted = 0',
    variables: [
      Variable.withInt(from + 1),
      Variable.withInt(chars),
      Variable.withString(messageId),
      Variable.withString(conversationId),
    ],
  ).getSingleOrNull();

  /// [chars] code points from [from] of segment [seq]'s row text
  /// ([rowTextSql]) in the transcript of message [ownerId] (or run [ownerId]
  /// when [run]), with its length and, for a tool call, the marks of a cut
  /// output: [markChars] code points from the first `read_output(handle: "`
  /// (`handle_mark`), and whether it says `(original not stored)]` or ends a
  /// script call's preview with `<digits> bytes, truncated]` (`lost_mark`).
  /// A message must be a live one of [conversationId].
  Future<QueryRow?> segmentStretch({
    required String ownerId,
    required bool run,
    required String? conversationId,
    required int seq,
    required int from,
    required int chars,
    required int markChars,
  }) => customSelect(
    'SELECT substr(r.text, ?, ?) AS text, length(r.text) AS length, '
    'CASE WHEN r.type = ? AND instr(r.outputs, \'read_output(handle: "\') > 0 '
    'THEN substr(r.outputs, instr(r.outputs, \'read_output(handle: "\'), ?) '
    'END AS handle_mark, '
    "(r.type = 'tool' AND (instr(r.outputs, '(original not stored)]') > 0 OR "
    "(instr(r.outputs, ' bytes, truncated]') > 1 AND substr(r.outputs, "
    "instr(r.outputs, ' bytes, truncated]') - 1, 1) GLOB '[0-9]'))) "
    'AS lost_mark '
    'FROM (SELECT $rowTextSql AS text, '
    "json_extract(s.body, '\$.type') AS type, "
    "coalesce(json_extract(s.body, '\$.outputs'), '') AS outputs "
    'FROM transcript_segments s '
    'WHERE s.transcript_id = (${_owner(run: run)}) AND s.seq = ? '
    '${run ? '' : 'AND EXISTS (SELECT 1 FROM conversation_messages m '
              'WHERE m.id = ? AND m.conversation_id = ? AND m.reverted = 0) '}'
    ') r WHERE r.text IS NOT NULL',
    variables: [
      Variable.withInt(from + 1),
      Variable.withInt(chars),
      Variable.withString('tool'),
      Variable.withInt(markChars),
      Variable.withString(ownerId),
      Variable.withInt(seq),
      if (!run) ...[
        Variable.withString(ownerId),
        Variable.withString(conversationId ?? ''),
      ],
    ],
  ).getSingleOrNull();

  /// When run [runId]'s own transcript started, or null.
  Future<DateTime?> runTranscriptStartedAt(String runId) async {
    final row = await customSelect(
      'SELECT started_at FROM transcripts WHERE run_id = ?',
      variables: [Variable.withString(runId)],
    ).getSingleOrNull();
    return row?.read<DateTime>('started_at');
  }
}
