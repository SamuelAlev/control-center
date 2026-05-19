import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/pr_worktree_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/register_orchestration_bodies.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_launcher.dart';
import 'package:cc_domain/features/pipelines/domain/templates/call_flow_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/foreach_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/human_gate_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/messaging_post_space_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/prompt_agent_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_cleanup_repos_body.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_create_space_body.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_index_code_body.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_skill_analysis_body.dart';
import 'package:cc_domain/features/pipelines/domain/templates/team_dispatch_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/trigger_template.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_analysis_port.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/cc_infra.dart';

/// The headless server's pipeline executor: the [PipelineEngine] plus the
/// [StepProcessRegistry] its bodies expose kill callbacks through.
typedef ServerPipelineExecutor = ({
  PipelineEngine engine,
  StepProcessRegistry stepProcess,
});

/// Builds the pure-Dart [PipelineEngine] for the headless `cc_server`, mirroring
/// the desktop `pipelineEngineServerProvider` / `pipelineBodyRegistryProvider`
/// wiring but with the dependencies passed in directly (no Riverpod). The engine
/// drives the same Flutter-free dispatch stack the desktop uses (now relocated
/// to cc_infra), so server-run pipelines dispatch agents through libccpty.
///
/// Registers all step bodies whose dependencies the headless runtime holds.
/// The meeting bodies need only the meeting / voice-profile repos + the
/// (gracefully-degrading) diarization stack, all of which cc_server can
/// construct, so the `meeting_summary` pipeline runs headless. The `indexCode`
/// body (the `index_code` template fired by `RepoAdded`) is wired via
/// [codeIndexer], which FAILS the step (naming the language) when a tree-sitter
/// grammar cannot be resolved — the natives ride in the bundle, so that is a
/// broken install, not a coverage gap. The `cleanupRepos` body (worktree GC for tickets/PRs/sweeps) is
/// wired via [provisioner] and [prWorktrees].
ServerPipelineExecutor buildServerPipelineExecutor({
  required PipelineTemplateRepository templateRepository,
  required PipelineRunRepository runRepository,
  required AgentRunLogRepository agentRunLogRepository,
  required AgentRepository agentRepository,
  required TeamRepository teamRepository,
  required CredentialsRepository credentials,
  required MessagingPort messagingPort,
  required MessagingRepository messagingRepository,
  // Read by `messaging.createSpace` to publish the room's copy-on-write
  // checkout as `repoLocalPath` — what the bash and router steps that used to
  // clone a repo per run now address instead.
  required IsolatedRepoRepository isolatedRepoRepository,
  required AgentDispatchPort agentDispatchPort,
  required GitHubPrClient githubPrClient,
  required OrchestrationRepository orchestrationRepository,
  required TicketWorkflowService ticketWorkflow,
  required CodeIndexer codeIndexer,
  required SkillAnalysisPort skillAnalysis,
  required DomainEventBus eventBus,
  required SchemaValidatorPort schemaValidator,
  required Future<String> Function(String runId) runDirPath,
  // Backs `messaging.createSpace`'s pull-request lane (`extras['pr']`):
  // resolves the PR's one review space (creating it + its association when
  // absent) so the review's reviewers share a single checkout of the repo under
  // review, at the PR head.
  Future<String?> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title,
  })?
  ensureReviewSpace,
  // Backs `prReview.finalize`: turns the reviewers' findings into the verdict
  // + summary the PR's review tab renders, and moves the association to
  // `awaiting_approval` so the operator can publish.
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    String? editorialNote,
    ReviewLevel level,
    String? headSha,
  })?
  finalizeReview,
  // Worktree cleanup body (repos.cleanup) used by pr_merged_cleanup.
  required RepoWorkspaceProvisionerPort provisioner,
  required PrWorktreePort prWorktrees,
  // Meeting summary bodies (the `meeting_summary` pipeline). Diarization
  // degrades to a no-op when its models aren't installed, so wiring it is safe
  // even on a server with only the ASR model present.
  required MeetingRepository meetingRepository,
  required VoiceProfileRepository voiceProfileRepository,
  required DiarizationModelManager diarizationModelManager,
  required MeetingDiarizationPort diarizationService,
}) {
  final stepProcess = StepProcessRegistry();
  final launcher = SubPipelineLauncher();
  final registry = PipelineBodyRegistry();

  registerTriggerBody(registry);
  // Orchestration generates pipelines that use the deterministic `orchestration.*`
  // bodies (hire/team/ticket steps), so register them here too.
  registerOrchestrationBodies(
    registry,
    orchestrations: orchestrationRepository,
    ticketWorkflow: ticketWorkflow,
    messaging: messagingRepository,
    eventBus: eventBus,
  );
  registerBashScriptBody(
    registry,
    templateRepository: templateRepository,
    runRepository: runRepository,
    credentialsRepository: credentials,
    stepProcessRegistry: stepProcess,
    runDirPath: runDirPath,
  );
  registerPrReviewBodies(
    registry,
    githubPrClient: githubPrClient,
    finalizeReview: finalizeReview,
  );
  // The `messaging.createSpace` entry node every agent-bearing template opens
  // with: one visible conversation per run, scoped to exactly the repos and
  // agents that template needs, created before the work so its checkout clones
  // in the background.
  registerCreateSpaceBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    messagingPort: messagingPort,
    messagingRepository: messagingRepository,
    isolatedRepoRepository: isolatedRepoRepository,
    stepProcessRegistry: stepProcess,
    runRepository: runRepository,
    // The PR templates ask this node for the pull request's OWN room, through
    // the same closure the PR page uses — so a review run, a triage run, a
    // pre-merge gate and a human opening the PR all address one checkout.
    ensureReviewSpace: ensureReviewSpace,
  );
  registerPromptAgentBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    messagingPort: messagingPort,
    agentDispatchPort: agentDispatchPort,
    stepProcessRegistry: stepProcess,
    runRepository: runRepository,
  );
  registerMessagingPostSpaceBody(registry, messagingPort: messagingPort);
  registerConditionBody(
    registry,
    templateRepository: templateRepository,
    runDirPath: runDirPath,
  );
  registerTeamDispatchBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    teamRepository: teamRepository,
    messagingPort: messagingPort,
    agentDispatchPort: agentDispatchPort,
    stepProcessRegistry: stepProcess,
    runRepository: runRepository,
  );
  registerHumanGateBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    messagingPort: messagingPort,
    agentDispatchPort: agentDispatchPort,
    stepProcessRegistry: stepProcess,
    runRepository: runRepository,
  );
  registerForEachBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    messagingPort: messagingPort,
    agentDispatchPort: agentDispatchPort,
    stepProcessRegistry: stepProcess,
    runRepository: runRepository,
  );
  registerCallFlowBody(
    registry,
    templateRepository: templateRepository,
    launcher: launcher,
  );
  // The `code.index` body of the `index_code` template (fired by `RepoAdded`).
  // Walks the repo with tree-sitter and ingests symbols/edges into the
  // workspace-scoped code graph. Always safe to register: with nothing indexable
  // the indexer returns a skipped result and a MISSING grammar for a recognised
  // language fails the step loudly (a broken install) rather than writing a graph
  // that silently omits that language.
  registerIndexCodeBody(
    registry,
    codeIndexer: codeIndexer,
    runRepository: runRepository,
    stepProcessRegistry: stepProcess,
  );
  // Skills antivirus (skills.analyze) — scans installed skills' on-disk bytes
  // and enforces quarantines. Deterministic and agentless; the same work the
  // settings UI's scan ops drive synchronously.
  registerSkillAnalysisBody(registry, skillAnalysis: skillAnalysis);
  // Worktree cleanup (repos.cleanup) — releases ticket/PR worktrees or sweeps
  // orphans. Uses the same provisioner + prWorktree the runtime already owns.
  registerCleanupReposBody(
    registry,
    templateRepository: templateRepository,
    provisioner: provisioner,
    prWorktrees: prWorktrees,
  );
  // The deterministic `meeting.*` persist bodies of the `meeting_summary`
  // pipeline (diarize → identifySpeakers → saveNotes / addActionItems /
  // addDecisions). Diarization is best-effort and no-ops when its models aren't
  // on disk, so this is safe whenever the host can resolve a transcriber.
  registerMeetingBodies(
    registry,
    meetingRepository: meetingRepository,
    voiceProfileRepository: voiceProfileRepository,
    diarizationModelManager: diarizationModelManager,
    diarizationService: diarizationService,
  );

  final engine = PipelineEngine(
    bodies: registry,
    templates: templateRepository,
    repository: runRepository,
    agentRunLogRepository: agentRunLogRepository,
    stepProcessRegistry: stepProcess,
    eventBus: eventBus,
    schemaValidator: schemaValidator,
  );
  // Wire the late-bound launcher so `flow.callPipeline` can start child runs.
  launcher.engine = engine;

  return (engine: engine, stepProcess: stepProcess);
}
