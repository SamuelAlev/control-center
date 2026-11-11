part of 'dispatch_session.dart';

/// What this run's sandbox is handed. Everything else under the server's data
/// directory stays hidden from it (the sandbox manager hides the whole tree),
/// so a path the run needs must be named here.
extension _DispatchSessionSandbox on DispatchSession {
  /// Asked before anything of the run starts: on a host with no sandbox, only
  /// work the server owner is accountable for may run there. A refused run
  /// ends with the refusal as its error.
  Future<bool> _admittedOnHost() async {
    try {
      await deps.hostExecution.admit(
        workspaceId: workspaceId,
        requestedByUserId: requestedByUserId,
      );
      return true;
    } on HostSandboxUnavailableException catch (e) {
      _failRun(e.message, code: e.code);
      _finish(error: e);
      return false;
    }
  }

  /// Per-dispatch bind mounts (cross-agent isolation).
  ///
  /// Overlay: cwd **rw**; agent config **ro**; the workspace skills its
  /// links point into **ro**; `<convRoot>/repos` **rw** when present, with
  /// each worktree the run may not change **ro** inside it; space
  /// `attachments/` **ro** when present (harness uses [_workspaceSharedRoots]
  /// with no RO mode — convention only). Fallback/oneshot: single writable
  /// cwd. Sibling agent dirs and other spaces are never mounted.
  List<SandboxBindMount> _bindMounts() {
    final cwd = agentDirHostPath;
    final layout = _layout;
    if (!layout.isOverlay) {
      return [SandboxBindMount(hostPath: cwd, guestPath: cwd)];
    }
    final configDir = agentConfigDir!;
    final reposPath = layout.reposDir;
    final attachmentsPath = layout.attachmentsDir;
    // `syncAgentSkillLinks` links the agent's skills to `<wsRoot>/skills`,
    // one level above the agent dir; the links resolve only if it is mounted.
    final skillsPath = p.join(p.dirname(p.dirname(configDir)), 'skills');
    return [
      SandboxBindMount(hostPath: cwd, guestPath: cwd),
      SandboxBindMount(
        hostPath: configDir,
        guestPath: configDir,
        readOnly: true,
      ),
      if (Directory(skillsPath).existsSync())
        SandboxBindMount(
          hostPath: skillsPath,
          guestPath: skillsPath,
          readOnly: true,
        ),
      // Writable so the overlay `repos` symlink resolves in the guest
      // namespace (identical host/guest paths).
      if (reposPath != null)
        SandboxBindMount(hostPath: reposPath, guestPath: reposPath),
      ..._readOnlyWorktreeMounts,
      if (attachmentsPath != null)
        SandboxBindMount(
          hostPath: attachmentsPath,
          guestPath: attachmentsPath,
          readOnly: true,
        ),
    ];
  }

  /// The ONE sandbox spec this dispatch's processes run under: its CLI
  /// transports (Claude Code, ACP) and, with its own session id and the mode
  /// its registry was built for, the harness `bash` tool and the processes
  /// its tools start. Every input is a value resolved at run start, so two
  /// transports of one run can never be sandboxed differently.
  /// [loopbackPorts] only narrows the run's own. The read-only worktrees are
  /// part of it, so a run after a grant change gets a different spec and
  /// never a warm sandbox made for the old one.
  Future<SandboxSpec> _sandboxSpec(
    String sandboxSessionId,
    String wsId, {
    Mode? mode,
    List<int>? loopbackPorts,
    List<String> extraToolDirs = const [],
  }) async {
    await _resolveReadOnlyWorktrees();
    return processSandboxSpec(
      sessionId: sandboxSessionId,
      workspaceId: wsId,
      agentId: agentId,
      bindMounts: _bindMounts(),
      workdir: agentDirHostPath,
      networkEnabled: _run.networkEnabled,
      mode: mode ?? this.mode,
      protectedPaths: await _protectedPaths(),
      runnerStateDirs: _runnerStateDirs,
      execGrantRoots: await _execGrants(wsId),
      toolDirs: [..._toolDirs, ...extraToolDirs],
      loopbackPorts: loopbackPorts ?? _gatewayLoopbackPorts,
      environmentScope: _run.environment.scope,
      superviseProcessGroup: true,
    );
  }

  /// The sandbox session id a dispatch's CLI transports share: one per
  /// agent, conversation and mode, so a follow-up turn can reuse it warm.
  String get _sandboxSessionId {
    final agentKey = (agentId != null && agentId!.isNotEmpty)
        ? agentId!
        : 'oneshot';
    final convKey = conversationId ?? 'no-conv';
    return '${DispatchSession.agentSessionPrefix}$agentKey::$convKey::'
        '${mode.name}';
  }

  /// The tool sandbox sessions are this run's own (they end with it), so they
  /// are named by its dispatch id too.
  String get _toolSessionKey =>
      '${agentId ?? 'oneshot'}::${conversationId ?? 'no-conv'}::$dispatchId';

  /// The sandbox session the harness `bash` tool runs in, shared with
  /// [_toolProcesses].
  String get _harnessSandboxSessionId => 'harness-$_toolSessionKey';

  /// Starts the `eval` kernel on the host: under this run's spec in [mode]
  /// when the server sandboxes agents, else unconfined (the run was admitted
  /// by `HostExecutionGate`). Shares the harness `bash` tool's sandbox
  /// session.
  ToolProcessLauncher _toolProcesses(Mode mode) =>
      _launcherFor(_harnessSandboxSessionId, mode);

  /// Starts the debug adapter and its debuggee. A debug session outlives the
  /// run that launched it (one per conversation, up to its TTL), so its
  /// sandbox session is released when the debug session ends.
  ToolProcessLauncher _debugProcesses(Mode mode) =>
      _launcherFor('debug-$_toolSessionKey', mode);

  /// Starts this run's language servers and project checker, with the run's
  /// spec and no loopback reach: a language server never needs the gateway.
  /// They stop when the run ends ([_releaseToolProcesses]).
  ToolProcessLauncher _lspProcesses(Mode mode) =>
      _launcherFor('lsp-$_toolSessionKey', mode, loopbackPorts: const []);

  /// Starts this run's shell hooks, the scripts in [hookFolder]: like every
  /// tool process of the run, with no loopback reach, and with [hookFolder]
  /// readable and executable but never writable.
  ToolProcessLauncher _hookProcesses(Mode mode, String hookFolder) =>
      _launcherFor(
        'hook-$_toolSessionKey',
        mode,
        loopbackPorts: const [],
        toolDirs: [hookFolder],
      );

  /// This agent's folder in the server's hook folder, or null when the
  /// server has none or the run has no agent config dir.
  String? get _hookFolder => agentHookFolder(
    deps.agentHooksRoot,
    workspaceId: workspaceId,
    agentConfigDir: agentConfigDir,
  );

  /// Tells the run's log which hook declarations were not honored and where
  /// the server owner puts hooks instead.
  void _reportHookConfig(HarnessRunConfig config, String? hookFolder) {
    final where = hookFolder == null
        ? 'this server has no hook folder for this agent'
        : 'the server owner puts them in $hookFolder/'
              '${HarnessRunConfig.hooksFileName}';
    if (config.droppedHookBase != null) {
      addEvent(
        DebugEvent(
          content:
              '[harness] ignoring shell hooks declared by '
              '${config.droppedHookBase}/.agents/harness.json: hooks are host '
              'configuration, read only from the server\'s hook folder '
              '($where).',
        ),
      );
    }
    if (config.refusedHooks.isNotEmpty) {
      addEvent(
        DebugEvent(
          content:
              '[harness] refused shell hooks (${config.refusedHooks.join('; ')})'
              '${config.preToolRefused ? '; every tool call is denied until '
                        'the pre-tool gate is fixed' : ''}.',
        ),
      );
    }
  }

  /// Ends what this run's tool launchers started: its language servers stop
  /// and their sandbox sessions are released, except a debug session that is
  /// still running, which releases its own when it ends. Safe to call twice.
  Future<void> _releaseToolProcesses() async {
    for (final launcher in List.of(_toolLaunchers.values)) {
      await deps.lspSupervisor?.closeStartedBy(launcher);
      final conversation = conversationId;
      if (conversation != null &&
          (deps.debugSupervisor?.runsUnder(conversation, launcher) ?? false)) {
        continue;
      }
      await launcher.release();
    }
  }

  /// The live kernel for [language], created on first use.
  ///
  /// **The bridge re-enters the registry, it does not go around it.** A
  /// `tool(...)` call from inside a cell resolves against the SAME tool
  /// registry a model-issued call does, so `ActionClass` guardrails, the
  /// approval callback and every wrapper (diagnostics-on-write included) apply
  /// identically. A bridge that reached past the registry would be a hole in
  /// the guardrails shaped exactly like "write a Python one-liner".
  EvalKernel _kernelFor(
    KernelLanguage language, {
    required HarnessToolRegistry registryForBridge,
    required ToolProcessLauncher hostProcesses,
  }) => _kernels.putIfAbsent(
    language,
    () => EvalKernel(
      language: language,
      launcher: LazyKernelLauncher(
        () => deps.kernelLauncherFactory!(
          workingDirectory: agentDirHostPath,
          hostProcesses: hostProcesses,
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
      ),
      bridge: (name, arguments) async {
        final tool = registryForBridge.findByName(name);
        if (tool == null) {
          return (content: 'Unknown tool: $name', isError: true);
        }
        final result = await tool.execute(
          arguments,
          HarnessToolContext(
            workingDirectory: agentDirHostPath,
            sharedRoots: _workspaceSharedRoots(),
            readOnlyRoots: _readOnlyRoots,
            agentId: agentId,
            workspaceId: workspaceId,
            conversationId: conversationId,
            spaceId: spaceId,
          ),
        );
        return (content: result.content, isError: result.isError);
      },
    ),
  );

  /// One launcher per session and mode for the whole run, so the run's end
  /// can find everything it started.
  ///
  /// Unconfined only when the posture lets runs leave the sandbox (the gate
  /// admitted this one); a server that sandboxes agents but has no manager
  /// wired starts nothing.
  ToolProcessLauncher _launcherFor(
    String sandboxSessionId,
    Mode mode, {
    List<int>? loopbackPorts,
    List<String> toolDirs = const [],
  }) => _toolLaunchers.putIfAbsent(
    '$sandboxSessionId/${mode.name}',
    () => switch (deps.sandboxManager) {
      final manager? => SandboxedToolProcessLauncher(
        manager: manager,
        sessionId: sandboxSessionId,
        spec: (id) => _sandboxSpec(
          id,
          workspaceId ?? '',
          mode: mode,
          loopbackPorts: loopbackPorts,
          extraToolDirs: toolDirs,
        ),
      ),
      null when deps.hostExecution.posture.confined =>
        const RefusingToolProcessLauncher(),
      null => const HostToolProcessLauncher(),
    },
  );

  /// The directories of tools the server wrote for this run: its environment
  /// command shims and git's signer. Executable, never writable: they are on
  /// the run's `PATH`, and git runs its signer from here.
  List<String> get _toolDirs =>
      {?_run.environment.shimDir, ?_runShimDir}.toList();
}

/// Test access to the spec this run's processes are sandboxed with.
@visibleForTesting
extension DispatchSessionSandboxForTesting on DispatchSession {
  /// The spec this run's CLI would get, after writing git's signer when
  /// [signShim] is set (a real run writes it when its gateway lease opens).
  Future<SandboxSpec> sandboxSpecForTesting({bool signShim = false}) async {
    if (signShim) {
      await _writeSignShim(
        deps.agentRunGateway?.client ?? AgentRunClientLauncher.current,
      );
    }
    return _sandboxSpec(_sandboxSessionId, workspaceId ?? '');
  }
}
