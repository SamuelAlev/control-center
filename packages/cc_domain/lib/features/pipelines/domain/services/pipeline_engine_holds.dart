part of 'pipeline_engine.dart';

/// Steps that settle from outside a dispatched run (`goal.pursue`), and the
/// budget hold: a run whose owner's cap is reached is suspended before its
/// next step is dispatched, and resumed when the cap allows it again.
extension _PipelineHolds on PipelineEngine {
  /// Writes the suspended row of [stepRunId] (kept `running`, see
  /// [_runStep]) unless it already settled: a step settled from outside
  /// (`goal.pursue`) can finish between its body's return and this write,
  /// and the write must not reopen it. Serialised with
  /// [_settleSuspended] by the resume lock.
  Future<void> _writeSuspended(
    PipelineRun run,
    String stepId,
    String stepRunId,
    Map<String, dynamic> mutations,
  ) => _withResumeLock(run.id, stepId, () async {
    final row = await repository.getStepRunById(run.workspaceId, stepRunId);
    if (row != null &&
        row.status != PipelineStepStatus.pending &&
        row.status != PipelineStepStatus.running &&
        row.status != PipelineStepStatus.suspended) {
      return;
    }
    await repository.updateStepRun(
      run.workspaceId,
      stepRunId,
      status: PipelineStepStatus.running,
      outputJson: mutations.isEmpty ? null : jsonEncode(mutations),
    );
  });

  /// Settles the open row of [stepId] in [pipelineRunId] with what
  /// [outcome] makes of the step's definition: a failure goes through the
  /// step-failure path (retry, `continueOnFail`); an ok result is validated
  /// against the node's contract, merged and completes the step. False when there is nothing to settle (the run is
  /// not in [workspaceId], is terminal, or the step has no open row).
  Future<bool> _settleSuspended({
    required String workspaceId,
    required String pipelineRunId,
    required String stepId,
    required StepResult Function(PipelineStepDefinition step) outcome,
  }) async {
    var settled = false;
    await _withResumeLock(pipelineRunId, stepId, () async {
      final run = await repository.getRun(pipelineRunId);
      if (run == null || run.workspaceId != workspaceId || run.isTerminal) {
        return;
      }
      final definition = await _definitionFor(run);
      final stepDef = definition?.step(stepId);
      if (definition == null || stepDef == null) {
        return;
      }
      final open = (await repository.stepRunsForPipeline(pipelineRunId))
          .where(
            (sr) =>
                sr.stepId == stepId &&
                (sr.status == PipelineStepStatus.running ||
                    sr.status == PipelineStepStatus.suspended),
          )
          .toList();
      if (open.isEmpty) {
        return;
      }
      final row = open.reduce(
        (a, b) => b.startedAt.isAfter(a.startedAt) ? b : a,
      );
      settled = true;
      stepProcessRegistry.unregister(row.id);
      final result = outcome(stepDef);
      if (result.isFailed) {
        if (stepDef.bodyKey == kGoalPursueBodyKey) {
          // The goal ended: a retry of the step starts a new one instead of
          // re-attaching to it.
          await _mergeState(pipelineRunId, {
            goalPursueStateKey(stepId): null,
          });
        }
        await _handleStepFailure(
          run: run,
          definition: definition,
          stepDef: stepDef,
          stepRunId: row.id,
          error: result.errorMessage ?? 'step failed',
        );
        return;
      }
      final mutations = <String, dynamic>{...?result.mutatedState};
      final violations = _validateOutput(stepDef, mutations);
      if (violations.isNotEmpty) {
        await _handleStepFailure(
          run: run,
          definition: definition,
          stepDef: stepDef,
          stepRunId: row.id,
          error: 'Output schema violation: ${violations.join('; ')}',
          outputJson: jsonEncode({
            'error': 'Output schema violation',
            'violations': violations,
            'invalidOutput': mutations,
          }),
        );
        return;
      }
      if (mutations.isNotEmpty) {
        await _mergeState(pipelineRunId, mutations, producer: stepDef);
      }
      await repository.updateStepRun(
        workspaceId,
        row.id,
        status: PipelineStepStatus.completed,
        outputJson: mutations.isEmpty ? null : jsonEncode(mutations),
        finishedAt: DateTime.now(),
      );
      final latest = await repository.getRun(pipelineRunId) ?? run;
      await _evaluateDownstream(
        run: latest,
        definition: definition,
        completedStepIds: {stepId},
      );
    });
    return settled;
  }

  /// True when [run] must hold instead of dispatching a step: the budget
  /// gate found its cap reached. The first hold suspends the run, records
  /// [kBudgetHoldStateKey] and tells the gate (once); a later check of a
  /// held run that may continue lifts the hold.
  Future<bool> _heldByBudget(PipelineRun run) async {
    final gate = _budgetGate;
    if (gate == null || run.dryRun) {
      return false;
    }
    final hold = await gate.check(run);
    if (hold == null) {
      if (run.state.containsKey(kBudgetHoldStateKey) ||
          run.status == PipelineRunStatus.suspended) {
        await _liftHold(run.id);
      }
      return false;
    }
    PipelineRun? first;
    await _stateLocks.run(run.id, () async {
      final fresh = await repository.getRun(run.id);
      if (fresh == null || fresh.isTerminal) {
        return;
      }
      if (!fresh.state.containsKey(kBudgetHoldStateKey)) {
        await repository.updateRunState(run.id, {
          ...fresh.state,
          kBudgetHoldStateKey: hold.toJson(),
        });
        first = fresh;
      }
      if (fresh.status != PipelineRunStatus.suspended) {
        final latest = await repository.getRun(run.id) ?? fresh;
        await repository.updateRun(
          latest.copyWith(status: PipelineRunStatus.suspended),
        );
      }
    });
    final held = first;
    if (held != null) {
      try {
        await gate.onHeld(held, hold);
      } on Object catch (e, st) {
        CcDomainLog.error('PipelineEngine: telling about a hold failed', e, st);
      }
    }
    return true;
  }

  /// Removes the hold of [runId]: the reserved key goes and a suspended
  /// run is `running` again.
  Future<void> _liftHold(String runId) => _stateLocks.run(runId, () async {
    final fresh = await repository.getRun(runId);
    if (fresh == null || fresh.isTerminal) {
      return;
    }
    if (fresh.state.containsKey(kBudgetHoldStateKey)) {
      await repository.updateRunState(
        runId,
        Map.of(fresh.state)..remove(kBudgetHoldStateKey),
      );
    }
    if (fresh.status == PipelineRunStatus.suspended) {
      final latest = await repository.getRun(runId) ?? fresh;
      await repository.updateRun(
        latest.copyWith(status: PipelineRunStatus.running),
      );
    }
  });

  /// Resumes [pipelineRunId] in [workspaceId] if it is held and its gate
  /// now lets it continue: the hold is lifted and the steps it held are
  /// offered again. False when it is not held, not in [workspaceId], or
  /// still at its cap.
  Future<bool> _resumeHeld(String workspaceId, String pipelineRunId) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null ||
        run.workspaceId != workspaceId ||
        run.isTerminal ||
        run.status != PipelineRunStatus.suspended ||
        !run.state.containsKey(kBudgetHoldStateKey)) {
      return false;
    }
    final gate = _budgetGate;
    if (gate != null && await gate.check(run) != null) {
      return false;
    }
    await _liftHold(pipelineRunId);
    final latest = await repository.getRun(pipelineRunId) ?? run;
    final definition = await _definitionFor(latest);
    if (definition == null) {
      return true;
    }
    final rows = await repository.stepRunsForPipeline(pipelineRunId);
    if (rows.isEmpty) {
      // Held before its first step: start it again.
      _track(
        _runStep(
          run: latest,
          definition: definition,
          stepDef: pipelineStartStep(
            definition,
            triggerEventType: latest.triggerEventType,
          ),
        ),
      );
      return true;
    }
    final completed = <String>{
      for (final sr in rows)
        if (sr.status == PipelineStepStatus.completed) sr.stepId,
    };
    await _evaluateDownstream(
      run: latest,
      definition: definition,
      completedStepIds: completed,
    );
    return true;
  }
}
