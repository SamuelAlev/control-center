import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between the eval (PRD 21) table rows — [SessionRecordingsTableData],
/// [GoldenSessionsTableData], [EvalSuitesTableData], [EvalRunsTableData],
/// [AgentConfigVersionsTableData] — and their domain entities. Every entity
/// field maps 1:1 to a same-named column, so the mappers are direct copies.
class EvalsMapper {
  /// Creates an [EvalsMapper].
  const EvalsMapper();

  // ── Session recordings ──

  /// Session-recording row to domain.
  SessionRecording recordingFromRow(SessionRecordingsTableData row) =>
      SessionRecording(
        id: row.id,
        workspaceId: row.workspaceId,
        runLogId: row.runLogId,
        agentId: row.agentId,
        conversationId: row.conversationId,
        configHash: row.configHash,
        hashVersion: row.hashVersion,
        eventsRef: row.eventsRef,
        cassetteRef: row.cassetteRef,
        fixtureRef: row.fixtureRef,
        eventCount: row.eventCount,
        title: row.title,
        createdAt: row.createdAt,
      );

  /// Session recording to companion (full-row upsert).
  SessionRecordingsTableCompanion recordingToCompanion(SessionRecording r) =>
      SessionRecordingsTableCompanion(
        id: Value(r.id),
        workspaceId: Value(r.workspaceId),
        runLogId: Value(r.runLogId),
        agentId: Value(r.agentId),
        conversationId: Value(r.conversationId),
        configHash: Value(r.configHash),
        hashVersion: Value(r.hashVersion),
        eventsRef: Value(r.eventsRef),
        cassetteRef: Value(r.cassetteRef),
        fixtureRef: Value(r.fixtureRef),
        eventCount: Value(r.eventCount),
        title: Value(r.title),
        createdAt: Value(r.createdAt),
      );

  // ── Golden sessions ──

  /// Golden-session row to domain.
  GoldenSession goldenFromRow(GoldenSessionsTableData row) => GoldenSession(
    id: row.id,
    workspaceId: row.workspaceId,
    agentId: row.agentId,
    recordingId: row.recordingId,
    mode: row.mode,
    name: row.name,
    enabled: row.enabled,
    lastStatus: row.lastStatus,
    lastScorecardJson: row.lastScorecardJson,
    blessedBy: row.blessedBy,
    blessedAt: row.blessedAt,
  );

  /// Golden session to companion (full-row upsert).
  GoldenSessionsTableCompanion goldenToCompanion(GoldenSession g) =>
      GoldenSessionsTableCompanion(
        id: Value(g.id),
        workspaceId: Value(g.workspaceId),
        agentId: Value(g.agentId),
        recordingId: Value(g.recordingId),
        mode: Value(g.mode),
        name: Value(g.name),
        enabled: Value(g.enabled),
        lastStatus: Value(g.lastStatus),
        lastScorecardJson: Value(g.lastScorecardJson),
        blessedBy: Value(g.blessedBy),
        blessedAt: Value(g.blessedAt),
      );

  // ── Eval suites ──

  /// Eval-suite row to domain.
  EvalSuite suiteFromRow(EvalSuitesTableData row) => EvalSuite(
    id: row.id,
    workspaceId: row.workspaceId,
    name: row.name,
    description: row.description,
    taskJson: row.taskJson,
    fixtureRef: row.fixtureRef,
    fixtureSha: row.fixtureSha,
    gradersJson: row.gradersJson,
    defaultBatchSize: row.defaultBatchSize,
    isStarter: row.isStarter,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// Eval suite to companion (full-row upsert).
  EvalSuitesTableCompanion suiteToCompanion(EvalSuite s) =>
      EvalSuitesTableCompanion(
        id: Value(s.id),
        workspaceId: Value(s.workspaceId),
        name: Value(s.name),
        description: Value(s.description),
        taskJson: Value(s.taskJson),
        fixtureRef: Value(s.fixtureRef),
        fixtureSha: Value(s.fixtureSha),
        gradersJson: Value(s.gradersJson),
        defaultBatchSize: Value(s.defaultBatchSize),
        isStarter: Value(s.isStarter),
        createdAt: Value(s.createdAt),
        updatedAt: Value(s.updatedAt),
      );

  // ── Eval runs ──

  /// Eval-run row to domain.
  EvalRun runFromRow(EvalRunsTableData row) => EvalRun(
    id: row.id,
    workspaceId: row.workspaceId,
    suiteId: row.suiteId,
    configHash: row.configHash,
    batchSize: row.batchSize,
    scorecardJson: row.scorecardJson,
    passRate: row.passRate,
    status: row.status,
    costCents: row.costCents,
    triggeredBy: row.triggeredBy,
    jobId: row.jobId,
    createdAt: row.createdAt,
    startedAt: row.startedAt,
    finishedAt: row.finishedAt,
  );

  /// Eval run to companion (full-row upsert).
  EvalRunsTableCompanion runToCompanion(EvalRun r) => EvalRunsTableCompanion(
    id: Value(r.id),
    workspaceId: Value(r.workspaceId),
    suiteId: Value(r.suiteId),
    configHash: Value(r.configHash),
    batchSize: Value(r.batchSize),
    scorecardJson: Value(r.scorecardJson),
    passRate: Value(r.passRate),
    status: Value(r.status),
    costCents: Value(r.costCents),
    triggeredBy: Value(r.triggeredBy),
    jobId: Value(r.jobId),
    createdAt: Value(r.createdAt),
    startedAt: Value(r.startedAt),
    finishedAt: Value(r.finishedAt),
  );

  // ── Agent config versions ──

  /// Agent-config-version row to domain.
  AgentConfigVersion configVersionFromRow(AgentConfigVersionsTableData row) =>
      AgentConfigVersion(
        id: row.id,
        workspaceId: row.workspaceId,
        agentId: row.agentId,
        configHash: row.configHash,
        hashVersion: row.hashVersion,
        configJson: row.configJson,
        status: row.status,
        scorecardJson: row.scorecardJson,
        promotedBy: row.promotedBy,
        promotedAt: row.promotedAt,
        createdAt: row.createdAt,
      );

  /// Agent config version to companion (full-row upsert).
  AgentConfigVersionsTableCompanion configVersionToCompanion(
    AgentConfigVersion v,
  ) => AgentConfigVersionsTableCompanion(
    id: Value(v.id),
    workspaceId: Value(v.workspaceId),
    agentId: Value(v.agentId),
    configHash: Value(v.configHash),
    hashVersion: Value(v.hashVersion),
    configJson: Value(v.configJson),
    status: Value(v.status),
    scorecardJson: Value(v.scorecardJson),
    promotedBy: Value(v.promotedBy),
    promotedAt: Value(v.promotedAt),
    createdAt: Value(v.createdAt),
  );
}
