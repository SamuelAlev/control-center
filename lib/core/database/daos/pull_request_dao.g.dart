// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pull_request_dao.dart';

// ignore_for_file: type=lint
mixin _$PullRequestDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $PullRequestsTableTable get pullRequestsTable =>
      attachedDatabase.pullRequestsTable;
  PullRequestDaoManager get managers => PullRequestDaoManager(this);
}

class PullRequestDaoManager {
  final _$PullRequestDaoMixin _db;
  PullRequestDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$PullRequestsTableTableTableManager get pullRequestsTable =>
      $$PullRequestsTableTableTableManager(
        _db.attachedDatabase,
        _db.pullRequestsTable,
      );
}
