import 'package:drift/drift.dart';

/// Drift table definition for messages within a channel.
@TableIndex(name: 'idx_channel_messages_messageType', columns: {#messageType})
@TableIndex(name: 'idx_channel_messages_channelId', columns: {#channelId})
class ChannelMessagesTable extends Table {
  /// Message id.
  TextColumn get id => text()();

  /// Channel id.
  TextColumn get channelId => text().customConstraint(
    'NOT NULL REFERENCES channels (id) ON DELETE CASCADE',
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

  /// Parent message ID for threaded replies (null for top-level messages).
  TextColumn get parentMessageId => text()
      .nullable()
      .customConstraint('REFERENCES channel_messages (id) ON DELETE CASCADE')();

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
  String get tableName => 'channel_messages';

  @override
  Set<Column> get primaryKey => {id};
}
