// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_feed_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationFeedDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $NotificationFeedTableTable get notificationFeedTable =>
      attachedDatabase.notificationFeedTable;
  $NotificationReadMarksTableTable get notificationReadMarksTable =>
      attachedDatabase.notificationReadMarksTable;
  $NotificationItemStatesTableTable get notificationItemStatesTable =>
      attachedDatabase.notificationItemStatesTable;
  NotificationFeedDaoManager get managers => NotificationFeedDaoManager(this);
}

class NotificationFeedDaoManager {
  final _$NotificationFeedDaoMixin _db;
  NotificationFeedDaoManager(this._db);
  $$NotificationFeedTableTableTableManager get notificationFeedTable =>
      $$NotificationFeedTableTableTableManager(
        _db.attachedDatabase,
        _db.notificationFeedTable,
      );
  $$NotificationReadMarksTableTableTableManager
  get notificationReadMarksTable =>
      $$NotificationReadMarksTableTableTableManager(
        _db.attachedDatabase,
        _db.notificationReadMarksTable,
      );
  $$NotificationItemStatesTableTableTableManager
  get notificationItemStatesTable =>
      $$NotificationItemStatesTableTableTableManager(
        _db.attachedDatabase,
        _db.notificationItemStatesTable,
      );
}
