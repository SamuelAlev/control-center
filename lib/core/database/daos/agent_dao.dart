import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/agent_run_logs.dart';
import 'package:control_center/core/database/tables/agents.dart';
import 'package:drift/drift.dart';

part 'agent_dao.g.dart';

/// Data access object for [AgentsTable] and [AgentRunLogsTable].
@DriftAccessor(tables: [AgentsTable, AgentRunLogsTable])
class AgentDao extends DatabaseAccessor<AppDatabase> with _$AgentDaoMixin {
  /// Creates an [AgentDao] for the given database.
  AgentDao(super.attachedDatabase);

  // ── Agent methods ──

  /// Watches **all agents across every workspace**, ordered by name.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for global/system surfaces only (the
  /// dashboard's all-agents view, process detection, startup reconcilers).
  /// Never use this to populate a workspace-scoped surface: agents are
  /// workspace-scoped, so use [watchByWorkspace] and pass the active
  /// `workspaceId` to avoid leaking other workspaces' agents.
  Stream<List<AgentsTableData>> watchAll() =>
      (select(agentsTable)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// Watches agents for a specific workspace ordered by name.
  Stream<List<AgentsTableData>> watchByWorkspace(String workspaceId) =>
      (select(agentsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// Returns **all agents across every workspace**.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for global analytics/aggregation only. For a
  /// workspace-scoped read, filter by `workspaceId` instead.
  Future<List<AgentsTableData>> getAll() => select(agentsTable).get();

  /// Returns a single agent by [id] or null.
  Future<AgentsTableData?> getById(String id) =>
      (select(agentsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns the agent with the given [name] inside [workspaceId], or null.
  ///
  /// Names are unique per workspace (enforced at the use-case layer), so this
  /// is the correct lookup for checking name collisions before insert.
  Future<AgentsTableData?> getByWorkspaceAndName(
    String workspaceId,
    String name,
  ) =>
      (select(agentsTable)
            ..where(
              (t) => t.workspaceId.equals(workspaceId) & t.name.equals(name),
            ))
          .getSingleOrNull();

  /// Inserts or updates an agent.
  Future<void> upsert(AgentsTableCompanion entry) =>
      into(agentsTable).insertOnConflictUpdate(entry);

  /// Deletes an agent by [id].
  Future<int> deleteById(String id) =>
      (delete(agentsTable)..where((t) => t.id.equals(id))).go();

  /// Deletes all agents.
  Future<int> deleteAll() => delete(agentsTable).go();

  /// Deletes an agent and all its associated run logs in a transaction.
  Future<void> deleteAgentWithLogs(String id) => transaction(() async {
    await (delete(agentRunLogsTable)..where((t) => t.agentId.equals(id))).go();
    await (delete(agentsTable)..where((t) => t.id.equals(id))).go();
  });

  // ── Agent run log methods ──

  /// Watches run logs for a specific agent.
  Stream<List<AgentRunLogsTableData>> watchLogsByAgent(String agentId) =>
      (select(agentRunLogsTable)
            ..where((t) => t.agentId.equals(agentId))
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch();

  /// Watches **all run logs across every workspace**.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for global/system jobs only (cost rollups,
  /// the orphan-run reaper, process detection, analytics). A workspace-scoped
  /// surface must filter by `workspaceId`.
  Stream<List<AgentRunLogsTableData>> watchAllLogs() => (select(
    agentRunLogsTable,
  )..orderBy([(t) => OrderingTerm.desc(t.startedAt)])).watch();

  /// Watches the active (not-yet-completed) run logs for a conversation within
  /// a workspace, newest first.
  ///
  /// Workspace-scoped: filters on both `workspaceId` and `conversationId` so a
  /// foreign workspace's runs can never surface. Used to tell whether an agent
  /// is currently working in a channel/ticket so the composer can offer
  /// stop/queue. "Active" means `completedAt IS NULL` — both the natural
  /// completion and the user-stop paths stamp `completedAt`.
  Stream<List<AgentRunLogsTableData>> watchActiveLogsByConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.conversationId.equals(conversationId) &
                  t.completedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch();

  /// Returns a single run log by [id] or null.
  Future<AgentRunLogsTableData?> getLogById(String id) => (select(
    agentRunLogsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Upserts a run log.
  Future<void> upsertLog(AgentRunLogsTableCompanion entry) =>
      into(agentRunLogsTable).insertOnConflictUpdate(entry);

  /// Deletes run logs by agent id.
  Future<int> deleteLogsByAgentId(String agentId) =>
      (delete(agentRunLogsTable)..where((t) => t.agentId.equals(agentId))).go();
}
