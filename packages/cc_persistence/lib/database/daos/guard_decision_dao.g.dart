// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guard_decision_dao.dart';

// ignore_for_file: type=lint
mixin _$GuardDecisionDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $GuardDecisionsTableTable get guardDecisionsTable =>
      attachedDatabase.guardDecisionsTable;
  GuardDecisionDaoManager get managers => GuardDecisionDaoManager(this);
}

class GuardDecisionDaoManager {
  final _$GuardDecisionDaoMixin _db;
  GuardDecisionDaoManager(this._db);
  $$GuardDecisionsTableTableTableManager get guardDecisionsTable =>
      $$GuardDecisionsTableTableTableManager(
        _db.attachedDatabase,
        _db.guardDecisionsTable,
      );
}
