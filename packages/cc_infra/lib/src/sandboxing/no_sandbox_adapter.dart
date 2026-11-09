// Controllers and processes here are owned by the adapter for the lifetime
// of each sandbox session and are closed/killed in `destroy()` — these
// lints flag false positives.
// ignore_for_file: close_sinks, unnecessary_lambdas

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/process_group_supervisor.dart';
import 'package:cc_infra/src/sandboxing/sandbox_process_io.dart';
import 'package:cc_infra/src/sandboxing/stdin_pipe.dart';

/// `SandboxPort` implementation that intentionally provides no isolation —
/// `exec` is a direct `Process.start` on the host. Users opt into this from
/// Settings → Security → Sandboxing when they explicitly want the old
/// behavior. Every chat header should show a red "No isolation" banner
/// whenever this adapter is in use.
class NoSandboxAdapter implements SandboxPort {
  /// Creates a [NoSandboxAdapter].
  NoSandboxAdapter();

  final Map<String, StreamController<SandboxEvent>> _streams = {};
  final Map<String, Process> _processes = {};
  final Map<String, SandboxHandle> _handles = {};
  final Set<String> _supervised = {};

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Future<SandboxBackendCapabilities> probe() async {
    return const SandboxBackendCapabilities(
      backend: SandboxBackend.none,
      available: true,
      note: 'No isolation — agents run directly on the host with full env.',
    );
  }

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async {
    _streams[spec.sessionId] = StreamController<SandboxEvent>.broadcast();
    if (spec.superviseProcessGroup && canSuperviseProcessGroup) {
      _supervised.add(spec.sessionId);
    }
    // Without a sandbox the bind mounts collapse to "run on the host" — we
    // just pick the first mount's host path as the default working dir.
    final defaultDir = spec.bindMounts.isNotEmpty
        ? spec.bindMounts.first.hostPath
        : null;
    final handle = SandboxHandle(
      sessionId: spec.sessionId,
      backend: SandboxBackend.none,
      state: SandboxState.warm,
      details: {'workingDirectory': defaultDir},
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
    _updateState(handle.sessionId, SandboxState.active);
    final controller = _streams[handle.sessionId];
    // `destroy` can close the stream while the child is still flushing.
    void emit(SandboxEvent event) {
      if (controller != null && !controller.isClosed) {
        controller.add(event);
      }
    }

    final workingDirectory =
        workdir ??
        _handles[handle.sessionId]?.details['workingDirectory'] as String?;

    final launch = _supervised.contains(handle.sessionId)
        ? superviseProcessGroup(argv.first, argv.skip(1).toList())
        : (executable: argv.first, argv: argv.skip(1).toList());
    final process = await ChildProcess.start(
      launch.executable,
      launch.argv,
      workingDirectory: workingDirectory,
      environment: env,
      toolchain: true,
      // NEVER a shell. This argv is built for execve (`--model <id>`,
      // `--mcp-config <path>`, a prompt), so `runInShell: true` handed
      // semi-trusted config strings containing shell metacharacters to `sh`
      // — divergent from the native path's semantics and an injection surface.
      runInShell: false,
    );
    _processes[handle.sessionId] = process;
    onPid?.call(process.pid);

    settleStdin(process, input: stdinInput, stream: stdinStream);

    final forwardings = [
      for (final (stream, type) in [
        (process.stdout, SandboxEventType.stdout),
        (process.stderr, SandboxEventType.stderr),
      ])
        ProcessLineForwarding.start(
          stream,
          (line) => emit(SandboxEvent(type: type, content: line)),
        ),
    ];

    final exitCode = await awaitExitWithTimeout(
      process,
      timeout,
      (message) =>
          emit(SandboxEvent(type: SandboxEventType.stderr, content: message)),
    );
    // Drain stdio before the exit event: a short-lived `echo` can exit before
    // the event loop delivers the stdout listen callback and consumers that
    // stop on `exit` would miss the output. Bounded, so a grandchild holding
    // the pipe cannot park the exec.
    await drainForwardings(forwardings);
    _processes.remove(handle.sessionId);
    emit(SandboxEvent(type: SandboxEventType.exit, exitCode: exitCode));
    _updateState(handle.sessionId, SandboxState.warm);
    return exitCode;
  }

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
    // SIGTERM → 3s → SIGKILL, and AWAIT it. A bare `kill()` that returns
    // immediately leaves a SIGTERM-ignoring child running while the caller
    // believes the sandbox is gone.
    _supervised.remove(handle.sessionId);
    final process = _processes.remove(handle.sessionId);
    if (process != null) {
      await terminateProcess(process);
    }
    await _streams.remove(handle.sessionId)?.close();
    _updateState(handle.sessionId, SandboxState.destroyed);
    _handles.remove(handle.sessionId);
  }

  void _updateState(String sessionId, SandboxState state) {
    final current = _handles[sessionId];
    if (current != null) {
      _handles[sessionId] = current.copyWith(state: state);
    }
  }
}
