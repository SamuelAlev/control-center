part of 'environment_service.dart';

/// Reacting to the world: events, polling, idle stop, and coming back at boot.
mixin _LifecycleOps
    on
        _EnvironmentServiceBase,
        _DefinitionOps,
        _ComponentOps,
        _StackOps,
        _EnsureOps,
        _OperationOps,
        _WorktreeOps {
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<String, DateTime> _lastPoll = {};
  Timer? _timer;
  bool _maintaining = false;
  bool _warnedNoActivity = false;

  /// Subscribes to the lifecycle events, starts maintenance, then recovers.
  ///
  /// Listeners come first so nothing published during recovery is missed, and
  /// a recovery that fails still leaves the service running. [runRecovery] is
  /// false only where the processes already belong to this server.
  Future<void> start({bool runRecovery = true}) async {
    if (_timer != null) {
      return;
    }
    final events = _d.events;
    _guarded(events.on<SpaceProvisioningChanged>(), _onProvisioned);
    _guarded(events.on<PrHeadChanged>(), _onHeadChanged);
    _guarded(events.on<SpaceArchived>(), _onArchived);
    _guarded(
      events.on<SpaceDeleted>(),
      (event) => beforeRelease(event.workspaceId, event.spaceId),
    );
    _guarded(_d.supervisor.states, _onProcessState);
    _guarded(_d.supervisor.exits, _onProcessExit);
    _timer = Timer.periodic(
      _d.maintenanceInterval,
      (_) => unawaited(runMaintenance()),
    );
    if (runRecovery) {
      try {
        await recover();
      } on Object catch (e, st) {
        CcInfraLog.error('environment recovery failed', e, st);
      }
    }
  }

  /// Stops listening. Environments keep running.
  Future<void> stopListening() async {
    _timer?.cancel();
    _timer = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _guarded<T>(Stream<T> stream, Future<void> Function(T event) handler) {
    _subscriptions.add(
      stream.listen((event) {
        unawaited(
          handler(event).catchError((Object e, StackTrace st) {
            CcInfraLog.error('environment listener failed', e, st);
          }),
        );
      }),
    );
  }

  Future<void> _onProvisioned(SpaceProvisioningChanged event) async {
    if (event.status != SpaceProvisioningStatus.ready) {
      return;
    }
    final ws = event.workspaceId;
    final space = await _space(ws, event.spaceId);
    for (final row in await _d.environments.forSpace(ws, space.id)) {
      await _reconcileRepos(row);
    }
    for (final loaded in await _eligible(space)) {
      final mode = loaded.definition.policy.autoCreate;
      final wanted =
          mode == EnvironmentAutoCreate.allSpaces ||
          (mode == EnvironmentAutoCreate.prSpaces && space.prNumber != null);
      if (wanted) {
        try {
          await _ensureIn(
            space,
            loaded,
            const {},
            _EnvironmentServiceBase._system,
          );
        } on Exception catch (e) {
          // A refusal here is policy working, with nobody to tell but the log.
          CcInfraLog.warning('auto-create in ${space.id} did not start: $e');
        }
      }
    }
  }

  Future<void> _onHeadChanged(PrHeadChanged event) async {
    final sync = _d.syncWorktree;
    final ws = event.workspaceId;
    final repo = '${event.repoOwner}/${event.repoName}';
    final rows = await _d.environments.list(ws);
    bool isHost(SpaceEnvironment row) =>
        row.placement == EnvironmentPlacement.host.name;
    // Host rows first: a rig in the same space may sync the worktree they share.
    for (final row in [
      ...rows.where(isHost),
      ...rows.where((row) => !isHost(row)),
    ]) {
      if (!row.status.isRunning) {
        continue;
      }
      final EnvironmentSpaceInfo space;
      final _Loaded loaded;
      try {
        space = await _space(ws, row.spaceId);
        loaded = await _load(ws, row.definitionId);
      } on Exception catch (e) {
        CcInfraLog.warning('PR head change skipped ${row.id}: $e');
        continue;
      }
      if (space.prNumber != event.prNumber || space.prRepo != repo) {
        continue;
      }
      if (space.isFork && row.placement == EnvironmentPlacement.host.name) {
        // New code nobody approved. Syncing it would run it on the host.
        await _exclusive(
          _lockOf(row),
          () => _holdForApproval(
            row,
            EnvironmentError(
              code: 'fork-needs-approval',
              message:
                  'The fork PR moved to ${event.headSha}. It was stopped, and '
                  'an admin has to start it again',
            ),
          ),
        );
        continue;
      }
      if (!loaded.definition.policy.followPrHead) {
        continue;
      }
      if (sync == null) {
        CcInfraLog.warning('no worktree sync is wired: PR head change ignored');
        continue;
      }
      await _exclusive(_lockOf(row), () async {
        final changed = await sync(
          workspaceId: ws,
          spaceId: row.spaceId,
          headSha: event.headSha,
        );
        if (changed == null) {
          CcInfraLog.info(
            'worktree of ${row.spaceId} is not clean: not synced',
          );
          return;
        }
        await _applyChange(row, changed, quiet: true);
      });
    }
  }

  /// Stops a fork PR's environment that lost its admission, and says why.
  Future<void> _holdForApproval(
    SpaceEnvironment env,
    EnvironmentError why,
  ) async {
    await _revokeApproval(env);
    await _stopLocked(env);
    await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(lastError: why),
    );
  }

  /// The supervisor's gate: a restart runs what is in the worktree now, so on
  /// a fork's host environment it is an entry like any other.
  ///
  /// A start in flight was admitted a moment ago and holds the head still,
  /// and its approval is written only when it finishes. Not awaited past the
  /// refusal: whoever holds the lock may be waiting for this very process.
  Future<void> _admitRespawn(EnvironmentProcessSpec spec) async {
    final env = await _d.environments.get(spec.workspaceId, spec.environmentId);
    if (env == null) {
      throw _EnvironmentServiceBase._failure(
        'not-running',
        'This environment no longer exists',
      );
    }
    if (_ensures.containsKey(_lockOf(env))) {
      return;
    }
    try {
      await _readmit(
        env,
        await _space(env.workspaceId, env.spaceId),
        _EnvironmentServiceBase._system,
      );
    } on EnvironmentDriverException {
      unawaited(
        _holdUnlessAdmitted(env).catchError((Object e, StackTrace st) {
          CcInfraLog.error('holding ${env.id} failed', e, st);
        }),
      );
      rethrow;
    }
  }

  /// Decided again under the lock: an admin may have started it since.
  Future<void> _holdUnlessAdmitted(SpaceEnvironment env) =>
      _exclusive(_lockOf(env), () async {
        final row = await _d.environments.get(env.workspaceId, env.id);
        if (row == null || !row.status.isRunning) {
          return;
        }
        try {
          await _readmit(
            row,
            await _space(row.workspaceId, row.spaceId),
            _EnvironmentServiceBase._system,
          );
        } on EnvironmentDriverException catch (e) {
          await _holdForApproval(row, e.error);
        }
      });

  Future<void> _onArchived(SpaceArchived event) async {
    final ws = event.workspaceId;
    for (final row in await _d.environments.forSpace(ws, event.spaceId)) {
      if (row.status.isRunning) {
        await _stopIfSafe(row, 'Space archived, still running');
      }
    }
    // Leases go with the archive, except under what still runs: those ports
    // are in use, and moving them would pull them out from under it.
    final running = {
      for (final row in await _d.environments.forSpace(ws, event.spaceId))
        if (row.status.isRunning || row.status.isBusy) row.definitionId,
    };
    for (final lease in await _d.leases.all()) {
      if (lease.workspaceId == ws &&
          lease.spaceId == event.spaceId &&
          !running.contains(lease.definitionId)) {
        await _d.allocator.release(
          workspaceId: ws,
          spaceId: event.spaceId,
          definitionId: lease.definitionId,
        );
      }
    }
  }

  /// Stops [env] unless that would lose data or close someone's window.
  Future<void> _stopIfSafe(
    SpaceEnvironment env,
    String? otherwise, {
    Future<bool> Function(SpaceEnvironment row)? still,
  }) => _exclusive(_lockOf(env), () async {
    // Read again under the lock: a start or a stop may have got there first.
    final row = await _d.environments.get(env.workspaceId, env.id);
    if (row == null || !row.status.isRunning) {
      return;
    }
    if (still != null && !await still(row)) {
      return;
    }
    await _stopIfSafeLocked(row, otherwise);
  });

  Future<void> _stopIfSafeLocked(
    SpaceEnvironment env,
    String? otherwise,
  ) async {
    final hasApp = env.components.any(
      (state) => state.kind == 'app' && state.state == 'running',
    );
    final definition = (await _load(
      env.workspaceId,
      env.definitionId,
    )).definition;
    if (hasApp || !definition.keepsDataOnStop) {
      if (otherwise != null) {
        await _update(
          env.workspaceId,
          env.id,
          (row) =>
              row.copyWith(warnings: {...row.warnings, otherwise}.toList()),
        );
      }
      return;
    }
    await _stopLocked(env);
  }

  Future<void> _onProcessState(EnvironmentProcessStateChange change) async {
    final state = change.state;
    if (state.kind == 'app' &&
        const {'closed', 'crashed'}.contains(state.state)) {
      await _closeWindow(change.environmentId, state.id);
    }
    await _update(change.workspaceId, change.environmentId, (row) {
      final known = row.components.any((item) => item.id == state.id);
      if (!known) {
        return row;
      }
      final components = [
        for (final item in row.components)
          if (item.id != state.id)
            item
          else
            item.copyWith(
              state: state.state,
              detail: state.detail,
              restarts: state.restarts,
              sessionId: state.sessionId,
              lastExitCode: state.lastExitCode,
            ),
      ];
      return row.copyWith(
        components: components,
        status: _settledStatus(row.status, components),
      );
    });
  }

  /// A running stack with a process down is degraded, and ready again once it
  /// is back. Anything mid-mutation keeps the status its mutation set.
  EnvironmentStatus _settledStatus(
    EnvironmentStatus status,
    List<EnvironmentComponentState> components,
  ) {
    if (status != EnvironmentStatus.ready &&
        status != EnvironmentStatus.degraded) {
      return status;
    }
    final allUp = components
        .where((state) => state.kind == 'process')
        .every((state) => state.state == 'ready');
    return allUp ? EnvironmentStatus.ready : EnvironmentStatus.degraded;
  }

  Future<void> _onProcessExit(EnvironmentProcessExit exit) async {
    _d.events.publish(
      EnvironmentProcessExited(
        workspaceId: exit.workspaceId,
        spaceId: exit.spaceId,
        environmentId: exit.environmentId,
        componentId: exit.componentId,
        exitCode: exit.exitCode,
        occurredAt: _d.now(),
      ),
    );
  }

  /// One pass of status polling, idle stop and repo checks. Runs on a timer
  /// after [start]; a pass never overlaps another.
  @visibleForTesting
  Future<void> runMaintenance() async {
    if (_maintaining) {
      return;
    }
    _maintaining = true;
    try {
      for (final ws in await _d.directory.workspaceIds()) {
        for (final row in await _d.environments.list(ws)) {
          if (_locks.containsKey(_lockOf(row)) || row.status.isBusy) {
            continue;
          }
          try {
            await _maintain(row);
          } on Object catch (e) {
            CcInfraLog.warning('maintenance of ${row.id} failed: $e');
          }
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('environment maintenance failed: $e');
    } finally {
      _maintaining = false;
    }
  }

  Future<void> _maintain(SpaceEnvironment env) async {
    if (_testSpaces.containsKey(env.spaceId)) {
      return;
    }
    if (!await _spaceExists(env.workspaceId, env.spaceId)) {
      // Its space went without a release reaching it: nothing else will.
      await _exclusive(_lockOf(env), () => _teardown(env, force: true));
      return;
    }
    if (await _reconcileRig(env)) {
      return;
    }
    if (await _reconcileRepos(env)) {
      return;
    }
    if (_isPollDue(env)) {
      _lastPoll[env.id] = _d.now();
      await _poll(env);
    }
    if (env.status.isRunning) {
      await _stopIfIdle(env);
    }
  }

  bool _isPollDue(SpaceEnvironment env) {
    final watched = _watchers.containsKey('${env.workspaceId}/${env.spaceId}');
    final interval = watched ? _d.watchedPollInterval : _d.idlePollInterval;
    final last = _lastPoll[env.id];
    return last == null || _d.now().difference(last) >= interval;
  }

  /// Asks the tools and Docker how things stand, and records what changed.
  Future<void> _poll(SpaceEnvironment env) async {
    if (!env.status.isRunning && env.status != EnvironmentStatus.failed) {
      return;
    }
    if (env.placement != 'host') {
      return;
    }
    final stack = await _stackOf(env);
    var healthy = true;
    var missing = false;
    for (final component in stack.definition.components) {
      if (!stack.isEnabled(component)) {
        continue;
      }
      if (component is CliEnvironmentComponent) {
        final report = await _d.cli.status(_cliContext(stack, component));
        // A create that failed left the tool nothing to report on. The failure
        // says why, and what to do about it, so it stays until someone acts.
        if (env.status == EnvironmentStatus.failed &&
            report.state == EnvironmentReportedState.missing) {
          continue;
        }
        await _applyCliReport(env, component, report);
        missing |= report.state == EnvironmentReportedState.missing;
        healthy &= report.state == EnvironmentReportedState.ready;
      } else if (component is ComposeEnvironmentComponent) {
        final plan = await _planOf(env, stack, component);
        final services = await _d.compose.status(plan);
        healthy &= services.every((service) => service.isSettled);
        await _setComponent(
          env,
          component.id,
          (state) => state.copyWith(
            services: [for (final service in services) service.toJson()],
          ),
        );
      }
    }
    final row = await _update(env.workspaceId, env.id, (row) {
      if (row.status.isBusy) {
        return row;
      }
      if (row.status == EnvironmentStatus.failed) {
        return row;
      }
      if (missing) {
        return row.copyWith(status: EnvironmentStatus.gone);
      }
      return row.copyWith(
        status: healthy && !row.needsRecreate
            ? _settledStatus(EnvironmentStatus.ready, row.components)
            : EnvironmentStatus.degraded,
      );
    });
    if (row != null && row.status.isRunning) {
      await _applyRoutes(row, stack);
    }
  }

  Future<void> _stopIfIdle(SpaceEnvironment env) =>
      _stopIfSafe(env, null, still: _isIdle);

  /// Whether nothing has used [env] for `idleStopMinutes`: the environment
  /// itself, its runs, and what the activity probe knows (messages, terminal
  /// input, focused tabs). Without a probe, terminal input goes unseen.
  Future<bool> _isIdle(SpaceEnvironment env) async {
    final definition = (await _load(
      env.workspaceId,
      env.definitionId,
    )).definition;
    final minutes = definition.policy.idleStopMinutes;
    if (minutes <= 0 ||
        _watchers.containsKey('${env.workspaceId}/${env.spaceId}')) {
      return false;
    }
    var last = env.lastUsedAt;
    final runs = await _d.runs.forSpace(env.workspaceId, env.spaceId, limit: 1);
    for (final run in runs) {
      if (run.status == EnvironmentRunStatus.running) {
        return false;
      }
      final at = run.completedAt ?? run.startedAt;
      if (at.isAfter(last)) {
        last = at;
      }
    }
    final probe = _d.lastActivity;
    if (probe == null) {
      if (!_warnedNoActivity) {
        _warnedNoActivity = true;
        CcInfraLog.warning(
          'no activity probe is wired: idle stop counts environment use only',
        );
      }
    } else {
      final seen = await probe(env.workspaceId, env.spaceId);
      if (seen != null && seen.isAfter(last)) {
        last = seen;
      }
    }
    return _d.now().difference(last) >= Duration(minutes: minutes);
  }

  /// A rig that went away takes its environment with it. Returns whether
  /// [env] was found dead.
  Future<bool> _reconcileRig(SpaceEnvironment env) async {
    final rigId = env.rigId;
    final host = _d.rigHost;
    if (env.placement != 'rig' ||
        rigId == null ||
        host == null ||
        !env.status.isRunning) {
      return false;
    }
    if (await host.isRunning(workspaceId: env.workspaceId, rigId: rigId)) {
      return false;
    }
    await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(
        status: EnvironmentStatus.failed,
        lastError: const EnvironmentError(
          code: 'rig-gone',
          message: 'Its rig no longer exists. Start it again',
        ),
      ),
    );
    return true;
  }

  /// Acts on a space having dropped a repo the stack runs on: a required role
  /// or the last anchor destroys it, anything else asks for a Recreate.
  ///
  /// Returns whether it destroyed [env].
  Future<bool> _reconcileRepos(SpaceEnvironment env) async {
    final file = _boundRolesFile(_d.stateDirFor(env.workspaceId, env.id));
    if (!file.existsSync()) {
      return false;
    }
    final EnvironmentSpaceInfo space;
    final _Loaded loaded;
    try {
      space = await _space(env.workspaceId, env.spaceId);
      loaded = await _load(env.workspaceId, env.definitionId);
    } on Exception {
      return false;
    }
    final bound = {
      for (final role in jsonDecode(await file.readAsString()) as List) '$role',
    };
    final roles = loaded.definition.repos;
    final dropped = roles.where(
      (role) => bound.contains(role.key) && space.repo(role.repoId) == null,
    );
    if (dropped.isEmpty) {
      return false;
    }
    final hasAnchor = roles.any(
      (role) => role.anchor && space.repo(role.repoId) != null,
    );
    if (dropped.any((role) => role.required) || !hasAnchor) {
      await _exclusive(_lockOf(env), () => _teardown(env, force: true));
      return true;
    }
    await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(
        status: row.status.isRunning ? EnvironmentStatus.degraded : row.status,
        needsRecreate: true,
      ),
    );
    return false;
  }

  /// Boot: reconciles rows, leases and labels with what is really there.
  ///
  /// Touches only what carries CC's own labels or leases, and of that, only
  /// what belongs to a workspace of THIS server: a second server on the same
  /// Docker daemon has its own rows, and a space it knows is not an orphan.
  Future<void> recover() async {
    final List<String> workspaces;
    try {
      workspaces = await _d.directory.workspaceIds();
    } on Object catch (e) {
      CcInfraLog.error('environment recovery could not list workspaces', e);
      return;
    }
    final known = <String>{};
    for (final ws in workspaces) {
      try {
        await _d.runs.failInterrupted(ws, _d.now());
        final rows = await _d.environments.list(ws);
        known.addAll(rows.map((row) => row.id));
        for (final row in rows) {
          try {
            await _recoverRow(row);
          } on Object catch (e) {
            CcInfraLog.warning('recovery of ${row.id} failed: $e');
          }
        }
        await _reconcileCliLists(ws);
      } on Object catch (e) {
        // One broken workspace database must not keep the others down.
        CcInfraLog.warning('recovery of workspace $ws failed: $e');
      }
    }
    await _recoverOrphans(workspaces.toSet(), known);
    await _recoverLeases(workspaces.toSet());
  }

  Future<bool> _spaceExists(String workspaceId, String spaceId) async {
    try {
      await _d.directory.space(workspaceId, spaceId);
      return true;
    } on NotFoundException {
      return false;
    }
  }

  Future<void> _recoverRow(SpaceEnvironment env) async {
    final ws = env.workspaceId;
    await _d.supervisor.reapSurvivors(_d.stateDirFor(ws, env.id));
    if (!await _spaceExists(ws, env.spaceId) ||
        env.status == EnvironmentStatus.destroying) {
      await _exclusive(_lockOf(env), () => _teardown(env, force: true));
      return;
    }
    switch (env.status) {
      case EnvironmentStatus.creating:
      case EnvironmentStatus.starting:
        await _update(
          ws,
          env.id,
          (row) => row.copyWith(
            status: EnvironmentStatus.failed,
            lastError: const EnvironmentError(
              code: 'interrupted',
              message: 'The server stopped while this was starting',
            ),
          ),
        );
      case EnvironmentStatus.stopping:
        await _update(
          ws,
          env.id,
          (row) => row.copyWith(status: EnvironmentStatus.stopped),
        );
      case EnvironmentStatus.ready:
      case EnvironmentStatus.degraded:
        if (!await _reconcileRig(env)) {
          await _restartProcesses(env);
        }
      case EnvironmentStatus.failed:
      case EnvironmentStatus.stopped:
      case EnvironmentStatus.gone:
      case EnvironmentStatus.destroying:
        break;
    }
  }

  /// Brings a running environment's processes back. A process someone stopped
  /// stays stopped, and an app stays down: a window opening on its own after a
  /// reboot is the last thing anyone wants.
  Future<void> _restartProcesses(SpaceEnvironment env) async {
    try {
      await _readmit(
        env,
        await _space(env.workspaceId, env.spaceId),
        _EnvironmentServiceBase._system,
      );
    } on EnvironmentDriverException catch (e) {
      // Reaping took its processes, but its containers outlived the server.
      await _exclusive(_lockOf(env), () => _holdForApproval(env, e.error));
      return;
    }
    final _Stack stack;
    try {
      stack = await _stackOf(env);
    } on ValidationException catch (e) {
      await _update(
        env.workspaceId,
        env.id,
        (row) => row.copyWith(
          status: EnvironmentStatus.failed,
          lastError: EnvironmentError(code: 'invalid', message: e.message),
        ),
      );
      return;
    }
    final urls = stack.contract.input.urls;
    final current = await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(
        components: [
          for (final state in row.components)
            state.kind == 'app' ? state.copyWith(state: 'closed') : state,
        ],
        // The router may have come back on another port.
        endpoints: [
          for (final endpoint in row.endpoints)
            urls.containsKey(endpoint.role) && endpoint.url != null
                ? EnvironmentEndpoint(
                    role: endpoint.role,
                    label: endpoint.label,
                    url: urls[endpoint.role],
                    hostPort: endpoint.hostPort,
                    primary: endpoint.primary,
                  )
                : endpoint,
        ],
      ),
    );
    await _applyRoutes(current ?? env, stack);
    final stopped = {
      for (final state in env.components)
        if (state.state == 'stopped') state.id,
    };
    await _d.supervisor.recover(
      stateDir: stack.stateDir,
      specs: [
        for (final process
            in stack.definition.components
                .whereType<ProcessEnvironmentComponent>())
          if (stack.isEnabled(process) && !stopped.contains(process.id))
            EnvironmentProcessSpec.forProcess(
              component: process,
              contract: stack.contract,
              workspaceId: env.workspaceId,
            ),
      ],
    );
  }

  /// A tool that no longer lists an environment has lost it.
  Future<void> _reconcileCliLists(String workspaceId) async {
    final rows = await _d.environments.list(workspaceId);
    for (final loaded in await _loadAll(workspaceId)) {
      final mine = rows.where(
        (row) =>
            row.definitionId == loaded.id &&
            row.status != EnvironmentStatus.gone &&
            row.placement == 'host',
      );
      if (mine.isEmpty) {
        continue;
      }
      for (final component
          in loaded.definition.components
              .whereType<CliEnvironmentComponent>()) {
        if (!component.verbs.containsKey('list')) {
          continue;
        }
        final row = mine.first;
        try {
          final stack = await _stackOf(row);
          final names = await _d.cli.list(_cliContext(stack, component));
          for (final item in mine) {
            if (!names.contains(item.name)) {
              await _update(
                workspaceId,
                item.id,
                // A failed row may never have reached the tool, and it holds
                // the reason.
                (current) => current.status == EnvironmentStatus.failed
                    ? current
                    : current.copyWith(status: EnvironmentStatus.gone),
              );
            }
          }
        } on Object catch (e) {
          CcInfraLog.warning('could not list ${component.id}: $e');
        }
      }
    }
  }

  Future<void> _recoverOrphans(
    Set<String> workspaces,
    Set<String> known,
  ) async {
    final List<ComposeOwnedContainer> orphans;
    try {
      orphans = await _d.compose.orphans(known);
    } on Object catch (e) {
      CcInfraLog.warning('could not look for orphaned containers: $e');
      return;
    }
    final seen = <String>{};
    for (final container in orphans) {
      if (!seen.add(container.environmentId)) {
        continue;
      }
      final ws = container.workspaceId;
      final spaceId = container.spaceId;
      if (ws == null || spaceId == null || !workspaces.contains(ws)) {
        continue;
      }
      try {
        if (!await _spaceExists(ws, spaceId)) {
          await _d.compose.destroyProject(container.environmentId);
        } else {
          CcInfraLog.warning(
            'container ${container.name} has no environment, but its space '
            'exists: left alone',
          );
        }
      } on Object catch (e) {
        CcInfraLog.warning('orphan ${container.name} not removed: $e');
      }
    }
  }

  Future<void> _recoverLeases(Set<String> workspaces) async {
    final List<EnvironmentLease> leases;
    try {
      leases = await _d.leases.all();
    } on Object catch (e) {
      CcInfraLog.warning('could not read leases: $e');
      return;
    }
    for (final lease in leases) {
      try {
        // A workspace this server no longer has can't use its ports, and the
        // lease table is this server's own.
        if (!workspaces.contains(lease.workspaceId) ||
            !await _spaceExists(lease.workspaceId, lease.spaceId)) {
          await _d.allocator.releaseSpace(
            workspaceId: lease.workspaceId,
            spaceId: lease.spaceId,
          );
        }
      } on Object catch (e) {
        CcInfraLog.warning('lease of ${lease.spaceId} not released: $e');
      }
    }
  }
}
