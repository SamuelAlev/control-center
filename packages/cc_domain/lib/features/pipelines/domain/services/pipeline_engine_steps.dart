part of 'pipeline_engine.dart';

/// Step execution: resolving the pinned graph, running one step body under
/// the concurrency permit with retries and output validation, and turning a
/// failure into a skip, a retry or a failed step.
extension _PipelineStepExecution on PipelineEngine {
  /// The graph [run] executes: the snapshot pinned when it started, or — for
  /// a run that predates snapshots — the live template.
  Future<PipelineDefinition?> _definitionFor(PipelineRun run) async {
    final pinned = run.templateSnapshot;
    if (pinned != null) {
      return pinned;
    }
    final live = await templates.getById(run.workspaceId, run.templateId);
    if (live != null && live.version != run.templateVersion) {
      CcDomainLog.warning(
        'PipelineEngine: Run ${run.id} predates template snapshots and pinned '
        '${run.templateId} v${run.templateVersion}; the live template is now '
        'v${live.version}, so it continues against the live graph.',
      );
    }
    return live;
  }

  Future<PipelineDefinition> _requireTemplate(
    String workspaceId,
    String templateId,
  ) async {
    final def = await templates.getById(workspaceId, templateId);
    if (def == null) {
      throw PipelineTemplateNotFoundError(
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

    final permit = _StepPermit(_slots);
    final ctx = PipelineContext(
      pipelineRunId: current.id,
      templateId: current.templateId,
      stepId: stepDef.id,
      stepRunId: stepRunId,
      workspaceId: current.workspaceId,
      state: Map<String, dynamic>.from(current.state),
      triggerPayload: current.triggerPayload,
      dryRun: current.dryRun,
      definition: definition,
      step: stepDef,
      // Lets a body hand its concurrency permit back while it is idle-waiting.
      // See [PipelineContext.whileWaiting].
      idleRunner: permit.whileWaiting,
    );

    // Snapshot the input so the run-detail card can show what the body saw —
    // rendered prompt, resolved inputKeys values and the trigger payload.
    await repository.updateStepRun(
      current.workspaceId,
      stepRunId,
      inputJson: encodePipelineInputSnapshot(stepDef, ctx),
    );

    // ── Attempt loop: retry synchronous failures per the node policy ────
    final policy = config.retryPolicy;
    final maxAttempts = policy?.maxAttempts ?? 1;
    StepResult? result;
    String lastError = 'unknown error';
    String? lastStack;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final bodyFn = bodies.body(stepDef.bodyKey);
        final StepResult r;
        _executingStepRuns.add(stepRunId);
        try {
          r = await _invokeBody(
            bodyFn,
            ctx,
            config.timeoutMs,
            stepRunId,
            permit,
          );
        } finally {
          _executingStepRuns.remove(stepRunId);
        }

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
  ///
  /// The body's permit is [permit], which the body's
  /// [PipelineContext.whileWaiting] hands back and re-takes. Ending the
  /// attempt releases it only if it is still held, so a timeout that fires
  /// while the body sits in `whileWaiting` cannot release a permit the body had
  /// already given back.
  Future<StepResult> _invokeBody(
    StepBodyFn bodyFn,
    PipelineContext ctx,
    int? timeoutMs,
    String stepRunId,
    _StepPermit permit,
  ) async {
    await permit.begin();
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
      permit.end();
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
    // Publish a failure marker under the step's output key. Downstream steps
    // that template `{{<outputKey>}}` are exactly the ones continueOnFail keeps
    // alive; without the key they failed on an unresolved placeholder instead
    // of seeing — and reporting — the upstream failure. Same `{failed: true}`
    // shape the orchestration join writes for a node that produced nothing.
    final outputKey = stepDef.config.outputKey;
    await _mergeState(run.id, {
      kStepErrorsKey: errors,
      if (outputKey != null &&
          outputKey.isNotEmpty &&
          fresh.state[outputKey] == null)
        outputKey: {'failed': true, 'error': error},
    });
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
}

/// One step invocation's hold on a [_Semaphore] permit, across the body's
/// [PipelineContext.whileWaiting] hand-backs and its retry attempts.
///
/// The permit is tracked, not assumed: [end] releases only a permit that is
/// actually held, and a `whileWaiting` that returns after its attempt ended (a
/// node timeout fired while the body was idle) does not re-take one. A
/// timed-out idle body used to release a permit it had already handed back
/// and later re-take one nobody released, which only cancelled out by luck.
final class _StepPermit {
  _StepPermit(this._slots);

  final _Semaphore _slots;
  int _attempt = 0;
  bool _open = false;
  bool _held = false;

  /// Starts an attempt and takes a permit for it.
  Future<void> begin() async {
    _attempt++;
    _open = true;
    await _slots.acquire();
    _held = true;
  }

  /// Ends the current attempt, releasing its permit if it still holds one.
  void end() {
    _open = false;
    if (_held) {
      _held = false;
      _slots.release();
    }
  }

  /// Runs [action] without the permit, re-taking it afterwards (even on
  /// throw) unless the attempt ended meanwhile.
  Future<T> whileWaiting<T>(Future<T> Function() action) async {
    final attempt = _attempt;
    final gaveBack = _open && _held;
    if (gaveBack) {
      _held = false;
      _slots.release();
    }
    try {
      return await action();
    } finally {
      if (gaveBack && _open && _attempt == attempt) {
        await _slots.acquire();
        if (_open && _attempt == attempt && !_held) {
          _held = true;
        } else {
          // The attempt ended while this waited for a permit.
          _slots.release();
        }
      }
    }
  }
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
