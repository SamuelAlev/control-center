// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_repo_dao.dart';

// ignore_for_file: type=lint
mixin _$SpaceRepoDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SpaceReposTableTable get spaceReposTable => attachedDatabase.spaceReposTable;
  SpaceRepoDaoManager get managers => SpaceRepoDaoManager(this);
}

class SpaceRepoDaoManager {
  final _$SpaceRepoDaoMixin _db;
  SpaceRepoDaoManager(this._db);
  $$SpaceReposTableTableTableManager get spaceReposTable =>
      $$SpaceReposTableTableTableManager(
        _db.attachedDatabase,
        _db.spaceReposTable,
      );
}
