// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $ConversationsTableTable get conversationsTable =>
      attachedDatabase.conversationsTable;
  $ConversationMessagesTableTable get conversationMessagesTable =>
      attachedDatabase.conversationMessagesTable;
  ConversationDaoManager get managers => ConversationDaoManager(this);
}

class ConversationDaoManager {
  final _$ConversationDaoMixin _db;
  ConversationDaoManager(this._db);
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationsTable,
      );
  $$ConversationMessagesTableTableTableManager get conversationMessagesTable =>
      $$ConversationMessagesTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationMessagesTable,
      );
}
