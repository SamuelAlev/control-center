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
    _streams[spec.sessionId]
        ?.add(const SandboxEvent(type: SandboxEventType.ready));
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
        workdir ?? _handles[handle.sessionId]?.details['workingDirectory'] as String?;

    final process = await Process.start(
      argv.first,
      argv.skip(1).toList(),
      workingDirectory: workingDirectory,
      environment: env,
      includeParentEnvironment: true,
      runInShell: true,
    );
    _processes[handle.sessionId] = process;
    onPid?.call(process.pid);

    if (stdinInput != null) {
      process.stdin.write(stdinInput);
    }
    unawaited(process.stdin.close());

    void forward(Stream<List<int>> stream, SandboxEventType type) {
      stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        controller?.add(SandboxEvent(type: type, content: line));
      });
    }

    forward(process.stdout, SandboxEventType.stdout);
    forward(process.stderr, SandboxEventType.stderr);

    final exitCode = await process.exitCode;
    _processes.remove(handle.sessionId);
    controller
        ?.add(SandboxEvent(type: SandboxEventType.exit, exitCode: exitCode));
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
    _processes.remove(handle.sessionId)?.kill();
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
