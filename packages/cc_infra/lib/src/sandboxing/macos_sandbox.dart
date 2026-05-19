// MacosSandbox is a namespace of pure functions (profile generation, argv
// assembly). Suppress the "no instance members" hint — that's the design.
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:io';

import 'package:cc_infra/src/sandboxing/sandbox_config.dart';

/// Wrapping logic for macOS, using Apple's `sandbox-exec` and a dynamically
/// generated Seatbelt (sbpl) profile.
///
/// The profile is permissive-by-default (`(allow default)`) — a fully
/// deny-by-default profile makes macOS interactive shells unusable (too many
/// dyld/xpc/mach calls to enumerate) — then carves out explicit denies:
///   - `file-read*` denies for secret paths (`~/.ssh`, …)
///   - `file-write*` reset to deny, then explicit subpath allows, with
///     mandatory-deny paths (shell rc, `.git/hooks`, Claude config, …)
///     blocked even inside writable roots
///   - `file-write-unlink` denies (move-blocking) on every denied path +
///     its ancestor directories so `mv payload ~/.bashrc` can't bypass a
///     write-deny via rename
///   - `process-exec` denies for always-dangerous binaries + writable-dir
///     exec blocks (no running copied/symlinked binaries from $HOME or /tmp)
///   - `network*` restricted to ONLY the in-process proxy ports + DNS;
///     loopback is NOT blanket-allowed, unix-sockets are NOT allowed
abstract final class MacosSandbox {
  /// Generates an sbpl profile string from [config].
  ///
  /// [httpProxyPort] / [socksProxyPort] carve out the in-process proxy
  /// loopback endpoints when network is restricted. [allowedExecutables]
  /// are explicit process-exec allows for the legitimate CLI binary (so
  /// the writable-dir exec block doesn't block the agent's own CLI).
  static String generateSeatbeltProfile(
    SandboxConfig config, {
    int? httpProxyPort,
    int? socksProxyPort,
    List<String> allowedExecutables = const [],
  }) {
    final policy = config.policy;
    final isPty = policy?.isPty ?? false;
    final lines = <String>[];
    lines.add('(version 1)');
    lines.add('(allow default)');
    lines.add('');

    // --- Filesystem reads ---
    for (final path in config.filesystem.denyRead) {
      lines.add('(deny file-read* ${_seatbeltPath(path)})');
    }
    for (final path in config.filesystem.allowRead) {
      lines.add('(allow file-read* ${_seatbeltPath(path)})');
    }
    if (config.filesystem.denyRead.isNotEmpty ||
        config.filesystem.allowRead.isNotEmpty) {
      lines.add('');
    }

    // --- Filesystem writes ---
    if (config.filesystem.allowWrite.isNotEmpty ||
        config.filesystem.denyWrite.isNotEmpty) {
      lines.add('(deny file-write*)');
      for (final path in config.filesystem.allowWrite) {
        lines.add('(allow file-write* ${_seatbeltPath(path)})');
      }
      // System scratch dirs the CLI needs (temp, caches).
      for (final standby in const [
        '/private/tmp',
        '/private/var/folders',
      ]) {
        lines.add('(allow file-write* (subpath "$standby"))');
      }
      for (final literal in const [
        '/dev/null',
        '/dev/dtracehelper',
        '/dev/tty',
        '/dev/stdout',
        '/dev/stderr',
      ]) {
        lines.add('(allow file-write* (literal "$literal"))');
      }
      // PTY devices for relay/interactive transports.
      if (isPty) {
        lines.add('(allow file-write* (literal "/dev/ptmx"))');
        lines.add('(allow file-write* (subpath "/dev/pts"))');
      }
      // Secrets + mandatory-deny writes.
      for (final path in config.filesystem.denyWrite) {
        lines.addAll(_denyWriteRule(path));
      }
      lines.add('');
    }

    // --- Move-blocking ---
    // For every denied path, deny file-write-unlink on the path AND its
    // ancestor directories. This prevents `mv payload ~/.bashrc` from
    // bypassing a write-deny via rename (rename(2) triggers
    // file-write-unlink on the destination).
    final moveBlocked = <String>{};
    for (final path in config.filesystem.denyWrite) {
      if (!path.contains('*')) {
        moveBlocked.add(path);
      }
    }
    if (moveBlocked.isNotEmpty) {
      for (final path in moveBlocked) {
        lines.add('(deny file-write-unlink (subpath "${_escape(path)}"))');
        for (final ancestor in _ancestorDirectories(path)) {
          lines.add(
              '(deny file-write-unlink (literal "${_escape(ancestor)}"))');
        }
      }
      lines.add('');
    }

    // --- Exec deny ---
    // Always-dangerous binaries (resolved to absolute paths) + writable-dir
    // exec blocks (no running binaries from $HOME or /tmp — closes the
    // TOCTOU where a copied/symlinked binary bypasses literal exec-denies).
    if (config.denyExecutables.isNotEmpty || policy != null) {
      for (final exePath in config.denyExecutables) {
        lines.add('(deny process-exec (literal "${_escape(exePath)}"))');
        // Also deny realpaths (symlink resolution).
        try {
          final real = File(exePath).resolveSymbolicLinksSync();
          if (real != exePath) {
            lines.add('(deny process-exec (literal "${_escape(real)}"))');
          }
        } catch (_) {}
      }
      final home = policy?.homeDir;
      if (home != null && home.isNotEmpty) {
        lines.add('(deny process-exec (subpath "${_escape(home)}"))');
      }
      lines.add('(deny process-exec (subpath "/tmp"))');
      // Explicit allow for the legitimate CLI binary (more specific than
      // the writable-dir block above).
      // Explicit allows for the legitimate CLI binary + resolved runtime
      // tools (node, python, dart, …) so the writable-dir block doesn't
      // break fnm/nvm/pyenv-managed runtimes. These are more specific than
      // the subpath deny.
      final allAllowed = <String>{
        ...allowedExecutables,
        ...config.allowedExecutables,
      };
      for (final exe in allAllowed) {
        if (exe.isNotEmpty) {
          lines.add('(allow process-exec (literal "${_escape(exe)}"))');
        }
      }
      lines.add('');
    }

    // --- PTY process allows ---
    if (isPty) {
      lines.add('(allow process-exec)');
      lines.add('(allow process-fork)');
      lines.add('');
    }

    // --- Network ---
    if (config.network.isRestricted) {
      lines.add('(deny network*)');
      // Local IP binding is needed for outbound connection setup (the
      // kernel binds an ephemeral local port). This does NOT open egress —
      // egress is gated by the (remote ...) rules below.
      lines.add('(allow network* (local ip))');
      if (httpProxyPort != null) {
        lines.add(
          '(allow network* (remote tcp "localhost:$httpProxyPort"))',
        );
      }
      if (socksProxyPort != null) {
        lines.add(
          '(allow network* (remote tcp "localhost:$socksProxyPort"))',
        );
      }
      // PTY/relay: the Claude relay's AnthropicProxy listens on a dynamic
      // loopback port (unknown at profile-generation time). Allow loopback
      // connections for PTY mode only — the proxy itself is a trusted local
      // intermediary, and real egress is gated by the proxy's allowlist.
      if (isPty) {
        lines.add('(allow network* (remote ip "localhost:*"))');
      }
      // DNS resolution via macOS mDNSResponder.
      lines.add(
        '(allow network-outbound (literal "/private/var/run/mDNSResponder"))',
      );
      // Explicit deny for container/runtime sockets (belt-and-suspenders —
      // they're already blocked by the blanket deny + removal of the
      // unix-socket allow).
      for (final sock in const [
        '/var/run/docker.sock',
        '/var/run/colima.sock',
        '/var/run/lima.sock',
        '/private/var/run/docker.sock',
        '/private/var/run/colima.sock',
      ]) {
        lines.add('(deny network-outbound (literal "$sock"))');
      }
      lines.add('');
    }

    return lines.join('\n');
  }

  /// Builds the argv used to invoke a sandboxed command via `sandbox-exec`.
  /// The profile is written to a temp file under [profilesDir] and its path
  /// is returned alongside the argv so the caller can clean it up.
  static MacosWrapResult wrapCommand({
    required SandboxConfig config,
    required List<String> argv,
    required Directory profilesDir,
    String? workingDirectory,
    int? httpProxyPort,
    int? socksProxyPort,
    String binShell = '/bin/bash',
  }) {
    if (!profilesDir.existsSync()) {
      profilesDir.createSync(recursive: true);
    }
    // The legitimate CLI binary gets an explicit exec allow so the
    // writable-dir exec block doesn't block it.
    final allowedExecutables = <String>[
      if (argv.isNotEmpty) argv.first,
      binShell,
    ];
    final profile = generateSeatbeltProfile(
      config,
      httpProxyPort: httpProxyPort,
      socksProxyPort: socksProxyPort,
      allowedExecutables: allowedExecutables,
    );
    final profileFile = File(
      '${profilesDir.path}/sandbox-${config.sessionId}.sb',
    );
    profileFile.writeAsStringSync(profile);

    final inner = _shellQuote(argv);
    final wrapped = <String>[
      '-f',
      profileFile.path,
      binShell,
      '-c',
      workingDirectory == null
          ? inner
          : 'cd ${_shellQuote([workingDirectory])} && $inner',
    ];
    return MacosWrapResult(
      executable: '/usr/bin/sandbox-exec',
      argv: wrapped,
      profilePath: profileFile.path,
    );
  }

  /// Returns a seatbelt deny rule for a write-denied path. Glob patterns
  /// (`**/...`) are converted to regex rules; literal paths use subpath.
  static List<String> _denyWriteRule(String path) {
    if (path.contains('*')) {
      final regex = _globToSeatbeltRegex(path);
      if (regex != null) {
        return ['(deny file-write* (regex #"$regex"))'];
      }
    }
    return ['(deny file-write* ${_seatbeltPath(path)})'];
  }

  /// Converts a glob pattern to a seatbelt-flavoured POSIX regex string.
  /// `**` → `.*`, `*` → `[^/]*`, other chars are escaped.
  static String? _globToSeatbeltRegex(String glob) {
    final buf = StringBuffer();
    var i = 0;
    while (i < glob.length) {
      final c = glob[i];
      if (c == '*' && i + 1 < glob.length && glob[i + 1] == '*') {
        buf.write('.*');
        i += 2;
        // Skip optional trailing /.
        if (i < glob.length && glob[i] == '/') {
          i++;
        }
      } else if (c == '*') {
        buf.write('[^/]*');
        i++;
      } else if (RegExp(r'[.+?^${}()|[\]\\]').hasMatch(c)) {
        buf.write('\\$c');
        i++;
      } else {
        buf.write(c);
        i++;
      }
    }
    return '^${buf.toString()}\$';
  }

  /// Returns all ancestor directories of [path] (not including `/` or `.`).
  /// E.g. `/Users/foo/.bashrc` → `['/Users/foo', '/Users']`.
  static List<String> _ancestorDirectories(String path) {
    final ancestors = <String>[];
    var current = File(path).parent.path;
    while (current != '/' && current != '.') {
      ancestors.add(current);
      final parent = Directory(current).parent.path;
      if (parent == current) break;
      current = parent;
    }
    return ancestors;
  }

  static String _seatbeltPath(String path) {
    // sbpl path predicates: `subpath` matches a directory tree, `literal`
    // matches an exact file. We prefer the filesystem-truth answer (if the
    // path exists, ask whether it's a directory). For non-existent paths,
    // prefer subpath (broader match — safer for deny rules).
    if (path.endsWith('/')) {
      return '(subpath "${_escape(path)}")';
    }
    try {
      final stat = FileSystemEntity.typeSync(path, followLinks: false);
      if (stat == FileSystemEntityType.directory) {
        return '(subpath "${_escape(path)}")';
      }
      if (stat == FileSystemEntityType.file) {
        return '(literal "${_escape(path)}")';
      }
    } catch (_) {}
    return '(subpath "${_escape(path)}")';
  }

  static String _escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  static String _shellQuote(List<String> argv) {
    return argv.map(_quoteOne).join(' ');
  }

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

/// Result of [MacosSandbox.wrapCommand].
class MacosWrapResult {
  /// Creates a [MacosWrapResult].
  const MacosWrapResult({
    required this.executable,
    required this.argv,
    required this.profilePath,
  });

  /// Executable to spawn (always `/usr/bin/sandbox-exec`).
  final String executable;

  /// Argv list passed to [Process.start].
  final List<String> argv;

  /// Path to the generated Seatbelt profile file. The caller should delete
  /// it when the session ends.
  final String profilePath;
}
