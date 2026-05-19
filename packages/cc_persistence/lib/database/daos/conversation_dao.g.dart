// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ChannelsTableTable get channelsTable => attachedDatabase.channelsTable;
  $ConversationsTableTable get conversationsTable =>
      attachedDatabase.conversationsTable;
  ConversationDaoManager get managers => ConversationDaoManager(this);
}

class ConversationDaoManager {
  final _$ConversationDaoMixin _db;
  ConversationDaoManager(this._db);
  $$ChannelsTableTableTableManager get channelsTable =>
      $$ChannelsTableTableTableManager(_db.attachedDatabase, _db.channelsTable);
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationsTable,
      );
}
