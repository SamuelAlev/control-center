import 'package:control_center/core/database/daos/achievement_dao.dart';
import 'package:control_center/core/database/daos/activity_log_dao.dart';
import 'package:control_center/core/database/daos/agent_dao.dart';
import 'package:control_center/core/database/daos/agent_working_memory_dao.dart';
import 'package:control_center/core/database/daos/analytics_dao.dart';
import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/database/daos/calendar_dao.dart';
import 'package:control_center/core/database/daos/code_graph_dao.dart';
import 'package:control_center/core/database/daos/isolated_repo_dao.dart';
import 'package:control_center/core/database/daos/meeting_dao.dart';
import 'package:control_center/core/database/daos/memory_access_grant_dao.dart';
import 'package:control_center/core/database/daos/memory_domain_dao.dart';
import 'package:control_center/core/database/daos/memory_fact_dao.dart';
import 'package:control_center/core/database/daos/memory_policy_dao.dart';
import 'package:control_center/core/database/daos/messaging_dao.dart';
import 'package:control_center/core/database/daos/orchestration_dao.dart';
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
import 'package:control_center/core/database/tables/calendar_accounts.dart';
import 'package:control_center/core/database/tables/calendar_events.dart';
import 'package:control_center/core/database/tables/channel_messages.dart';
import 'package:control_center/core/database/tables/channel_participants.dart';
import 'package:control_center/core/database/tables/channels.dart';
import 'package:control_center/core/database/tables/code_edges.dart';
import 'package:control_center/core/database/tables/code_files.dart';
import 'package:control_center/core/database/tables/code_symbols.dart';
import 'package:control_center/core/database/tables/isolated_repos.dart';
import 'package:control_center/core/database/tables/meeting_action_items.dart';
import 'package:control_center/core/database/tables/meeting_calendar_links.dart';
import 'package:control_center/core/database/tables/meeting_decisions.dart';
import 'package:control_center/core/database/tables/meeting_speakers.dart';
import 'package:control_center/core/database/tables/meeting_transcript_segments.dart';
import 'package:control_center/core/database/tables/meetings.dart';
import 'package:control_center/core/database/tables/memory_access_grants.dart';
import 'package:control_center/core/database/tables/memory_domains.dart';
import 'package:control_center/core/database/tables/memory_facts.dart';
import 'package:control_center/core/database/tables/memory_policies.dart';
import 'package:control_center/core/database/tables/orchestrations_table.dart';
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
    MeetingsTable,
    MeetingTranscriptSegmentsTable,
    MeetingActionItemsTable,
    MeetingDecisionsTable,
    MeetingSpeakersTable,
    CalendarAccountsTable,
    CalendarEventsTable,
    MeetingCalendarLinksTable,
    OrchestrationsTable,
  ],
  daos: [
    WorkspaceDao,
    RepoDao,
    AgentDao,
    ActivityLogDao,
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
    MeetingDao,
    CalendarDao,
    OrchestrationDao,
  ],
)
/// The application's Drift database.
class AppDatabase extends _$AppDatabase {
  /// Creates the production database.
  AppDatabase() : super(_openConnection());

  /// Creates an in-memory database for testing.
  AppDatabase.forTesting(super.e);


  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createFts5Tables();
      await _createTicketIndexes();
      await _createPipelineIndexes();
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

  /// Creates the FTS5 indexes and their sync triggers.
  ///
  /// Both indexes carry a `workspace_id` column so a MATCH can be constrained
  /// to a single workspace at the index level (see `toWorkspaceScopedFtsMatch`).
  /// The column maps to the content table's own `workspace_id`, so FTS5
  /// `rebuild` stays valid.
  Future<void> _createFts5Tables() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS memory_facts_fts
      USING fts5(topic, content, workspace_id, content=memory_facts_table, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_ai AFTER INSERT ON memory_facts_table BEGIN
        INSERT INTO memory_facts_fts(rowid, topic, content, workspace_id)
        VALUES (new.rowid, new.topic, new.content, new.workspace_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_ad AFTER DELETE ON memory_facts_table BEGIN
        INSERT INTO memory_facts_fts(memory_facts_fts, rowid, topic, content, workspace_id)
        VALUES ('delete', old.rowid, old.topic, old.content, old.workspace_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_au AFTER UPDATE ON memory_facts_table BEGIN
        INSERT INTO memory_facts_fts(memory_facts_fts, rowid, topic, content, workspace_id)
        VALUES ('delete', old.rowid, old.topic, old.content, old.workspace_id);
        INSERT INTO memory_facts_fts(rowid, topic, content, workspace_id)
        VALUES (new.rowid, new.topic, new.content, new.workspace_id);
      END
    ''');
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS code_symbols_fts
      USING fts5(name, qualified_name, signature, docstring, workspace_id, content=code_symbols, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_ai AFTER INSERT ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring, workspace_id)
        VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring, new.workspace_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_ad AFTER DELETE ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring, workspace_id)
        VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring, old.workspace_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_au AFTER UPDATE ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring, workspace_id)
        VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring, old.workspace_id);
        INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring, workspace_id)
        VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring, new.workspace_id);
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

  ///
  /// v1 → v2 adds the meetings + transcript-segment tables (local
  /// meeting notes). v2 → v3 adds the structured meeting action-item + decision
  /// tables (the `meeting_summary` pipeline persists into them deterministically
  /// instead of scraping the notes markdown). Fresh installs build them via
  /// `onCreate`'s `createAll()`; existing databases create them here.
  List<MigrationStep> get _migrationSteps => <MigrationStep>[
    MigrationStep(1, 2, (m) async {
      await m.createTable(meetingsTable);
      await m.createTable(meetingTranscriptSegmentsTable);
    }),
    MigrationStep(2, 3, (m) async {
      await m.createTable(meetingActionItemsTable);
      await m.createTable(meetingDecisionsTable);
    }),
    // v3 → v4 adds the calendar feature: connected accounts, synced events,
    // and meeting↔event links. Their `@TableIndex` indexes (incl. the unique
    // ones) are built automatically by `createTable` here and `createAll` in
    // `onCreate` — no `customStatement` needed (that is only for the partial
    // ticket/pipeline indexes that carry a `WHERE` clause).
    MigrationStep(3, 4, (m) async {
      await m.createTable(calendarAccountsTable);
      await m.createTable(calendarEventsTable);
      await m.createTable(meetingCalendarLinksTable);
    }),
    // v4 → v5 allows several Google accounts per workspace: the calendar
    // account uniqueness moves from `(workspaceId, providerId)` to
    // `(workspaceId, accountEmail)`. Drop the old unique index and create the
    // new one. Fresh installs (and DBs upgrading from <4, whose v3→v4 step
    // builds the table from the current `@TableIndex`) already carry the new
    // index, so guard on the table actually existing before re-indexing.
    //
    // NB: drift keeps the `Table` suffix in SQL names — the table is
    // `calendar_accounts_table`, not `calendar_accounts`.
    MigrationStep(4, 5, (m) async {
      final exists = (await m.database
              .customSelect(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' "
                "AND name = 'calendar_accounts_table'",
              )
              .get())
          .isNotEmpty;
      if (!exists) {
        return;
      }
      await m.database.customStatement(
        'DROP INDEX IF EXISTS uq_calendar_accounts_ws_provider',
      );
      await m.database.customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_calendar_accounts_ws_email '
        'ON calendar_accounts_table (workspace_id, account_email)',
      );
    }),
    // v5 → v6 adds speaker diarization for meetings: a per-meeting capture
    // `mode`, a diarized `speakerLabel` on each transcript segment, and the
    // `meeting_speakers` table mapping diarization labels to (optional) display
    // names. All additive (new nullable/defaulted columns + a new table), so
    // existing meetings are untouched. Fresh installs build them via
    // `onCreate`'s `createAll()`.
    MigrationStep(5, 6, (m) async {
      await m.addColumn(meetingsTable, meetingsTable.mode);
      await m.addColumn(
        meetingTranscriptSegmentsTable,
        meetingTranscriptSegmentsTable.speakerLabel,
      );
      await m.createTable(meetingSpeakersTable);
    }),
    // v6 → v7 adds `auth_expired_at` to calendar accounts: a nullable timestamp
    // set when an account's OAuth refresh token dies (Google `invalid_grant`)
    // and cleared on the next successful sync / reconnect. Drives the in-app
    // "reconnect calendar" banner. Additive nullable column, so existing rows
    // are untouched. Fresh installs build it via `onCreate`'s `createAll()`.
    MigrationStep(6, 7, (m) async {
      await m.addColumn(calendarAccountsTable, calendarAccountsTable.authExpiredAt);
    }),
    // v7 → v8 is the "enterprise + orchestration" migration. It is additive
    // (new tables + new nullable/defaulted columns) plus one data-fix UPDATE,
    // so existing rows are untouched. Fresh installs build everything via
    // `onCreate`'s `createAll()`.
    //
    //   * orchestrations              — autonomous multi-agent orchestration
    //   * tickets.outputContractMode  — strict/permissive output-contract gate
    //   * agent_run_logs.*            — errorCode + pipeline correlation +
    //                                   memory/code-graph telemetry counters
    //   * activity_log.workspaceId    — workspace-scoped audit trail
    //   * agents.silenceTimeoutMinutes— per-agent silence-timeout override
    //   * memory_access_grants        — flip silent read defaults to write so
    //                                   agents can actually contribute policies
    MigrationStep(7, 8, (m) async {
      await m.createTable(orchestrationsTable);
      await m.addColumn(ticketsTable, ticketsTable.outputContractMode);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.errorCode);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.pipelineRunId);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.pipelineStepRunId);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.memoryReads);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.memoryWrites);
      await m.addColumn(agentRunLogsTable, agentRunLogsTable.codeGraphCalls);
      await m.addColumn(activityLogTable, activityLogTable.workspaceId);
      await m.addColumn(agentsTable, agentsTable.silenceTimeoutMinutes);
      await m.database.customStatement(
        "UPDATE memory_access_grants_table SET permission = 'write' "
        "WHERE permission = 'read'",
      );
    }),
    // v8 → v9 adds `title_is_custom` to meetings: a flag tracking whether the
    // user has manually renamed a meeting. While false, a linked calendar
    // event's title keeps the meeting title in sync (on link + on every
    // calendar sync); once the user edits the title it is "custom" and the
    // calendar never overwrites it. Additive defaulted column, so existing rows
    // are untouched (defaulting to not-custom, which is correct — they were
    // never linked). Fresh installs build it via `onCreate`'s `createAll()`.
    MigrationStep(8, 9, (m) async {
      await m.addColumn(meetingsTable, meetingsTable.titleIsCustom);
    }),
    // v9 → v10 adds `is_manual` to meeting action items and decisions: a flag
    // marking rows the user authored or edited in the detail view (vs. the
    // agent extracting them). A "Re-run summary" replaces only the agent rows,
    // so manual items survive re-summarization. Additive defaulted column, so
    // existing rows are untouched (defaulting to not-manual, which is correct —
    // they were all agent-extracted). Fresh installs build it via `onCreate`'s
    // `createAll()`.
    MigrationStep(9, 10, (m) async {
      await m.addColumn(meetingActionItemsTable, meetingActionItemsTable.isManual);
      await m.addColumn(meetingDecisionsTable, meetingDecisionsTable.isManual);
    }),
  ];

  /// Creates the partial-unique index that prevents duplicate remote mirrors
  /// (local tickets have a null `external_key`, so the index is partial).
  ///
  /// Partial indexes carry a `WHERE` clause, so they cannot be expressed as a
  /// `@TableIndex` on the table class and `createAll()` won't build them — they
  /// are created here from `onCreate` instead.
  Future<void> _createTicketIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_tickets_provider_externalKey '
      'ON tickets (provider, external_key) WHERE external_key IS NOT NULL',
    );
  }

  /// Creates the partial-unique index that enforces idempotency for
  /// event-triggered pipeline runs: at most one non-terminal run may exist per
  /// `(template_id, dedup_key)` tuple. Like [_createTicketIndexes], it is
  /// partial (only rows with a non-null `dedup_key` in a pending/running/
  /// suspended state participate), so it can't be a `@TableIndex` on
  /// [PipelineRunsTable] and is created here from `onCreate`.
  Future<void> _createPipelineIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_pipeline_runs_active_dedup '
      'ON pipeline_runs_table (template_id, dedup_key) '
      'WHERE dedup_key IS NOT NULL '
      "AND status IN ('pending','running','suspended')",
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
