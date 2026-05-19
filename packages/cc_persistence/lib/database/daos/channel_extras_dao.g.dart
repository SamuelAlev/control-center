// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_extras_dao.dart';

// ignore_for_file: type=lint
mixin _$ChannelExtrasDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ChannelsTableTable get channelsTable => attachedDatabase.channelsTable;
  $ChannelNotesTableTable get channelNotesTable =>
      attachedDatabase.channelNotesTable;
  $ChannelAutonomyTableTable get channelAutonomyTable =>
      attachedDatabase.channelAutonomyTable;
  $ChannelMessagesTableTable get channelMessagesTable =>
      attachedDatabase.channelMessagesTable;
  $MessageReactionsTableTable get messageReactionsTable =>
      attachedDatabase.messageReactionsTable;
  ChannelExtrasDaoManager get managers => ChannelExtrasDaoManager(this);
}

class ChannelExtrasDaoManager {
  final _$ChannelExtrasDaoMixin _db;
  ChannelExtrasDaoManager(this._db);
  $$ChannelsTableTableTableManager get channelsTable =>
      $$ChannelsTableTableTableManager(_db.attachedDatabase, _db.channelsTable);
  $$ChannelNotesTableTableTableManager get channelNotesTable =>
      $$ChannelNotesTableTableTableManager(
        _db.attachedDatabase,
        _db.channelNotesTable,
      );
  $$ChannelAutonomyTableTableTableManager get channelAutonomyTable =>
      $$ChannelAutonomyTableTableTableManager(
        _db.attachedDatabase,
        _db.channelAutonomyTable,
      );
  $$ChannelMessagesTableTableTableManager get channelMessagesTable =>
      $$ChannelMessagesTableTableTableManager(
        _db.attachedDatabase,
        _db.channelMessagesTable,
      );
  $$MessageReactionsTableTableTableManager get messageReactionsTable =>
      $$MessageReactionsTableTableTableManager(
        _db.attachedDatabase,
        _db.messageReactionsTable,
      );
}
