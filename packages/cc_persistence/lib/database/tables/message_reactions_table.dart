import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Lightweight reactions on space messages (PRD 16 §15). Reactor is a
/// principal (human OR agent) — reactions are co-equal signals on the shared
/// thread. A principal reacts with an emoji once per message:
/// `(message_id, principal_id, emoji)` is unique.
@TableIndex(name: 'idx_message_reactions_spaceId', columns: {#spaceId})
class MessageReactionsTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Workspace id (isolation invariant).
  TextColumn get workspaceId => text()();

  /// The space the message lives in (denormalized for scoped queries).
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// The reacted-to message.
  TextColumn get messageId => text().references(
    ConversationMessagesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The reacting principal's id. No foreign key: a principal is a user (in
  /// `global.db`) or an agent.
  TextColumn get principalId => text()();

  /// `user` | `agent` (`PrincipalType.wireName`).
  TextColumn get principalType => text().check(
    // ignore: recursive_getters
    principalType.isIn(SpacesStoredValues.principalType),
  )();

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
    {messageId, principalId, emoji},
  ];
}
