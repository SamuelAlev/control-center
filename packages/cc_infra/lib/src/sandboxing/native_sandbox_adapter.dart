// The per-session StreamControllers/processes are stored in maps and closed/
// killed in `destroy()` (per session) and `dispose()` (any still-open at
// shutdown). `close_sinks` can't track that cross-method closure, so it flags
// false positives on the map assignments — suppressed deliberately.
// ignore_for_file: close_sinks, unnecessary_lambdas

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/linux_sandbox.dart';
import 'package:cc_infra/src/sandboxing/process_group_supervisor.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/sandbox_process_io.dart';
import 'package:cc_infra/src/sandboxing/stdin_pipe.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// `SandboxPort` implementation that wraps each command with the in-project
/// native sandbox runtime: `sandbox-exec` (Seatbelt) on macOS, `bubblewrap`
/// on Linux/WSL2.
///
/// Lifecycle:
///   - [launch] computes a [SandboxConfig] from the [SandboxSpec] and stashes
///     it on the handle. There's no long-lived "container" — the sandbox is
///     applied on every [exec].
///   - [exec] asks [SandboxManager.wrap] for the spawn argv + proxy env,
///     forks via `Process.start` and forwards stdout/stderr/exit on the
///     handle's event stream.
///   - [destroy] tells the manager to clean per-session temp files
///     (Seatbelt profiles, Linux socket bridges) and closes the stream.
class NativeSandboxAdapter implements SandboxPort {
  /// Creates a [NativeSandboxAdapter] bound to [_manager].
  NativeSandboxAdapter({required this._manager}) {
    _violationSub = _manager.violations.listen(_dispatchViolation);
  }

  final SandboxManager _manager;
  final Map<String, StreamController<SandboxEvent>> _streams = {};
  final Map<String, Process> _processes = {};
  final Map<String, SandboxConfig> _configs = {};
  final Map<String, SandboxHandle> _handles = {};
  final Map<String, List<String>> _mounts = {};
  final Set<String> _supervised = {};
  StreamSubscription<SandboxViolation>? _violationSub;

  @override
  SandboxBackend get backend => SandboxBackend.native;

  @override
  Future<SandboxBackendCapabilities> probe() async {
    if (Platform.isMacOS) {
      // `sandbox-exec` is part of every macOS install.
      return const SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: true,
        note:
            'macOS sandbox-exec (Seatbelt) — namespace isolation, no kernel boundary.',
      );
    }
    final isLinuxLike = Platform.isLinux || LinuxSandbox.isWsl2();
    if (isLinuxLike) {
      final hasBwrap = await _hasOnPath('bwrap');
      final hasSocat = await _hasOnPath('socat');
      final missing = <String>[
        if (!hasBwrap) 'bubblewrap',
        if (!hasSocat) 'socat',
      ];
      return SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: missing.isEmpty,
        requiresInstall: missing.isNotEmpty,
        installHint: missing.isEmpty
            ? null
            : 'Install missing tools: ${missing.join(', ')} '
                  '(e.g. `sudo apt-get install ${missing.join(' ')}`)',
        note: 'Linux bubblewrap — namespace isolation, no kernel boundary.',
      );
    }
    return const SandboxBackendCapabilities(
      backend: SandboxBackend.native,
      available: false,
      note: 'Native sandbox is not yet supported on this platform.',
    );
  }

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async {
    _streams[spec.sessionId] = StreamController<SandboxEvent>.broadcast();
    _configs[spec.sessionId] = await _buildConfigForSpec(spec);
    // Linux needs no watcher: bwrap's `--die-with-parent --unshare-pid` already
    // ends the tree with its parent.
    if (spec.superviseProcessGroup && Platform.isMacOS) {
      _supervised.add(spec.sessionId);
    }
    _mounts[spec.sessionId] = [
      for (final m in spec.bindMounts)
        if (m.hostPath.isNotEmpty) m.hostPath,
    ];
    final handle = SandboxHandle(
      sessionId: spec.sessionId,
      backend: SandboxBackend.native,
      state: SandboxState.warm,
      details: {'workingDirectory': _defaultDirFor(spec)},
    );
    _handles[spec.sessionId] = handle;
    _streams[spec.sessionId]?.add(
      const SandboxEvent(type: SandboxEventType.ready),
    );
    return handle;
  }

  @override
  Future<bool> isAlive(SandboxHandle handle) async {
    final current = _handles[handle.sessionId];
    if (current == null) {
      return false;
    }
    return current.state != SandboxState.destroyed &&
        current.state != SandboxState.error;
  }

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) {
    final controller = _streams.putIfAbsent(
      handle.sessionId,
      () => StreamController<SandboxEvent>.broadcast(),
    );
    return controller.stream;
  }

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
    Stream<String>? stdinStream,
  }) async {
    if (argv.isEmpty) {
      throw ArgumentError('argv must not be empty');
    }
    final config = _configs[handle.sessionId];
    if (config == null) {
      throw StateError('no sandbox config for session ${handle.sessionId}');
    }

    _updateState(handle.sessionId, SandboxState.active);
    final controller = _streams[handle.sessionId];
    // `destroy` closes the session's stream while a killed child can still be
    // flushing stdout/stderr (and before its exit code is reaped); adding to
    // the closed controller then was an uncaught zone error per late line.
    void emit(SandboxEvent event) {
      if (controller != null && !controller.isClosed) {
        controller.add(event);
      }
    }

    final workingDirectory =
        workdir ??
        _handles[handle.sessionId]?.details['workingDirectory'] as String?;

    final wrap = await _manager.wrap(
      config: config,
      argv: argv,
      workingDirectory: workingDirectory,
    );

    // The allowlisted child environment (base + toolchain, provider secrets
    // and injection vectors stripped), then the proxy env (re-adds the safe
    // GIT_SSH_COMMAND), then the dispatch env on top.
    final mergedEnv = <String, String>{...wrap.environment, ...?env};

    final launch = _supervised.contains(handle.sessionId)
        ? superviseProcessGroup(wrap.executable, wrap.argv)
        : (executable: wrap.executable, argv: wrap.argv);
    final process = await ChildProcess.start(
      launch.executable,
      launch.argv,
      workingDirectory: workingDirectory,
      environment: mergedEnv,
      toolchain: true,
    );
    // One live child per session. Overwriting the map entry used to strand the
    // previous process — unkillable by `destroy`, invisible to `dispose` —
    // and session reuse is warm, so overlapping execs on the same
    // agent+conversation+mode are reachable.
    final previous = _processes[handle.sessionId];
    if (previous != null) {
      CcInfraLog.warning(
        'sandbox ${handle.sessionId}: a second exec started while one was '
        'still running — terminating the previous child (pid ${previous.pid})',
      );
      previous.kill();
    }
    _processes[handle.sessionId] = process;
    onPid?.call(process.pid);

    // Always settle stdin — a CLI that reads it hangs forever otherwise.
    settleStdin(process, input: stdinInput, stream: stdinStream);

    // Linux reports denials only on the child's own stderr, so they are known
    // to belong to THIS session and go straight onto its stream.
    final linux = Platform.isLinux || LinuxSandbox.isWsl2();
    final forwardings = [
      ProcessLineForwarding.start(
        process.stdout,
        (line) =>
            emit(SandboxEvent(type: SandboxEventType.stdout, content: line)),
      ),
      ProcessLineForwarding.start(process.stderr, (line) {
        emit(SandboxEvent(type: SandboxEventType.stderr, content: line));
        final violation = linux ? SandboxManager.parseLinuxDenial(line) : null;
        if (violation != null) {
          emit(_violationEvent(violation));
        }
      }),
    ];

    final exitCode = await awaitExitWithTimeout(
      process,
      timeout,
      (message) =>
          emit(SandboxEvent(type: SandboxEventType.stderr, content: message)),
    );
    // Every line BEFORE the exit event, and before `exec` returns: a caller
    // that stops parsing once the exec is over (Claude's stream-json reader)
    // would otherwise lose or misread the last lines — the turn's `result`.
    await drainForwardings(forwardings);
    if (identical(_processes[handle.sessionId], process)) {
      _processes.remove(handle.sessionId);
    }
    emit(SandboxEvent(type: SandboxEventType.exit, exitCode: exitCode));
    _updateState(handle.sessionId, SandboxState.warm);
    return exitCode;
  }

  static SandboxEvent _violationEvent(SandboxViolation violation) =>
      SandboxEvent(
        type: SandboxEventType.violation,
        content: '${violation.action} ${violation.target}',
        violation: violation,
      );

  /// Routes a host-wide denial (macOS `log stream`) to the session it belongs
  /// to, among every session with a live child.
  ///
  /// One `_activeSession` field used to name "the" running session, so with two
  /// concurrent runs every denial — and the exec-grant offer it triggers —
  /// went to whichever started last. Now: the session whose child IS the
  /// denied pid; else the one session whose own directories hold the denied
  /// path; else, with exactly one live session, that one. A denial that fits
  /// none of those is dropped rather than shown to (and offered as a grant
  /// to) a run that did not cause it.
  void _dispatchViolation(SandboxViolation violation) {
    final id = sessionForViolation(violation);
    if (id == null) {
      if (_processes.isNotEmpty) {
        CcInfraLog.debug(
          'sandbox: denial ${violation.action} ${violation.target} matched no '
          'single live session — not attributed',
        );
      }
      return;
    }
    final controller = _streams[id];
    if (controller != null && !controller.isClosed) {
      controller.add(_violationEvent(violation));
    }
  }

  /// The session [violation] belongs to, or null when it cannot be told.
  String? sessionForViolation(SandboxViolation violation) => routeViolation(
    violation,
    livePids: {
      for (final MapEntry(:key, :value) in _processes.entries) key: value.pid,
    },
    rootsOf: _rootsOf,
  );

  /// Picks the session among [livePids] (session id → its live child's pid)
  /// that [violation] belongs to: the one whose child is the denied pid; else
  /// the one session whose directories ([rootsOf]) hold the denied path;
  /// else, with exactly one live session, that one. Null when none of those
  /// tell — a guess would offer the wrong run an exec grant.
  @visibleForTesting
  static String? routeViolation(
    SandboxViolation violation, {
    required Map<String, int> livePids,
    required List<String> Function(String sessionId) rootsOf,
  }) {
    if (livePids.isEmpty) {
      return null;
    }
    final pid = violation.pid;
    if (pid != null) {
      for (final MapEntry(:key, :value) in livePids.entries) {
        if (value == pid) {
          return key;
        }
      }
    }
    final target = violation.target;
    if (p.isAbsolute(target)) {
      final owners = [
        for (final id in livePids.keys)
          if (rootsOf(
            id,
          ).any((root) => p.equals(root, target) || p.isWithin(root, target)))
            id,
      ];
      if (owners.length == 1) {
        return owners.single;
      }
      if (owners.length > 1) {
        return null;
      }
    }
    return livePids.length == 1 ? livePids.keys.single : null;
  }

  /// The host directories a session's child works in: its bind mounts and
  /// default working directory.
  List<String> _rootsOf(String sessionId) => [
    ...?_mounts[sessionId],
    if (_handles[sessionId]?.details['workingDirectory'] case final String dir)
      dir,
  ];

  @override
  Future<void> pause(SandboxHandle handle) async {
    _updateState(handle.sessionId, SandboxState.suspended);
  }

  @override
  Future<void> resume(SandboxHandle handle) async {
    _updateState(handle.sessionId, SandboxState.warm);
  }

  @override
  Future<void> destroy(SandboxHandle handle) async {
    // SIGTERM → 3s → SIGKILL, awaited: a child that traps SIGTERM otherwise
    // outlives the "destroyed" sandbox, holding its worktree and its egress.
    final process = _processes.remove(handle.sessionId);
    if (process != null) {
      await terminateProcess(process);
    }
    _configs.remove(handle.sessionId);
    _mounts.remove(handle.sessionId);
    _supervised.remove(handle.sessionId);
    await _streams.remove(handle.sessionId)?.close();
    await _manager.disposeSession(handle.sessionId);
    _updateState(handle.sessionId, SandboxState.destroyed);
    _handles.remove(handle.sessionId);
  }

  /// Stops listening for violations. Called by the Riverpod provider when the
  /// adapter is being disposed (e.g. app shutdown).
  Future<void> dispose() async {
    await _violationSub?.cancel();
    _violationSub = null;
    // Close any still-open per-session controllers and kill their processes so
    // a dispose with live sessions (e.g. app shutdown) doesn't leak them.
    for (final process in _processes.values) {
      process.kill();
    }
    _processes.clear();
    for (final controller in _streams.values) {
      await controller.close();
    }
    _streams.clear();
    _configs.clear();
    _mounts.clear();
    _handles.clear();
  }

  Future<SandboxConfig> _buildConfigForSpec(SandboxSpec spec) =>
      processSandboxConfig(spec);

  String? _defaultDirFor(SandboxSpec spec) {
    if (spec.guestWorkdir != null) {
      return spec.guestWorkdir;
    }
    if (spec.bindMounts.isNotEmpty) {
      return spec.bindMounts.first.hostPath;
    }
    return null;
  }

  void _updateState(String sessionId, SandboxState state) {
    final current = _handles[sessionId];
    if (current != null) {
      _handles[sessionId] = current.copyWith(state: state);
    }
  }

  Future<bool> _hasOnPath(String binary) async {
    try {
      final result = await ChildProcess.run('which', [binary]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
