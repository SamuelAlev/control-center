part of 'dispatch_session.dart';

extension _AcpMethods on DispatchSession {
  /// `<cliPath> <acpArgs> <argsOverride>` as a subprocess, speaks JSON-RPC 2.0
  /// over stdio and translates `session/update` notifications into events.
  Future<void> _runAcp({
    required AgentCapabilities caps,
    required List<String> scopedNotes,
  }) async {
    final backend = deps.backendRegistry.backendFor(cliName)!;
    for (final note in scopedNotes) {
      addEvent(DebugEvent(content: '[acp] $note'));
    }

    final cliPath = await resolveBinary(cliName);
    if (cliPath == null) {
      addEvent(
        ErrorEvent(
          content:
              '[acp] "$cliName" not found. Install it on your host '
              'or check Settings → Adapters for the detected path.',
        ),
      );
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    final mcpConfigPath = await _resolveMcpConfigPath();
    final argv = <String>[
      cliPath,
      if (backend.acpArgs != null && backend.acpArgs!.isNotEmpty)
        backend.acpArgs!,
      ...adapterArgsOverride,
    ];

    if (!await _preflightCommand(argv)) {
      return;
    }
    final mergedEnv = _mergedEnv(
      caps: caps,
      scopedEnv: const {},
      backendEnv: backend.defaultEnv(),
    );

    addEvent(DebugEvent(content: '[acp] launching $cliName…'));

    late Process process;
    try {
      final manager = deps.sandboxManager;
      final sanitizedParent = const EnvSanitizer().hardenPlatform({});
      if (manager != null) {
        // Route through the OS sandbox (sandbox-exec / bwrap).
        final config = await _buildSandboxConfig(caps);
        final wrap = await manager.wrap(
          config: config,
          argv: argv,
          workingDirectory: agentDirHostPath,
        );
        process = await Process.start(
          wrap.executable,
          wrap.argv,
          workingDirectory: agentDirHostPath,
          environment: {...sanitizedParent, ...wrap.environment, ...mergedEnv},
          includeParentEnvironment: false,
          runInShell: false,
        );
      } else {
        CcInfraLog.warning(
          '[acp] No native sandbox available; '
          'spawning $cliName with env sanitization only.',
        );
        process = await Process.start(
          cliPath,
          argv.skip(1).toList(),
          workingDirectory: agentDirHostPath,
          environment: {...sanitizedParent, ...mergedEnv},
          includeParentEnvironment: false,
          runInShell: false,
        );
      }
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[acp] failed to start $cliName: $e'));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }
    _acpProcess = process;
    this.pid = process.pid;
    _onPidAvailable(process.pid);
    addEvent(
      DebugEvent(content: '[acp] $cliName running (pid ${process.pid})'),
    );

    final client = AcpClient(
      send: (line) {
        try {
          process.stdin.writeln(line);
        } on Object catch (_) {
          // stdin may already be closed after a crash; ignore.
        }
      },
      onDone: () {},
    );
    _acpClient = client;

    // Pipe stdout → newline-delimited JSON-RPC lines into the client.
    final lineStream = process.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter());
    final stdoutSub = lineStream.listen(client.feedLine);
    process.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) => addEvent(ErrorEvent(content: '[acp] $line')));

    // Forward structured events to the session stream.
    _acpEventsSub = client.events.listen(addEvent);

    try {
      await client.initialize();
      final sessionId = await client.sessionNew(
        cwd: agentDirHostPath,
        model: modelId,
        mcpConfigPath: mcpConfigPath,
      );
      await client.sessionPrompt(sessionId: sessionId, prompt: prompt);
      unawaited(_closeRunLog(exitCode: 0));
      addEvent(DebugEvent(content: '[acp] $cliName turn complete'));
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[acp] $cliName failed: $e'));
      unawaited(_closeRunLog(exitCode: 1, error: e));
    } finally {
      await stdoutSub.cancel();
      await _acpEventsSub?.cancel();
      _acpEventsSub = null;
      await client.close();
      _acpProcess?.kill();
      _acpProcess = null;
      addEvent(DoneEvent());
      _completeRun();
    }
  }
}
