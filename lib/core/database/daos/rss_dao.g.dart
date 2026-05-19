// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rss_dao.dart';

// ignore_for_file: type=lint
mixin _$RssDaoMixin on DatabaseAccessor<AppDatabase> {
  $RssFeedsTableTable get rssFeedsTable => attachedDatabase.rssFeedsTable;
  $RssArticlesTableTable get rssArticlesTable =>
      attachedDatabase.rssArticlesTable;
  RssDaoManager get managers => RssDaoManager(this);
}

class RssDaoManager {
  final _$RssDaoMixin _db;
  RssDaoManager(this._db);
  $$RssFeedsTableTableTableManager get rssFeedsTable =>
      $$RssFeedsTableTableTableManager(_db.attachedDatabase, _db.rssFeedsTable);
  $$RssArticlesTableTableTableManager get rssArticlesTable =>
      $$RssArticlesTableTableTableManager(
        _db.attachedDatabase,
        _db.rssArticlesTable,
      );
}
