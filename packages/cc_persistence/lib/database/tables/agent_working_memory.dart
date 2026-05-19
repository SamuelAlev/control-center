import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_agent_working_memory_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_agent_working_memory_agentId', columns: {#agentId})
/// Drift table for per-agent working memory.
class AgentWorkingMemoryTable extends Table {
  /// Unique entry identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Agent this memory belongs to.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();
  /// JSON-encoded memory content.
  TextColumn get content => text().withDefault(const Constant(''))();
  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
