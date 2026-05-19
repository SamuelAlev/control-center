// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReviewDraftsTable get reviewDrafts => attachedDatabase.reviewDrafts;
  ReviewDaoManager get managers => ReviewDaoManager(this);
}

class ReviewDaoManager {
  final _$ReviewDaoMixin _db;
  ReviewDaoManager(this._db);
  $$ReviewDraftsTableTableManager get reviewDrafts =>
      $$ReviewDraftsTableTableManager(_db.attachedDatabase, _db.reviewDrafts);
}
