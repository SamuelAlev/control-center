import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/child_environment.dart';

/// The only way the server runs `git`.
///
/// Every server-run git (clones, fetches and provisioning, PR clones, space
/// worktrees, the IDE surface's commit/push on a space worktree, code-index
/// probes, rig sync, snapshot and diff reads, the gateway's push inspection)
/// is isolated from the host user's git setup:
///
/// * `GIT_CONFIG_GLOBAL` names the null device and `GIT_CONFIG_NOSYSTEM=1`,
///   so `~/.gitconfig`, `$XDG_CONFIG_HOME/git/config` and `/etc/gitconfig`
///   are never read: no `insteadOf` rewrite, `core.sshCommand`, credential
///   helper, signing key or include can reach a server-run git.
/// * `-c credential.helper=` clears every helper, so a token the server hands
///   git (always through `GIT_CONFIG_PARAMETERS`, never argv or a URL) is
///   neither looked up in nor stored to the operator's keychain.
/// * `-c protocol.ssh.allow=never`, and no `SSH_AUTH_SOCK`: the server never
///   authenticates with the operator's SSH identity. GitHub SSH remotes are
///   rewritten to HTTPS ([githubHttpsRewrites]) so a broker-minted token can
///   authenticate them; other SSH remotes fail closed.
/// * `-c core.fsmonitor=false`: a repo-local fsmonitor command (which a
///   status or diff would run on the host) never runs.
/// * `GIT_TERMINAL_PROMPT=0`: nothing ever waits on a prompt.
/// * The environment otherwise comes from [ChildEnvironment], so a host
///   `GH_TOKEN` or provider secret never reaches git or its hooks.
///
/// `protocol.file.allow` is left at git's default; callers that need local
/// clones pass it themselves, as before.
///
/// [readHostGlobalConfig] is the one deliberate exception: the owner's commit
/// signer must read the owner's own signing setup.
// A namespace: the one way server code runs git.
// ignore: avoid_classes_with_only_static_members
abstract final class IsolatedGit {
  /// The program run.
  static const String executable = 'git';

  /// What `GIT_CONFIG_GLOBAL` points at: an empty config.
  static String get nullDevice => Platform.isWindows ? 'NUL' : '/dev/null';

  /// GitHub SSH spellings rewritten to HTTPS, as `-c` arguments.
  static const List<String> githubHttpsRewrites = [
    '-c',
    'url.https://github.com/.insteadOf=git@github.com:',
    '-c',
    'url.https://github.com/.insteadOf=ssh://git@github.com/',
  ];

  /// The `-c` arguments every invocation starts with.
  static const List<String> isolationArgs = [
    '-c',
    'credential.helper=',
    '-c',
    'protocol.ssh.allow=never',
    '-c',
    'core.fsmonitor=false',
    ...githubHttpsRewrites,
  ];

  /// [arguments] behind [isolationArgs].
  static List<String> args(List<String> arguments) => [
    ...isolationArgs,
    ...arguments,
  ];

  /// The isolation variables. They are applied after a caller's own values,
  /// so no caller can weaken them.
  static Map<String, String> get isolationEnvironment => {
    'GIT_CONFIG_GLOBAL': nullDevice,
    'GIT_CONFIG_NOSYSTEM': '1',
    'GIT_TERMINAL_PROMPT': '0',
  };

  /// The environment for a git child: [ChildEnvironment] from [host]
  /// (`Platform.environment` by default), [environment] on top, then
  /// [isolationEnvironment]. [toolchain] passes version-manager variables
  /// through for repo hooks that build code (an IDE commit).
  static Map<String, String> environmentFor({
    Map<String, String>? environment,
    bool toolchain = false,
    Map<String, String>? host,
  }) => ChildEnvironment.build(
    host ?? Platform.environment,
    toolchain: toolchain,
    overrides: {...?environment, ...isolationEnvironment},
  );

  /// Runs git with [arguments].
  static Future<ProcessResult> run(
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool toolchain = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) => Process.run(
    executable,
    args(arguments),
    workingDirectory: workingDirectory,
    environment: environmentFor(environment: environment, toolchain: toolchain),
    includeParentEnvironment: false,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
  );

  /// Runs git with [arguments], synchronously.
  static ProcessResult runSync(
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) => Process.runSync(
    executable,
    args(arguments),
    workingDirectory: workingDirectory,
    environment: environmentFor(environment: environment),
    includeParentEnvironment: false,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
  );

  /// Starts git with [arguments].
  static Future<Process> start(
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool toolchain = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) => Process.start(
    executable,
    args(arguments),
    workingDirectory: workingDirectory,
    environment: environmentFor(environment: environment, toolchain: toolchain),
    includeParentEnvironment: false,
    mode: mode,
  );

  /// Reads [key] from the host user's global git config, top level only, or
  /// null when unset.
  ///
  /// Only the owner's commit signer calls this: it signs with the owner's own
  /// SSH setup and so must read it. `--no-includes`, because an included file
  /// can live where a sandbox may write; the global files themselves are
  /// write-denied to every sandbox. It reads and never touches the network.
  static Future<String?> readHostGlobalConfig(
    String key, {
    Map<String, String>? host,
  }) async {
    final source = host ?? Platform.environment;
    final ProcessResult result;
    try {
      result = await Process.run(
        executable,
        ['config', '--global', '--no-includes', '--get', key],
        environment: ChildEnvironment.build(
          source,
          // Where git finds the global file, and nothing else of the host's.
          inherit: const ['GIT_CONFIG_GLOBAL', 'XDG_CONFIG_HOME'],
          overrides: const {'GIT_CONFIG_NOSYSTEM': '1'},
        ),
        includeParentEnvironment: false,
      );
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) {
      return null;
    }
    final value = (result.stdout as String).trim();
    return value.isEmpty ? null : value;
  }
}
