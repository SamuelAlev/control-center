// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_dao.dart';

// ignore_for_file: type=lint
mixin _$TodoDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $TodosTableTable get todosTable => attachedDatabase.todosTable;
  TodoDaoManager get managers => TodoDaoManager(this);
}

class TodoDaoManager {
  final _$TodoDaoMixin _db;
  TodoDaoManager(this._db);
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$TodosTableTableTableManager get todosTable =>
      $$TodosTableTableTableManager(_db.attachedDatabase, _db.todosTable);
}
