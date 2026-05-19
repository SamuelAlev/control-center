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
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/linux_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';

/// `SandboxPort` implementation that wraps each command with the in-project
/// native sandbox runtime: `sandbox-exec` (Seatbelt) on macOS, `bubblewrap`
/// on Linux/WSL2.
///
/// Lifecycle:
///   - [launch] computes a [SandboxConfig] from the [SandboxSpec] and stashes
///     it on the handle. There's no long-lived "container" — the sandbox is
///     applied on every [exec].
///   - [exec] asks [SandboxManager.wrap] for the spawn argv + proxy env,
///     forks via `Process.start`, and forwards stdout/stderr/exit on the
///     handle's event stream.
///   - [destroy] tells the manager to clean per-session temp files
///     (Seatbelt profiles, Linux socket bridges) and closes the stream.
class NativeSandboxAdapter implements SandboxPort {
  /// Creates a [NativeSandboxAdapter] bound to [_manager].
  NativeSandboxAdapter({required SandboxManager manager}) : _manager = manager {
    _violationSub = _manager.violations.listen(_dispatchViolation);
  }

  final SandboxManager _manager;
  final Map<String, StreamController<SandboxEvent>> _streams = {};
  final Map<String, Process> _processes = {};
  final Map<String, SandboxConfig> _configs = {};
  final Map<String, SandboxHandle> _handles = {};
  String? _activeSession;
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
        note: 'macOS sandbox-exec (Seatbelt) — namespace isolation, no kernel boundary.',
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
    final handle = SandboxHandle(
      sessionId: spec.sessionId,
      backend: SandboxBackend.native,
      state: SandboxState.warm,
      details: {
        'workingDirectory': _defaultDirFor(spec),
      },
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
    final config = _configs[handle.sessionId];
    if (config == null) {
      throw StateError('no sandbox config for session ${handle.sessionId}');
    }

    _updateState(handle.sessionId, SandboxState.active);
    _activeSession = handle.sessionId;
    final controller = _streams[handle.sessionId];
    final workingDirectory =
        workdir ?? _handles[handle.sessionId]?.details['workingDirectory'] as String?;

    final wrap = await _manager.wrap(
      config: config,
      argv: argv,
      workingDirectory: workingDirectory,
    );

    // Sanitize the parent environment (strip LD_*/DYLD_*/injection vars),
    // then layer the proxy env (re-adds the safe GIT_SSH_COMMAND) + the
    // dispatch env on top. includeParentEnvironment:false so the sanitized
    // set is authoritative.
    final sanitizedParent = const EnvSanitizer().hardenPlatform({});
    final mergedEnv = <String, String>{
      ...sanitizedParent,
      ...wrap.environment,
      ...?env,
    };

    final process = await Process.start(
      wrap.executable,
      wrap.argv,
      workingDirectory: workingDirectory,
      environment: mergedEnv,
      includeParentEnvironment: false,
      runInShell: false,
    );
    _processes[handle.sessionId] = process;
    onPid?.call(process.pid);

    // Always settle stdin — CLIs that read it (like `pi --mode json`) hang
    // forever otherwise. Pipe the prompt when one is provided; close
    // immediately to signal EOF when not.
    if (stdinInput != null) {
      process.stdin.write(stdinInput);
    }
    unawaited(process.stdin.close());

    void forward(
      Stream<List<int>> stream,
      SandboxEventType type, {
      bool watchEperm = false,
    }) {
      stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        controller?.add(SandboxEvent(type: type, content: line));
        if (watchEperm) {
          _manager.reportLinuxStderr(line);
        }
      });
    }

    forward(process.stdout, SandboxEventType.stdout);
    forward(
      process.stderr,
      SandboxEventType.stderr,
      // macOS surfaces denials through the log stream; Linux relies on the
      // child's stderr — feed it back into the manager here.
      watchEperm: Platform.isLinux || LinuxSandbox.isWsl2(),
    );

    final exitCode = await process.exitCode;
    _processes.remove(handle.sessionId);
    controller
        ?.add(SandboxEvent(type: SandboxEventType.exit, exitCode: exitCode));
    _updateState(handle.sessionId, SandboxState.warm);
    if (_activeSession == handle.sessionId) {
      _activeSession = null;
    }
    return exitCode;
  }

  void _dispatchViolation(SandboxViolation violation) {
    final id = _activeSession;
    if (id == null) {
      return;
    }
    final controller = _streams[id];
    controller?.add(
      SandboxEvent(
        type: SandboxEventType.violation,
        content: '${violation.action} ${violation.target}',
        violation: violation,
      ),
    );
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
    _configs.remove(handle.sessionId);
    await _streams.remove(handle.sessionId)?.close();
    await _manager.disposeSession(handle.sessionId);
    if (_activeSession == handle.sessionId) {
      _activeSession = null;
    }
    _updateState(handle.sessionId, SandboxState.destroyed);
    _handles.remove(handle.sessionId);
  }

  /// Stops listening for violations. Called by the Riverpod provider when the
  /// adapter is being disposed (e.g. app shutdown).
  Future<void> dispose() async {
    await _violationSub?.cancel();
    _violationSub = null;
  }

  Future<SandboxConfig> _buildConfigForSpec(SandboxSpec spec) async {
    final home = Platform.environment['HOME'] ?? '';
    final runDir = spec.guestWorkdir != null
        ? '${spec.guestWorkdir}/.cc-runs/${spec.sessionId}'
        : null;
    final policy = const SandboxPolicyResolver().resolve(
      spec: spec,
      capabilities: spec.capabilities,
      homeDir: home.isNotEmpty ? home : null,
      runDir: runDir,
      isPty: false,
    );
    return buildSandboxConfigFromPolicy(policy);
  }

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
      final result = await Process.run('which', [binary]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
