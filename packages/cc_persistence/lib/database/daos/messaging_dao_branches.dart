part of 'messaging_dao.dart';

/// A conversation's message tree: its current tip, the path from a leaf
/// back to the root, and every node for the navigator.
mixin _MessageBranches
    on DatabaseAccessor<WorkspaceDatabase>, _$MessagingDaoMixin {
  /// The conversation's current branch tip, or null when it has none.
  Future<String?> currentLeaf(String conversationId) async {
    final row = await (select(
      conversationsTable,
    )..where((t) => t.id.equals(conversationId))).getSingleOrNull();
    final pointer = row?.leafMessageId;
    return pointer == null || pointer.isEmpty ? null : pointer;
  }

  /// Points a conversation at [messageId] (null = no tip).
  Future<void> setLeaf(String conversationId, String? messageId) =>
      (update(conversationsTable)..where((t) => t.id.equals(conversationId)))
          .write(ConversationsTableCompanion(leafMessageId: Value(messageId)));

  /// Ids on the path from [leafId] back to the root, oldest first.
  ///
  /// Depth-capped: a corrupt parent chain that loops would otherwise walk
  /// forever, and a conversation is never legitimately this deep.
  Future<List<String>> branchIds(
    String conversationId,
    String leafId, {
    int maxDepth = 10000,
  }) async {
    final rows = await customSelect(
      '${MessagingDao.branchSql}SELECT id FROM branch ORDER BY depth ASC',
      variables: [
        Variable.withString(conversationId),
        Variable.withString(leafId),
        Variable.withInt(maxDepth - 1),
      ],
      readsFrom: {conversationMessagesTable},
    ).get();
    final seen = <String>{};
    final path = <String>[];
    for (final row in rows) {
      final id = row.read<String>('id');
      if (!seen.add(id)) {
        break;
      }
      path.add(id);
    }
    return path.reversed.toList();
  }

  /// The messages on the path from [leafId] back to the root, oldest first.
  ///
  /// Forking copies exactly these rows. Same depth cap as [branchIds].
  Future<List<ConversationMessagesTableData>> branchFrom(
    String conversationId,
    String leafId, {
    int maxDepth = 10000,
  }) async {
    final rows = await customSelect(
      '${MessagingDao.branchSql}SELECT m.*, branch.depth AS _depth '
      'FROM branch JOIN conversation_messages m ON m.id = branch.id '
      'ORDER BY branch.depth ASC',
      variables: [
        Variable.withString(conversationId),
        Variable.withString(leafId),
        Variable.withInt(maxDepth - 1),
      ],
      readsFrom: {conversationMessagesTable},
    ).get();
    final seen = <String>{};
    final path = <ConversationMessagesTableData>[];
    for (final row in rows) {
      final message = conversationMessagesTable.map(row.data);
      if (!seen.add(message.id)) {
        break;
      }
      path.add(message);
    }
    return path.reversed.toList();
  }

  /// Every message in the conversation, whichever branch it is on, as the
  /// tree navigator draws it: identity, lineage, sender, a content prefix
  /// and time. Oldest first.
  Future<
    List<
      ({
        String id,
        String? parentMessageId,
        String senderType,
        String senderId,
        String contentHead,
        DateTime createdAt,
      })
    >
  >
  treeNodes(String conversationId) =>
      customSelect(
        'SELECT id, parent_message_id, sender_type, sender_id, '
        'substr(content, 1, ${MessagingDao.treePreviewSourceChars}) AS content_head, created_at '
        'FROM conversation_messages WHERE conversation_id = ? '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => [
          for (final row in rows)
            (
              id: row.read<String>('id'),
              parentMessageId: row.readNullable<String>('parent_message_id'),
              senderType: row.read<String>('sender_type'),
              senderId: row.read<String>('sender_id'),
              contentHead: row.read<String>('content_head'),
              createdAt: _fromSeconds(row.read<int>('created_at')),
            ),
        ],
      );
}
