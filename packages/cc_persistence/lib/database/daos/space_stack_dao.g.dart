// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_stack_dao.dart';

// ignore_for_file: type=lint
mixin _$SpaceStackDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SpaceStackEntriesTableTable get spaceStackEntriesTable =>
      attachedDatabase.spaceStackEntriesTable;
  SpaceStackDaoManager get managers => SpaceStackDaoManager(this);
}

class SpaceStackDaoManager {
  final _$SpaceStackDaoMixin _db;
  SpaceStackDaoManager(this._db);
  $$SpaceStackEntriesTableTableTableManager get spaceStackEntriesTable =>
      $$SpaceStackEntriesTableTableTableManager(
        _db.attachedDatabase,
        _db.spaceStackEntriesTable,
      );
}
