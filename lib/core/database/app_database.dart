import 'package:control_center/core/database/daos/achievement_dao.dart';
import 'package:control_center/core/database/daos/agent_dao.dart';
import 'package:control_center/core/database/daos/agent_working_memory_dao.dart';
import 'package:control_center/core/database/daos/analytics_dao.dart';
import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/database/daos/code_graph_dao.dart';
import 'package:control_center/core/database/daos/isolated_repo_dao.dart';
import 'package:control_center/core/database/daos/memory_access_grant_dao.dart';
import 'package:control_center/core/database/daos/memory_domain_dao.dart';
import 'package:control_center/core/database/daos/memory_fact_dao.dart';
import 'package:control_center/core/database/daos/memory_policy_dao.dart';
import 'package:control_center/core/database/daos/messaging_dao.dart';
import 'package:control_center/core/database/daos/pipeline_dao.dart';
import 'package:control_center/core/database/daos/pipeline_template_dao.dart';
import 'package:control_center/core/database/daos/pipeline_trigger_dao.dart';
import 'package:control_center/core/database/daos/project_dao.dart';
import 'package:control_center/core/database/daos/pull_request_dao.dart';
import 'package:control_center/core/database/daos/repo_dao.dart';
import 'package:control_center/core/database/daos/review_channel_dao.dart';
import 'package:control_center/core/database/daos/review_dao.dart';
import 'package:control_center/core/database/daos/rss_dao.dart';
import 'package:control_center/core/database/daos/streak_dao.dart';
import 'package:control_center/core/database/daos/team_dao.dart';
import 'package:control_center/core/database/daos/ticket_dao.dart';
import 'package:control_center/core/database/daos/ticket_link_dao.dart';
import 'package:control_center/core/database/daos/workspace_dao.dart';
import 'package:control_center/core/database/migration_steps.dart';
import 'package:control_center/core/database/tables/achievements_table.dart';
import 'package:control_center/core/database/tables/activity_log_table.dart';
import 'package:control_center/core/database/tables/agent_daily_stats_table.dart';
import 'package:control_center/core/database/tables/agent_run_logs.dart';
import 'package:control_center/core/database/tables/agent_working_memory.dart';
import 'package:control_center/core/database/tables/agents.dart';
import 'package:control_center/core/database/tables/budget_policy_table.dart';
import 'package:control_center/core/database/tables/caches.dart';
import 'package:control_center/core/database/tables/channel_messages.dart';
import 'package:control_center/core/database/tables/channel_participants.dart';
import 'package:control_center/core/database/tables/channels.dart';
import 'package:control_center/core/database/tables/code_edges.dart';
import 'package:control_center/core/database/tables/code_files.dart';
import 'package:control_center/core/database/tables/code_symbols.dart';
import 'package:control_center/core/database/tables/isolated_repos.dart';
import 'package:control_center/core/database/tables/memory_access_grants.dart';
import 'package:control_center/core/database/tables/memory_domains.dart';
import 'package:control_center/core/database/tables/memory_facts.dart';
import 'package:control_center/core/database/tables/memory_policies.dart';
import 'package:control_center/core/database/tables/pipeline_runs_table.dart';
import 'package:control_center/core/database/tables/pipeline_step_runs_table.dart';
import 'package:control_center/core/database/tables/pipeline_templates_table.dart';
import 'package:control_center/core/database/tables/pipeline_triggers_table.dart';
import 'package:control_center/core/database/tables/projects_table.dart';
import 'package:control_center/core/database/tables/pull_requests.dart';
import 'package:control_center/core/database/tables/repos.dart';
import 'package:control_center/core/database/tables/review_channels.dart';
import 'package:control_center/core/database/tables/review_drafts.dart';
import 'package:control_center/core/database/tables/rss_articles.dart';
import 'package:control_center/core/database/tables/rss_feeds.dart';
import 'package:control_center/core/database/tables/streaks_table.dart';
import 'package:control_center/core/database/tables/teams_table.dart';
import 'package:control_center/core/database/tables/ticket_collaborators_table.dart';
import 'package:control_center/core/database/tables/ticket_links_table.dart';
import 'package:control_center/core/database/tables/tickets_table.dart';
import 'package:control_center/core/database/tables/workspace_repos.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:control_center/core/database/tables/worktree_merge_log_table.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_vector/sqlite_vector.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WorkspacesTable,
    ReposTable,
    WorkspaceReposTable,
    AgentsTable,
    AgentRunLogsTable,
    PullRequestsTable,
    ReviewDrafts,
    CachesTable,
    ChannelsTable,
    ChannelParticipantsTable,
    ChannelMessagesTable,
    RssFeedsTable,
    RssArticlesTable,
    AchievementsTable,
    AgentDailyStatsTable,
    StreaksTable,
    ReviewChannelsTable,
    ActivityLogTable,
    WorktreeMergeLogTable,
    BudgetPolicyTable,
    AgentWorkingMemoryTable,
    MemoryDomainsTable,
    MemoryFactsTable,
    MemoryPoliciesTable,
    MemoryAccessGrantsTable,
    PipelineRunsTable,
    PipelineStepRunsTable,
    PipelineTemplatesTable,
    PipelineTriggersTable,
    TicketsTable,
    TicketCollaboratorsTable,
    TicketLinksTable,
    ProjectsTable,
    TeamsTable,
    TeamMembersTable,
    CodeSymbolsTable,
    CodeEdgesTable,
    CodeFilesTable,
    IsolatedReposTable,
  ],
  daos: [
    WorkspaceDao,
    RepoDao,
    AgentDao,
    PullRequestDao,
    ReviewDao,
    CacheDao,
    MessagingDao,
    RssDao,
    AchievementDao,
    AnalyticsDao,
    StreakDao,
    ReviewChannelDao,
    AgentWorkingMemoryDao,
    MemoryDomainDao,
    MemoryFactDao,
    MemoryPolicyDao,
    MemoryAccessGrantDao,
    PipelineDao,
    PipelineTemplateDao,
    PipelineTriggerDao,
    TicketDao,
    TicketLinkDao,
    ProjectDao,
    TeamDao,
    CodeGraphDao,
    IsolatedRepoDao,
  ],
)
/// The application's Drift database.
class AppDatabase extends _$AppDatabase {
  /// Creates the production database.
  AppDatabase() : super(_openConnection());

  /// Creates an in-memory database for testing.
  AppDatabase.forTesting(super.e);

  /// New DAOs not yet present in generated code.
  @override
  late final PipelineDao pipelineDao = PipelineDao(this);
  @override
  late final PipelineTemplateDao pipelineTemplateDao =
      PipelineTemplateDao(this);
  @override
  late final PipelineTriggerDao pipelineTriggerDao = PipelineTriggerDao(this);
  @override
  late final TicketDao ticketDao = TicketDao(this);
  @override
  late final TicketLinkDao ticketLinkDao = TicketLinkDao(this);
  @override
  late final ProjectDao projectDao = ProjectDao(this);
  @override
  late final TeamDao teamDao = TeamDao(this);
  @override
  late final CodeGraphDao codeGraphDao = CodeGraphDao(this);
  @override
  late final IsolatedRepoDao isolatedRepoDao = IsolatedRepoDao(this);

  @override
  int get schemaVersion => 31;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createFts5Tables();
      await _createTicketIndexes();
      await _initVectorIndex();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      for (final step in _migrationSteps) {
        if (from < step.to) {
          await step.migrate(m);
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      final result = await customSelect('PRAGMA integrity_check').get();
      final status = result.first.read<String>('integrity_check');
      if (status != 'ok') {
        AppLog.e(
          'AppDatabase',
          'SQLite integrity_check failed: $status',
        );
      }
    },
  );

  Future<void> _createFts5Tables() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS memory_facts_fts
      USING fts5(topic, content, content=memory_facts_table, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_ai AFTER INSERT ON memory_facts_table BEGIN
        INSERT INTO memory_facts_fts(rowid, topic, content)
        VALUES (new.rowid, new.topic, new.content);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_ad AFTER DELETE ON memory_facts_table BEGIN
        INSERT INTO memory_facts_fts(memory_facts_fts, rowid, topic, content)
        VALUES ('delete', old.rowid, old.topic, old.content);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_au AFTER UPDATE ON memory_facts_table BEGIN
        INSERT INTO memory_facts_fts(memory_facts_fts, rowid, topic, content)
        VALUES ('delete', old.rowid, old.topic, old.content);
        INSERT INTO memory_facts_fts(rowid, topic, content)
        VALUES (new.rowid, new.topic, new.content);
      END
    ''');
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS code_symbols_fts
      USING fts5(name, qualified_name, signature, docstring, content=code_symbols, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_ai AFTER INSERT ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
        VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_ad AFTER DELETE ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
        VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_au AFTER UPDATE ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
        VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
        INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
        VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
      END
    ''');
  }

  Future<void> _initVectorIndex() async {
    await _initVectorIndexFor('memory_facts_table');
    await _initVectorIndexFor('code_symbols');
  }

  Future<void> _initVectorIndexFor(String table) async {
    try {
      await customStatement(
        "SELECT vector_init('$table', 'embedding', 'type=FLOAT32,dimension=384')",
      );
    } on Exception catch (e) {
      AppLog.w(
        'AppDatabase',
        'sqlite_vector extension unavailable, skipping vector index for $table: $e',
      );
    }
  }

  List<MigrationStep> get _migrationSteps => [
    MigrationStep(1, 2, (m) async {
      // v1 → v2: review_channels.priority → urgency (rename column),
      // workspaces.review_concurrency added (NOT NULL DEFAULT 3).
      await m.addColumn(workspacesTable, workspacesTable.reviewConcurrency);
      await customStatement(
        'ALTER TABLE review_channels RENAME COLUMN priority TO urgency',
      );
    }),
    MigrationStep(2, 3, (m) async {
      // v2 → v3: remove unused columns.
      await customStatement('ALTER TABLE workspaces DROP COLUMN status');
      await customStatement('ALTER TABLE repos DROP COLUMN branch');
      await customStatement('ALTER TABLE agents_table DROP COLUMN role');
    }),
    MigrationStep(3, 4, (m) async {
      // v3 → v4: remove urgency column from review_channels.
      await customStatement('ALTER TABLE review_channels DROP COLUMN urgency');
    }),
    MigrationStep(4, 5, (m) async {
      // v4 → v5: add performance indexes on frequently-queried columns.
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_agents_workspaceId ON agents_table (workspace_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_agent_run_logs_workspaceId ON agent_run_logs_table (workspace_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_memory_facts_supersededBy ON memory_facts_table (superseded_by)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_channel_messages_messageType ON channel_messages (message_type)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_channel_participants_channelId ON channel_participants (channel_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_channels_workspaceId ON channels (workspace_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_review_channels_workspaceId ON review_channels (workspace_id)',
      );
    }),
    MigrationStep(5, 6, (m) async {
      // v5 → v6: previously added orchestration_runs_table. Superseded by
      // pipeline_runs_table / pipeline_step_runs_table in v9. The legacy
      // table is dropped in v16; the v5→v6 migration is intentionally a
      // no-op so historical databases skip cleanly to v9+.
    }),
    MigrationStep(6, 7, (m) async {
      // v6 → v7: previously created working_sessions_table and
      // working_session_revisions_table. Both tables have been removed
      // from the schema; the migration is now a no-op. Existing
      // databases that already ran v6→v7 are unaffected (the tables
      // just sit empty in SQLite).
    }),
    MigrationStep(7, 8, (m) async {
      // v7 → v8: add deleted_at column for workspace soft delete.
      await m.addColumn(workspacesTable, workspacesTable.deletedAt);
    }),
    MigrationStep(8, 9, (m) async {
      // v8 → v9: pipeline runs and step runs tables.
      await m.createTable(pipelineRunsTable);
      await m.createTable(pipelineStepRunsTable);
    }),
    MigrationStep(9, 10, (m) async {
      // v9 → v10: pipeline triggers table.
      await m.createTable(pipelineTriggersTable);
    }),
    MigrationStep(10, 11, (m) async {
      // v10 → v11: tasks table. The `tasks` table was absorbed into `tickets`
      // in v23; recreated here via raw SQL so the migration keeps compiling
      // after the Dart table class was removed. The v22→v23 step migrates its
      // rows into `tickets` and drops it.
      await customStatement('''
        CREATE TABLE IF NOT EXISTS tasks_table (
          id TEXT NOT NULL PRIMARY KEY,
          pipeline_run_id TEXT REFERENCES pipeline_runs_table (id) ON DELETE SET NULL,
          workspace_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          expected_output_schema TEXT,
          assigned_agent_id TEXT NOT NULL,
          delegated_by_agent_id TEXT,
          parent_task_id TEXT REFERENCES tasks_table (id) ON DELETE CASCADE,
          status TEXT NOT NULL DEFAULT 'pending',
          output_json TEXT,
          error_message TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          started_at INTEGER,
          finished_at INTEGER
        )
      ''');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_pipelineRunId '
        'ON tasks_table (pipeline_run_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_assignedAgentId '
        'ON tasks_table (assigned_agent_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_parentTaskId '
        'ON tasks_table (parent_task_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_status_agent '
        'ON tasks_table (status, assigned_agent_id)',
      );
    }),
    MigrationStep(11, 12, (m) async {
      // v11 → v12: teams and team members tables.
      await m.createTable(teamsTable);
      await m.createTable(teamMembersTable);
    }),
    MigrationStep(12, 13, (m) async {
      // v12 → v13: link tasks back to the pipeline step that created them.
      // Raw SQL (the Dart `tasks` table class was removed in v23).
      await customStatement(
        'ALTER TABLE tasks_table ADD COLUMN pipeline_step_id TEXT',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_pipelineStepId '
        'ON tasks_table (pipeline_step_id)',
      );
    }),
    MigrationStep(13, 14, (m) async {
      // v13 → v14: persist stack traces on failures.
      await m.addColumn(
        pipelineRunsTable,
        pipelineRunsTable.errorStackTrace,
      );
      await m.addColumn(
        pipelineStepRunsTable,
        pipelineStepRunsTable.errorStackTrace,
      );
    }),
    MigrationStep(14, 15, (m) async {
      // v14 → v15: idempotency for event-triggered runs.
      await m.addColumn(pipelineRunsTable, pipelineRunsTable.dedupKey);
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_pipeline_runs_active_dedup '
        'ON pipeline_runs_table (template_id, dedup_key) '
        'WHERE dedup_key IS NOT NULL '
        "AND status IN ('pending','running','suspended')",
      );
    }),
    MigrationStep(15, 16, (m) async {
      // v15 → v16: drop the unused orchestration scaffold.
      await customStatement('DROP TABLE IF EXISTS orchestration_runs_table');
    }),
    MigrationStep(16, 17, (m) async {
      // v16 → v17: placeholder — migration deferred and re-added in a
      // later schema version.
    }),
    MigrationStep(17, 18, (m) async {
      // v17 → v18: add is_enabled column to pipeline templates.
      await m.addColumn(
        pipelineTemplatesTable,
        pipelineTemplatesTable.isEnabled,
      );
    }),
    MigrationStep(18, 19, (m) async {
      // v18 → v19: pipeline engine — cost rollup, retry persistence, sub-flow
      // parenting, version pinning, dry-run, and cron triggers.
      await m.addColumn(
        pipelineRunsTable,
        pipelineRunsTable.parentPipelineRunId,
      );
      await m.addColumn(pipelineRunsTable, pipelineRunsTable.parentStepId);
      await m.addColumn(pipelineRunsTable, pipelineRunsTable.templateVersion);
      await m.addColumn(pipelineRunsTable, pipelineRunsTable.totalCostCents);
      await m.addColumn(pipelineRunsTable, pipelineRunsTable.totalTokens);
      await m.addColumn(pipelineRunsTable, pipelineRunsTable.dryRun);
      await m.addColumn(
        pipelineStepRunsTable,
        pipelineStepRunsTable.attemptCount,
      );
      await m.addColumn(pipelineTemplatesTable, pipelineTemplatesTable.version);
      await m.addColumn(
        pipelineTriggersTable,
        pipelineTriggersTable.cronExpression,
      );
      await m.addColumn(
        pipelineTriggersTable,
        pipelineTriggersTable.lastFiredAt,
      );
    }),
    MigrationStep(19, 20, (m) async {
      // v19 → v20: code graph + code facts — code_symbols / code_edges /
      // code_files tables, the code_symbols FTS5 index + sync triggers, and
      // the code_symbols vector index (mirrors the memory_facts setup).
      await m.createTable(codeSymbolsTable);
      await m.createTable(codeEdgesTable);
      await m.createTable(codeFilesTable);
      await customStatement('''
        CREATE VIRTUAL TABLE IF NOT EXISTS code_symbols_fts
        USING fts5(name, qualified_name, signature, docstring, content=code_symbols, content_rowid=rowid)
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS code_symbols_ai AFTER INSERT ON code_symbols BEGIN
          INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
          VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS code_symbols_ad AFTER DELETE ON code_symbols BEGIN
          INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
          VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS code_symbols_au AFTER UPDATE ON code_symbols BEGIN
          INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
          VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
          INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
          VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
        END
      ''');
      try {
        await customStatement(
          "SELECT vector_init('code_symbols', 'embedding', 'type=FLOAT32,dimension=384')",
        );
      } on Exception catch (_) {
        // sqlite_vector unavailable — degrade to FTS-only (matches memory).
      }
    }),
    MigrationStep(20, 21, (m) async {
      // v20 → v21: declared manual-run inputs on pipeline templates. The
      // run form is built from this column; existing rows default to `[]`.
      await m.addColumn(
        pipelineTemplatesTable,
        pipelineTemplatesTable.inputsJson,
      );
    }),
    MigrationStep(21, 22, (m) async {
      // v21 → v22: per-trigger event-payload match filter (e.g. fire a PR
      // status-changed trigger only when status ∈ {merged, closed}). Existing
      // rows default to `{}` (match every matching event).
      await m.addColumn(
        pipelineTriggersTable,
        pipelineTriggersTable.matchJson,
      );
    }),
    MigrationStep(22, 23, (m) async {
      // v22 → v23: unify the `tasks` feature into the new `tickets` model and
      // add ticketing tables. The local `tasks` rows migrate into `tickets`
      // (provider 'local', mapped statuses); `tasks_table` is then dropped
      // (pre-1.0, no backwards-compat).
      await m.createTable(ticketsTable);
      await m.createTable(ticketCollaboratorsTable);
      await _createTicketIndexes();
      // Migrate existing local tasks into tickets, preserving ids so
      // parent_task_id self-references resolve.
      await customStatement(
        'INSERT INTO tickets ('
        'id, workspace_id, provider, title, description, status, '
        'parent_ticket_id, assigned_agent_id, delegated_by_agent_id, '
        'pipeline_run_id, pipeline_step_id, expected_output_schema, '
        'output_json, error_message, priority, mode, labels, metadata, '
        'linked_pr_ids, created_at, started_at, finished_at, updated_at) '
        'SELECT '
        "id, workspace_id, 'local', name, description, "
        'CASE status '
        "WHEN 'pending' THEN 'open' "
        "WHEN 'inProgress' THEN 'inProgress' "
        "WHEN 'completed' THEN 'done' "
        "WHEN 'failed' THEN 'failed' "
        "WHEN 'cancelled' THEN 'cancelled' "
        "ELSE 'open' END, "
        'parent_task_id, assigned_agent_id, delegated_by_agent_id, '
        'pipeline_run_id, pipeline_step_id, expected_output_schema, '
        "output_json, error_message, 0, 'chat', '[]', '{}', '[]', "
        'created_at, started_at, finished_at, created_at '
        'FROM tasks_table',
      );
      await customStatement('DROP TABLE IF EXISTS tasks_table');
    }),
    MigrationStep(23, 24, (m) async {
      // v23 → v24: add unique index on (workspace_id, name) in agents table
      // to prevent duplicate agent names per workspace at the DB level.
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_agents_workspace_name '
        'ON agents_table (workspace_id, name)',
      );
    }),
    MigrationStep(24, 25, (m) async {
      // v24 → v25: add role column to agents table.
      await m.addColumn(agentsTable, agentsTable.role);
    }),
    MigrationStep(25, 26, (m) async {
      // v25 → v26: add unique index on (ticketId, agentId) for
      // ticket_collaborators to enable insertOnConflictUpdate.
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS '
        'uq_ticket_collaborators_ticket_agent '
        'ON ticket_collaborators (ticket_id, agent_id)',
      );
    }),
    MigrationStep(26, 27, (m) async {
      // v26 → v27: add new columns to tickets (lifecycle, lock, policy, origins).
      await m.addColumn(ticketsTable, ticketsTable.version);
      await m.addColumn(ticketsTable, ticketsTable.originKind);
      await m.addColumn(ticketsTable, ticketsTable.checkoutRunId);
      await m.addColumn(ticketsTable, ticketsTable.executionLockedAt);
      await m.addColumn(ticketsTable, ticketsTable.checkoutAgentId);
      await m.addColumn(ticketsTable, ticketsTable.executionPolicyJson);
      await m.addColumn(ticketsTable, ticketsTable.executionStateJson);
      await m.addColumn(ticketsTable, ticketsTable.recoveryActionsJson);
      await m.addColumn(ticketsTable, ticketsTable.blockedAt);
      await m.addColumn(ticketsTable, ticketsTable.cancelledAt);
      await m.addColumn(ticketsTable, ticketsTable.completedAt);

      // Add new columns to agent_run_logs (run tracking, recovery, context).
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.ticketId);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.channelId);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.errorFamily);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.lastOutputAt);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.continuationSummary);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.contextSnapshotJson);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.retryOfRunId);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.retryAttempt);

      // Update default for status column to include 'pending'.
      await customStatement(
        "UPDATE agent_run_logs SET status = 'running' WHERE status = 'running'",
      );

      // Add new indices.
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_agent_run_logs_ticket '
        'ON agent_run_logs (ticket_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_agent_run_logs_status '
        'ON agent_run_logs (status)',
      );
    }),
    MigrationStep(27, 28, (m) async {
      // v27 → v28: make pipeline_runs_table.workspace_id NOT NULL.
      // Replace any null workspaceIds with 'unknown_workspace'.
      await customStatement(
        'UPDATE pipeline_runs_table '
        "SET workspace_id = 'unknown_workspace' "
        'WHERE workspace_id IS NULL',
      );
      await customStatement(
        'CREATE TABLE pipeline_runs_tmp ('
        '  id TEXT NOT NULL PRIMARY KEY,'
        '  template_id TEXT NOT NULL,'
        '  workspace_id TEXT NOT NULL,'
        '  status TEXT NOT NULL DEFAULT \'pending\','
        '  state_json TEXT NOT NULL DEFAULT \'{}\','
        '  trigger_event_type TEXT,'
        '  trigger_payload_json TEXT,'
        '  started_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,'
        '  finished_at TEXT,'
        '  error_message TEXT,'
        '  error_stack_trace TEXT,'
        '  dedup_key TEXT,'
        '  parent_pipeline_run_id TEXT,'
        '  parent_step_id TEXT,'
        '  template_version INTEGER NOT NULL DEFAULT 1,'
        '  total_cost_cents INTEGER NOT NULL DEFAULT 0,'
        '  total_tokens INTEGER NOT NULL DEFAULT 0,'
        '  dry_run INTEGER NOT NULL DEFAULT 0'
        ')',
      );
      await customStatement(
        'INSERT INTO pipeline_runs_tmp SELECT * FROM pipeline_runs_table',
      );
      await customStatement('DROP TABLE pipeline_runs_table');
      await customStatement(
        'ALTER TABLE pipeline_runs_tmp RENAME TO pipeline_runs_table',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pipeline_runs_status '
        'ON pipeline_runs_table (status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pipeline_runs_workspaceId '
        'ON pipeline_runs_table (workspace_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pipeline_runs_templateId '
        'ON pipeline_runs_table (template_id)',
      );
    }),
    MigrationStep(28, 29, (m) async {
      // v28 → v29: scope the code graph by workspace. code_symbols / code_edges
      // / code_files gain a workspace_id column, and their deterministic ids now
      // include workspaceId (workspaces are isolated worktrees that can share a
      // repoId — keying by repoId alone leaked one workspace's graph into
      // another's queries). The id format change makes old rows incompatible, so
      // the index is dropped and rebuilt from scratch; the `index_code` pipeline
      // re-indexes each repo per workspace on demand (pre-1.0, no data to keep).
      await customStatement('DROP TRIGGER IF EXISTS code_symbols_ai');
      await customStatement('DROP TRIGGER IF EXISTS code_symbols_ad');
      await customStatement('DROP TRIGGER IF EXISTS code_symbols_au');
      await customStatement('DROP TABLE IF EXISTS code_symbols_fts');
      await customStatement('DROP TABLE IF EXISTS code_edges');
      await customStatement('DROP TABLE IF EXISTS code_files');
      await customStatement('DROP TABLE IF EXISTS code_symbols');
      await m.createTable(codeSymbolsTable);
      await m.createTable(codeEdgesTable);
      await m.createTable(codeFilesTable);
      await customStatement('''
        CREATE VIRTUAL TABLE IF NOT EXISTS code_symbols_fts
        USING fts5(name, qualified_name, signature, docstring, content=code_symbols, content_rowid=rowid)
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS code_symbols_ai AFTER INSERT ON code_symbols BEGIN
          INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
          VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS code_symbols_ad AFTER DELETE ON code_symbols BEGIN
          INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
          VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS code_symbols_au AFTER UPDATE ON code_symbols BEGIN
          INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
          VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
          INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
          VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
        END
      ''');
      try {
        await customStatement(
          "SELECT vector_init('code_symbols', 'embedding', 'type=FLOAT32,dimension=384')",
        );
      } on Exception catch (_) {
        // sqlite_vector unavailable — degrade to FTS-only (matches memory).
      }
    }),
    MigrationStep(29, 30, (m) async {
      // v29 → v30: track per-conversation isolated copy-on-write worktrees so
      // they can be reused across dispatches and garbage-collected when the
      // unit ends (ticket done/won't-do, conversation deleted, PR merged).
      await m.createTable(isolatedReposTable);
    }),
    MigrationStep(30, 31, (m) async {
      // v30 → v31: ticket dependencies + projects. Adds the `ticket_links`
      // table (directional blocks / relates_to / duplicate_of edges), the
      // `projects` table (a workspace-scoped grouping), and `tickets.project_id`
      // (nullable; cleared in application code when a project is deleted, so it
      // orphans rather than cascades its tickets).
      await m.createTable(ticketLinksTable);
      await m.createTable(projectsTable);
      await m.addColumn(ticketsTable, ticketsTable.projectId);
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tickets_project '
        'ON tickets (project_id)',
      );
    }),
  ];

  /// Creates the partial-unique index that prevents duplicate remote mirrors
  /// (local tickets have a null `external_key`, so the index is partial). Run
  /// from both `onCreate` and the v22→v23 migration.
  Future<void> _createTicketIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_tickets_provider_externalKey '
      'ON tickets (provider, external_key) WHERE external_key IS NOT NULL',
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final file = await controlCenterDatabaseFile();
      final cacheBase = (await getTemporaryDirectory()).path;
      sqlite3.sqlite3.tempDirectory = cacheBase;
      sqlite3.sqlite3.loadSqliteVectorExtension();
      return NativeDatabase.createInBackground(file);
    });
  }
}
