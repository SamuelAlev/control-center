// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_belief_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryBeliefDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $MemoryBeliefsTableTable get memoryBeliefsTable =>
      attachedDatabase.memoryBeliefsTable;
  MemoryBeliefDaoManager get managers => MemoryBeliefDaoManager(this);
}

class MemoryBeliefDaoManager {
  final _$MemoryBeliefDaoMixin _db;
  MemoryBeliefDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$MemoryBeliefsTableTableTableManager get memoryBeliefsTable =>
      $$MemoryBeliefsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryBeliefsTable,
      );
}
