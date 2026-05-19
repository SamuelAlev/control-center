// Lightweight domain entities mirroring the PRD 21 eval tables. Kept in one
// file since they are thin data carriers over the workspace-scoped rows.

/// A complete, replayable recording of one harness run (PRD 21 §1).
class SessionRecording {
  /// Creates a [SessionRecording].
  const SessionRecording({
    required this.id,
    required this.workspaceId,
    required this.runLogId,
    required this.configHash,
    required this.createdAt,
    this.agentId,
    this.conversationId,
    this.hashVersion = 1,
    this.eventsRef,
    this.cassetteRef,
    this.fixtureRef,
    this.eventCount = 0,
    this.title = '',
  });

  /// Unique recording id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The run log this captures.
  final String runLogId;

  /// The agent whose config produced the run.
  final String? agentId;

  /// The conversation the run belongs to.
  final String? conversationId;

  /// The config hash at record time.
  final String configHash;

  /// The config-hash field-list version.
  final int hashVersion;

  /// Content-addressed ref to the event stream.
  final String? eventsRef;

  /// Content-addressed ref to the cassette bundle.
  final String? cassetteRef;

  /// Content-addressed ref to the fixture.
  final String? fixtureRef;

  /// Number of events captured.
  final int eventCount;

  /// Human-facing title.
  final String title;

  /// Creation time.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionRecording &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          runLogId == other.runLogId &&
          agentId == other.agentId &&
          conversationId == other.conversationId &&
          configHash == other.configHash &&
          hashVersion == other.hashVersion &&
          eventsRef == other.eventsRef &&
          cassetteRef == other.cassetteRef &&
          fixtureRef == other.fixtureRef &&
          eventCount == other.eventCount &&
          title == other.title &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    runLogId,
    agentId,
    conversationId,
    configHash,
    hashVersion,
    eventsRef,
    cassetteRef,
    fixtureRef,
    eventCount,
    title,
    createdAt,
  );
}

/// A blessed recording pinned as a golden (PRD 21 §4).
class GoldenSession {
  /// Creates a [GoldenSession].
  const GoldenSession({
    required this.id,
    required this.workspaceId,
    required this.agentId,
    required this.recordingId,
    required this.blessedAt,
    this.mode = 'deterministic',
    this.name = '',
    this.enabled = true,
    this.lastStatus = 'unknown',
    this.lastScorecardJson,
    this.blessedBy,
  });

  /// Unique golden id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The agent this golden protects.
  final String agentId;

  /// The recording that is the golden.
  final String recordingId;

  /// Gating mode (`deterministic`/`live`).
  final String mode;

  /// Operator-facing name.
  final String name;

  /// Whether it gates saves / CI.
  final bool enabled;

  /// Last run status.
  final String lastStatus;

  /// Last run scorecard JSON.
  final String? lastScorecardJson;

  /// Who blessed it.
  final String? blessedBy;

  /// When it was blessed.
  final DateTime blessedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoldenSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          recordingId == other.recordingId &&
          mode == other.mode &&
          name == other.name &&
          enabled == other.enabled &&
          lastStatus == other.lastStatus &&
          lastScorecardJson == other.lastScorecardJson &&
          blessedBy == other.blessedBy &&
          blessedAt == other.blessedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    agentId,
    recordingId,
    mode,
    name,
    enabled,
    lastStatus,
    lastScorecardJson,
    blessedBy,
    blessedAt,
  );
}

/// A workspace-scoped eval suite (PRD 21 §5).
class EvalSuite {
  /// Creates an [EvalSuite].
  const EvalSuite({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.taskJson = '{}',
    this.fixtureRef,
    this.fixtureSha,
    this.gradersJson = '[]',
    this.defaultBatchSize = 1,
    this.isStarter = false,
  });

  /// Unique suite id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Suite name.
  final String name;

  /// Description.
  final String description;

  /// The task spec JSON.
  final String taskJson;

  /// Content-addressed fixture ref.
  final String? fixtureRef;

  /// Pinned fixture SHA (drift measurement).
  final String? fixtureSha;

  /// Graders JSON array.
  final String gradersJson;

  /// Default batch size.
  final int defaultBatchSize;

  /// Whether it's a built-in starter suite.
  final bool isStarter;

  /// Creation time.
  final DateTime createdAt;

  /// Last mutation time.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvalSuite &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          name == other.name &&
          description == other.description &&
          taskJson == other.taskJson &&
          fixtureRef == other.fixtureRef &&
          fixtureSha == other.fixtureSha &&
          gradersJson == other.gradersJson &&
          defaultBatchSize == other.defaultBatchSize &&
          isStarter == other.isStarter &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    description,
    taskJson,
    fixtureRef,
    fixtureSha,
    gradersJson,
    defaultBatchSize,
    isStarter,
    createdAt,
    updatedAt,
  );
}

/// One batch execution of a suite against a config (PRD 21 §5).
class EvalRun {
  /// Creates an [EvalRun].
  const EvalRun({
    required this.id,
    required this.workspaceId,
    required this.suiteId,
    required this.configHash,
    required this.createdAt,
    this.batchSize = 1,
    this.scorecardJson,
    this.passRate = 0,
    this.status = 'queued',
    this.costCents = 0,
    this.triggeredBy = 'manual',
    this.jobId,
    this.startedAt,
    this.finishedAt,
  });

  /// Unique run id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The suite that ran.
  final String suiteId;

  /// The config hash evaluated.
  final String configHash;

  /// Batch size.
  final int batchSize;

  /// Scorecard JSON.
  final String? scorecardJson;

  /// Denormalized pass rate.
  final double passRate;

  /// Status.
  final String status;

  /// Metered cost in cents.
  final int costCents;

  /// What triggered it.
  final String triggeredBy;

  /// The fleet job driving the batch.
  final String? jobId;

  /// Creation time.
  final DateTime createdAt;

  /// When it started.
  final DateTime? startedAt;

  /// When it finished.
  final DateTime? finishedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvalRun &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          suiteId == other.suiteId &&
          configHash == other.configHash &&
          batchSize == other.batchSize &&
          scorecardJson == other.scorecardJson &&
          passRate == other.passRate &&
          status == other.status &&
          costCents == other.costCents &&
          triggeredBy == other.triggeredBy &&
          jobId == other.jobId &&
          createdAt == other.createdAt &&
          startedAt == other.startedAt &&
          finishedAt == other.finishedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    suiteId,
    configHash,
    batchSize,
    scorecardJson,
    passRate,
    status,
    costCents,
    triggeredBy,
    jobId,
    createdAt,
    startedAt,
    finishedAt,
  );
}

/// A versioned agent config with a canary lifecycle (PRD 21 §6).
class AgentConfigVersion {
  /// Creates an [AgentConfigVersion].
  const AgentConfigVersion({
    required this.id,
    required this.workspaceId,
    required this.agentId,
    required this.configHash,
    required this.createdAt,
    this.hashVersion = 1,
    this.configJson = '{}',
    this.status = 'live',
    this.scorecardJson,
    this.promotedBy,
    this.promotedAt,
  });

  /// Unique row id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The agent.
  final String agentId;

  /// The config hash (version identity).
  final String configHash;

  /// The field-list version.
  final int hashVersion;

  /// The config snapshot JSON.
  final String configJson;

  /// Lifecycle status (`live`/`canary`/`retired`).
  final String status;

  /// Canary evidence scorecard.
  final String? scorecardJson;

  /// Who promoted it.
  final String? promotedBy;

  /// When promoted.
  final DateTime? promotedAt;

  /// Creation time.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentConfigVersion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          configHash == other.configHash &&
          hashVersion == other.hashVersion &&
          configJson == other.configJson &&
          status == other.status &&
          scorecardJson == other.scorecardJson &&
          promotedBy == other.promotedBy &&
          promotedAt == other.promotedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    agentId,
    configHash,
    hashVersion,
    configJson,
    status,
    scorecardJson,
    promotedBy,
    promotedAt,
    createdAt,
  );
}
