// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_channel_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewChannelDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReviewChannelsTableTable get reviewChannelsTable =>
      attachedDatabase.reviewChannelsTable;
  ReviewChannelDaoManager get managers => ReviewChannelDaoManager(this);
}

class ReviewChannelDaoManager {
  final _$ReviewChannelDaoMixin _db;
  ReviewChannelDaoManager(this._db);
  $$ReviewChannelsTableTableTableManager get reviewChannelsTable =>
      $$ReviewChannelsTableTableTableManager(
        _db.attachedDatabase,
        _db.reviewChannelsTable,
      );
}
