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
import 'package:cc_persistence/database/daos/conversation_dao.dart';
import 'package:cc_persistence/database/daos/conversation_goal_dao.dart';
import 'package:cc_persistence/database/daos/cron_execution_dao.dart';
import 'package:cc_persistence/database/daos/environment_dao.dart';
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/database/daos/evals_dao.dart';
import 'package:cc_persistence/database/daos/goal_dao.dart';
import 'package:cc_persistence/database/daos/guard_decision_dao.dart';
import 'package:cc_persistence/database/daos/isolated_repo_dao.dart';
import 'package:cc_persistence/database/daos/mcp_server_dao.dart';
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
import 'package:cc_persistence/database/daos/space_stack_dao.dart';
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
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/schema/schema_converge.dart';
import 'package:cc_persistence/database/tables/action_policies_table.dart';
import 'package:cc_persistence/database/tables/activity_log_table.dart';
import 'package:cc_persistence/database/tables/agent_goal_runs_table.dart';
import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agent_run_payloads_table.dart';
import 'package:cc_persistence/database/tables/agent_runtime_state_table.dart';
import 'package:cc_persistence/database/tables/agent_working_memory.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/approval_comments_table.dart';
import 'package:cc_persistence/database/tables/approval_escalations_table.dart';
import 'package:cc_persistence/database/tables/approval_routing_policies_table.dart';
import 'package:cc_persistence/database/tables/approvals_table.dart';
import 'package:cc_persistence/database/tables/budget_incidents_table.dart';
import 'package:cc_persistence/database/tables/budget_policy_table.dart';
import 'package:cc_persistence/database/tables/caches.dart';
import 'package:cc_persistence/database/tables/calendar_accounts.dart';
import 'package:cc_persistence/database/tables/calendar_events.dart';
import 'package:cc_persistence/database/tables/calendar_sources.dart';
import 'package:cc_persistence/database/tables/catalog_files_table.dart';
import 'package:cc_persistence/database/tables/chat_links_tables.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/conversation_activity.dart';
import 'package:cc_persistence/database/tables/conversation_goals_table.dart';
import 'package:cc_persistence/database/tables/conversation_message_embeddings_table.dart';
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/cron_executions_table.dart';
import 'package:cc_persistence/database/tables/editor_layouts_table.dart';
import 'package:cc_persistence/database/tables/environment_definitions.dart';
import 'package:cc_persistence/database/tables/environment_runs.dart';
import 'package:cc_persistence/database/tables/episodic_edges.dart';
import 'package:cc_persistence/database/tables/evals_tables.dart';
import 'package:cc_persistence/database/tables/goals_table.dart';
import 'package:cc_persistence/database/tables/guard_decisions_table.dart';
import 'package:cc_persistence/database/tables/imported_authority_holds_table.dart';
import 'package:cc_persistence/database/tables/isolated_repos.dart';
import 'package:cc_persistence/database/tables/mcp_servers.dart';
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
import 'package:cc_persistence/database/tables/memory_fact_embeddings.dart';
import 'package:cc_persistence/database/tables/memory_facts.dart';
import 'package:cc_persistence/database/tables/memory_policies.dart';
import 'package:cc_persistence/database/tables/message_reactions_table.dart';
import 'package:cc_persistence/database/tables/notification_feed_table.dart';
import 'package:cc_persistence/database/tables/notification_item_states_table.dart';
import 'package:cc_persistence/database/tables/notification_read_marks_table.dart';
import 'package:cc_persistence/database/tables/orchestrations_table.dart';
import 'package:cc_persistence/database/tables/pipeline_run_snapshots_table.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_step_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_templates_table.dart';
import 'package:cc_persistence/database/tables/pipeline_triggers_table.dart';
import 'package:cc_persistence/database/tables/plan_divergences_table.dart';
import 'package:cc_persistence/database/tables/plan_studio_tables.dart';
import 'package:cc_persistence/database/tables/pr_state_tables.dart';
import 'package:cc_persistence/database/tables/projects_table.dart';
import 'package:cc_persistence/database/tables/provider_policies.dart';
import 'package:cc_persistence/database/tables/pull_requests.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:cc_persistence/database/tables/review_drafts.dart';
import 'package:cc_persistence/database/tables/review_spaces.dart';
import 'package:cc_persistence/database/tables/review_studio_tables.dart';
import 'package:cc_persistence/database/tables/rigs_tables.dart';
import 'package:cc_persistence/database/tables/run_call_usages_table.dart';
import 'package:cc_persistence/database/tables/runtime_profiles_table.dart';
import 'package:cc_persistence/database/tables/sandbox_exec_grants_table.dart';
import 'package:cc_persistence/database/tables/skill_scan_results_table.dart';
import 'package:cc_persistence/database/tables/skill_sources_table.dart';
import 'package:cc_persistence/database/tables/space_autonomy_table.dart';
import 'package:cc_persistence/database/tables/space_environments.dart';
import 'package:cc_persistence/database/tables/space_notes_table.dart';
import 'package:cc_persistence/database/tables/space_participants.dart';
import 'package:cc_persistence/database/tables/space_repos.dart';
import 'package:cc_persistence/database/tables/space_stack_entries.dart';
import 'package:cc_persistence/database/tables/space_state_tables.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
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
import 'package:cc_persistence/database/tables/transcript_segments_table.dart';
import 'package:cc_persistence/database/tables/transcripts_table.dart';
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
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:cc_persistence/src/vector_extension.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'workspace_database.g.dart';

/// One workspace's DB (`<dataDir>/<workspaceId>/workspace.db`).
///
/// Isolation boundary: this class does not declare global/other-workspace
/// tables, so cross-workspace reads do not compile. `workspaceId` columns are
/// still written (FTS/self-describing). Multi-workspace reads go through
/// `CrossWorkspaceQueries` only. Opens lazily on first touch.
///
/// The code index derived from the workspace's checkouts is not here: it is
/// `CodeIndexDatabase`, in `code_index.db` beside this file.
@DriftDatabase(
  tables: [
    ReposTable,
    AgentsTable,
    AgentRunLogsTable,
    AgentRunPayloadsTable,
    AgentGoalRunsTable,
    PullRequestsTable,
    ReviewDrafts,
    CachesTable,
    SpacesTable,
    ConversationsTable,
    SpaceParticipantsTable,
    SpaceReposTable,
    CatalogFilesTable,
    SpaceNotesTable,
    SpaceAutonomyTable,
    MessageReactionsTable,
    ConversationMessagesTable,
    ConversationMessageEmbeddingsTable,
    ConversationActivityTable,
    ReviewSpacesTable,
    ActivityLogTable,
    BudgetPolicyTable,
    AgentWorkingMemoryTable,
    MemoryDomainsTable,
    MemoryFactsTable,
    MemoryFactEmbeddingsTable,
    MemoryPoliciesTable,
    MemoryAccessGrantsTable,
    MemoryConflictsTable,
    EpisodicEdgesTable,
    WorkingMemoryItemsTable,
    MemoryConsolidationLogTable,
    MemoryBeliefsTable,
    PipelineRunsTable,
    PipelineRunSnapshotsTable,
    PipelineStepRunsTable,
    PipelineTemplatesTable,
    PipelineTriggersTable,
    TicketsTable,
    TicketCollaboratorsTable,
    TicketLinksTable,
    ProjectsTable,
    TeamsTable,
    TeamMembersTable,
    IsolatedReposTable,
    SpaceStackEntriesTable,
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
    SkillEvalCampaignsTable,
    SkillEvalAttemptsTable,
    SkillEvalPoliciesTable,
    SkillScanResultsTable,
    ActionPoliciesTable,
    SandboxExecGrantsTable,
    GuardDecisionsTable,
    WorkspaceRolesTable,
    ConversationGoalsTable,
    TranscriptsTable,
    TranscriptSegmentsTable,
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
    RunCallUsagesTable,
    EnvironmentDefinitionsTable,
    SpaceEnvironmentsTable,
    EnvironmentRunsTable,
    ImportedAuthorityHoldsTable,
    SpaceTakeoversTable,
    SpaceCheckersTable,
    EditorLayoutsTable,
    PrCodeOwnerReviewersTable,
    PendingPrRepliesTable,
    ApprovalEscalationsTable,
    PlanDivergencesTable,
    McpServersTable,
  ],
  daos: [
    WorkspaceSettingDao,
    RepoDao,
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
    IsolatedRepoDao,
    SpaceStackDao,
    MeetingDao,
    CalendarDao,
    VoiceProfileDao,
    OrchestrationDao,
    PlanStudioDao,
    ReviewStudioDao,
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
    EnvironmentDao,
    McpServerDao,
  ],
)
class WorkspaceDatabase extends _$WorkspaceDatabase with ConvergedDatabase {
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
    this.upgradeSnapshotDirectory,
  }) {
    // The extension applies to connections opened after it is registered, and
    // the executor opens on the first statement, so this is early enough.
    ensureVectorExtensionRegistered();
  }

  /// Creates an in-memory workspace database for testing.
  WorkspaceDatabase.forTesting(super.e, {this.workspaceId = 'test-workspace'})
    : installId = 'test-install',
      onWarn = null,
      onError = null,
      skipIntegrityCheck = false,
      onIntegrityChecked = null,
      upgradeSnapshotDirectory = null {
    ensureVectorExtensionRegistered();
  }

  /// Skips the `PRAGMA quick_check` on this open.
  ///
  /// Set by `WorkspaceDatabaseManager` when this process has already checked
  /// this file. The check is a statement about bytes on disk that only this
  /// process writes, so paying 2.8s again on a reopen would re-derive an answer
  /// that cannot have changed — and reopening is now routine, because a
  /// cross-workspace read closes the files it opened.
  final bool skipIntegrityCheck;

  /// Called after a `quick_check` completes, with null when it passed and
  /// SQLite's finding when it failed, so the manager can stop asking for the
  /// check on later opens and can take a damaged workspace out of service.
  final void Function(String? failure)? onIntegrityChecked;

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

  /// Warning sink (schema convergence, a slow integrity check). Host-injected.
  @override
  final void Function(String tag, String message)? onWarn;

  /// Error sink (e.g. a failed integrity check). Host-injected.
  final void Function(String tag, String message)? onError;

  @override
  final String? upgradeSnapshotDirectory;

  /// The current workspace schema version, as a const so non-database code
  /// (the server's /healthz build/compat block) can report it without
  /// instantiating a database. Keep in lockstep with [schemaVersion].
  ///
  /// Bump it whenever the declared schema changes (a table class, an index,
  /// a constraint): the version differing is what makes an existing file
  /// converge on its next open. There are no migration steps to write.
  static const int currentSchemaVersion = 33;

  /// `PRAGMA application_id` of a workspace database: "CCWS".
  static const int fileApplicationId = 0x43435753;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  int get applicationId => fileApplicationId;

  @override
  int get lastUnidentifiedVersion => 29;

  @override
  String get identityTable => 'workspace_meta';

  @override
  String get databaseLabel => 'workspace $workspaceId';

  /// Every row in this file belongs to [workspaceId], so a row that lost or
  /// never had its `workspace_id` gets this one.
  @override
  Map<String, Object> get convergeFills => {'workspace_id': workspaceId};

  static Future<SchemaSnapshot>? _declaredSchema;

  /// The schema a fresh workspace file holds, read once per process from an
  /// in-memory instance.
  static Future<SchemaSnapshot> declaredSchema() =>
      _declaredSchema ??= _readDeclaredSchema();

  static Future<SchemaSnapshot> _readDeclaredSchema() async {
    final db = WorkspaceDatabase(
      NativeDatabase.memory(),
      workspaceId: 'declared-schema',
    );
    try {
      return await SchemaSnapshot.read(db);
    } on Object {
      _declaredSchema = null;
      rethrow;
    } finally {
      await db.close();
    }
  }

  @override
  Future<SchemaSnapshot> loadDeclaredSchema() => declaredSchema();

  /// Writes a consistent, defragmented snapshot of this workspace to [path]
  /// using `VACUUM INTO`, on this database's own connection.
  ///
  /// Safe on a live WAL database (it takes a read transaction and writes a
  /// clean copy). For a file on disk prefer `snapshotDatabaseFile`, which
  /// copies on a connection of its own so nothing queues behind the copy;
  /// this is what an in-memory database has.
  Future<void> backupTo(String path) =>
      customStatement('VACUUM INTO ?', [path]);

  /// Everything a fresh file holds besides the FTS indexes `beforeOpen`
  /// installs: the declared tables with their indexes (partial and
  /// expression indexes included, each declared on its table class) and the
  /// row naming the workspace.
  Future<void> _createDeclaredSchema(Migrator m) async {
    await m.createAll();
    await into(workspaceMetaTable).insert(
      WorkspaceMetaTableCompanion.insert(
        workspaceId: workspaceId,
        installId: installId,
        createdWithSchemaVersion: schemaVersion,
        createdAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => createFresh(() => _createDeclaredSchema(m)),
    onUpgrade: (Migrator m, int from, int to) => upgradeByConverging(from, to),
    beforeOpen: (_) async {
      await applyConnectionPragmas();
      await verifyIdentity();
      // The integrity check comes before anything below that writes. A
      // damaged file takes no more writes: every one would be laid on top of
      // the damage and carried into the next snapshot.
      if (await _foundDamaged()) {
        await customStatement('PRAGMA query_only = ON');
        try {
          await _initVectorIndex();
        } on Object catch (error) {
          onError?.call(
            'WorkspaceDatabase',
            'vector index unavailable for damaged workspace $workspaceId: '
                '${error.runtimeType}',
          );
        }
        return;
      }
      // vector_init builds the sqlite_vector extension's PER-CONNECTION,
      // in-memory context — it is NOT persisted in the database file. It must
      // therefore run on EVERY open, not just onCreate: an existing database
      // reopened after a restart otherwise has no context and every
      // vector KNN query fails with "unable to retrieve context".
      // beforeOpen runs after onCreate/onUpgrade, so the tables always exist
      // by now. A failure fails the open: the extension is a required native.
      await _initVectorIndex();
      // FTS5 external-content tables + their sync triggers. Idempotent
      // (everything is IF NOT EXISTS) and installed on every open rather than
      // only in `onCreate`: a trigger lost for any reason (maintenance, a
      // schema convergence, an adopted file) is otherwise never rebuilt and
      // the failure is silent — inserts stop reaching the index and search
      // just returns less and less.
      final createdFts = await _createFts5Tables();
      await _rebuildStaleFtsIndexes(createdFts);
      await _createMessageRevisionTrigger();
      await optimize(onOpen: true);
    },
  );

  /// Runs the corruption check of this open and reports its outcome through
  /// [onIntegrityChecked]. True when SQLite found the file damaged.
  ///
  /// `quick_check`, NOT `integrity_check`. `integrity_check` verifies every
  /// b-tree page against every index entry, so its cost scales with the whole
  /// database: on a 2.6GB graph-heavy file it took 21s warm (worse cold).
  /// `quick_check` catches the corruption that actually happens (bad page
  /// structure, broken b-trees) while skipping the exhaustive cross-checks:
  /// 2.8s on that same file. It is paid once per file per process, on the
  /// file's first open. For a live workspace that is at boot: the owner
  /// membership pass touches every one of them before the server listens,
  /// side by side, so boot waits for the largest file and not for their sum.
  Future<bool> _foundDamaged() async {
    if (skipIntegrityCheck) {
      return false;
    }
    final startedAt = DateTime.now();
    final status = await _quickCheck();
    final damaged = status != 'ok';
    if (damaged) {
      onError?.call(
        'WorkspaceDatabase',
        'SQLite quick_check failed for workspace $workspaceId: $status',
      );
    }
    onIntegrityChecked?.call(damaged ? status : null);
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed > const Duration(seconds: 2)) {
      onWarn?.call(
        'WorkspaceDatabase',
        'quick_check took ${elapsed.inMilliseconds}ms for workspace '
            '$workspaceId — this workspace is large enough that opening it '
            'is a visible pause',
      );
    }
    return damaged;
  }

  /// `PRAGMA quick_check`'s finding: `ok`, or what it reported.
  ///
  /// Damage bad enough stops the check itself: SQLite then fails the
  /// statement with "database disk image is malformed" instead of returning
  /// a finding. That is the same verdict, so it is returned as one.
  Future<String> _quickCheck() async {
    try {
      final result = await customSelect('PRAGMA quick_check').get();
      return result.first.read<String>('quick_check');
    } on Object catch (error) {
      if (storageFailureOf(error) != StorageFailure.damaged) {
        rethrow;
      }
      return sqliteCauseOf(error)?.message ??
          'database disk image is malformed';
    }
  }

  /// The FTS5 indexes of this file and the table each one indexes.
  static const Map<String, String> _ftsContentTables = {
    'memory_facts_fts': 'memory_facts',
    'conversation_messages_fts': 'conversation_messages',
  };

  Future<bool> _hasSchemaObject(String name) async => (await customSelect(
    'SELECT 1 FROM sqlite_master WHERE name = ?',
    variables: [Variable.withString(name)],
  ).get()).isNotEmpty;

  /// Creates the FTS5 indexes and their sync triggers, and returns the names
  /// of the indexes this call had to create.
  ///
  /// `memory_facts_fts` keeps its `workspace_id` column even though a file
  /// now holds exactly one workspace: the column maps to the content table's
  /// own `workspace_id`, so FTS5 `rebuild` stays valid. The MATCH-level
  /// workspace filter (`toWorkspaceScopedFtsMatch`) is belt-and-braces rather
  /// than the isolation mechanism. The code index lives in its own file
  /// (`CodeIndexDatabase`).
  Future<Set<String>> _createFts5Tables() async {
    final created = <String>{
      for (final name in _ftsContentTables.keys)
        if (!await _hasSchemaObject(name)) name,
    };
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
    // In-space message search (§8.4). Scoped by `space_id` — messages have
    // no `workspace_id` column (they belong to a space, which does), so the
    // search RPC validates space ownership and MATCHes with `space_id = ?`.
    await _createSpaceMessagesFts();
    return created;
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
    // A streaming turn rewrites its row's meter columns on every flush and
    // its metadata whenever the turn changes state; without the column list
    // each of those ran a delete+insert of UNCHANGED text through FTS5.
    // (Embeddings no longer touch the row at all: they live in
    // `conversation_message_embeddings`.) Any statement that writes either
    // indexed column still fires, so the index cannot drift.
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

  /// Installs the trigger that keeps `conversation_messages.revision`: one
  /// more on every `UPDATE` of a row, whatever the statement wrote.
  ///
  /// Installed on every open like the FTS triggers, because schema
  /// convergence drops every trigger. The trigger's own `UPDATE` sets a
  /// revision above the old one, so its `WHEN` stops it from firing itself
  /// (with or without `recursive_triggers`). A statement that writes a stale
  /// revision back gets a bump on top of the stored one, never a step back.
  Future<void> _createMessageRevisionTrigger() => customStatement('''
      CREATE TRIGGER IF NOT EXISTS conversation_messages_revision_au
      AFTER UPDATE ON conversation_messages
      WHEN new.revision <= old.revision BEGIN
        UPDATE conversation_messages SET revision = old.revision + 1
        WHERE rowid = new.rowid;
      END
    ''');

  /// Rebuilds the FTS indexes whose content may no longer match them.
  ///
  /// An external-content index addresses rows by rowid and is fed by
  /// triggers. It is stale when it was just created over existing rows
  /// ([created]), when the convergence rebuilt its content table (rows that
  /// broke a constraint were left behind without a delete trigger firing), or
  /// when the file was rewritten whole: SQLite does not promise that `VACUUM`
  /// keeps the rowids of a table without an integer primary key.
  Future<void> _rebuildStaleFtsIndexes(Set<String> created) async {
    final rebuilt = lastConvergeReport?.rebuiltTables.toSet() ?? const {};
    for (final MapEntry(key: index, value: content)
        in _ftsContentTables.entries) {
      if (created.contains(index) ||
          fileWasRewritten ||
          rebuilt.contains(content)) {
        await customStatement("INSERT INTO $index($index) VALUES('rebuild')");
      }
    }
  }

  /// Rebuilds every FTS5 index from its content table.
  ///
  /// Needed after anything that changed rows without the triggers seeing it
  /// or that may have renumbered rowids: adopting a file written by
  /// `VACUUM INTO` (a snapshot, an export) is the standing case.
  Future<void> rebuildFtsIndexes() async {
    for (final index in _ftsContentTables.keys) {
      await customStatement("INSERT INTO $index($index) VALUES('rebuild')");
    }
  }

  Future<void> _initVectorIndex() async {
    for (final table in workspaceVectorTables) {
      await customStatement(vectorInitStatement(table));
    }
  }
}
