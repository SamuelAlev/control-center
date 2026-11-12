// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_graph_dao.dart';

// ignore_for_file: type=lint
mixin _$CodeGraphDaoMixin on DatabaseAccessor<CodeIndexDatabase> {
  $CodeSymbolsTableTable get codeSymbolsTable =>
      attachedDatabase.codeSymbolsTable;
  $CodeSymbolEmbeddingsTableTable get codeSymbolEmbeddingsTable =>
      attachedDatabase.codeSymbolEmbeddingsTable;
  $CodeEdgesTableTable get codeEdgesTable => attachedDatabase.codeEdgesTable;
  $CodeFilesTableTable get codeFilesTable => attachedDatabase.codeFilesTable;
  $CodeIndexCheckpointsTableTable get codeIndexCheckpointsTable =>
      attachedDatabase.codeIndexCheckpointsTable;
  CodeGraphDaoManager get managers => CodeGraphDaoManager(this);
}

class CodeGraphDaoManager {
  final _$CodeGraphDaoMixin _db;
  CodeGraphDaoManager(this._db);
  $$CodeSymbolsTableTableTableManager get codeSymbolsTable =>
      $$CodeSymbolsTableTableTableManager(
        _db.attachedDatabase,
        _db.codeSymbolsTable,
      );
  $$CodeSymbolEmbeddingsTableTableTableManager get codeSymbolEmbeddingsTable =>
      $$CodeSymbolEmbeddingsTableTableTableManager(
        _db.attachedDatabase,
        _db.codeSymbolEmbeddingsTable,
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
