import 'package:cc_persistence/database/daos/action_policy_dao.dart';
import 'package:cc_persistence/database/daos/activity_log_dao.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/daos/agent_goal_run_dao.dart';
import 'package:cc_persistence/database/daos/agent_runtime_state_dao.dart';
import 'package:cc_persistence/database/daos/agent_working_memory_dao.dart';
import 'package:cc_persistence/database/daos/approval_dao.dart';
import 'package:cc_persistence/database/daos/budget_dao.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/calendar_dao.dart';
import 'package:cc_persistence/database/daos/channel_extras_dao.dart';
import 'package:cc_persistence/database/daos/channel_repo_dao.dart';
import 'package:cc_persistence/database/daos/chat_link_dao.dart';
import 'package:cc_persistence/database/daos/code_graph_dao.dart';
import 'package:cc_persistence/database/daos/conversation_dao.dart';
import 'package:cc_persistence/database/daos/conversation_goal_dao.dart';
import 'package:cc_persistence/database/daos/cron_execution_dao.dart';
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/database/daos/evals_dao.dart';
import 'package:cc_persistence/database/daos/goal_dao.dart';
import 'package:cc_persistence/database/daos/isolated_repo_dao.dart';
import 'package:cc_persistence/database/daos/meeting_dao.dart';
import 'package:cc_persistence/database/daos/memory_access_grant_dao.dart';
import 'package:cc_persistence/database/daos/memory_belief_dao.dart';
import 'package:cc_persistence/database/daos/memory_conflict_dao.dart';
import 'package:cc_persistence/database/daos/memory_consolidation_log_dao.dart';
import 'package:cc_persistence/database/daos/memory_domain_dao.dart';
import 'package:cc_persistence/database/daos/memory_fact_dao.dart';
import 'package:cc_persistence/database/daos/memory_policy_dao.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/daos/notification_feed_dao.dart';
import 'package:cc_persistence/database/daos/orchestration_dao.dart';
import 'package:cc_persistence/database/daos/pipeline_dao.dart';
import 'package:cc_persistence/database/daos/pipeline_template_dao.dart';
import 'package:cc_persistence/database/daos/pipeline_trigger_dao.dart';
import 'package:cc_persistence/database/daos/plan_studio_dao.dart';
import 'package:cc_persistence/database/daos/project_dao.dart';
import 'package:cc_persistence/database/daos/provider_policy_dao.dart';
import 'package:cc_persistence/database/daos/pull_request_dao.dart';
import 'package:cc_persistence/database/daos/repo_dao.dart';
import 'package:cc_persistence/database/daos/review_channel_dao.dart';
import 'package:cc_persistence/database/daos/review_dao.dart';
import 'package:cc_persistence/database/daos/review_studio_dao.dart';
import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
import 'package:cc_persistence/database/daos/runtime_profile_dao.dart';
import 'package:cc_persistence/database/daos/skill_scan_dao.dart';
import 'package:cc_persistence/database/daos/sync_dao.dart';
import 'package:cc_persistence/database/daos/team_activity_dao.dart';
import 'package:cc_persistence/database/daos/team_dao.dart';
import 'package:cc_persistence/database/daos/ticket_dao.dart';
import 'package:cc_persistence/database/daos/ticket_link_dao.dart';
import 'package:cc_persistence/database/daos/ticket_sync_dao.dart';
import 'package:cc_persistence/database/daos/ticket_write_ledger_dao.dart';
import 'package:cc_persistence/database/daos/todo_dao.dart';
import 'package:cc_persistence/database/daos/user_activity_dao.dart';
import 'package:cc_persistence/database/daos/voice_profile_dao.dart';
import 'package:cc_persistence/database/daos/webhook_delivery_dao.dart';
import 'package:cc_persistence/database/daos/work_product_dao.dart';
import 'package:cc_persistence/database/daos/working_memory_item_dao.dart';
import 'package:cc_persistence/database/daos/workspace_invite_dao.dart';
import 'package:cc_persistence/database/daos/workspace_member_dao.dart';
import 'package:cc_persistence/database/daos/workspace_setting_dao.dart';
import 'package:cc_persistence/database/daos/write_ledger_dao.dart';
import 'package:cc_persistence/database/migration_steps.dart';
import 'package:cc_persistence/database/tables/action_policies_table.dart';
import 'package:cc_persistence/database/tables/activity_log_table.dart';
import 'package:cc_persistence/database/tables/agent_goal_runs_table.dart';
import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agent_runtime_state_table.dart';
import 'package:cc_persistence/database/tables/agent_working_memory.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/approval_comments_table.dart';
import 'package:cc_persistence/database/tables/approvals_table.dart';
import 'package:cc_persistence/database/tables/budget_incidents_table.dart';
import 'package:cc_persistence/database/tables/budget_policy_table.dart';
import 'package:cc_persistence/database/tables/caches.dart';
import 'package:cc_persistence/database/tables/calendar_accounts.dart';
import 'package:cc_persistence/database/tables/calendar_events.dart';
import 'package:cc_persistence/database/tables/calendar_sources.dart';
import 'package:cc_persistence/database/tables/channel_autonomy_table.dart';
import 'package:cc_persistence/database/tables/channel_messages.dart';
import 'package:cc_persistence/database/tables/channel_notes_table.dart';
import 'package:cc_persistence/database/tables/channel_participants.dart';
import 'package:cc_persistence/database/tables/channel_repos.dart';
import 'package:cc_persistence/database/tables/channels.dart';
import 'package:cc_persistence/database/tables/chat_links_tables.dart';
import 'package:cc_persistence/database/tables/code_edges.dart';
import 'package:cc_persistence/database/tables/code_files.dart';
import 'package:cc_persistence/database/tables/code_index_checkpoints.dart';
import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:cc_persistence/database/tables/conversation_goals_table.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/cron_executions_table.dart';
import 'package:cc_persistence/database/tables/episodic_edges.dart';
import 'package:cc_persistence/database/tables/evals_tables.dart';
import 'package:cc_persistence/database/tables/goals_table.dart';
import 'package:cc_persistence/database/tables/isolated_repos.dart';
import 'package:cc_persistence/database/tables/meeting_action_items.dart';
import 'package:cc_persistence/database/tables/meeting_calendar_links.dart';
import 'package:cc_persistence/database/tables/meeting_decisions.dart';
import 'package:cc_persistence/database/tables/meeting_speakers.dart';
import 'package:cc_persistence/database/tables/meeting_transcript_segments.dart';
import 'package:cc_persistence/database/tables/meetings.dart';
import 'package:cc_persistence/database/tables/memory_access_grants.dart';
import 'package:cc_persistence/database/tables/memory_beliefs.dart';
import 'package:cc_persistence/database/tables/memory_conflicts.dart';
import 'package:cc_persistence/database/tables/memory_consolidation_log.dart';
import 'package:cc_persistence/database/tables/memory_domains.dart';
import 'package:cc_persistence/database/tables/memory_facts.dart';
import 'package:cc_persistence/database/tables/memory_policies.dart';
import 'package:cc_persistence/database/tables/message_reactions_table.dart';
import 'package:cc_persistence/database/tables/notification_feed_table.dart';
import 'package:cc_persistence/database/tables/notification_read_marks_table.dart';
import 'package:cc_persistence/database/tables/orchestrations_table.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_step_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_templates_table.dart';
import 'package:cc_persistence/database/tables/pipeline_triggers_table.dart';
import 'package:cc_persistence/database/tables/plan_studio_tables.dart';
import 'package:cc_persistence/database/tables/projects_table.dart';
import 'package:cc_persistence/database/tables/provider_policies.dart';
import 'package:cc_persistence/database/tables/pull_requests.dart';
import 'package:cc_persistence/database/tables/remembered_decisions.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:cc_persistence/database/tables/review_channels.dart';
import 'package:cc_persistence/database/tables/review_drafts.dart';
import 'package:cc_persistence/database/tables/review_studio_tables.dart';
import 'package:cc_persistence/database/tables/run_transcripts_table.dart';
import 'package:cc_persistence/database/tables/runtime_profiles_table.dart';
import 'package:cc_persistence/database/tables/skill_scan_results_table.dart';
import 'package:cc_persistence/database/tables/sync_changes_table.dart';
import 'package:cc_persistence/database/tables/team_activity_log_table.dart';
import 'package:cc_persistence/database/tables/teams_table.dart';
import 'package:cc_persistence/database/tables/ticket_collaborators_table.dart';
import 'package:cc_persistence/database/tables/ticket_links_table.dart';
import 'package:cc_persistence/database/tables/ticket_sync_configs_table.dart';
import 'package:cc_persistence/database/tables/ticket_sync_links_table.dart';
import 'package:cc_persistence/database/tables/ticket_sync_log_table.dart';
import 'package:cc_persistence/database/tables/ticket_write_ledger_table.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:cc_persistence/database/tables/todos_table.dart';
import 'package:cc_persistence/database/tables/user_activity_table.dart';
import 'package:cc_persistence/database/tables/voice_profiles.dart';
import 'package:cc_persistence/database/tables/webhook_deliveries_table.dart';
import 'package:cc_persistence/database/tables/work_product_revisions_table.dart';
import 'package:cc_persistence/database/tables/work_products_table.dart';
import 'package:cc_persistence/database/tables/working_memory_items.dart';
import 'package:cc_persistence/database/tables/workspace_invites_table.dart';
import 'package:cc_persistence/database/tables/workspace_member_repo_grants_table.dart';
import 'package:cc_persistence/database/tables/workspace_members_table.dart';
import 'package:cc_persistence/database/tables/workspace_meta_table.dart';
import 'package:cc_persistence/database/tables/workspace_settings_table.dart';
import 'package:cc_persistence/database/tables/worktree_merge_log_table.dart';
import 'package:cc_persistence/database/tables/write_ledger_table.dart';
import 'package:drift/drift.dart';

part 'workspace_database.g.dart';

/// ONE workspace's database (`<dataDir>/workspaces/<id>.db`).
///
/// The second half of Control Center's persistence, and where nearly everything
/// lives: agents, channels, tickets, memory, pipelines, meetings, the code
/// graph, reviews, repos. There is one instance per workspace, handed out by
/// `WorkspaceDatabaseManager`.
///
/// **This class is the workspace-isolation boundary.** Isolation used to be a
/// convention — every query had to remember `WHERE workspace_id = ?`, policed
/// by a ratchet test that could only pattern-match SQL. Now it is structural: a
/// [WorkspaceDatabase] physically contains one workspace's rows and does not
/// declare `users`, `workspaces`, or any other workspace's data, so a
/// cross-workspace read is not a bug you can write — it does not compile.
///
/// Two consequences worth knowing:
///
///  * The `workspaceId` columns are still there and still written. They are
///    redundant *within* a file, but they keep the sync-feed triggers, the FTS
///    indexes and every existing row shape unchanged, and they make a file
///    self-describing if it is ever inspected on its own.
///  * Answering a question about *several* workspaces means opening several
///    databases. That fan-out is deliberately confined to
///    `CrossWorkspaceQueries`, so the cross-workspace surface stays enumerable
///    in one file instead of diffuse behind doc comments.
///
/// Boot does not open these files. Each one opens lazily on first touch and
/// pays its own `quick_check`, FTS/trigger install and `vector_init` then.
@DriftDatabase(
  tables: [
    ReposTable,
    AgentsTable,
    AgentRunLogsTable,
    AgentGoalRunsTable,
    PullRequestsTable,
    ReviewDrafts,
    CachesTable,
    ChannelsTable,
    ConversationsTable,
    ChannelParticipantsTable,
    ChannelReposTable,
    ChannelNotesTable,
    ChannelAutonomyTable,
    MessageReactionsTable,
    SyncSequencesTable,
    SyncChangesTable,
    ChannelMessagesTable,
    ReviewChannelsTable,
    ActivityLogTable,
    WorktreeMergeLogTable,
    BudgetPolicyTable,
    AgentWorkingMemoryTable,
    MemoryDomainsTable,
    MemoryFactsTable,
    MemoryPoliciesTable,
    MemoryAccessGrantsTable,
    MemoryConflictsTable,
    EpisodicEdgesTable,
    WorkingMemoryItemsTable,
    MemoryConsolidationLogTable,
    MemoryBeliefsTable,
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
    CodeIndexCheckpointsTable,
    IsolatedReposTable,
    MeetingsTable,
    MeetingTranscriptSegmentsTable,
    MeetingActionItemsTable,
    MeetingDecisionsTable,
    MeetingSpeakersTable,
    CalendarAccountsTable,
    CalendarEventsTable,
    CalendarSourcesTable,
    MeetingCalendarLinksTable,
    VoiceProfilesTable,
    OrchestrationsTable,
    OrchestrationRevisionsTable,
    PlanDocumentsTable,
    PlaybooksTable,
    ReviewCohortsTable,
    ApiContractSnapshotsTable,
    VisualDiffSnapshotsTable,
    ReviewAxisResultsTable,
    ProviderPoliciesTable,
    RememberedDecisionsTable,
    GoalsTable,
    BudgetIncidentsTable,
    ApprovalsTable,
    ApprovalCommentsTable,
    WorkProductsTable,
    WorkProductRevisionsTable,
    AgentRuntimeStateTable,
    RuntimeProfilesTable,
    TeamActivityLogTable,
    WebhookDeliveriesTable,
    CronExecutionsTable,
    TicketSyncConfigsTable,
    TicketSyncLinksTable,
    TicketSyncLogTable,
    TicketWriteLedgerTable,
    WriteLedgerTable,
    TodosTable,
    WorkspaceMembersTable,
    WorkspaceInvitesTable,
    UserActivityTable,
    WorkspaceMemberRepoGrantsTable,
    SessionRecordingsTable,
    GoldenSessionsTable,
    EvalSuitesTable,
    EvalRunsTable,
    AgentConfigVersionsTable,
    SkillScanResultsTable,
    ActionPoliciesTable,
    ConversationGoalsTable,
    RunTranscriptsTable,
    ChatChannelLinksTable,
    ChatUserLinksTable,
    WorkspaceMetaTable,
    WorkspaceSettingsTable,
    NotificationFeedTable,
    NotificationReadMarksTable,
  ],
  daos: [
    WorkspaceSettingDao,
    RepoDao,
    ChannelRepoDao,
    AgentDao,
    ActivityLogDao,
    PullRequestDao,
    ReviewDao,
    CacheDao,
    MessagingDao,
    ConversationDao,
    ReviewChannelDao,
    AgentWorkingMemoryDao,
    MemoryDomainDao,
    MemoryFactDao,
    MemoryPolicyDao,
    MemoryAccessGrantDao,
    MemoryConflictDao,
    EpisodicEdgeDao,
    WorkingMemoryItemDao,
    MemoryConsolidationLogDao,
    MemoryBeliefDao,
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
    VoiceProfileDao,
    OrchestrationDao,
    PlanStudioDao,
    ReviewStudioDao,
    SyncDao,
    ChannelExtrasDao,
    ProviderPolicyDao,
    GoalDao,
    BudgetDao,
    ApprovalDao,
    WorkProductDao,
    AgentRuntimeStateDao,
    RuntimeProfileDao,
    TeamActivityDao,
    WebhookDeliveryDao,
    CronExecutionDao,
    TicketSyncDao,
    TicketWriteLedgerDao,
    WriteLedgerDao,
    TodoDao,
    WorkspaceMemberDao,
    WorkspaceInviteDao,
    UserActivityDao,
    EvalsDao,
    SkillScanDao,
    ActionPolicyDao,
    ConversationGoalDao,
    RunTranscriptDao,
    AgentGoalRunDao,
    ChatLinkDao,
    NotificationFeedDao,
  ],
)
class WorkspaceDatabase extends _$WorkspaceDatabase {
  /// Creates the database for the workspace identified by [workspaceId] over a
  /// host-supplied [QueryExecutor].
  ///
  /// The connection is injected so the package stays Flutter-free: the server
  /// passes `openWorkspaceDatabase(dataDir:, workspaceId:)`. Diagnostics route
  /// through the optional [onWarn]/[onError] sinks for the same reason.
  WorkspaceDatabase(
    super.e, {
    required this.workspaceId,
    this.installId = 'unknown',
    this.onWarn,
    this.onError,
  });

  /// Creates an in-memory workspace database for testing.
  WorkspaceDatabase.forTesting(super.e, {this.workspaceId = 'test-workspace'})
    : installId = 'test-install',
      onWarn = null,
      onError = null;

  /// The workspace this database holds.
  ///
  /// Every row in this file belongs to it. Code that needs to stamp a
  /// `workspaceId` column, or to call a DAO method that still takes one, reads
  /// it from here rather than threading a separate parameter that could
  /// disagree with the file it is writing to.
  final String workspaceId;

  /// The `server_meta.install_id` of the server that owns this file, stamped
  /// into [WorkspaceMetaTable] when the file is created.
  ///
  /// It is what lets `workspace.import` tell "this is my own file, re-adopted"
  /// from "this file came from another install" — the latter is allowed, but
  /// logged rather than invisible.
  final String installId;

  /// Warning sink (e.g. a missing optional extension). Host-injected.
  final void Function(String tag, String message)? onWarn;

  /// Error sink (e.g. a failed integrity check). Host-injected.
  final void Function(String tag, String message)? onError;

  /// The current workspace schema version, as a const so non-database code
  /// (the server's /healthz build/compat block) can report it without
  /// instantiating a database. Keep in lockstep with [schemaVersion].
  static const int currentSchemaVersion = 6;

  @override
  int get schemaVersion => currentSchemaVersion;

  /// Writes a consistent, defragmented snapshot of this workspace to [path]
  /// using `VACUUM INTO`.
  ///
  /// Safe on a live WAL database (it takes a read transaction and writes a
  /// clean copy), so it runs while the server is serving. This is also the
  /// whole implementation of `workspace.export`: one workspace is one file, so
  /// exporting it is a single statement rather than a table-by-table dump.
  Future<void> backupTo(String path) =>
      customStatement('VACUUM INTO ?', [path]);

  /// Schema evolution for the per-workspace half.
  ///
  /// The split databases were introduced with a squashed baseline, and
  /// `onCreate` builds exactly the current table set — so a step that only DROPS
  /// a table has nothing to do (no database in existence ever created it), which
  /// is why removing the analytics tables folded back into the baseline instead
  /// of becoming a version.
  ///
  /// Append a `MigrationStep(from, to, migrate)` here (and bump
  /// [schemaVersion]) once there are deployed databases a change has to carry
  /// forward.
  List<MigrationStep> get _migrationSteps => <MigrationStep>[
    // v2: the audit trail gains the client IP and its resolved country.
    MigrationStep(1, 2, (Migrator m) async {
      await m.addColumn(userActivityTable, userActivityTable.ip);
      await m.addColumn(userActivityTable, userActivityTable.countryCode);
    }),
    // v4: the chat bridge's provider-agnostic link tables
    // (conversation↔channel, member↔user), each keyed by provider.
    //
    // There is deliberately no 2→3 step: v3 created Slack-named tables that
    // were generalized before any build shipped them, and `from < step.to`
    // means a v2 database runs this step too. So both paths converge here — a
    // v2 database simply creates the tables, while a local v3 database also
    // carries its Slack rows over as `provider = 'slack'` and drops the
    // originals (dropping a table drops its indexes with it).
    MigrationStep(3, 4, (Migrator m) async {
      await m.createTable(chatChannelLinksTable);
      await m.createTable(chatUserLinksTable);
      await _createChatIndexes(m);
      if (await _tableExists('slack_channel_links')) {
        await customStatement(
          'INSERT OR IGNORE INTO chat_channel_links '
          '(id, workspace_id, provider, external_team_id, '
          'external_channel_id, external_thread_id, cc_channel_id, '
          'created_by_user_id, created_at, last_activity_at) '
          "SELECT id, workspace_id, 'slack', slack_team_id, slack_channel_id, "
          'slack_thread_ts, cc_channel_id, created_by_user_id, created_at, '
          'last_activity_at FROM slack_channel_links',
        );
        await customStatement('DROP TABLE slack_channel_links');
      }
      if (await _tableExists('slack_user_links')) {
        await customStatement(
          'INSERT OR IGNORE INTO chat_user_links '
          '(id, workspace_id, provider, external_team_id, external_user_id, '
          'user_id, method, linked_at) '
          "SELECT id, workspace_id, 'slack', slack_team_id, slack_user_id, "
          'user_id, method, linked_at FROM slack_user_links',
        );
        await customStatement('DROP TABLE slack_user_links');
      }
    }),
    // v5: workspace-scoped settings KV (branch naming, agent/model defaults,
    // default sandbox capabilities, data-sharing policy). Previously these
    // lived in device-local preferences, so two members of one workspace — or
    // one member on two machines — disagreed about workspace policy.
    MigrationStep(4, 5, (Migrator m) async {
      await m.createTable(workspaceSettingsTable);
    }),
    // v6: the durable notification feed (raw notifications/* frames, recorded
    // once per domain event server-side) + per-user read/cleared watermarks.
    // Previously the bell's history lived in device-local preferences, so it
    // was machine-global (shared across every install on the box) and neither
    // per-workspace nor per-user.
    MigrationStep(5, 6, (Migrator m) async {
      await m.createTable(notificationFeedTable);
      await m.createTable(notificationReadMarksTable);
      await m.createIndex(idxNotificationFeedWorkspaceCreated);
    }),
  ];

  /// Whether [name] is a table in this database.
  ///
  /// The migration path above needs it because the legacy Slack tables exist
  /// only in databases that ran the superseded v3 step, and `INSERT … SELECT`
  /// from a missing table is an error, not an empty result.
  Future<bool> _tableExists(String name) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createFts5Tables();
      await _createTicketIndexes();
      await _createPipelineIndexes();
      await _createCronIndexes();
      await _createHotPathIndexes();
      await _createChatIndexes();
      await _createSyncTriggers();
      await into(workspaceMetaTable).insert(
        WorkspaceMetaTableCompanion.insert(
          workspaceId: workspaceId,
          installId: installId,
          createdWithSchemaVersion: schemaVersion,
          createdAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrReplace,
      );
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
      // Wait up to 5s for a lock instead of failing a contended write
      // immediately with SQLITE_BUSY. The server runs background reconcilers
      // (orphan-run reaper, sync, pipeline resume) concurrently with live
      // writes; WAL lets readers proceed, but two writers still contend and
      // without this a reconciler tick can abort a user write outright.
      await customStatement('PRAGMA busy_timeout = 5000');
      // Cap the per-connection page cache at 8MB (negative = KiB units) and
      // let SQLite hand cache memory back to the OS under pressure. This bound
      // matters more than it used to: N open workspaces means N caches, so an
      // unbounded per-connection cache would multiply.
      await customStatement('PRAGMA cache_size = -8192');
      // Bound the WAL file so a long-running server doesn't accumulate an
      // unbounded -wal that gets mmapped/paged in on every checkpoint.
      await customStatement('PRAGMA journal_size_limit = 67108864');
      // vector_init builds the sqlite_vector extension's PER-CONNECTION,
      // in-memory context — it is NOT persisted in the database file. It must
      // therefore run on EVERY open, not just onCreate: an existing database
      // reopened after a restart otherwise has no context, and every
      // vector_full_scan KNN query fails with "unable to retrieve context"
      // (semantic/hybrid search silently degraded to keyword-only for the
      // whole session). beforeOpen runs after onCreate/onUpgrade, so the
      // tables always exist by now.
      await _initVectorIndex();
      // FTS5 external-content tables + their sync triggers. Idempotent
      // (everything is IF NOT EXISTS), and installed on every open rather than
      // only in `onCreate`: a trigger lost for any reason (maintenance, a
      // hand-run migration, a restored backup, an imported workspace file) is
      // otherwise never rebuilt, and the failure is silent — inserts stop
      // reaching the index and search just returns less and less.
      await _createFts5Tables();
      // Deterministic-sync change-feed triggers (PRD 16 §6). Idempotent
      // (CREATE TRIGGER IF NOT EXISTS) and installed on every open like the
      // FTS triggers, so the adopted stores always record into sync_changes.
      await _createSyncTriggers();
      // Corruption check on open — `quick_check`, NOT `integrity_check`.
      //
      // `integrity_check` verifies every b-tree page in the file, so its cost
      // scales with the whole database: on a 2.6GB graph-heavy DB it took 21s
      // warm (worse cold). `quick_check` catches the corruption that actually
      // happens (bad page structure, broken indexes) while skipping the
      // exhaustive cross-page work — 2.8s on that same file. Splitting the
      // database moved this off the boot path entirely: it is now paid per
      // workspace, on first touch of that workspace, against a file holding one
      // workspace's history instead of every workspace's.
      final startedAt = DateTime.now();
      final result = await customSelect('PRAGMA quick_check').get();
      final status = result.first.read<String>('quick_check');
      if (status != 'ok') {
        onError?.call(
          'WorkspaceDatabase',
          'SQLite quick_check failed for workspace $workspaceId: $status',
        );
      }
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed > const Duration(seconds: 2)) {
        onWarn?.call(
          'WorkspaceDatabase',
          'quick_check took ${elapsed.inMilliseconds}ms for workspace '
              '$workspaceId — this workspace is large enough that opening it '
              'is a visible pause',
        );
      }
    },
  );

  /// Installs the deterministic-sync change-feed triggers (PRD 16 §6).
  ///
  /// Every adopted table (`tickets`; the messaging tables; `channel_notes`;
  /// `message_reactions`) gets `AFTER INSERT/UPDATE/DELETE` triggers that
  /// allocate the monotonic seq and append a `sync_changes` row INSIDE the
  /// writing transaction — delta id and data are atomic by construction, and
  /// every write path (services, reconcilers, sync engines) is covered without
  /// instrumenting a single DAO method.
  ///
  /// The trigger SQL is deliberately unchanged by the database split, including
  /// the `workspace_id` columns and the `sync_sequences` upsert: `sync_changes`
  /// is a wire format that delta clients already speak, and per-workspace
  /// sequencing was always the semantics. In this file `sync_sequences` simply
  /// holds a single row.
  ///
  /// Messaging child tables resolve their workspace through `channels`; on a
  /// channel-delete CASCADE the parent row is already gone, so child deletions
  /// are deliberately not recorded — the channel's own delete change is, and
  /// delta clients cascade child removal locally.
  Future<void> _createSyncTriggers() async {
    // (table, store, workspaceExpr(NEW/OLD), pkColumn, ctxExpr)
    const specs = [
      ('tickets', 'tickets', '{ROW}.workspace_id', 'id', 'NULL'),
      ('channels', 'messaging', '{ROW}.workspace_id', 'id', 'NULL'),
      (
        'conversations',
        'messaging',
        '{ROW}.workspace_id',
        'id',
        '{ROW}.channel_id',
      ),
      (
        'channel_messages',
        'messaging',
        '(SELECT workspace_id FROM channels WHERE id = {ROW}.channel_id)',
        'id',
        '{ROW}.channel_id',
      ),
      (
        'channel_participants',
        'messaging',
        '(SELECT workspace_id FROM channels WHERE id = {ROW}.channel_id)',
        'id',
        '{ROW}.channel_id',
      ),
      (
        'channel_notes',
        'notes',
        '{ROW}.workspace_id',
        'id',
        '{ROW}.channel_id',
      ),
      (
        'message_reactions',
        'messaging',
        '{ROW}.workspace_id',
        'id',
        '{ROW}.channel_id',
      ),
    ];
    for (final (table, store, wsTemplate, pk, ctxTemplate) in specs) {
      for (final (op, sqlOp, row) in [
        ('insert', 'INSERT', 'NEW'),
        ('update', 'UPDATE', 'NEW'),
        ('delete', 'DELETE', 'OLD'),
      ]) {
        final ws = wsTemplate.replaceAll('{ROW}', row);
        final ctx = ctxTemplate.replaceAll('{ROW}', row);
        final changeOp = op == 'delete' ? 'delete' : 'upsert';
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_$op '
          'AFTER $sqlOp ON $table '
          'WHEN $ws IS NOT NULL '
          'BEGIN '
          'INSERT INTO sync_sequences(workspace_id, next_seq) '
          'VALUES ($ws, 1) ON CONFLICT(workspace_id) DO NOTHING; '
          'UPDATE sync_sequences SET next_seq = next_seq + 1 '
          'WHERE workspace_id = $ws; '
          'INSERT INTO sync_changes'
          '(workspace_id, seq, store, tbl, pk, op, ctx, created_at_ms) '
          'VALUES ($ws, '
          '(SELECT next_seq - 1 FROM sync_sequences WHERE workspace_id = $ws), '
          "'$store', '$table', $row.$pk, '$changeOp', $ctx, "
          "CAST(strftime('%s', 'now') AS INTEGER) * 1000); "
          'END',
        );
      }
    }
  }

  /// Creates the FTS5 indexes and their sync triggers.
  ///
  /// Both indexes keep their `workspace_id` column even though a file now holds
  /// exactly one workspace: the column maps to the content table's own
  /// `workspace_id`, so FTS5 `rebuild` stays valid, and dropping it would be a
  /// schema change for no gain. The MATCH-level workspace filter
  /// (`toWorkspaceScopedFtsMatch`) is now belt-and-braces rather than the
  /// isolation mechanism.
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
    // In-channel message search (§8.4). Scoped by `channel_id` — messages have
    // no `workspace_id` column (they belong to a channel, which does), so the
    // search RPC validates channel ownership and MATCHes with `channel_id = ?`.
    await _createChannelMessagesFts();
  }

  /// Creates the `channel_messages_fts` external-content FTS5 index + its
  /// insert/delete/update sync triggers.
  Future<void> _createChannelMessagesFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS channel_messages_fts
      USING fts5(content, channel_id, content=channel_messages, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channel_messages_ai AFTER INSERT ON channel_messages BEGIN
        INSERT INTO channel_messages_fts(rowid, content, channel_id)
        VALUES (new.rowid, new.content, new.channel_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channel_messages_ad AFTER DELETE ON channel_messages BEGIN
        INSERT INTO channel_messages_fts(channel_messages_fts, rowid, content, channel_id)
        VALUES ('delete', old.rowid, old.content, old.channel_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channel_messages_au AFTER UPDATE ON channel_messages BEGIN
        INSERT INTO channel_messages_fts(channel_messages_fts, rowid, content, channel_id)
        VALUES ('delete', old.rowid, old.content, old.channel_id);
        INSERT INTO channel_messages_fts(rowid, content, channel_id)
        VALUES (new.rowid, new.content, new.channel_id);
      END
    ''');
  }

  /// Rebuilds every FTS5 index from its content table.
  ///
  /// Needed after a bulk copy that bypassed the triggers — which is exactly what
  /// `workspace.import` does when it adopts a file.
  Future<void> rebuildFtsIndexes() async {
    for (final index in const [
      'memory_facts_fts',
      'code_symbols_fts',
      'channel_messages_fts',
    ]) {
      await customStatement("INSERT INTO $index($index) VALUES('rebuild')");
    }
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
      onWarn?.call(
        'WorkspaceDatabase',
        'sqlite_vector extension unavailable, skipping vector index for $table: $e',
      );
    }
  }

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

  /// Composite indexes for the two hottest filter+sort read paths, which the
  /// single-column `@TableIndex`es don't fully cover:
  ///  * channel-message history: `WHERE channel_id = ? ORDER BY created_at DESC`
  ///  * agent run logs by agent: `WHERE workspace_id = ? AND agent_id = ?
  ///    ORDER BY started_at DESC`
  /// A composite serves both the filter and the sort from one index, avoiding a
  /// filesort over a growing table. `IF NOT EXISTS` keeps it idempotent.
  Future<void> _createHotPathIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channel_messages_channel_created '
      'ON channel_messages (channel_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_agent_run_logs_ws_agent_started '
      'ON agent_run_logs_table (workspace_id, agent_id, started_at)',
    );
    // Partial index over unresolved code-graph edges: the indexer probes
    // "any pending references for this partition?" before loading anything,
    // and this keeps that probe O(unresolved) instead of a repo-range scan.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_code_edges_unresolved '
      'ON code_edges (workspace_id, repo_id, checkout_id) '
      'WHERE target_symbol_id IS NULL',
    );
  }

  /// Creates the partial-unique index that keeps a bot-DM bridge single-valued.
  ///
  /// The table's `(workspace_id, provider, external_channel_id,
  /// external_thread_id)` unique index cannot do it: SQLite treats NULLs as
  /// distinct, so a conversation-level link (null `external_thread_id` — a DM
  /// with the bot) could be inserted twice and the bridge would then stream one
  /// turn into two CC channels. Partial indexes carry a `WHERE`, so this cannot
  /// be a `@TableIndex`.
  ///
  /// Pass [m] from a migration: `createTable` issues only `CREATE TABLE`, so the
  /// declared `@TableIndex`es have to be created explicitly there. `onCreate`
  /// calls this with no migrator because `createAll()` already built them.
  Future<void> _createChatIndexes([Migrator? m]) async {
    if (m != null) {
      await m.createIndex(uqChatChannelLinksWsProviderChannelThread);
      await m.createIndex(idxChatChannelLinksCcChannelId);
      await m.createIndex(uqChatUserLinksWsProviderTeamUser);
      await m.createIndex(uqChatUserLinksWsProviderUser);
    }
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_channel_links_ws_provider_dm '
      'ON chat_channel_links (workspace_id, provider, external_channel_id) '
      'WHERE external_thread_id IS NULL',
    );
  }

  /// Creates the unique index that makes a cron fire idempotent: at most one
  /// `cron_executions` row may exist per `(trigger_id, planned_at)` slot, so a
  /// re-fire of the same scheduled instant (after a restart, or from
  /// overlapping ticks) is a no-op.
  Future<void> _createCronIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_cron_executions_slot '
      'ON cron_executions_table (trigger_id, planned_at)',
    );
  }

  /// Creates the partial-unique index that enforces idempotency for
  /// event-triggered pipeline runs: at most one non-terminal run may exist per
  /// `(template_id, dedup_key)` tuple.
  Future<void> _createPipelineIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_pipeline_runs_active_dedup '
      'ON pipeline_runs_table (template_id, dedup_key) '
      'WHERE dedup_key IS NOT NULL '
      "AND status IN ('pending','running','suspended')",
    );
  }
}
