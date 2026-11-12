import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:drift/drift.dart';

/// A complete, replayable recording of one harness run (PRD 21 §1).
///
/// Bundles the event stream, the LLM/tool cassettes (content-addressed refs),
/// the fixture ref and the [configHash] — the content hash over the effective
/// agent config. Workspace-scoped. Recording is opt-in per agent/space, so
/// most runs have no row here.
///
/// A recording goes with the run log it captures.
@TableIndex(name: 'idx_session_recordings_config', columns: {#configHash})
@TableIndex(name: 'idx_session_recordings_runlog', columns: {#runLogId})
@TableIndex(
  name: 'idx_session_recordings_agent',
  columns: {#agentId, #createdAt},
)
@TableIndex(name: 'idx_session_recordings_created', columns: {#createdAt})
class SessionRecordingsTable extends Table {
  @override
  String get tableName => 'session_recordings';

  /// Unique recording id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The run log this recording captures.
  TextColumn get runLogId =>
      text().references(AgentRunLogsTable, #id, onDelete: KeyAction.cascade)();

  /// The agent whose config produced this run (nullable for ad-hoc runs).
  /// `SET NULL`: the recording outlives the agent.
  TextColumn get agentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The conversation (space) id, when applicable. No foreign key: the
  /// recorder passes whichever of the two the run carried.
  TextColumn get conversationId => text().nullable()();

  /// SHA-256 `AgentConfigHash` over the canonical config document.
  TextColumn get configHash => text()();

  /// Version of the config-hash field list (re-keys deliberately, not
  /// silently, when the hashed field set changes).
  IntColumn get hashVersion => integer().withDefault(const Constant(1))();

  /// Content-addressed ref to the serialized event stream (JSONL under the
  /// server data dir).
  TextColumn get eventsRef => text().nullable()();

  /// Content-addressed ref to the LLM/tool cassette bundle.
  TextColumn get cassetteRef => text().nullable()();

  /// Content-addressed ref to the fixture (git bundle + pinned SHA / rift snap).
  TextColumn get fixtureRef => text().nullable()();

  /// Number of events in the stream (quick display / integrity check).
  IntColumn get eventCount => integer().withDefault(const Constant(0))();

  /// Human-facing title (first user message summary, or explicit label).
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A blessed recording pinned as a golden per agent/playbook (PRD 21 §4).
/// A golden goes with its recording.
@TableIndex(name: 'idx_golden_sessions_agent', columns: {#agentId})
@TableIndex(name: 'idx_golden_sessions_recording', columns: {#recordingId})
@TableIndex(name: 'idx_golden_sessions_blessed', columns: {#blessedAt})
class GoldenSessionsTable extends Table {
  @override
  String get tableName => 'golden_sessions';

  /// Unique golden id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The agent (or playbook, by convention) this golden protects. No foreign
  /// key: it may name a playbook.
  TextColumn get agentId => text()();

  /// The recording that is the golden.
  TextColumn get recordingId => text().references(
    SessionRecordingsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Gating mode: a `GoldenMode` name.
  TextColumn get mode => text()
      .check(
        // ignore: recursive_getters
        mode.isIn(AgentsStoredValues.goldenMode),
      )
      .withDefault(const Constant('deterministic'))();

  /// Operator-facing name.
  TextColumn get name => text().withDefault(const Constant(''))();

  /// Whether the golden is active (gates saves / CI).
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Last run status: a `GoldenStatus` name.
  TextColumn get lastStatus => text()
      .check(
        // ignore: recursive_getters
        lastStatus.isIn(AgentsStoredValues.goldenStatus),
      )
      .withDefault(const Constant('unknown'))();

  /// Last run scorecard JSON (diff summary / grader breakdown).
  TextColumn get lastScorecardJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJson(lastScorecardJson))();

  /// Principal that blessed the golden (no foreign key: a user id lives in
  /// `global.db`).
  TextColumn get blessedBy => text().nullable()();

  /// When it was blessed.
  DateTimeColumn get blessedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A workspace-scoped eval suite: task + fixture + graders (PRD 21 §5).
class EvalSuitesTable extends Table {
  @override
  String get tableName => 'eval_suites';

  /// Unique suite id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Suite name, unique in the workspace.
  TextColumn get name => text()();

  /// Suite description.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// JSON-encoded `EvalTask` (task prompt, target agent/mode, setup).
  TextColumn get taskJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(taskJson))
      .withDefault(const Constant('{}'))();

  /// Content-addressed fixture ref (git bundle + pinned SHA / rift snap).
  TextColumn get fixtureRef => text().nullable()();

  /// Pinned fixture SHA (for fixture-drift measurement against live default).
  TextColumn get fixtureSha => text().nullable()();

  /// JSON array of `EvalGrader`s (deterministic first, LLM-judge only for the
  /// rest).
  TextColumn get gradersJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(gradersJson))
      .withDefault(const Constant('[]'))();

  /// Default batch size (N repetitions to expose variance).
  IntColumn get defaultBatchSize => integer().withDefault(const Constant(1))();

  /// Whether the suite is a built-in starter suite (ships with CC).
  BoolColumn get isStarter => boolean().withDefault(const Constant(false))();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}

/// One batch execution of an eval suite against a config (PRD 21 §5).
///
/// A run goes with its suite.
@TableIndex(
  name: 'idx_eval_runs_suite_created',
  columns: {#suiteId, #createdAt},
)
class EvalRunsTable extends Table {
  @override
  String get tableName => 'eval_runs';

  /// Unique run id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The suite that ran.
  TextColumn get suiteId =>
      text().references(EvalSuitesTable, #id, onDelete: KeyAction.cascade)();

  /// The config hash the batch evaluated.
  TextColumn get configHash => text()();

  /// Number of repetitions in the batch.
  IntColumn get batchSize => integer().withDefault(const Constant(1))();

  /// JSON-encoded `EvalScorecard` (pass-rate, cost, latency, variance,
  /// per-grader breakdown).
  TextColumn get scorecardJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(scorecardJson))();

  /// Aggregate pass-rate `[0,1]` (denormalized for quick sort/filter).
  RealColumn get passRate => real().withDefault(const Constant(0))();

  /// Status: an `EvalRunStatus` name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.evalRunStatus),
      )
      .withDefault(const Constant('queued'))();

  /// Metered cost in micro-dollars.
  IntColumn get costMicros => integer().withDefault(const Constant(0))();

  /// Who/what triggered the run: an `EvalTrigger` name.
  TextColumn get triggeredBy => text()
      .check(
        // ignore: recursive_getters
        triggeredBy.isIn(AgentsStoredValues.evalTrigger),
      )
      .withDefault(const Constant('manual'))();

  /// The fleet job driving the batch, when fanned out to workers (no
  /// foreign key: jobs live in `global.db`).
  TextColumn get jobId => text().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When execution started.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// When the run reached a terminal state.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A versioned agent config with a canary/live/retired lifecycle (PRD 21 §6).
///
/// A config version goes with its agent.
@TableIndex(
  name: 'idx_agent_config_versions_agent',
  columns: {#agentId, #status, #createdAt},
)
class AgentConfigVersionsTable extends Table {
  @override
  String get tableName => 'agent_config_versions';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The agent this config version belongs to.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// SHA-256 config hash (the version identity).
  TextColumn get configHash => text()();

  /// Version of the config-hash field list.
  IntColumn get hashVersion => integer().withDefault(const Constant(1))();

  /// JSON snapshot of the effective config document.
  TextColumn get configJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(configJson))
      .withDefault(const Constant('{}'))();

  /// Lifecycle status: an `AgentConfigVersionStatus` name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.agentConfigVersionStatus),
      )
      .withDefault(const Constant('live'))();

  /// The canary evidence scorecard (goldens + suite), when canaried.
  TextColumn get scorecardJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJson(scorecardJson))();

  /// Principal that promoted this version to live (no foreign key: a user
  /// id lives in `global.db`).
  TextColumn get promotedBy => text().nullable()();

  /// When it was promoted.
  DateTimeColumn get promotedAt => dateTime().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {agentId, configHash},
  ];
}

/// Workspace-owned campaign index. Payload is the canonical domain wire JSON.
@TableIndex(
  name: 'idx_skill_eval_campaigns_skill_created',
  columns: {#skillKey, #createdAt, #id},
)
@TableIndex(
  name: 'idx_skill_eval_campaigns_created',
  columns: {#createdAt, #id},
)
@TableIndex(name: 'idx_skill_eval_campaigns_status', columns: {#status})
class SkillEvalCampaignsTable extends Table {
  @override
  String get tableName => 'skill_eval_campaigns';

  /// Server-assigned campaign identifier.
  TextColumn get id => text()();

  /// Workspace that owns this campaign.
  TextColumn get workspaceId => text()();

  /// Stable skill identity indexed for campaign history.
  TextColumn get skillKey => text()();

  /// Campaign lifecycle state indexed for active campaign queries: a
  /// `SkillEvaluationCampaignStatus` name.
  TextColumn get status => text().check(
    // ignore: recursive_getters
    status.isIn(AgentsStoredValues.skillEvaluationCampaignStatus),
  )();

  /// Campaign creation time used for history ordering.
  DateTimeColumn get createdAt => dateTime()();

  /// Canonical serialized campaign including configuration and results.
  // ignore: recursive_getters
  TextColumn get payloadJson => text().check(isJsonObject(payloadJson))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Attempt metadata and redacted evidence, never host filesystem paths.
@TableIndex(
  name: 'idx_skill_eval_attempts_campaign',
  columns: {#campaignId, #ordinal},
)
class SkillEvalAttemptsTable extends Table {
  @override
  String get tableName => 'skill_eval_attempts';

  /// Server-assigned attempt identifier.
  TextColumn get id => text()();

  /// Workspace that owns this attempt.
  TextColumn get workspaceId => text()();

  /// Parent campaign; an attempt goes with it.
  TextColumn get campaignId => text().references(
    SkillEvalCampaignsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Campaign-wide attempt order used for result listing.
  IntColumn get ordinal => integer()();

  /// Canonical serialized attempt and redacted evidence.
  // ignore: recursive_getters
  TextColumn get payloadJson => text().check(isJsonObject(payloadJson))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Absence means disabled; enabling requires an explicit workspace-level opt-in.
class SkillEvalPoliciesTable extends Table {
  @override
  String get tableName => 'skill_eval_policies';

  /// Workspace that opted into this skill's evaluations.
  TextColumn get workspaceId => text()();

  /// Stable skill identity governed by the policy.
  TextColumn get skillKey => text()();

  /// Whether automatic evaluation is enabled for the skill.
  BoolColumn get enabled => boolean()();

  /// Canonical serialized policy configuration and actor.
  // ignore: recursive_getters
  TextColumn get payloadJson => text().check(isJsonObject(payloadJson))();

  @override
  Set<Column> get primaryKey => {skillKey};
}
