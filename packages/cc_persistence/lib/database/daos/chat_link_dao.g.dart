// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_link_dao.dart';

// ignore_for_file: type=lint
mixin _$ChatLinkDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ChatChannelLinksTableTable get chatChannelLinksTable =>
      attachedDatabase.chatChannelLinksTable;
  $ChatUserLinksTableTable get chatUserLinksTable =>
      attachedDatabase.chatUserLinksTable;
  ChatLinkDaoManager get managers => ChatLinkDaoManager(this);
}

class ChatLinkDaoManager {
  final _$ChatLinkDaoMixin _db;
  ChatLinkDaoManager(this._db);
  $$ChatChannelLinksTableTableTableManager get chatChannelLinksTable =>
      $$ChatChannelLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.chatChannelLinksTable,
      );
  $$ChatUserLinksTableTableTableManager get chatUserLinksTable =>
      $$ChatUserLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.chatUserLinksTable,
      );
}
