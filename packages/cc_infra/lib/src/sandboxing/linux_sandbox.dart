// LinuxSandbox is a namespace of pure functions (argv assembly, bridge
// lifecycle). Suppress the "no instance members" hint — that's the design.
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/hidden_roots.dart';
import 'package:cc_infra/src/sandboxing/host_executables.dart';

/// Wrapping logic for Linux (and WSL2), using `bubblewrap` (`bwrap`) for
/// filesystem + PID + namespace isolation and `socat` Unix-socket bridges
/// for routing sandboxed traffic to the in-process HTTP/SOCKS proxies on the
/// host.
///
/// The bwrap argv is built from [SandboxConfig.filesystem]:
///   - `--bind <p> <p>` for every `allowWrite` entry (writable bind mount)
///   - `--ro-bind /dev/null <p>` for literal `denyWrite` paths
///   - `--ro-bind /dev/null <p>` for every `denyRead` file
///   - `--tmpfs <p>` for `denyRead` directories that need to look empty
///   - `--unshare-net --unshare-pid --proc /proc --dev /dev` as configured
///
/// Globbed deny-write rules cannot be enforced by mount points: enumerating
/// existing files still lets a process create a new matching filename. Refuse
/// those configurations rather than silently start an under-protected shell.
/// Networking, when enabled, is reachable only through Unix sockets bind-mounted
/// into the sandbox; the in-sandbox `socat` listens on 127.0.0.1 and forwards
/// to those sockets so the user command sees a normal `HTTP_PROXY` URL.
abstract final class LinuxSandbox {
  /// Rejects deny-write patterns that bwrap cannot enforce for future files.
  ///
  /// There is no bwrap pathname-glob rule or safe expansion of one: a process
  /// can create `.env`, `secret.key`, or a nested directory after mounting.
  static void validateConfig(SandboxConfig config) {
    for (final path in config.filesystem.denyWrite) {
      if (path.contains('*') || path.contains('?')) {
        throw UnsupportedError(
          'Linux bubblewrap cannot enforce denyWrite pattern "$path" for '
          'new files; refusing to run without secret-write protection.',
        );
      }
    }
  }

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
    validateConfig(config);
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
      // Numeric, never the name: bwrap resolves --cap-add through libcap's
      // cap_from_name, and some libcap builds fail the NAME lookup for every
      // capability (CI's ubuntu-24.04 runner dies "bwrap: unknown cap:
      // NET_ADMIN" before creating a single namespace, so every restricted
      // sandbox — not just tests — refused to start). libcap's numeric path
      // is a plain strtoul and cannot misresolve. CAP_NET_ADMIN = 12 is
      // frozen kernel ABI (uapi/linux/capability.h).
      args.add('12');
    }

    final hidden = HiddenRoots.of(config);
    // Paths granted for reading only, so they exist in here (the server's own
    // agent run client may live under `/opt`, which nothing else binds).
    // Bound before the writable roots: a path inside one keeps whatever the
    // binds after it decide, and a hidden one is bound back further down.
    for (final p in config.filesystem.allowRead) {
      if (!hidden.covers(p)) {
        args.addAll(['--ro-bind-try', p, p]);
      }
    }
    // Writable roots inside a hidden one are bound after it is masked.
    for (final p in config.filesystem.allowWrite) {
      if (!hidden.covers(p)) {
        args.addAll(['--bind', p, p]);
      }
    }
    args.addAll(hostExecutableBinds(config));
    for (final p in config.filesystem.denyRead) {
      if (FileSystemEntity.isDirectorySync(p)) {
        args.addAll(['--tmpfs', p]);
      } else {
        args.addAll(['--ro-bind-try', '/dev/null', p]);
      }
    }
    // Server-private trees: an empty tmpfs over a directory (it may sit under
    // the writable `$HOME`), `/dev/null` over a file, then exactly what the
    // config names inside them bound back. bwrap reads every bind source from
    // the host's tree, so the mask does not hide the sources.
    for (final root in hidden.roots) {
      if (FileSystemEntity.isDirectorySync(root)) {
        args.addAll(['--tmpfs', root]);
      } else {
        args.addAll(['--ro-bind-try', '/dev/null', root]);
      }
    }
    for (final p in hidden.writable) {
      args.addAll(['--bind-try', p, p]);
    }
    for (final p in hidden.readable) {
      if (!hidden.writable.contains(p)) {
        args.addAll(['--ro-bind-try', p, p]);
      }
    }
    for (final p in config.filesystem.denyWrite) {
      // Re-binding a hidden or read-denied directory read-only would make it
      // readable. Both are masked already, and nothing written to the mask
      // reaches the host.
      if (hidden.hides(p) || config.filesystem.denyRead.contains(p)) {
        continue;
      }
      // bwrap can only shadow what exists: binding over a missing path
      // creates it on the host, and an empty `.git/commondir` breaks git.
      // macOS denies the missing ones too; here they stay creatable.
      if (FileSystemEntity.typeSync(p, followLinks: false) ==
          FileSystemEntityType.notFound) {
        continue;
      }
      if (FileSystemEntity.isDirectorySync(p)) {
        // A directory cannot be shadowed by /dev/null: bwrap refuses the
        // mount outright ("Can't create file at …: Is a directory") and the
        // WHOLE sandbox dies at spawn — every dispatch with a protected
        // checkout (i.e. every dispatch) failed this way. A directory is
        // denied WRITES by re-binding itself read-only: visible, unchanged,
        // untouchable. Read-denial stays denyRead's business (tmpfs).
        args.addAll(['--ro-bind-try', p, p]);
      } else {
        args.addAll(['--ro-bind-try', '/dev/null', p]);
      }
    }

    // Read-only mounts: worktree visible but not writable in
    // review/plan/orchestrate modes. Must come AFTER the writable binds so
    // bwrap's last-mount-wins resolution gives us read-only visibility.
    for (final p in config.policy?.readOnlyMounts ?? const <String>[]) {
      args.addAll(['--ro-bind-try', p, p]);
    }

    // …and the run directory must come after THOSE: it is the sanctioned
    // writable scratch in read-only modes, but it lives at
    // `<agentDir>/.cc-runs/<sessionId>` — inside a bind mount the loop above
    // just re-mounted read-only. Re-bind it writable so last-mount-wins keeps
    // the promise `SandboxPolicySpec.runDir` makes.
    final runDir = config.policy?.runDir;
    if (runDir != null && runDir.isNotEmpty) {
      args.addAll(['--bind', runDir, runDir]);
    }

    // …and so must the runner's own state dirs (the CC-managed
    // `CLAUDE_CONFIG_DIR`), for the same last-mount-wins reason: the CLI
    // refreshes its token in there, so a read-only re-mount over it turns
    // every long run into a mid-turn 401. `--bind-try`, not `--bind`: a
    // configured-but-not-yet-created dir must not abort the whole spawn.
    for (final dir in config.policy?.runnerStateDirs ?? const <String>[]) {
      if (dir.isNotEmpty) {
        args.addAll(['--bind-try', dir, dir]);
      }
    }

    // The run's tool dirs (its git signer, its environment shims) sit inside
    // its writable worktree. Re-bound read-only after every writable bind, so
    // last-mount-wins keeps them unchangeable.
    for (final dir in config.policy?.toolDirs ?? const <String>[]) {
      if (dir.isNotEmpty) {
        args.addAll(['--ro-bind-try', dir, dir]);
      }
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
      if (isGitInternal(mandatory)) {
        // Git inside the sandbox still reads these (an empty config has no
        // remotes, empty alternates lose objects): unwritable, not gone.
        // One inside a hidden root stays hidden: re-binding it would show it.
        if (!hidden.hides(mandatory)) {
          args.addAll(['--ro-bind-try', mandatory, mandatory]);
        }
      } else if (FileSystemEntity.isDirectorySync(mandatory)) {
        // A directory cannot be shadowed by /dev/null — bwrap refuses the
        // mount ("Can't create file at …: Is a directory") and the WHOLE
        // sandbox dies at spawn. A mandatory deny wants the path GONE, and
        // a tmpfs is the directory-shaped way to make one unreadable (same
        // treatment denyRead directories get).
        args.addAll(['--tmpfs', mandatory]);
      } else {
        args.addAll(['--ro-bind-try', '/dev/null', mandatory]);
      }
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

  /// The binds that keep the host's executable directories unchangeable
  /// (see [FilesystemConfig.hostExecutables]), placed right after the
  /// writable binds so every later mask still applies inside them.
  ///
  /// bwrap has no per-name rule, so a directory is re-bound read-only and its
  /// existing sub-directories re-bound writable over it: its direct children
  /// cannot change, the trees below them can. Each directory between the
  /// writable root and a protected path is bound onto itself, which makes it a
  /// mount point that cannot be renamed or removed (`EBUSY`). A symlink cannot
  /// be bound, so the directory holding it is treated like an executable
  /// directory. bwrap only binds what exists: a missing directory stays
  /// creatable here (macOS denies it).
  static List<String> hostExecutableBinds(SandboxConfig config) {
    final writableRoots = config.filesystem.allowWrite;
    final protect = hostExecutablesUnder(
      config.filesystem.hostExecutables,
      writableRoots,
    );
    if (protect.isEmpty) {
      return const [];
    }
    bool exists(String path) => FileSystemEntity.isDirectorySync(path);
    final readOnlyDirs = <String>{
      for (final dir in protect.dirs)
        if (exists(dir) &&
            FileSystemEntity.typeSync(dir, followLinks: false) !=
                FileSystemEntityType.link)
          dir,
      // Not when the link sits directly in a writable root: that root would
      // turn read-only as a whole.
      for (final link in protect.links)
        if (exists(_parent(link)) && !writableRoots.contains(_parent(link)))
          _parent(link),
    };
    final readOnlyTrees = <String>{
      for (final root in protect.installRoots)
        if (FileSystemEntity.typeSync(root) != FileSystemEntityType.notFound)
          root,
    };
    final mountPoints = <String>{
      for (final path in [...readOnlyDirs, ...readOnlyTrees])
        ...ancestorsBelowWritableRoot(path, writableRoots),
    }..removeAll([...readOnlyDirs, ...readOnlyTrees]);
    final args = <String>[];
    // Outermost first: a later bind of an ancestor would cover the ones
    // below it.
    for (final dir
        in mountPoints.toList()..sort((a, b) => a.length.compareTo(b.length))) {
      args.addAll(['--bind', dir, dir]);
    }
    for (final dir in readOnlyDirs) {
      args.addAll(['--ro-bind', dir, dir]);
      final List<FileSystemEntity> children;
      try {
        children = Directory(dir).listSync(followLinks: false);
      } on FileSystemException {
        continue;
      }
      for (final child in children.whereType<Directory>()) {
        if (!readOnlyDirs.contains(child.path) &&
            !mountPoints.contains(child.path)) {
          args.addAll(['--bind', child.path, child.path]);
        }
      }
    }
    for (final root in readOnlyTrees) {
      args.addAll(['--ro-bind', root, root]);
    }
    return args;
  }

  static String _parent(String path) => File(path).parent.path;

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
        .map(
          (b) =>
              'socat TCP-LISTEN:${b.sandboxLoopbackPort},reuseaddr,fork,bind=127.0.0.1 '
              'UNIX-CONNECT:${b.sandboxSocketPath} &',
        )
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
      final result = ChildProcess.runSync('uname', ['-m']);
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
    List<int> loopbackPorts = const [],
    String socatPath = 'socat',
  }) async {
    final processes = <Process>[];
    final bridges = <LinuxSocketBridge>[];
    if (httpProxyPort != null) {
      final socket = '/tmp/cc-sb-${sessionId}_http.sock';
      _unlinkIfExists(socket);
      final p = await ChildProcess.start(socatPath, [
        'UNIX-LISTEN:$socket,fork,reuseaddr',
        'TCP:127.0.0.1:$httpProxyPort',
      ]);
      processes.add(p);
      bridges.add(
        LinuxSocketBridge(
          hostSocketPath: socket,
          sandboxSocketPath: socket,
          sandboxLoopbackPort: 3128,
        ),
      );
    }
    if (socksProxyPort != null) {
      final socket = '/tmp/cc-sb-${sessionId}_socks.sock';
      _unlinkIfExists(socket);
      final p = await ChildProcess.start(socatPath, [
        'UNIX-LISTEN:$socket,fork,reuseaddr',
        'TCP:127.0.0.1:$socksProxyPort',
      ]);
      processes.add(p);
      bridges.add(
        LinuxSocketBridge(
          hostSocketPath: socket,
          sandboxSocketPath: socket,
          sandboxLoopbackPort: 1080,
        ),
      );
    }
    // The server's own agent endpoint (MCP, the agent run gateway), reachable
    // inside the namespace at the SAME port, so a URL written for the host
    // works unchanged in here.
    for (final port in loopbackPorts) {
      final socket = '/tmp/cc-sb-${sessionId}_lo$port.sock';
      _unlinkIfExists(socket);
      final p = await ChildProcess.start(socatPath, [
        'UNIX-LISTEN:$socket,fork,reuseaddr',
        'TCP:127.0.0.1:$port',
      ]);
      processes.add(p);
      bridges.add(
        LinuxSocketBridge(
          hostSocketPath: socket,
          sandboxSocketPath: socket,
          sandboxLoopbackPort: port,
        ),
      );
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

  /// The git internals that steer which config, hooks, attributes and
  /// objects git reads (`SandboxPolicyResolver.dangerousGitPaths`), as path
  /// endings.
  static const List<String> _gitInternalSegments = [
    '.git/hooks',
    '.git/config',
    '.git/config.worktree',
    '.git/commondir',
    '.git/info',
    '.git/objects/info',
  ];

  /// Whether [path] is one of [_gitInternalSegments].
  static bool isGitInternal(String path) =>
      _gitInternalSegments.any((segment) => path.endsWith('/$segment'));

  /// Directory names that must never be writable, matched as path endings.
  static const List<String> _mandatoryDirSegments = [
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
      if (isGitInternal(entry.path)) {
        hits.add(entry.path);
        continue;
      }
      if (entry is File) {
        if (_mandatoryFileNames.contains(name) ||
            _mandatoryEnvPrefixes.any(name.startsWith)) {
          hits.add(entry.path);
        }
      } else if (entry is Directory) {
        for (final segment in _mandatoryDirSegments) {
          if (entry.path.endsWith('/$segment') ||
              entry.path.endsWith(segment)) {
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

  static String _shellQuote(List<String> argv) => argv.map(_quoteOne).join(' ');

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
/// [sandboxSocketPath] and an in-sandbox `socat` listens on
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
