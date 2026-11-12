// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_authority_hold_dao.dart';

// ignore_for_file: type=lint
mixin _$ImportedAuthorityHoldDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ImportedAuthorityHoldsTableTable get importedAuthorityHoldsTable =>
      attachedDatabase.importedAuthorityHoldsTable;
  ImportedAuthorityHoldDaoManager get managers =>
      ImportedAuthorityHoldDaoManager(this);
}

class ImportedAuthorityHoldDaoManager {
  final _$ImportedAuthorityHoldDaoMixin _db;
  ImportedAuthorityHoldDaoManager(this._db);
  $$ImportedAuthorityHoldsTableTableTableManager
  get importedAuthorityHoldsTable =>
      $$ImportedAuthorityHoldsTableTableTableManager(
        _db.attachedDatabase,
        _db.importedAuthorityHoldsTable,
      );
}
