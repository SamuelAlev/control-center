part of 'pipeline_engine.dart';

/// Downstream and finish: firing the steps a completed step unblocks,
/// merging state, and the one terminal path ([_finish]) that cancels open
/// steps and clears the run's bookkeeping.
extension _PipelineDownstream on PipelineEngine {
  /// Stops and closes out every step row of [pipelineRunId] that is still open
  /// (pending / running / suspended). Call this immediately after flipping a run
  /// terminal.
  /// Once the run is terminal, an open step row is orphaned: [resumeStep],
  /// [resumeAll] and `_evaluateDownstreamLocked` all bail on a terminal run, so
  /// nothing will ever finish it. Left behind it reads "Running" forever, its
  /// live-duration timer ticks without bound (inflating the waterfall's idle
  /// gap) and its kill callback leaks in [StepProcessRegistry].
  /// Parallel branches are the common case: a fan-out is N sibling step rows
  /// listening on the same source, so stopping (or failing) one of them takes
  /// the run terminal out from under all the others.
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

  /// Fails an entire run without attributing the failure to a specific step
  /// run (used by the loop/recursion guard).
  Future<void> _failRun(PipelineRun run, String error) async {
    if (run.isTerminal) {
      return;
    }
    await _finish(run, PipelineRunStatus.failed, error: error);
  }

  /// The one way an admitted run becomes terminal.
  ///
  /// Stops the active-time clock, drops the run's in-memory bookkeeping,
  /// announces the transition, closes every step row still open — a terminal
  /// run is never revisited, so an open row would read "Running" forever and
  /// leak its kill callback — and frees the run's `maxParallelRuns` slot.
  /// Completing, failing and cancelling used to each do a different subset of
  /// that.
  Future<void> _finish(
    PipelineRun run,
    PipelineRunStatus status, {
    String? error,
    String? stackTrace,
    String? openStepReason,
  }) async {
    assert(status.isTerminal, 'not a terminal status: $status');
    final now = DateTime.now();
    final failed = status == PipelineRunStatus.failed;
    await repository.updateRun(
      run.copyWith(
        status: status,
        finishedAt: now,
        // Fold the live segment and stop the active-time clock (PRD 25 §6).
        activeMs: _foldedActiveMs(run, now),
        lastResumedAt: null,
        errorMessage: failed ? error : run.errorMessage,
        errorStackTrace: failed ? stackTrace : run.errorStackTrace,
      ),
    );
    _clearRunBookkeeping(run.id);
    eventBus.publish(switch (status) {
      PipelineRunStatus.completed => PipelineRunCompleted(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        occurredAt: now,
      ),
      PipelineRunStatus.failed => PipelineRunFailed(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        errorMessage: error ?? 'Pipeline run failed',
        occurredAt: now,
      ),
      _ => PipelineRunCancelled(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        templateId: run.templateId,
        occurredAt: now,
      ),
    });
    await _cancelOpenSteps(
      run.workspaceId,
      run.id,
      reason:
          openStepReason ??
          switch (status) {
            PipelineRunStatus.completed => 'Cancelled: the run completed',
            PipelineRunStatus.failed => 'Cancelled: the run failed',
            _ => 'Run cancelled',
          },
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
    await _evalLocks.run(
      run.id,
      () => _evaluateDownstreamLocked(
        run: run,
        definition: definition,
        completedStepIds: completedStepIds,
      ),
    );
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
    existing.addAll(_scheduledSteps[current.id] ?? const <String>{});

    final plan = planDownstream(
      definition: definition,
      completed: completed,
      skipped: skipped,
      existing: existing,
      chosenRoutes: chosenRoutes,
      resumable: resumable.keys.toSet(),
      startStepId: pipelineStartStep(
        definition,
        triggerEventType: current.triggerEventType,
      ).id,
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
      final claims = _scheduledSteps.putIfAbsent(current.id, () => {})
        ..add(stepId);
      _track(
        _runStep(
          run: current,
          definition: definition,
          stepDef: stepDef,
          existingStepRunId: held,
        ).whenComplete(() {
          claims.remove(stepId);
          if (claims.isEmpty &&
              identical(_scheduledSteps[current.id], claims)) {
            _scheduledSteps.remove(current.id);
          }
        }),
      );
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
    await _stateLocks.run(runId, () async {
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
    });
  }

  Future<void> _completeRun(PipelineRun run) =>
      _finish(run, PipelineRunStatus.completed);

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

    // The run is terminal now, so any sibling branch still in flight is
    // orphaned — nothing downstream will ever finish its row. [_finish] closes
    // them out rather than leaving them stuck on "Running".
    await _finish(
      run,
      PipelineRunStatus.failed,
      error: error,
      stackTrace: stackTrace,
      openStepReason: 'Cancelled: the run stopped on step $stepId',
    );
  }
}

/// Accumulated active milliseconds for [run] as of [now] (PRD 25 §6): the
/// persisted [PipelineRun.activeMs] plus the currently-running segment
/// (`now - lastResumedAt`). Called at a stop to fold the live segment into
/// `activeMs` before clearing `lastResumedAt`, so idle stop→restart gaps
/// never enter the total.
int _foldedActiveMs(PipelineRun run, DateTime now) {
  final resumed = run.lastResumedAt;
  if (resumed == null) {
    return run.activeMs;
  }
  final live = now.difference(resumed).inMilliseconds;
  return live > 0 ? run.activeMs + live : run.activeMs;
}
