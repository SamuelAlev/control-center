part of 'environment_service.dart';

/// A start that needs a person, finished on a terminal.
///
/// A tool that wants a password can't ask through a pipe, so it exits 3 and the
/// start stops. The `setup` verb is the same work with a terminal attached: the
/// tool asks for itself and the answer goes straight to it. What runs is argv
/// from the approved definition, never a command the tool printed, since that
/// text comes from a process the worktree can influence and would be running
/// with someone's password behind it.
mixin _SetupOps
    on _EnvironmentServiceBase, _ComponentOps, _StackOps, _EnsureOps {
  /// Terminals waiting on a person, by environment.
  final Map<String, ({String sessionId, String owner})> _setups = {};

  /// See [EnvironmentPort.startSetup].
  Future<String> startSetup(
    String workspaceId,
    String spaceId, {
    required Principal by,
  }) async {
    final space = await _space(workspaceId, spaceId);
    final env = await _require(workspaceId, spaceId);
    return _exclusive(_lockOf(env), () async {
      final running = _setups[env.id];
      if (running != null) {
        return running.sessionId;
      }
      // Nobody's password goes to a process a stranger's branch can reach.
      if (space.isFork) {
        throw _EnvironmentServiceBase._failure(
          'setup-refused',
          'A fork pull request cannot run setup on this machine',
        );
      }
      if (env.status != EnvironmentStatus.failed ||
          !(env.lastError?.needsHostSetup ?? false)) {
        throw _EnvironmentServiceBase._failure(
          'setup-not-needed',
          'This environment is not waiting on host setup',
        );
      }
      final stack = await _stackOf(env);
      final component = stack.definition.components
          .whereType<CliEnvironmentComponent>()
          .where(
            (item) => stack.isEnabled(item) && item.verbs.containsKey('setup'),
          )
          .firstOrNull;
      if (component == null) {
        throw _EnvironmentServiceBase._failure(
          'setup-missing',
          'This definition has no setup verb',
        );
      }
      return _spawnSetup(env, stack, component, by);
    });
  }

  Future<String> _spawnSetup(
    SpaceEnvironment env,
    _Stack stack,
    CliEnvironmentComponent component,
    Principal by,
  ) async {
    final context = _cliContext(stack, component);
    final owner = 'environment:${env.id}/setup';
    final ring = EnvironmentLogRing(path: p.join(stack.stateDir, 'setup.log'));
    final run = await _beginRun(env, EnvironmentRunKind.start, label: 'setup');
    final OwnedTerminalSession session;
    try {
      session = await _d.supervisor.startInteractive(
        workspaceId: env.workspaceId,
        spaceId: env.spaceId,
        owner: owner,
        argv: EnvironmentCommandRunner.argvFor(
          component.verbs['setup']!,
          context.values,
        ),
        environment: context.environment,
        workingDirectory: context.workingDirectory,
        onOutput: ring.addBytes,
      );
    } on Object catch (e) {
      await _endRun(env, run, failure: _EnvironmentServiceBase._errorOf(e));
      rethrow;
    }
    _setups[env.id] = (sessionId: session.sessionId, owner: owner);
    unawaited(
      session.exitCode.then((code) => _finishSetup(env, run, ring, code, by)),
    );
    return session.sessionId;
  }

  /// Records how it went and, when it worked, picks the start back up.
  Future<void> _finishSetup(
    SpaceEnvironment env,
    String run,
    EnvironmentLogRing ring,
    int exitCode,
    Principal by,
  ) async {
    final wasRunning = _setups.remove(env.id) != null;
    ring.finishLine();
    await _endRun(
      env,
      run,
      failure: exitCode == 0
          ? null
          : EnvironmentError(
              code: 'setup-failed',
              message: 'Setup exited with code $exitCode',
              exitCode: exitCode,
            ),
      log: ring.tail(200),
    );
    await ring.close();
    if (exitCode != 0 || !wasRunning) {
      return;
    }
    try {
      await ensure(
        workspaceId: env.workspaceId,
        spaceId: env.spaceId,
        definitionId: env.definitionId,
        options: env.options,
        by: by,
      );
    } on Object catch (e) {
      // The row carries the failure; this only explains the missing retry.
      CcInfraLog.warning('environment ${env.id}: start after setup failed: $e');
    }
  }

  /// Ends a setup nobody will finish.
  Future<void> _cancelSetup(SpaceEnvironment env) async {
    final setup = _setups.remove(env.id);
    if (setup != null) {
      await _d.supervisor.stopInteractive(
        workspaceId: env.workspaceId,
        sessionId: setup.sessionId,
        owner: setup.owner,
      );
    }
  }
}
