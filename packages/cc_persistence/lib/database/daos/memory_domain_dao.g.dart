// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_domain_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryDomainDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $MemoryDomainsTableTable get memoryDomainsTable =>
      attachedDatabase.memoryDomainsTable;
  MemoryDomainDaoManager get managers => MemoryDomainDaoManager(this);
}

class MemoryDomainDaoManager {
  final _$MemoryDomainDaoMixin _db;
  MemoryDomainDaoManager(this._db);
  $$MemoryDomainsTableTableTableManager get memoryDomainsTable =>
      $$MemoryDomainsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryDomainsTable,
      );
}
