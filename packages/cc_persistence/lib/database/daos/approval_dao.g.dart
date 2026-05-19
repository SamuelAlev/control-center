// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_dao.dart';

// ignore_for_file: type=lint
mixin _$ApprovalDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ApprovalsTableTable get approvalsTable => attachedDatabase.approvalsTable;
  $ApprovalCommentsTableTable get approvalCommentsTable =>
      attachedDatabase.approvalCommentsTable;
  ApprovalDaoManager get managers => ApprovalDaoManager(this);
}

class ApprovalDaoManager {
  final _$ApprovalDaoMixin _db;
  ApprovalDaoManager(this._db);
  $$ApprovalsTableTableTableManager get approvalsTable =>
      $$ApprovalsTableTableTableManager(
        _db.attachedDatabase,
        _db.approvalsTable,
      );
  $$ApprovalCommentsTableTableTableManager get approvalCommentsTable =>
      $$ApprovalCommentsTableTableTableManager(
        _db.attachedDatabase,
        _db.approvalCommentsTable,
      );
}
