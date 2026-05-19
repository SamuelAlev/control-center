// LinuxSandbox is a namespace of pure functions (argv assembly, bridge
// lifecycle). Suppress the "no instance members" hint — that's the design.
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/sandboxing/sandbox_config.dart';

/// Wrapping logic for Linux (and WSL2), using `bubblewrap` (`bwrap`) for
/// filesystem + PID + namespace isolation and `socat` Unix-socket bridges
/// for routing sandboxed traffic to the in-process HTTP/SOCKS proxies on the
/// host.
///
/// The bwrap argv is built from [SandboxConfig.filesystem]:
///   - `--bind <p> <p>` for every `allowWrite` entry (writable bind mount)
///   - `--ro-bind /dev/null <p>` for every `denyRead` and `denyWrite` entry
///   - `--tmpfs <p>` for `denyRead` directories that need to look empty
///   - `--unshare-net --unshare-pid --proc /proc --dev /dev` always
///
/// Networking, when enabled, is reachable only through Unix sockets bind-mounted
/// into the sandbox; the in-sandbox `socat` listens on 127.0.0.1 and forwards
/// to those sockets so the user command sees a normal `HTTP_PROXY` URL.
abstract final class LinuxSandbox {
  /// Builds the bwrap argv for [config], excluding the leading `bwrap` token.
  ///
  /// [innerCommand] is the command (already shell-quoted) executed by
  /// `/bin/bash -c` inside the sandbox. When proxies are configured the
  /// caller is expected to prepend its own `socat` listener inside this
  /// inner command — see [wrapCommand] which does this assembly.
  static List<String> buildBwrapArgs({
    required SandboxConfig config,
    required String innerCommand,
    List<LinuxSocketBridge> bridges = const [],
    String? workingDirectory,
    String binShell = '/bin/bash',
  }) {
    final args = <String>[
      '--die-with-parent',
      '--unshare-pid',
      '--unshare-uts',
      '--unshare-ipc',
      '--proc',
      '/proc',
      '--dev',
      '/dev',
      '--ro-bind',
      '/usr',
      '/usr',
      '--ro-bind-try',
      '/lib',
      '/lib',
      '--ro-bind-try',
      '/lib64',
      '/lib64',
      '--ro-bind-try',
      '/bin',
      '/bin',
      '--ro-bind-try',
      '/sbin',
      '/sbin',
      '--ro-bind-try',
      '/usr/sbin',
      '/usr/sbin',
      '--ro-bind-try',
      '/etc',
      '/etc',
      '--tmpfs',
      '/tmp',
    ];

    // Network isolation: unshare the net namespace whenever network is
    // restricted (not only fully blocked). NET_ADMIN is scoped to the
    // netns — it only lets the inner process bring the sandbox loopback
    // up so the socat bridges and HTTP_PROXY calls work.
    if (config.network.isRestricted) {
      args.add('--unshare-net');
      args.add('--cap-add');
      args.add('NET_ADMIN');
    }


    for (final p in config.filesystem.allowWrite) {
      args.addAll(['--bind', p, p]);
    }
    for (final p in config.filesystem.denyRead) {
      if (FileSystemEntity.isDirectorySync(p)) {
        args.addAll(['--tmpfs', p]);
      } else {
        args.addAll(['--ro-bind-try', '/dev/null', p]);
      }
    }
    for (final p in config.filesystem.denyWrite) {
      if (!p.contains('*')) {
        args.addAll(['--ro-bind-try', '/dev/null', p]);
      }
    }

    // Read-only mounts: worktree visible but not writable in
    // review/plan/orchestrate modes. Must come AFTER the writable binds so
    // bwrap's last-mount-wins resolution gives us read-only visibility.
    for (final p in config.policy?.readOnlyMounts ?? const <String>[]) {
      args.addAll(['--ro-bind-try', p, p]);
    }

    // Exec-deny: shadow always-dangerous binaries with /dev/null so they
    // can't be invoked from inside the sandbox.
    for (final exe in config.denyExecutables) {
      args.addAll(['--ro-bind-try', '/dev/null', exe]);
    }

    // Mandatory denies: scan allowWrite regions for sensitive files (shell
    // dotfiles, .git/hooks, .env*, .npmrc) up to [_mandatoryDenyDepth] levels
    // deep and shadow each one with /dev/null. Mirrors the reference
    // runtime's defense-in-depth pass.
    for (final mandatory in findMandatoryDenyPaths(
      config.filesystem.allowWrite,
    )) {
      args.addAll(['--ro-bind-try', '/dev/null', mandatory]);
    }

    for (final b in bridges) {
      args.addAll(['--bind', b.hostSocketPath, b.sandboxSocketPath]);
    }

    if (workingDirectory != null) {
      args.addAll(['--chdir', workingDirectory]);
    }

    args.addAll(['--setenv', 'HOME', workingDirectory ?? '/tmp']);

    // Tail: `--` separates bwrap flags from the command.
    args.addAll(['--', binShell, '-c', innerCommand]);
    return args;
  }

  /// Returns argv to run [argv] inside a bwrap sandbox, with optional socket
  /// bridges. The caller is responsible for starting the corresponding
  /// host-side `socat` processes via [startBridges] before invoking this.
  static LinuxWrapResult wrapCommand({
    required SandboxConfig config,
    required List<String> argv,
    List<LinuxSocketBridge> bridges = const [],
    String? workingDirectory,
    String binShell = '/bin/bash',
    String bwrapPath = 'bwrap',
  }) {
    final userInner = _shellQuote(argv);

    // If bridges are present, start in-sandbox socat listeners that map
    // TCP loopback ports back to the bind-mounted Unix sockets.
    final socatPreamble = bridges
        .map((b) =>
            'socat TCP-LISTEN:${b.sandboxLoopbackPort},reuseaddr,fork,bind=127.0.0.1 '
            'UNIX-CONNECT:${b.sandboxSocketPath} &')
        .join(' ');

    // If a vendored apply-seccomp binary is available for the current arch,
    // wrap the user command with it so AF_UNIX socket creation is blocked
    // inside the sandbox. When config.allowAllUnixSockets is true (or the
    // binary isn't shipped for this arch) we skip the wrap and the sandbox
    // still has full filesystem/network isolation, just not the seccomp
    // defense-in-depth layer.
    final seccomp = _resolveApplySeccomp(config);
    final wrappedUser = seccomp == null
        ? userInner
        : '${_shellQuote([seccomp])} -- $binShell -c ${_shellQuote([userInner])}';

    final innerCommand = bridges.isEmpty
        ? wrappedUser
        // Bring the netns loopback up so the in-sandbox socat listeners and
        // HTTP_PROXY calls work (bwrap leaves lo DOWN by default).
        : 'ip link set dev lo up 2>/dev/null; $socatPreamble sleep 0.1; $wrappedUser';

    final bwrapArgs = buildBwrapArgs(
      config: config,
      innerCommand: innerCommand,
      bridges: bridges,
      workingDirectory: workingDirectory,
      binShell: binShell,
    );
    return LinuxWrapResult(executable: bwrapPath, argv: bwrapArgs);
  }

  /// Returns the absolute path to a vendored `apply-seccomp-<arch>` binary
  /// if it exists and is executable. Returns `null` when
  /// [SandboxConfig.allowAllUnixSockets] is true, the binary is missing for
  /// the current arch, or the file isn't executable — callers should fall
  /// back to a plain bwrap invocation in that case.
  static String? _resolveApplySeccomp(SandboxConfig config) {
    if (config.allowAllUnixSockets) {
      return null;
    }
    final arch = _archSuffix();
    if (arch == null) {
      return null;
    }
    // Look in the app's assets directory; ship under
    // assets/sandbox/seccomp/apply-seccomp-<arch>. Resolves via
    // `Platform.resolvedExecutable`'s parent directory so we work both in
    // `flutter run` and in a built release bundle.
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      '$exeDir/data/flutter_assets/assets/sandbox/seccomp/apply-seccomp-$arch',
      '$exeDir/../Resources/flutter_assets/assets/sandbox/seccomp/apply-seccomp-$arch',
      // Project-local fallback for dev runs.
      '${Directory.current.path}/assets/sandbox/seccomp/apply-seccomp-$arch',
    ];
    for (final p in candidates) {
      final f = File(p);
      if (!f.existsSync()) {
        continue;
      }
      try {
        final stat = f.statSync();
        const userExec = 0x40; // 0o100 — owner execute bit
        if (stat.mode & userExec != 0) {
          return p;
        }
      } catch (_) {}
    }
    return null;
  }

  static String? _archSuffix() {
    // Process.version exposes CPU arch on some Dart builds; otherwise we
    // inspect uname output (cheap since we already shell out for socat).
    final v = Platform.version.toLowerCase();
    if (v.contains('arm64') || v.contains('aarch64')) {
      return 'arm64';
    }
    if (v.contains('x86_64') || v.contains('amd64')) {
      return 'x64';
    }
    try {
      final result = Process.runSync('uname', ['-m']);
      final out = (result.stdout as String).trim().toLowerCase();
      if (out == 'aarch64' || out == 'arm64') {
        return 'arm64';
      }
      if (out == 'x86_64' || out == 'amd64') {
        return 'x64';
      }
    } catch (_) {}
    return null;
  }

  /// Starts a `socat` UNIX-LISTEN ↔ TCP-CONNECT pair on the host for each
  /// requested bridge. The returned [LinuxBridgeHandles] holds the spawned
  /// processes so the caller can kill them in cleanup.
  static Future<LinuxBridgeHandles> startBridges({
    required String sessionId,
    int? httpProxyPort,
    int? socksProxyPort,
    String socatPath = 'socat',
  }) async {
    final processes = <Process>[];
    final bridges = <LinuxSocketBridge>[];
    if (httpProxyPort != null) {
      final socket = '/tmp/cc-sb-${sessionId}_http.sock';
      _unlinkIfExists(socket);
      final p = await Process.start(socatPath, [
        'UNIX-LISTEN:$socket,fork,reuseaddr',
        'TCP:127.0.0.1:$httpProxyPort',
      ]);
      processes.add(p);
      bridges.add(LinuxSocketBridge(
        hostSocketPath: socket,
        sandboxSocketPath: socket,
        sandboxLoopbackPort: 3128,
      ));
    }
    if (socksProxyPort != null) {
      final socket = '/tmp/cc-sb-${sessionId}_socks.sock';
      _unlinkIfExists(socket);
      final p = await Process.start(socatPath, [
        'UNIX-LISTEN:$socket,fork,reuseaddr',
        'TCP:127.0.0.1:$socksProxyPort',
      ]);
      processes.add(p);
      bridges.add(LinuxSocketBridge(
        hostSocketPath: socket,
        sandboxSocketPath: socket,
        sandboxLoopbackPort: 1080,
      ));
    }
    return LinuxBridgeHandles(processes: processes, bridges: bridges);
  }

  /// Maximum directory depth scanned by [findMandatoryDenyPaths]. Matches
  /// the reference runtime's default of 3.
  static const int _mandatoryDenyDepth = 3;

  /// File basenames + directory names that must never be writable, even
  /// when their parent falls inside an `allowWrite` region.
  static const List<String> _mandatoryFileNames = [
    '.bashrc',
    '.bash_profile',
    '.zshrc',
    '.zprofile',
    '.profile',
    '.gitconfig',
    '.gitmodules',
    '.npmrc',
    '.mcp.json',
    '.ripgreprc',
    // VULN-008: credential files shadowed with /dev/null even when $HOME is
    // writable.
    '.netrc',
    '.git-credentials',
  ];

  static const List<String> _mandatoryEnvPrefixes = ['.env'];

  static const List<String> _mandatoryDirSegments = [
    '.git/hooks',
    '.git/config',
    '.vscode',
    '.idea',
    '.claude/commands',
    '.claude/agents',
    // VULN-008: credential dirs a sandboxed agent must never write.
    '.ssh',
    '.aws',
    '.kube',
    '.docker',
  ];

  /// Scans [allowWritePaths] up to [_mandatoryDenyDepth] levels deep and
  /// returns absolute paths to sensitive files / directories that should be
  /// shadowed with `/dev/null` in the bwrap argv.
  ///
  /// Pure Dart so we don't need `ripgrep` installed — small set of patterns
  /// and shallow depth keep this cheap.
  static List<String> findMandatoryDenyPaths(List<String> allowWritePaths) {
    final hits = <String>{};
    for (final root in allowWritePaths) {
      final dir = Directory(root);
      if (!dir.existsSync()) {
        continue;
      }
      _scan(dir, 0, hits);
    }
    return hits.toList();
  }

  static void _scan(Directory dir, int depth, Set<String> hits) {
    if (depth > _mandatoryDenyDepth) {
      return;
    }
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      return;
    }
    for (final entry in entries) {
      final name = entry.uri.pathSegments.isNotEmpty
          ? entry.uri.pathSegments.last
          : entry.path.split('/').last;
      if (entry is File) {
        if (_mandatoryFileNames.contains(name) ||
            _mandatoryEnvPrefixes.any(name.startsWith)) {
          hits.add(entry.path);
        }
      } else if (entry is Directory) {
        for (final segment in _mandatoryDirSegments) {
          if (entry.path.endsWith('/$segment') || entry.path.endsWith(segment)) {
            hits.add(entry.path);
          }
        }
        _scan(entry, depth + 1, hits);
      }
    }
  }

  /// True when running under WSL2. Used to share the Linux code path on
  /// Windows hosts that have WSL2 set up.
  static bool isWsl2() {
    try {
      final osrelease = File('/proc/sys/kernel/osrelease');
      if (!osrelease.existsSync()) {
        return false;
      }
      final contents = osrelease.readAsStringSync().toLowerCase();
      return contents.contains('microsoft') || contents.contains('wsl');
    } catch (_) {
      return false;
    }
  }

  static void _unlinkIfExists(String path) {
    final f = File(path);
    if (f.existsSync()) {
      f.deleteSync();
    }
  }

  static String _shellQuote(List<String> argv) =>
      argv.map(_quoteOne).join(' ');

  static String _quoteOne(String s) {
    if (s.isEmpty) {
      return "''";
    }
    if (RegExp(r'^[A-Za-z0-9_\-./=:@%+,]+$').hasMatch(s)) {
      return s;
    }
    return "'${s.replaceAll("'", r"'\''")}'";
  }
}

/// One in-sandbox Unix socket bridge: bwrap binds [hostSocketPath] to
/// [sandboxSocketPath], and an in-sandbox `socat` listens on
/// `127.0.0.1:[sandboxLoopbackPort]` and connects to the socket.
class LinuxSocketBridge {
  /// Creates a [LinuxSocketBridge].
  const LinuxSocketBridge({
    required this.hostSocketPath,
    required this.sandboxSocketPath,
    required this.sandboxLoopbackPort,
  });

  /// Path of the Unix socket on the host (where the proxy listens).
  final String hostSocketPath;

  /// Path the same socket appears at inside the sandbox (bind-mounted).
  final String sandboxSocketPath;

  /// Port the in-sandbox `socat` should listen on. The caller is expected
  /// to set `HTTP_PROXY=http://127.0.0.1:<port>` (or `ALL_PROXY` for SOCKS).
  final int sandboxLoopbackPort;
}

/// Host-side bookkeeping for active bridges. Returned by
/// [LinuxSandbox.startBridges] so callers can kill the bridge processes at
/// sandbox shutdown.
class LinuxBridgeHandles {
  /// Creates a [LinuxBridgeHandles].
  const LinuxBridgeHandles({required this.processes, required this.bridges});

  /// Host-side `socat` processes.
  final List<Process> processes;

  /// Bridge descriptors to pass into `LinuxSandbox.buildBwrapArgs`.
  final List<LinuxSocketBridge> bridges;

  /// Kills all bridge processes and unlinks their sockets.
  Future<void> dispose() async {
    for (final p in processes) {
      p.kill();
    }
    for (final b in bridges) {
      final f = File(b.hostSocketPath);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }
}

/// Result of [LinuxSandbox.wrapCommand].
class LinuxWrapResult {
  /// Creates a [LinuxWrapResult].
  const LinuxWrapResult({required this.executable, required this.argv});

  /// Typically `bwrap`.
  final String executable;

  /// Argv excluding [executable].
  final List<String> argv;
}
