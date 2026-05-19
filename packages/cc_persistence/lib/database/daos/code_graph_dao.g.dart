// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_graph_dao.dart';

// ignore_for_file: type=lint
mixin _$CodeGraphDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ReposTableTable get reposTable => attachedDatabase.reposTable;
  $IsolatedReposTableTable get isolatedReposTable =>
      attachedDatabase.isolatedReposTable;
  $CodeSymbolsTableTable get codeSymbolsTable =>
      attachedDatabase.codeSymbolsTable;
  $CodeEdgesTableTable get codeEdgesTable => attachedDatabase.codeEdgesTable;
  $CodeFilesTableTable get codeFilesTable => attachedDatabase.codeFilesTable;
  $CodeIndexCheckpointsTableTable get codeIndexCheckpointsTable =>
      attachedDatabase.codeIndexCheckpointsTable;
  CodeGraphDaoManager get managers => CodeGraphDaoManager(this);
}

class CodeGraphDaoManager {
  final _$CodeGraphDaoMixin _db;
  CodeGraphDaoManager(this._db);
  $$ReposTableTableTableManager get reposTable =>
      $$ReposTableTableTableManager(_db.attachedDatabase, _db.reposTable);
  $$IsolatedReposTableTableTableManager get isolatedReposTable =>
      $$IsolatedReposTableTableTableManager(
        _db.attachedDatabase,
        _db.isolatedReposTable,
      );
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
  $$CodeIndexCheckpointsTableTableTableManager get codeIndexCheckpointsTable =>
      $$CodeIndexCheckpointsTableTableTableManager(
        _db.attachedDatabase,
        _db.codeIndexCheckpointsTable,
      );
}
