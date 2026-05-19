// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_graph_dao.dart';

// ignore_for_file: type=lint
mixin _$CodeGraphDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $ReposTableTable get reposTable => attachedDatabase.reposTable;
  $CodeSymbolsTableTable get codeSymbolsTable =>
      attachedDatabase.codeSymbolsTable;
  $CodeEdgesTableTable get codeEdgesTable => attachedDatabase.codeEdgesTable;
  $CodeFilesTableTable get codeFilesTable => attachedDatabase.codeFilesTable;
  CodeGraphDaoManager get managers => CodeGraphDaoManager(this);
}

class CodeGraphDaoManager {
  final _$CodeGraphDaoMixin _db;
  CodeGraphDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$ReposTableTableTableManager get reposTable =>
      $$ReposTableTableTableManager(_db.attachedDatabase, _db.reposTable);
  $$CodeSymbolsTableTableTableManager get codeSymbolsTable =>
      $$CodeSymbolsTableTableTableManager(
        _db.attachedDatabase,
        _db.codeSymbolsTable,
      );
  $$CodeEdgesTableTableTableManager get codeEdgesTable =>
      $$CodeEdgesTableTableTableManager(
        _db.attachedDatabase,
        _db.codeEdgesTable,
      );
  $$CodeFilesTableTableTableManager get codeFilesTable =>
      $$CodeFilesTableTableTableManager(
        _db.attachedDatabase,
        _db.codeFilesTable,
      );
}
