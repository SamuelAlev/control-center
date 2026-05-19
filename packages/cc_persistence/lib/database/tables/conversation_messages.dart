import 'package:drift/drift.dart';

/// Drift table definition for messages within a conversation. A message
/// belongs to exactly one conversation; `spaceId` is denormalized from it.
@TableIndex(
  name: 'idx_conversation_messages_messageType',
  columns: {#messageType},
)
@TableIndex(name: 'idx_conversation_messages_spaceId', columns: {#spaceId})
@TableIndex(
  name: 'idx_conversation_messages_conversationId',
  columns: {#conversationId},
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

  /// Id of the agent or user that sent the message.
  TextColumn get senderId => text()();

  /// Sender type.
  TextColumn get senderType => text()();

  /// Content.
  TextColumn get content => text()();

  /// Message type.
  TextColumn get messageType => text().withDefault(const Constant('text'))();

  /// Metadata.
  TextColumn get metadata => text().nullable()();

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
  /// Nullable and unconstrained on purpose: a message whose parent was hard
  /// deleted is a root, not an error, and a foreign key here would make
  /// deleting one message fail on the ones that came after it.
  TextColumn get parentMessageId => text().nullable()();

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

  /// Embedding vector for semantic retrieval (Float32List bytes).
  BlobColumn get embedding => blob().nullable()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'conversation_messages';

  @override
  Set<Column> get primaryKey => {id};
}
