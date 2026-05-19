// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_dao.dart';

// ignore_for_file: type=lint
mixin _$BudgetDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $BudgetIncidentsTableTable get budgetIncidentsTable =>
      attachedDatabase.budgetIncidentsTable;
  BudgetDaoManager get managers => BudgetDaoManager(this);
}

class BudgetDaoManager {
  final _$BudgetDaoMixin _db;
  BudgetDaoManager(this._db);
  $$BudgetPolicyTableTableTableManager get budgetPolicyTable =>
      $$BudgetPolicyTableTableTableManager(
        _db.attachedDatabase,
        _db.budgetPolicyTable,
      );
  $$BudgetIncidentsTableTableTableManager get budgetIncidentsTable =>
      $$BudgetIncidentsTableTableTableManager(
        _db.attachedDatabase,
        _db.budgetIncidentsTable,
      );
}
