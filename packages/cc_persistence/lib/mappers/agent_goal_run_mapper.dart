import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_progress_marks.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [AgentGoalRun] domain entities and `agent_goal_runs` rows.
class AgentGoalRunMapper {
  /// Creates an [AgentGoalRunMapper].
  const AgentGoalRunMapper();

  /// To domain.
  AgentGoalRun toDomain(AgentGoalRunsTableData row) => AgentGoalRun(
    id: row.id,
    workspaceId: row.workspaceId,
    spaceId: row.spaceId,
    conversationId: row.conversationId,
    agentId: row.agentId,
    userText: row.userText,
    status: AgentGoalStatusWire.fromWire(row.status),
    // drift reads a stored time back as a local time; the goal keeps UTC.
    deadlineAt: row.deadlineAt?.toUtc(),
    costCapMicros: row.costCapMicros,
    costMicros: row.costMicros,
    maxRuns: row.maxRuns,
    runCount: row.runCount,
    activeRunId: row.activeRunId,
    consecutiveFailures: row.consecutiveFailures,
    requestedByUserId: row.requestedByUserId,
    summary: row.summary,
    // JSON columns decode defensively: a malformed contract or verification
    // reads as absent rather than failing every goal read.
    contract: GoalContract.tryParse(row.contract),
    hold: GoalHoldWire.tryParse(row.hold),
    holdUntil: row.holdUntil?.toUtc(),
    holdDetail: _clip(row.holdDetail, AgentGoalRun.maxHoldDetailLength),
    noProgressStreak: row.noProgressStreak,
    verificationRounds: row.verificationRounds,
    lastFingerprint: row.lastFingerprint,
    lastActivityDigest: _digest(row.lastActivityDigest),
    startRefs: GoalStartRefs.tryParse(row.startRef),
    parkCount: row.parkCount,
    fresh: row.fresh,
    unattended:
        GoalUnattendedPolicyWire.tryParse(row.unattended) ??
        GoalUnattendedPolicy.wait,
    checkerAgentId: (row.checkerAgentId?.isEmpty ?? true)
        ? null
        : row.checkerAgentId,
    verification: GoalVerification.tryParse(row.verification),
    pipeline: GoalPipelineLink.tryOf(row.pipelineRunId, row.pipelineStepId),
    progressMarks: row.progressMarks == null
        ? null
        : GoalProgressMarks.parse(row.progressMarks),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );

  static String? _clip(String? text, int max) =>
      text == null || text.length <= max ? text : text.substring(0, max);

  /// A digest the entity would refuse reads as absent: a clipped digest would
  /// compare as changed work.
  static String? _digest(String? text) =>
      text == null ||
          text.isEmpty ||
          text.length > AgentGoalRun.maxActivityDigestLength
      ? null
      : text;

  /// To domain list.
  List<AgentGoalRun> toDomainList(List<AgentGoalRunsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// To companion.
  AgentGoalRunsTableCompanion toCompanion(AgentGoalRun goal) =>
      AgentGoalRunsTableCompanion(
        id: Value(goal.id),
        workspaceId: Value(goal.workspaceId),
        spaceId: Value(goal.spaceId),
        conversationId: Value(goal.conversationId),
        agentId: Value(goal.agentId),
        userText: Value(goal.userText),
        status: Value(goal.status.wire),
        deadlineAt: Value(goal.deadlineAt),
        costCapMicros: Value(goal.costCapMicros),
        costMicros: Value(goal.costMicros),
        maxRuns: Value(goal.maxRuns),
        runCount: Value(goal.runCount),
        activeRunId: Value(goal.activeRunId),
        consecutiveFailures: Value(goal.consecutiveFailures),
        requestedByUserId: Value(goal.requestedByUserId),
        summary: Value(goal.summary),
        contract: Value(goal.contract?.encode()),
        hold: Value(goal.hold?.wire),
        holdUntil: Value(goal.holdUntil),
        holdDetail: Value(goal.holdDetail),
        noProgressStreak: Value(goal.noProgressStreak),
        verificationRounds: Value(goal.verificationRounds),
        lastFingerprint: Value(goal.lastFingerprint),
        lastActivityDigest: Value(goal.lastActivityDigest),
        startRef: Value(goal.startRefs?.encode()),
        parkCount: Value(goal.parkCount),
        fresh: Value(goal.fresh),
        unattended: Value(goal.unattended.wire),
        checkerAgentId: Value(goal.checkerAgentId),
        verification: Value(goal.verification?.encode()),
        pipelineRunId: Value(goal.pipeline?.pipelineRunId),
        pipelineStepId: Value(goal.pipeline?.stepId),
        progressMarks: Value(goal.progressMarks?.encode()),
        createdAt: Value(goal.createdAt),
        updatedAt: Value(goal.updatedAt),
      );
}
