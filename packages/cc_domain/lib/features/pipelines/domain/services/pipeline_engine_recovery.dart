part of 'pipeline_engine.dart';

/// Recovery: re-attaching in-flight runs after a restart, resuming suspended
/// steps and child flows (one resume per step under its lock) and re-running a
/// stopped run from where it stopped.
extension _PipelineRecovery on PipelineEngine {
  /// Body of [PipelineEngine.resumeAll].
  Future<void> _resumeAll() async {
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
      // A run that holds no pinned graph cannot be continued by anyone: left
      // as it is, it would read "running" forever and keep a slot of its
      // template's parallel cap. Queued ones are cancelled by admission.
      if (staleRun.templateSnapshot == null) {
        await _failRun(
          staleRun,
          'This run no longer holds the pipeline definition it started '
          'with, so it cannot continue. Start it again.',
        );
        continue;
      }
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
      final definition = staleRun.templateSnapshot!;

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
        // (running/suspended) might have completed its side effect (e.g. a
        // workspace backup) before the crash. Re-running could double-apply it,
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

  /// Runs [action] serialized against every other resume of `(runId, stepId)`.
  /// See [_resumeLocks].
  Future<void> _withResumeLock(
    String runId,
    String stepId,
    Future<void> Function() action,
  ) => _resumeLocks.run('$runId/$stepId', action);

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
    // doesn't say "suspended" while the agent is actively working. Non-task
    // suspensions use `suspended`; accept both. A step
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
    final definition = await _definitionFor(run);
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
    final definition = await _definitionFor(run);
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

  /// Body of [PipelineEngine.retry].
  Future<void> _retry(String workspaceId, String pipelineRunId) async {
    final run = await repository.getRun(pipelineRunId);
    if (run == null) {
      return;
    }
    if (run.status != PipelineRunStatus.failed &&
        run.status != PipelineRunStatus.cancelled) {
      return;
    }

    final definition = await _definitionFor(run);
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
          stepDef: pipelineStartStep(
            definition,
            triggerEventType: run.triggerEventType,
          ),
        ),
      );
      return;
    }

    for (final sr in toRerun) {
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
}
