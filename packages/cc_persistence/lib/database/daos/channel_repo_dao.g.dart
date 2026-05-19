// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_repo_dao.dart';

// ignore_for_file: type=lint
mixin _$ChannelRepoDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ChannelReposTableTable get channelReposTable =>
      attachedDatabase.channelReposTable;
  ChannelRepoDaoManager get managers => ChannelRepoDaoManager(this);
}

class ChannelRepoDaoManager {
  final _$ChannelRepoDaoMixin _db;
  ChannelRepoDaoManager(this._db);
  $$ChannelReposTableTableTableManager get channelReposTable =>
      $$ChannelReposTableTableTableManager(
        _db.attachedDatabase,
        _db.channelReposTable,
      );
}
