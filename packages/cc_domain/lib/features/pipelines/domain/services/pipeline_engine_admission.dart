part of 'pipeline_engine.dart';

/// Admission and queueing: a start's parent-link and requester checks, the
/// `maxParallelRuns` cap (counted and written under the cap lock), and
/// promoting the oldest queued run when a slot frees.
extension _PipelineAdmission on PipelineEngine {
  /// A child run's parent link must name a live `flow.callPipeline` step of a
  /// run in the same workspace that is waiting on it. The link is what
  /// [resumeChildFlow] follows to merge the child's result into the parent and
  /// re-fire its downstream steps, and the parent's requester is what the
  /// child inherits, so a forged one would let any caller write into — and
  /// borrow the access of — another run.
  Future<void> _requireValidParentLink({
    required String workspaceId,
    required String? parentPipelineRunId,
    required String? parentStepId,
  }) async {
    if (parentPipelineRunId == null && parentStepId == null) {
      return;
    }
    if (parentPipelineRunId == null ||
        parentPipelineRunId.isEmpty ||
        parentStepId == null ||
        parentStepId.isEmpty) {
      throw const ValidationException(
        'A sub-pipeline needs both a parent run and a parent step',
      );
    }
    final parent = await repository.getRun(parentPipelineRunId);
    if (parent == null || parent.workspaceId != workspaceId) {
      throw const ValidationException('Parent pipeline run not found');
    }
    if (parent.isTerminal) {
      throw const ValidationException('Parent pipeline run has finished');
    }
    final step = parent.templateSnapshot?.step(parentStepId);
    if (step == null || step.bodyKey != BuiltInBodyKeys.callFlow) {
      throw const ValidationException(
        'Parent step is not a sub-pipeline (flow.callPipeline) step',
      );
    }
    final stepRuns = await repository.stepRunsForPipeline(parent.id);
    final waiting = stepRuns.any(
      (sr) =>
          sr.stepId == parentStepId &&
          (sr.status == PipelineStepStatus.running ||
              sr.status == PipelineStepStatus.suspended),
    );
    if (!waiting) {
      throw const ValidationException(
        'Parent step is not waiting on a sub-pipeline',
      );
    }
  }

  /// [payload] with [kPipelineRequestedByKey] set from [requestedByUserId]
  /// and [kPipelineArmedByKey] from [armedByUserIds] (or the parent run's,
  /// for a sub-pipeline) and never from the payload itself: a trigger's
  /// inputs, a webhook body or a client argument must not be able to name
  /// whose access a run borrows, or who may approve what it opens.
  Future<Map<String, dynamic>?> _withRequester(
    Map<String, dynamic>? payload, {
    required String? requestedByUserId,
    required Set<String> armedByUserIds,
    required String? parentPipelineRunId,
    required String workspaceId,
  }) async {
    var requester = requestedByUserId ?? '';
    final armers = {
      for (final id in armedByUserIds)
        if (id.isNotEmpty) id,
    };
    if (parentPipelineRunId != null && (requester.isEmpty || armers.isEmpty)) {
      final parent = await repository.getRun(parentPipelineRunId);
      final inherited = parent != null && parent.workspaceId == workspaceId
          ? parent.triggerPayload ?? const <String, dynamic>{}
          : const <String, dynamic>{};
      final theirRequester = inherited[kPipelineRequestedByKey];
      if (requester.isEmpty && theirRequester is String) {
        requester = theirRequester;
      }
      if (armers.isEmpty) {
        armers.addAll(pipelineArmedByOf(inherited));
      }
    }
    const keys = {kPipelineRequestedByKey, kPipelineArmedByKey};
    final hasKey = keys.any((k) => payload?.containsKey(k) ?? false);
    if (!hasKey && requester.isEmpty && armers.isEmpty) {
      return payload;
    }
    return {...?payload}
      ..removeWhere((k, _) => keys.contains(k))
      ..addAll({
        if (requester.isNotEmpty) kPipelineRequestedByKey: requester,
        if (armers.isNotEmpty) kPipelineArmedByKey: armers.toList()..sort(),
      });
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
      templateSnapshot: definition,
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
      _runStep(
        run: run,
        definition: definition,
        stepDef: pipelineStartStep(
          definition,
          triggerEventType: run.triggerEventType,
        ),
      ),
    );
    return run;
  }

  /// Runs [action] serialized against every other cap decision for
  /// `(workspaceId, templateId)`. See [_capLocks].
  Future<T> _withCapLock<T>(
    String workspaceId,
    String templateId,
    Future<T> Function() action,
  ) => _capLocks.run('$workspaceId|$templateId', action);

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
        final live = await templates.getById(workspaceId, templateId);
        if (live == null || !live.isEnabled) {
          // The template was deleted or switched off while these runs waited.
          // None of them can ever start, and a deleted template will never
          // produce the completion that would drain them one at a time — so
          // close out the whole queue here rather than stranding it.
          final reason = live == null
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
        // The cap is the template's current setting; the graph the run
        // executes is the one it was pinned to when it was queued.
        final definition = next.templateSnapshot;
        if (definition == null) {
          await _cancelQueuedRun(
            next,
            reason: 'Run ${next.id} has no pinned template snapshot.',
          );
          // The next queued run still waits for a slot this one never took.
          _track(_admitNext(workspaceId, templateId));
          return null;
        }
        final cap = live.maxParallelRuns;
        if (cap != null) {
          final active = await repository.activeRunCountForTemplate(
            workspaceId: workspaceId,
            templateId: templateId,
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
                  stepDef: pipelineStartStep(
                    definition,
                    triggerEventType: started.triggerEventType,
                  ),
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
}
