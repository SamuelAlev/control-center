// Controllers and processes here are owned by the adapter for the lifetime
// of each sandbox session and are closed/killed in `destroy()` — these
// lints flag false positives.
// ignore_for_file: close_sinks, unnecessary_lambdas

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';

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
  }) async {
    if (argv.isEmpty) {
      throw ArgumentError('argv must not be empty');
    }
    _updateState(handle.sessionId, SandboxState.active);
    final controller = _streams[handle.sessionId];
    final workingDirectory =
        workdir ??
        _handles[handle.sessionId]?.details['workingDirectory'] as String?;

    final process = await Process.start(
      argv.first,
      argv.skip(1).toList(),
      workingDirectory: workingDirectory,
      environment: env,
      includeParentEnvironment: true,
      // NEVER a shell. This argv is built for execve (`--model <id>`,
      // `--mcp-config <path>`, a prompt), so `runInShell: true` handed
      // semi-trusted config strings containing shell metacharacters to `sh`
      // — divergent from the native path's semantics and an injection surface.
      runInShell: false,
    );
    _processes[handle.sessionId] = process;
    onPid?.call(process.pid);

    if (stdinInput != null) {
      process.stdin.write(stdinInput);
    }
    unawaited(process.stdin.close());

    Future<void> forward(Stream<List<int>> stream, SandboxEventType type) {
      final done = Completer<void>();
      stream
          // Tolerate malformed bytes: the throwing decoder ends the forwarding
          // (and the `done` completer with it) on a single bad byte.
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(
            (line) {
              controller?.add(SandboxEvent(type: type, content: line));
            },
            onDone: done.complete,
            onError: (_, _) {
              if (!done.isCompleted) {
                done.complete();
              }
            },
            cancelOnError: true,
          );
      return done.future;
    }

    final stdoutDone = forward(process.stdout, SandboxEventType.stdout);
    final stderrDone = forward(process.stderr, SandboxEventType.stderr);

    final exitCode = await _awaitExitWithTimeout(
      process,
      timeout,
      (message) => controller?.add(
        SandboxEvent(type: SandboxEventType.stderr, content: message),
      ),
    );
    // Drain stdio before the exit event: a short-lived `echo` can exit before
    // the event loop delivers the stdout listen callback and consumers that
    // stop on `exit` would miss the output.
    await Future.wait<void>([stdoutDone, stderrDone]);
    _processes.remove(handle.sessionId);
    controller?.add(
      SandboxEvent(type: SandboxEventType.exit, exitCode: exitCode),
    );
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
    final process = _processes.remove(handle.sessionId);
    if (process != null) {
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        try {
          await process.exitCode.timeout(const Duration(seconds: 2));
        } on TimeoutException {
          // Unreapable; nothing further this layer can do.
        }
      }
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

/// Awaits [process] with an optional [timeout], killing it (SIGTERM → 2s →
/// SIGKILL) and reporting exit code 124 — the `timeout(1)` convention — when
/// the deadline passes. See the native adapter's copy for why this exists.
Future<int> _awaitExitWithTimeout(
  Process process,
  Duration? timeout,
  void Function(String message)? onTimeoutMessage,
) async {
  if (timeout == null) {
    return process.exitCode;
  }
  try {
    return await process.exitCode.timeout(timeout);
  } on TimeoutException {
    onTimeoutMessage?.call(
      '[sandbox] command exceeded ${timeout.inSeconds}s — terminating',
    );
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }
    return 124;
  }
}
