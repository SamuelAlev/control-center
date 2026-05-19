import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'agent_dao.g.dart';

/// Data access object for [AgentsTable] and [AgentRunLogsTable].
@DriftAccessor(tables: [AgentsTable, AgentRunLogsTable])
class AgentDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$AgentDaoMixin {
  /// Creates an [AgentDao] for the given database.
  AgentDao(super.attachedDatabase);

  // ── Agent methods ──

  /// Watches this workspace's agents, ordered by name.
  ///
  /// Unfiltered and safe: this DAO hangs off one workspace's database, so every
  /// row it can see belongs to that workspace. The dashboard's all-agents view
  /// merges one of these streams per workspace via
  /// `CrossWorkspaceQueries.mergeStreams`.
  Stream<List<AgentsTableData>> watchAll() =>
      (select(agentsTable)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// Watches agents for a specific workspace ordered by name.
  Stream<List<AgentsTableData>> watchByWorkspace(String workspaceId) =>
      (select(agentsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// Returns this workspace's agents.
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
      (select(agentsTable)..where(
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

  /// How many run logs [watchLogsByAgent] returns per agent (newest first).
  ///
  /// This watch backs live UI (fleet rail, roster live state, run history,
  /// plan estimates) that only ever needs recent runs, yet it is pinned
  /// process-wide per agent by the keep-awake service. Without a limit every
  /// agent's FULL history — including heavy JSON columns — is re-read and
  /// re-shipped on every run-log write, growing without bound.
  static const int watchLogsByAgentLimit = 200;

  /// Watches run logs for a specific agent within a workspace, newest first.
  /// Bounded to the [watchLogsByAgentLimit] most recent rows.
  ///
  /// Workspace-scoped: filters on both `workspaceId` and `agentId`. An agent
  /// belongs to exactly one workspace, but scoping the query keeps a foreign
  /// workspace's rows from surfacing even if an id is reused or mis-passed.
  Stream<List<AgentRunLogsTableData>> watchLogsByAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(watchLogsByAgentLimit))
          .watch();

  /// Returns ALL run logs for a specific agent within a workspace, newest
  /// first — no limit.
  ///
  /// For one-shot maintenance jobs that genuinely need the complete
  /// history (historical backfill). Live UI watches must
  /// use the bounded [watchLogsByAgent] instead.
  Future<List<AgentRunLogsTableData>> allLogsByAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.agentId.equals(agentId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  /// Returns the run logs belonging to a pipeline run within a workspace,
  /// newest first. Used to roll up per-step cost on the run waterfall.
  ///
  /// Workspace-scoped: filters on both `workspaceId` and `pipelineRunId`.
  Future<List<AgentRunLogsTableData>> logsForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.pipelineRunId.equals(pipelineRunId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  /// Returns the run logs belonging to a specific pipeline step within a
  /// workspace, newest first. Workspace-scoped: filters on `workspaceId`,
  /// `pipelineRunId`, and `pipelineStepRunId` (which carries the template step
  /// id the engine dispatches under).
  Future<List<AgentRunLogsTableData>> logsForPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.pipelineRunId.equals(pipelineRunId) &
                  t.pipelineStepRunId.equals(pipelineStepId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  /// Watches this workspace's run logs.
  ///
  /// Live UI surfaces should prefer [watchRecentLogs] — this unbounded watch
  /// re-materializes the whole table on every run-log change.
  Stream<List<AgentRunLogsTableData>> watchAllLogs() => (select(
    agentRunLogsTable,
  )..orderBy([(t) => OrderingTerm.desc(t.startedAt)])).watch();

  /// Watches the [limit] most recent run logs across every workspace, newest
  /// first.
  ///
  /// The bounded companion to [watchAllLogs] for live dashboards: only the
  /// newest [limit] rows are read and re-emitted per change, keeping memory and
  /// wire traffic flat as history grows.
  ///
  /// An all-workspace "most recent N" takes N from every workspace and
  /// merge-sorts (`CrossWorkspaceQueries.topN` / `mergeStreams`) — taking fewer
  /// per workspace could miss rows that outrank another workspace's.
  Stream<List<AgentRunLogsTableData>> watchRecentLogs(int limit) =>
      (select(agentRunLogsTable)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(limit))
          .watch();

  /// Returns all run logs belonging to [workspaceId], newest first.
  ///
  /// Workspace-scoped: the SQL `WHERE` filters on `workspaceId` so only this
  /// workspace's rows are read — never load `watchAllLogs()` and filter in
  /// memory (that both leaks other workspaces' rows into memory and scales
  /// with the whole DB). Used by the workspace-health rollup.
  Future<List<AgentRunLogsTableData>> logsByWorkspace(String workspaceId) =>
      (select(agentRunLogsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

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

  /// Watches ALL run logs (active + completed) for a conversation within a
  /// workspace, newest first. Workspace-scoped (filters both `workspaceId` and
  /// `conversationId`). Used by the conversation run-tree UI to render the
  /// parent dispatch plus its ephemeral subagent runs (`parentRunId`).
  Stream<List<AgentRunLogsTableData>> watchLogsByConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.conversationId.equals(conversationId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .watch();

  /// Returns a single run log by [id] or null.
  Future<AgentRunLogsTableData?> getLogById(String id) => (select(
    agentRunLogsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns the agent's most-recently-started run that has not yet completed,
  /// or null. Used to resolve which conversation an agent is currently working
  /// in, server-side, without trusting client-supplied tool arguments.
  Future<AgentRunLogsTableData?> getActiveLogByAgent(String agentId) =>
      (select(agentRunLogsTable)
            ..where((t) => t.agentId.equals(agentId) & t.completedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Upserts a run log.
  Future<void> upsertLog(AgentRunLogsTableCompanion entry) =>
      into(agentRunLogsTable).insertOnConflictUpdate(entry);

  /// Deletes run logs by agent id.
  Future<int> deleteLogsByAgentId(String agentId) =>
      (delete(agentRunLogsTable)..where((t) => t.agentId.equals(agentId))).go();
}
