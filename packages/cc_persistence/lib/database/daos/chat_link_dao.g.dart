// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_link_dao.dart';

// ignore_for_file: type=lint
mixin _$ChatLinkDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ChatSpaceLinksTableTable get chatSpaceLinksTable =>
      attachedDatabase.chatSpaceLinksTable;
  $ChatUserLinksTableTable get chatUserLinksTable =>
      attachedDatabase.chatUserLinksTable;
  ChatLinkDaoManager get managers => ChatLinkDaoManager(this);
}

class ChatLinkDaoManager {
  final _$ChatLinkDaoMixin _db;
  ChatLinkDaoManager(this._db);
  $$ChatSpaceLinksTableTableTableManager get chatSpaceLinksTable =>
      $$ChatSpaceLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.chatSpaceLinksTable,
      );
  $$ChatUserLinksTableTableTableManager get chatUserLinksTable =>
      $$ChatUserLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.chatUserLinksTable,
      );
}
