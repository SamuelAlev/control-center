import 'package:drift/drift.dart';

class BudgetPolicyTable extends Table {
  TextColumn get id => text()();
  TextColumn get scopeType => text()();
  TextColumn get scopeId => text()();
  IntColumn get monthlyBudgetCents => integer().withDefault(const Constant(0))();
  IntColumn get softThresholdPercent =>
      integer().withDefault(const Constant(80))();
  BoolColumn get hardStopEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get spentCents => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get periodStart =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get periodEnd => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
