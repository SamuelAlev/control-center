import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cc_domain/features/sandboxing/domain/child_environment.dart';
import 'package:meta/meta.dart';

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
/// * No program a repository's content or config chooses ever runs, because
///   server-run git works in trees an agent or a pull request can write:
///   `core.hooksPath` is the null device (no hook runs, like `--no-verify`),
///   `core.askPass` is empty (a failed authentication never runs a
///   repo-chosen prompt program), `protocol.ext.allow=never` (no `ext::`
///   remote runs a command), the editors are `false` (a server git never
///   waits on one, and a repo-chosen one never runs), and every signing
///   program is `false` with commit, tag and push signing off (server git
///   never signs; `CommitResigner` signs IDE commits in-process).
///   `git diff` always runs with `--no-ext-diff` ([args]), so neither
///   `diff.external` nor a diff driver's `command` runs; the other diff
///   commands never run them. `core.alternateRefsCommand` is empty (no
///   alternate-refs command), and submodules are never
///   recursed into (`submodule.recurse`, `fetch.recurseSubmodules`), so a
///   submodule's own config and hooks never come into play. Drivers
///   named by `.gitattributes` (filters, diff and merge drivers, textconv)
///   and per-remote `uploadpack`/`receivepack` are defined only in the
///   repository's own config, which no sandbox can write.
/// * `GIT_TERMINAL_PROMPT=0`: nothing ever waits on a prompt.
/// * The environment otherwise comes from [ChildEnvironment], so a host
///   `GH_TOKEN` or provider secret never reaches git or its hooks.
///
/// `protocol.file.allow` is left at git's default; callers that need local
/// clones pass it themselves, as before.
///
/// Nothing here reads the host's own git config.
///
/// [run] admits at most [localConcurrency] local commands at once, server
/// wide; the rest wait their turn. Polls of several worktrees (the IDE's
/// Source Control panel reads each repository every few seconds with about
/// ten commands) otherwise start dozens of children together: they thrash the
/// disk the interactive read needs and, at macOS's default limit of 256 open
/// files, fail with "Too many open files". Commands that talk to a remote
/// ([networkSubcommands]) skip the queue, so a slow fetch never holds up a
/// diff and a diff never holds up a push. [runSync] and [start] are not
/// queued: one blocks the isolate and the other hands back a live process.
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

  /// The `-c` arguments every invocation starts with. A caller's own `-c`
  /// comes after them and wins: these guard against the repository, not
  /// against server code.
  static List<String> get isolationArgs => [
    '-c',
    'credential.helper=',
    '-c',
    'protocol.ssh.allow=never',
    '-c',
    'protocol.ext.allow=never',
    '-c',
    'core.fsmonitor=false',
    '-c',
    'core.hooksPath=$nullDevice',
    '-c',
    'core.askPass=',
    '-c',
    'core.editor=false',
    '-c',
    'sequence.editor=false',
    '-c',
    'gpg.program=false',
    '-c',
    'gpg.ssh.program=false',
    '-c',
    'gpg.x509.program=false',
    '-c',
    'commit.gpgSign=false',
    '-c',
    'tag.gpgSign=false',
    '-c',
    'push.gpgSign=false',
    '-c',
    'core.alternateRefsCommand=',
    '-c',
    'submodule.recurse=false',
    '-c',
    'fetch.recurseSubmodules=false',
    ...githubHttpsRewrites,
  ];

  /// [arguments] behind [isolationArgs], with `--no-ext-diff` right after a
  /// `diff` subcommand.
  ///
  /// Porcelain `git diff` is the one command that runs `diff.external` or a
  /// `diff.<driver>.command`, and no config value turns that off: an empty
  /// `diff.external` is taken as a program named "" and the diff dies.
  static List<String> args(List<String> arguments) {
    final command = _subcommandIndex(arguments);
    return [
      ...isolationArgs,
      if (command != null && arguments[command] == 'diff') ...[
        ...arguments.take(command + 1),
        '--no-ext-diff',
        ...arguments.skip(command + 1),
      ] else
        ...arguments,
    ];
  }

  /// Global options that take their value as the next argument.
  static const Set<String> _globalOptionsWithValue = {
    '-C',
    '-c',
    '--git-dir',
    '--work-tree',
    '--namespace',
    '--config-env',
  };

  /// The index of the subcommand in [arguments], past git's global options.
  static int? _subcommandIndex(List<String> arguments) {
    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      if (_globalOptionsWithValue.contains(arg)) {
        i++;
      } else if (!arg.startsWith('-')) {
        return i;
      }
    }
    return null;
  }

  /// The isolation variables. They are applied after a caller's own values,
  /// so no caller can weaken them.
  static Map<String, String> get isolationEnvironment => {
    'GIT_CONFIG_GLOBAL': nullDevice,
    'GIT_CONFIG_NOSYSTEM': '1',
    'GIT_TERMINAL_PROMPT': '0',
  };

  /// The environment for a git child: [ChildEnvironment] from [host]
  /// (`Platform.environment` by default), [environment] on top, then
  /// [isolationEnvironment]. No toolchain variables: no hook or other
  /// repository program runs ([isolationArgs]), so nothing needs them.
  static Map<String, String> environmentFor({
    Map<String, String>? environment,
    Map<String, String>? host,
  }) => ChildEnvironment.build(
    host ?? Platform.environment,
    overrides: {...?environment, ...isolationEnvironment},
  );

  /// Local git commands [run] lets execute at once.
  static final int localConcurrency = math.max(
    4,
    math.min(8, Platform.numberOfProcessors),
  );

  /// Subcommands that reach a remote. [run] never queues them.
  static const Set<String> networkSubcommands = {
    'clone',
    'fetch',
    'pull',
    'push',
    'ls-remote',
    'remote',
    'submodule',
    'archive',
  };

  static final _localGate = _Gate(localConcurrency);

  /// Local commands [run] has queued but not started.
  @visibleForTesting
  static int get queuedLocalRuns => _localGate.waiting;

  /// Runs git with [arguments]. A local command waits for one of
  /// [localConcurrency] slots first.
  ///
  /// [stdin], when given, is written to the command's standard input (UTF-8)
  /// and the input closed, for commands that read it (`update-ref --stdin`,
  /// `cat-file --batch-check`).
  static Future<ProcessResult> run(
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
    String? stdin,
  }) {
    Future<ProcessResult> spawn() => stdin == null
        ? Process.run(
            executable,
            args(arguments),
            workingDirectory: workingDirectory,
            environment: environmentFor(environment: environment),
            includeParentEnvironment: false,
            stdoutEncoding: stdoutEncoding,
            stderrEncoding: stderrEncoding,
          )
        : _runWithInput(
            arguments,
            stdin,
            workingDirectory: workingDirectory,
            environment: environment,
            stdoutEncoding: stdoutEncoding,
            stderrEncoding: stderrEncoding,
          );
    final command = _subcommandIndex(arguments);
    if (command != null && networkSubcommands.contains(arguments[command])) {
      return spawn();
    }
    return _localGate.run(spawn);
  }

  static Future<ProcessResult> _runWithInput(
    List<String> arguments,
    String input, {
    String? workingDirectory,
    Map<String, String>? environment,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) async {
    final process = await Process.start(
      executable,
      args(arguments),
      workingDirectory: workingDirectory,
      environment: environmentFor(environment: environment),
      includeParentEnvironment: false,
    );
    Future<Object> collect(Stream<List<int>> stream, Encoding? encoding) =>
        encoding == null
        ? stream.fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk))
        : encoding.decodeStream(stream);
    final stdout = collect(process.stdout, stdoutEncoding);
    final stderr = collect(process.stderr, stderrEncoding);
    try {
      process.stdin.add(utf8.encode(input));
      await process.stdin.close();
    } on Object {
      // The command exited without reading all of it; its exit code and
      // stderr say why.
    }
    final exitCode = await process.exitCode;
    return ProcessResult(process.pid, exitCode, await stdout, await stderr);
  }

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
    ProcessStartMode mode = ProcessStartMode.normal,
  }) => Process.start(
    executable,
    args(arguments),
    workingDirectory: workingDirectory,
    environment: environmentFor(environment: environment),
    includeParentEnvironment: false,
    mode: mode,
  );
}

/// A first-come, first-served limit on how many tasks run at once.
class _Gate {
  _Gate(this._capacity);

  final int _capacity;
  int _running = 0;
  final _waiters = Queue<Completer<void>>();

  int get waiting => _waiters.length;

  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= _capacity) {
      final turn = Completer<void>();
      _waiters.add(turn);
      // The slot is handed over by the task that frees it, already counted.
      await turn.future;
    } else {
      _running++;
    }
    try {
      return await task();
    } finally {
      if (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete();
      } else {
        _running--;
      }
    }
  }
}
