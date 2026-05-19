// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_script_run_dao.dart';

// ignore_for_file: type=lint
mixin _$RepoScriptRunDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $RepoScriptRunsTableTable get repoScriptRunsTable =>
      attachedDatabase.repoScriptRunsTable;
  RepoScriptRunDaoManager get managers => RepoScriptRunDaoManager(this);
}

class RepoScriptRunDaoManager {
  final _$RepoScriptRunDaoMixin _db;
  RepoScriptRunDaoManager(this._db);
  $$RepoScriptRunsTableTableTableManager get repoScriptRunsTable =>
      $$RepoScriptRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.repoScriptRunsTable,
      );
}
