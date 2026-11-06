part of 'environment_service.dart';

/// Everything done to an environment that exists.
mixin _OperationOps
    on
        _EnvironmentServiceBase,
        _SetupOps,
        _DefinitionOps,
        _ComponentOps,
        _StackOps,
        _EnsureOps {
  /// See [EnvironmentPort.environmentsFor].
  Future<List<SpaceEnvironment>> environmentsFor(
    String workspaceId,
    String spaceId,
  ) async {
    await _space(workspaceId, spaceId);
    return _d.environments.forSpace(workspaceId, spaceId);
  }

  /// See [EnvironmentPort.watch].
  Stream<List<SpaceEnvironment>> watch(
    String workspaceId,
    String spaceId,
  ) async* {
    await _space(workspaceId, spaceId);
    final key = '$workspaceId/$spaceId';
    _watchers[key] = (_watchers[key] ?? 0) + 1;
    // Subscribed before the first read, so nothing falls between the two.
    final pending = StreamController<void>();
    final subscription = _changes.stream
        .where(
          (change) =>
              change.workspaceId == workspaceId && change.spaceId == spaceId,
        )
        .listen((_) => pending.add(null));
    String encode(List<SpaceEnvironment> rows) =>
        jsonEncode([for (final row in rows) row.toJson()]);
    try {
      final rows = await _d.environments.forSpace(workspaceId, spaceId);
      var sent = encode(rows);
      yield rows;
      // `yield*`, because it forwards a cancel. Parked in an `await for`, this
      // would only notice one at the next event, and a quiet space has none.
      yield* pending.stream
          .asyncMap((_) => _d.environments.forSpace(workspaceId, spaceId))
          .where((rows) {
            // A poll rewrites the row whether or not anything moved.
            final next = encode(rows);
            final moved = next != sent;
            sent = next;
            return moved;
          });
    } finally {
      await subscription.cancel();
      // Not awaited: cancelled at the first `yield`, nothing ever listened, and
      // the future of an unlistened controller's `close` never completes.
      unawaited(pending.close());
      final left = (_watchers[key] ?? 1) - 1;
      if (left <= 0) {
        _watchers.remove(key);
      } else {
        _watchers[key] = left;
      }
    }
  }

  /// See [EnvironmentPort.stop].
  Future<SpaceEnvironment> stop(
    String workspaceId,
    String spaceId, {
    required Principal by,
  }) async {
    await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    return _exclusive(_lockOf(env), () => _stopLocked(env));
  }

  Future<SpaceEnvironment> _stopLocked(SpaceEnvironment env) async {
    await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(status: EnvironmentStatus.stopping),
    );
    await _closeWindows(env);
    await _d.supervisor.stopEnvironment(env.id);
    _d.routing.clearRoutes(env.id);
    final log = <String>[];
    final run = await _beginRun(env, EnvironmentRunKind.stop);
    EnvironmentError? failure;
    String? note;
    try {
      final rigId = env.rigId;
      if (rigId != null) {
        await _d.rigHost?.stop(workspaceId: env.workspaceId, rigId: rigId);
      }
      final _Stack stack;
      try {
        stack = await _stackOf(env);
      } on Exception catch (e) {
        // Nobody may be stuck with running containers because a definition
        // went bad or a file moved: the project label is enough to stop them.
        if (env.placement == 'host' && _hasComposeLabels(env)) {
          await _d.compose.stopProject(env.id);
        }
        note = 'Stopped without its definition: $e';
        rethrow;
      }
      for (final component in stack.definition.components.reversed) {
        if (env.placement == 'rig' || !stack.isEnabled(component)) {
          continue;
        }
        if (component is ComposeEnvironmentComponent) {
          await _d.compose.stop(await _planOf(env, stack, component));
        } else if (component is CliEnvironmentComponent &&
            component.verbs.containsKey('stop')) {
          await _d.cli.stop(
            _cliContext(stack, component),
            onEvent: _logTo(log),
          );
        }
      }
    } on Exception catch (e) {
      failure = note == null ? _EnvironmentServiceBase._errorOf(e) : null;
    }
    await _endRun(env, run, failure: failure, log: log);
    final done = await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(
        warnings: note == null ? null : {...row.warnings, note}.toList(),
        status: failure == null
            ? EnvironmentStatus.stopped
            : EnvironmentStatus.failed,
        lastError: failure,
        clearLastError: failure == null,
        components: [
          for (final state in row.components)
            state.kind == 'task'
                ? state
                : state.copyWith(
                    state: state.kind == 'app' ? 'closed' : 'stopped',
                  ),
        ],
      ),
    );
    return done ?? env;
  }

  /// See [EnvironmentPort.reset].
  Future<SpaceEnvironment> reset(
    String workspaceId,
    String spaceId, {
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _readmit(env, space, by);
    final loaded = await _load(workspaceId, env.definitionId);
    return _exclusive(_lockOf(env), () async {
      await _d.supervisor.stopEnvironment(env.id);
      return _bringUp(
        space: space,
        loaded: loaded,
        options: env.options,
        by: by,
        existing: env,
        placement: env.placement == 'rig'
            ? EnvironmentPlacement.rig
            : EnvironmentPlacement.host,
        mode: _StartMode.reset,
      );
    });
  }

  /// See [EnvironmentPort.refresh].
  Future<SpaceEnvironment> refresh(
    String workspaceId,
    String spaceId, {
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _readmit(env, space, by);
    return _exclusive(_lockOf(env), () => _applyChange(env, const []));
  }

  /// Re-plans compose, then runs what [changed] calls for.
  Future<SpaceEnvironment> _applyChange(
    SpaceEnvironment stale,
    List<String> changed, {
    bool quiet = false,
  }) async {
    // Under the lock now, so whatever happened while waiting for it counts.
    final env = await _d.environments.get(stale.workspaceId, stale.id);
    if (env == null || !env.status.isRunning) {
      if (quiet) {
        return env ?? stale;
      }
      throw _EnvironmentServiceBase._failure(
        'not-running',
        'Start the environment before refreshing it',
      );
    }
    var stack = await _stackOf(env);
    final definition = stack.definition;
    var current = env;
    EnvironmentError? failure;
    try {
      if (env.placement == 'host') {
        final lease = await _lease(stack.space, stack.loaded);
        for (final component
            in definition.components.whereType<ComposeEnvironmentComponent>()) {
          if (!stack.isEnabled(component)) {
            continue;
          }
          final result = await _d.compose.refresh(
            _composeContext(
              stack.space,
              stack.roles,
              component,
              env.id,
              stack.stateDir,
              stack.contract.forComponent(component),
            ),
            lease: lease,
            existingPorts: current.ports,
          );
          (_plans[env.id] ??= {})[component.id] = result.plan;
          current =
              await _update(
                env.workspaceId,
                env.id,
                (row) => row.copyWith(ports: result.plan.ports),
              ) ??
              current;
        }
        stack = await _stackOf(current);
      }
      for (final task
          in definition.components.whereType<TaskEnvironmentComponent>()) {
        if (stack.isEnabled(task) &&
            task.when.contains(EnvironmentTaskTrigger.change) &&
            environmentAnyPathMatches(task.onChange, changed)) {
          _throwIfFailed(await _runEnvironmentTask(current, stack, task), task);
        }
      }
      for (final process
          in definition.components.whereType<ProcessEnvironmentComponent>()) {
        if (stack.isEnabled(process) &&
            environmentAnyPathMatches(process.restartOn, changed)) {
          await _d.supervisor.stop(env.id, process.id);
          await _d.supervisor.start(
            EnvironmentProcessSpec.forProcess(
              component: process,
              contract: stack.contract,
              workspaceId: env.workspaceId,
            ),
          );
        }
      }
    } on Exception catch (e) {
      failure = _EnvironmentServiceBase._errorOf(e);
    }
    final done = await _update(
      env.workspaceId,
      env.id,
      (row) => failure == null
          ? row.copyWith(clearLastError: true)
          : row.copyWith(status: EnvironmentStatus.failed, lastError: failure),
    );
    return done ?? current;
  }

  /// See [EnvironmentPort.destroy].
  Future<void> destroy(
    String workspaceId,
    String spaceId, {
    required Principal by,
  }) async {
    await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _cancelSetup(env);
    final run = await _beginRun(env, EnvironmentRunKind.destroy);
    try {
      await _exclusive(_lockOf(env), () => _teardown(env, force: false));
    } on Object catch (e) {
      await _endRun(env, run, failure: _EnvironmentServiceBase._errorOf(e));
      rethrow;
    }
    await _endRun(env, run);
  }

  /// Takes [env] apart, last started first.
  ///
  /// With [force] nothing stops it: the worktree is going away regardless, so
  /// each step is attempted and a failure is logged. What a definition supplies
  /// (tool verbs) runs only if it still validates; CC's own resources go anyway.
  Future<void> _teardown(SpaceEnvironment env, {required bool force}) async {
    final ws = env.workspaceId;
    Future<void> quietly(String name, Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (e) {
        CcInfraLog.warning('teardown of ${env.id}: $name failed: $e');
      }
    }

    Future<void> step(String name, Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (e) {
        if (!force) {
          rethrow;
        }
        CcInfraLog.warning('teardown of ${env.id}: $name failed: $e');
      }
    }

    await _update(
      ws,
      env.id,
      (row) => row.copyWith(status: EnvironmentStatus.destroying),
    );
    // CC's own resources go whatever happens next.
    await quietly('windows', () => _closeWindows(env));
    await quietly('processes', () => _d.supervisor.stopEnvironment(env.id));
    await quietly('supervisor', () => _d.supervisor.forget(env.id));

    _Stack? stack;
    try {
      try {
        stack = await _stackOf(env);
      } on NotFoundException {
        stack = await _stackWithoutSpace(env);
      }
    } on Exception catch (e) {
      // A definition that no longer validates can't run a tool's verbs, and
      // must not leave containers running either: labels are enough for those.
      CcInfraLog.warning('teardown of ${env.id} without its definition: $e');
    }
    try {
      final rigId = env.rigId;
      if (rigId != null) {
        await step('rig', () async {
          await _d.rigHost?.destroy(workspaceId: ws, rigId: rigId);
        });
      }
      final known = stack;
      if (known != null && env.placement == 'host') {
        for (final component in known.definition.components.reversed) {
          if (component is CliEnvironmentComponent) {
            await step(
              component.id,
              () => _d.cli.destroy(_cliContext(known, component)),
            );
          } else if (component is ComposeEnvironmentComponent) {
            await step(component.id, () async {
              try {
                await _d.compose.destroy(await _planOf(env, known, component));
              } on Exception catch (e) {
                // The file went with the worktree, or never parses. The
                // project has a name.
                CcInfraLog.info('destroying ${env.id} by label: $e');
                await _d.compose.destroyProject(env.id);
              }
            });
          }
        }
      } else if (env.placement == 'host' && _hasComposeLabels(env)) {
        await step('compose', () => _d.compose.destroyProject(env.id));
      }
    } on Object catch (e) {
      await _update(
        ws,
        env.id,
        (row) => row.copyWith(
          status: EnvironmentStatus.failed,
          lastError: _EnvironmentServiceBase._errorOf(e),
        ),
      );
      rethrow;
    }

    await quietly('routes', () async => _d.routing.clearRoutes(env.id));
    await quietly(
      'lease',
      () => _d.allocator.release(
        workspaceId: ws,
        spaceId: env.spaceId,
        definitionId: env.definitionId,
      ),
    );
    await quietly('state', () async {
      final directory = Directory(_d.stateDirFor(ws, env.id));
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    _plans.remove(env.id);
    await _d.environments.delete(ws, env.id);
    _spaceChanged(ws, env.spaceId);
    _d.events.publish(
      EnvironmentDestroyed(
        workspaceId: ws,
        spaceId: env.spaceId,
        environmentId: env.id,
        occurredAt: _d.now(),
      ),
    );
  }

  /// Without a definition to ask, a row with `<service>.<target>` ports is the
  /// sign compose ran. A project with no containers makes this a no-op anyway.
  bool _hasComposeLabels(SpaceEnvironment env) =>
      env.ports.keys.any((key) => key.contains('.')) ||
      env.components.any((component) => component.kind == 'compose');

  /// See [EnvironmentPort.restart].
  Future<void> restart(
    String workspaceId,
    String spaceId,
    String target, {
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _readmit(env, space, by);
    await _exclusive(_lockOf(env), () async {
      final stack = await _stackOf(env);
      final component = stack.definition.component(target);
      if (component is ProcessEnvironmentComponent) {
        await _d.supervisor.stop(env.id, target);
        await _d.supervisor.start(
          EnvironmentProcessSpec.forProcess(
            component: component,
            contract: stack.contract,
            workspaceId: workspaceId,
          ),
        );
        return;
      }
      for (final compose
          in stack.definition.components
              .whereType<ComposeEnvironmentComponent>()) {
        final plan = await _planOf(env, stack, compose);
        // The component's own id means the whole stack.
        if (compose.id == target || plan.services.contains(target)) {
          await _d.compose.restart(plan, compose.id == target ? null : target);
          return;
        }
      }
      throw _unknownTarget(target);
    });
  }

  ValidationException _unknownTarget(String target) =>
      ValidationException('target: This environment has no $target');

  /// See [EnvironmentPort.stopProcess].
  Future<void> stopProcess(
    String workspaceId,
    String spaceId,
    String componentId, {
    required Principal by,
  }) async {
    await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _exclusive(
      _lockOf(env),
      () => _d.supervisor.stop(env.id, componentId),
    );
  }

  /// See [EnvironmentPort.exec].
  Future<EnvironmentExecResult> exec(
    String workspaceId,
    String spaceId, {
    required String service,
    required List<String> command,
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _readmit(env, space, by);
    final stack = await _stackOf(env);
    if (env.placement == 'rig') {
      final host = _d.rigHost;
      if (host == null) {
        throw _EnvironmentServiceBase._failure(
          'rig-unavailable',
          'This server has no environment rigs',
        );
      }
      return host.exec(
        workspaceId: workspaceId,
        spaceId: spaceId,
        rigId: env.rigId,
        argv: ['docker', 'compose', 'exec', '-T', service, ...command],
      );
    }
    for (final component in stack.definition.components) {
      if (component is ComposeEnvironmentComponent) {
        final plan = await _planOf(env, stack, component);
        if (plan.services.contains(service)) {
          return _d.compose.exec(plan, service, command);
        }
      } else if (component is CliEnvironmentComponent &&
          component.verbs.containsKey('exec')) {
        return _d.cli.exec(
          _cliContext(stack, component),
          service: service,
          command: command,
        );
      }
    }
    throw _unknownTarget(service);
  }

  /// See [EnvironmentPort.logs].
  Future<String> logs(
    String workspaceId,
    String spaceId, {
    required String target,
    int tail = 200,
  }) async {
    await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    final stack = await _stackOf(env);
    final component = stack.definition.component(target);
    if (component is ProcessEnvironmentComponent ||
        component is AppEnvironmentComponent) {
      final lines = await _d.supervisor.logs(
        environmentId: env.id,
        componentId: target,
        stateDir: stack.stateDir,
        tail: tail,
      );
      return lines.join('\n');
    }
    for (final item in stack.definition.components) {
      if (item is ComposeEnvironmentComponent) {
        final plan = await _planOf(env, stack, item);
        if (item.id == target || plan.services.contains(target)) {
          return _d.compose.logs(
            plan,
            item.id == target ? null : target,
            tail: tail,
          );
        }
      } else if (item is CliEnvironmentComponent &&
          item.verbs.containsKey('logs')) {
        return _d.cli.logs(
          _cliContext(stack, item),
          service: target == item.id ? null : target,
          tail: tail,
        );
      }
    }
    throw _unknownTarget(target);
  }

  /// See [EnvironmentPort.followLogs].
  Stream<String> followLogs(
    String workspaceId,
    String spaceId, {
    required String target,
    int tail = 200,
  }) async* {
    await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    final stack = await _stackOf(env);
    final component = stack.definition.component(target);
    if (component is ProcessEnvironmentComponent ||
        component is AppEnvironmentComponent) {
      yield* _d.supervisor.followLogs(env.id, target, tail: tail);
      return;
    }
    for (final item in stack.definition.components) {
      if (item is ComposeEnvironmentComponent) {
        final plan = await _planOf(env, stack, item);
        if (item.id == target || plan.services.contains(target)) {
          yield* _d.compose.followLogs(
            plan,
            item.id == target ? null : target,
            tail: tail,
          );
          return;
        }
      } else if (item is CliEnvironmentComponent &&
          item.verbs.containsKey('logs')) {
        yield* _d.cli.followLogs(
          _cliContext(stack, item),
          service: target == item.id ? null : target,
          tail: tail,
        );
        return;
      }
    }
    throw _unknownTarget(target);
  }

  /// See [EnvironmentPort.runTask].
  Future<EnvironmentRun> runTask(
    String workspaceId,
    String spaceId,
    String taskId, {
    List<String> arguments = const [],
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _readmit(env, space, by);
    final stack = await _stackOf(env);
    final task = stack.definition.component(taskId);
    if (task is! TaskEnvironmentComponent ||
        !task.when.contains(EnvironmentTaskTrigger.manual)) {
      throw ValidationException('task: $taskId is not a manual task');
    }
    final outcome = await _runEnvironmentTask(
      env,
      stack,
      task,
      arguments: arguments,
    );
    return outcome.run;
  }

  /// See [EnvironmentPort.runs].
  Future<List<EnvironmentRun>> runs(String workspaceId, String spaceId) async {
    await _space(workspaceId, spaceId);
    return _d.runs.forSpace(workspaceId, spaceId);
  }

  /// See [EnvironmentPort.definitionEnvironments].
  Future<List<EnvironmentInstance>> definitionEnvironments(
    String workspaceId,
    String definitionId,
  ) async {
    final rows = await _d.environments.list(workspaceId);
    return [
      for (final row in rows)
        if (row.definitionId == definitionId &&
            row.status != EnvironmentStatus.gone)
          (
            environment: row,
            spaceName: await _spaceNameOf(workspaceId, row.spaceId),
          ),
    ];
  }

  Future<String?> _spaceNameOf(String workspaceId, String spaceId) async {
    try {
      return (await _d.directory.space(workspaceId, spaceId)).name;
    } on Exception {
      return null;
    }
  }

  /// See [EnvironmentPort.definitionRuns].
  Future<List<EnvironmentRun>> definitionRuns(
    String workspaceId,
    String definitionId,
  ) => _d.runs.forDefinition(workspaceId, definitionId);

  /// See [EnvironmentPort.launchApp].
  Future<void> launchApp(
    String workspaceId,
    String spaceId,
    String componentId, {
    bool rebuild = false,
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _readmit(env, space, by);
    await _exclusive(_lockOf(env), () async {
      final stack = await _stackOf(env);
      final app = stack.definition.component(componentId);
      if (app is! AppEnvironmentComponent) {
        throw ValidationException('component: $componentId is not an app');
      }
      if (!env.status.isRunning) {
        throw _EnvironmentServiceBase._failure(
          'not-running',
          'Start the environment before launching ${app.displayName}',
        );
      }
      final running = _d.supervisor.processOf(env.id, componentId) != null;
      if (running && !rebuild) {
        return;
      }
      if (running) {
        await _closeWindow(env.id, componentId);
        await _d.supervisor.stop(env.id, componentId);
      }
      final prepare = app.prepare;
      if (prepare != null) {
        final task = stack.definition.component(prepare);
        if (task is TaskEnvironmentComponent) {
          _throwIfFailed(await _runEnvironmentTask(env, stack, task), task);
        }
      }
      await _d.supervisor.start(
        EnvironmentProcessSpec.forApp(
          component: app,
          contract: stack.contract,
          workspaceId: workspaceId,
        ),
      );
      await _openWindow(env, app);
    });
  }

  Future<void> _openWindow(
    SpaceEnvironment env,
    AppEnvironmentComponent app,
  ) async {
    final windows = _d.windows;
    if (windows == null) {
      return;
    }
    try {
      final rigId = await windows.open(
        workspaceId: env.workspaceId,
        spaceId: env.spaceId,
        environmentId: env.id,
        componentId: app.id,
        pids: await _d.supervisor.processTreeOf(env.id, app.id),
        inputMode: app.inputMode,
      );
      _appWindows['${env.id}/${app.id}'] = rigId;
      await _setComponent(
        env,
        app.id,
        (state) => state.copyWith(
          services: [
            {'name': 'window', 'rig_id': rigId},
          ],
        ),
      );
    } on Object catch (e) {
      // The app is up and a person can use it. Only the viewer is missing.
      CcInfraLog.warning('no viewer for ${app.id}: $e');
    }
  }

  Future<void> _closeWindow(String environmentId, String componentId) async {
    final rigId = _appWindows.remove('$environmentId/$componentId');
    if (rigId != null) {
      try {
        await _d.windows?.close(rigId);
      } on Object catch (e) {
        CcInfraLog.warning('could not close viewer $rigId: $e');
      }
    }
  }

  Future<void> _closeWindows(SpaceEnvironment env) async {
    final prefix = '${env.id}/';
    for (final key in _appWindows.keys.toList(growable: false)) {
      if (key.startsWith(prefix)) {
        await _closeWindow(env.id, key.substring(prefix.length));
      }
    }
  }

  /// See [EnvironmentPort.stopApp].
  Future<void> stopApp(
    String workspaceId,
    String spaceId,
    String componentId, {
    required Principal by,
  }) async {
    await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    await _closeWindow(env.id, componentId);
    await _d.supervisor.stop(env.id, componentId);
  }

  /// See [EnvironmentPort.terminalEnvironment].
  Future<Map<String, String>> terminalEnvironment(
    String workspaceId,
    String spaceId,
  ) async {
    await _space(workspaceId, spaceId);
    final env = await _current(workspaceId, spaceId);
    if (env == null || env.status == EnvironmentStatus.gone) {
      return const {};
    }
    try {
      return (await _stackOf(env)).contract.environment();
    } on ValidationException catch (e) {
      // A terminal still opens: it just doesn't get a stack that can't run.
      CcInfraLog.warning('no contract for ${env.id}: ${e.message}');
      return const {};
    } on EnvironmentDriverException catch (e) {
      CcInfraLog.warning('no contract for ${env.id}: $e');
      return const {};
    }
  }

  /// See [EnvironmentPort.sandboxLoopbackPorts].
  ///
  /// Only ports of a lease the space already holds: asking never takes one,
  /// so no run can use up the range or a pool slot. A run gets these at its
  /// start and keeps them, which means a run started before the environment's
  /// first Start has none of its ports; it reaches that environment only
  /// through its proxy's host pins and `cc-env`.
  Future<List<int>> sandboxLoopbackPorts(
    String workspaceId,
    String spaceId,
  ) async {
    final space = await _space(workspaceId, spaceId);
    final ports = <int>{};
    for (final loaded in await _eligible(space)) {
      final lease = await _d.leases.forSpace(workspaceId, spaceId, loaded.id);
      if (lease != null) {
        ports.addAll(lease.ports);
      }
    }
    return ports.toList(growable: false);
  }

  /// See [EnvironmentPort.agentShimTools].
  Future<Set<String>> agentShimTools(String workspaceId, String spaceId) async {
    final space = await _space(workspaceId, spaceId);
    final tools = <String>{};
    for (final loaded in await _eligible(space)) {
      tools.add('cc-env');
      for (final component in loaded.definition.components) {
        if (component is ComposeEnvironmentComponent) {
          tools.add('docker');
        } else if (component is CliEnvironmentComponent) {
          final binary = component.agentPassthrough?.binary;
          if (binary != null) {
            tools.add(binary);
          }
        }
      }
    }
    return tools;
  }

  /// See [EnvironmentPort.sandboxHosts].
  ///
  /// Each of CC's names goes to its own endpoint's loopback port, never to the
  /// router: the router's port is shared by every workspace, and a pin to it
  /// would let a `Host` header reach another space's stack. A tool's names get
  /// no pin at all, for the same reason: its proxy serves every environment by
  /// SNI. Agents reach those through `cc-env`, pass-through and `browser_use`.
  Future<Map<String, String>> sandboxHosts(
    String workspaceId,
    String spaceId,
  ) async {
    await _space(workspaceId, spaceId);
    final hosts = <String, String>{};
    for (final env in await _d.environments.forSpace(workspaceId, spaceId)) {
      if (!env.status.isRunning) {
        continue;
      }
      for (final endpoint in env.endpoints) {
        final host = endpoint.host;
        final port = endpoint.hostPort;
        if (host != null && port != null && host.endsWith('.localhost')) {
          hosts[host] = '127.0.0.1:$port';
        }
      }
    }
    return hosts;
  }

  /// See [AgentEnvironmentContext.definitionFor].
  Future<EnvironmentDefinition?> definitionFor(
    String workspaceId,
    String spaceId,
  ) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _current(workspaceId, spaceId);
    if (env != null) {
      return (await _load(workspaceId, env.definitionId)).definition;
    }
    return (await _eligible(space)).firstOrNull?.definition;
  }

  /// See [AgentEnvironmentContext.nameFor].
  Future<String?> nameFor(String workspaceId, String spaceId) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _current(workspaceId, spaceId);
    if (env != null) {
      return env.name;
    }
    final loaded = (await _eligible(space)).firstOrNull;
    if (loaded == null) {
      return null;
    }
    final naming = loaded.definition.naming;
    return environmentNameFor(
      template: naming.template,
      branch: space.branch,
      prNumber: space.prNumber,
      maxLength: naming.maxLength,
    );
  }

  /// See [AgentEnvironmentContext.worktreeRoots].
  Future<List<String>> worktreeRoots(String workspaceId, String spaceId) async {
    final space = await _space(workspaceId, spaceId);
    return [for (final repo in space.repos) repo.worktreePath];
  }

  /// See [AgentEnvironmentContext.workingDirectory].
  Future<String?> workingDirectory(String workspaceId, String spaceId) async {
    final space = await _space(workspaceId, spaceId);
    final definition = await definitionFor(workspaceId, spaceId);
    if (definition != null) {
      for (final role in definition.repos) {
        final repo = space.repo(role.repoId);
        if (repo != null) {
          return repo.worktreePath;
        }
      }
    }
    return space.repos.firstOrNull?.worktreePath;
  }

  /// See [AgentEnvironmentContext.isInside].
  Future<bool> isInside(String path, List<String> roots) async =>
      resolvesInsideRoots(path, roots);
}
