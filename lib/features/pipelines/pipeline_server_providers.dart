// VM-only pipeline providers (server-side execution half of
// `pipeline_providers.dart`).
//
// The pipeline EXECUTOR — the engine, the step-body registry, and every
// keep-alive listener / dispatcher / scheduler — runs on the server. It owns
// run-state persistence and template loading, drives the dispatch stack
// (cc_natives code indexer, the messaging service, the repo provisioner / PR
// worktrees), and is reached by the MCP tool registry that `rpcClientProvider`
// depends on. So it binds the Drift `dao*` repositories directly and lives
// here — imported by the desktop bootstrap, the MCP/orchestration server
// surfaces, and the pipeline seam, never from the web graph. The web-safe UI
// providers (run/template/trigger RPC reads + derivations + UI state) stay in
// `pipeline_providers.dart`.
library;

import 'dart:async';

import 'package:cc_domain/features/calendar/domain/services/event_attendee_names.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/agent_run_task_completer.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cost_rollup_listener.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_step_resume_listener.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_trigger_dispatcher.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_launcher.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_resume_listener.dart';
import 'package:cc_domain/features/pipelines/domain/templates/call_flow_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/foreach_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/hello_pipeline_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/human_gate_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/messaging_post_channel_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/prompt_agent_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_cleanup_repos_body.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_index_code_body.dart';
import 'package:cc_domain/features/pipelines/domain/templates/team_dispatch_template.dart';
import 'package:cc_domain/features/pipelines/domain/templates/trigger_template.dart';
import 'package:cc_infra/src/pipelines/bash_script_template.dart';
import 'package:cc_infra/src/pipelines/condition_template.dart';
import 'package:cc_infra/src/pipelines/pr_review_pipeline_template.dart';
import 'package:cc_infra/src/pipelines/register_meeting_bodies.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_providers.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart'
    show messagingServiceProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory registry that bodies use to expose a kill callback so the
/// UI's per-node Stop button can interrupt their live work.
final stepProcessRegistryProvider = Provider<StepProcessRegistry>((ref) {
  return StepProcessRegistry();
});

/// Late-bound bridge so the `flow.callPipeline` body can start child runs.
/// The engine provider sets [SubPipelineLauncher.engine] after construction.
final subPipelineLauncherProvider = Provider<SubPipelineLauncher>((ref) {
  return SubPipelineLauncher();
});

/// Provides the [PipelineBodyRegistry] populated with every built-in body.
///
/// Templates (the *graphs*) live in the DB; only the executable step bodies
/// are registered here, looked up by `bodyKey` at runtime.
final pipelineBodyRegistryProvider = Provider<PipelineBodyRegistry>((ref) {
  // The step bodies are server-side EXECUTION — they persist run state and load
  // templates as the engine runs them, so they bind the Dao-backed (`dao*`)
  // pipeline/team repositories, NOT the RPC ones the UI reads. (Routing them
  // over RPC would cycle through rpcClient → MCP dispatcher → tool registry →
  // engine → body registry.)
  final registry = PipelineBodyRegistry();
  registerTriggerBody(registry);
  registerHelloBodies(registry);
  registerBashScriptBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
    credentialsRepository: ref.watch(credentialsRepositoryProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    runDirPath: (runId) async => (await appCcPaths.pipelineRunDir(runId)).path,
  );
  registerPrReviewBodies(
    registry,
    githubPrClient: ref.watch(githubApiClientProvider).pr,
  );
  registerPromptAgentBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(daoAgentRepositoryProvider),
    messagingPort: ref.watch(messagingServiceProvider),
    agentDispatchPort: ref.watch(agentDispatchPortProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
  );
  registerMessagingPostChannelBody(
    registry,
    messagingPort: ref.watch(messagingServiceProvider),
  );
  registerConditionBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    runDirPath: (runId) async => (await appCcPaths.pipelineRunDir(runId)).path,
  );
  registerTeamDispatchBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(daoAgentRepositoryProvider),
    teamRepository: ref.watch(daoTeamRepositoryProvider),
    messagingPort: ref.watch(messagingServiceProvider),
    agentDispatchPort: ref.watch(agentDispatchPortProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
  );
  registerHumanGateBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(daoAgentRepositoryProvider),
    messagingPort: ref.watch(messagingServiceProvider),
    agentDispatchPort: ref.watch(agentDispatchPortProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
  );
  registerForEachBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(daoAgentRepositoryProvider),
    messagingPort: ref.watch(messagingServiceProvider),
    agentDispatchPort: ref.watch(agentDispatchPortProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
  );
  registerCallFlowBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    launcher: ref.watch(subPipelineLauncherProvider),
  );
  registerIndexCodeBody(
    registry,
    codeIndexer: ref.watch(codeIndexerProvider),
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
  );
  registerCleanupReposBody(
    registry,
    templateRepository: ref.watch(daoPipelineTemplateRepositoryProvider),
    provisioner: ref.watch(repoWorkspaceProvisionerProvider),
    prWorktrees: ref.watch(prWorktreePortProvider),
  );
  registerMeetingBodies(
    registry,
    meetingRepository: ref.watch(meetingRepositoryProvider),
    voiceProfileRepository: ref.watch(daoVoiceProfileRepositoryProvider),
    diarizationModelManager: ref.watch(diarizationModelManagerProvider),
    diarizationService: const MeetingDiarizationService(),
    recordFact: ref.watch(recordMemoryFactUseCaseProvider),
    // Pre-seed diarized speaker names from the meeting's linked calendar
    // invitees (best-effort; the user can correct via the rename chips).
    attendeeNamesFor: (workspaceId, meetingId, channel) async {
      final event = await ref
          .read(calendarRepositoryProvider)
          .getEventForMeeting(workspaceId, meetingId);
      return eventAttendeeNames(event, self: channel == MeetingSpeaker.me);
    },
  );
  return registry;
});

/// Provides the concrete [PipelineEngine] — the server-side pipeline EXECUTOR.
/// It owns run-state persistence and template loading, so it binds the
/// Dao-backed (`dao*`) repositories directly; it cannot go over RPC (it is the
/// server, and it is reached by the MCP tool registry that `rpcClientProvider`
/// depends on). Exposed to the UI as a `PipelineEnginePort` via the pipeline
/// seam (`pipelineEngineProvider`).
final pipelineEngineServerProvider = Provider<PipelineEngine>((ref) {
  final engine = PipelineEngine(
    bodies: ref.watch(pipelineBodyRegistryProvider),
    templates: ref.watch(daoPipelineTemplateRepositoryProvider),
    repository: ref.watch(daoPipelineRunRepositoryProvider),
    agentRunLogRepository: ref.watch(daoAgentRunLogRepositoryProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    eventBus: ref.watch(domainEventBusProvider),
    schemaValidator: ref.watch(schemaValidatorProvider),
  );
  // Wire the late-bound launcher so `flow.callPipeline` can start child runs.
  ref.watch(subPipelineLauncherProvider).engine = engine;
  ref.onDispose(() => unawaited(engine.dispose()));
  return engine;
});

/// Resumes a parent `flow.callPipeline` step when its child run finishes.
final subPipelineResumeListenerProvider =
    Provider<SubPipelineResumeListener>((ref) {
  return SubPipelineResumeListener(
    eventBus: ref.watch(domainEventBusProvider),
    engine: ref.watch(pipelineEngineServerProvider),
    repository: ref.watch(daoPipelineRunRepositoryProvider),
  );
});

/// Keep-alive notifier that starts the sub-pipeline resume listener.
class SubPipelineResumeNotifier extends Notifier<void> {
  @override
  void build() {
    final listener = ref.watch(subPipelineResumeListenerProvider);
    listener.start();
    ref.onDispose(listener.dispose);
  }
}

/// Keeps the sub-pipeline resume listener alive across the app lifetime.
final subPipelineResumeAliveProvider =
    NotifierProvider<SubPipelineResumeNotifier, void>(
  SubPipelineResumeNotifier.new,
);

/// Rolls up agent cost/tokens onto the dispatching pipeline run.
final pipelineCostRollupListenerProvider =
    Provider<PipelineCostRollupListener>((ref) {
  return PipelineCostRollupListener(
    eventBus: ref.watch(domainEventBusProvider),
    runLogRepository: ref.watch(daoAgentRunLogRepositoryProvider),
    runRepository: ref.watch(daoPipelineRunRepositoryProvider),
  );
});

/// Keep-alive notifier that starts the cost rollup listener.
class PipelineCostRollupNotifier extends Notifier<void> {
  @override
  void build() {
    final listener = ref.watch(pipelineCostRollupListenerProvider);
    listener.start();
    ref.onDispose(listener.dispose);
  }
}

/// Keeps the cost rollup listener alive across the app lifetime.
final pipelineCostRollupAliveProvider =
    NotifierProvider<PipelineCostRollupNotifier, void>(
  PipelineCostRollupNotifier.new,
);

/// Provides the [PipelineTriggerDispatcher].
final pipelineTriggerDispatcherProvider = Provider<PipelineTriggerDispatcher>((
  ref,
) {
  return PipelineTriggerDispatcher(
    eventBus: ref.watch(domainEventBusProvider),
    engine: ref.watch(pipelineEngineServerProvider),
    triggerRepository: ref.watch(daoPipelineTriggerRepositoryProvider),
  );
});

/// Keep-alive notifier that resumes in-flight pipelines on app startup.
class PipelineResumeNotifier extends Notifier<void> {
  @override
  void build() {
    final engine = ref.watch(pipelineEngineServerProvider);
    unawaited(() async {
      try {
        await engine.resumeAll();
      } on Object catch (e, st) {
        AppLog.e('PipelineResume', 'Failed to resume pipelines', e, st);
      }
    }());
  }
}

/// Keeps the pipeline resume listener alive across the app lifetime.
final pipelineResumeProvider = NotifierProvider<PipelineResumeNotifier, void>(
  PipelineResumeNotifier.new,
);

/// Keep-alive notifier that starts the trigger dispatcher.
class PipelineTriggerDispatcherNotifier extends Notifier<void> {
  @override
  void build() {
    final dispatcher = ref.watch(pipelineTriggerDispatcherProvider);
    dispatcher.start();
    ref.onDispose(dispatcher.dispose);
  }
}

/// Keeps the trigger dispatcher alive across the app lifetime.
final pipelineTriggerDispatcherAliveProvider =
    NotifierProvider<PipelineTriggerDispatcherNotifier, void>(
      PipelineTriggerDispatcherNotifier.new,
    );

/// Ticks every minute and starts pipelines whose scheduled (`every:<seconds>`)
/// trigger is due. Kept out of the domain dispatcher (which is event-only) so
/// the timer lives in the provider/infra layer.
class PipelineScheduleNotifier extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      unawaited(_tick());
    });
    ref.onDispose(() => _timer?.cancel());
  }

  Future<void> _tick() async {
    try {
      // Server-side scheduler tick: reads the cross-workspace `scheduled()` set
      // and fires due pipelines. Dao-backed (the engine is server-side; the RPC
      // trigger repo is for the workspace-scoped UI reads).
      final repo = ref.read(daoPipelineTriggerRepositoryProvider);
      final engine = ref.read(pipelineEngineServerProvider);
      final now = DateTime.now();
      final scheduled = await repo.scheduled();
      for (final trigger in scheduled) {
        final interval = trigger.intervalSeconds;
        if (interval == null) {
          continue;
        }
        final last = trigger.lastFiredAt;
        if (last != null && now.difference(last).inSeconds < interval) {
          continue;
        }
        await engine.start(
          trigger.templateId,
          workspaceId: trigger.workspaceId,
          triggerEventType: PipelineTrigger.scheduleEventType,
          triggerPayload: {'workspaceId': trigger.workspaceId},
        );
        await repo.markFired(trigger.id, now);
      }
    } on Object catch (e, st) {
      AppLog.e('PipelineSchedule', 'scheduled tick failed', e, st);
    }
  }
}

/// Keeps the scheduled-trigger ticker alive across the app lifetime.
final pipelineScheduleAliveProvider =
    NotifierProvider<PipelineScheduleNotifier, void>(
  PipelineScheduleNotifier.new,
);

/// Provides the [AgentRunTaskCompleter] that harvests a best-effort output
/// onto a pipeline-dispatched run when the agent finishes without calling
/// `submit_output`, so suspended steps don't get stuck.
final agentRunTaskCompleterProvider = Provider<AgentRunTaskCompleter>((ref) {
  return AgentRunTaskCompleter(
    eventBus: ref.watch(domainEventBusProvider),
    runLogRepository: ref.watch(daoAgentRunLogRepositoryProvider),
    // Server-side keep-alive listener (harvests pipeline-run output) — owns the
    // DB directly via dao*.
    messagingRepository: ref.watch(daoMessagingRepositoryProvider),
  );
});

/// Keep-alive notifier that starts the agent-run → task bridge.
class AgentRunTaskCompleterNotifier extends Notifier<void> {
  @override
  void build() {
    final bridge = ref.watch(agentRunTaskCompleterProvider);
    bridge.start();
    ref.onDispose(bridge.dispose);
  }
}

/// Keeps the agent-run → task bridge alive across the app lifetime.
final agentRunTaskCompleterAliveProvider =
    NotifierProvider<AgentRunTaskCompleterNotifier, void>(
      AgentRunTaskCompleterNotifier.new,
    );

/// Resumes a suspended pipeline step when every agent run it dispatched has
/// finished. The conversation-first successor to the ticket resume listener.
final pipelineStepResumeListenerProvider =
    Provider<PipelineStepResumeListener>((ref) {
  final listener = PipelineStepResumeListener(
    eventBus: ref.watch(domainEventBusProvider),
    runLogRepository: ref.watch(daoAgentRunLogRepositoryProvider),
    engine: ref.watch(pipelineEngineServerProvider),
  );
  listener.start();
  ref.onDispose(listener.dispose);
  return listener;
});

/// Keep-alive notifier that starts the pipeline step resume listener.
class PipelineStepResumeListenerNotifier extends Notifier<void> {
  @override
  void build() {
    ref.watch(pipelineStepResumeListenerProvider);
  }
}

/// Keeps the pipeline step resume listener alive across the app lifetime.
final pipelineStepResumeListenerAliveProvider =
    NotifierProvider<PipelineStepResumeListenerNotifier, void>(
      PipelineStepResumeListenerNotifier.new,
    );
