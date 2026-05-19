import 'package:cc_persistence/database/daos/action_policy_dao.dart';
import 'package:cc_persistence/database/daos/activity_log_dao.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/daos/agent_goal_run_dao.dart';
import 'package:cc_persistence/database/daos/agent_runtime_state_dao.dart';
import 'package:cc_persistence/database/daos/agent_working_memory_dao.dart';
import 'package:cc_persistence/database/daos/approval_dao.dart';
import 'package:cc_persistence/database/daos/approval_routing_policy_dao.dart';
import 'package:cc_persistence/database/daos/budget_dao.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/calendar_dao.dart';
import 'package:cc_persistence/database/daos/chat_link_dao.dart';
import 'package:cc_persistence/database/daos/code_graph_dao.dart';
import 'package:cc_persistence/database/daos/conversation_dao.dart';
import 'package:cc_persistence/database/daos/conversation_goal_dao.dart';
import 'package:cc_persistence/database/daos/cron_execution_dao.dart';
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/database/daos/evals_dao.dart';
import 'package:cc_persistence/database/daos/goal_dao.dart';
import 'package:cc_persistence/database/daos/guard_decision_dao.dart';
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
import 'package:cc_persistence/database/daos/repo_script_run_dao.dart';
import 'package:cc_persistence/database/daos/review_dao.dart';
import 'package:cc_persistence/database/daos/review_space_dao.dart';
import 'package:cc_persistence/database/daos/review_studio_dao.dart';
import 'package:cc_persistence/database/daos/rig_dao.dart';
import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
import 'package:cc_persistence/database/daos/runtime_profile_dao.dart';
import 'package:cc_persistence/database/daos/sandbox_exec_grant_dao.dart';
import 'package:cc_persistence/database/daos/skill_scan_dao.dart';
import 'package:cc_persistence/database/daos/skill_source_dao.dart';
import 'package:cc_persistence/database/daos/space_extras_dao.dart';
import 'package:cc_persistence/database/daos/space_repo_dao.dart';
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
import 'package:cc_persistence/database/daos/workspace_role_dao.dart';
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
import 'package:cc_persistence/database/tables/approval_routing_policies_table.dart';
import 'package:cc_persistence/database/tables/approvals_table.dart';
import 'package:cc_persistence/database/tables/budget_incidents_table.dart';
import 'package:cc_persistence/database/tables/budget_policy_table.dart';
import 'package:cc_persistence/database/tables/caches.dart';
import 'package:cc_persistence/database/tables/calendar_accounts.dart';
import 'package:cc_persistence/database/tables/calendar_events.dart';
import 'package:cc_persistence/database/tables/calendar_sources.dart';
import 'package:cc_persistence/database/tables/chat_links_tables.dart';
import 'package:cc_persistence/database/tables/code_edges.dart';
import 'package:cc_persistence/database/tables/code_files.dart';
import 'package:cc_persistence/database/tables/code_index_checkpoints.dart';
import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:cc_persistence/database/tables/conversation_goals_table.dart';
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/cron_executions_table.dart';
import 'package:cc_persistence/database/tables/episodic_edges.dart';
import 'package:cc_persistence/database/tables/evals_tables.dart';
import 'package:cc_persistence/database/tables/goals_table.dart';
import 'package:cc_persistence/database/tables/guard_decisions_table.dart';
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
import 'package:cc_persistence/database/tables/notification_item_states_table.dart';
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
import 'package:cc_persistence/database/tables/repo_script_runs.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:cc_persistence/database/tables/review_drafts.dart';
import 'package:cc_persistence/database/tables/review_spaces.dart';
import 'package:cc_persistence/database/tables/review_studio_tables.dart';
import 'package:cc_persistence/database/tables/rigs_tables.dart';
import 'package:cc_persistence/database/tables/run_transcripts_table.dart';
import 'package:cc_persistence/database/tables/runtime_profiles_table.dart';
import 'package:cc_persistence/database/tables/sandbox_exec_grants_table.dart';
import 'package:cc_persistence/database/tables/skill_scan_results_table.dart';
import 'package:cc_persistence/database/tables/skill_sources_table.dart';
import 'package:cc_persistence/database/tables/space_autonomy_table.dart';
import 'package:cc_persistence/database/tables/space_notes_table.dart';
import 'package:cc_persistence/database/tables/space_participants.dart';
import 'package:cc_persistence/database/tables/space_repos.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
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
import 'package:cc_persistence/database/tables/workspace_roles_table.dart';
import 'package:cc_persistence/database/tables/workspace_settings_table.dart';
import 'package:cc_persistence/database/tables/write_ledger_table.dart';
import 'package:drift/drift.dart';

part 'workspace_database.g.dart';

/// ONE workspace's database (`<dataDir>/workspaces/<id>.db`).
///
/// The second half of Control Center's persistence and where nearly everything
/// lives: agents, spaces, tickets, memory, pipelines, meetings, the code
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
///    indexes and every existing row shape unchanged and they make a file
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
    SpacesTable,
    ConversationsTable,
    SpaceParticipantsTable,
    SpaceReposTable,
    SpaceNotesTable,
    SpaceAutonomyTable,
    MessageReactionsTable,
    SyncSequencesTable,
    SyncChangesTable,
    ConversationMessagesTable,
    ReviewSpacesTable,
    ActivityLogTable,
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
    ReviewDependencyDiffsTable,
    ReviewRunSnapshotsTable,
    ProviderPoliciesTable,
    GoalsTable,
    BudgetIncidentsTable,
    ApprovalsTable,
    ApprovalCommentsTable,
    ApprovalRoutingPoliciesTable,
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
    SandboxExecGrantsTable,
    GuardDecisionsTable,
    WorkspaceRolesTable,
    ConversationGoalsTable,
    RunTranscriptsTable,
    ChatSpaceLinksTable,
    ChatUserLinksTable,
    WorkspaceMetaTable,
    WorkspaceSettingsTable,
    NotificationFeedTable,
    NotificationReadMarksTable,
    NotificationItemStatesTable,
    RigSessionsTable,
    RigActionLogTable,
    SkillSourcesTable,
    RepoScriptRunsTable,
  ],
  daos: [
    WorkspaceSettingDao,
    RepoDao,
    RepoScriptRunDao,
    SpaceRepoDao,
    AgentDao,
    ActivityLogDao,
    PullRequestDao,
    ReviewDao,
    CacheDao,
    MessagingDao,
    ConversationDao,
    ReviewSpaceDao,
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
    SpaceExtrasDao,
    ProviderPolicyDao,
    GoalDao,
    BudgetDao,
    ApprovalDao,
    ApprovalRoutingPolicyDao,
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
    RigDao,
    SkillSourceDao,
    SandboxExecGrantDao,
    GuardDecisionDao,
    WorkspaceRoleDao,
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
    this.skipIntegrityCheck = false,
    this.onIntegrityChecked,
  });

  /// Creates an in-memory workspace database for testing.
  WorkspaceDatabase.forTesting(super.e, {this.workspaceId = 'test-workspace'})
    : installId = 'test-install',
      onWarn = null,
      onError = null,
      skipIntegrityCheck = false,
      onIntegrityChecked = null;

  /// Skips the `PRAGMA quick_check` on this open.
  ///
  /// Set by `WorkspaceDatabaseManager` when this process has already checked
  /// this file. The check is a statement about bytes on disk that only this
  /// process writes, so paying 2.8s again on a reopen would re-derive an answer
  /// that cannot have changed — and reopening is now routine, because a
  /// cross-workspace read closes the files it opened.
  final bool skipIntegrityCheck;

  /// Called after a `quick_check` completes (pass or fail), so the manager can
  /// stop asking for it on later opens of this file.
  final void Function()? onIntegrityChecked;

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
  static const int currentSchemaVersion = 7;

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
  /// The current schema IS the baseline: `onCreate` builds everything current
  /// at version 1 and this list is empty. It has been squashed twice — first
  /// when the Space · Conversation · Thread cutover renamed every messaging
  /// table out from under the pre-cutover chain, and again when the tables
  /// dropped their redundant `_table` suffix, which renamed 46 of them. Both
  /// times the chain described tables the product no longer has, and replaying
  /// it would have meant carrying a mapper for data nothing reads.
  ///
  /// A file written before a squash is NOT carried forward: nothing renames
  /// its tables, so the first query against it fails with `no such table`.
  /// Such a file is replaced, the same way the pre-split single-file
  /// `control_center.db` simply stopped being opened.
  ///
  /// Append a [MigrationStep] here (and bump [currentSchemaVersion]) for every
  /// schema change from now on.
  List<MigrationStep> get _migrationSteps => <MigrationStep>[
    // v1 → v2: skill sources — the GitHub repositories registered as skill
    // catalogs (the skills.sh registry replacement). Purely additive; a fresh
    // database already builds the table in `onCreate`, this step carries
    // existing workspace files forward.
    MigrationStep(
      1,
      2,
      (m) async {
        await m.createTable(skillSourcesTable);
        await _createIndexIfMissing(m, idxSkillSourcesWorkspace);
      },
    ),
    // v2 → v3: the session tree. `conversation_messages.parent_message_id`
    // turns the message list into a tree and `conversations.leaf_message_id`
    // names the branch tip, so branching is a pointer move rather than a
    // delete. Purely additive and both nullable: every existing row is a
    // linear chain with no parent recorded, which reads exactly as it did
    // before — the tree is only consulted by the branch/fork/tree paths.
    MigrationStep(
      2,
      3,
      (m) async {
        await _addColumnIfMissing(
          m,
          conversationMessagesTable,
          conversationMessagesTable.parentMessageId,
        );
        await _addColumnIfMissing(
          m,
          conversationsTable,
          conversationsTable.leafMessageId,
        );
      },
    ),
    // v3 → v4: per-repo lifecycle scripts. Two nullable columns on `repos`
    // (`setup_script`, `archive_script`) and the `repo_script_runs` audit
    // table. Purely additive; a fresh database already builds all of it in
    // `onCreate`, this step carries existing workspace files forward.
    MigrationStep(
      3,
      4,
      (m) async {
        await _addColumnIfMissing(
          m,
          reposTable,
          reposTable.setupScript,
        );
        await _addColumnIfMissing(
          m,
          reposTable,
          reposTable.archiveScript,
        );
        await m.createTable(repoScriptRunsTable);
        await _createIndexIfMissing(m, idxRepoScriptRunsRepo);
        await _createIndexIfMissing(m, idxRepoScriptRunsSpace);
      },
    ),
    // v4 → v5: sandbox exec grants. Records whether the operator allowed
    // running binaries from inside a worktree, which the macOS writable-dir
    // exec block otherwise denies wholesale. Purely additive; a fresh database
    // already builds it in `onCreate`, this step carries existing files
    // forward. An absent row means "not asked yet", so nothing is implied for
    // workspaces that predate this.
    MigrationStep(
      4,
      5,
      (m) async {
        await m.createTable(sandboxExecGrantsTable);
        await _createIndexIfMissing(m, idxSandboxExecGrantsWorkspace);
      },
    ),
    // v5 → v6: the enterprise permissions batch. Three new tables —
    // `approval_routing_policies` (the routing policy's durable home; it used
    // to be a `caches` row the retention sweep deleted after 21 quiet days),
    // `guard_decisions` (the hash-chained authorization audit spine) and
    // `workspace_roles` (custom subtractive roles) — plus three nullable
    // columns on `action_policies` (`constraint_json`, `expires_at`,
    // `enforcement`) whose NULL reads exactly as the pre-column behavior
    // (match everything / never expire / hard). Purely additive; a fresh
    // database builds all of it in `onCreate`.
    MigrationStep(
      5,
      6,
      (m) async {
        await m.createTable(approvalRoutingPoliciesTable);
        await m.createTable(guardDecisionsTable);
        await _createIndexIfMissing(m, idxGuardDecisionsWorkspace);
        await _createIndexIfMissing(m, idxGuardDecisionsTime);
        await m.createTable(workspaceRolesTable);
        await _createIndexIfMissing(m, idxWorkspaceRolesWorkspace);
        await _addColumnIfMissing(
          m,
          actionPoliciesTable,
          actionPoliciesTable.constraintJson,
        );
        await _addColumnIfMissing(
          m,
          actionPoliciesTable,
          actionPoliciesTable.expiresAt,
        );
        await _addColumnIfMissing(
          m,
          actionPoliciesTable,
          actionPoliciesTable.enforcement,
        );
      },
    ),
    // v6 → v7: code-graph reference-edge cleanup. Unresolved reference edges
    // (target_symbol_id NULL) are write-only rows — no graph query can see
    // them, they exist only as retry input for the name-resolution pass — and
    // measured on a real index 80% of them referenced external packages
    // (`react`, `vitest`, vendor namespaces) that can never resolve, at ~500MB
    // with their indexes. The indexer now prunes them after every resolution
    // pass and the extractor no longer emits package imports at all; this step
    // removes the ones already on disk, because a quiet repo's checkpoint
    // short-circuits every future run and the organic prune would never fire.
    // Bound edges are untouched.
    MigrationStep(
      6,
      7,
      (m) async {
        await m.database.customStatement(
          'DELETE FROM code_edges '
          'WHERE target_symbol_id IS NULL AND target_name IS NOT NULL',
        );
      },
    ),
  ];

  /// Creates [index] unless the file already has it.
  ///
  /// Same reasoning as [_addColumnIfMissing]: a re-entered step must not throw
  /// on work a previous attempt already did.
  Future<void> _createIndexIfMissing(Migrator m, Index index) async {
    final existing = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?",
      variables: [Variable<String>(index.entityName)],
    ).get();
    if (existing.isEmpty) {
      await m.createIndex(index);
    }
  }

  /// Adds [column] to [table] unless the file already has it.
  ///
  /// **Why every step has to be safe to re-run.** A migration is not atomic
  /// across statements: a crash (or a rewound `user_version`) can leave a file
  /// that has some of a step's changes and not others, and drift only stamps
  /// the new version when the whole `onUpgrade` returns. A bare
  /// `ALTER TABLE ADD COLUMN` on a column that is already there throws, the
  /// version is never stamped, and the workspace then fails to open FOREVER —
  /// a far worse outcome than the missing column the step was adding.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final existing = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    final present = existing.any(
      (row) => row.read<String>('name') == column.name,
    );
    if (!present) {
      await m.addColumn(table, column);
    }
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
      // reopened after a restart otherwise has no context and every
      // vector_full_scan KNN query fails with "unable to retrieve context"
      // (semantic/hybrid search silently degraded to keyword-only for the
      // whole session). beforeOpen runs after onCreate/onUpgrade, so the
      // tables always exist by now.
      await _initVectorIndex();
      // FTS5 external-content tables + their sync triggers. Idempotent
      // (everything is IF NOT EXISTS) and installed on every open rather than
      // only in `onCreate`: a trigger lost for any reason (maintenance, a
      // hand-run migration, a restored backup, an imported workspace file) is
      // otherwise never rebuilt and the failure is silent — inserts stop
      // reaching the index and search just returns less and less.
      await _createFts5Tables();
      // Deterministic-sync change-feed triggers (PRD 16 §6). Idempotent
      // (CREATE TRIGGER IF NOT EXISTS) and installed on every open like the
      // FTS triggers, so the adopted stores always record into sync_changes.
      await _createSyncTriggers();
      // One-time compaction after the v6→v7 edge cleanup: that step deletes
      // what was ~500MB of unresolved reference edges on graph-heavy
      // workspaces, and SQLite never returns freed pages to the OS on its own
      // — without this the file keeps its old size as empty freelist pages
      // forever. VACUUM cannot run inside the migration transaction, which is
      // why it lives here: `beforeOpen` runs after the steps, outside any
      // transaction. Rewrites the file once, then never again.
      final upgradedFrom = details.versionBefore;
      if (upgradedFrom != null && upgradedFrom < 7) {
        final startedAt = DateTime.now();
        await customStatement('VACUUM');
        final elapsed = DateTime.now().difference(startedAt);
        if (elapsed > const Duration(seconds: 2)) {
          onWarn?.call(
            'WorkspaceDatabase',
            'post-migration VACUUM took ${elapsed.inMilliseconds}ms for '
                'workspace $workspaceId — this workspace is large enough that '
                'opening it is a visible pause',
          );
        }
      }
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
      if (skipIntegrityCheck) {
        return;
      }
      final startedAt = DateTime.now();
      final result = await customSelect('PRAGMA quick_check').get();
      final status = result.first.read<String>('quick_check');
      if (status != 'ok') {
        onError?.call(
          'WorkspaceDatabase',
          'SQLite quick_check failed for workspace $workspaceId: $status',
        );
      }
      onIntegrityChecked?.call();
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
  /// Every adopted table (`tickets`; the messaging tables; `space_notes`;
  /// `message_reactions`) gets `AFTER INSERT/UPDATE/DELETE` triggers that
  /// allocate the monotonic seq and append a `sync_changes` row INSIDE the
  /// writing transaction — delta id and data are atomic by construction and
  /// every write path (services, reconcilers, sync engines) is covered without
  /// instrumenting a single DAO method.
  ///
  /// The trigger SQL is deliberately unchanged by the database split, including
  /// the `workspace_id` columns and the `sync_sequences` upsert: `sync_changes`
  /// is a wire format that delta clients already speak and per-workspace
  /// sequencing was always the semantics. In this file `sync_sequences` simply
  /// holds a single row.
  ///
  /// Messaging child tables resolve their workspace through `spaces`; on a
  /// space-delete CASCADE the parent row is already gone, so child deletions
  /// are deliberately not recorded — the space's own delete change is and
  /// delta clients cascade child removal locally.
  Future<void> _createSyncTriggers() async {
    // (table, store, workspaceExpr(NEW/OLD), pkColumn, ctxExpr)
    const specs = [
      ('tickets', 'tickets', '{ROW}.workspace_id', 'id', 'NULL'),
      ('spaces', 'messaging', '{ROW}.workspace_id', 'id', 'NULL'),
      (
        'conversations',
        'messaging',
        '{ROW}.workspace_id',
        'id',
        '{ROW}.space_id',
      ),
      (
        'conversation_messages',
        'messaging',
        '(SELECT workspace_id FROM spaces WHERE id = {ROW}.space_id)',
        'id',
        '{ROW}.space_id',
      ),
      (
        'space_participants',
        'messaging',
        '(SELECT workspace_id FROM spaces WHERE id = {ROW}.space_id)',
        'id',
        '{ROW}.space_id',
      ),
      (
        'space_notes',
        'notes',
        '{ROW}.workspace_id',
        'id',
        '{ROW}.space_id',
      ),
      (
        'message_reactions',
        'messaging',
        '{ROW}.workspace_id',
        'id',
        '{ROW}.space_id',
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
        // A message's `embedding` is not on the wire and no delta client can
        // observe it, but the backfill writes one UPDATE per message (200 per
        // batch) and each fired three statements plus a `spaces` subselect
        // and produced a `sync_changes` row nobody reads. `updateMessageEmbedding`
        // is the only writer of that column and it writes nothing else, so
        // "the embedding is unchanged" cleanly separates real updates from
        // backfill noise — and unlike an `UPDATE OF` column list it cannot go
        // stale when the table gains a column.
        final embeddingGuard =
            table == 'conversation_messages' && op == 'update'
            ? ' AND NEW.embedding IS OLD.embedding'
            : '';
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS trg_sync_${table}_$op '
          'AFTER $sqlOp ON $table '
          'WHEN $ws IS NOT NULL$embeddingGuard '
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
  /// `workspace_id`, so FTS5 `rebuild` stays valid and dropping it would be a
  /// schema change for no gain. The MATCH-level workspace filter
  /// (`toWorkspaceScopedFtsMatch`) is now belt-and-braces rather than the
  /// isolation mechanism.
  Future<void> _createFts5Tables() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS memory_facts_fts
      USING fts5(topic, content, workspace_id, content=memory_facts, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_ai AFTER INSERT ON memory_facts BEGIN
        INSERT INTO memory_facts_fts(rowid, topic, content, workspace_id)
        VALUES (new.rowid, new.topic, new.content, new.workspace_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_ad AFTER DELETE ON memory_facts BEGIN
        INSERT INTO memory_facts_fts(memory_facts_fts, rowid, topic, content, workspace_id)
        VALUES ('delete', old.rowid, old.topic, old.content, old.workspace_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS memory_facts_au AFTER UPDATE ON memory_facts BEGIN
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
    // In-space message search (§8.4). Scoped by `space_id` — messages have
    // no `workspace_id` column (they belong to a space, which does), so the
    // search RPC validates space ownership and MATCHes with `space_id = ?`.
    await _createSpaceMessagesFts();
  }

  /// Creates the `conversation_messages_fts` external-content FTS5 index + its
  /// insert/delete/update sync triggers.
  Future<void> _createSpaceMessagesFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS conversation_messages_fts
      USING fts5(content, space_id, content=conversation_messages, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS conversation_messages_ai AFTER INSERT ON conversation_messages BEGIN
        INSERT INTO conversation_messages_fts(rowid, content, space_id)
        VALUES (new.rowid, new.content, new.space_id);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS conversation_messages_ad AFTER DELETE ON conversation_messages BEGIN
        INSERT INTO conversation_messages_fts(conversation_messages_fts, rowid, content, space_id)
        VALUES ('delete', old.rowid, old.content, old.space_id);
      END
    ''');
    // `OF content, space_id` — the only two columns this index covers.
    // Without it, an embedding-only UPDATE (the backfill writes one per
    // message, 200 per batch) still ran a delete+insert of UNCHANGED text
    // through FTS5. Any statement that writes either indexed column still
    // fires, so the index cannot drift.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS conversation_messages_au
      AFTER UPDATE OF content, space_id ON conversation_messages BEGIN
        INSERT INTO conversation_messages_fts(conversation_messages_fts, rowid, content, space_id)
        VALUES ('delete', old.rowid, old.content, old.space_id);
        INSERT INTO conversation_messages_fts(rowid, content, space_id)
        VALUES (new.rowid, new.content, new.space_id);
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
      'conversation_messages_fts',
    ]) {
      await customStatement("INSERT INTO $index($index) VALUES('rebuild')");
    }
  }

  Future<void> _initVectorIndex() async {
    await _initVectorIndexFor('memory_facts');
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

  /// Composite indexes for the hottest filter+sort read paths, which the
  /// single-column `@TableIndex`es don't fully cover:
  ///  * space-message history: `WHERE space_id = ? ORDER BY created_at DESC`
  ///  * message history by CONVERSATION, which is what every page/window query
  ///    actually filters on (`conversation_id != space_id` — the space
  ///    composite cannot serve it, so each page did an index lookup then a
  ///    filesort)
  ///  * agent run logs by agent: `WHERE workspace_id = ? AND agent_id = ?
  ///    ORDER BY started_at DESC`
  ///  * agent run logs by conversation (the composer's stop/queue affordance,
  ///    live during every conversation) — previously a full scan
  ///  * agent run logs sorted by `started_at` with NO filter: the bounded
  ///    dashboard watch re-runs on every run-log write, and none of the six
  ///    single-column indexes can serve an unfiltered `ORDER BY started_at
  ///    DESC LIMIT n`, so it filesorted the whole table each time
  ///  * pull requests by workspace ordered by creation: webhook mirror bursts
  ///    update PR rows, and each update re-ran this list
  /// A composite serves both the filter and the sort from one index, avoiding a
  /// filesort over a growing table. `IF NOT EXISTS` keeps it idempotent.
  Future<void> _createHotPathIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_conversation_messages_space_created '
      'ON conversation_messages (space_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_conversation_messages_conversation_created '
      'ON conversation_messages (conversation_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_agent_run_logs_ws_agent_started '
      'ON agent_run_logs (workspace_id, agent_id, started_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_agent_run_logs_ws_conv_started '
      'ON agent_run_logs (workspace_id, conversation_id, started_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_agent_run_logs_started '
      'ON agent_run_logs (started_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pull_requests_ws_created '
      'ON pull_requests (workspace_id, created_at)',
    );
    // Reference resolution matches an import/reference name against BOTH
    // `name` and `qualified_name`. Only the latter had an index, so the `name`
    // half of that OR was a scan of the symbol table — and because import URIs
    // into external packages can never resolve, `countUnresolvedEdges > 0` is
    // permanently true and every incremental run pays it.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_code_symbols_name '
      'ON code_symbols (name)',
    );
    // Partial index for the embedding backfill's "what is left?" query
    // (`WHERE embedding IS NULL AND compacted = 0 … LIMIT 200`). Without it
    // that scans an unindexed column, so as the backlog drains each batch
    // scans an ever-longer prefix of rows that ARE already embedded. A partial
    // index holds only the pending rows: it shrinks as the backlog does and is
    // empty — free to maintain — once the backfill finishes.
    //
    // Indexed on `message_type` because the query also filters it, and NOT on
    // `workspace_id`: `conversation_messages` has no such column (a message
    // belongs to a space, which belongs to the workspace, and a file now holds
    // exactly one workspace anyway).
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_conversation_messages_pending_embedding '
      'ON conversation_messages (message_type) '
      'WHERE embedding IS NULL AND compacted = 0',
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

  /// Creates the chat-bridge link indexes: the four declared on the tables,
  /// plus the partial-unique one that keeps a bot-DM bridge single-valued.
  ///
  /// The DM index cannot be a `@TableIndex`: the tables'
  /// `(workspace_id, provider, external_channel_id, external_thread_id)` unique
  /// index does not cover it, because SQLite treats NULLs as distinct, so a
  /// conversation-level link (null `external_thread_id` — a DM with the bot)
  /// could be inserted twice and the bridge would then stream one turn into two
  /// CC spaces. Partial indexes carry a `WHERE`, so it has to be spelled out.
  ///
  /// The other four are declared `@TableIndex`es and are repeated here because
  /// `createTable` issues only `CREATE TABLE` — a migration that creates the
  /// tables has to create their indexes itself. They are spelled out rather
  /// than passed to `m.createIndex`, which generates a bare `CREATE INDEX` and
  /// therefore throws if the index is already there: with `IF NOT EXISTS` this
  /// is a no-op both from `onCreate` (where `createAll()` already built them)
  /// and on any re-run, so one helper serves both paths.
  Future<void> _createChatIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'uq_chat_space_links_ws_provider_space_thread '
      'ON chat_space_links '
      '(workspace_id, provider, external_channel_id, external_thread_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_chat_space_links_ccSpaceId '
      'ON chat_space_links (cc_space_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'uq_chat_user_links_ws_provider_team_user '
      'ON chat_user_links '
      '(workspace_id, provider, external_team_id, external_user_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_user_links_ws_provider_user '
      'ON chat_user_links (workspace_id, provider, user_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_space_links_ws_provider_dm '
      'ON chat_space_links (workspace_id, provider, external_channel_id) '
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
      'ON cron_executions (trigger_id, planned_at)',
    );
  }

  /// Creates the partial-unique index that enforces idempotency for
  /// event-triggered pipeline runs: at most one non-terminal run may exist per
  /// `(template_id, dedup_key)` tuple.
  Future<void> _createPipelineIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_pipeline_runs_active_dedup '
      'ON pipeline_runs (template_id, dedup_key) '
      'WHERE dedup_key IS NOT NULL '
      "AND status IN ('pending','queued','running','suspended')",
    );
    // Admission reads exactly this shape on every run completion: count the
    // slot holders of one template, then find its oldest queued row.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pipeline_runs_template_status '
      'ON pipeline_runs (workspace_id, template_id, status, started_at)',
    );
  }
}
