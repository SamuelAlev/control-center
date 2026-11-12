import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agent_run_payloads_table.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'agent_dao.g.dart';

/// A run-log row read together with its payload row, which is null when the
/// run has stored nothing in `agent_run_payloads`.
typedef AgentRunLogWithPayload = ({
  AgentRunLogsTableData log,
  AgentRunPayloadsTableData? payload,
});

/// Data access object for [AgentsTable], [AgentRunLogsTable] and
/// [AgentRunPayloadsTable].
///
/// Run lists read `agent_run_logs` alone. The single-run reads and the
/// pipeline step harvest, which are what read a run's payload, join
/// `agent_run_payloads` and return [AgentRunLogWithPayload].
@DriftAccessor(tables: [AgentsTable, AgentRunLogsTable, AgentRunPayloadsTable])
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

  /// Deletes an agent and all its run logs: `agent_run_logs.agent_id` is
  /// `ON DELETE CASCADE`, so the one delete takes them.
  Future<void> deleteAgentWithLogs(String id) =>
      (delete(agentsTable)..where((t) => t.id.equals(id))).go();

  // ── Agent run log methods ──

  /// Run-log order, newest first. `started_at` has whole-second resolution,
  /// so runs started together (a fan-out, a team dispatch) tie on it; `id`
  /// makes the order the same on every read.
  static final List<OrderClauseGenerator<$AgentRunLogsTableTable>>
  _newestFirst = [
    (t) => OrderingTerm.desc(t.startedAt),
    (t) => OrderingTerm.desc(t.id),
  ];

  /// Run-log rows matching [where], each with its payload row (a primary-key
  /// lookup per run), newest first.
  JoinedSelectStatement<HasResultSet, dynamic> _withPayload(
    Expression<bool> where,
  ) =>
      select(agentRunLogsTable).join([
          leftOuterJoin(
            agentRunPayloadsTable,
            agentRunPayloadsTable.runId.equalsExp(agentRunLogsTable.id),
          ),
        ])
        ..where(where)
        ..orderBy([
          OrderingTerm.desc(agentRunLogsTable.startedAt),
          OrderingTerm.desc(agentRunLogsTable.id),
        ]);

  AgentRunLogWithPayload _readWithPayload(TypedResult row) => (
    log: row.readTable(agentRunLogsTable),
    payload: row.readTableOrNull(agentRunPayloadsTable),
  );

  /// The statuses of a run that has not finished: the complement of
  /// `completed` and `error`.
  static const List<String> nonTerminalStatuses = ['pending', 'running'];

  /// Most non-terminal runs [nonTerminalLogs] returns. A workspace never has
  /// this many runs in flight; the bound keeps a corrupted status column from
  /// turning a liveness scan back into a full-table read.
  static const int nonTerminalLimit = 1000;

  /// Most rows a conversation's or space's run watch returns (the newest).
  static const int watchLogsByScopeLimit = 500;

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
            ..orderBy(_newestFirst)
            ..limit(watchLogsByAgentLimit))
          .watch();

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
            ..orderBy(_newestFirst))
          .get();

  /// Returns the run logs belonging to a specific pipeline step within a
  /// workspace, newest first, with their payloads: the engine harvests each
  /// run's `submit_output` from them. Workspace-scoped: filters on
  /// `workspaceId`, `pipelineRunId` and `pipelineStepId` (which carries the
  /// template step id the engine dispatches under).
  Future<List<AgentRunLogWithPayload>> logsForPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) => _withPayload(
    agentRunLogsTable.workspaceId.equals(workspaceId) &
        agentRunLogsTable.pipelineRunId.equals(pipelineRunId) &
        agentRunLogsTable.pipelineStepId.equals(pipelineStepId),
  ).map(_readWithPayload).get();

  /// The three columns the spend summary needs, for cost-bearing runs in
  /// [workspaceId] started at or after [sinceSeconds] (epoch seconds).
  ///
  /// Projected on purpose: the summary reads `started_at`, `adapter` and
  /// `cost_micros`, and materializing whole run-log rows to get them
  /// decodes some fifty columns per run for nothing.
  Future<List<({DateTime startedAt, String? adapter, int costMicros})>>
  costHistory(String workspaceId, int sinceSeconds) =>
      customSelect(
        'SELECT started_at, adapter, cost_micros '
        'FROM agent_run_logs '
        'WHERE workspace_id = ? AND started_at >= ? '
        'AND cost_micros > 0 '
        'ORDER BY started_at DESC, id DESC',
        variables: [
          Variable.withString(workspaceId),
          Variable.withInt(sinceSeconds),
        ],
        readsFrom: {agentRunLogsTable},
      ).get().then(
        (rows) => [
          for (final row in rows)
            (
              startedAt: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('started_at') * 1000,
              ),
              adapter: row.readNullable<String>('adapter'),
              costMicros: row.read<int>('cost_micros'),
            ),
        ],
      );

  /// This workspace's runs that have not finished (pending or running),
  /// newest first, at most [limit].
  ///
  /// The liveness jobs (orphan reaping, process detection) only ever look at
  /// runs still in flight. They used to read every run log of every
  /// workspace and filter in Dart; the status filter here is an index probe
  /// on `idx_agent_run_logs_status`.
  Future<List<AgentRunLogsTableData>> nonTerminalLogs({
    int limit = nonTerminalLimit,
  }) =>
      (select(agentRunLogsTable)
            ..where((t) => t.status.isIn(nonTerminalStatuses))
            ..orderBy(_newestFirst)
            ..limit(limit))
          .get();

  /// Watches [workspaceId]'s unfinished runs (pending or running), newest
  /// first, at most [limit]. Backs "which spaces have an agent working".
  Stream<List<AgentRunLogsTableData>> watchNonTerminalLogs(
    String workspaceId, {
    int limit = nonTerminalLimit,
  }) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.status.isIn(nonTerminalStatuses),
            )
            ..orderBy(_newestFirst)
            ..limit(limit))
          .watch();

  /// The most recently started run for [ticketId] in [workspaceId], with its
  /// payload, or null.
  Future<AgentRunLogWithPayload?> latestLogForTicket(
    String workspaceId,
    String ticketId,
  ) => (_withPayload(
    agentRunLogsTable.workspaceId.equals(workspaceId) &
        agentRunLogsTable.ticketId.equals(ticketId),
  )..limit(1)).map(_readWithPayload).getSingleOrNull();

  /// Watches the [limit] most recent run logs of this workspace file, newest
  /// first.
  ///
  /// An all-workspace "most recent N" takes N from every workspace and
  /// merge-sorts (`CrossWorkspaceQueries.mergeStreams`) — taking fewer per
  /// workspace could miss rows that outrank another workspace's.
  Stream<List<AgentRunLogsTableData>> watchRecentLogs(int limit) =>
      (select(agentRunLogsTable)
            ..orderBy(_newestFirst)
            ..limit(limit))
          .watch();

  /// One keyset page of [workspaceId]'s run logs, newest first: at most
  /// [limit] rows strictly older than the `(beforeStartedAt, beforeId)`
  /// position, or the newest rows when no position is given.
  ///
  /// Narrowed by whichever of [agentId], [spaceId] and [conversationId] is
  /// set. The bounded watches show the newest window; this reads what lies
  /// behind it without an `OFFSET` scan.
  Future<List<AgentRunLogsTableData>> logsPage(
    String workspaceId, {
    required int limit,
    String? agentId,
    String? spaceId,
    String? conversationId,
    DateTime? beforeStartedAt,
    String? beforeId,
  }) {
    final hasCursor = beforeStartedAt != null && beforeId != null;
    return (select(agentRunLogsTable)
          ..where((t) {
            Expression<bool> where = t.workspaceId.equals(workspaceId);
            if (agentId != null) {
              where = where & t.agentId.equals(agentId);
            }
            if (spaceId != null) {
              where = where & t.spaceId.equals(spaceId);
            }
            if (conversationId != null) {
              where = where & t.conversationId.equals(conversationId);
            }
            if (hasCursor) {
              where =
                  where &
                  (t.startedAt.isSmallerThanValue(beforeStartedAt) |
                      (t.startedAt.equals(beforeStartedAt) &
                          t.id.isSmallerThanValue(beforeId)));
            }
            return where;
          })
          ..orderBy(_newestFirst)
          ..limit(limit))
        .get();
  }

  /// Watches the active (not-yet-completed) run logs for a conversation within
  /// a workspace, newest first.
  ///
  /// Workspace-scoped: filters on both `workspaceId` and `conversationId` so a
  /// foreign workspace's runs can never surface. Used to tell whether an agent
  /// is currently working in a space/ticket so the composer can offer
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
            ..orderBy(_newestFirst))
          .watch();

  /// Watches the active run logs of a whole SPACE (every conversation in it,
  /// threads included), newest first.
  ///
  /// The space-level "an agent is working here" signal — the sidebar dot, the
  /// review hub's busy gate and the take-over guard all mean the space, not
  /// one stream. They used to ask `watchActiveLogsByConversation` with a SPACE
  /// id, which matched while the two ids were the same value and matches
  /// nothing now.
  Stream<List<AgentRunLogsTableData>> watchActiveLogsBySpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.spaceId.equals(spaceId) &
                  t.completedAt.isNull(),
            )
            ..orderBy(_newestFirst))
          .watch();

  /// Watches the newest [watchLogsByScopeLimit] run logs (active +
  /// completed) for a conversation within a workspace, returned oldest
  /// first. Workspace-scoped (filters both `workspaceId` and
  /// `conversationId`). Used by the conversation run-tree UI to render the
  /// parent dispatch plus its ephemeral subagent runs (`parentRunId`); older
  /// runs are read with [logsPage].
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
            ..orderBy(_newestFirst)
            ..limit(watchLogsByScopeLimit))
          .watch()
          .map((rows) => rows.reversed.toList(growable: false));

  /// The space-wide twin of [watchLogsByConversation]: the newest
  /// [watchLogsByScopeLimit] runs of every conversation in [spaceId],
  /// returned oldest first.
  Stream<List<AgentRunLogsTableData>> watchLogsBySpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(agentRunLogsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.spaceId.equals(spaceId),
            )
            ..orderBy(_newestFirst)
            ..limit(watchLogsByScopeLimit))
          .watch()
          .map((rows) => rows.reversed.toList(growable: false));

  /// Returns a single run log by [id] with its payload, or null.
  Future<AgentRunLogWithPayload?> getLogById(String id) => _withPayload(
    agentRunLogsTable.id.equals(id),
  ).map(_readWithPayload).getSingleOrNull();

  /// Returns the agent's most-recently-started run that has not yet completed,
  /// with its payload, or null. Used to resolve which conversation an agent is
  /// currently working in, server-side, without trusting client-supplied tool
  /// arguments, and by `submit_output`, which validates against the run's
  /// output contract.
  Future<AgentRunLogWithPayload?> getActiveLogByAgent(String agentId) =>
      (_withPayload(
        agentRunLogsTable.agentId.equals(agentId) &
            agentRunLogsTable.completedAt.isNull(),
      )..limit(1)).map(_readWithPayload).getSingleOrNull();

  /// Upserts a run log, and writes the payload columns [payload] carries.
  ///
  /// The payload write is skipped when [payload] carries nothing, and is a
  /// no-op on a payload row that already holds those values (see
  /// [writePayload]), so re-upserting a run to change its status never
  /// rewrites its payload row.
  Future<void> upsertLog(
    AgentRunLogsTableCompanion entry, [
    AgentRunPayloadsTableCompanion payload =
        const AgentRunPayloadsTableCompanion(),
  ]) => transaction(() async {
    await into(agentRunLogsTable).insertOnConflictUpdate(entry);
    await writePayload(entry.workspaceId.value, entry.id.value, payload);
  });

  /// Writes the payload columns [values] carries for run [runId] of
  /// [workspaceId], in ONE statement, and returns how many rows changed.
  ///
  /// Only the columns present in [values] are written (a present null clears
  /// one); absent columns keep what they hold. The run-log row is never
  /// written. The statement inserts the payload row the first time, and
  /// otherwise updates it only when a written column actually changes, so an
  /// unchanged value costs no row write. A run that does not exist in
  /// [workspaceId] matches nothing and returns 0.
  Future<int> writePayload(
    String workspaceId,
    String runId,
    AgentRunPayloadsTableCompanion values,
  ) {
    final present = <String, Value<String?>>{
      agentRunPayloadsTable.contextSnapshotJson.name:
          values.contextSnapshotJson,
      agentRunPayloadsTable.expectedOutputSchema.name:
          values.expectedOutputSchema,
      agentRunPayloadsTable.outputJson.name: values.outputJson,
      agentRunPayloadsTable.verificationJson.name: values.verificationJson,
    }..removeWhere((_, value) => !value.present);
    if (present.isEmpty) {
      return Future.value(0);
    }
    final columns = present.keys.toList(growable: false);
    // `INSERT … SELECT` from the run-log row both scopes the write to the
    // workspace and turns a missing run into zero rows instead of a
    // foreign-key failure. SQLite needs the WHERE on that SELECT to parse the
    // upsert clause after it.
    return customUpdate(
      'INSERT INTO agent_run_payloads (run_id, ${columns.join(', ')}) '
      'SELECT id, ${List.filled(columns.length, '?').join(', ')} '
      'FROM agent_run_logs WHERE id = ? AND workspace_id = ? '
      'ON CONFLICT (run_id) DO UPDATE SET '
      '${columns.map((c) => '$c = excluded.$c').join(', ')} '
      'WHERE ${columns.map((c) => 'agent_run_payloads.$c IS NOT excluded.$c').join(' OR ')}',
      variables: [
        for (final value in present.values) Variable<String>(value.value),
        Variable.withString(runId),
        Variable.withString(workspaceId),
      ],
      updates: {agentRunPayloadsTable},
      updateKind: UpdateKind.update,
    );
  }

  /// Adds one to the run's `submit_output` rejection count, in one statement,
  /// and returns the new count, or null when the run is not in [workspaceId].
  Future<int?> addOutputRejection(String workspaceId, String runId) async {
    final rows = await customWriteReturning(
      'UPDATE agent_run_logs SET output_rejections = output_rejections + 1 '
      'WHERE id = ? AND workspace_id = ? RETURNING output_rejections',
      variables: [Variable.withString(runId), Variable.withString(workspaceId)],
      updates: {agentRunLogsTable},
      updateKind: UpdateKind.update,
    );
    return rows.isEmpty ? null : rows.single.read<int>('output_rejections');
  }

  /// Mutates only the own usage/timing columns, without an upsert that could
  /// replace concurrent child rollups or terminal metadata.
  Future<int> updateLogCost(
    String workspaceId,
    String runId,
    AgentRunLogsTableCompanion cost,
  ) =>
      (update(agentRunLogsTable)..where(
            (t) => t.id.equals(runId) & t.workspaceId.equals(workspaceId),
          ))
          .write(cost);

  /// Adds [amountMicros] to the run's child rollup in a single SQL statement,
  /// so concurrent sibling writes never lose a delta.
  Future<int> addLogChildCostMicros(
    String workspaceId,
    String runId,
    int amountMicros,
  ) {
    return customUpdate(
      'UPDATE agent_run_logs SET '
      'child_cost_micros = child_cost_micros + ? '
      'WHERE id = ? AND workspace_id = ?',
      variables: [
        Variable.withInt(amountMicros),
        Variable.withString(runId),
        Variable.withString(workspaceId),
      ],
      updates: {agentRunLogsTable},
    );
  }

  /// Atomically applies supplied runtime fields while guarding ONLY the
  /// pending→running status change. A late path/output write must survive even
  /// if the run completed just before this call.
  ///
  /// [runtime] goes to the run-log row and [payload] to the payload row, each
  /// only when it carries a column: a snapshot-only write leaves the run-log
  /// row alone, and a status or classification write the payload row.
  Future<int> updateLogRuntime(
    String workspaceId,
    String runId,
    AgentRunLogsTableCompanion runtime,
    AgentRunPayloadsTableCompanion payload, {
    required bool markRunning,
  }) => transaction(() async {
    var updated = 0;
    if (_carriesColumns(runtime)) {
      updated =
          await (update(agentRunLogsTable)..where(
                (t) => t.id.equals(runId) & t.workspaceId.equals(workspaceId),
              ))
              .write(runtime);
    }
    if (_carriesColumns(payload)) {
      final run =
          await (selectOnly(agentRunLogsTable)
                ..addColumns([agentRunLogsTable.id])
                ..where(
                  agentRunLogsTable.id.equals(runId) &
                      agentRunLogsTable.workspaceId.equals(workspaceId),
                ))
              .getSingleOrNull();
      if (run != null) {
        await writePayload(workspaceId, runId, payload);
        updated = 1;
      }
    }
    if (markRunning) {
      final started =
          await (update(agentRunLogsTable)..where(
                (t) =>
                    t.id.equals(runId) &
                    t.workspaceId.equals(workspaceId) &
                    t.completedAt.isNull() &
                    t.status.equals('pending'),
              ))
              .write(
                const AgentRunLogsTableCompanion(status: Value('running')),
              );
      if (started > 0) {
        updated = started;
      }
    }
    return updated;
  });

  /// Conditional partial terminal write; no descendant spend columns are
  /// included, even when they change between preparing and applying the row.
  ///
  /// [payload] (the verification detail, when the verdict has one) is written
  /// only when the terminal write landed, in the same transaction.
  Future<int> completeLogIfActive(
    String workspaceId,
    String runId,
    AgentRunLogsTableCompanion terminal,
    AgentRunPayloadsTableCompanion payload,
  ) => transaction(() async {
    final updated =
        await (update(agentRunLogsTable)..where(
              (t) =>
                  t.id.equals(runId) &
                  t.workspaceId.equals(workspaceId) &
                  t.completedAt.isNull(),
            ))
            .write(terminal);
    if (updated > 0) {
      await writePayload(workspaceId, runId, payload);
    }
    return updated;
  });

  /// Whether [companion] carries at least one column to write.
  static bool _carriesColumns(UpdateCompanion<Object?> companion) =>
      companion.toColumns(false).isNotEmpty;

  /// Deletes run logs by agent id.
  Future<int> deleteLogsByAgentId(String agentId) =>
      (delete(agentRunLogsTable)..where((t) => t.agentId.equals(agentId))).go();
}
