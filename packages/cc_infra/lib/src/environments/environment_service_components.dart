part of 'environment_service.dart';

/// Starting each kind of component, and serving what they publish.
mixin _ComponentOps on _EnvironmentServiceBase, _DefinitionOps {
  List<EnvironmentComponent> _startable(_Stack stack) => [
    for (final component in stack.definition.components)
      if (stack.isEnabled(component) &&
          component is! AppEnvironmentComponent &&
          !(component is TaskEnvironmentComponent &&
              component.when.every((trigger) => trigger.isWorktreeTrigger)))
        component,
  ];

  Iterable<AppEnvironmentComponent> _apps(_Stack stack) => stack
      .definition
      .components
      .whereType<AppEnvironmentComponent>()
      .where(stack.isEnabled);

  List<EnvironmentEndpoint> _processEndpoints(
    _Stack stack,
    Map<String, int> ports,
  ) {
    final urls = stack.contract.input.urls;
    return [
      for (final process
          in stack.definition.components
              .whereType<ProcessEnvironmentComponent>())
        if (stack.isEnabled(process) && process.endpoint != null)
          EnvironmentEndpoint(
            role: process.endpoint!.role,
            label: process.endpoint!.label,
            url: urls[process.endpoint!.role],
            hostPort: ports[process.ports.first],
            primary: process.endpoint!.primary,
          ),
    ];
  }

  /// Runs [components]: declared order, each waiting for the one before it,
  /// unless `after` names what it waits for instead.
  Future<void> _startComponents(
    SpaceEnvironment env,
    _Stack stack,
    List<EnvironmentComponent> components,
    _StartMode mode,
    List<String> log,
  ) async {
    final done = <String, Future<void>>{};
    String? previous;
    for (final component in components) {
      final waits = component.after.isNotEmpty ? component.after : [?previous];
      final dependencies = [for (final id in waits) ?done[id]];
      done[component.id] = Future.wait(
        dependencies,
      ).then((_) => _startComponent(env, stack, component, mode, log));
      previous = component.id;
    }
    await Future.wait(done.values);
  }

  Future<void> _startComponent(
    SpaceEnvironment env,
    _Stack stack,
    EnvironmentComponent component,
    _StartMode mode,
    List<String> log,
  ) async {
    await _setComponent(
      env,
      component.id,
      (state) => state.copyWith(state: 'starting'),
    );
    try {
      switch (component) {
        case ComposeEnvironmentComponent():
          await _startCompose(env, stack, component, mode);
        case CliEnvironmentComponent():
          await _startCli(env, stack, component, mode, log);
        case ProcessEnvironmentComponent():
          await _startProcess(env, stack, component);
        case TaskEnvironmentComponent():
          await _startTask(env, stack, component);
        case AppEnvironmentComponent():
          break;
      }
    } on Object catch (e) {
      await _setComponent(
        env,
        component.id,
        (state) => state.copyWith(
          state: 'failed',
          detail: _EnvironmentServiceBase._errorOf(e).message,
        ),
      );
      rethrow;
    }
  }

  Future<void> _startCompose(
    SpaceEnvironment env,
    _Stack stack,
    ComposeEnvironmentComponent component,
    _StartMode mode,
  ) async {
    final plan = _plans[env.id]?[component.id];
    if (plan == null) {
      if (env.placement == EnvironmentPlacement.host.name) {
        throw _EnvironmentServiceBase._failure(
          'role-missing',
          'This space has no repo for ${component.displayName}',
        );
      }
      // In a rig, the host started it with the VM.
      await _setComponent(
        env,
        component.id,
        (state) => state.copyWith(state: 'ready'),
      );
      return;
    }
    final notes = await switch (mode) {
      _StartMode.create => _d.compose.up(plan),
      _StartMode.resume => _d.compose.start(plan),
      _StartMode.reset => _d.compose.reset(plan),
    };
    final services = await _d.compose.waitReady(plan);
    final found = await _d.compose.detectEndpoints(plan, services);
    final urls = stack.contract.input.urls;
    final declared = stack.definition.processEndpointRoles;
    await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(
        warnings: {...row.warnings, ...notes}.toList(),
        endpoints: _mergeEndpoints(row.endpoints, [
          for (final endpoint in found)
            if (!declared.contains(endpoint.role))
              EnvironmentEndpoint(
                role: endpoint.role,
                label: endpoint.label,
                url: endpoint.url == null ? null : urls[endpoint.role],
                hostPort: endpoint.hostPort,
              ),
        ]),
        components: [
          for (final state in row.components)
            state.id == component.id
                ? state.copyWith(
                    state: 'ready',
                    services: [
                      for (final service in services)
                        service.toJson(
                          ports: [
                            for (final port in plan.published)
                              if (port.service == service.service)
                                port.hostPort,
                          ],
                        ),
                    ],
                  )
                : state,
        ],
      ),
    );
  }

  List<EnvironmentEndpoint> _mergeEndpoints(
    List<EnvironmentEndpoint> current,
    List<EnvironmentEndpoint> added,
  ) {
    final roles = {for (final endpoint in added) endpoint.role};
    return [
      for (final endpoint in current)
        if (!roles.contains(endpoint.role)) endpoint,
      ...added,
    ];
  }

  CliContext _cliContext(_Stack stack, CliEnvironmentComponent component) =>
      CliContext(
        component: component,
        values: stack.contract.values,
        // A space that is gone has no worktree, and a tool's `destroy` still
        // has to run from somewhere.
        workingDirectory: stack.roles.isEmpty
            ? _d.home
            : stack.contract.workingDirectory(component.cwd),
        environment: stack.contract.forComponent(component),
        routingDomain: stack.definition.routing.domain,
      );

  Future<void> _startCli(
    SpaceEnvironment env,
    _Stack stack,
    CliEnvironmentComponent component,
    _StartMode mode,
    List<String> log,
  ) async {
    final context = _cliContext(stack, component);
    final EnvironmentStatusReport report;
    if (mode == _StartMode.reset) {
      await _d.cli.reset(context, onEvent: _logTo(log));
      report = await _d.cli.waitReady(context);
    } else {
      report = await _d.cli.up(context, onEvent: _logTo(log));
    }
    await _applyCliReport(env, component, report);
  }

  /// Collects a verb's output into [log], for the run it belongs to.
  void Function(EnvironmentCommandEvent) _logTo(List<String> log) => (event) {
    if (event is EnvironmentCommandOutput) {
      log.add(event.line);
    }
  };

  /// Puts [kind] on record for [env], so the space's activity shows it.
  Future<String> _beginRun(
    SpaceEnvironment env,
    EnvironmentRunKind kind, {
    String? label,
  }) async {
    final id = _uuid.v4();
    await _d.runs.start(
      EnvironmentRun(
        id: id,
        workspaceId: env.workspaceId,
        spaceId: env.spaceId,
        environmentId: env.id,
        definitionId: env.definitionId,
        kind: kind,
        label: label,
        status: EnvironmentRunStatus.running,
        startedAt: _d.now(),
      ),
    );
    return id;
  }

  /// Closes what [_beginRun] opened.
  Future<void> _endRun(
    SpaceEnvironment env,
    String id, {
    EnvironmentError? failure,
    List<String> log = const [],
  }) => _d.runs.finish(
    env.workspaceId,
    id,
    status: failure == null
        ? EnvironmentRunStatus.succeeded
        : EnvironmentRunStatus.failed,
    completedAt: _d.now(),
    exitCode: failure?.exitCode,
    error: failure?.message,
    output: log.join('\n'),
  );

  Future<void> _applyCliReport(
    SpaceEnvironment env,
    CliEnvironmentComponent component,
    EnvironmentStatusReport report,
  ) => _update(
    env.workspaceId,
    env.id,
    (row) => row.copyWith(
      endpoints: _mergeEndpoints(row.endpoints, report.endpoints),
      warnings: {...row.warnings, ...report.warnings}.toList(),
      // Sticky: the space dropping a repo needs a Recreate whatever a tool says.
      needsRecreate: row.needsRecreate || report.needsRecreate,
      components: [
        for (final state in row.components)
          state.id == component.id
              ? state.copyWith(
                  state: _componentStateOf(report.state),
                  detail: report.detail,
                  services: [
                    for (final service in report.services)
                      {'name': service, 'state': 'ready'},
                  ],
                )
              : state,
      ],
    ),
  );

  String _componentStateOf(EnvironmentReportedState state) => switch (state) {
    EnvironmentReportedState.ready => 'ready',
    EnvironmentReportedState.starting => 'starting',
    EnvironmentReportedState.stopped => 'stopped',
    EnvironmentReportedState.missing => 'stopped',
    EnvironmentReportedState.failed => 'failed',
    EnvironmentReportedState.degraded => 'failed',
  };

  Future<void> _startProcess(
    SpaceEnvironment env,
    _Stack stack,
    ProcessEnvironmentComponent component,
  ) async {
    await _d.supervisor.start(
      EnvironmentProcessSpec.forProcess(
        component: component,
        contract: stack.contract,
        workspaceId: env.workspaceId,
      ),
    );
    final state = await _d.supervisor.waitReady(env.id, component.id);
    await _setComponent(
      env,
      component.id,
      (current) => current.copyWith(
        state: 'ready',
        sessionId: state.sessionId,
        restarts: state.restarts,
      ),
    );
  }

  /// A `create` task's marker. Per task, so a retry skips what already worked
  /// and a task added later still runs once.
  File _createMarker(String stateDir, String taskId) =>
      File(p.join(stateDir, 'create-tasks', taskId));

  Future<void> _clearCreateMarkers(String stateDir) async {
    final directory = Directory(p.join(stateDir, 'create-tasks'));
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _startTask(
    SpaceEnvironment env,
    _Stack stack,
    TaskEnvironmentComponent task,
  ) async {
    final marker = _createMarker(stack.stateDir, task.id);
    final isCreate = task.when.contains(EnvironmentTaskTrigger.create);
    final runs =
        task.when.contains(EnvironmentTaskTrigger.start) ||
        (isCreate && !marker.existsSync());
    if (!runs) {
      await _setComponent(
        env,
        task.id,
        (state) => state.copyWith(state: 'pending'),
      );
      return;
    }
    _throwIfFailed(await _runEnvironmentTask(env, stack, task), task);
    if (isCreate) {
      await marker.parent.create(recursive: true);
      await marker.writeAsString(_d.now().toUtc().toIso8601String());
    }
  }

  /// Throws what [outcome] failed with, keeping a tool's structured error: a
  /// failed task is often an exit 3 with a command to copy.
  void _throwIfFailed(
    ({EnvironmentRun run, EnvironmentError? error}) outcome,
    TaskEnvironmentComponent task,
  ) {
    if (outcome.run.status == EnvironmentRunStatus.succeeded) {
      return;
    }
    throw EnvironmentDriverException(
      outcome.error ??
          EnvironmentError(
            code: 'task-failed',
            message: outcome.run.error ?? '${task.displayName} failed',
            exitCode: outcome.run.exitCode,
          ),
    );
  }

  /// Runs [task] where the environment runs, and records it on its component.
  Future<({EnvironmentRun run, EnvironmentError? error})> _runEnvironmentTask(
    SpaceEnvironment env,
    _Stack stack,
    TaskEnvironmentComponent task, {
    List<String> arguments = const [],
  }) async {
    final EnvironmentRun run;
    EnvironmentError? error;
    if (env.placement == EnvironmentPlacement.rig.name) {
      run = await _runInRig(
        task: task,
        workspaceId: env.workspaceId,
        spaceId: env.spaceId,
        environmentId: env.id,
        definitionId: env.definitionId,
        rigId: (await _d.environments.get(env.workspaceId, env.id))?.rigId,
        argv: EnvironmentCommandRunner.argvFor(
          task.command,
          stack.contract.values,
          arguments: arguments,
        ),
        environment: stack.contract.forComponent(task),
      );
    } else {
      final outcome = await _d.tasks.runInEnvironment(
        task: task,
        contract: stack.contract,
        workspaceId: env.workspaceId,
        definitionId: env.definitionId,
        environmentId: env.id,
        arguments: arguments,
      );
      run = outcome.run;
      error = outcome.error;
    }
    await _setComponent(
      env,
      task.id,
      (state) => state.copyWith(
        state: run.status == EnvironmentRunStatus.succeeded
            ? 'completed'
            : 'failed',
        lastRunAt: run.completedAt,
        lastExitCode: run.exitCode,
      ),
    );
    return (run: run, error: error);
  }

  /// Runs a task in a rig, recording it the way the task runner would.
  Future<EnvironmentRun> _runInRig({
    required TaskEnvironmentComponent task,
    required String workspaceId,
    required String spaceId,
    required List<String> argv,
    required Map<String, String> environment,
    String? environmentId,
    String? definitionId,
    String? repoId,
    String? rigId,
  }) async {
    final host = _d.rigHost;
    if (host == null) {
      throw _EnvironmentServiceBase._failure(
        'rig-unavailable',
        'This task runs in a rig, and this server has no environment rigs',
      );
    }
    final id = _uuid.v4();
    final startedAt = _d.now();
    EnvironmentRun record(
      EnvironmentRunStatus status, {
      int? exitCode,
      String? error,
      String output = '',
      DateTime? completedAt,
    }) => EnvironmentRun(
      id: id,
      workspaceId: workspaceId,
      spaceId: spaceId,
      environmentId: environmentId,
      definitionId: definitionId,
      repoId: repoId,
      kind: EnvironmentRunKind.task,
      label: task.id,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      exitCode: exitCode,
      error: error,
      output: output,
    );
    await _d.runs.start(record(EnvironmentRunStatus.running));
    final result = await host.exec(
      workspaceId: workspaceId,
      spaceId: spaceId,
      rigId: rigId,
      argv: argv,
      environment: environment,
      timeout: Duration(seconds: task.timeoutSeconds),
    );
    final finished = record(
      result.exitCode == 0
          ? EnvironmentRunStatus.succeeded
          : EnvironmentRunStatus.failed,
      exitCode: result.exitCode,
      error: result.exitCode == 0 ? null : result.stderr,
      output: result.stdout,
      completedAt: _d.now(),
    );
    await _d.runs.finish(
      workspaceId,
      id,
      status: finished.status,
      completedAt: finished.completedAt!,
      exitCode: result.exitCode,
      error: finished.error,
      output: result.stdout,
    );
    return finished;
  }

  Future<void> _startRig(SpaceEnvironment env, _Stack stack) async {
    final instance = await _d.rigHost!.start(
      workspaceId: env.workspaceId,
      spaceId: env.spaceId,
      environmentId: env.id,
      definition: stack.definition,
      // Never the registered checkout: a VM gets copies of worktrees, and the
      // operator's own tree is exactly what a rig keeps away from fork code.
      worktrees: {
        for (final role in stack.roles)
          if (!role.isSource) role.role.key: role.repo.path,
      },
      environment: stack.contract.environment(),
    );
    await _update(
      env.workspaceId,
      env.id,
      (row) => row.copyWith(
        rigId: instance.rigId,
        endpoints: _mergeEndpoints(row.endpoints, instance.endpoints),
      ),
    );
  }

  /// Serves [env]'s endpoints: router URLs on CC's own hostnames, and a tool's
  /// hostnames through its proxy, re-encrypted against its CA.
  Future<void> _applyRoutes(SpaceEnvironment env, _Stack stack) async {
    final routes = <String, RigEnvironmentRoute>{};
    final routing = stack.definition.routing;
    for (final endpoint in env.endpoints) {
      final host = endpoint.host;
      final port = endpoint.hostPort;
      if (host == null || !endpoint.isAllowedFor(routing.domain)) {
        continue;
      }
      if (host.endsWith('.localhost') && port != null) {
        routes[host] = RigEnvironmentRoute(
          workspaceId: env.workspaceId,
          host: '127.0.0.1',
          port: port,
        );
      } else if (routing.mode == EnvironmentRoutingMode.tool &&
          host != 'localhost' &&
          host != '127.0.0.1') {
        final upstream = _hostPort(routing.upstream);
        if (upstream != null) {
          routes[host] = RigEnvironmentRoute(
            workspaceId: env.workspaceId,
            host: upstream.host,
            port: upstream.port,
            tlsContext: routing.tls ? _trusting(routing.caFile) : null,
          );
        }
      }
    }
    try {
      _d.routing.setRoutes(env.id, routes);
    } on ArgumentError catch (e) {
      throw _EnvironmentServiceBase._failure('route-taken', '${e.message}');
    }
  }

  ({String host, int port})? _hostPort(String? value) {
    if (value == null) {
      return null;
    }
    final separator = value.lastIndexOf(':');
    final port = int.tryParse(value.substring(separator + 1));
    return separator <= 0 || port == null
        ? null
        : (host: value.substring(0, separator), port: port);
  }

  SecurityContext _trusting(String? caFile) {
    final context = SecurityContext();
    if (caFile != null) {
      context.setTrustedCertificates(
        caFile.startsWith('~/') ? p.join(_d.home, caFile.substring(2)) : caFile,
      );
    }
    return context;
  }
}
