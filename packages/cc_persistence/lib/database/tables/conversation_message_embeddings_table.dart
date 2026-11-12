import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:drift/drift.dart';

/// The semantic-recall vector of a message, one row per embedded message.
///
/// Kept beside the message rather than on it: a message row is read by every
/// list and rewritten by every streaming flush, and neither needs a 1.5 KB
/// vector. A message that is not embedded yet has no row here, which is what
/// the backfill looks for (an anti-join served by the primary key).
///
/// Message vectors are ranked in Dart over one space at a time, not by the
/// vector extension, so the table needs no rowid of its own.
class ConversationMessageEmbeddingsTable extends Table {
  /// The embedded message. `ON DELETE CASCADE`: the vector is part of it.
  TextColumn get messageId => text().references(
    ConversationMessagesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The vector (Float32List bytes).
  BlobColumn get embedding => blob()();

  @override
  String get tableName => 'conversation_message_embeddings';

  @override
  Set<Column> get primaryKey => {messageId};
}
