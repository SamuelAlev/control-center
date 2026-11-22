import 'package:drift/drift.dart';

/// One person's read cursor in one conversation: the position of the newest
/// message they had seen when they last read it down to the end.
///
/// The sidebar's unread state is computed from these and the per-conversation
/// activity: a conversation is unread when its newest agent message is after
/// the reader's cursor, or when the reader has no cursor there yet. A space
/// keeps no read state of its own; it is unread when one of its listed
/// conversations is.
@TableIndex(name: 'idx_conversation_reads_userId', columns: {#userId})
class ConversationReadsTable extends Table {
  /// The conversation this cursor reads.
  TextColumn get conversationId => text().customConstraint(
    'NOT NULL REFERENCES conversations (id) ON DELETE CASCADE',
  )();

  /// The person whose cursor this is.
  TextColumn get userId => text()();

  /// `created_at` of the newest message they had seen.
  DateTimeColumn get lastReadAt => dateTime()();

  /// `rowid` of that message (0 when the conversation had none), so the
  /// cursor is the pair `(lastReadAt, lastReadSeq)`. `created_at` has
  /// whole-second resolution: a message landing later in the same second
  /// as the read compares after it by this column, not before.
  IntColumn get lastReadSeq => integer()();

  @override
  String get tableName => 'conversation_reads';

  @override
  Set<Column> get primaryKey => {conversationId, userId};
}
