part of 'dispatch_session.dart';

/// What this run's sandbox is handed. Everything else under the server's data
/// directory stays hidden from it (the sandbox manager hides the whole tree),
/// so a path the run needs must be named here.
extension _DispatchSessionSandbox on DispatchSession {
  /// Asked before anything of the run starts: on a host with no sandbox, only
  /// work the server owner is accountable for may run there. A refused run
  /// ends with the refusal as its error.
  Future<bool> _admittedOnHost() async {
    // A read-only run is read-only because the sandbox mounts its worktree
    // read-only: without one it is refused, whoever asked, never started
    // bare with only the tools held back.
    if (readOnly &&
        (deps.hostExecution.posture != HostExecutionPosture.sandboxed ||
            deps.sandboxManager == null)) {
      const refusal = ReadOnlyRunUnavailableException();
      _failRun(refusal.message, code: refusal.code);
      _finish(error: refusal);
      return false;
    }
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
  /// with no RO mode — convention only). Fallback/oneshot: writable cwd, plus
  /// the space's `attachments/` **ro** when the run is in a space with
  /// nothing to check out — its prompt names files there all the same.
  /// Sibling agent dirs and other spaces are never mounted.
  List<SandboxBindMount> _bindMounts() {
    final cwd = agentDirHostPath;
    final layout = _layout;
    if (!layout.isOverlay) {
      final attachmentsPath = layout.attachmentsDir;
      return [
        SandboxBindMount(hostPath: cwd, guestPath: cwd),
        if (attachmentsPath != null)
          SandboxBindMount(
            hostPath: attachmentsPath,
            guestPath: attachmentsPath,
            readOnly: true,
          ),
      ];
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
  EvalKernel _kernelFor(
    KernelLanguage language, {
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

  /// The run, agent and conversation an exec-grant card names: a run the
  /// server started waits the workspace's unattended expiry on it.
  ExecGrantAsker get _execGrantAsker =>
      (runId: runLogId, agentId: agentId, conversationId: conversationId);

  /// Resolves the operator-approved exec roots for this session, asking once
  /// per undecided tree. Returns empty when no grant service is wired, which
  /// leaves the exec block fully closed.
  ///
  /// Also the harness `bash` tool's resolver (per command, so an answer lands
  /// on the next one): the tool's own cwd is deliberately NOT the candidate —
  /// it is a subdirectory of these roots, and naming it would make each `cd` a
  /// fresh unknown tree and re-ask on it.
  Future<List<String>> _resolveExecGrantRoots(String wsId) async {
    final service = deps.execGrantService;
    if (service == null || wsId.isEmpty) {
      return const [];
    }
    try {
      return await service.approvedRoots(
        workspaceId: wsId,
        candidateRoots: _execGrantCandidateRoots(),
        managedRoots: await _managedExecGrantRoots(),
        spaceId: spaceId,
        asker: _execGrantAsker,
        runAsks: _execGrantAsks,
      );
    } on Object catch (e) {
      // A failed lookup must not take the dispatch down with it: the run
      // proceeds under the stricter, pre-grant rules.
      CcInfraLog.warning(
        'dispatch $dispatchId: exec-grant resolution failed, '
        'continuing without grants: $e',
      );
      return const [];
    }
  }

  /// Offers a grant for a `process-exec` denial the sandbox reported.
  ///
  /// Deliberately AFTER the fact and deliberately not blocking: a Seatbelt
  /// profile is fixed when the process starts, so the exec that was just
  /// refused cannot be retried under a new answer. The approval applies from
  /// the next command (the harness rebuilds its profile per command) or the
  /// next dispatch — which the confirmation copy says outright, rather than
  /// letting the operator approve and watch it fail again.
  Future<void> _maybeOfferExecGrant(SandboxViolation v) async {
    final service = deps.execGrantService;
    final wsId = workspaceId ?? '';
    final action = v.action;
    final target = v.target;
    if (service == null ||
        wsId.isEmpty ||
        !action.startsWith('process-exec') ||
        target.isEmpty ||
        !_execGrantAsks.offering.add(target)) {
      return;
    }
    try {
      final granted = await service.recordDeniedExec(
        workspaceId: wsId,
        deniedPath: target,
        candidateRoots: _execGrantCandidateRoots(),
        managedRoots: await _managedExecGrantRoots(),
        spaceId: spaceId,
        asker: _execGrantAsker,
        runAsks: _execGrantAsks,
      );
      if (granted != null) {
        addEvent(
          DebugEvent(
            content:
                '[sandbox] allowed running programs under $granted — '
                'takes effect on the next command',
          ),
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning(
        'dispatch $dispatchId: exec-grant prompt failed for $target: $e',
      );
    } finally {
      _execGrantAsks.offering.remove(target);
    }
  }
}
