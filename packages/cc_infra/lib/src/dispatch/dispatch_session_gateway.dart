part of 'dispatch_session.dart';

/// The run's side of the action policy: its network posture and its
/// registration with the agent run gateway (fetches, pushes, forge tokens,
/// Claude Code's hook).
extension _DispatchSessionGateway on DispatchSession {
  /// Registers this run with the gateway under [identity] (who its commits
  /// name, and the key that signs them) for the [repos] it works on, and
  /// returns what the run may use of its space's environment. Without a
  /// gateway or a workspace the run has no lease, and so no push path and no
  /// forge token, which fails closed, and no environment.
  Future<_RunEnvironmentAccess> _openGatewayLease({
    required AgentCommitIdentity? identity,
    required List<ForgeRemote> repos,
  }) async {
    final gateway = deps.agentRunGateway;
    final ws = workspaceId;
    if (gateway == null || ws == null || ws.isEmpty) {
      return const _RunEnvironmentAccess();
    }
    final signProgram = identity?.signingKey == null
        ? null
        : await _writeSignShim(gateway.client);
    final lease = _gatewayLease = await gateway.open(
      AgentRunGrant(
        workspaceId: ws,
        conversationId: conversationId ?? dispatchId,
        agentId: agentId,
        spaceId: spaceId,
        mode: mode,
        actingUserId: requestedByUserId,
        runId: dispatchId,
        repos: repos,
        identity: identity,
        signProgram: signProgram,
        worktreeRoot: agentDirHostPath,
        sharedWorktreeRoots: [?_reposDir],
        readOnlyWorktrees: _readOnlyWorktrees,
        runnerStateDirs: _runnerStateDirs,
        autonomy: _resolveAutonomy,
      ),
    );
    final github = lease?.repos.where((r) => r.forge == ForgeHost.github);
    if (lease != null && github!.isNotEmpty && !Platform.isWindows) {
      await _writeRunShim(
        AgentRunForgeTokens.ghShimName,
        AgentRunForgeTokens.ghShim(lease.client),
      );
    }
    String names(Iterable<ForgeRemote> repos) =>
        [for (final r in repos) '${r.owner}/${r.name}'].join(', ');
    final others = repos.where((r) => r.forge != ForgeHost.github);
    final String said;
    if (lease == null) {
      said =
          '[forge] No fetch or push through Control Center: the agent run '
          'gateway is not reachable.';
    } else if (repos.isEmpty) {
      said =
          '[forge] This run works on no linked repository, so Control Center '
          'fetches none for it.';
    } else {
      final gitHubLine =
          '[forge] GitHub: ${names(github!)} fetch through Control Center on '
          'a read-only token, which gh gets on request; pushes go through '
          'Control Center.';
      final othersLine =
          '[forge] GitLab and Bitbucket: ${names(others)} fetch through '
          'Control Center on a token the run never sees; agents publish there '
          'with stack_publish.';
      said = [
        if (github.isNotEmpty) gitHubLine,
        if (others.isNotEmpty) othersLine,
      ].join('\n');
    }
    addEvent(DebugEvent(content: said));
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

  /// Writes git's signer for this run ([AgentRunSigning.shim]) into the
  /// run's own directory and returns its path.
  Future<String> _writeSignShim(AgentRunClientLauncher client) =>
      _writeRunShim(AgentRunSigning.shimName, AgentRunSigning.shim(client));

  /// Writes one of the run's own programs into its shim directory and returns
  /// its path. They hold no secret and enforce nothing: they read the run's
  /// token from the environment, and the gateway decides.
  Future<String> _writeRunShim(String name, String script) async {
    final directory = Directory(p.join(_shimRunDir, 'bin'));
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, name));
    await file.writeAsString(script);
    await ChildProcess.run('/bin/chmod', ['755', file.path]);
    _runShimDir = directory.path;
    return file.path;
  }

  /// Writes one shim per name into this run's own directory.
  ///
  /// The shims hold no secret and enforce nothing: they read the run's token
  /// from the environment, and the gateway decides.
  Future<String?> _writeEnvironmentShims(Set<String> tools) async {
    if (Platform.isWindows) {
      return null;
    }
    final lease = _gatewayLease;
    if (lease == null) {
      return null;
    }
    final directory = Directory(p.join(_shimRunDir, 'bin'));
    await directory.create(recursive: true);
    final script = agentShimScript(clientCommand: lease.client.shellCommand);
    for (final tool in tools) {
      final file = File(p.join(directory.path, tool));
      await file.writeAsString(script);
      await ChildProcess.run('/bin/chmod', ['755', file.path]);
    }
    return directory.path;
  }

  /// The gateway's variables for the run, with the shim directory first on
  /// `PATH` when the run has an environment or programs of its own there.
  Map<String, String> _leaseEnvironment(
    AgentRunLease lease,
    Map<String, String> env,
  ) {
    final out = lease.environment(env);
    final shims = _run.environment.shimDir ?? _runShimDir;
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

  /// The exec roots the operator approved for this run. The run's own shims
  /// are not among them: an exec grant re-opens a tree the run may write,
  /// and the shims are tool dirs ([_DispatchSessionSandbox._toolDirs]), which
  /// it may run but never change.
  Future<List<String>> _execGrants(String wsId) => _resolveExecGrantRoots(wsId);

  /// Resolves the "network egress" rule for this run: only a deny takes the
  /// sandbox's network away. Without a guard (tests, minimal hosts) or a
  /// workspace there is no rule to read, and the network stays on.
  Future<bool> _resolveNetworkEnabled() => resolveNetworkEgress(
    deps.actionGuard,
    workspaceId: workspaceId,
    spaceId: spaceId,
    agentId: agentId,
    mode: mode,
    label: 'dispatch $dispatchId',
  );

  /// Closes the run's gateway lease, which revokes every forge token the
  /// gateway minted for it (what it read with, what its pushes were forwarded
  /// on), then removes the run's shim directory. Idempotent, and the shims go
  /// whatever closing the lease did.
  Future<void> _releaseRunCredentials() async {
    final lease = _gatewayLease;
    _gatewayLease = null;
    try {
      await deps.agentRunGateway?.close(lease);
    } on Object catch (e, st) {
      CcInfraLog.error('dispatch $dispatchId: lease close failed', e, st);
    } finally {
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
    if (_run.environment.shimDir == null && _runShimDir == null) {
      return;
    }
    _runShimDir = null;
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

  /// Directory of command shims, prepended to `PATH`, executable and never
  /// writable in the sandbox: they forward to the gateway and do nothing
  /// else, so running them grants nothing the gateway doesn't.
  final String? shimDir;
}
