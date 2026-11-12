import 'package:drift/drift.dart';

/// One row per conversation that holds at least one live (not reverted)
/// message: the signals the sidebar reads, kept current by the message write
/// path in the same transaction as the write that changes them.
///
/// The sidebar watch used to aggregate `conversation_messages` for the whole
/// workspace, and it re-ran on every transcript flush of a streaming turn.
/// Flushes update a message; they never change these columns, so the watch
/// now reads this table and does not run for them at all.
///
/// A conversation without a row has no live messages, or predates this table
/// in a converged file; `MessagingDao` fills those from the messages before
/// the first read and before the first write that would adjust one.
@TableIndex(name: 'idx_conversation_activity_spaceId', columns: {#spaceId})
class ConversationActivityTable extends Table {
  /// The conversation these signals describe.
  TextColumn get conversationId => text().customConstraint(
    'NOT NULL REFERENCES conversations (id) ON DELETE CASCADE',
  )();

  /// The space that owns the conversation.
  TextColumn get spaceId => text().customConstraint(
    'NOT NULL REFERENCES spaces (id) ON DELETE CASCADE',
  )();

  /// `created_at` of the newest live message.
  DateTimeColumn get lastMessageAt => dateTime()();

  /// `created_at` of the newest live message not sent by a person (agent
  /// output and server notices), or null when there is none.
  DateTimeColumn get lastAgentMessageAt => dateTime().nullable()();

  /// `rowid` of that message: with [lastAgentMessageAt] it is the position
  /// a read cursor compares against, since several messages share a second.
  IntColumn get lastAgentMessageSeq => integer().nullable()();

  /// Live `user_question` rows not yet answered or expired.
  IntColumn get openQuestionCount => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'conversation_activity';

  @override
  Set<Column> get primaryKey => {conversationId};
}
