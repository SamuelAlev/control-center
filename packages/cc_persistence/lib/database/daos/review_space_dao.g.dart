// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_space_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewSpaceDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ReviewSpacesTableTable get reviewSpacesTable =>
      attachedDatabase.reviewSpacesTable;
  ReviewSpaceDaoManager get managers => ReviewSpaceDaoManager(this);
}

class ReviewSpaceDaoManager {
  final _$ReviewSpaceDaoMixin _db;
  ReviewSpaceDaoManager(this._db);
  $$ReviewSpacesTableTableTableManager get reviewSpacesTable =>
      $$ReviewSpacesTableTableTableManager(
        _db.attachedDatabase,
        _db.reviewSpacesTable,
      );
}
