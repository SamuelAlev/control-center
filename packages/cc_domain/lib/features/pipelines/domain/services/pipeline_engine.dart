import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/core/utils/keyed_async_mutex.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart'
    show StepRetryPolicy;
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart'
    show StepResult;
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/downstream_planner.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_input_snapshot.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_start.dart';
import 'package:cc_domain/features/pipelines/domain/services/state_reducer.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show BuiltInBodyKeys;
import 'package:cc_domain/src/errors/app_exceptions.dart'
    show ValidationException;
import 'package:uuid/uuid.dart';

part 'pipeline_engine_admission.dart';
part 'pipeline_engine_downstream.dart';
part 'pipeline_engine_recovery.dart';
part 'pipeline_engine_steps.dart';

/// Reserved state-key prefix recording which branch a router selected, so
/// downstream evaluation can gate conditional edges. One key per router.
const String kRouteStateKeyPrefix = '__route__';

/// Reserved state key holding a map of `stepId -> error message` for steps
/// that failed but were configured `continueOnFail`.
const String kStepErrorsKey = '_stepErrors';

/// Orchestrates pipeline execution: starts runs, schedules steps, persists
/// state and resumes in-flight runs after app restart.
class PipelineEngine implements PipelineEnginePort {
  /// Creates a [PipelineEngine].
  PipelineEngine({
    required this.bodies,
    required this.templates,
    required this.repository,
    required this.eventBus,
    required this.stepProcessRegistry,
    required this.agentRunLogRepository,
    this.reducers = const StateReducer(),
    this.schemaValidator,
    this.renderer = const TemplateRenderer(),
    this.maxStepsPerRun = 500,
    this.maxConcurrentSteps = 8,
    this.suspendedStepTimeout = const Duration(hours: 24),
  }) : _slots = _Semaphore(maxConcurrentSteps);

  /// Combines values when a node writes a state key that already has a value.
  final StateReducer reducers;

  /// Validates node outputs against their declared `outputSchema`. When null
  /// schema validation is skipped (e.g. in tests without an adapter bound).
  final SchemaValidatorPort? schemaValidator;

  /// Centralized `{{key}}` renderer used for the input snapshot.
  final TemplateRenderer renderer;

  /// Hard cap on the number of step executions per run — a loop/recursion
  /// safety backstop. Counted in-memory per process lifetime.
  final int maxStepsPerRun;

  /// Maximum number of step bodies executing concurrently across the engine.
  final int maxConcurrentSteps;

  /// How long a step may stay `suspended` (waiting on tickets that never reach
  /// a terminal state) before the liveness backstop fails it to free the run —
  /// at [resumeAll] and on every [sweepStalledSteps]. A backstop for a
  /// dispatched agent that neither completes its ticket nor ends its run.
  final Duration suspendedStepTimeout;

  /// Bounds concurrent body execution so wide fan-outs (forEach / teamDispatch)
  /// don't dispatch unbounded work at once.
  final _Semaphore _slots;

  /// In-memory executed-step counts per run (loop/recursion guard).
  final Map<String, int> _stepCounts = {};

  /// Code-registered step body closures (keyed by `bodyKey`).
  final PipelineBodyRegistry bodies;

  /// DB-backed template repository — source of truth for pipeline graphs.
  final PipelineTemplateRepository templates;

  /// Pipeline run persistence.
  final PipelineRunRepository repository;

  /// Used during step resume to collect the dispatched agent runs' output
  /// payloads and feed them into pipeline state under the resumed step's
  /// `outputKey`.
  final AgentRunLogRepository agentRunLogRepository;

  /// real work (subprocess, dispatched agent) is live so [killStep] can
  /// interrupt them from the UI.
  final StepProcessRegistry stepProcessRegistry;

  /// Publishes domain events for pipeline state transitions.
  final DomainEventBus eventBus;

  /// Per-run lock that serializes state merges so two parallel steps can't
  /// lose each other's writes. Keyed by run id.
  final KeyedAsyncMutex _stateLocks = KeyedAsyncMutex();

  /// Per-run lock that serializes downstream evaluation. Without it, two
  /// steps completing in parallel could both read the step-run set before
  /// either writes, then both insert a `skipped` row for the same bypassed
  /// branch (or both schedule the same ready step). Keyed by run id.
  final KeyedAsyncMutex _evalLocks = KeyedAsyncMutex();

  /// Steps an evaluation has scheduled whose `_runStep` has not finished yet,
  /// as `runId -> {stepId}`.
  ///
  /// [_evalLocks] serializes evaluations, but scheduling is fire-and-forget:
  /// `_runStep` awaits the run row (and may flip it to running) BEFORE it
  /// inserts the step row. A join's second upstream completing in that window
  /// found no row, read the join as unstarted and scheduled it again — an
  /// approved plan ran its fan-in steps, the join and synthesis twice. The
  /// claim stands in for the row until `_runStep` returns, by which point the
  /// row itself carries the existing-row veto.
  final Map<String, Set<String>> _scheduledSteps = {};

  /// Serializes [start] per `(templateId, workspaceId, dedupKey)` so two
  /// concurrent triggers carrying the same dedup key can't both pass the
  /// active-run check and insert duplicate runs (a check-then-insert TOCTOU).
  /// Only engaged when `dedupKey != null`.
  final KeyedAsyncMutex _startLocks = KeyedAsyncMutex();

  /// Serializes the `maxParallelRuns` count-then-admit per
  /// `(workspaceId, templateId)`. Both the admission check in [start] and the
  /// promotion in [_admitNext] run under it, so two starts racing a completion
  /// can't each read "one slot free" and both take it. Only engaged for
  /// templates that declare a cap.
  final KeyedAsyncMutex _capLocks = KeyedAsyncMutex();

  /// Per-`(runId, stepId)` lock chain serializing [resumeStep] /
  /// [resumeChildFlow].
  ///
  /// A fan-out step dispatches N agent runs and every one of them publishes
  /// `AgentRunCompleted`; the listener asks whether they are ALL terminal, and
  /// the last two to finish can both answer yes. Unserialized, both reach the
  /// resume path and — with a dozen awaits between reading the step's open row
  /// and writing it completed — both harvest. An `override` node hides that;
  /// an `append` / `mergeLists` reducer does not, because the second harvest
  /// folds into the value the first just merged and the step's output carries
  /// every payload twice.
  ///
  /// Under the lock the second caller's re-read finds the row already
  /// `completed` and returns without harvesting.
  final KeyedAsyncMutex _resumeLocks = KeyedAsyncMutex();

  /// Interrupted step rows a crash-resume is holding until their sources
  /// finish, as `runId -> {stepId: stepRunId}`.
  /// A resume obeys the graph: a row is re-fired only once its sources are
  /// satisfied, and `_evaluateDownstreamLocked` does it ON THAT ROW.
  /// Re-firing every open row at once instead treats a crash as a reason to
  /// ignore the edges. A run interrupted with two steps open then starts both
  /// in the same instant and the downstream one reads state its own upstream
  /// has not written yet — on a chain like `index_code`'s
  /// `space → index → analyze` that means `analyze` resolves
  /// `{{pipeline_space_id}}` to nothing, falls back to a hidden conversation and,
  /// naming no repo scope, checks out every repo in the workspace to do it.
  /// Once per restart.
  /// The row is held rather than dropped and re-created because it carries the
  /// `spaceId` of the room the interrupted attempt already opened — reusing it
  /// is what keeps the resume from provisioning a second checkout.
  final Map<String, Map<String, String>> _resumableSteps = {};

  /// `workspaceId|templateId` keys that MAY have a `queued` run waiting.
  ///
  /// [_admitNext] runs at every terminal transition, and the overwhelming
  /// majority of templates declare no cap and can therefore never have queued
  /// anything — without this gate each of those completions would pay a
  /// database round-trip to learn that. The engine is the only writer of
  /// `queued` rows, so the set is authoritative for this process; [resumeAll]
  /// repopulates it from the database after a restart.
  final Set<String> _queuedTemplates = {};

  /// Tracks futures of in-flight `_runStep` invocations so `dispose()` can
  /// wait for them on app shutdown.
  final Set<Future<void>> _inFlight = {};

  /// Step-run ids whose body is executing in this process right now. A row in
  /// here is doing work, not waiting on a ticket or a child run, so the
  /// liveness sweep leaves it alone.
  final Set<String> _executingStepRuns = {};

  /// Drives [sweepStalledSteps]; see [startLivenessSweep].
  Timer? _sweepTimer;

  /// Starts a new pipeline run from [templateId]. Returns the persisted run.
  ///
  /// When [dedupKey] is non-null and there is already a non-terminal run with
  /// the same `(templateId, dedupKey)` tuple, this method returns null and
  /// skips the new run — used for trigger idempotency.
  ///
  /// When the template declares `maxParallelRuns` and that many runs are
  /// already in flight, the returned run is persisted `queued` and nothing
  /// executes for it yet — [_admitNext] promotes it once a sibling finishes.
  /// The cap governs starts only: [retry] re-opens an existing failed run at
  /// the operator's explicit request and is deliberately not gated by it.
  @override
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
    String? requestedByUserId,
  }) async {
    await _requireValidParentLink(
      workspaceId: workspaceId,
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
    );
    final definition = await _requireTemplate(workspaceId, templateId);
    if (!definition.isEnabled) {
      CcDomainLog.info(
        'PipelineEngine: Rejected disabled template: $templateId',
      );
      return null;
    }
    triggerPayload = await _withRequester(
      triggerPayload,
      requestedByUserId: requestedByUserId,
      parentPipelineRunId: parentPipelineRunId,
      workspaceId: workspaceId,
    );

    // Without a dedup key there's nothing to serialize.
    if (dedupKey == null) {
      return _insertAndLaunch(
        definition: definition,
        templateId: templateId,
        workspaceId: workspaceId,
        triggerEventType: triggerEventType,
        triggerPayload: triggerPayload,
        dedupKey: null,
        parentPipelineRunId: parentPipelineRunId,
        parentStepId: parentStepId,
        dryRun: dryRun,
      );
    }

    // Serialize the active-run check + insert per dedup key so two concurrent
    // triggers (e.g. a manual run racing the event trigger) can't both pass the
    // check and create duplicate runs.
    return _startLocks.run('$templateId|$workspaceId|$dedupKey', () async {
      final existing = await repository.activeForDedupKey(
        templateId: templateId,
        workspaceId: workspaceId,
        dedupKey: dedupKey,
      );
      if (existing != null) {
        CcDomainLog.info(
          'PipelineEngine: Skipping duplicate run for $templateId $dedupKey (active=${existing.id})',
        );
        return null;
      }
      return _insertAndLaunch(
        definition: definition,
        templateId: templateId,
        workspaceId: workspaceId,
        triggerEventType: triggerEventType,
        triggerPayload: triggerPayload,
        dedupKey: dedupKey,
        parentPipelineRunId: parentPipelineRunId,
        parentStepId: parentStepId,
        dryRun: dryRun,
      );
    });
  }

  /// Resumes all in-flight runs that were interrupted by a crash/restart.
  @override
  Future<void> resumeAll() => _resumeAll();

  /// Cancels a running pipeline: flips the run + step rows to cancelled and
  /// interrupts each in-flight step's live work via its registered kill
  /// callback — the same cleanup the per-step Stop button runs (`promptAgent`
  /// cancels the step's ticket and stops the dispatched agent).
  ///
  /// Cancelling the ticket here is what stops a step that is still *provisioning*
  /// (e.g. cloning its repo) when the run is cancelled from going on to dispatch
  /// its agent: the `TicketDispatcher` re-reads the ticket after provisioning and
  /// aborts the dispatch when it finds the ticket already terminal. Flipping the
  /// run terminal first means the `TicketResumeListener` (and any downstream
  /// evaluation) triggered by those ticket cancellations sees an
  /// already-terminal run and no-ops.
  @override
  Future<void> cancel(String workspaceId, String pipelineRunId) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null || run.isTerminal) {
      return;
    }

    await _finish(run, PipelineRunStatus.cancelled);
  }

  /// Resumes a suspended step by marking it completed and evaluating
  /// downstream listeners. Called by `TaskResumeListener` once all tasks
  /// associated with the step have reached terminal state.
  ///
  /// Before marking the step complete, harvests the sibling tasks' output
  /// payloads and merges them into pipeline state under the step's
  /// configured `outputKey` so downstream nodes can read the result.
  Future<void> resumeStep({
    required String pipelineRunId,
    required String stepId,
  }) => _withResumeLock(
    pipelineRunId,
    stepId,
    () => _resumeStepLocked(pipelineRunId: pipelineRunId, stepId: stepId),
  );

  /// Resumes a parent step that was suspended on a `flow.callPipeline` child
  /// run, once that child reaches a terminal state. Merges the child's final
  /// state under the parent step's `outputKey` (or fails the parent step if
  /// the child failed/cancelled, feeding the parent's retry/continueOnFail).
  Future<void> resumeChildFlow({
    required String parentRunId,
    required String parentStepId,
    required PipelineRun childRun,
  }) => _withResumeLock(
    parentRunId,
    parentStepId,
    () => _resumeChildFlowLocked(
      parentRunId: parentRunId,
      parentStepId: parentStepId,
      childRun: childRun,
    ),
  );

  /// Kills the in-flight work for [stepRunId]: invokes the registered
  /// cleanup callback (bash → SIGTERM the process; promptAgent → cancel
  /// task + kill agent PID), marks the step run row as failed and fails
  /// the parent pipeline run so the Retry button shows up.
  /// Failing the run closes out the step's still-open siblings (see
  /// [_cancelOpenSteps]) — a parallel branch cannot keep running once the run
  /// it belongs to is terminal.
  /// [workspaceId] is the workspace owning [stepRunId]; a step-run id is not
  /// routable to a workspace on its own, so a foreign id resolves to nothing.
  /// An already-terminal run does NOT short-circuit this: the row still has to
  /// be closed and its work still has to be stopped, otherwise Stop looks like
  /// a no-op on exactly the rows that need it (a branch left open by an earlier
  /// failure). Only the run-level transition is skipped in that case.
  @override
  Future<void> killStep(String workspaceId, String stepRunId) async {
    final stepRun = await repository.getStepRunById(workspaceId, stepRunId);
    if (stepRun == null || stepRun.isTerminal) {
      return;
    }

    try {
      await stepProcessRegistry.kill(stepRunId);
    } on Object catch (e, st) {
      CcDomainLog.error('PipelineEngine: kill callback threw', e, st);
    }

    final owningRun = await repository.getRun(stepRun.pipelineRunId);
    if (owningRun == null || owningRun.isTerminal) {
      stepProcessRegistry.unregister(stepRunId);
      await repository.updateStepRun(
        workspaceId,
        stepRunId,
        status: PipelineStepStatus.failed,
        errorMessage: 'Killed by user',
        finishedAt: DateTime.now(),
      );
      return;
    }

    await _failStep(
      run: owningRun,
      stepRunId: stepRunId,
      stepId: stepRun.stepId,
      error: 'Killed by user',
    );
  }

  /// Re-runs a stopped pipeline from where it stopped (same as [resumeAll]).
  ///
  /// Preserves completed steps; re-opens others in place. Accepts `failed` and
  /// `cancelled`. Takes a `maxParallelRuns` slot (queues when full). Rows are
  /// re-opened, never re-created (keeps `spaceId` / checkout); re-stamps
  /// `startedAt`.
  @override
  Future<void> retry(String workspaceId, String pipelineRunId) =>
      _retry(workspaceId, pipelineRunId);

  /// Wait for any in-flight step futures to settle. Call from
  /// `Provider.onDispose` so we don't leak work across hot reloads.
  Future<void> dispose() async {
    _sweepTimer?.cancel();
    _sweepTimer = null;
    if (_inFlight.isEmpty) {
      return;
    }
    await Future.wait(_inFlight, eagerError: false);
  }

  /// Runs [sweepStalledSteps] every [interval] until [dispose]. Idempotent.
  ///
  /// [resumeAll] applies the same backstop once at boot, but a server that
  /// stays up for weeks would otherwise never fail a step whose agent
  /// neither completed its ticket nor ended its run.
  void startLivenessSweep({Duration interval = const Duration(minutes: 15)}) {
    _sweepTimer ??= Timer.periodic(interval, (_) {
      _track(
        sweepStalledSteps().catchError((Object e, StackTrace st) {
          CcDomainLog.error('PipelineEngine: liveness sweep failed', e, st);
        }),
      );
    });
  }

  /// Fails every step that has waited longer than [suspendedStepTimeout] on
  /// work outside this process — a dispatched agent's ticket — so its run is
  /// freed.
  ///
  /// Exempt: a step whose body is executing here (it is working, and its node
  /// timeout governs it), an approval gate or human gate (waiting days for a
  /// person is its job), and a sub-pipeline call (the child run is swept on
  /// its own). Waiting rows are kept `running` so the canvas doesn't say
  /// "suspended" while an agent works, so both statuses are swept.
  Future<void> sweepStalledSteps() async {
    final now = DateTime.now();
    for (final run in await repository.nonTerminalRuns()) {
      if (run.status != PipelineRunStatus.running) {
        continue;
      }
      final definition = await _definitionFor(run);
      if (definition == null) {
        continue;
      }
      for (final sr in await repository.stepRunsForPipeline(run.id)) {
        if (sr.status != PipelineStepStatus.running &&
            sr.status != PipelineStepStatus.suspended) {
          continue;
        }
        if (_executingStepRuns.contains(sr.id) ||
            now.difference(sr.startedAt) <= suspendedStepTimeout) {
          continue;
        }
        final stepDef = definition.step(sr.stepId);
        if (stepDef == null ||
            stepDef.config.extras['awaitApproval'] == true ||
            stepDef.bodyKey == BuiltInBodyKeys.humanGate ||
            stepDef.bodyKey == BuiltInBodyKeys.callFlow) {
          continue;
        }
        final latest = await repository.getRun(run.id);
        if (latest == null || latest.isTerminal) {
          break;
        }
        await _failStep(
          run: latest,
          stepRunId: sr.id,
          stepId: sr.stepId,
          error:
              'Waited beyond ${suspendedStepTimeout.inHours}h without its '
              'tickets completing — failed by the liveness backstop.',
        );
        // The run is failed now and its other open rows closed.
        break;
      }
    }
  }

  // ── Step execution ──────────────────────────────────────────────────

  void _track(Future<void> f) {
    _inFlight.add(f);
    f.whenComplete(() => _inFlight.remove(f));
  }

  /// Drops the in-memory step-count bookkeeping for a finished run.
  void _clearRunBookkeeping(String runId) {
    _stepCounts.remove(runId);
    // A terminal run re-fires nothing; `_cancelOpenSteps` closes whatever rows
    // were still being held.
    _resumableSteps.remove(runId);
  }
}

const _uuidGen = Uuid();
String _uuid() => _uuidGen.v4();
