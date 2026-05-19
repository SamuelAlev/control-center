import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:drift/drift.dart';

/// Lightweight reactions on space messages (PRD 16 §15). Reactor is a
/// principal (human OR agent) — reactions are co-equal signals on the shared
/// thread.
@TableIndex(name: 'idx_message_reactions_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_message_reactions_message', columns: {#messageId})
class MessageReactionsTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Workspace id (isolation invariant).
  TextColumn get workspaceId => text()();

  /// The space the message lives in (denormalized for scoped queries).
  TextColumn get spaceId => text()();

  /// The reacted-to message.
  TextColumn get messageId => text().references(
    ConversationMessagesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The reacting principal's id.
  TextColumn get principalId => text()();

  /// `user` | `agent`.
  TextColumn get principalType => text()();

  /// The emoji (a literal glyph, e.g. 👍).
  TextColumn get emoji => text()();

  /// When the reaction landed.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'message_reactions';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, messageId, principalId, emoji},
  ];
}
