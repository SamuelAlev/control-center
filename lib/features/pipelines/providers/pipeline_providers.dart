import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:collection/collection.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pipelines/pipeline_bindings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
export 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
export 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
export 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
export 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';

/// The [PipelineRunRepository] the UI reads/writes through — flipped to the
/// cc_data RpcX adapter over the desktop's in-process RPC server (the
/// composition flip). Server-side EXECUTION (the engine, body registry, trigger
/// dispatcher, scheduler, resume/rollup listeners) does NOT use this — it reads
/// the Dao-backed `daoPipelineRunRepositoryProvider` directly, because (a) the
/// engine is server-side execution that must own the DB, and (b) routing it over
/// RPC would cycle through `rpcClientProvider` → the MCP dispatcher → the tool
/// registry → the engine. Both paths share one Drift DB, so the UI's RPC streams
/// still update live.
final pipelineRunRepositoryProvider = Provider<PipelineRunRepository>((ref) {
  return RpcPipelineRunRepository(ref.watch(rpcClientProvider));
});

/// The [PipelineTemplateRepository] the UI reads/writes through — RPC-backed
/// (see [pipelineRunRepositoryProvider]). Save-time schema validation lives on
/// the server-side write path (`daoPipelineTemplateRepositoryProvider`).
final pipelineTemplateRepositoryProvider = Provider<PipelineTemplateRepository>(
  (ref) {
    return RpcPipelineTemplateRepository(ref.watch(rpcClientProvider));
  },
);

/// The [PipelineTriggerRepository] the UI reads through — RPC-backed (see
/// [pipelineRunRepositoryProvider]).
final pipelineTriggerRepositoryProvider = Provider<PipelineTriggerRepository>((
  ref,
) {
  return RpcPipelineTriggerRepository(ref.watch(rpcClientProvider));
});

/// Provides the [NodeTypeLibrary] used to populate the editor sidebar.
/// Pure data — web-safe.
final nodeTypeLibraryProvider = Provider<NodeTypeLibrary>((ref) {
  return defaultNodeTypeLibrary();
});

/// Provides the pipeline EXECUTOR, typed as the web-safe [PipelineEnginePort].
///
/// DECLARED here and RESOLVED through the pipeline seam: on the VM it builds the
/// real `PipelineEngine` (owning run-state via dao*, driving the dispatch stack
/// — it cannot go over RPC, being the server reached by the MCP tool registry);
/// on web it returns an honest "not available on web" stub for the
/// start/cancel/retry actions. The pipeline list/run views still read run state
/// over RPC on both targets.
final pipelineEngineProvider = Provider<PipelineEnginePort>(buildPipelineEngine);

/// Watches every persisted template in `workspaceId`, built-ins first.
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

/// Identifies a pipeline run within a workspace, for workspace-scoped run-log
/// queries. A record (value equality) so it works as a provider family key.
typedef PipelineRunKey = ({String workspaceId, String runId});

/// Per-step cost (in US cents) for a pipeline run, rolled up from the agent
/// run logs dispatched by each step. Keyed by the template step id, so the
/// waterfall can label each bar with its cost. Workspace-scoped: reads only
/// run logs belonging to the caller's workspace.
final pipelineStepCostProvider =
    FutureProvider.family<Map<String, int>, PipelineRunKey>((ref, key) async {
  final logs = await ref
      .watch(agentRunLogRepositoryProvider)
      .forPipelineRun(key.workspaceId, key.runId);
  final byStep = <String, int>{};
  for (final log in logs) {
    final stepId = log.pipelineStepRunId;
    if (stepId == null) {
      continue;
    }
    byStep[stepId] = (byStep[stepId] ?? 0) + log.cost.estimatedCostCents;
  }
  return byStep;
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

/// The enabled templates in `workspaceId` that can be started by hand — i.e.
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
