part of 'environment_service.dart';

/// What one start may do, and where it writes what it did.
class _StartRun {
  const _StartRun({
    required this.mode,
    required this.by,
    required this.attended,
    required this.log,
  });

  /// Create, resume or reset.
  final _StartMode mode;

  /// Who asked for it.
  final Principal by;

  /// Whether a person is at a client that can show them a terminal.
  final bool attended;

  /// Its run record.
  final EnvironmentRunLog log;
}

/// A terminal a start is running a verb on.
typedef _TerminalRun = ({
  String workspaceId,
  String spaceId,
  String sessionId,
  String owner,
});

/// A start that needs a person, carried on where they can answer.
///
/// A tool that wants a password can't ask through a pipe, so its verb exits 3
/// and says so. A verb the definition lists as `interactive` then runs again
/// on a terminal tab: the tool asks for itself, the answer
/// goes straight to it, and the same start carries on from its exit. What
/// runs is the verb's argv from the approved definition, never a command the
/// tool printed, since that text comes from a process the worktree can
/// influence and would be running with someone's password behind it.
mixin _TerminalOps on _EnvironmentServiceBase {
  /// Terminals a start is running on, by environment.
  final Map<String, _TerminalRun> _terminalRuns = {};

  /// Whether [start] may carry on at a terminal in [stack].
  ///
  /// Only for a person, and one who said they are there to answer: an agent's
  /// start, an automatic one, or one from a surface with no terminal stops and
  /// waits instead. Never for a fork, where nobody's password goes to a
  /// process a stranger's branch can reach.
  bool _mayUseTerminal(_Stack stack, SpaceEnvironment env, _StartRun start) =>
      start.attended &&
      start.by.isUser &&
      start.by != _EnvironmentServiceBase._system &&
      !stack.space.isFork &&
      env.placement == EnvironmentPlacement.host.name;

  /// Runs [verb] of [context]'s component on a terminal and waits for it.
  ///
  /// The component reads `interactive` with the session to open while it runs.
  /// Throws when the verb did not exit 0: [reason] again when nobody answered
  /// in time, so the environment still waits for someone; a plain failure
  /// otherwise, since the terminal has already shown why.
  Future<void> _runOnTerminal({
    required SpaceEnvironment env,
    required _Stack stack,
    required CliContext context,
    required String verb,
    required EnvironmentError reason,
    required EnvironmentRunLog log,
  }) async {
    final component = context.component;
    final owner = 'environment:${env.id}/terminal';
    final ring = EnvironmentLogRing(
      path: p.join(stack.stateDir, 'terminal.log'),
    );
    log.line('[terminal] ${reason.message}');
    final session = await _d.supervisor.startInteractive(
      workspaceId: env.workspaceId,
      spaceId: env.spaceId,
      owner: owner,
      argv: EnvironmentCommandRunner.argvFor(
        component.verbs[verb]!,
        context.values.withAll(const {
          CliEnvironmentComponent.interactiveValue: 'true',
        }),
      ),
      environment: {...context.environment, 'CC_ENV_INTERACTIVE': '1'},
      workingDirectory: context.workingDirectory,
      onOutput: ring.addBytes,
    );
    final entry = (
      workspaceId: env.workspaceId,
      spaceId: env.spaceId,
      sessionId: session.sessionId,
      owner: owner,
    );
    _terminalRuns[env.id] = entry;
    final lines = ring.lines.listen(log.line);
    var timedOut = false;
    final limit = _d.terminalTimeout;
    final deadline = Timer(limit, () {
      timedOut = true;
      unawaited(_endTerminal(entry));
    });
    final int exitCode;
    final bool cancelled;
    try {
      await _setComponent(
        env,
        component.id,
        (state) => state.copyWith(
          state: EnvironmentComponentPhase.interactive.wire,
          sessionId: session.sessionId,
          detail: reason.message,
        ),
      );
      exitCode = await session.exitCode;
    } finally {
      deadline.cancel();
      // Still on record unless [_cancelTerminal] took it.
      cancelled = _terminalRuns.remove(env.id) == null;
      ring.finishLine();
      await lines.cancel();
      await ring.close();
      await _setComponent(
        env,
        component.id,
        (state) => state.copyWith(
          state: EnvironmentComponentPhase.starting.wire,
          clearSessionId: true,
          clearDetail: true,
        ),
      );
    }
    if (timedOut) {
      throw EnvironmentDriverException(
        EnvironmentError(
          code: reason.code,
          message: reason.message,
          hint:
              'Nobody finished it on the terminal within '
              '${limit.inMinutes} min. Start it again when someone can',
          command: reason.command,
          exitCode: reason.exitCode,
        ),
      );
    }
    if (cancelled) {
      throw _EnvironmentServiceBase._failure(
        'cancelled',
        'The start was cancelled while it ran on a terminal',
      );
    }
    if (exitCode != 0) {
      // No exit code on the error: the terminal was the place to answer, so a
      // verb that still says it needs a person there is simply not working.
      // What the tool suggested stays, for whoever does it by hand.
      throw EnvironmentDriverException(
        EnvironmentError(
          code: 'terminal-failed',
          message: exitCode < 0 || exitCode == 130
              ? '${component.displayName} was interrupted on the terminal'
              : '${component.displayName} exited $exitCode on the terminal',
          hint: reason.message,
          command: reason.command,
        ),
      );
    }
    log.line('[terminal] done');
  }

  /// Ends the terminal a start of [env] is running on, so whatever waits for
  /// that start (a stop, a teardown) gets its turn. Does nothing without one.
  Future<void> _cancelTerminal(SpaceEnvironment env) async {
    final entry = _terminalRuns.remove(env.id);
    if (entry != null) {
      await _endTerminal(entry);
    }
  }

  /// [_cancelTerminal] for every environment of a space that is going away.
  Future<void> _cancelTerminalsIn(String workspaceId, String spaceId) async {
    final ids = [
      for (final MapEntry(:key, :value) in _terminalRuns.entries)
        if (value.workspaceId == workspaceId && value.spaceId == spaceId) key,
    ];
    for (final id in ids) {
      final entry = _terminalRuns.remove(id);
      if (entry != null) {
        await _endTerminal(entry);
      }
    }
  }

  Future<void> _endTerminal(_TerminalRun entry) async {
    try {
      await _d.supervisor.stopInteractive(
        workspaceId: entry.workspaceId,
        sessionId: entry.sessionId,
        owner: entry.owner,
      );
    } on Object catch (e) {
      CcInfraLog.warning('terminal ${entry.sessionId} not ended: $e');
    }
  }
}
