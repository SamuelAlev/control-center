// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_product_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkProductDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $WorkProductsTableTable get workProductsTable =>
      attachedDatabase.workProductsTable;
  $WorkProductRevisionsTableTable get workProductRevisionsTable =>
      attachedDatabase.workProductRevisionsTable;
  WorkProductDaoManager get managers => WorkProductDaoManager(this);
}

class WorkProductDaoManager {
  final _$WorkProductDaoMixin _db;
  WorkProductDaoManager(this._db);
  $$WorkProductsTableTableTableManager get workProductsTable =>
      $$WorkProductsTableTableTableManager(
        _db.attachedDatabase,
        _db.workProductsTable,
      );
  $$WorkProductRevisionsTableTableTableManager get workProductRevisionsTable =>
      $$WorkProductRevisionsTableTableTableManager(
        _db.attachedDatabase,
        _db.workProductRevisionsTable,
      );
}
