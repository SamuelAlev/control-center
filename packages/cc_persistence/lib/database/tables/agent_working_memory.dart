import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'uq_agent_working_memory_agent',
  columns: {#agentId},
  unique: true,
)
/// Drift table for per-agent working memory: one entry per agent, written
/// with one `INSERT … ON CONFLICT (agent_id)`.
class AgentWorkingMemoryTable extends Table {
  /// Unique entry identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Agent this memory belongs to.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The agent's working notes, as it wrote them (free text).
  TextColumn get content => text().withDefault(const Constant(''))();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'agent_working_memory';

  @override
  Set<Column> get primaryKey => {id};
}
