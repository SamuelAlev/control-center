// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_source_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillSourceDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SkillSourcesTableTable get skillSourcesTable =>
      attachedDatabase.skillSourcesTable;
  SkillSourceDaoManager get managers => SkillSourceDaoManager(this);
}

class SkillSourceDaoManager {
  final _$SkillSourceDaoMixin _db;
  SkillSourceDaoManager(this._db);
  $$SkillSourcesTableTableTableManager get skillSourcesTable =>
      $$SkillSourcesTableTableTableManager(
        _db.attachedDatabase,
        _db.skillSourcesTable,
      );
}
