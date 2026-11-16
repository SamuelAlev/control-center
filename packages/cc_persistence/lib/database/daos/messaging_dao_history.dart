part of 'messaging_dao.dart';

/// A conversation's history beyond the feed's live window: the outline of
/// every message (stored sizes, no content) and the range of messages around
/// an anchor, kept current.
extension MessagingDaoHistory on MessagingDao {
  /// Statement behind [conversationOutline].
  ///
  /// Public so a test can `EXPLAIN QUERY PLAN` the exact text. Every message
  /// column it names is in `idx_conversation_messages_outline`, so the read
  /// never touches a message row (whose content can run to overflow pages).
  /// The planner would rather walk `(conversation_id, created_at)` and skip
  /// sorting a second's ties by rowid, not knowing the rows are large, so the
  /// index is named; `revision >= 0` is the index's own fence term;
  /// the transcript facts come off the small `transcripts` row by its
  /// message index. `space_id` is an authorization predicate, as in
  /// [getMessagePageRows].
  static const conversationOutlineSql =
      'SELECT m.id, m.created_at, m.sender_id, m.sender_type, '
      'm.message_type, m.content_chars, '
      'CASE WHEN t.complete THEN t.segment_count END AS finished_segment_count, '
      'm.steer_state, m.answered, m.revision '
      'FROM conversation_messages m '
      'INDEXED BY idx_conversation_messages_outline '
      'LEFT JOIN transcripts t ON t.message_id = m.id '
      'WHERE m.conversation_id = ? AND m.space_id = ? AND m.reverted = 0 '
      'AND m.revision >= 0 '
      'ORDER BY m.created_at ASC, m.rowid ASC';

  /// Every live message of [conversationId] in [spaceId] as stored values,
  /// oldest first: what the feed's outline needs to place and size each
  /// row.
  Future<List<ConversationOutlineRow>> conversationOutline(
    String spaceId,
    String conversationId,
  ) => customSelect(
    conversationOutlineSql,
    variables: [
      Variable.withString(conversationId),
      Variable.withString(spaceId),
    ],
    readsFrom: {conversationMessagesTable},
  ).map(_outlineRow).get();

  ConversationOutlineRow _outlineRow(QueryRow row) => (
    id: row.read<String>('id'),
    createdAt: row.read<DateTime>('created_at'),
    senderId: row.read<String>('sender_id'),
    senderType: row.read<String>('sender_type'),
    messageType: row.read<String>('message_type'),
    contentChars: row.read<int>('content_chars'),
    segmentCount: row.readNullable<int>('finished_segment_count'),
    steerState: row.readNullable<String>('steer_state'),
    answered: row.read<bool>('answered'),
    revision: row.read<int>('revision'),
  );

  /// Where a live message of [conversationId] in [spaceId] sits in the
  /// conversation's `(created_at, rowid)` order, or null when there is no
  /// such message: missing, reverted, or another conversation's.
  Future<({int createdAtSeconds, int rowid})?> messagePosition(
    String spaceId,
    String conversationId,
    String messageId,
  ) async {
    final row = await customSelect(
      'SELECT created_at, rowid AS _rowid FROM conversation_messages '
      'WHERE id = ? AND conversation_id = ? AND space_id = ? AND reverted = 0',
      variables: [
        Variable.withString(messageId),
        Variable.withString(conversationId),
        Variable.withString(spaceId),
      ],
      readsFrom: {conversationMessagesTable},
    ).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (
      createdAtSeconds: row.read<int>('created_at'),
      rowid: row.read<int>('_rowid'),
    );
  }

  /// Statement behind [watchMessagesRange]: the messages before the anchor
  /// (`_older = 1`, newest first, up to the limit) and from it on
  /// (`_older = 0`, oldest first, up to the limit), as one statement so one
  /// write re-runs it once.
  static const messagesRangeSql =
      'SELECT * FROM ('
      'SELECT ${MessagingDao.listedMessageColumns}, m.rowid AS _rowid, 1 AS _older '
      '${MessagingDao.listedMessagesFrom}'
      'WHERE m.space_id = ? AND m.conversation_id = ? AND m.reverted = 0 '
      'AND (m.created_at < ? OR (m.created_at = ? AND m.rowid < ?)) '
      'ORDER BY m.created_at DESC, m.rowid DESC LIMIT ?) '
      'UNION ALL '
      'SELECT * FROM ('
      'SELECT ${MessagingDao.listedMessageColumns}, m.rowid AS _rowid, 0 AS _older '
      '${MessagingDao.listedMessagesFrom}'
      'WHERE m.space_id = ? AND m.conversation_id = ? AND m.reverted = 0 '
      'AND (m.created_at > ? OR (m.created_at = ? AND m.rowid >= ?)) '
      'ORDER BY m.created_at ASC, m.rowid ASC LIMIT ?)';

  /// Watches the messages around [anchor] in [conversationId] (scoped to
  /// [spaceId]): the anchor itself, up to [before] older and up to [after]
  /// newer, ascending by `(created_at, rowid)`.
  ///
  /// Keyset on the anchor's position rather than its row, so a message
  /// written in the anchor's second lands on the right side of it, and a
  /// range whose anchor is reverted while watched keeps its place. Each side
  /// reads one row past its limit to tell whether the conversation continues
  /// (`hasOlder` / `hasNewer`).
  Stream<({List<ListedMessageRow> rows, bool hasOlder, bool hasNewer})>
  watchMessagesRange(
    String spaceId,
    String conversationId, {
    required ({int createdAtSeconds, int rowid}) anchor,
    required int before,
    required int after,
  }) {
    final scope = [
      Variable.withString(spaceId),
      Variable.withString(conversationId),
      Variable.withInt(anchor.createdAtSeconds),
      Variable.withInt(anchor.createdAtSeconds),
      Variable.withInt(anchor.rowid),
    ];
    return customSelect(
      messagesRangeSql,
      variables: [
        ...scope,
        Variable.withInt(before + 1),
        ...scope,
        // The anchor, [after] newer, and one more to see past the edge.
        Variable.withInt(after + 2),
      ],
      readsFrom: {conversationMessagesTable},
    ).watch().map((result) {
      final older = <({ListedMessageRow listed, int rowid})>[];
      final rest = <({ListedMessageRow listed, int rowid})>[];
      for (final row in result) {
        final entry = (listed: _listed(row), rowid: row.read<int>('_rowid'));
        (row.read<int>('_older') == 1 ? older : rest).add(entry);
      }
      int byPosition(
        ({ListedMessageRow listed, int rowid}) a,
        ({ListedMessageRow listed, int rowid}) b,
      ) {
        final byTime = a.listed.data.createdAt.compareTo(
          b.listed.data.createdAt,
        );
        return byTime != 0 ? byTime : a.rowid.compareTo(b.rowid);
      }

      older.sort(byPosition);
      rest.sort(byPosition);
      final hasOlder = older.length > before;
      final anchorRow = rest.isNotEmpty && rest.first.rowid == anchor.rowid
          ? rest.first
          : null;
      final newer = anchorRow == null ? rest : rest.sublist(1);
      final hasNewer = newer.length > after;
      return (
        rows: [
          for (final e
              in hasOlder ? older.sublist(older.length - before) : older)
            e.listed,
          ?anchorRow?.listed,
          for (final e in hasNewer ? newer.sublist(0, after) : newer) e.listed,
        ],
        hasOlder: hasOlder,
        hasNewer: hasNewer,
      );
    });
  }
}
