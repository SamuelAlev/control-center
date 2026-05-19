import 'dart:async';

import 'package:collection/collection.dart';
import 'package:control_center/core/database/daos/pipeline_dao.dart';
import 'package:control_center/core/database/daos/pipeline_template_dao.dart';
import 'package:control_center/core/database/daos/pipeline_trigger_dao.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pipelines/data/repositories/pipeline_run_repository_impl.dart';
import 'package:control_center/features/pipelines/data/repositories/pipeline_template_repository_impl.dart';
import 'package:control_center/features/pipelines/data/repositories/pipeline_trigger_repository_impl.dart';
import 'package:control_center/features/pipelines/data/services/json_schema_validator.dart';
import 'package:control_center/features/pipelines/data/templates/bash_script_template.dart';
import 'package:control_center/features/pipelines/data/templates/condition_template.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/agent_run_task_completer.dart';
import 'package:control_center/features/pipelines/domain/services/node_type_library.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_cost_rollup_listener.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_trigger_dispatcher.dart';
import 'package:control_center/features/pipelines/domain/services/step_process_registry.dart';
import 'package:control_center/features/pipelines/domain/services/sub_pipeline_launcher.dart';
import 'package:control_center/features/pipelines/domain/services/sub_pipeline_resume_listener.dart';
import 'package:control_center/features/pipelines/domain/templates/call_flow_template.dart';
import 'package:control_center/features/pipelines/domain/templates/create_ticket_template.dart';
import 'package:control_center/features/pipelines/domain/templates/foreach_template.dart';
import 'package:control_center/features/pipelines/domain/templates/hello_pipeline_template.dart';
import 'package:control_center/features/pipelines/domain/templates/human_gate_template.dart';
import 'package:control_center/features/pipelines/domain/templates/messaging_post_channel_template.dart';
import 'package:control_center/features/pipelines/domain/templates/pr_review_pipeline_template.dart';
import 'package:control_center/features/pipelines/domain/templates/prompt_agent_template.dart';
import 'package:control_center/features/pipelines/domain/templates/register_index_code_body.dart';
import 'package:control_center/features/pipelines/domain/templates/team_dispatch_template.dart';
import 'package:control_center/features/pipelines/domain/templates/trigger_template.dart';
import 'package:control_center/features/teams/providers/team_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
export 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
export 'package:control_center/features/pipelines/domain/entities/pipeline_step_run.dart';
export 'package:control_center/features/pipelines/domain/services/node_type_library.dart';
export 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
export 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';

/// Provides the [PipelineDao].
final pipelineDaoProvider = Provider<PipelineDao>((ref) {
  return ref.watch(databaseProvider).pipelineDao;
});

/// Provides the [PipelineTemplateDao].
final pipelineTemplateDaoProvider = Provider<PipelineTemplateDao>((ref) {
  return ref.watch(databaseProvider).pipelineTemplateDao;
});

/// Provides the [PipelineTriggerDao].
final pipelineTriggerDaoProvider = Provider<PipelineTriggerDao>((ref) {
  return ref.watch(databaseProvider).pipelineTriggerDao;
});

/// Provides the [PipelineRunRepositoryImpl].
final pipelineRunRepositoryProvider = Provider<PipelineRunRepositoryImpl>((
  ref,
) {
  return PipelineRunRepositoryImpl(ref.watch(pipelineDaoProvider));
});

/// Provides the [PipelineTemplateRepositoryImpl].
final pipelineTemplateRepositoryProvider = Provider<PipelineTemplateRepository>(
  (ref) {
    return PipelineTemplateRepositoryImpl(
      ref.watch(pipelineTemplateDaoProvider),
    );
  },
);

/// Provides the [PipelineTriggerRepositoryImpl].
final pipelineTriggerRepositoryProvider =
    Provider<PipelineTriggerRepositoryImpl>((ref) {
      return PipelineTriggerRepositoryImpl(
        ref.watch(pipelineTriggerDaoProvider),
      );
    });

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
  final registry = PipelineBodyRegistry();
  registerTriggerBody(registry);
  registerHelloBodies(registry);
  registerBashScriptBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
    runRepository: ref.watch(pipelineRunRepositoryProvider),
    credentialsRepository: ref.watch(credentialsRepositoryProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
  );
  registerPrReviewBodies(
    registry,
    githubPrClient: ref.watch(githubApiClientProvider).pr,
  );
  registerPromptAgentBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(agentRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    agentDispatchPort: ref.watch(agentDispatchPortProvider),
  );
  registerMessagingPostChannelBody(
    registry,
    messagingPort: ref.watch(messagingServiceProvider),
  );
  registerConditionBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
  );
  registerTeamDispatchBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(agentRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
  );
  registerHumanGateBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(agentRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
  );
  registerForEachBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
    agentRepository: ref.watch(agentRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
  );
  registerCallFlowBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
    launcher: ref.watch(subPipelineLauncherProvider),
  );
  registerCreateTicketBody(
    registry,
    templateRepository: ref.watch(pipelineTemplateRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    provider: ref.watch(activeTicketProviderProvider),
  );
  registerIndexCodeBody(
    registry,
    codeIndexer: ref.watch(codeIndexerProvider),
    runRepository: ref.watch(pipelineRunRepositoryProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
  );
  return registry;
});

/// Provides the [NodeTypeLibrary] used to populate the editor sidebar.
final nodeTypeLibraryProvider = Provider<NodeTypeLibrary>((ref) {
  return defaultNodeTypeLibrary();
});

/// Provides the [PipelineEngine].
final pipelineEngineProvider = Provider<PipelineEngine>((ref) {
  final engine = PipelineEngine(
    bodies: ref.watch(pipelineBodyRegistryProvider),
    templates: ref.watch(pipelineTemplateRepositoryProvider),
    repository: ref.watch(pipelineRunRepositoryProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
    stepProcessRegistry: ref.watch(stepProcessRegistryProvider),
    eventBus: ref.watch(domainEventBusProvider),
    schemaValidator: const JsonSchemaValidator(),
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
    engine: ref.watch(pipelineEngineProvider),
    repository: ref.watch(pipelineRunRepositoryProvider),
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
    ticketRepository: ref.watch(ticketRepositoryProvider),
    runLogRepository: ref.watch(agentRunLogRepositoryProvider),
    runRepository: ref.watch(pipelineRunRepositoryProvider),
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
    engine: ref.watch(pipelineEngineProvider),
    triggerRepository: ref.watch(pipelineTriggerRepositoryProvider),
  );
});

/// Watches every persisted template in [workspaceId], built-ins first.
final pipelineTemplatesProvider =
    StreamProvider.family<List<PipelineDefinition>, String>((ref, workspaceId) {
      return ref
          .watch(pipelineTemplateRepositoryProvider)
          .watchForWorkspace(workspaceId);
    });

/// Watches all pipeline runs for a specific workspace.
final workspacePipelineRunsProvider =
    StreamProvider.family<List<PipelineRun>, String>((ref, workspaceId) {
      return ref
          .watch(pipelineRunRepositoryProvider)
          .watchForWorkspace(workspaceId);
    });

/// Watches step runs for a single pipeline run. Used by the canvas overlay
/// and the step timeline.
final pipelineStepRunsForRunProvider =
    StreamProvider.family<List<PipelineStepRun>, String>((ref, runId) {
      return ref
          .watch(pipelineRunRepositoryProvider)
          .watchStepRunsForPipeline(runId);
    });

/// Clock that ticks every second so duration displays stay live for active runs.
final pipelineClockProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
});

/// Watches a single pipeline run by ID, emitting on every status change.
final pipelineRunProvider =
    StreamProvider.family<PipelineRun?, String>((ref, runId) {
      return ref.watch(pipelineRunRepositoryProvider).watchRun(runId);
    });

/// Watches pipeline triggers for a specific workspace.
final pipelineTriggersForWorkspaceProvider =
    StreamProvider.family<List<PipelineTrigger>, String>((ref, workspaceId) {
      return ref
          .watch(pipelineTriggerRepositoryProvider)
          .watchForWorkspace(workspaceId);
    });

/// The enabled templates in [workspaceId] that can be started by hand — i.e.
/// those that are enabled AND have an enabled `manual` trigger. Drives the run
/// page's pipeline picker. Sorted by name. Combines the templates and triggers
/// streams so it reacts to either changing.
final manuallyRunnablePipelinesProvider =
    Provider.family<AsyncValue<List<PipelineDefinition>>, String>((
      ref,
      workspaceId,
    ) {
      final templatesAsync = ref.watch(pipelineTemplatesProvider(workspaceId));
      final triggersAsync =
          ref.watch(pipelineTriggersForWorkspaceProvider(workspaceId));
      return templatesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
        data: (templates) => triggersAsync.when(
          loading: () => const AsyncValue.loading(),
          error: AsyncValue.error,
          data: (triggers) {
            final manualTemplateIds = triggers
                .where((t) =>
                    t.enabled &&
                    t.eventType == PipelineTrigger.manualEventType)
                .map((t) => t.templateId)
                .toSet();
            final runnable = templates
                .where((t) =>
                    t.isEnabled && manualTemplateIds.contains(t.templateId))
                .toList()
              ..sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return AsyncValue.data(runnable);
          },
        ),
      );
    });

/// The `manual` trigger for a single template, or null if the template is not
/// manually runnable. Used by the editor's "allow manual run" toggle.
final manualTriggerForTemplateProvider = Provider.family<
    AsyncValue<PipelineTrigger?>,
    ({String workspaceId, String templateId})>((ref, args) {
  final triggersAsync =
      ref.watch(pipelineTriggersForWorkspaceProvider(args.workspaceId));
  return triggersAsync.whenData(
    (triggers) => triggers.firstWhereOrNull(
      (t) =>
          t.templateId == args.templateId &&
          t.eventType == PipelineTrigger.manualEventType,
    ),
  );
});

/// Keep-alive notifier that resumes in-flight pipelines on app startup.
class PipelineResumeNotifier extends Notifier<void> {
  @override
  void build() {
    final engine = ref.watch(pipelineEngineProvider);
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
      final repo = ref.read(pipelineTriggerRepositoryProvider);
      final engine = ref.read(pipelineEngineProvider);
      final now = DateTime.now();
      final scheduled = await repo.scheduled();
      for (final trigger in scheduled) {
        final interval = trigger.intervalSeconds;
        if (interval == null) continue;
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

/// Provides the [AgentRunTaskCompleter] that auto-completes pipeline tasks
/// when their dispatched agent finishes — so suspended `promptAgent` steps
/// don't get stuck waiting for the agent to manually call `complete_task`.
final agentRunTaskCompleterProvider = Provider<AgentRunTaskCompleter>((ref) {
  return AgentRunTaskCompleter(
    eventBus: ref.watch(domainEventBusProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    messagingRepository: ref.watch(messagingRepositoryProvider),
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
