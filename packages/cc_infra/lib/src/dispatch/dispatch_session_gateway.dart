part of 'dispatch_session.dart';

/// The run's side of the action policy: its network posture and its
/// registration with the agent run gateway (pushes, Claude Code's hook).
extension _DispatchSessionGateway on DispatchSession {
  /// Registers this run with the gateway, signing as [identity], and returns
  /// what the run may use of its space's environment. Without a gateway or a
  /// workspace the run has no lease — and so no push path, which fails closed
  /// — and no environment.
  Future<_RunEnvironmentAccess> _openGatewayLease({
    required AgentCommitIdentity? identity,
    String? repoOwner,
    String? repoName,
  }) async {
    final gateway = deps.agentRunGateway;
    final ws = workspaceId;
    if (gateway == null || ws == null || ws.isEmpty) {
      return const _RunEnvironmentAccess();
    }
    _gatewayLease = await gateway.open(
      AgentRunGrant(
        workspaceId: ws,
        conversationId: conversationId ?? dispatchId,
        agentId: agentId,
        spaceId: spaceId,
        mode: mode,
        actingUserId: requestedByUserId,
        runId: dispatchId,
        repoOwner: repoOwner,
        repoName: repoName,
        identity: identity,
        worktreeRoot: agentDirHostPath,
        sharedWorktreeRoots: [?_reposDir],
        runnerStateDirs: _runnerStateDirs,
        autonomy: _resolveAutonomy,
      ),
    );
    return _openEnvironmentAccess();
  }

  /// Gives this run what it needs to use its space's environment.
  ///
  /// A failure here costs the run its environment commands, never the run:
  /// most runs don't touch an environment at all.
  Future<_RunEnvironmentAccess> _openEnvironmentAccess() async {
    final environments = deps.environments?.target;
    final ws = workspaceId;
    final space = spaceId;
    if (environments == null ||
        ws == null ||
        ws.isEmpty ||
        space == null ||
        space.isEmpty) {
      return const _RunEnvironmentAccess();
    }
    try {
      final tools = await environments.agentShimTools(ws, space);
      if (tools.isEmpty) {
        return const _RunEnvironmentAccess();
      }
      return _RunEnvironmentAccess(
        ports: await environments.sandboxLoopbackPorts(ws, space),
        scope: '$ws/$space',
        shimDir: await _writeEnvironmentShims(tools),
      );
    } on Object catch (e) {
      CcInfraLog.warning(
        'dispatch $dispatchId: environment access unavailable: $e',
      );
      return const _RunEnvironmentAccess();
    }
  }

  /// Writes one shim per name into this run's own directory.
  ///
  /// The shims hold no secret and enforce nothing: they read the run's token
  /// from the environment, and the gateway decides.
  Future<String?> _writeEnvironmentShims(Set<String> tools) async {
    if (Platform.isWindows) {
      return null;
    }
    final directory = Directory(p.join(_shimRunDir, 'bin'));
    await directory.create(recursive: true);
    final script = agentShimScript(
      tokenHeader: AgentRunLease.tokenHeader,
      tokenEnvKey: AgentRunLease.tokenEnvKey,
      gatewayEnvKey: AgentRunLease.gatewayEnvKey,
    );
    for (final tool in tools) {
      final file = File(p.join(directory.path, tool));
      await file.writeAsString(script);
      await ChildProcess.run('/bin/chmod', ['755', file.path]);
    }
    return directory.path;
  }

  /// The gateway's variables for the run, with the shim directory first on
  /// `PATH` when the run has an environment.
  Map<String, String> _leaseEnvironment(
    AgentRunLease lease,
    Map<String, String> env,
  ) {
    final out = lease.environment(env);
    final shims = _run.environment.shimDir;
    if (shims == null) {
      return out;
    }
    final path = env['PATH'] ?? Platform.environment['PATH'] ?? '';
    return {...out, 'PATH': '$shims:$path'};
  }

  /// Every sandbox of this run must reach the gateway, and the lease ports of
  /// its space's environment.
  List<int> get _gatewayLoopbackPorts => [
    ?_gatewayLease?.base.port,
    ..._run.environment.ports,
  ];

  /// Approved exec roots plus the run's own shims. Kept separate from the
  /// grant service so the shims work even where there is none.
  Future<List<String>> _execGrants(String wsId) async => [
    ...await _resolveExecGrantRoots(wsId),
    ?_run.environment.shimDir,
  ];

  /// Resolves the "network egress" rule for this run: only a deny takes the
  /// sandbox's network away. Without a guard (tests, minimal hosts) or a
  /// workspace there is no rule to read, and the network stays on.
  Future<bool> _resolveNetworkEnabled() async {
    final guard = deps.actionGuard;
    final ws = workspaceId;
    if (guard == null || ws == null || ws.isEmpty) {
      return true;
    }
    try {
      final resolution = await guard.resolve(
        workspaceId: ws,
        classes: const {ActionClass.networkEgress},
        spaceId: spaceId,
        agentId: agentId,
        mode: mode,
      );
      return resolution.decision != ActionDecision.deny;
    } on Object catch (e) {
      CcInfraLog.warning(
        'dispatch $dispatchId: network-egress rule resolution failed, '
        'keeping the network on: $e',
      );
      return true;
    }
  }

  /// Revokes the run's scoped credential and closes its gateway lease (which
  /// revokes any write token the gateway minted for its pushes), then removes
  /// the run's shim directory. Idempotent, and each step runs whatever the
  /// one before it did: a revoke that threw used to leave the lease open, its
  /// secret still accepted and its write tokens live.
  Future<void> _releaseRunCredentials() async {
    final cred = credHandle;
    credHandle = null;
    final lease = _gatewayLease;
    _gatewayLease = null;
    try {
      if (cred != null) {
        await deps.broker.revoke(cred);
      }
    } on Object catch (e, st) {
      CcInfraLog.error('dispatch $dispatchId: credential revoke failed', e, st);
    } finally {
      try {
        await deps.agentRunGateway?.close(lease);
      } on Object catch (e, st) {
        CcInfraLog.error('dispatch $dispatchId: lease close failed', e, st);
      }
      await _removeEnvironmentShims();
    }
  }

  /// The directory this run's environment shims live in.
  String get _shimRunDir => p.join(agentDirHostPath, '.cc-runs', dispatchId);

  /// Deletes this run's shim directory, once the run is over. They were never
  /// removed, so every environment-enabled run left a `.cc-runs/<id>` behind
  /// in the agent's working tree.
  ///
  /// Only a real directory is removed: the agent could have swapped the path
  /// for a link, and a recursive delete must never follow one out.
  Future<void> _removeEnvironmentShims() async {
    if (_run.environment.shimDir == null) {
      return;
    }
    final dir = _shimRunDir;
    try {
      if (FileSystemEntity.typeSync(dir, followLinks: false) ==
          FileSystemEntityType.directory) {
        await Directory(dir).delete(recursive: true);
      }
    } on FileSystemException catch (e) {
      CcInfraLog.warning('dispatch $dispatchId: shim cleanup failed: $e');
    }
  }
}

/// What a run may use of its space's environment. Fixed when the run starts,
/// because the sandbox profile is.
class _RunEnvironmentAccess {
  const _RunEnvironmentAccess({
    this.ports = const [],
    this.scope,
    this.shimDir,
  });

  /// Lease ports the sandbox may dial.
  final List<int> ports;

  /// `<workspaceId>/<spaceId>`, for the run's own proxy pins.
  final String? scope;

  /// Directory of command shims, prepended to `PATH` and granted exec: they
  /// forward to the gateway and do nothing else, so running them grants
  /// nothing the gateway doesn't.
  final String? shimDir;
}
