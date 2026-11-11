part of 'dispatch_session.dart';

extension _AcpMethods on DispatchSession {
  /// `<cliPath> <acpArgs> <argsOverride>` inside the run's sandbox, speaking
  /// JSON-RPC 2.0 over stdio and translating `session/update` notifications
  /// into events.
  ///
  /// The agent runs through the same `SandboxPort` as `claude -p` — same spec,
  /// same handle reuse, same kill on stop — and never outside one: with no OS
  /// sandbox on this host the run is refused. It used to spawn the agent
  /// directly with only a warning in the server log, which made "pick an ACP
  /// adapter" a way to run an agent with the operator's full reach.
  ///
  /// The agent's own requests are answered here: `session/request_permission`
  /// goes through the action policy and the space's autonomy dial like every
  /// other runtime's approvals, and `fs/*` reads and writes only inside the
  /// run's own directories.
  Future<void> _runAcp({
    required String sandboxSessionId,
    required String wsId,
  }) async {
    final backend = deps.backendRegistry.backendFor(cliName)!;

    if (deps.sandboxManager == null) {
      addEvent(
        ErrorEvent(
          content:
              '[acp] $cliName needs the OS sandbox, which is not available on '
              'this server (Settings → Security → Sandboxing). Control Center '
              'does not run ACP agents unsandboxed.',
        ),
      );
      _finish(exitCode: 126);
      return;
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
      _finish(exitCode: 127);
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
    final mergedEnv = _mergedEnv(backendEnv: backend.defaultEnv());

    addEvent(DebugEvent(content: '[acp] launching $cliName…'));
    final handle = await _launchSandbox(sandboxSessionId, wsId);

    // Closed in the `finally` below and by `_teardownAcp`.
    // ignore: close_sinks
    final stdin = StreamController<String>();
    _acpStdin = stdin;
    final client = AcpClient(
      send: (line) {
        if (!stdin.isClosed) {
          stdin.add('$line\n');
        }
      },
      onRequest: _answerAcpRequest,
    );
    _acpClient = client;
    // Stdout lines reach the client through `_forwardSandboxEvent`.
    eventsSub = deps.sandbox.events(handle).listen(_forwardSandboxEvent);
    final acpEventsSub = client.events.listen(addEvent);

    final exited = deps.sandbox.exec(
      handle,
      argv,
      env: mergedEnv,
      onPid: (forkedPid) {
        _onPidAvailable(forkedPid);
        addEvent(
          DebugEvent(content: '[acp] $cliName running (pid $forkedPid)'),
        );
      },
      stdinStream: stdin.stream,
    );
    // An agent that dies mid-handshake would otherwise leave every pending
    // request waiting forever.
    unawaited(
      exited.then((_) => client.close(), onError: (Object _) => client.close()),
    );

    int? exitCode;
    Object? failure;
    try {
      await client.initialize();
      final sessionId = await client.sessionNew(
        cwd: agentDirHostPath,
        model: modelId,
        mcpConfigPath: mcpConfigPath,
      );
      await client.sessionPrompt(
        sessionId: sessionId,
        prompt: '$agentCommitAttributionInstruction\n\n$prompt',
      );
      exitCode = 0;
      addEvent(DebugEvent(content: '[acp] $cliName turn complete'));
    } on Object catch (e) {
      if (!_cancelSource.isCancelled) {
        exitCode = 1;
        failure = e;
        addEvent(ErrorEvent(content: '[acp] $cliName failed: $e'));
      }
    } finally {
      _acpClient = null;
      _acpStdin = null;
      await acpEventsSub.cancel();
      await client.close();
      // End of stdin is an ACP agent's cue to exit; one that does not is
      // stopped like any other child.
      await stdin.close();
      try {
        await exited.timeout(const Duration(seconds: 5));
      } on Object {
        await _killActiveProcess('ACP turn end');
      }
      await _drainSandboxEvents();
    }
    if (_cancelSource.isCancelled) {
      return;
    }
    _finish(exitCode: exitCode, error: failure);
  }

  /// Answers one request the ACP agent sent this client.
  Future<Object?> _answerAcpRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    switch (method) {
      case 'session/request_permission':
        return _answerAcpPermission(params);
      case 'fs/read_text_file':
        return _acpReadTextFile(params);
      case 'fs/write_text_file':
        return _acpWriteTextFile(params);
    }
    throw AcpRpcException(
      'Control Center does not support $method',
      code: AcpClient.methodNotFound,
    );
  }

  /// `session/request_permission`: the agent asks before a tool call. The
  /// answer comes from the action policy, the space's autonomy dial and — when
  /// either asks — the operator, exactly as for the harness and Claude Code.
  Future<Object?> _answerAcpPermission(Map<String, dynamic> params) async {
    final options = [
      for (final o in params['options'] as List? ?? const [])
        if (o is Map) o.cast<String, dynamic>(),
    ];
    String? optionOf(List<String> kinds) {
      for (final kind in kinds) {
        for (final o in options) {
          if (o['kind'] == kind && o['optionId'] is String) {
            return o['optionId'] as String;
          }
        }
      }
      return null;
    }

    const cancelled = {
      'outcome': {'outcome': 'cancelled'},
    };
    if (_cancelSource.isCancelled) {
      return cancelled;
    }
    final toolCall = params['toolCall'];
    final call = toolCall is Map
        ? toolCall.cast<String, dynamic>()
        : <String, dynamic>{};
    final allowed = await _approveAcpToolCall(call);
    // Only ever a ONE-time answer: an `allow_always` would let the agent skip
    // asking next time, outside every rule this run is held to.
    final option = allowed
        ? optionOf(const ['allow_once'])
        : optionOf(const ['reject_once', 'reject_always']);
    if (option == null) {
      return cancelled;
    }
    return {
      'outcome': {'outcome': 'selected', 'optionId': option},
    };
  }

  /// Whether the tool call an ACP agent asked about may run.
  Future<bool> _approveAcpToolCall(Map<String, dynamic> call) async {
    final kind = call['kind']?.toString() ?? 'other';
    final title = call['title']?.toString() ?? kind;
    final rawInput = call['rawInput'];
    final input = rawInput is Map
        ? rawInput.cast<String, dynamic>()
        : const <String, dynamic>{};
    final command = input['command'] is String
        ? input['command'] as String
        : null;
    final paths = <String>[
      for (final l in call['locations'] as List? ?? const [])
        if (l is Map && l['path'] is String) l['path'] as String,
    ];

    // What the call does, in the policy's terms.
    final classes = <ActionClass>{};
    switch (kind) {
      case 'read' || 'search' || 'think':
        // The sandbox decides what a read can see; there is nothing to ask.
        return true;
      case 'edit' || 'delete' || 'move':
        final readOnly = [
          for (final path in paths)
            ?ReadOnlyWorktrees.containing(path, _readOnlyWorktrees),
        ];
        if (readOnly.isNotEmpty) {
          addEvent(
            DebugEvent(
              content:
                  '[acp] "$title" denied: '
                  '${ReadOnlyWorktrees.refusal(readOnly.first)}',
            ),
          );
          return false;
        }
        final roots = await _acpRoots(write: true);
        for (final path in paths) {
          final resolved = _resolveExistingAncestor(path);
          if (!roots.any(
            (r) => p.equals(r, resolved) || p.isWithin(r, resolved),
          )) {
            classes.add(ActionClass.fileWriteOutsideWorktree);
          }
        }
        if (kind == 'delete') {
          classes.add(ActionClass.fileDelete);
        }
      case 'execute':
        if (command != null && command.trim().isNotEmpty) {
          classes.addAll(const ShellActionClassifier().classify(command));
        }
      case 'fetch':
        classes.add(ActionClass.networkEgress);
    }
    final autonomy = await _resolveAutonomy();
    final guard = deps.actionGuard;
    final ws = workspaceId;
    if (guard != null && ws != null && ws.isNotEmpty && classes.isNotEmpty) {
      final verdict = await guard.check(
        workspaceId: ws,
        classes: classes,
        command: command,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        mode: mode,
        actionSummary: 'acp $kind: $title',
        onBehalfOfUserId: requestedByUserId,
        runId: runLogId,
        request: ActionRequest(
          classes: classes,
          command: command,
          paths: paths,
        ),
        autonomy: autonomy,
        withdrawn: _cancelSource.token.whenCancelled,
      );
      if (!verdict.allowed) {
        addEvent(
          DebugEvent(
            content: '[acp] "$title" denied: ${verdict.reason ?? 'denied'}',
          ),
        );
      }
      return verdict.allowed;
    }
    // The agent asked although no rule governs the call. The dial decides,
    // then a human — as the harness gate does for its approval-tier tools.
    if (autonomy == AutonomyLevel.proposeOnly) {
      addEvent(
        DebugEvent(content: '[acp] "$title" denied: $kProposeOnlyReason'),
      );
      return false;
    }
    if (autonomy == AutonomyLevel.actFreely) {
      return true;
    }
    final port = deps.confirmationPort;
    if (port == null) {
      addEvent(
        DebugEvent(
          content:
              '[acp] "$title" needs approval but no approver is connected — '
              'denied',
        ),
      );
      return false;
    }
    final asked = classes.isEmpty
        ? ActionGuardService.undeclaredEffect
        : classes;
    final copy = ActionApprovalCopy.describe(classes: asked, command: command);
    final detail = '${copy.detail}\n\n$title';
    final cardKind = kind == 'execute'
        ? ConfirmationKind.command
        : ConfirmationKind.fileWrite;
    if (kind == 'execute' && command != null && command.trim().isNotEmpty) {
      // A command the classifier names no effect for is still a process the
      // agent runs, and a person may approve that exact command for a while.
      return ActionGuardService.confirmCommand(
        guard: guard,
        port: port,
        workspaceId: ws,
        classes: asked,
        command: command,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        mode: mode,
        actionSummary: 'acp $kind: $title',
        onBehalfOfUserId: requestedByUserId,
        runId: runLogId,
        detail: detail,
        kind: cardKind,
        withdrawn: _cancelSource.token.whenCancelled,
      );
    }
    // Not a command: policy names no effect for this call (or cannot be
    // asked), so there is nothing a standing approval could rest on and this
    // card confirms this one call.
    return port.requestApproval(
      ActionGuardService.approvalRequest(
        resolution: null,
        classes: asked,
        command: command,
        spaceId: spaceId,
        conversationId: conversationId,
        workspaceId: workspaceId,
        agentId: agentId,
        actionSummary: 'acp $kind: $title',
        detail: detail,
        kind: cardKind,
        withdrawn: _cancelSource.token.whenCancelled,
      ),
    );
  }

  /// `fs/read_text_file`: a file inside the run's own directories.
  Future<Object?> _acpReadTextFile(Map<String, dynamic> params) async {
    final path = await _acpPath(params['path'], write: false);
    final file = File(path);
    if (!file.existsSync()) {
      throw AcpRpcException('No such file: $path');
    }
    final content = await file.readAsString();
    final line = params['line'];
    final limit = params['limit'];
    if (line is! int && limit is! int) {
      return {'content': content};
    }
    final lines = const LineSplitter().convert(content);
    final start = line is int && line > 1 ? line - 1 : 0;
    final end = limit is int && limit >= 0
        ? (start + limit).clamp(start, lines.length)
        : lines.length;
    return {
      'content': start >= lines.length
          ? ''
          : lines.sublist(start, end).join('\n'),
    };
  }

  /// `fs/write_text_file`: only inside the run's writable directories, and
  /// never in a read-only mode — the same ground the sandbox lets the agent
  /// write itself, because this write happens OUTSIDE the sandbox.
  Future<Object?> _acpWriteTextFile(Map<String, dynamic> params) async {
    if (mode != Mode.chat) {
      throw AcpRpcException(
        'Writing files is not allowed in ${mode.name} mode.',
      );
    }
    final content = params['content'];
    if (content is! String) {
      throw AcpRpcException('fs/write_text_file needs string content');
    }
    final path = await _acpPath(params['path'], write: true);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return null;
  }

  /// [raw] as a resolved absolute path inside the run's directories, or an
  /// [AcpRpcException] saying why not.
  Future<String> _acpPath(Object? raw, {required bool write}) async {
    if (raw is! String || raw.trim().isEmpty || !p.isAbsolute(raw)) {
      throw AcpRpcException('An absolute path is required.');
    }
    final resolved = _resolveExistingAncestor(raw);
    final roots = await _acpRoots(write: write);
    final inside = roots.any(
      (r) => p.equals(r, resolved) || p.isWithin(r, resolved),
    );
    if (!inside) {
      throw AcpRpcException('$raw is outside this run\'s working directory.');
    }
    for (final protected in await _protectedPaths()) {
      if (protected.isEmpty) {
        continue;
      }
      final root = _resolveExistingAncestor(protected);
      if (write && (p.equals(root, resolved) || p.isWithin(root, resolved))) {
        throw AcpRpcException('$raw is a protected checkout.');
      }
    }
    final readOnly = write
        ? ReadOnlyWorktrees.containing(resolved, _readOnlyWorktrees)
        : null;
    if (readOnly != null) {
      throw AcpRpcException(ReadOnlyWorktrees.refusal(readOnly));
    }
    return resolved;
  }

  /// The directories `fs/*` may touch, symlinks resolved: the cwd and the
  /// shared worktrees (writable); reads also reach the agent's config and the
  /// space's attachments, which are mounted read-only.
  Future<List<String>> _acpRoots({required bool write}) async {
    final layout = _layout;
    return [
      agentDirHostPath,
      ?layout.reposDir,
      if (!write) ...[?agentConfigDir, ?layout.attachmentsDir],
    ].where((r) => r.isNotEmpty).map(_resolveExistingAncestor).toList();
  }
}

/// [path] with `..` and symlinks gone, so neither can walk an access out of
/// its directory. A path that does not exist yet resolves through its deepest
/// ancestor that does.
String _resolveExistingAncestor(String path) {
  var existing = p.normalize(path);
  final missing = <String>[];
  while (true) {
    try {
      return p.joinAll([
        File(existing).resolveSymbolicLinksSync(),
        ...missing.reversed,
      ]);
    } on FileSystemException {
      final parent = p.dirname(existing);
      if (parent == existing) {
        return p.joinAll([existing, ...missing.reversed]);
      }
      missing.add(p.basename(existing));
      existing = parent;
    }
  }
}
