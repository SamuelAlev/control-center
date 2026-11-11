import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';

/// Starts the helper processes a run's tools drive on the server host: the
/// `eval` kernel, a debug adapter and its debuggee, a language server and the
/// project checker behind `lsp diagnostics`.
///
/// A run gets one, chosen where it is dispatched: [SandboxedToolProcessLauncher]
/// when the server sandboxes agents, [HostToolProcessLauncher] only when the
/// host execution posture lets the run be unconfined, and
/// [RefusingToolProcessLauncher] when the server sandboxes agents but has no
/// manager to do it with. Tools and shell hooks never start a helper process
/// any other way.
abstract interface class ToolProcessLauncher {
  /// Whether processes started here run inside the run's OS sandbox.
  bool get confined;

  /// Starts [executable] with [args] and piped stdio.
  Future<Process> start(
    String executable,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  });

  /// Releases the sandbox session processes started here ran in (its
  /// proxies, profiles and private `TMPDIR`). Call once nothing started here
  /// is running any more; a later [start] opens the session again.
  Future<void> release();
}

/// Wraps every process with [SandboxManager.wrap] in sandbox session
/// [sessionId], under the spec [_spec] builds for it, rebuilt per start so an
/// exec grant answered mid-run applies to the next one. The data dir stays
/// hidden, the network follows the run's policy and loopback reach is the
/// run's `loopbackPorts`.
final class SandboxedToolProcessLauncher implements ToolProcessLauncher {
  /// Creates a [SandboxedToolProcessLauncher].
  SandboxedToolProcessLauncher({
    required this._manager,
    required this.sessionId,
    required this._spec,
  });

  final SandboxManager _manager;

  /// The sandbox session every process started here shares.
  final String sessionId;

  final Future<SandboxSpec> Function(String sessionId) _spec;

  @override
  bool get confined => true;

  @override
  Future<void> release() => _manager.disposeSession(sessionId);

  @override
  Future<Process> start(
    String executable,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    final config = await processSandboxConfig(await _spec(sessionId));
    final wrap = await _manager.wrap(
      config: config,
      argv: [executable, ...args],
      workingDirectory: workingDirectory,
    );
    return ChildProcess.start(
      wrap.executable,
      wrap.argv,
      workingDirectory: workingDirectory,
      environment: {...?environment, ...wrap.environment},
      toolchain: true,
    );
  }
}

/// Starts processes directly on the host, with the allowlisted environment
/// only. Used when the sandbox is off by the owner's choice, or unavailable
/// and the run's accountable person is the server owner.
final class HostToolProcessLauncher implements ToolProcessLauncher {
  /// Creates a [HostToolProcessLauncher].
  const HostToolProcessLauncher();

  @override
  bool get confined => false;

  @override
  Future<void> release() async {}

  @override
  Future<Process> start(
    String executable,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) => ChildProcess.start(
    executable,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
    toolchain: true,
    // `npx` and friends are `.cmd` shims on Windows.
    runInShell: Platform.isWindows,
  );
}

/// Starts nothing. Used when the server sandboxes agents but has no sandbox
/// manager wired: a tool process then has nowhere confined to run, and the
/// host is not a fallback.
final class RefusingToolProcessLauncher implements ToolProcessLauncher {
  /// Creates a [RefusingToolProcessLauncher].
  const RefusingToolProcessLauncher();

  @override
  bool get confined => true;

  @override
  Future<void> release() async {}

  @override
  Future<Process> start(
    String executable,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) => Future.error(
    ProcessException(
      executable,
      args,
      'no sandbox is available to run tool processes in',
    ),
  );
}

/// Runs [executable] through [launcher] to completion, killing it after
/// [timeout].
Future<ProcessResult> runToolProcess(
  ToolProcessLauncher launcher,
  String executable,
  List<String> args, {
  required String workingDirectory,
  Duration timeout = const Duration(minutes: 3),
}) async {
  final process = await launcher.start(
    executable,
    args,
    workingDirectory: workingDirectory,
  );
  const decoder = Utf8Decoder(allowMalformed: true);
  final stdout = process.stdout.transform(decoder).join();
  final stderr = process.stderr.transform(decoder).join();
  final exitCode = await process.exitCode.timeout(
    timeout,
    onTimeout: () {
      process.kill(ProcessSignal.sigkill);
      throw TimeoutException('$executable did not finish', timeout);
    },
  );
  return ProcessResult(process.pid, exitCode, await stdout, await stderr);
}
