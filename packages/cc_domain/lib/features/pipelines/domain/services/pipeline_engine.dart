import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
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
import 'package:cc_domain/features/pipelines/domain/services/state_reducer.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show kProjectionTriggerEventTypes;
import 'package:uuid/uuid.dart';

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
    this.projectionTriggerEventTypes = kProjectionTriggerEventTypes,
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

  /// `triggerEventType` markers identifying run rows this engine does not own —
  /// projections of work published by the code-graph watcher and the skill
  /// scanners. They are excluded from `maxParallelRuns` accounting because the
  /// engine never observes them finish, so a slot one of them held would never
  /// be released and every later run of that template would queue forever.
  final Set<String> projectionTriggerEventTypes;

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

  /// Used during step resume to collect the dispatched agent runs' output
  /// payloads and feed them into pipeline state under the resumed step's
  /// `outputKey`.
  final AgentRunLogRepository agentRunLogRepository;

  /// real work (subprocess, dispatched agent) is live so [killStep] can
  /// interrupt them from the UI.
  final StepProcessRegistry stepProcessRegistry;

  /// Publishes domain events for pipeline state transitions.
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

  /// Serializes the `maxParallelRuns` count-then-admit per
  /// `(workspaceId, templateId)`. Both the admission check in [start] and the
  /// promotion in [_admitNext] run under it, so two starts racing a completion
  /// can't each read "one slot free" and both take it. Only engaged for
  /// templates that declare a cap.
  final Map<String, Future<void>> _capLocks = {};

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
  final Map<String, Future<void>> _resumeLocks = {};

  /// Interrupted step rows a crash-resume is holding until their sources
  /// finish, as `runId -> {stepId: stepRunId}`.
  ///
  /// A resume obeys the graph: a row is re-fired only once its sources are
  /// satisfied, and `_evaluateDownstreamLocked` does it ON THAT ROW.
  ///
  /// Re-firing every open row at once instead treats a crash as a reason to
  /// ignore the edges. A run interrupted with two steps open then starts both
  /// in the same instant and the downstream one reads state its own upstream
  /// has not written yet — on a chain like `index_code`'s
  /// `space → index → analyze` that means `analyze` resolves
  /// `{{pipeline_space_id}}` to nothing, falls back to a hidden conversation and,
  /// naming no repo scope, checks out every repo in the workspace to do it.
  /// Once per restart.
  ///
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
  }) async {
    final definition = await _requireTemplate(workspaceId, templateId);
    if (!definition.isEnabled) {
      CcDomainLog.info(
        'PipelineEngine: Rejected disabled template: $templateId',
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
        CcDomainLog.info(
          'PipelineEngine: Skipping duplicate run for $templateId $dedupKey (active=${existing.id})',
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
        unawaited(_startLocks.remove(lockKey));
      }
    }
  }

  /// Builds the run row, persists it and kicks
  /// off the entry step. Shared by the dedup and non-dedup paths of [start].
  ///
  /// When the template declares `maxParallelRuns` and the cap is full, the row
  /// is persisted `queued` instead and neither the event nor the entry step
  /// fire — [_admitNext] does both when a slot frees.
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
    PipelineRun buildRun({required bool queued}) => PipelineRun(
      id: _uuid(),
      templateId: templateId,
      workspaceId: workspaceId,
      status: queued ? PipelineRunStatus.queued : PipelineRunStatus.pending,
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
      dedupKey: dedupKey,
      startedAt: DateTime.now(),
      // PRD 25 §6: begin the active-time clock at insert. Folded into activeMs
      // at the next stop; re-stamped on resume/retry so idle gaps are excluded.
      // A queued run has no clock yet — waiting for a slot is idle time, not
      // work, so it is stamped at admission instead.
      activeMs: 0,
      lastResumedAt: queued ? null : DateTime.now(),
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      templateVersion: definition.version,
      dryRun: dryRun,
    );

    final cap = definition.maxParallelRuns;

    /// Inserts the run row, `queued` when the cap is already full.
    ///
    /// Counting and inserting are ONE step on purpose: decide first and insert
    /// after, and two concurrent starts both count the slot as free (neither
    /// has written yet) and both take it — the same check-then-insert race the
    /// dedup lock exists for. A `pending` row already holds its slot, so doing
    /// both under [_withCapLock] below is what closes the window.
    Future<(PipelineRun, bool)> insertAdmitted() async {
      if (cap == null) {
        final run = buildRun(queued: false);
        await repository.insertRun(run);
        return (run, false);
      }
      final active = await repository.activeRunCountForTemplate(
        workspaceId: workspaceId,
        templateId: templateId,
        excludeTriggerEventTypes: projectionTriggerEventTypes,
      );
      final full = active >= cap;
      final run = buildRun(queued: full);
      await repository.insertRun(run);
      if (full) {
        _queuedTemplates.add('$workspaceId|$templateId');
        CcDomainLog.info(
          'PipelineEngine: Queued run ${run.id} for $templateId — '
          '$active/$cap slot(s) in use',
        );
      }
      return (run, full);
    }

    // An uncapped template has nothing to serialize on, so it skips the lock
    // rather than funnelling every start of it through one chain.
    final (run, queued) = cap == null
        ? await insertAdmitted()
        : await _withCapLock(workspaceId, templateId, insertAdmitted);

    if (queued) {
      return run;
    }

    _track(
      _runStep(run: run, definition: definition, stepDef: definition.entryStep),
    );
    return run;
  }

  /// Runs [action] serialized against every other cap decision for
  /// `(workspaceId, templateId)`. See [_capLocks].
  Future<T> _withCapLock<T>(
    String workspaceId,
    String templateId,
    Future<T> Function() action,
  ) async {
    final lockKey = '$workspaceId|$templateId';
    final prev = _capLocks[lockKey] ?? Future<void>.value();
    final gate = Completer<void>();
    _capLocks[lockKey] = gate.future;
    try {
      await prev;
      return await action();
    } finally {
      gate.complete();
      if (_capLocks[lockKey] == gate.future) {
        unawaited(_capLocks.remove(lockKey));
      }
    }
  }

  /// Promotes the oldest `queued` run of [templateId] when the template's
  /// `maxParallelRuns` cap has room. Called at every terminal transition, which
  /// is the only moment a slot frees.
  ///
  /// Free for a template that has never queued anything — see [_queuedTemplates]
  /// — and one indexed lookup otherwise.
  Future<void> _admitNext(String workspaceId, String templateId) async {
    final key = '$workspaceId|$templateId';
    if (!_queuedTemplates.contains(key)) {
      return;
    }
    final PipelineRun? promoted = await _withCapLock(
      workspaceId,
      templateId,
      () async {
        final next = await repository.nextQueuedRunForTemplate(
          workspaceId: workspaceId,
          templateId: templateId,
        );
        if (next == null) {
          _queuedTemplates.remove(key);
          return null;
        }
        final definition = await templates.getById(workspaceId, templateId);
        if (definition == null || !definition.isEnabled) {
          // The template was deleted or switched off while these runs waited.
          // None of them can ever start, and a deleted template will never
          // produce the completion that would drain them one at a time — so
          // close out the whole queue here rather than stranding it.
          final reason = definition == null
              ? 'Template $templateId was deleted while this run was queued.'
              : 'Template $templateId was disabled while this run was queued.';
          var pending = next;
          while (true) {
            await _cancelQueuedRun(pending, reason: reason);
            final more = await repository.nextQueuedRunForTemplate(
              workspaceId: workspaceId,
              templateId: templateId,
            );
            if (more == null) {
              break;
            }
            pending = more;
          }
          _queuedTemplates.remove(key);
          return null;
        }
        final cap = definition.maxParallelRuns;
        if (cap != null) {
          final active = await repository.activeRunCountForTemplate(
            workspaceId: workspaceId,
            templateId: templateId,
            excludeTriggerEventTypes: projectionTriggerEventTypes,
          );
          if (active >= cap) {
            return null;
          }
        }
        // A queued run is usually one that never started — but it can also be a
        // re-run that was queued because the template was full, and that one
        // owns step rows recording what the previous attempt already finished.
        // Firing its entry step would redo all of it, in a room its completed
        // steps already worked in.
        final progress = await repository.stepRunsForPipeline(next.id);
        final isRerun = progress.isNotEmpty;
        final started = next.copyWith(
          // A re-run resumes mid-flight; a fresh start has not run a step yet
          // and `_runStep` promotes it to `running` when one begins.
          status: isRerun
              ? PipelineRunStatus.running
              : PipelineRunStatus.pending,
          // The queue wait was idle; the active-time clock starts here.
          lastResumedAt: DateTime.now(),
        );
        await repository.updateRun(started);
        // Neither branch is awaited: both yield at their first await, which
        // releases this cap lock — and a completion inside them re-enters
        // [_admitNext], which would deadlock on a lock its own caller holds.
        _track(
          isRerun
              ? _rerunFromProgress(run: started, definition: definition)
              : _runStep(
                  run: started,
                  definition: definition,
                  stepDef: definition.entryStep,
                ),
        );
        return started;
      },
    );
    if (promoted != null) {
      CcDomainLog.info(
        'PipelineEngine: Admitted queued run ${promoted.id} for $templateId',
      );
    }
  }

  /// Closes out a run that is still `queued` and can never be admitted. It
  /// owns no step rows and no live work, so this is a plain status flip.
  Future<void> _cancelQueuedRun(
    PipelineRun run, {
    required String reason,
  }) async {
    CcDomainLog.warning(
      'PipelineEngine: Dropping queued run ${run.id}: $reason',
    );
    await repository.updateRun(
      run.copyWith(
        status: PipelineRunStatus.cancelled,
        finishedAt: DateTime.now(),
        errorMessage: reason,
        lastResumedAt: null,
      ),
    );
    eventBus.publish(
      PipelineRunCancelled(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  /// Resumes all in-flight runs that were interrupted by a crash/restart.
  @override
  Future<void> resumeAll() async {
    final all = await repository.nonTerminalRuns();
    if (all.isEmpty) {
      return;
    }

    // A queued run was never started: it owns no step rows, so the resume path
    // below would find nothing to re-fire and leave it waiting forever behind a
    // cap whose in-flight runs died with the previous process. Hold them out
    // and re-run admission per template once the survivors are back.
    final runs = <PipelineRun>[];
    final queuedTemplates = <({String workspaceId, String templateId})>{};
    for (final run in all) {
      if (run.status == PipelineRunStatus.queued) {
        queuedTemplates.add((
          workspaceId: run.workspaceId,
          templateId: run.templateId,
        ));
        _queuedTemplates.add('${run.workspaceId}|${run.templateId}');
      } else {
        runs.add(run);
      }
    }

    CcDomainLog.info(
      'PipelineEngine: Resuming ${runs.length} in-flight pipeline(s)'
      '${queuedTemplates.isEmpty ? '' : ', ${all.length - runs.length} queued'}',
    );

    for (final staleRun in runs) {
      // PRD 25 §6: the app was down between the crash and this resume; that gap
      // is idle, not active. Re-stamp lastResumedAt = now so the downtime is
      // excluded from the run's active duration. The pre-crash running segment
      // is unrecoverable (it was never folded), but counting the downtime would
      // reintroduce the wall-clock inflation this fixes.
      final now = DateTime.now();
      final stepRuns = await repository.stepRunsForPipeline(staleRun.id);
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

      // Re-firing an interrupted step body is a new attempt from the operator's
      // side — the agents start over, the logs start over. A run with nothing
      // in flight is only being RE-ATTACHED, so it keeps the attempt it was on.
      final isNewAttempt = pendingOrSuspended.isNotEmpty;
      final run = staleRun.copyWith(
        lastResumedAt: now,
        // "Started" on the run's page names this moment: the process the
        // original stamp belongs to is gone. Null keeps the run's current
        // value, which is what a re-attach wants.
        attemptStartedAt: isNewAttempt ? now : null,
        attemptCount: isNewAttempt ? staleRun.attemptCount + 1 : null,
      );
      await repository.updateRun(run);
      final workspaceId = run.workspaceId;
      final definition = await templates.getById(workspaceId, run.templateId);
      if (definition == null) {
        CcDomainLog.warning(
          'PipelineEngine: Cannot resume run ${run.id}: template ${run.templateId} '
          'missing for workspace $workspaceId',
        );
        continue;
      }
      if (definition.version != run.templateVersion) {
        CcDomainLog.warning(
          'PipelineEngine: Run ${run.id} pinned template ${run.templateId} v'
          '${run.templateVersion} but the live template is now v'
          '${definition.version}; resuming against the live graph.',
        );
      }

      // A backstop failure below fails the whole run (and closes out its other
      // open rows), so the remaining steps of this run must not be resumed.
      var runFailed = false;
      for (final sr in pendingOrSuspended) {
        if (runFailed) {
          break;
        }
        final stepDef = definition.step(sr.stepId);
        if (stepDef == null) {
          continue;
        }
        // Liveness backstop: a step suspended longer than the timeout is waiting
        // on tickets that will never complete (e.g. an agent that neither
        // completed its ticket nor ended its run). Fail it rather than re-run /
        // hang the run forever. Approval gates (PRD 17 §4 partial approval)
        // are exempt: waiting days for an explicit human approval is their
        // job and re-running the gate body below re-checks the approved set.
        //
        // It measures THIS attempt: re-firing the body below re-stamps the
        // row's start, because the agents it dispatches are new ones. So the
        // clock a resume restarts is the clock on work that restarted with it,
        // and the backstop only ever fails a step that sat still for the whole
        // timeout inside one attempt.
        final awaitsApproval = stepDef.config.extras['awaitApproval'] == true;
        if (!awaitsApproval &&
            sr.status == PipelineStepStatus.suspended &&
            now.difference(sr.startedAt) > suspendedStepTimeout) {
          await _failStep(
            run: run,
            stepRunId: sr.id,
            stepId: sr.stepId,
            error:
                'Suspended beyond ${suspendedStepTimeout.inHours}h without '
                'its tickets completing — failed by the liveness backstop.',
          );
          runFailed = true;
          continue;
        }
        // A step explicitly marked non-idempotent that was already mid-flight
        // (running/suspended) might have completed its side effect (e.g.
        // `gh pr merge`) before the crash. Re-running could double-apply it,
        // so fail it instead and let the user retry deliberately.
        final nonIdempotent = stepDef.config.extras['idempotent'] == false;
        final alreadyStarted =
            sr.status == PipelineStepStatus.running ||
            sr.status == PipelineStepStatus.suspended;
        if (nonIdempotent && alreadyStarted) {
          await _failStep(
            run: run,
            stepRunId: sr.id,
            stepId: sr.stepId,
            error:
                'Interrupted non-idempotent step — not auto-re-run on '
                'resume. Retry the run to re-execute it deliberately.',
          );
          runFailed = true;
          continue;
        }
        // An entry step answers to nothing, so it can only be re-fired here.
        // Everything else waits for its sources: the downstream evaluation
        // below re-fires it on this row the moment they are satisfied. Firing
        // them all here is what let a step run before its own upstream had
        // written the state it reads. See [_resumableSteps].
        if (stepDef.triggers.isEmpty) {
          _track(
            _runStep(
              run: run,
              definition: definition,
              stepDef: stepDef,
              existingStepRunId: sr.id,
            ),
          );
        } else {
          (_resumableSteps[run.id] ??= <String, String>{})[sr.stepId] = sr.id;
        }
      }

      await _evaluateDownstream(
        run: run,
        definition: definition,
        completedStepIds: completedStepIds,
      );
    }

    for (final t in queuedTemplates) {
      await _admitNext(t.workspaceId, t.templateId);
    }
  }

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

    final now = DateTime.now();
    final updated = run.copyWith(
      status: PipelineRunStatus.cancelled,
      finishedAt: now,
      // Fold the live segment and stop the active-time clock (PRD 25 §6).
      activeMs: _foldedActiveMs(run, now),
      lastResumedAt: null,
    );
    await repository.updateRun(updated);
    _clearRunBookkeeping(run.id);
    // Announce the terminal transition so listeners that finalize work tied to
    // this run (e.g. the meeting-summary reconciler) can release it now rather
    // than waiting for the next startup sweep. Cancellation emits no
    // Completed/Failed, so without this the run looks alive to those listeners.
    eventBus.publish(
      PipelineRunCancelled(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        occurredAt: DateTime.now(),
      ),
    );

    await _cancelOpenSteps(
      run.workspaceId,
      pipelineRunId,
      reason: 'Run cancelled',
    );
    await _admitNext(run.workspaceId, run.templateId);
  }

  /// Stops and closes out every step row of [pipelineRunId] that is still open
  /// (pending / running / suspended). Call this immediately after flipping a run
  /// terminal.
  ///
  /// Once the run is terminal, an open step row is orphaned: [resumeStep],
  /// [resumeAll] and `_evaluateDownstreamLocked` all bail on a terminal run, so
  /// nothing will ever finish it. Left behind it reads "Running" forever, its
  /// live-duration timer ticks without bound (inflating the waterfall's idle
  /// gap) and its kill callback leaks in [StepProcessRegistry].
  ///
  /// Parallel branches are the common case: a fan-out is N sibling step rows
  /// listening on the same source, so stopping (or failing) one of them takes
  /// the run terminal out from under all the others.
  ///
  /// [workspaceId] is the workspace owning [pipelineRunId]; a step-run id is not
  /// routable to a workspace on its own, so every row write is scoped by it.
  Future<void> _cancelOpenSteps(
    String workspaceId,
    String pipelineRunId, {
    required String reason,
  }) async {
    final steps = await repository.stepRunsForPipeline(pipelineRunId);
    for (final sr in steps) {
      if (sr.isTerminal) {
        continue;
      }
      // Interrupt the step's live work (cancel its ticket, stop its agent).
      // No-op when nothing is registered yet (the step had not started its
      // work) — the ticket guard in TicketDispatcher still covers that case.
      try {
        await stepProcessRegistry.kill(sr.id);
      } on Object catch (e, st) {
        CcDomainLog.error(
          'PipelineEngine: kill callback threw for orphaned step ${sr.id}',
          e,
          st,
        );
      }
      await repository.updateStepRun(
        workspaceId,
        sr.id,
        status: PipelineStepStatus.cancelled,
        errorMessage: reason,
        finishedAt: DateTime.now(),
      );
    }
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

  /// Runs [action] serialized against every other resume of `(runId, stepId)`.
  /// See [_resumeLocks].
  Future<void> _withResumeLock(
    String runId,
    String stepId,
    Future<void> Function() action,
  ) async {
    final lockKey = '$runId/$stepId';
    final prev = _resumeLocks[lockKey] ?? Future<void>.value();
    final gate = Completer<void>();
    _resumeLocks[lockKey] = gate.future;
    try {
      await prev;
      await action();
    } finally {
      gate.complete();
      if (_resumeLocks[lockKey] == gate.future) {
        unawaited(_resumeLocks.remove(lockKey));
      }
    }
  }

  Future<void> _resumeStepLocked({
    required String pipelineRunId,
    required String stepId,
  }) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null || run.isTerminal) {
      return;
    }

    final stepRuns = await repository.stepRunsForPipeline(pipelineRunId);
    // Rows waiting on a dispatched task are kept in `running` so the UI
    // doesn't say "suspended" while the agent is actively working. Some
    // legacy / non-task suspensions still use `suspended`; accept both. A step
    // that was re-dispatched (manual retry, or a timeout that re-fired the
    // body) can momentarily have more than one such row — take the most
    // recently started so the harvest below reads the live attempt, not a
    // superseded one.
    final suspendedRuns = stepRuns
        .where(
          (sr) =>
              sr.stepId == stepId &&
              (sr.status == PipelineStepStatus.running ||
                  sr.status == PipelineStepStatus.suspended),
        )
        .toList();
    if (suspendedRuns.isEmpty) {
      return;
    }
    final suspended = suspendedRuns.reduce(
      (a, b) => b.startedAt.isAfter(a.startedAt) ? b : a,
    );

    final workspaceId = run.workspaceId;
    final definition = await templates.getById(workspaceId, run.templateId);
    final stepDef = definition?.step(stepId);
    final outputKey = stepDef?.config.outputKey;
    if (outputKey != null && outputKey.isNotEmpty && stepDef != null) {
      try {
        final allRuns = await agentRunLogRepository.forPipelineStep(
          workspaceId,
          pipelineRunId,
          stepId,
        );
        // Runs are scoped to (run, step), not to one step-run attempt. The
        // startedAt cutoff drops runs minted before THIS suspension's step
        // run started (covering the retry() path, which inserts a fresh
        // step-run row). What survives is then reconciled by cardinality below
        // so a single-object node never collapses 0-or-many payloads into a
        // List — validating a List against an object schema reports the
        // misleading "expected object, got array" and hides the real failure.
        final runs = allRuns
            .where((r) => !r.startedAt.isBefore(suspended.startedAt))
            .toList();
        final schema = stepDef.config.outputSchema;
        final isObjectContract = schema != null && schema['type'] == 'object';
        // A run recorded as failed has no deliverable, whatever it left behind:
        // a partial answer written before the process died is not a result, and
        // harvesting one is how a step whose agent never finished reached the
        // canvas as a green node. Dropping the payload here routes it into the
        // guard below, which fails the step with the run's own reason.
        final failedRuns = runs
            .where((r) => r.status == RunStatus.error)
            .toList();
        final withOutput =
            runs
                .where(
                  (r) => r.outputJson != null && r.status != RunStatus.error,
                )
                .toList()
              // Freshest completion first, so a lingering duplicate from a prior
              // attempt can't shadow the live one.
              ..sort(
                (a, b) => (b.completedAt ?? b.startedAt).compareTo(
                  a.completedAt ?? a.startedAt,
                ),
              );

        // Every awaited run terminated without output — the agent failed, was
        // force-failed by the output contract, or the run ended without a
        // final submit_output. Surface that reason (and record it on the step)
        // instead of a schema-shape error.
        //
        // The guard used to sit inside the object-contract branch alone, so a
        // SCHEMALESS node fell through to the fan-out path below and merged
        // its EMPTY payload list as the step's result. A literal `[]`
        // downstream cannot be told apart from a reviewer who genuinely found
        // nothing: three PR reviewers that had filed 52 findings between them
        // each handed the consolidation step `[]`, and the lead reviewer
        // faithfully reported that every specialist pass came back empty.
        if (withOutput.isEmpty && (runs.isNotEmpty || isObjectContract)) {
          if (definition != null) {
            final reasons = runs
                .map((r) => r.summary)
                .whereType<String>()
                .where((m) => m.trim().isNotEmpty)
                .toList();
            final reason = reasons.isNotEmpty
                ? reasons.join('; ')
                // No summary yet (the terminal write can land after the event
                // that brought us here), so say which of the two shapes this
                // was rather than blaming the payload for a failed run.
                : failedRuns.isEmpty
                ? 'the agent returned no output payload'
                : 'the agent run failed';
            await _handleStepFailure(
              run: run,
              definition: definition,
              stepDef: stepDef,
              stepRunId: suspended.id,
              error: '$outputKey: $reason',
              outputJson: jsonEncode({
                'error': 'No output payload',
                'reason': reason,
                'runIds': runs.map((r) => r.id).toList(),
              }),
            );
          }
          return;
        }

        // Some runs failed but others delivered — a fan-out (forEach / team
        // dispatch) that partly worked. The step still advances on what it got,
        // but the drop is said out loud: a silently shortened payload list is
        // the shape that produced a confident report from three reviewers who
        // had never run.
        if (failedRuns.isNotEmpty) {
          CcDomainLog.warning(
            'PipelineEngine: step $stepId of run $pipelineRunId harvested '
            '${withOutput.length} payload(s) and dropped ${failedRuns.length} '
            'failed run(s): ${failedRuns.map((r) => r.id).join(', ')}',
          );
        }

        if (isObjectContract) {
          // One or many: take the freshest payload so a stale duplicate can't
          // turn a single-object contract into a List.
          final value = withOutput.first.outputJson!;
          if (!await _validateAndMergeHarvest(
            pipelineRunId: pipelineRunId,
            run: run,
            definition: definition,
            stepDef: stepDef,
            stepRunId: suspended.id,
            outputKey: outputKey,
            value: value,
          )) {
            return;
          }
        } else if (runs.isNotEmpty) {
          // Schemaless node, or an array-rooted schema → may legitimately fan
          // out to several runs (forEach / team dispatch). Preserve the
          // historical shape: one payload unwraps a `{result: ...}`
          // convenience; multiple payloads stay a List.
          final payloads = withOutput.map((r) => r.outputJson!).toList();
          final hasSchema = schema != null;
          final value = (payloads.length == 1 && !hasSchema)
              ? (payloads.single['result'] ?? payloads.single)
              : (payloads.length == 1 ? payloads.single : payloads);
          if (!await _validateAndMergeHarvest(
            pipelineRunId: pipelineRunId,
            run: run,
            definition: definition,
            stepDef: stepDef,
            stepRunId: suspended.id,
            outputKey: outputKey,
            value: value,
          )) {
            return;
          }
        }
      } on Object catch (e, st) {
        // A harvest failure must fail the step — never silently complete it
        // with no output (which would feed downstream nothing and mask the
        // problem).
        CcDomainLog.error('PipelineEngine: output harvest failed', e, st);
        if (definition != null) {
          await _handleStepFailure(
            run: run,
            definition: definition,
            stepDef: stepDef,
            stepRunId: suspended.id,
            error: 'Output harvest failed: $e',
            outputJson: jsonEncode({
              'error': 'Output harvest failed',
              'detail': '$e',
            }),
          );
        }
        return;
      }
    }

    stepProcessRegistry.unregister(suspended.id);
    await repository.updateStepRun(
      workspaceId,
      suspended.id,
      status: PipelineStepStatus.completed,
      finishedAt: DateTime.now(),
    );

    if (definition == null) {
      return;
    }
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
  }) => _withResumeLock(
    parentRunId,
    parentStepId,
    () => _resumeChildFlowLocked(
      parentRunId: parentRunId,
      parentStepId: parentStepId,
      childRun: childRun,
    ),
  );

  Future<void> _resumeChildFlowLocked({
    required String parentRunId,
    required String parentStepId,
    required PipelineRun childRun,
  }) async {
    final run = await repository.getRun(parentRunId);
    if (run == null || run.isTerminal) {
      return;
    }

    final stepRuns = await repository.stepRunsForPipeline(parentRunId);
    final suspended = stepRuns
        .where(
          (sr) =>
              sr.stepId == parentStepId &&
              (sr.status == PipelineStepStatus.running ||
                  sr.status == PipelineStepStatus.suspended),
        )
        .firstOrNull;
    if (suspended == null) {
      return;
    }

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
          error:
              'Sub-pipeline "${childRun.templateId}" '
              '${childRun.status.name}',
        );
      }
      return;
    }

    final outputKey = stepDef?.config.outputKey;
    if (outputKey != null && outputKey.isNotEmpty && stepDef != null) {
      await _mergeState(parentRunId, {
        outputKey: childRun.state,
      }, producer: stepDef);
    }

    stepProcessRegistry.unregister(suspended.id);
    await repository.updateStepRun(
      workspaceId,
      suspended.id,
      status: PipelineStepStatus.completed,
      finishedAt: DateTime.now(),
    );

    if (definition == null) {
      return;
    }
    final latest = await repository.getRun(parentRunId) ?? run;
    await _evaluateDownstream(
      run: latest,
      definition: definition,
      completedStepIds: {parentStepId},
    );
  }

  /// Kills the in-flight work for [stepRunId]: invokes the registered
  /// cleanup callback (bash → SIGTERM the process; promptAgent → cancel
  /// task + kill agent PID), marks the step run row as failed and fails
  /// the parent pipeline run so the Retry button shows up.
  ///
  /// Failing the run closes out the step's still-open siblings (see
  /// [_cancelOpenSteps]) — a parallel branch cannot keep running once the run
  /// it belongs to is terminal.
  ///
  /// [workspaceId] is the workspace owning [stepRunId]; a step-run id is not
  /// routable to a workspace on its own, so a foreign id resolves to nothing.
  ///
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

  /// Re-runs a pipeline run that has stopped, from where it stopped. Completed
  /// step runs (and their outputs) are preserved; every other row is re-opened
  /// in place and its body re-fired — the same mechanism [resumeAll] uses after
  /// a crash.
  ///
  /// Both terminal outcomes an operator can act on are accepted: `failed`, and
  /// `cancelled` for a run they stopped themselves. Refusing the second meant
  /// pressing Stop was irreversible — the only way back was a fresh run that
  /// redid the work the cancelled one had already finished.
  ///
  /// A re-run takes a `maxParallelRuns` slot like a start does and QUEUES when
  /// the template is full. An operator asking for it explicitly is not a reason
  /// to exempt it: "retry all" on a morning's worth of failures is exactly when
  /// the cap earns its keep, and a cap a button can exceed bounds nothing.
  /// Queued, the run keeps its place in the list and [_admitNext] resumes it
  /// from its own progress when a slot frees.
  ///
  /// Rows are re-opened, never deleted and re-created. A step run carries the
  /// `spaceId` of the room its agents already work in, so a fresh row would
  /// provision a second checkout for work already under way. Re-opening also
  /// re-stamps `startedAt`, so the step reports the attempt being watched.
  @override
  Future<void> retry(String workspaceId, String pipelineRunId) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null) {
      return;
    }
    if (run.status != PipelineRunStatus.failed &&
        run.status != PipelineRunStatus.cancelled) {
      return;
    }

    final definition = await templates.getById(run.workspaceId, run.templateId);
    if (definition == null) {
      return;
    }

    final now = DateTime.now();

    /// The run re-opened for another attempt.
    ///
    /// `startedAt` stays the run's ORIGINAL start — it is the origin the
    /// waterfall draws from and the queue orders by, so a re-run keeps its
    /// place in the list instead of jumping to the top. The attempt an operator
    /// is looking at is `attemptStartedAt`.
    ///
    /// The previous outcome is CLEARED. Left behind, a re-running run still
    /// reported when it had finished and why it had failed.
    PipelineRun reopened({required bool admitted}) => run.copyWith(
      status: admitted ? PipelineRunStatus.running : PipelineRunStatus.queued,
      attemptStartedAt: now,
      // Counted once, here — not at admission: a queued re-run is already on
      // its new attempt from the operator's side, and the wait for a slot is
      // part of it.
      attemptCount: run.attemptCount + 1,
      // Resume the active-time clock (PRD 25 §6): activeMs already holds the
      // prior attempt's folded active time (stamped at the failing stop), so
      // re-stamping lastResumedAt accumulates this attempt on top of it while
      // the idle gap between failure and retry is excluded. A queued re-run has
      // no clock yet — waiting for a slot is idle time, not work.
      lastResumedAt: admitted ? now : null,
      finishedAt: null,
      errorMessage: null,
      errorStackTrace: null,
    );

    final cap = definition.maxParallelRuns;
    final PipelineRun reset;
    if (cap == null) {
      reset = reopened(admitted: true);
      await repository.updateRun(reset);
    } else {
      // Counting and writing under the cap lock, for the same reason a start
      // does: two re-runs racing a completion would otherwise each read one
      // slot free and both take it.
      final admitted = await _withCapLock(
        run.workspaceId,
        run.templateId,
        () async {
          final active = await repository.activeRunCountForTemplate(
            workspaceId: run.workspaceId,
            templateId: run.templateId,
            excludeTriggerEventTypes: projectionTriggerEventTypes,
          );
          final full = active >= cap;
          await repository.updateRun(reopened(admitted: !full));
          if (full) {
            _queuedTemplates.add('${run.workspaceId}|${run.templateId}');
          }
          return !full;
        },
      );
      if (!admitted) {
        CcDomainLog.info(
          'PipelineEngine: Queued rerun of ${run.id} for ${run.templateId} — '
          'the template is at its $cap-run cap',
        );
        return;
      }
      reset = reopened(admitted: true);
    }

    await _rerunFromProgress(run: reset, definition: definition);
  }

  /// Re-fires everything [run] has left to do: each non-terminal step row on the
  /// row it already owns, then a downstream evaluation for anything the
  /// preserved-completed set unblocks. Shared by [retry] and by [_admitNext]
  /// when the run it promotes is a queued re-run rather than a fresh start.
  Future<void> _rerunFromProgress({
    required PipelineRun run,
    required PipelineDefinition definition,
  }) async {
    final stepRuns = await repository.stepRunsForPipeline(run.id);
    final completed = <String>{};
    final toRerun = <PipelineStepRun>[];
    for (final sr in stepRuns) {
      if (sr.status == PipelineStepStatus.completed ||
          sr.status == PipelineStepStatus.skipped) {
        completed.add(sr.stepId);
      } else {
        // Failed / cancelled / pending / running / suspended: this attempt's
        // work, re-fired below on the row it already owns.
        toRerun.add(sr);
      }
    }

    if (completed.isEmpty && toRerun.isEmpty) {
      // Nothing ever ran — kick the start step over again.
      _track(
        _runStep(
          run: run,
          definition: definition,
          stepDef: definition.entryStep,
        ),
      );
      return;
    }

    for (final sr in toRerun) {
      // Drop the per-(run, step) attempt bookkeeping from the failed pass, so
      // what the counter reports is this retry's progress through the node's
      // policy rather than the exhausted count it stopped at.
      _attempts.remove('${run.id}/${sr.stepId}');
      final stepDef = definition.step(sr.stepId);
      if (stepDef == null) {
        // The template dropped this step since the run started — the row has
        // nothing left to execute, so drop it rather than strand it open.
        await repository.deleteStepRun(run.workspaceId, sr.id);
        continue;
      }
      _track(
        _runStep(
          run: run,
          definition: definition,
          stepDef: stepDef,
          existingStepRunId: sr.id,
        ),
      );
    }

    // Anything downstream of the preserved-completed set that never got a row.
    await _evaluateDownstream(
      run: run,
      definition: definition,
      completedStepIds: completed,
    );
  }

  /// Wait for any in-flight step futures to settle. Call from
  /// `Provider.onDispose` so we don't leak work across hot reloads.
  Future<void> dispose() async {
    if (_inFlight.isEmpty) {
      return;
    }
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
        CcDomainLog.warning(
          'PipelineEngine: Template "$templateId" step "${step.id}" references unregistered '
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
    if (stepDef.kind == StepKind.terminal) {
      return;
    }

    // The run can go terminal between this step being scheduled and it actually
    // starting (a sibling branch was stopped, or failed). Inserting a fresh
    // `running` row now would strand it: nothing revisits the steps of a
    // terminal run, so it would read "Running" forever.
    final owning = await repository.getRun(run.id);
    if (owning != null && owning.isTerminal) {
      return;
    }

    // A node can declare a condition on the run's own state / trigger payload
    // (`extras.runWhen`), which is how ONE template varies its shape per run
    // instead of forking into near-identical copies. An unmet condition records
    // the step as skipped rather than omitting it, so the timeline distinguishes
    // "deliberately not run" from "missing", and joins downstream resolve
    // (a join is ready once its sources are completed-or-skipped).
    final gate = stepDef.config.runWhen;
    if (gate != null) {
      final gateRun = owning ?? run;
      final resolved =
          gateRun.state[gate.key] ?? gateRun.triggerPayload?[gate.key];
      if (!gate.allows(resolved)) {
        await _skipGatedStep(
          run: gateRun,
          definition: definition,
          stepDef: stepDef,
          existingStepRunId: existingStepRunId,
          skippedOutput: gate.skippedOutput,
        );
        return;
      }
    }

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
      await repository.insertStepRun(
        PipelineStepRun(
          id: stepRunId,
          pipelineRunId: current.id,
          stepId: stepDef.id,
          status: PipelineStepStatus.running,
          startedAt: now,
        ),
      );
    } else {
      // Another attempt on the SAME row (a crash-resume or a retry re-firing
      // this step). Re-stamp its start and drop the previous attempt's outcome:
      // flipping the status alone left the row reporting the FIRST attempt's
      // "Started" — and its stale error — while the body it just re-invoked was
      // minutes into a second one.
      await repository.restartStepRun(
        current.workspaceId,
        existingStepRunId,
        startedAt: now,
      );
    }

    final ctx = PipelineContext(
      pipelineRunId: current.id,
      templateId: current.templateId,
      stepId: stepDef.id,
      stepRunId: stepRunId,
      workspaceId: current.workspaceId,
      state: Map<String, dynamic>.from(current.state),
      triggerPayload: current.triggerPayload,
      dryRun: current.dryRun,
      // Lets a body hand its concurrency permit back while it is idle-waiting.
      // See [PipelineContext.whileWaiting].
      idleRunner: _runWhileWaiting,
    );

    // Snapshot the input so the run-detail card can show what the body saw —
    // rendered prompt, resolved inputKeys values and the trigger payload.
    await repository.updateStepRun(
      current.workspaceId,
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

        // Stopped mid-body? Covers `failed` as well as `cancelled`: a sibling
        // branch that was stopped (or failed) took the whole run down while
        // this body was still working and this row has nobody left to finish
        // it. Falling through would re-write it to `running` (the suspend path
        // below) and strand it there.
        final fresh = await repository.getRun(current.id);
        if (fresh == null ||
            fresh.status == PipelineRunStatus.cancelled ||
            fresh.status == PipelineRunStatus.failed) {
          stepProcessRegistry.unregister(stepRunId);
          await repository.updateStepRun(
            current.workspaceId,
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
              outputJson: jsonEncode({
                'error': 'Output schema violation',
                'violations': violations,
                'invalidOutput': r.mutatedState,
              }),
            );
            return;
          }
        }

        result = r;
        break;
      } on Object catch (e, st) {
        lastError = e.toString();
        lastStack = st.toString();
        CcDomainLog.error(
          'PipelineEngine: Step ${stepDef.id} attempt $attempt/$maxAttempts failed',
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

    if (result == null) {
      return; // failure already handled in the loop
    }
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
        current.workspaceId,
        stepRunId,
        status: PipelineStepStatus.running,
        outputJson: mutations.isEmpty ? null : jsonEncode(mutations),
      );
      return;
    }

    stepProcessRegistry.unregister(stepRunId);
    await repository.updateStepRun(
      current.workspaceId,
      stepRunId,
      status: PipelineStepStatus.completed,
      outputJson: mutations.isEmpty ? null : jsonEncode(mutations),
      finishedAt: DateTime.now(),
    );

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
      if (timeoutMs == null) {
        return await future;
      }
      try {
        return await future.timeout(Duration(milliseconds: timeoutMs));
      } on TimeoutException {
        try {
          await stepProcessRegistry.kill(stepRunId);
        } on Object catch (_) {
          /* best effort */
        }
        rethrow;
      }
    } finally {
      _slots.release();
    }
  }

  /// Backs [PipelineContext.whileWaiting]: gives the step's permit back for the
  /// duration of [action], then takes one again.
  ///
  /// The re-acquire is in a `finally` so a throwing [action] still leaves the
  /// permit accounted for — [_invokeBody] releases one unconditionally when the
  /// body returns, and an unbalanced release would silently raise the cap for
  /// the rest of the process's life.
  ///
  /// One case is net-neutral rather than exact: a node `timeoutMs` that fires
  /// while the body sits in here. `Future.timeout` does not stop the body, so
  /// [_invokeBody] releases a permit this body had already handed back (+1 to
  /// the cap) and the re-acquire below is never released when the body finally
  /// unwinds (−1). They cancel. That the cap can be off by one either way while
  /// a timed-out body drains is inherited, not introduced: a timed-out body
  /// already kept running past its permit's release.
  Future<T> _runWhileWaiting<T>(Future<T> Function() action) async {
    _slots.release();
    try {
      return await action();
    } finally {
      await _slots.acquire();
    }
  }

  Future<void> _backoff(StepRetryPolicy? policy, int attempt) async {
    if (policy == null) {
      return;
    }
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
    if (schema == null || schemaValidator == null || key == null) {
      return const [];
    }
    return schemaValidator!.validate(mutatedState?[key], schema);
  }

  /// Validates a harvested [value] against the node's output contract and, on
  /// success, merges it into pipeline state under [outputKey]. Returns `true`
  /// when the harvest may proceed; on a schema violation it fails the step —
  /// recording the offending value on the step run so the failure is
  /// diagnosable — and returns `false`.
  Future<bool> _validateAndMergeHarvest({
    required String pipelineRunId,
    required PipelineRun run,
    required PipelineDefinition? definition,
    required PipelineStepDefinition stepDef,
    required String stepRunId,
    required String outputKey,
    required Object? value,
  }) async {
    // Enforce the node's output contract on the (least-trustworthy)
    // agent-produced output before it flows downstream.
    final violations = _validateOutput(stepDef, {outputKey: value});
    if (violations.isNotEmpty && definition != null) {
      await _handleStepFailure(
        run: run,
        definition: definition,
        stepDef: stepDef,
        stepRunId: stepRunId,
        error: 'Output schema violation: ${violations.join('; ')}',
        outputJson: jsonEncode({
          'error': 'Output schema violation',
          'violations': violations,
          'invalidOutput': value,
        }),
      );
      return false;
    }
    await _mergeState(pipelineRunId, {outputKey: value}, producer: stepDef);
    return true;
  }

  /// Records a step whose `runWhen` condition was unmet as skipped, publishes
  /// its declared placeholder output and lets the run continue.
  ///
  /// No `PipelineStepStarted` / `PipelineStepCompleted` pair is published: the
  /// step never ran, and a completion event for a body that was not invoked
  /// would be consumed by listeners as work having happened. That matches how
  /// router-bypassed branches are already recorded.
  Future<void> _skipGatedStep({
    required PipelineRun run,
    required PipelineDefinition definition,
    required PipelineStepDefinition stepDef,
    required String? existingStepRunId,
    required String? skippedOutput,
  }) async {
    final now = DateTime.now();
    if (existingStepRunId == null) {
      await repository.insertStepRun(
        PipelineStepRun(
          id: _uuid(),
          pipelineRunId: run.id,
          stepId: stepDef.id,
          status: PipelineStepStatus.skipped,
          startedAt: now,
          finishedAt: now,
        ),
      );
    } else {
      // A resume or retry landed on a row that already exists: flip it rather
      // than inserting a second row for the same step.
      await repository.updateStepRun(
        run.workspaceId,
        existingStepRunId,
        status: PipelineStepStatus.skipped,
        finishedAt: now,
      );
    }

    // Downstream prompts may interpolate this step's output. An unresolved
    // placeholder fails its step, so a skipped optional node would otherwise
    // take the step that consolidates it down too.
    final outputKey = stepDef.config.outputKey;
    if (skippedOutput != null && outputKey != null && outputKey.isNotEmpty) {
      await _mergeState(run.id, {outputKey: skippedOutput});
    }

    await _evaluateDownstream(
      run: run,
      definition: definition,
      completedStepIds: const {},
    );
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
    String? outputJson,
  }) async {
    if (!stepDef.config.continueOnFail) {
      await _failStep(
        run: run,
        stepRunId: stepRunId,
        stepId: stepDef.id,
        error: error,
        stackTrace: stackTrace,
        outputJson: outputJson,
      );
      return;
    }

    // continueOnFail: record the error, mark the step completed (so downstream
    // gated on it still fires) and keep the run alive.
    stepProcessRegistry.unregister(stepRunId);
    final fresh = await repository.getRun(run.id) ?? run;
    final errors = <String, dynamic>{
      ...?(fresh.state[kStepErrorsKey] as Map?)?.cast<String, dynamic>(),
      stepDef.id: error,
    };
    await _mergeState(run.id, {kStepErrorsKey: errors});
    await repository.updateStepRun(
      run.workspaceId,
      stepRunId,
      status: PipelineStepStatus.completed,
      outputJson:
          outputJson ?? jsonEncode({'error': error, 'continuedOnFail': true}),
      finishedAt: DateTime.now(),
    );
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
    if (run.isTerminal) {
      return;
    }
    final now = DateTime.now();
    final updated = run.copyWith(
      status: PipelineRunStatus.failed,
      finishedAt: now,
      // Fold the live segment and stop the active-time clock (PRD 25 §6).
      activeMs: _foldedActiveMs(run, now),
      lastResumedAt: null,
      errorMessage: error,
    );
    await repository.updateRun(updated);
    eventBus.publish(
      PipelineRunFailed(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        errorMessage: error,
        occurredAt: DateTime.now(),
      ),
    );
    await _admitNext(run.workspaceId, run.templateId);
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
        unawaited(_evalLocks.remove(run.id));
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
    if (current.isTerminal) {
      return;
    }

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

    // Rows a crash-resume is holding until their sources finish. They have a
    // row, so the existing-row veto would hide them forever; naming them here
    // lets the planner judge them on readiness like anything else.
    final resumable = _resumableSteps[current.id] ?? const <String, String>{};

    final plan = planDownstream(
      definition: definition,
      completed: completed,
      skipped: skipped,
      existing: existing,
      chosenRoutes: chosenRoutes,
      resumable: resumable.keys.toSet(),
    );

    // Record branches a router bypassed (and their now-unreachable descendants)
    // as skipped, so joins/terminals downstream resolve instead of hanging and
    // the timeline shows them as deliberately skipped rather than missing.
    for (final stepId in plan.toSkip) {
      final now = DateTime.now();
      await repository.insertStepRun(
        PipelineStepRun(
          id: _uuid(),
          pipelineRunId: current.id,
          stepId: stepId,
          status: PipelineStepStatus.skipped,
          startedAt: now,
          finishedAt: now,
        ),
      );
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
      if (stepDef == null) {
        continue;
      }
      // A held row is re-fired ON ITSELF — claimed here so a later evaluation
      // cannot schedule it a second time, and so the room a previous attempt
      // opened is the one this attempt works in.
      final held = _resumableSteps[current.id]?.remove(stepId);
      _track(
        _runStep(
          run: current,
          definition: definition,
          stepDef: stepDef,
          existingStepRunId: held,
        ),
      );
    }
  }

  // ── State + status helpers ──────────────────────────────────────────

  /// Accumulated active milliseconds for [run] as of [now] (PRD 25 §6): the
  /// persisted [PipelineRun.activeMs] plus the currently-running segment
  /// (`now - lastResumedAt`). Called at a stop to fold the live segment into
  /// `activeMs` before clearing `lastResumedAt`, so idle stop→restart gaps
  /// never enter the total.
  static int _foldedActiveMs(PipelineRun run, DateTime now) {
    final resumed = run.lastResumedAt;
    if (resumed == null) {
      return run.activeMs;
    }
    final live = now.difference(resumed).inMilliseconds;
    return live > 0 ? run.activeMs + live : run.activeMs;
  }

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
      if (fresh == null) {
        return;
      }
      final reducerKey = producer?.config.outputKey;
      final reducerName = producer?.config.reducer;
      // A non-empty reducer name that isn't a known strategy is a template bug
      // (save-time validation catches new templates; this guards rows that
      // predate it). Fail loudly instead of silently degrading to 'override'.
      if (reducerName != null &&
          reducerName.isNotEmpty &&
          reducerName != 'override' &&
          !reducers.isKnown(reducerName)) {
        throw StateError('Unknown state reducer "$reducerName"');
      }
      final useReducer =
          reducerKey != null &&
          reducerName != null &&
          reducerName.isNotEmpty &&
          reducerName != 'override';
      final merged = <String, dynamic>{...fresh.state};
      for (final entry in mutations.entries) {
        if (useReducer && entry.key == reducerKey) {
          merged[entry.key] = reducers.apply(
            reducerName,
            merged[entry.key],
            entry.value,
          );
        } else {
          merged[entry.key] = entry.value;
        }
      }
      await repository.updateRunState(runId, merged);
    } finally {
      completer.complete();
      if (_stateLocks[runId] == completer.future) {
        unawaited(_stateLocks.remove(runId));
      }
    }
  }

  Future<void> _completeRun(PipelineRun run) async {
    final now = DateTime.now();
    final updated = run.copyWith(
      status: PipelineRunStatus.completed,
      finishedAt: now,
      // Fold the live segment and stop the active-time clock (PRD 25 §6).
      activeMs: _foldedActiveMs(run, now),
      lastResumedAt: null,
    );
    await repository.updateRun(updated);
    _clearRunBookkeeping(run.id);
    eventBus.publish(
      PipelineRunCompleted(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        occurredAt: DateTime.now(),
      ),
    );
    await _admitNext(run.workspaceId, run.templateId);
  }

  Future<void> _failStep({
    required PipelineRun run,
    required String stepRunId,
    required String stepId,
    required String error,
    String? stackTrace,
    String? outputJson,
  }) async {
    stepProcessRegistry.unregister(stepRunId);
    await repository.updateStepRun(
      run.workspaceId,
      stepRunId,
      status: PipelineStepStatus.failed,
      errorMessage: error,
      errorStackTrace: stackTrace,
      outputJson: outputJson,
      finishedAt: DateTime.now(),
    );

    final now = DateTime.now();
    final updated = run.copyWith(
      status: PipelineRunStatus.failed,
      finishedAt: now,
      // Fold the live segment and stop the active-time clock (PRD 25 §6).
      activeMs: _foldedActiveMs(run, now),
      lastResumedAt: null,
      errorMessage: error,
      errorStackTrace: stackTrace,
    );
    await repository.updateRun(updated);
    _clearRunBookkeeping(run.id);
    eventBus.publish(
      PipelineRunFailed(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        errorMessage: error,
        occurredAt: DateTime.now(),
      ),
    );

    // The run is terminal now, so any sibling branch still in flight is
    // orphaned — nothing downstream will ever finish its row. Close them out
    // rather than leaving them stuck on "Running" with a ticking timer.
    await _cancelOpenSteps(
      run.workspaceId,
      run.id,
      reason: 'Cancelled: the run stopped on step $stepId',
    );
    await _admitNext(run.workspaceId, run.templateId);
  }

  void _track(Future<void> f) {
    _inFlight.add(f);
    f.whenComplete(() => _inFlight.remove(f));
  }

  /// Snapshots the body's input — config metadata, the rendered prompt with
  /// `{{key}}` placeholders substituted, the values of the keys listed in
  /// `inputKeys` and the trigger payload. Stored on the step run so the
  /// run-detail card can show what the body actually saw.
  String _encodeInputSnapshot(
    PipelineStepDefinition stepDef,
    PipelineContext ctx,
  ) {
    final config = stepDef.config;
    final inputs = <String, dynamic>{};
    for (final key in config.inputKeys) {
      final v = ctx.state[key] ?? ctx.triggerPayload?[key];
      if (v != null) {
        inputs[key] = _redactSecret(key, v);
      }
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
    // A terminal run re-fires nothing; `_cancelOpenSteps` closes whatever rows
    // were still being held.
    _resumableSteps.remove(runId);
  }

  static final RegExp _secretKeyPattern = RegExp(
    r'(token|secret|password|passwd|apikey|api_key|authorization|credential|private_key)',
    caseSensitive: false,
  );

  /// Redacts values whose key name looks secret, so the persisted input
  /// snapshot never writes credentials to disk in cleartext.
  static Object? _redactSecret(String key, Object? value) {
    if (_secretKeyPattern.hasMatch(key)) {
      return '***redacted***';
    }
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
