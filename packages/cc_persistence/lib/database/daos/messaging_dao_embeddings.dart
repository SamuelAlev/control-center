part of 'messaging_dao.dart';

/// Message vectors, kept in `conversation_message_embeddings` beside the
/// message rows.
mixin _MessageEmbeddings
    on DatabaseAccessor<WorkspaceDatabase>, _$MessagingDaoMixin {
  /// Stores [embedding] as message [id]'s vector, replacing one it had.
  ///
  /// Writes only the side row: the message row, and with it the full-text
  /// index and every message watch, are left alone.
  Future<void> updateMessageEmbedding(String id, Uint8List embedding) =>
      into(conversationMessageEmbeddingsTable).insertOnConflictUpdate(
        ConversationMessageEmbeddingsTableCompanion.insert(
          messageId: id,
          embedding: embedding,
        ),
      );

  /// Messages in a space that have embeddings, ordered by creation, each
  /// with its vector.
  Future<List<({ConversationMessagesTableData data, Uint8List embedding})>>
  getMessagesWithEmbedding(String spaceId) =>
      customSelect(
        'SELECT m.*, e.embedding AS embedding_vector '
        'FROM conversation_messages m '
        'JOIN conversation_message_embeddings e ON e.message_id = m.id '
        'WHERE m.space_id = ? AND m.reverted = 0 '
        'ORDER BY m.created_at ASC, m.rowid ASC',
        variables: [Variable.withString(spaceId)],
        readsFrom: {
          conversationMessagesTable,
          conversationMessageEmbeddingsTable,
        },
      ).get().then(
        (rows) => [
          for (final row in rows)
            (
              data: conversationMessagesTable.map(row.data),
              embedding: row.read<Uint8List>('embedding_vector'),
            ),
        ],
      );

  /// This workspace's next [limit] messages that have no embedding yet, in
  /// rowid order after the position [after] (0 to start), each with the
  /// position to continue from.
  Future<List<({int position, String id, String content})>> messagesToEmbed({
    required int after,
    int limit = 64,
  }) =>
      customSelect(
        MessagingDao.messagesToEmbedSql,
        variables: [Variable.withInt(after), Variable.withInt(limit)],
        readsFrom: {
          conversationMessagesTable,
          conversationMessageEmbeddingsTable,
        },
      ).get().then(
        (rows) => [
          for (final row in rows)
            (
              position: row.read<int>('position'),
              id: row.read<String>('id'),
              content: row.read<String>('content'),
            ),
        ],
      );

  /// Stores backfilled vectors and returns how many were stored: each only
  /// when its message still holds the `content` the vector was computed from
  /// and has no vector yet.
  ///
  /// A message that was edited, deleted or embedded by its own writer while
  /// the batch was being embedded is skipped: the newer vector wins, and a
  /// missing message is zero rows rather than a foreign-key failure.
  Future<int> putBackfilledEmbeddings(
    List<({String messageId, String content, Uint8List embedding})> embeddings,
  ) => transaction(() async {
    var stored = 0;
    for (final e in embeddings) {
      stored += await customUpdate(
        'INSERT INTO conversation_message_embeddings (message_id, embedding) '
        'SELECT id, ? FROM conversation_messages '
        'WHERE id = ? AND content = ? '
        'ON CONFLICT (message_id) DO NOTHING',
        variables: [
          Variable<Uint8List>(e.embedding),
          Variable<String>(e.messageId),
          Variable<String>(e.content),
        ],
        updates: {conversationMessageEmbeddingsTable},
        updateKind: UpdateKind.insert,
      );
    }
    return stored;
  });
}
