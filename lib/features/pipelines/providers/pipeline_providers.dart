import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
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
/// engine is server-side execution that must own the DB and (b) routing it over
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
final pipelineEngineProvider = Provider<PipelineEnginePort>(
  buildPipelineEngine,
);

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

/// How long the running-run count must hold still before the sidebar badge
/// follows it. See [runningPipelineCountProvider].
const _badgeSettleDelay = Duration(milliseconds: 700);

/// The number of runs currently `running` in the family's workspace, SETTLED by
/// [_badgeSettleDelay] — the feed behind the sidebar's pipelines badge.
///
/// Event-triggered housekeeping pipelines finish faster than the eye can read:
/// `pr_merged_cleanup` starts on every PR the open-PR poller sees flip to
/// merged/closed and the overwhelming majority of its runs start and finish
/// inside the same second. Counting `running` straight off the run stream turns
/// each of those into a `1` badge that blinks on and off, which reads as a bug
/// and points at nothing the operator can act on. Presence over decoration: a
/// badge nobody can read is noise, so a run has to still be going after
/// [_badgeSettleDelay] to earn one. The pipelines screen keeps the unsettled
/// stream and still shows every run, however brief.
///
/// `distinct()` runs BEFORE the debounce on purpose: the run stream re-emits on
/// every pipeline mutation (progress ticks, step transitions) and feeding those
/// no-op repeats into the timer would keep resetting it, so a long, chatty run
/// would never surface a badge at all.
final runningPipelineCountProvider = StreamProvider.family<int, String>((
  ref,
  workspaceId,
) {
  return _settled(
    ref
        .watch(pipelineRunRepositoryProvider)
        .watchForWorkspace(workspaceId)
        .map(
          (runs) => runs
              .where((run) => run.status == PipelineRunStatus.running)
              .length,
        )
        .distinct(),
    _badgeSettleDelay,
  );
});

/// Trailing-debounces [source]: emits a value only once [delay] has passed with
/// nothing newer arriving and drops the emission if the settled value matches
/// what was last emitted. A burst that returns to where it started therefore
/// produces no emission at all — which is what keeps a sub-second pipeline run
/// from reaching the widget tree.
Stream<T> _settled<T>(Stream<T> source, Duration delay) {
  StreamSubscription<T>? subscription;
  Timer? timer;
  late T pending;
  var hasPending = false;
  var hasEmitted = false;
  late T lastEmitted;
  late StreamController<T> controller;

  void flush() {
    timer = null;
    if (!hasPending) {
      return;
    }
    hasPending = false;
    if (hasEmitted && pending == lastEmitted) {
      return;
    }
    hasEmitted = true;
    lastEmitted = pending;
    controller.add(pending);
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        (value) {
          pending = value;
          hasPending = true;
          timer?.cancel();
          timer = Timer(delay, flush);
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          flush();
          controller.close();
        },
      );
    },
    onCancel: () async {
      timer?.cancel();
      timer = null;
      await subscription?.cancel();
      subscription = null;
    },
  );
  return controller.stream;
}

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

/// The agent run logs dispatched during a pipeline run (newest first),
/// workspace-scoped. The step detail panel filters these to a single step run
/// (by `pipelineStepRunId`) so it can show what the step's agent actually did —
/// status, summary, duration, cost — not just the step's terminal status.
final pipelineRunAgentLogsProvider =
    FutureProvider.family<List<AgentRunLog>, PipelineRunKey>((ref, key) async {
      return ref
          .watch(agentRunLogRepositoryProvider)
          .forPipelineRun(key.workspaceId, key.runId);
    });

/// Clock that ticks every second so duration displays stay live for active runs.
final pipelineClockProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
});

/// Watches a single pipeline run by ID, emitting on every status change.
final pipelineRunProvider = StreamProvider.family<PipelineRun?, String>((
  ref,
  runId,
) {
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
      final triggersAsync = ref.watch(
        pipelineTriggersForWorkspaceProvider(workspaceId),
      );
      return templatesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
        data: (templates) => triggersAsync.when(
          loading: () => const AsyncValue.loading(),
          error: AsyncValue.error,
          data: (triggers) {
            final manualTemplateIds = triggers
                .where(
                  (t) =>
                      t.enabled &&
                      t.eventType == PipelineTrigger.manualEventType,
                )
                .map((t) => t.templateId)
                .toSet();
            final runnable =
                templates
                    .where(
                      (t) =>
                          t.isEnabled &&
                          manualTemplateIds.contains(t.templateId),
                    )
                    .toList()
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
            return AsyncValue.data(runnable);
          },
        ),
      );
    });

/// The `manual` trigger for a single template, or null if the template is not
/// manually runnable. Used by the editor's "allow manual run" toggle.
final manualTriggerForTemplateProvider =
    Provider.family<
      AsyncValue<PipelineTrigger?>,
      ({String workspaceId, String templateId})
    >((ref, args) {
      final triggersAsync = ref.watch(
        pipelineTriggersForWorkspaceProvider(args.workspaceId),
      );
      return triggersAsync.whenData(
        (triggers) => triggers.firstWhereOrNull(
          (t) =>
              t.templateId == args.templateId &&
              t.eventType == PipelineTrigger.manualEventType,
        ),
      );
    });
