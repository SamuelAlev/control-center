import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/child_environment.dart';
import 'package:cc_infra/src/process/process_tree.dart';

/// The only way server code starts a child process (`git` goes through
/// `IsolatedGit` instead).
///
/// Mirrors `Process.start`/`run`/`runSync`, except for the environment: a
/// child never inherits the server's. It gets [ChildEnvironment]'s allowlist
/// out of the host environment, the host variables its caller names, and
/// `environment` on top (`includeParentEnvironment` is always false). So a
/// `GITHUB_CLIENT_SECRET`, `GH_TOKEN` or Slack secret the operator exported
/// never reaches an agent, a pipeline step, a rig tool or an MCP server.
///
/// * `inherit` / `inheritPrefixes`: further host variables this caller needs
///   (never a [ChildEnvironment.isStripped] one).
/// * `toolchain`: version-manager and SDK locations, for children that build
///   or run project code.
/// * `display`: what a windowed or audio program needs on a Linux desktop.
/// * `inheritBase`: false starts from nothing but `environment` (a managed
///   media executable that must not see `PATH`).
// A namespace: the one way server code starts a child.
// ignore: avoid_classes_with_only_static_members
abstract final class ChildProcess {
  /// The environment a child started with these options sees.
  static Map<String, String> environmentFor({
    Map<String, String>? environment,
    Iterable<String> inherit = const [],
    Iterable<String> inheritPrefixes = const [],
    bool toolchain = false,
    bool display = false,
    bool inheritBase = true,
  }) => ChildEnvironment.build(
    Platform.environment,
    inherit: inherit,
    inheritPrefixes: inheritPrefixes,
    toolchain: toolchain,
    display: display,
    inheritBase: inheritBase,
    overrides: environment,
  );

  /// `Process.start` with a [ChildEnvironment].
  static Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Iterable<String> inherit = const [],
    Iterable<String> inheritPrefixes = const [],
    bool toolchain = false,
    bool display = false,
    bool inheritBase = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) => Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environmentFor(
      environment: environment,
      inherit: inherit,
      inheritPrefixes: inheritPrefixes,
      toolchain: toolchain,
      display: display,
      inheritBase: inheritBase,
    ),
    includeParentEnvironment: false,
    runInShell: runInShell,
    mode: mode,
  );

  /// `Process.run` with a [ChildEnvironment].
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Iterable<String> inherit = const [],
    Iterable<String> inheritPrefixes = const [],
    bool toolchain = false,
    bool display = false,
    bool inheritBase = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) => Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environmentFor(
      environment: environment,
      inherit: inherit,
      inheritPrefixes: inheritPrefixes,
      toolchain: toolchain,
      display: display,
      inheritBase: inheritBase,
    ),
    includeParentEnvironment: false,
    runInShell: runInShell,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
  );

  /// The first path `which` (`where` on Windows) prints for [binary], or
  /// null when it is not on `PATH` or the lookup cannot run.
  static Future<String?> which(String binary, {bool toolchain = false}) async {
    try {
      final result = await run(Platform.isWindows ? 'where' : 'which', [
        binary,
      ], toolchain: toolchain);
      if (result.exitCode != 0) {
        return null;
      }
      final path = '${result.stdout}'.split('\n').first.trim();
      return path.isEmpty ? null : path;
    } on Object {
      return null;
    }
  }

  /// Kills [rootPid] and every process it started (its descendants, the
  /// process groups and sessions they lead, and every process whose
  /// environment carries [marker]): TERM, then KILL to whatever is left after
  /// [grace]. A child started in its own group (see `superviseProcessGroup`)
  /// takes what it left behind down with it, even re-parented processes.
  /// Never signals the server or the server's own group, and never the root
  /// once [exited] says its exit was seen. Windows ends the tree with
  /// `taskkill /T /F`. See [killProcessTree].
  static Future<void> killTree(
    int rootPid, {
    required bool Function() exited,
    String? marker,
    Duration grace = const Duration(seconds: 2),
  }) => killProcessTree(rootPid, grace: grace, exited: exited, marker: marker);

  /// `Process.runSync` with a [ChildEnvironment].
  static ProcessResult runSync(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Iterable<String> inherit = const [],
    bool toolchain = false,
    bool inheritBase = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) => Process.runSync(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environmentFor(
      environment: environment,
      inherit: inherit,
      toolchain: toolchain,
      inheritBase: inheritBase,
    ),
    includeParentEnvironment: false,
    runInShell: runInShell,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
  );
}
