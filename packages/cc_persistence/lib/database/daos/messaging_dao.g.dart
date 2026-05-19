// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_dao.dart';

// ignore_for_file: type=lint
mixin _$MessagingDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $ChannelsTableTable get channelsTable => attachedDatabase.channelsTable;
  $ChannelParticipantsTableTable get channelParticipantsTable =>
      attachedDatabase.channelParticipantsTable;
  $ChannelMessagesTableTable get channelMessagesTable =>
      attachedDatabase.channelMessagesTable;
  MessagingDaoManager get managers => MessagingDaoManager(this);
}

class MessagingDaoManager {
  final _$MessagingDaoMixin _db;
  MessagingDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$ChannelsTableTableTableManager get channelsTable =>
      $$ChannelsTableTableTableManager(_db.attachedDatabase, _db.channelsTable);
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
