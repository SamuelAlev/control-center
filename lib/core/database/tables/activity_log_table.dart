import 'package:control_center/core/database/tables/agents.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_activity_log_agent', columns: {#actorId})
@TableIndex(name: 'idx_activity_log_entity', columns: {#entityType, #entityId})
@TableIndex(name: 'idx_activity_log_created', columns: {#createdAt})
class ActivityLogTable extends Table {
  TextColumn get id => text()();
  TextColumn get actorType => text()();
  TextColumn get actorId => text().nullable().references(
        AgentsTable,
        #id,
        onDelete: KeyAction.setNull,
      )();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get details => text().nullable()();
  TextColumn get runId => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
