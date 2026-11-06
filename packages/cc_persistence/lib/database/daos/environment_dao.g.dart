// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_dao.dart';

// ignore_for_file: type=lint
mixin _$EnvironmentDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $EnvironmentDefinitionsTableTable get environmentDefinitionsTable =>
      attachedDatabase.environmentDefinitionsTable;
  $SpaceEnvironmentsTableTable get spaceEnvironmentsTable =>
      attachedDatabase.spaceEnvironmentsTable;
  $EnvironmentRunsTableTable get environmentRunsTable =>
      attachedDatabase.environmentRunsTable;
  EnvironmentDaoManager get managers => EnvironmentDaoManager(this);
}

class EnvironmentDaoManager {
  final _$EnvironmentDaoMixin _db;
  EnvironmentDaoManager(this._db);
  $$EnvironmentDefinitionsTableTableTableManager
  get environmentDefinitionsTable =>
      $$EnvironmentDefinitionsTableTableTableManager(
        _db.attachedDatabase,
        _db.environmentDefinitionsTable,
      );
  $$SpaceEnvironmentsTableTableTableManager get spaceEnvironmentsTable =>
      $$SpaceEnvironmentsTableTableTableManager(
        _db.attachedDatabase,
        _db.spaceEnvironmentsTable,
      );
  $$EnvironmentRunsTableTableTableManager get environmentRunsTable =>
      $$EnvironmentRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.environmentRunsTable,
      );
}
