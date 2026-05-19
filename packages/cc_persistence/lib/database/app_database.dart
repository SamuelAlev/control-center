import 'package:cc_persistence/database/daos/achievement_dao.dart';
import 'package:cc_persistence/database/daos/activity_log_dao.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/daos/agent_working_memory_dao.dart';
import 'package:cc_persistence/database/daos/analytics_dao.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/calendar_dao.dart';
import 'package:cc_persistence/database/daos/code_graph_dao.dart';
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
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
import 'package:cc_persistence/database/daos/orchestration_dao.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/daos/pipeline_dao.dart';
import 'package:cc_persistence/database/daos/pipeline_template_dao.dart';
import 'package:cc_persistence/database/daos/pipeline_trigger_dao.dart';
import 'package:cc_persistence/database/daos/project_dao.dart';
import 'package:cc_persistence/database/daos/pull_request_dao.dart';
import 'package:cc_persistence/database/daos/repo_dao.dart';
import 'package:cc_persistence/database/daos/review_channel_dao.dart';
import 'package:cc_persistence/database/daos/review_dao.dart';
import 'package:cc_persistence/database/daos/rss_dao.dart';
import 'package:cc_persistence/database/daos/streak_dao.dart';
import 'package:cc_persistence/database/daos/team_dao.dart';
import 'package:cc_persistence/database/daos/ticket_dao.dart';
import 'package:cc_persistence/database/daos/ticket_link_dao.dart';
import 'package:cc_persistence/database/daos/voice_profile_dao.dart';
import 'package:cc_persistence/database/daos/working_memory_item_dao.dart';
import 'package:cc_persistence/database/daos/workspace_dao.dart';
import 'package:cc_persistence/database/migration_steps.dart';
import 'package:cc_persistence/database/tables/achievements_table.dart';
import 'package:cc_persistence/database/tables/activity_log_table.dart';
import 'package:cc_persistence/database/tables/agent_daily_stats_table.dart';
import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agent_working_memory.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/budget_policy_table.dart';
import 'package:cc_persistence/database/tables/caches.dart';
import 'package:cc_persistence/database/tables/calendar_accounts.dart';
import 'package:cc_persistence/database/tables/calendar_events.dart';
import 'package:cc_persistence/database/tables/calendar_sources.dart';
import 'package:cc_persistence/database/tables/channel_messages.dart';
import 'package:cc_persistence/database/tables/channel_participants.dart';
import 'package:cc_persistence/database/tables/channels.dart';
import 'package:cc_persistence/database/tables/code_edges.dart';
import 'package:cc_persistence/database/tables/code_files.dart';
import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:cc_persistence/database/tables/episodic_edges.dart';
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
import 'package:cc_persistence/database/tables/orchestrations_table.dart';
import 'package:cc_persistence/database/tables/paired_devices.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_step_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_templates_table.dart';
import 'package:cc_persistence/database/tables/pipeline_triggers_table.dart';
import 'package:cc_persistence/database/tables/projects_table.dart';
import 'package:cc_persistence/database/tables/pull_requests.dart';
import 'package:cc_persistence/database/tables/remembered_decisions.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:cc_persistence/database/tables/review_channels.dart';
import 'package:cc_persistence/database/tables/review_drafts.dart';
import 'package:cc_persistence/database/tables/rss_articles.dart';
import 'package:cc_persistence/database/tables/rss_feeds.dart';
import 'package:cc_persistence/database/tables/streaks_table.dart';
import 'package:cc_persistence/database/tables/teams_table.dart';
import 'package:cc_persistence/database/tables/ticket_collaborators_table.dart';
import 'package:cc_persistence/database/tables/ticket_links_table.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:cc_persistence/database/tables/voice_profiles.dart';
import 'package:cc_persistence/database/tables/working_memory_items.dart';
import 'package:cc_persistence/database/tables/workspace_repos.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:cc_persistence/database/tables/worktree_merge_log_table.dart';
import 'package:drift/drift.dart';

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
    PairedDevicesTable,
    RememberedDecisionsTable,
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
    PairedDeviceDao,
  ],
)
/// The application's Drift database.
class AppDatabase extends _$AppDatabase {
  /// Creates the database over a host-supplied [QueryExecutor].
  ///
  /// The connection is injected so the database stays Flutter-free: the desktop
  /// app passes `openDesktopConnection()` (path_provider + sqlite_vector, in
  /// `desktop_connection.dart`); the headless server passes
  /// `openServerDatabase(dataDir:)` from `cc_persistence`. Diagnostics route
  /// through the optional [onWarn]/[onError] sinks for the same reason — the
  /// desktop wires them to `AppLog`, the server to stdout / a no-op.
  AppDatabase(super.e, {this.onWarn, this.onError});

  /// Creates an in-memory database for testing.
  AppDatabase.forTesting(super.e) : onWarn = null, onError = null;

  /// Warning sink (e.g. a missing optional extension). Host-injected.
  final void Function(String tag, String message)? onWarn;

  /// Error sink (e.g. a failed integrity check). Host-injected.
  final void Function(String tag, String message)? onError;

  @override
  int get schemaVersion => 21;

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
        onError?.call(
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
      onWarn?.call(
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
      // tickets.output_contract_mode was added here historically; the column
      // was later dropped (v15→v16, output contract moved to agent runs). Kept
      // as a raw statement so the historical step still compiles without the
      // now-removed Dart column getter.
      await m.database.customStatement(
        'ALTER TABLE tickets ADD COLUMN output_contract_mode TEXT NOT NULL '
        "DEFAULT 'strict'",
      );
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
    // v10 → v11 snapshots the summary template + persists speaker embeddings:
    //   * meetings.summary_instructions — the template instructions captured
    //     when summarization first ran, so a "Re-run summary" reproduces the
    //     original template instead of the (possibly since-changed) active one.
    //   * meeting_speakers.embedding — a representative WeSpeaker embedding per
    //     diarized speaker, persisted for future cross-meeting re-identification.
    // Both are additive nullable columns, so existing rows are untouched (null →
    // fall back to the current template / no stored embedding). Fresh installs
    // build them via `onCreate`'s `createAll()`. The adds are guarded as
    // idempotent so a partial/re-run upgrade (e.g. a launch interrupted before
    // the version bump persisted) doesn't fail with "duplicate column".
    MigrationStep(10, 11, (m) async {
      await _addColumnIfAbsent(
        m,
        'meetings_table',
        'summary_instructions',
        () => m.addColumn(meetingsTable, meetingsTable.summaryInstructions),
      );
      await _addColumnIfAbsent(
        m,
        'meeting_speakers_table',
        'embedding',
        () => m.addColumn(meetingSpeakersTable, meetingSpeakersTable.embedding),
      );
    }),
    // v11 → v12 adds the `voice_profiles_table` for persistent, cross-meeting
    // speaker recognition: a named voiceprint per person, so a speaker the user
    // names once is auto-recognized in future meetings. `createTable` builds
    // both its indexes (incl. the unique `(workspaceId, displayName)`) from the
    // `@TableIndex` annotations — like the v3→v4 calendar tables — so no
    // `customStatement` is needed. New, isolated table, so existing rows are
    // untouched. Fresh installs build it via `onCreate`'s `createAll()`.
    MigrationStep(11, 12, (m) async {
      await m.createTable(voiceProfilesTable);
    }),
    // v12 → v13 adds `last_read_at` to channel participants: a per-participant
    // read cursor that powers the sidebar's unread indicator (an agent message
    // newer than the user's cursor, while no run is in flight, surfaces a
    // notification dot). Additive nullable column, so existing rows are
    // untouched (null → "nothing unseen yet"). Fresh installs build it via
    // `onCreate`'s `createAll()`. Guarded idempotent so a partial/re-run
    // upgrade doesn't fail with "duplicate column".
    MigrationStep(12, 13, (m) async {
      await _addColumnIfAbsent(
        m,
        'channel_participants',
        'last_read_at',
        () => m.addColumn(
          channelParticipantsTable,
          channelParticipantsTable.lastReadAt,
        ),
      );
    }),
    // v13 → v14 refines per-block speaker renaming and voice-profile provenance:
    //   * meeting_transcript_segments_table.speaker_name_override — the name to
    //     show for a single transcript line, set when the user renames just that
    //     block instead of the whole speaker (the rename dialog's default).
    //   * meeting_speakers_table.enrolled_profile_name — the voice profile this
    //     speaker's voiceprint was enrolled into, so renaming the speaker can
    //     un-enroll the embedding from the previously-saved profile.
    // Both are additive nullable columns, so existing rows are untouched (null →
    // inherit the group name / never enrolled). Fresh installs build them via
    // `onCreate`'s `createAll()`. Guarded idempotent so a partial/re-run upgrade
    // doesn't fail with "duplicate column".
    MigrationStep(13, 14, (m) async {
      await _addColumnIfAbsent(
        m,
        'meeting_transcript_segments_table',
        'speaker_name_override',
        () => m.addColumn(
          meetingTranscriptSegmentsTable,
          meetingTranscriptSegmentsTable.speakerNameOverride,
        ),
      );
      await _addColumnIfAbsent(
        m,
        'meeting_speakers_table',
        'enrolled_profile_name',
        () => m.addColumn(
          meetingSpeakersTable,
          meetingSpeakersTable.enrolledProfileName,
        ),
      );
    }),
    // v14 → v15 adds the remote-control `paired_devices` table (metadata only
    // — the PSK lives in the platform secure store). Fresh installs build it
    // via `onCreate`'s `createAll()`.
    MigrationStep(14, 15, (m) async {
      await m.createTable(pairedDevicesTable);
    }),
    // v15 → v16 completes the conversation-first pivot: tickets become dumb
    // issue-tracking artifacts (the output contract + pipeline coupling move
    // onto the agent run), conversations gain a pipeline-run link, and
    // pipeline step runs gain a channel link.
    //   * agent_run_logs +expected_output_schema / +output_contract_mode /
    //     +output_json (the ported output contract).
    //   * channels +pipeline_run_id (non-null ⇒ pipeline-managed/hidden).
    //   * pipeline_step_runs +channel_id (the step-detail → conversation link).
    //   * tickets drops the execution / output-contract / pipeline-coupling /
    //     mode columns (rebuilt via alterTable so the dropped columns + their
    //     indexes vanish cleanly).
    // Additive columns are guarded idempotent; the tickets rebuild is a full
    // table rewrite (drift's alterTable copies surviving columns + rebuilds
    // indexes from the current @TableIndex set).
    MigrationStep(15, 16, (m) async {
      await _addColumnIfAbsent(
        m,
        'agent_run_logs_table',
        'expected_output_schema',
        () => m.addColumn(
          agentRunLogsTable,
          agentRunLogsTable.expectedOutputSchema,
        ),
      );
      await _addColumnIfAbsent(
        m,
        'agent_run_logs_table',
        'output_contract_mode',
        () => m.addColumn(
          agentRunLogsTable,
          agentRunLogsTable.outputContractMode,
        ),
      );
      await _addColumnIfAbsent(
        m,
        'agent_run_logs_table',
        'output_json',
        () => m.addColumn(agentRunLogsTable, agentRunLogsTable.outputJson),
      );
      await _addColumnIfAbsent(
        m,
        'channels',
        'pipeline_run_id',
        () => m.addColumn(channelsTable, channelsTable.pipelineRunId),
      );
      await _addColumnIfAbsent(
        m,
        'pipeline_step_runs_table',
        'channel_id',
        () => m.addColumn(
          pipelineStepRunsTable,
          pipelineStepRunsTable.channelId,
        ),
      );
      // Drop the stale pipeline-step index first: it references columns
      // (pipeline_run_id, pipeline_step_id) that the rebuild below removes.
      // Drift's alterTable re-applies the indexes it finds on the existing
      // table, so leaving this one in place would make the rebuild fail with
      // "no such column: pipeline_run_id".
      await customStatement('DROP INDEX IF EXISTS idx_tickets_pipelineStep');
      // Drop the ticket execution / output-contract / pipeline-coupling / mode
      // columns. alterTable rebuilds `tickets` from the current table class,
      // preserving surviving rows + rebuilding the partial unique index below.
      await m.alterTable(TableMigration(ticketsTable));
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_tickets_provider_externalKey '
        'ON tickets (provider, external_key) WHERE external_key IS NOT NULL',
      );
      await _addColumnIfAbsent(
        m,
        'agent_run_logs_table',
        'output_rejections',
        () => m.addColumn(
          agentRunLogsTable,
          agentRunLogsTable.outputRejections,
        ),
      );
    }),
    // v16 → v17 adds `expires_at` to paired_devices: the server-enforced
    // credential/pairing-offer expiry that time-boxes a remote-control link so a
    // leaked pairing can't be a permanent backdoor. Additive nullable column, so
    // existing rows are untouched (null → no expiry; legacy devices keep working
    // until re-paired). Fresh installs build it via `onCreate`'s `createAll()`.
    // Guarded idempotent so a partial/re-run upgrade doesn't fail with
    // "duplicate column".
    MigrationStep(16, 17, (m) async {
      await _addColumnIfAbsent(
        m,
        'paired_devices',
        'expires_at',
        () => m.addColumn(pairedDevicesTable, pairedDevicesTable.expiresAt),
      );
    }),
    MigrationStep(17, 18, (m) async {
      await m.createTable(calendarSourcesTable);
    }),
    // v18 → v19 adds `command_policy_json` to agents (per-agent command
    // policy delta, mirroring `sandboxCapabilitiesJson`) and the
    // workspace-scoped `remembered_decisions` table (UAC remembered choices).
    // Fresh installs build both via `onCreate`'s `createAll()`.
    MigrationStep(18, 19, (m) async {
      await _addColumnIfAbsent(
        m,
        'agents',
        'command_policy_json',
        () => m.addColumn(agentsTable, agentsTable.commandPolicyJson),
      );
      await m.createTable(rememberedDecisionsTable);
    }),
    // v19 → v20 is the "memory & intelligence engine" migration (PRD 04). It is
    // additive — new typed/decay/veracity columns on memory_facts plus five new
    // workspace-scoped tables — so existing rows are untouched (un-typed facts
    // default to memoryType='fact'/veracity='stated'). Fresh installs build
    // everything via `onCreate`'s `createAll()`. Column adds are guarded
    // idempotent so a partial/re-run upgrade doesn't fail with "duplicate
    // column".
    //
    //   * memory_facts +memory_type/+veracity/+valid_until/+recall_count/
    //     +last_recalled_at/+temporal_tags/+mention_count/+binary_embedding
    //   * memory_conflicts          — detected contradictions + supersession
    //   * episodic_edges            — typed semantic graph (the graph voice)
    //   * working_memory_items      — the hot tier for two-tier consolidation
    //   * memory_consolidation_log  — one row per `sleep()` pass
    //   * memory_beliefs            — harmonized cross-agent SHMR beliefs
    MigrationStep(19, 20, (m) async {
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'memory_type',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.memoryType),
      );
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'veracity',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.veracity),
      );
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'valid_until',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.validUntil),
      );
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'recall_count',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.recallCount),
      );
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'last_recalled_at',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.lastRecalledAt),
      );
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'temporal_tags',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.temporalTags),
      );
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'mention_count',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.mentionCount),
      );
      await _addColumnIfAbsent(
        m,
        'memory_facts_table',
        'binary_embedding',
        () => m.addColumn(memoryFactsTable, memoryFactsTable.binaryEmbedding),
      );
      await m.createTable(memoryConflictsTable);
      await m.createTable(episodicEdgesTable);
      await m.createTable(workingMemoryItemsTable);
      await m.createTable(memoryConsolidationLogTable);
      await m.createTable(memoryBeliefsTable);
    }),
    // v21: conversation revert/unrevert checkpointing — reverted messages are
    // hidden from the live conversation but kept so unrevert can restore them.
    MigrationStep(20, 21, (m) async {
      await _addColumnIfAbsent(
        m,
        'channel_messages',
        'reverted',
        () => m.addColumn(channelMessagesTable, channelMessagesTable.reverted),
      );
      await _addColumnIfAbsent(
        m,
        'channel_messages',
        'reverted_at',
        () => m.addColumn(channelMessagesTable, channelMessagesTable.revertedAt),
      );
    }),
  ];

  /// Adds a column only when it isn't already present, so an additive migration
  /// is idempotent across partial/re-run upgrades (a launch interrupted before
  /// the schema-version bump persisted would otherwise re-run the `ADD COLUMN`
  /// and fail with "duplicate column name"). Mirrors the existence-guard pattern
  /// used by the v4→v5 index migration.
  Future<void> _addColumnIfAbsent(
    Migrator m,
    String tableName,
    String columnName,
    Future<void> Function() add,
  ) async {
    final columns =
        await m.database.customSelect('PRAGMA table_info($tableName)').get();
    final exists =
        columns.any((row) => row.read<String>('name') == columnName);
    if (exists) {
      return;
    }
    // Belt-and-suspenders: a prior partial migration (interrupted before the
    // schema-version bump persisted) may have already added the column even
    // though the PRAGMA snapshot above missed it (e.g. a stale read or a
    // concurrent writer). Swallow the duplicate-column error so the upgrade
    // heals the partial state instead of crashing the app on every launch.
    try {
      await add();
    } on Object catch (e) {
      if (e.toString().contains('duplicate column name')) {
        onWarn?.call(
          'AppDatabase',
          'Column $columnName already present on $tableName — skipping.',
        );
        return;
      }
      rethrow;
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
}
