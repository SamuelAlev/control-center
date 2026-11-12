part of 'messaging_dao.dart';

/// The `conversation_activity` rows: one per conversation with live
/// messages.
///
/// Every write that changes what a row summarizes adjusts it inside the same
/// transaction: an insert folds the new message in, and the rarer writes
/// (revert, unrevert, delete, answering) recompute the affected
/// conversations from their messages.
mixin _ConversationActivity
    on DatabaseAccessor<WorkspaceDatabase>, _$MessagingDaoMixin {
  /// Recomputes the activity rows of [conversationIds] from their messages.
  /// A conversation left with no live message ends up with no row.
  Future<void> rebuildConversationActivity(Iterable<String> conversationIds) =>
      transaction(() async {
        for (final id in conversationIds.toSet()) {
          await customUpdate(
            'DELETE FROM conversation_activity WHERE conversation_id = ?',
            variables: [Variable.withString(id)],
            updates: {conversationActivityTable},
            updateKind: UpdateKind.delete,
          );
          await customInsert(
            MessagingDao.rebuildActivitySql,
            variables: [Variable.withString(id)],
            updates: {conversationActivityTable},
          );
        }
      });

  /// Folds the just-inserted message [messageId] into its conversation's
  /// activity row: maxima move forward, an open question adds one.
  ///
  /// A conversation with no row yet is recomputed whole instead. That is a
  /// new conversation (one message to read) or one written before this table
  /// existed, which a fold would describe from the new message alone.
  Future<void> _foldInsertIntoActivity(String messageId) async {
    final message = await customSelect(
      'SELECT conversation_id, created_at, rowid AS seq, sender_type, '
      'message_type, answered, reverted '
      'FROM conversation_messages WHERE id = ?',
      variables: [Variable.withString(messageId)],
      readsFrom: {conversationMessagesTable},
    ).getSingleOrNull();
    if (message == null || message.read<bool>('reverted')) {
      return;
    }
    final conversationId = message.read<String>('conversation_id');
    final isAgent = message.read<String>('sender_type') != 'user';
    final isOpenQuestion =
        message.read<String>('message_type') == 'user_question' &&
        !message.read<bool>('answered');
    final folded = await customUpdate(
      'UPDATE conversation_activity SET '
      'last_message_at = MAX(last_message_at, ?1), '
      'last_agent_message_at = CASE WHEN $_newestAgentCondition '
      'THEN ?1 ELSE last_agent_message_at END, '
      'last_agent_message_seq = CASE WHEN $_newestAgentCondition '
      'THEN ?2 ELSE last_agent_message_seq END, '
      'open_question_count = open_question_count + ?4 '
      'WHERE conversation_id = ?5',
      variables: [
        Variable.withInt(message.read<int>('created_at')),
        Variable.withInt(message.read<int>('seq')),
        Variable.withBool(isAgent),
        Variable.withInt(isOpenQuestion ? 1 : 0),
        Variable.withString(conversationId),
      ],
      updates: {conversationActivityTable},
      updateKind: UpdateKind.update,
    );
    if (folded == 0) {
      await rebuildConversationActivity([conversationId]);
    }
  }

  /// Whether the folded message (`?1` time, `?2` seq, `?3` non-human) is
  /// newer than the row's current newest non-human message. Every SET term
  /// reads the row as it was, so both CASEs see the same answer.
  static const _newestAgentCondition =
      '?3 AND (last_agent_message_at IS NULL OR ?1 > last_agent_message_at '
      'OR (?1 = last_agent_message_at AND ?2 > last_agent_message_seq))';

  /// Recounts open questions from the open-question index: for the
  /// conversation of [messageId], or for every row when it is null.
  Future<void> _recountOpenQuestions({String? messageId}) => customUpdate(
    'UPDATE conversation_activity SET open_question_count = '
    '(SELECT COUNT(*) FROM conversation_messages q '
    'WHERE q.conversation_id = conversation_activity.conversation_id '
    "AND q.message_type = 'user_question' AND q.answered = 0 "
    'AND q.reverted = 0)'
    '${messageId == null ? '' : ' WHERE conversation_id = (SELECT conversation_id FROM conversation_messages WHERE id = ?)'}',
    variables: [if (messageId != null) Variable.withString(messageId)],
    updates: {conversationActivityTable},
    updateKind: UpdateKind.update,
  );

  /// The distinct conversations holding [messageIds].
  Future<List<String>> _conversationsOf(List<String> messageIds) =>
      (selectOnly(conversationMessagesTable, distinct: true)
            ..addColumns([conversationMessagesTable.conversationId])
            ..where(conversationMessagesTable.id.isIn(messageIds)))
          .map((row) => row.read(conversationMessagesTable.conversationId)!)
          .get();

  /// Creates the activity rows missing for conversations that hold live
  /// messages, once per database handle.
  ///
  /// A converged file starts with an empty `conversation_activity` beside
  /// its existing messages. Writes only fill the conversations they touch,
  /// so the first read fills the rest; after that every row is kept exact by
  /// the write path.
  Future<void> _fillMissingActivity() => _activityFilled ??= transaction(
    () async {
      final missing = await customSelect(
        'SELECT DISTINCT m.conversation_id AS id FROM conversation_messages m '
        'WHERE m.reverted = 0 AND NOT EXISTS (SELECT 1 FROM '
        'conversation_activity a WHERE a.conversation_id = m.conversation_id)',
        readsFrom: {conversationMessagesTable, conversationActivityTable},
      ).get();
      await rebuildConversationActivity([
        for (final row in missing) row.read<String>('id'),
      ]);
    },
  );

  Future<void>? _activityFilled;

  Future<void> _fillMissingActivityOnce() =>
      _fillMissingActivity().catchError((Object error, StackTrace stack) {
        // A failed fill is retried by the next reader, not remembered.
        _activityFilled = null;
        Error.throwWithStackTrace(error, stack);
      });

  /// Watches per-conversation activity signals for one workspace: newest
  /// message time, the position of the newest agent message (the unread-dot
  /// signal) and the open (unanswered) agent-question count (the needs-input
  /// signal).
  ///
  /// Archived spaces are excluded: an archived space's row is gone from the
  /// sidebar, so its unread/needs-input signals would have no visible home —
  /// and a hidden room must not keep demanding attention.
  Stream<
    List<
      ({
        String spaceId,
        String conversationId,
        DateTime lastMessageAt,
        FeedPosition? lastAgentMessage,
        int openQuestionCount,
      })
    >
  >
  watchSpaceActivity(String workspaceId) =>
      Stream.fromFuture(_fillMissingActivityOnce()).asyncExpand(
        (_) =>
            customSelect(
              MessagingDao.spaceActivitySql,
              variables: [Variable.withString(workspaceId)],
              readsFrom: {
                conversationActivityTable,
                spacesTable,
                conversationsTable,
              },
            ).watch().map(
              (rows) => [
                for (final row in rows)
                  (
                    spaceId: row.read<String>('space_id'),
                    conversationId: row.read<String>('conversation_id'),
                    lastMessageAt: _fromSeconds(
                      row.read<int>('last_message_at'),
                    ),
                    lastAgentMessage: _positionOf(
                      row.readNullable<int>('last_agent_message_at'),
                      row.readNullable<int>('last_agent_message_seq'),
                    ),
                    openQuestionCount: row.read<int>('open_question_count'),
                  ),
              ],
            ),
      );
}

DateTime _fromSeconds(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

FeedPosition? _positionOf(int? seconds, int? seq) =>
    seconds == null || seq == null
    ? null
    : FeedPosition(at: _fromSeconds(seconds), seq: seq);
