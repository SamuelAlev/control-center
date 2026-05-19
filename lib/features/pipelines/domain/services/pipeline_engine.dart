import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/pipeline_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart' show StepRetryPolicy;
import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart' show StepResult;
import 'package:control_center/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:control_center/features/pipelines/domain/ports/schema_validator_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/downstream_planner.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/services/state_reducer.dart';
import 'package:control_center/features/pipelines/domain/services/step_process_registry.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:uuid/uuid.dart';

/// Reserved state-key prefix recording which branch a router selected, so
/// downstream evaluation can gate conditional edges. One key per router.
const String kRouteStateKeyPrefix = '__route__';

/// Reserved state key holding a map of `stepId -> error message` for steps
/// that failed but were configured `continueOnFail`.
const String kStepErrorsKey = '_stepErrors';

/// Orchestrates pipeline execution: starts runs, schedules steps, persists
/// state, and resumes in-flight runs after app restart.
class PipelineEngine implements PipelineEnginePort {
  /// Creates a [PipelineEngine].
  PipelineEngine({
    required this.bodies,
    required this.templates,
    required this.repository,
    required this.ticketRepository,
    required this.stepProcessRegistry,
    required this.eventBus,
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
  /// a terminal state) before [resumeAll] fails it to free the run. A liveness
  /// backstop for a dispatched agent that neither completes its ticket nor ends
  /// its run.
  final Duration suspendedStepTimeout;

  /// Bounds concurrent body execution so wide fan-outs (forEach / teamDispatch)
  /// don't dispatch unbounded work at once.
  final _Semaphore _slots;

  /// In-memory retry-attempt counts keyed by `$runId/$stepId`.
  final Map<String, int> _attempts = {};

  /// In-memory executed-step counts per run (loop/recursion guard).
  final Map<String, int> _stepCounts = {};

  /// Code-registered step body closures (keyed by `bodyKey`).
  final PipelineBodyRegistry bodies;

  /// DB-backed template repository — source of truth for pipeline graphs.
  final PipelineTemplateRepository templates;

  /// Pipeline run persistence.
  final PipelineRunRepository repository;

  /// Used during step resume to collect upstream ticket outputs and feed
  /// them into pipeline state under the resumed step's `outputKey`.
  final TicketRepository ticketRepository;

  /// In-memory kill-callback registry. Bodies register here while their
  /// real work (subprocess, dispatched agent) is live so [killStep] can
  /// interrupt them from the UI.
  final StepProcessRegistry stepProcessRegistry;

  final DomainEventBus eventBus;

  /// Per-run async lock chain that serializes state merges so two parallel
  /// steps can't lose each other's writes.
  final Map<String, Future<void>> _stateLocks = {};

  /// Per-run lock chain that serializes downstream evaluation. Without it, two
  /// steps completing in parallel could both read the step-run set before
  /// either writes, then both insert a `skipped` row for the same bypassed
  /// branch (or both schedule the same ready step). Mirrors [_stateLocks].
  final Map<String, Future<void>> _evalLocks = {};

  /// Serializes [start] per `(templateId, workspaceId, dedupKey)` so two
  /// concurrent triggers carrying the same dedup key can't both pass the
  /// active-run check and insert duplicate runs (a check-then-insert TOCTOU).
  /// Only engaged when `dedupKey != null`.
  final Map<String, Future<void>> _startLocks = {};

  /// Tracks futures of in-flight `_runStep` invocations so `dispose()` can
  /// wait for them on app shutdown.
  final Set<Future<void>> _inFlight = {};

  /// Starts a new pipeline run from [templateId]. Returns the persisted run.
  ///
  /// When [dedupKey] is non-null and there is already a non-terminal run with
  /// the same `(templateId, dedupKey)` tuple, this method returns null and
  /// skips the new run — used for trigger idempotency.
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
  }) async {
    final definition = await _requireTemplate(workspaceId, templateId);
    if (!definition.isEnabled) {
      AppLog.i(
        'PipelineEngine',
        'Rejected disabled template: $templateId',
      );
      return null;
    }

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
    final lockKey = '$templateId|$workspaceId|$dedupKey';
    final prev = _startLocks[lockKey] ?? Future<void>.value();
    final gate = Completer<void>();
    _startLocks[lockKey] = gate.future;
    try {
      await prev;
      final existing = await repository.activeForDedupKey(
        templateId: templateId,
        workspaceId: workspaceId,
        dedupKey: dedupKey,
      );
      if (existing != null) {
        AppLog.i(
          'PipelineEngine',
          'Skipping duplicate run for $templateId $dedupKey (active=${existing.id})',
        );
        return null;
      }
      return await _insertAndLaunch(
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
    } finally {
      gate.complete();
      if (_startLocks[lockKey] == gate.future) {
        _startLocks.remove(lockKey);
      }
    }
  }

  /// Builds the run row, persists it, publishes [PipelineRunStarted], and kicks
  /// off the entry step. Shared by the dedup and non-dedup paths of [start].
  Future<PipelineRun> _insertAndLaunch({
    required PipelineDefinition definition,
    required String templateId,
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  }) async {
    final run = PipelineRun(
      id: _uuid(),
      templateId: templateId,
      workspaceId: workspaceId,
      status: PipelineRunStatus.pending,
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
      dedupKey: dedupKey,
      startedAt: DateTime.now(),
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      templateVersion: definition.version,
      dryRun: dryRun,
    );

    await repository.insertRun(run);
    eventBus.publish(PipelineRunStarted(
      pipelineRunId: run.id,
      templateId: templateId,
      occurredAt: DateTime.now(),
    ));

    _track(_runStep(
      run: run,
      definition: definition,
      stepDef: definition.entryStep,
    ));
    return run;
  }

  /// Resumes all in-flight runs that were interrupted by a crash/restart.
  Future<void> resumeAll() async {
    final runs = await repository.nonTerminalRuns();
    if (runs.isEmpty) return;

    AppLog.i(
      'PipelineEngine',
      'Resuming ${runs.length} in-flight pipeline(s)',
    );

    for (final run in runs) {
      final workspaceId = run.workspaceId;
      final definition = await templates.getById(workspaceId, run.templateId);
      if (definition == null) {
        AppLog.w(
          'PipelineEngine',
          'Cannot resume run ${run.id}: template ${run.templateId} '
          'missing for workspace $workspaceId',
        );
        continue;
      }
      if (definition.version != run.templateVersion) {
        AppLog.w(
          'PipelineEngine',
          'Run ${run.id} pinned template ${run.templateId} v'
          '${run.templateVersion} but the live template is now v'
          '${definition.version}; resuming against the live graph.',
        );
      }
      final stepRuns = await repository.stepRunsForPipeline(run.id);
      final completedStepIds = <String>{};
      final pendingOrSuspended = <PipelineStepRun>[];

      for (final sr in stepRuns) {
        if (sr.status == PipelineStepStatus.completed ||
            sr.status == PipelineStepStatus.skipped) {
          completedStepIds.add(sr.stepId);
        } else if (sr.status == PipelineStepStatus.pending ||
            sr.status == PipelineStepStatus.suspended ||
            sr.status == PipelineStepStatus.running) {
          pendingOrSuspended.add(sr);
        }
      }

      final now = DateTime.now();
      for (final sr in pendingOrSuspended) {
        final stepDef = definition.step(sr.stepId);
        if (stepDef == null) continue;
        // Liveness backstop: a step suspended longer than the timeout is waiting
        // on tickets that will never complete (e.g. an agent that neither
        // completed its ticket nor ended its run). Fail it rather than re-run /
        // hang the run forever.
        if (sr.status == PipelineStepStatus.suspended &&
            now.difference(sr.startedAt) > suspendedStepTimeout) {
          await _failStep(
            run: run,
            stepRunId: sr.id,
            stepId: sr.stepId,
            error: 'Suspended beyond ${suspendedStepTimeout.inHours}h without '
                'its tickets completing — failed by the liveness backstop.',
          );
          continue;
        }
        // A step explicitly marked non-idempotent that was already mid-flight
        // (running/suspended) might have completed its side effect (e.g.
        // `gh pr merge`) before the crash. Re-running could double-apply it,
        // so fail it instead and let the user retry deliberately.
        final nonIdempotent = stepDef.config.extras['idempotent'] == false;
        final alreadyStarted = sr.status == PipelineStepStatus.running ||
            sr.status == PipelineStepStatus.suspended;
        if (nonIdempotent && alreadyStarted) {
          await _failStep(
            run: run,
            stepRunId: sr.id,
            stepId: sr.stepId,
            error: 'Interrupted non-idempotent step — not auto-re-run on '
                'resume. Retry the run to re-execute it deliberately.',
          );
          continue;
        }
        _track(_runStep(
          run: run,
          definition: definition,
          stepDef: stepDef,
          existingStepRunId: sr.id,
        ));
      }

      await _evaluateDownstream(
        run: run,
        definition: definition,
        completedStepIds: completedStepIds,
      );
    }
  }

  /// Cancels a running pipeline: flips the run + step rows to cancelled and
  /// interrupts each in-flight step's live work via its registered kill
  /// callback — the same cleanup the per-step Stop button runs (`promptAgent`
  /// cancels the step's ticket and stops the dispatched agent).
  ///
  /// Cancelling the ticket here is what stops a step that is still *provisioning*
  /// (e.g. cloning its repo) when the run is cancelled from going on to dispatch
  /// its agent: the [TicketDispatcher] re-reads the ticket after provisioning and
  /// aborts the dispatch when it finds the ticket already terminal. Flipping the
  /// run terminal first means the [TicketResumeListener] (and any downstream
  /// evaluation) triggered by those ticket cancellations sees an
  /// already-terminal run and no-ops.
  Future<void> cancel(String pipelineRunId) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null || run.isTerminal) return;

    final updated = run.copyWith(
      status: PipelineRunStatus.cancelled,
      finishedAt: DateTime.now(),
    );
    await repository.updateRun(updated);

    final steps = await repository.stepRunsForPipeline(pipelineRunId);
    for (final sr in steps) {
      if (sr.status == PipelineStepStatus.running ||
          sr.status == PipelineStepStatus.suspended ||
          sr.status == PipelineStepStatus.pending) {
        // Interrupt the step's live work (cancel its ticket, stop its agent).
        // No-op when nothing is registered yet (the step had not started its
        // work) — the ticket guard in TicketDispatcher still covers that case.
        try {
          await stepProcessRegistry.kill(sr.id);
        } on Object catch (e, st) {
          AppLog.e('PipelineEngine', 'cancel: kill callback threw for ${sr.id}',
              e, st);
        }
        await repository.updateStepRun(
          sr.id,
          status: PipelineStepStatus.cancelled,
          finishedAt: DateTime.now(),
        );
      }
    }
  }

  /// Resumes a suspended step by marking it completed and evaluating
  /// downstream listeners. Called by [TaskResumeListener] once all tasks
  /// associated with the step have reached terminal state.
  ///
  /// Before marking the step complete, harvests the sibling tasks' output
  /// payloads and merges them into pipeline state under the step's
  /// configured `outputKey` so downstream nodes can read the result.
  Future<void> resumeStep({
    required String pipelineRunId,
    required String stepId,
  }) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null || run.isTerminal) return;

    final stepRuns = await repository.stepRunsForPipeline(pipelineRunId);
    // Rows waiting on a dispatched task are kept in `running` so the UI
    // doesn't say "suspended" while the agent is actively working. Some
    // legacy / non-task suspensions still use `suspended`; accept both.
    final suspended = stepRuns
        .where(
          (sr) =>
              sr.stepId == stepId &&
              (sr.status == PipelineStepStatus.running ||
                  sr.status == PipelineStepStatus.suspended),
        )
        .firstOrNull;
    if (suspended == null) return;

    final workspaceId = run.workspaceId;
    final definition = await templates.getById(workspaceId, run.templateId);
    final stepDef = definition?.step(stepId);
    final outputKey = stepDef?.config.outputKey;
    if (outputKey != null && outputKey.isNotEmpty && stepDef != null) {
      try {
        final tickets = await ticketRepository.forPipelineStep(
          workspaceId,
          pipelineRunId,
          stepId,
        );
        if (tickets.isNotEmpty) {
          final payloads = tickets
              .where((t) => t.outputJson != null)
              .map((t) => t.outputJson!)
              .toList();
          final value = payloads.length == 1
              ? (payloads.single['result'] ?? payloads.single)
              : payloads;

          // Enforce the node's output contract on the (least-trustworthy)
          // agent-produced output before it flows downstream.
          final violations = _validateOutput(stepDef, {outputKey: value});
          if (violations.isNotEmpty && definition != null) {
            await _handleStepFailure(
              run: run,
              definition: definition,
              stepDef: stepDef,
              stepRunId: suspended.id,
              error: 'Output schema violation: ${violations.join('; ')}',
            );
            return;
          }

          await _mergeState(pipelineRunId, {outputKey: value},
              producer: stepDef);
        }
      } on Object catch (e, st) {
        AppLog.e('PipelineEngine', 'output harvest failed', e, st);
      }
    }

    stepProcessRegistry.unregister(suspended.id);
    await repository.updateStepRun(
      suspended.id,
      status: PipelineStepStatus.completed,
      finishedAt: DateTime.now(),
    );
    eventBus.publish(PipelineStepCompleted(
      pipelineRunId: pipelineRunId,
      stepRunId: suspended.id,
      stepId: stepId,
      occurredAt: DateTime.now(),
    ));

    if (definition == null) return;
    final latest = await repository.getRun(pipelineRunId) ?? run;
    await _evaluateDownstream(
      run: latest,
      definition: definition,
      completedStepIds: {stepId},
    );
  }

  /// Resumes a parent step that was suspended on a `flow.callPipeline` child
  /// run, once that child reaches a terminal state. Merges the child's final
  /// state under the parent step's `outputKey` (or fails the parent step if
  /// the child failed/cancelled, feeding the parent's retry/continueOnFail).
  Future<void> resumeChildFlow({
    required String parentRunId,
    required String parentStepId,
    required PipelineRun childRun,
  }) async {
    final run = await repository.getRun(parentRunId);
    if (run == null || run.isTerminal) return;

    final stepRuns = await repository.stepRunsForPipeline(parentRunId);
    final suspended = stepRuns
        .where((sr) =>
            sr.stepId == parentStepId &&
            (sr.status == PipelineStepStatus.running ||
                sr.status == PipelineStepStatus.suspended))
        .firstOrNull;
    if (suspended == null) return;

    final workspaceId = run.workspaceId;
    final definition = await templates.getById(workspaceId, run.templateId);
    final stepDef = definition?.step(parentStepId);

    if (childRun.status != PipelineRunStatus.completed) {
      if (definition != null && stepDef != null) {
        await _handleStepFailure(
          run: run,
          definition: definition,
          stepDef: stepDef,
          stepRunId: suspended.id,
          error: 'Sub-pipeline "${childRun.templateId}" '
              '${childRun.status.name}',
        );
      }
      return;
    }

    final outputKey = stepDef?.config.outputKey;
    if (outputKey != null && outputKey.isNotEmpty && stepDef != null) {
      await _mergeState(parentRunId, {outputKey: childRun.state},
          producer: stepDef);
    }

    stepProcessRegistry.unregister(suspended.id);
    await repository.updateStepRun(
      suspended.id,
      status: PipelineStepStatus.completed,
      finishedAt: DateTime.now(),
    );
    eventBus.publish(PipelineStepCompleted(
      pipelineRunId: parentRunId,
      stepRunId: suspended.id,
      stepId: parentStepId,
      occurredAt: DateTime.now(),
    ));

    if (definition == null) return;
    final latest = await repository.getRun(parentRunId) ?? run;
    await _evaluateDownstream(
      run: latest,
      definition: definition,
      completedStepIds: {parentStepId},
    );
  }

  /// Kills the in-flight work for [stepRunId]: invokes the registered
  /// cleanup callback (bash → SIGTERM the process; promptAgent → cancel
  /// task + kill agent PID), marks the step run row as failed, and fails
  /// the parent pipeline run so the Retry button shows up.
  Future<void> killStep(String stepRunId) async {
    final stepRun = await repository.getStepRunById(stepRunId);
    if (stepRun == null || stepRun.isTerminal) return;

    final owningRun = await repository.getRun(stepRun.pipelineRunId);
    if (owningRun == null || owningRun.isTerminal) return;

    try {
      await stepProcessRegistry.kill(stepRunId);
    } on Object catch (e, st) {
      AppLog.e('PipelineEngine', 'kill callback threw', e, st);
    }

    await _failStep(
      run: owningRun,
      stepRunId: stepRunId,
      stepId: stepRun.stepId,
      error: 'Killed by user',
    );
  }

  /// Retries a failed pipeline run from where it stopped. Completed step
  /// runs (and their outputs) are preserved; failed step runs are deleted
  /// so they re-execute. The run flips back to `running` and downstream
  /// listeners are re-evaluated against the currently-completed set.
  Future<void> retry(String pipelineRunId) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null) return;
    if (run.status != PipelineRunStatus.failed) return;

    final stepRuns = await repository.stepRunsForPipeline(pipelineRunId);
    final completed = <String>{};
    for (final sr in stepRuns) {
      if (sr.status == PipelineStepStatus.completed ||
          sr.status == PipelineStepStatus.skipped) {
        completed.add(sr.stepId);
      } else {
        // Drop failed / cancelled / pending / running / suspended rows so
        // _evaluateDownstream re-fires them.
        await repository.deleteStepRun(sr.id);
      }
    }

    final reset = PipelineRun(
      id: run.id,
      templateId: run.templateId,
      workspaceId: run.workspaceId,
      status: PipelineRunStatus.running,
      state: Map<String, dynamic>.from(run.state),
      triggerEventType: run.triggerEventType,
      triggerPayload: run.triggerPayload,
      dedupKey: run.dedupKey,
      startedAt: run.startedAt,
    );
    await repository.updateRun(reset);

    final workspaceId = run.workspaceId;
    final definition = await templates.getById(workspaceId, run.templateId);
    if (definition == null) return;

    if (completed.isEmpty) {
      // Nothing succeeded yet — kick the start step over again.
      _track(_runStep(
        run: reset,
        definition: definition,
        stepDef: definition.entryStep,
      ));
      return;
    }

    await _evaluateDownstream(
      run: reset,
      definition: definition,
      completedStepIds: completed,
    );
  }

  /// Wait for any in-flight step futures to settle. Call from
  /// [Provider.onDispose] so we don't leak work across hot reloads.
  Future<void> dispose() async {
    if (_inFlight.isEmpty) return;
    await Future.wait(_inFlight, eagerError: false);
  }

  // ── Step execution ──────────────────────────────────────────────────

  Future<PipelineDefinition> _requireTemplate(
    String workspaceId,
    String templateId,
  ) async {
    final def = await templates.getById(workspaceId, templateId);
    if (def == null) {
      throw StateError(
        'Pipeline template "$templateId" not found for workspace $workspaceId',
      );
    }
    // Defensive config check: every work-performing step must name a registered
    // body. Bodies are wired once at startup, so a miss is a template authoring
    // error, not a runtime condition — warn (don't fail) so it surfaces in logs
    // instead of silently no-op'ing at execution time. Trigger/terminal steps
    // are sentinels handled directly by the scheduler.
    for (final step in def.steps) {
      if (step.kind == StepKind.trigger || step.kind == StepKind.terminal) {
        continue;
      }
      if (!bodies.hasBody(step.bodyKey)) {
        AppLog.w(
          'PipelineEngine',
          'Template "$templateId" step "${step.id}" references unregistered '
          'body "${step.bodyKey}" — it will not execute.',
        );
      }
    }
    return def;
  }

  Future<void> _runStep({
    required PipelineRun run,
    required PipelineDefinition definition,
    required PipelineStepDefinition stepDef,
    String? existingStepRunId,
  }) async {
    // Terminal sentinel steps never have a body — they're markers consumed
    // by [_evaluateDownstream] to detect pipeline completion.
    if (stepDef.kind == StepKind.terminal) return;

    // Loop / recursion safety backstop (in-memory per process lifetime).
    final execCount = (_stepCounts[run.id] ?? 0) + 1;
    _stepCounts[run.id] = execCount;
    if (execCount > maxStepsPerRun) {
      final latest = await repository.getRun(run.id) ?? run;
      await _failRun(
        latest,
        'Exceeded max step executions ($maxStepsPerRun) — possible loop.',
      );
      return;
    }

    final now = DateTime.now();
    final stepRunId = existingStepRunId ?? _uuid();
    final config = stepDef.config;

    var current = run;
    if (current.status == PipelineRunStatus.pending) {
      current = current.copyWith(status: PipelineRunStatus.running);
      await repository.updateRun(current);
    }

    if (existingStepRunId == null) {
      await repository.insertStepRun(PipelineStepRun(
        id: stepRunId,
        pipelineRunId: current.id,
        stepId: stepDef.id,
        status: PipelineStepStatus.running,
        startedAt: now,
      ));
    } else {
      await repository.updateStepRun(
        existingStepRunId,
        status: PipelineStepStatus.running,
      );
    }

    eventBus.publish(PipelineStepStarted(
      pipelineRunId: current.id,
      stepRunId: stepRunId,
      stepId: stepDef.id,
      occurredAt: now,
    ));

    final ctx = PipelineContext(
      pipelineRunId: current.id,
      templateId: current.templateId,
      stepId: stepDef.id,
      stepRunId: stepRunId,
      workspaceId: current.workspaceId,
      state: Map<String, dynamic>.from(current.state),
      triggerPayload: current.triggerPayload,
      dryRun: current.dryRun,
    );

    // Snapshot the input so the run-detail card can show what the body saw —
    // rendered prompt, resolved inputKeys values, and the trigger payload.
    await repository.updateStepRun(
      stepRunId,
      inputJson: _encodeInputSnapshot(stepDef, ctx),
    );

    // ── Attempt loop: retry synchronous failures per the node policy ────
    final policy = config.retryPolicy;
    final maxAttempts = policy?.maxAttempts ?? 1;
    final attemptKey = '${current.id}/${stepDef.id}';
    StepResult? result;
    String lastError = 'unknown error';
    String? lastStack;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _attempts[attemptKey] = attempt;
      try {
        final bodyFn = bodies.body(stepDef.bodyKey);
        final r = await _invokeBody(bodyFn, ctx, config.timeoutMs, stepRunId);

        // Cancelled mid-body?
        final fresh = await repository.getRun(current.id);
        if (fresh == null || fresh.status == PipelineRunStatus.cancelled) {
          await repository.updateStepRun(
            stepRunId,
            status: PipelineStepStatus.cancelled,
            finishedAt: DateTime.now(),
          );
          return;
        }

        if (r.isFailed) {
          lastError = r.errorMessage ?? 'step failed';
          if (attempt < maxAttempts) {
            await _backoff(policy, attempt);
            continue;
          }
          await _handleStepFailure(
            run: fresh,
            definition: definition,
            stepDef: stepDef,
            stepRunId: stepRunId,
            error: lastError,
          );
          return;
        }

        // Validate immediate (non-suspended) output against the node schema.
        if (!r.isSuspended) {
          final violations = _validateOutput(stepDef, r.mutatedState);
          if (violations.isNotEmpty) {
            lastError = 'Output schema violation: ${violations.join('; ')}';
            if (attempt < maxAttempts) {
              await _backoff(policy, attempt);
              continue;
            }
            await _handleStepFailure(
              run: fresh,
              definition: definition,
              stepDef: stepDef,
              stepRunId: stepRunId,
              error: lastError,
            );
            return;
          }
        }

        result = r;
        break;
      } on Object catch (e, st) {
        lastError = e.toString();
        lastStack = st.toString();
        AppLog.e(
          'PipelineEngine',
          'Step ${stepDef.id} attempt $attempt/$maxAttempts failed',
          e,
          st,
        );
        if (attempt < maxAttempts) {
          await _backoff(policy, attempt);
          continue;
        }
        final latest = await repository.getRun(current.id) ?? current;
        await _handleStepFailure(
          run: latest,
          definition: definition,
          stepDef: stepDef,
          stepRunId: stepRunId,
          error: lastError,
          stackTrace: lastStack,
        );
        return;
      }
    }

    if (result == null) return; // failure already handled in the loop
    final r = result;

    // Merge state (reducer-aware) plus the router decision, if any.
    final mutations = <String, dynamic>{...?r.mutatedState};
    if (stepDef.kind == StepKind.router && r.nextRouterKey != null) {
      mutations['$kRouteStateKeyPrefix${stepDef.id}'] = r.nextRouterKey;
    }
    if (mutations.isNotEmpty) {
      await _mergeState(current.id, mutations, producer: stepDef);
    }

    if (r.isSuspended) {
      // The body dispatched work to a task and is waiting for it to settle.
      // The row stays `running` so the UI doesn't say "suspended" for a node
      // that's actively working. TicketResumeListener + [resumeStep] pick it up.
      await repository.updateStepRun(
        stepRunId,
        status: PipelineStepStatus.running,
        outputJson: mutations.isEmpty ? null : jsonEncode(mutations),
      );
      return;
    }

    stepProcessRegistry.unregister(stepRunId);
    await repository.updateStepRun(
      stepRunId,
      status: PipelineStepStatus.completed,
      outputJson: mutations.isEmpty ? null : jsonEncode(mutations),
      finishedAt: DateTime.now(),
    );
    eventBus.publish(PipelineStepCompleted(
      pipelineRunId: current.id,
      stepRunId: stepRunId,
      stepId: stepDef.id,
      occurredAt: DateTime.now(),
    ));

    if (r.isTerminal) {
      final fresh = await repository.getRun(current.id) ?? current;
      await _completeRun(fresh);
      return;
    }

    // Re-read run so downstream evaluation sees the latest state (incl. route).
    final latest = await repository.getRun(current.id) ?? current;
    await _evaluateDownstream(
      run: latest,
      definition: definition,
      completedStepIds: {stepDef.id},
    );
  }

  /// Runs a body under the concurrency cap, applying an optional timeout. On
  /// timeout the step's registered kill hook is invoked before rethrowing.
  Future<StepResult> _invokeBody(
    StepBodyFn bodyFn,
    PipelineContext ctx,
    int? timeoutMs,
    String stepRunId,
  ) async {
    await _slots.acquire();
    try {
      final future = bodyFn(ctx);
      if (timeoutMs == null) return await future;
      try {
        return await future.timeout(Duration(milliseconds: timeoutMs));
      } on TimeoutException {
        try {
          await stepProcessRegistry.kill(stepRunId);
        } on Object catch (_) {/* best effort */}
        rethrow;
      }
    } finally {
      _slots.release();
    }
  }

  Future<void> _backoff(StepRetryPolicy? policy, int attempt) async {
    if (policy == null) return;
    await Future<void>.delayed(policy.delayForAttempt(attempt));
  }

  /// Validates the value a node wrote under its `outputKey` against the node's
  /// declared `outputSchema`. Returns an empty list when there is no schema,
  /// no validator bound, or the value is valid.
  List<String> _validateOutput(
    PipelineStepDefinition stepDef,
    Map<String, dynamic>? mutatedState,
  ) {
    final schema = stepDef.config.outputSchema;
    final key = stepDef.config.outputKey;
    if (schema == null || schemaValidator == null || key == null) return const [];
    return schemaValidator!.validate(mutatedState?[key], schema);
  }

  /// Terminal failure of a step: either fail the whole run, or — when the node
  /// is `continueOnFail` — stash the error and let downstream proceed.
  Future<void> _handleStepFailure({
    required PipelineRun run,
    required PipelineDefinition definition,
    required PipelineStepDefinition stepDef,
    required String stepRunId,
    required String error,
    String? stackTrace,
  }) async {
    if (!stepDef.config.continueOnFail) {
      await _failStep(
        run: run,
        stepRunId: stepRunId,
        stepId: stepDef.id,
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    // continueOnFail: record the error, mark the step completed (so downstream
    // gated on it still fires), and keep the run alive.
    stepProcessRegistry.unregister(stepRunId);
    final fresh = await repository.getRun(run.id) ?? run;
    final errors = <String, dynamic>{
      ...?(fresh.state[kStepErrorsKey] as Map?)?.cast<String, dynamic>(),
      stepDef.id: error,
    };
    await _mergeState(run.id, {kStepErrorsKey: errors});
    await repository.updateStepRun(
      stepRunId,
      status: PipelineStepStatus.completed,
      outputJson: jsonEncode({'error': error, 'continuedOnFail': true}),
      finishedAt: DateTime.now(),
    );
    eventBus.publish(PipelineStepFailed(
      pipelineRunId: run.id,
      stepRunId: stepRunId,
      stepId: stepDef.id,
      errorMessage: error,
      occurredAt: DateTime.now(),
    ));
    final latest = await repository.getRun(run.id) ?? run;
    await _evaluateDownstream(
      run: latest,
      definition: definition,
      completedStepIds: {stepDef.id},
    );
  }

  /// Fails an entire run without attributing the failure to a specific step
  /// run (used by the loop/recursion guard).
  Future<void> _failRun(PipelineRun run, String error) async {
    if (run.isTerminal) return;
    final updated = run.copyWith(
      status: PipelineRunStatus.failed,
      finishedAt: DateTime.now(),
      errorMessage: error,
    );
    await repository.updateRun(updated);
    eventBus.publish(PipelineRunFailed(
      pipelineRunId: run.id,
      templateId: run.templateId,
      errorMessage: error,
      occurredAt: DateTime.now(),
    ));
  }

  Future<void> _evaluateDownstream({
    required PipelineRun run,
    required PipelineDefinition definition,
    required Set<String> completedStepIds,
  }) async {
    // Serialize per run so concurrent completions can't race the
    // read-modify-write below (duplicate skip rows / double-scheduled steps).
    final prev = _evalLocks[run.id] ?? Future.value();
    final completer = Completer<void>();
    _evalLocks[run.id] = completer.future;
    try {
      await prev;
      await _evaluateDownstreamLocked(
        run: run,
        definition: definition,
        completedStepIds: completedStepIds,
      );
    } finally {
      completer.complete();
      if (_evalLocks[run.id] == completer.future) {
        _evalLocks.remove(run.id);
      }
    }
  }

  Future<void> _evaluateDownstreamLocked({
    required PipelineRun run,
    required PipelineDefinition definition,
    required Set<String> completedStepIds,
  }) async {
    // Re-read under the lock: a queued evaluation may have completed the run or
    // recorded more steps since this call was scheduled.
    final current = await repository.getRun(run.id) ?? run;
    if (current.isTerminal) return;

    final allStepRuns = await repository.stepRunsForPipeline(current.id);
    final completed = <String>{...completedStepIds};
    final skipped = <String>{};
    final existing = <String>{};
    for (final sr in allStepRuns) {
      existing.add(sr.stepId);
      if (sr.status == PipelineStepStatus.completed) {
        completed.add(sr.stepId);
      } else if (sr.status == PipelineStepStatus.skipped) {
        skipped.add(sr.stepId);
      }
    }

    // Which branch each router chose, recorded as reserved state keys.
    final chosenRoutes = <String, String>{};
    current.state.forEach((k, v) {
      if (k.startsWith(kRouteStateKeyPrefix) && v is String) {
        chosenRoutes[k.substring(kRouteStateKeyPrefix.length)] = v;
      }
    });

    final plan = planDownstream(
      definition: definition,
      completed: completed,
      skipped: skipped,
      existing: existing,
      chosenRoutes: chosenRoutes,
    );

    // Record branches a router bypassed (and their now-unreachable descendants)
    // as skipped, so joins/terminals downstream resolve instead of hanging and
    // the timeline shows them as deliberately skipped rather than missing.
    for (final stepId in plan.toSkip) {
      final now = DateTime.now();
      await repository.insertStepRun(PipelineStepRun(
        id: _uuid(),
        pipelineRunId: current.id,
        stepId: stepId,
        status: PipelineStepStatus.skipped,
        startedAt: now,
        finishedAt: now,
      ));
    }

    // Pipeline completes when ANY terminal sentinel has one of its incoming
    // branches fully completed (OR across a convergent terminal's triggers,
    // so router branches that each lead to the same terminal still finish).
    if (plan.terminalReached && !current.isTerminal) {
      await _completeRun(current);
      return;
    }

    for (final stepId in plan.toRun) {
      final stepDef = definition.step(stepId);
      if (stepDef == null) continue;
      _track(_runStep(run: current, definition: definition, stepDef: stepDef));
    }
  }

  // ── State + status helpers ──────────────────────────────────────────

  /// Serializes state merges per-run so parallel steps don't lose writes.
  ///
  /// When [producer] declares a reducer and writes its `outputKey`, the
  /// reducer combines the existing and incoming values for that key instead of
  /// overwriting — so parallel branches / forEach iterations writing the same
  /// key don't clobber each other. All other keys overwrite.
  Future<void> _mergeState(
    String runId,
    Map<String, dynamic> mutations, {
    PipelineStepDefinition? producer,
  }) async {
    final prev = _stateLocks[runId] ?? Future.value();
    final completer = Completer<void>();
    _stateLocks[runId] = completer.future;
    try {
      await prev;
      final fresh = await repository.getRun(runId);
      if (fresh == null) return;
      final reducerKey = producer?.config.outputKey;
      final reducerName = producer?.config.reducer;
      final useReducer = reducerKey != null &&
          reducerName != null &&
          reducerName.isNotEmpty &&
          reducerName != 'override';
      final merged = <String, dynamic>{...fresh.state};
      for (final entry in mutations.entries) {
        if (useReducer && entry.key == reducerKey) {
          merged[entry.key] =
              reducers.apply(reducerName, merged[entry.key], entry.value);
        } else {
          merged[entry.key] = entry.value;
        }
      }
      await repository.updateRunState(runId, merged);
    } finally {
      completer.complete();
      if (_stateLocks[runId] == completer.future) {
        _stateLocks.remove(runId);
      }
    }
  }

  Future<void> _completeRun(PipelineRun run) async {
    final updated = run.copyWith(
      status: PipelineRunStatus.completed,
      finishedAt: DateTime.now(),
    );
    await repository.updateRun(updated);
    _clearRunBookkeeping(run.id);
    eventBus.publish(PipelineRunCompleted(
      pipelineRunId: run.id,
      templateId: run.templateId,
      occurredAt: DateTime.now(),
    ));
  }

  Future<void> _failStep({
    required PipelineRun run,
    required String stepRunId,
    required String stepId,
    required String error,
    String? stackTrace,
  }) async {
    stepProcessRegistry.unregister(stepRunId);
    await repository.updateStepRun(
      stepRunId,
      status: PipelineStepStatus.failed,
      errorMessage: error,
      errorStackTrace: stackTrace,
      finishedAt: DateTime.now(),
    );
    eventBus.publish(PipelineStepFailed(
      pipelineRunId: run.id,
      stepRunId: stepRunId,
      stepId: stepId,
      errorMessage: error,
      occurredAt: DateTime.now(),
    ));

    final updated = run.copyWith(
      status: PipelineRunStatus.failed,
      finishedAt: DateTime.now(),
      errorMessage: error,
      errorStackTrace: stackTrace,
    );
    await repository.updateRun(updated);
    _clearRunBookkeeping(run.id);
    eventBus.publish(PipelineRunFailed(
      pipelineRunId: run.id,
      templateId: run.templateId,
      errorMessage: error,
      occurredAt: DateTime.now(),
    ));
  }

  void _track(Future<void> f) {
    _inFlight.add(f);
    f.whenComplete(() => _inFlight.remove(f));
  }

  /// Snapshots the body's input — config metadata, the rendered prompt with
  /// `{{key}}` placeholders substituted, the values of the keys listed in
  /// `inputKeys`, and the trigger payload. Stored on the step run so the
  /// run-detail card can show what the body actually saw.
  String _encodeInputSnapshot(
    PipelineStepDefinition stepDef,
    PipelineContext ctx,
  ) {
    final config = stepDef.config;
    final inputs = <String, dynamic>{};
    for (final key in config.inputKeys) {
      final v = ctx.state[key] ?? ctx.triggerPayload?[key];
      if (v != null) inputs[key] = _redactSecret(key, v);
    }
    final rendered = config.prompt?.replaceAllMapped(
            RegExp(r'\{\{\s*([a-zA-Z0-9_.$]+)\s*\}\}'),
            (m) {
              final key = m.group(1)!;
              final v = ctx.state[key] ?? ctx.triggerPayload?[key];
              return v == null ? '' : '${_redactSecret(key, v)}';
            },
          );
    return jsonEncode({
      'bodyKey': stepDef.bodyKey,
      if (config.agentId != null) 'agentId': config.agentId,
      if (config.outputKey != null) 'outputKey': config.outputKey,
      'prompt': ?rendered,
      if (inputs.isNotEmpty) 'inputs': inputs,
      if (ctx.triggerPayload != null) 'triggerPayload': ctx.triggerPayload,
    });
  }

  /// Drops the in-memory attempt/step-count bookkeeping for a finished run.
  void _clearRunBookkeeping(String runId) {
    _stepCounts.remove(runId);
    _attempts.removeWhere((k, _) => k.startsWith('$runId/'));
  }

  static final RegExp _secretKeyPattern = RegExp(
    r'(token|secret|password|passwd|apikey|api_key|authorization|credential|private_key)',
    caseSensitive: false,
  );

  /// Redacts values whose key name looks secret, so the persisted input
  /// snapshot never writes credentials to disk in cleartext.
  static Object? _redactSecret(String key, Object? value) {
    if (_secretKeyPattern.hasMatch(key)) return '***redacted***';
    return value;
  }

  static const _uuidGen = Uuid();
  static String _uuid() => _uuidGen.v4();
}

/// Minimal async counting semaphore used to bound concurrent step bodies.
class _Semaphore {
  _Semaphore(this._permits) : assert(_permits > 0);

  int _permits;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() {
    if (_permits > 0) {
      _permits--;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _permits++;
    }
  }
}
