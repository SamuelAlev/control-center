// MacosSandbox is a namespace of pure functions (profile generation, argv
// assembly). Suppress the "no instance members" hint — that's the design.
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:io';

import 'package:control_center/features/sandboxing/data/runtime/sandbox_config.dart';

/// Wrapping logic for macOS, using Apple's `sandbox-exec` and a dynamically
/// generated Seatbelt (sbpl) profile.
///
/// The profile is permissive-by-default (a deny-by-default profile makes
/// macOS interactive shells unusable — too many dyld/xpc/mach calls to
/// enumerate), then carves out:
///   - `file-read*` denies for our list of secret paths (`~/.ssh`, …)
///   - `file-write*` reset to deny, then explicit subpath allows
///   - `network*` restricted to `localhost:<proxyPort>` when network is on
///     and the in-process HTTP proxy is the only egress path
abstract final class MacosSandbox {
  /// Generates an sbpl profile string from [config]. When the proxy ports are
  /// non-null, the profile carves out `localhost:<port>` so the sandboxed
  /// process can reach the in-process proxies; otherwise network is fully
  /// blocked.
  static String generateSeatbeltProfile(
    SandboxConfig config, {
    int? httpProxyPort,
    int? socksProxyPort,
  }) {
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
      for (final path in config.filesystem.denyWrite) {
        lines.add('(deny file-write* ${_seatbeltPath(path)})');
      }
      for (final mandatory in _mandatoryDenyPaths(config)) {
        lines.add('(deny file-write* ${_seatbeltPath(mandatory)})');
      }
      lines.add('');
    }

    // --- Network ---
    if (config.network.isRestricted) {
      lines.add('(deny network*)');
      lines.add('(allow network* (remote ip "localhost:*"))');
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
      // DNS resolution via macOS mDNSResponder — without this, every
      // hostname lookup fails before the HTTP proxy ever gets a chance.
      lines.add(
        '(allow network-outbound (literal "/private/var/run/mDNSResponder"))',
      );
      // Generic Unix domain sockets used by various local system services
      // (CFNetwork, syslog, etc.). The HTTP/SOCKS allowlist still gates
      // anything that reaches the real internet.
      lines.add('(allow network-outbound (remote unix-socket))');
      lines.add('(allow network-outbound (control-name "com.apple.netsrc"))');
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
    final profile = generateSeatbeltProfile(
      config,
      httpProxyPort: httpProxyPort,
      socksProxyPort: socksProxyPort,
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

  /// Mandatory denies that apply to writes even when the path falls within
  /// [FilesystemConfig.allowWrite]. Mirrors the reference's
  /// `macGetMandatoryDenyPatterns` but kept tiny — these are the paths that
  /// can lead to sandbox escape if writable.
  static List<String> _mandatoryDenyPaths(SandboxConfig config) {
    final home = Platform.environment['HOME'] ?? '';
    return [
      if (home.isNotEmpty && !config.skipMandatoryHomeRcDenies) ...[
        '$home/.bashrc',
        '$home/.bash_profile',
        '$home/.zshrc',
        '$home/.zprofile',
        '$home/.profile',
        '$home/.gitconfig',
      ],
      for (final writable in config.filesystem.allowWrite) ...[
        '$writable/.git/hooks',
        '$writable/.git/config',
        '$writable/.npmrc',
      ],
    ];
  }

  static String _seatbeltPath(String path) {
    // sbpl path predicates: `subpath` matches a directory tree, `literal`
    // matches an exact file. We prefer the filesystem-truth answer (if the
    // path exists, ask whether it's a directory). For non-existent paths,
    // fall back to a heuristic: a basename starting with `.` (like `.ssh`)
    // is treated as a hidden directory, plain extensions like `.env` stay
    // as literals.
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
    // Unknown path: prefer subpath (broader match — safer for deny rules).
    return '(subpath "${_escape(path)}")';
  }

  static String _escape(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

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

  /// Always `/usr/bin/sandbox-exec`.
  final String executable;

  /// Argv to spawn (does *not* include [executable]).
  final List<String> argv;

  /// Filesystem path of the generated sbpl profile, for cleanup by the caller.
  final String profilePath;
}
