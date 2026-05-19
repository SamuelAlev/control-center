import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
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
import 'package:cc_domain/features/pipelines/domain/templates/hello_pipeline_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/human_gate_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/messaging_post_channel_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/prompt_agent_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_index_code_body.dart';
import 'package:cc_domain/features/pipelines/domain/templates/team_dispatch_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/trigger_template.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/pipelines/bash_script_template.dart';
import 'package:cc_infra/src/pipelines/condition_template.dart';
import 'package:cc_infra/src/pipelines/pr_review_pipeline_template.dart';
import 'package:cc_infra/src/pipelines/register_meeting_bodies.dart';
import 'package:cc_infra/src/speech/diarization_model_manager.dart';

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
/// Registers the core + PR-review + meeting + code-index step bodies — every
/// body whose dependencies the headless runtime already holds. The meeting
/// bodies need only the meeting / voice-profile repos + the (gracefully-
/// degrading) diarization stack, all of which cc_server can construct, so the
/// `meeting_summary` pipeline runs headless. The `indexCode` body (the
/// `index_code` template fired by `RepoAdded`) is wired via [codeIndexer],
/// which the runtime builds from the code-graph repo + grammar manager; it
/// degrades gracefully (no symbols) when the tree-sitter natives are absent.
/// The remaining heavier body (`cleanupRepos`) still pulls the rift stack and
/// is a follow-up; a pipeline that uses it fails with an unknown-body error
/// until then (the common templates do not).
ServerPipelineExecutor buildServerPipelineExecutor({
  required PipelineTemplateRepository templateRepository,
  required PipelineRunRepository runRepository,
  required AgentRunLogRepository agentRunLogRepository,
  required AgentRepository agentRepository,
  required TeamRepository teamRepository,
  required CredentialsRepository credentials,
  required MessagingPort messagingPort,
  required MessagingRepository messagingRepository,
  required AgentDispatchPort agentDispatchPort,
  required GitHubPrClient githubPrClient,
  required OrchestrationRepository orchestrationRepository,
  required TicketWorkflowService ticketWorkflow,
  required CodeIndexer codeIndexer,
  required DomainEventBus eventBus,
  required SchemaValidatorPort schemaValidator,
  required Future<String> Function(String runId) runDirPath,
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
  registerHelloBodies(registry);
  registerBashScriptBody(
    registry,
    templateRepository: templateRepository,
    runRepository: runRepository,
    credentialsRepository: credentials,
    stepProcessRegistry: stepProcess,
    runDirPath: runDirPath,
  );
  registerPrReviewBodies(registry, githubPrClient: githubPrClient);
  registerPromptAgentBody(
    registry,
    templateRepository: templateRepository,
    agentRepository: agentRepository,
    messagingPort: messagingPort,
    agentDispatchPort: agentDispatchPort,
    stepProcessRegistry: stepProcess,
    runRepository: runRepository,
  );
  registerMessagingPostChannelBody(registry, messagingPort: messagingPort);
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
  // workspace-scoped code graph; the indexer degrades to a skipped result when
  // the grammar natives aren't installed, so this is safe to always register.
  registerIndexCodeBody(
    registry,
    codeIndexer: codeIndexer,
    runRepository: runRepository,
    stepProcessRegistry: stepProcess,
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
