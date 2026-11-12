import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show RunErrorFamily, RunLiveness, RunStatus;
import 'package:cc_domain/core/domain/entities/llm_call_record.dart'
    show LlmCallOutcome;
import 'package:cc_domain/core/domain/value_objects/actor_kind.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_visibility.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart'
    show PrincipalType;
import 'package:cc_domain/core/domain/value_objects/run_cost.dart'
    show CostBasis;
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart'
    show TurnOutcome, turnOutcomeToString;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart'
    show AgentGoalKind, AgentGoalKindWire;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart'
    show SkillEvaluationCampaignStatus;
import 'package:cc_domain/features/evals/domain/value_objects/eval_stored_values.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart'
    show ApprovalStatus;
import 'package:cc_domain/features/governance/domain/value_objects/budget_scope.dart';
import 'package:cc_domain/features/governance/domain/value_objects/heartbeat_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/protocol_family.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel, GuardSurface;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart'
    show ActionDecision, ActionPolicyProvenance, ActionScopeType;
import 'package:cc_domain/features/guardrails/domain/value_objects/guard_decision_kind.dart';
import 'package:cc_domain/features/model_routing/domain/entities/provider_policy.dart'
    show PolicyEffect, PolicyLayer;
import 'package:cc_domain/features/observability/domain/run_verification.dart'
    show VerificationStatus;
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart'
    show CronCatchUpPolicy;
import 'package:cc_domain/features/pipelines/domain/entities/webhook_delivery.dart'
    show WebhookDeliveryStatus, WebhookSignatureStatus;
import 'package:cc_domain/features/pipelines/domain/value_objects/cron_fire_status.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart'
    show PlanDocumentStatus;
import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart'
    show SandboxExecGrantDecision;
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart'
    show SkillScanVerdict;
import 'package:cc_domain/features/teams/domain/entities/team_activity.dart'
    show TeamActivityKind;
import 'package:cc_domain/features/teams/domain/entities/team_member.dart'
    show TeamMemberRole;
import 'package:cc_domain/features/ticketing/domain/entities/project.dart'
    show ProjectColor, ProjectStatus;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart'
    show TicketCollaboratorRole;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart'
    show TicketLinkType;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart'
    show SyncOutcome;
import 'package:cc_harness/tools.dart' show ActionClass;

/// The closed sets of values stored in text columns of these tables:
/// Agent, run, pipeline, ticket, team, approval, budget and governance tables.
///
/// Each list is built from the Dart enum that owns the values, with the same
/// accessor the mapper writes (`name`, `wire`, …), so a `CHECK` on the
/// column cannot disagree with the code. A column check reads
/// `text().check(status.isIn(AgentsStoredValues.someStatus))()`.
///
/// Adding a value to one of those enums changes the declared schema: bump the
/// database's schema version so existing files converge to the wider check.
// A namespace the column checks read; it is never instantiated.
// ignore: avoid_classes_with_only_static_members
abstract final class AgentsStoredValues {
  // --- guardrails ---

  /// `action_policies.scope_type`.
  static final List<String> actionScopeType = [
    for (final v in ActionScopeType.values) v.wire,
  ];

  /// `action_policies.action_class`.
  static final List<String> actionClass = [
    for (final v in ActionClass.values) v.wire,
  ];

  /// `action_policies.decision`, `guard_decisions.decision`.
  static final List<String> actionDecision = [
    for (final v in ActionDecision.values) v.wire,
  ];

  /// `action_policies.provenance`.
  static final List<String> actionPolicyProvenance = [
    for (final v in ActionPolicyProvenance.values) v.wire,
  ];

  /// `action_policies.enforcement`, `guard_decisions.enforcement`.
  static final List<String> enforcementLevel = [
    for (final v in EnforcementLevel.values) v.wire,
  ];

  /// `guard_decisions.surface`.
  static final List<String> guardSurface = [
    for (final v in GuardSurface.values) v.wire,
  ];

  /// `guard_decisions.kind`.
  static final List<String> guardDecisionKind = [
    for (final v in GuardDecisionKind.values) v.wire,
  ];

  /// `sandbox_exec_grants.decision`.
  static final List<String> sandboxExecGrantDecision = [
    for (final v in SandboxExecGrantDecision.values) v.wire,
  ];

  /// `provider_policies.effect`.
  static final List<String> policyEffect = [
    for (final v in PolicyEffect.values) v.id,
  ];

  /// `provider_policies.layer`.
  static final List<String> policyLayer = [
    for (final v in PolicyLayer.values) v.name,
  ];

  /// `skill_scan_results.verdict`.
  static final List<String> skillScanVerdict = [
    for (final v in SkillScanVerdict.values) v.wire,
  ];

  // --- actors ---

  /// Who did something: the `*_actor_type` / `author_type` / `author_kind`
  /// columns of approvals, comments, revisions and the guard audit.
  static final List<String> actorKind = [
    for (final v in ActorKind.values) v.wire,
  ];

  /// A principal kind: `tickets.assignee_type`,
  /// `ticket_collaborators.collaborator_type`.
  static final List<String> principalType = [
    for (final v in PrincipalType.values) v.wireName,
  ];

  /// `tickets.created_by_type` for a ticket the server itself opened (no
  /// principal behind it).
  static const String systemTicketCreator = 'system';

  /// `tickets.created_by_type`: a principal kind, or [systemTicketCreator].
  static final List<String> ticketCreatedByType = [
    ...principalType,
    systemTicketCreator,
  ];

  // --- tickets ---

  /// `tickets.provider`.
  static final List<String> ticketProvider = [
    for (final v in TicketProvider.values) v.toStorageString(),
  ];

  /// `tickets.status`.
  static final List<String> ticketStatus = [
    for (final v in TicketStatus.values) v.toStorageString(),
  ];

  /// `tickets.origin_kind`.
  static final List<String> ticketOriginKind = [
    for (final v in TicketOriginKind.values) v.name,
  ];

  /// `ticket_collaborators.role`.
  static final List<String> ticketCollaboratorRole = [
    for (final v in TicketCollaboratorRole.values) v.toStorageString(),
  ];

  /// `ticket_links.type`.
  static final List<String> ticketLinkType = [
    for (final v in TicketLinkType.values) v.toStorageString(),
  ];

  /// `ticket_sync_configs.direction`, `ticket_sync_links.last_direction`,
  /// `ticket_sync_log.direction`.
  static final List<String> syncDirection = [
    for (final v in SyncDirection.values) v.toStorageString(),
  ];

  /// `ticket_sync_log.outcome`.
  static final List<String> syncOutcome = [
    for (final v in SyncOutcome.values) v.toStorageString(),
  ];

  /// `projects.color`.
  static final List<String> projectColor = [
    for (final v in ProjectColor.values) v.toStorageString(),
  ];

  /// `projects.status`.
  static final List<String> projectStatus = [
    for (final v in ProjectStatus.values) v.toStorageString(),
  ];

  // --- teams and agents ---

  /// `team_members.role`.
  static final List<String> teamMemberRole = [
    for (final v in TeamMemberRole.values) v.toStorageString(),
  ];

  /// `team_activity_log.kind`.
  static final List<String> teamActivityKind = [
    for (final v in TeamActivityKind.values) v.toStorageString(),
  ];

  /// `agents.role`.
  static final List<String> agentRole = [
    for (final v in AgentRole.values) v.name,
  ];

  /// `agents.visibility`.
  static final List<String> agentVisibility = [
    for (final v in AgentVisibility.values) v.name,
  ];

  /// `agents.lifecycle_status`.
  static final List<String> agentLifecycleStatus = [
    for (final v in AgentLifecycleStatus.values) v.name,
  ];

  /// `agent_runtime_state.reported_status`.
  static final List<String> heartbeatStatus = [
    for (final v in HeartbeatStatus.values) v.name,
  ];

  /// `runtime_profiles.protocol_family`.
  static final List<String> protocolFamily = [
    for (final v in ProtocolFamily.values) v.name,
  ];

  /// `agent_goal_runs.kind`.
  static final List<String> agentGoalKind = [
    for (final v in AgentGoalKind.values) v.wire,
  ];

  /// `agent_goal_runs.status`.
  static final List<String> agentGoalStatus = [
    for (final v in AgentGoalStatus.values) v.wire,
  ];

  // --- runs ---

  /// `agent_run_logs.status`.
  static final List<String> runStatus = [
    for (final v in RunStatus.values) v.name,
  ];

  /// `agent_run_logs.cost_basis`, `run_call_usages.cost_basis`.
  static final List<String> costBasis = [
    for (final v in CostBasis.values) v.name,
  ];

  /// `agent_run_logs.verification_status`.
  static final List<String> verificationStatus = [
    for (final v in VerificationStatus.values) v.wire,
  ];

  /// `agent_run_logs.agent_role`.
  static final List<String> agentRunRole = [
    for (final v in AgentRunRole.values) v.name,
  ];

  /// `agent_run_logs.liveness_class`.
  static final List<String> runLiveness = [
    for (final v in RunLiveness.values) v.name,
  ];

  /// `agent_run_logs.error_family`.
  static final List<String> runErrorFamily = [
    for (final v in RunErrorFamily.values) v.name,
  ];

  /// `agent_run_logs.output_contract_mode`.
  static final List<String> outputContractMode = [
    for (final v in OutputContractMode.values) v.toStorageString(),
  ];

  /// `transcripts.outcome`.
  static final List<String> turnOutcome = [
    for (final v in TurnOutcome.values) turnOutcomeToString(v),
  ];

  /// `run_call_usages.purpose`.
  static final List<String> llmCallPurpose = [
    for (final v in LlmCallPurpose.values) v.wire,
  ];

  /// `run_call_usages.outcome`.
  static final List<String> llmCallOutcome = [
    for (final v in LlmCallOutcome.values) v.wire,
  ];

  // --- pipelines ---

  /// `pipeline_runs.status`.
  static final List<String> pipelineRunStatus = [
    for (final v in PipelineRunStatus.values) v.toStorageString(),
  ];

  /// `pipeline_step_runs.status`.
  static final List<String> pipelineStepStatus = [
    for (final v in PipelineStepStatus.values) v.toStorageString(),
  ];

  /// `pipeline_triggers.catch_up_policy`.
  static final List<String> cronCatchUpPolicy = [
    for (final v in CronCatchUpPolicy.values) v.name,
  ];

  /// `cron_executions.status`.
  static final List<String> cronFireStatus = [
    for (final v in CronFireStatus.values) v.wire,
  ];

  /// `webhook_deliveries.status`.
  static final List<String> webhookDeliveryStatus = [
    for (final v in WebhookDeliveryStatus.values) v.toStorageString(),
  ];

  /// `webhook_deliveries.signature_status`.
  static final List<String> webhookSignatureStatus = [
    for (final v in WebhookSignatureStatus.values) v.toStorageString(),
  ];

  // --- governance ---

  /// `approvals.kind`.
  static final List<String> approvalKind = [
    for (final v in ApprovalKind.values) v.storage,
  ];

  /// `approvals.status`.
  static final List<String> approvalStatus = [
    for (final v in ApprovalStatus.values) v.storage,
  ];

  /// `budget_policy.scope_type`, `budget_incidents.scope_type`.
  static final List<String> budgetScopeType = [
    for (final v in BudgetScopeType.values) v.wire,
  ];

  /// `budget_policy.status`.
  static final List<String> budgetPolicyStatus = [
    for (final v in BudgetPolicyStatus.values) v.wire,
  ];

  /// `goals.level`.
  static final List<String> orgGoalLevel = [
    for (final v in OrgGoalLevel.values) v.name,
  ];

  /// `goals.status`.
  static final List<String> orgGoalStatus = [
    for (final v in OrgGoalStatus.values) v.name,
  ];

  /// `work_products.artifact_type`.
  static final List<String> workProductType = [
    for (final v in WorkProductType.values) v.name,
  ];

  /// `orchestrations.status`.
  static final List<String> orchestrationStatus = [
    for (final v in OrchestrationStatus.values) v.toStorageString(),
  ];

  /// `plan_documents.status`.
  static final List<String> planDocumentStatus = [
    for (final v in PlanDocumentStatus.values) v.name,
  ];

  // --- evals ---

  /// `golden_sessions.mode`.
  static final List<String> goldenMode = [
    for (final v in GoldenMode.values) v.wire,
  ];

  /// `golden_sessions.last_status`.
  static final List<String> goldenStatus = [
    for (final v in GoldenStatus.values) v.wire,
  ];

  /// `eval_runs.status`.
  static final List<String> evalRunStatus = [
    for (final v in EvalRunStatus.values) v.wire,
  ];

  /// `eval_runs.triggered_by`.
  static final List<String> evalTrigger = [
    for (final v in EvalTrigger.values) v.wire,
  ];

  /// `agent_config_versions.status`.
  static final List<String> agentConfigVersionStatus = [
    for (final v in AgentConfigVersionStatus.values) v.wire,
  ];

  /// `skill_eval_campaigns.status`.
  static final List<String> skillEvaluationCampaignStatus = [
    for (final v in SkillEvaluationCampaignStatus.values) v.name,
  ];
}
