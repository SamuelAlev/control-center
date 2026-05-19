import 'package:drift/drift.dart';

/// A complete, replayable recording of one harness run (PRD 21 §1).
///
/// Bundles the event stream, the LLM/tool cassettes (content-addressed refs),
/// the fixture ref and the [configHash] — the content hash over the effective
/// agent config. Workspace-scoped. Recording is opt-in per agent/channel, so
/// most runs have no row here.
@TableIndex(name: 'idx_session_recordings_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_session_recordings_config', columns: {#configHash})
@TableIndex(name: 'idx_session_recordings_runlog', columns: {#runLogId})
class SessionRecordingsTable extends Table {
  @override
  String get tableName => 'session_recordings';

  /// Unique recording id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The run log this recording captures.
  TextColumn get runLogId => text()();

  /// The agent whose config produced this run (nullable for ad-hoc runs).
  TextColumn get agentId => text().nullable()();

  /// The conversation (channel) id, when applicable.
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
@TableIndex(name: 'idx_golden_sessions_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_golden_sessions_agent', columns: {#agentId})
class GoldenSessionsTable extends Table {
  @override
  String get tableName => 'golden_sessions';

  /// Unique golden id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The agent (or playbook, by convention) this golden protects.
  TextColumn get agentId => text()();

  /// The recording that is the golden.
  TextColumn get recordingId => text()();

  /// Gating mode: `deterministic` (exact, free, default) or `live` (advisory).
  TextColumn get mode => text().withDefault(const Constant('deterministic'))();

  /// Operator-facing name.
  TextColumn get name => text().withDefault(const Constant(''))();

  /// Whether the golden is active (gates saves / CI).
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Last run status (`pass`/`fail`/`unknown`).
  TextColumn get lastStatus => text().withDefault(const Constant('unknown'))();

  /// Last run scorecard JSON (diff summary / grader breakdown).
  TextColumn get lastScorecardJson => text().nullable()();

  /// Principal that blessed the golden.
  TextColumn get blessedBy => text().nullable()();

  /// When it was blessed.
  DateTimeColumn get blessedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A workspace-scoped eval suite: task + fixture + graders (PRD 21 §5).
@TableIndex(name: 'idx_eval_suites_workspace', columns: {#workspaceId})
class EvalSuitesTable extends Table {
  @override
  String get tableName => 'eval_suites';

  /// Unique suite id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Suite name (unique per workspace by convention).
  TextColumn get name => text()();

  /// Suite description.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// JSON-encoded `EvalTask` (task prompt, target agent/mode, setup).
  TextColumn get taskJson => text().withDefault(const Constant('{}'))();

  /// Content-addressed fixture ref (git bundle + pinned SHA / rift snap).
  TextColumn get fixtureRef => text().nullable()();

  /// Pinned fixture SHA (for fixture-drift measurement against live default).
  TextColumn get fixtureSha => text().nullable()();

  /// JSON array of `EvalGrader`s (deterministic first, LLM-judge only for the
  /// rest).
  TextColumn get gradersJson => text().withDefault(const Constant('[]'))();

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
    {workspaceId, name},
  ];
}

/// One batch execution of an eval suite against a config (PRD 21 §5).
@TableIndex(
  name: 'idx_eval_runs_workspace_suite_config',
  columns: {#workspaceId, #suiteId, #configHash},
)
class EvalRunsTable extends Table {
  @override
  String get tableName => 'eval_runs';

  /// Unique run id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The suite that ran.
  TextColumn get suiteId => text()();

  /// The config hash the batch evaluated.
  TextColumn get configHash => text()();

  /// Number of repetitions in the batch.
  IntColumn get batchSize => integer().withDefault(const Constant(1))();

  /// JSON-encoded `EvalScorecard` (pass-rate, cost, latency, variance,
  /// per-grader breakdown).
  TextColumn get scorecardJson => text().nullable()();

  /// Aggregate pass-rate `[0,1]` (denormalized for quick sort/filter).
  RealColumn get passRate => real().withDefault(const Constant(0))();

  /// Status: `queued`/`running`/`done`/`failed`/`cancelled`.
  TextColumn get status => text().withDefault(const Constant('queued'))();

  /// Metered cost in cents.
  IntColumn get costCents => integer().withDefault(const Constant(0))();

  /// Who/what triggered the run (`manual`/`canary`/`golden`/`ci`).
  TextColumn get triggeredBy => text().withDefault(const Constant('manual'))();

  /// The fleet job driving the batch, when fanned out to workers.
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
@TableIndex(
  name: 'idx_agent_config_versions_workspace',
  columns: {#workspaceId},
)
@TableIndex(
  name: 'idx_agent_config_versions_agent',
  columns: {#agentId, #status},
)
class AgentConfigVersionsTable extends Table {
  @override
  String get tableName => 'agent_config_versions';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The agent this config version belongs to.
  TextColumn get agentId => text()();

  /// SHA-256 config hash (the version identity).
  TextColumn get configHash => text()();

  /// Version of the config-hash field list.
  IntColumn get hashVersion => integer().withDefault(const Constant(1))();

  /// JSON snapshot of the effective config document.
  TextColumn get configJson => text().withDefault(const Constant('{}'))();

  /// Lifecycle status: `live`/`canary`/`retired`.
  TextColumn get status => text().withDefault(const Constant('live'))();

  /// The canary evidence scorecard (goldens + suite), when canaried.
  TextColumn get scorecardJson => text().nullable()();

  /// Principal that promoted this version to live.
  TextColumn get promotedBy => text().nullable()();

  /// When it was promoted.
  DateTimeColumn get promotedAt => dateTime().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, agentId, configHash},
  ];
}
