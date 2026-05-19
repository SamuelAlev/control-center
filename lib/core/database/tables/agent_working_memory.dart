import 'package:control_center/core/database/tables/agents.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_agent_working_memory_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_agent_working_memory_agentId', columns: {#agentId})
class AgentWorkingMemoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
