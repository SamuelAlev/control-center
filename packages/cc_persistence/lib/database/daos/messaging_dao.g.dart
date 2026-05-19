// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_dao.dart';

// ignore_for_file: type=lint
mixin _$MessagingDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ChannelsTableTable get channelsTable => attachedDatabase.channelsTable;
  $ConversationsTableTable get conversationsTable =>
      attachedDatabase.conversationsTable;
  $ChannelParticipantsTableTable get channelParticipantsTable =>
      attachedDatabase.channelParticipantsTable;
  $ChannelMessagesTableTable get channelMessagesTable =>
      attachedDatabase.channelMessagesTable;
  MessagingDaoManager get managers => MessagingDaoManager(this);
}

class MessagingDaoManager {
  final _$MessagingDaoMixin _db;
  MessagingDaoManager(this._db);
  $$ChannelsTableTableTableManager get channelsTable =>
      $$ChannelsTableTableTableManager(_db.attachedDatabase, _db.channelsTable);
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationsTable,
      );
  $$ChannelParticipantsTableTableTableManager get channelParticipantsTable =>
      $$ChannelParticipantsTableTableTableManager(
        _db.attachedDatabase,
        _db.channelParticipantsTable,
      );
  $$ChannelMessagesTableTableTableManager get channelMessagesTable =>
      $$ChannelMessagesTableTableTableManager(
        _db.attachedDatabase,
        _db.channelMessagesTable,
      );
}
