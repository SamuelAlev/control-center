import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:path/path.dart' as p;

/// Infra-layer materializer that turns a pure [SandboxPolicySpec] into a
/// platform-ready [SandboxConfig].
///
/// Lives in `cc_infra` (not the domain layer) because it needs:
///   * `Platform.environment['HOME']` — the real user home.
///   * `resolveBinaryPath` — to turn exec-deny tokens into absolute paths.
///   * Shell realpath resolution — to never deny the wrap shell itself.
///
/// The resulting [SandboxConfig] carries the resolved [SandboxConfig.policy]
/// so the platform materializers (Seatbelt profile, bwrap argv) can read the
/// home/runDir anchors and dangerous-path constants for recursive
/// mandatory-deny + move-blocking emission.
class SandboxConfigBuilder {
  /// Creates a [SandboxConfigBuilder].
  const SandboxConfigBuilder();

  /// The shell used to wrap sandboxed commands. Must never be exec-denied
  /// (the sandbox invocation itself runs through it).
  static const String wrapShell = '/bin/bash';

  /// Builds a [SandboxConfig] from [spec].
  Future<SandboxConfig> build(SandboxPolicySpec spec) async {
    final denyExecutables = await _resolveExecDenies(spec.denyExecutables);
    final allowedExecutables = await _resolveRuntimeTools(spec.homeDir);

    // Network: default-deny. Never allowAll:true — when on, restrict to the
    // resolved baseline + capability domains through the in-process proxy.
    final network = spec.networkOn
        ? NetworkConfig(
            allowAll: false,
            allowedDomains: spec.allowedDomains,
            deniedDomains: spec.deniedDomains,
          )
        : const NetworkConfig(allowAll: false);

    // Expand mandatory-deny write paths: home-mandatory (Claude config, CC
    // plist, credential stores) + recursive scan of writable roots for
    // dangerous files/dirs (shell rc, .git/hooks, editor configs, …).
    final denyWrite = _withResolvedPaths([
      ...spec.denyWrite,
      ..._expandHomeMandatoryDeny(spec),
      ..._scanDangerousPaths(spec),
    ]);

    // ALLOW paths need the same treatment as deny paths, and for a sharper
    // reason. The kernel matches every rule against the resolved path, so an
    // allow written against a symlinked one never fires — while the deny that
    // shadows it, having been resolved above, does. The pair then reads as "we
    // allowed it and it was refused anyway". Concretely: a data dir reached
    // through `/tmp` or `/var/folders` (both symlinks on macOS) made the
    // Claude Code account dir unwritable inside a protected checkout, and made
    // a read-only mount not read-only at all.
    return SandboxConfig(
      sessionId: spec.sessionId,
      network: network,
      filesystem: FilesystemConfig(
        denyRead: _withResolvedPaths(spec.denyRead),
        allowWrite: _withResolvedPaths(spec.allowWrite),
        denyWrite: denyWrite,
      ),
      denyExecutables: denyExecutables,
      allowedExecutables: allowedExecutables,
      // Grants get the same symlink treatment as every other rule, and for the
      // same reason: the kernel matches an exec rule against the RESOLVED path,
      // so a grant written against a symlinked worktree would emit an allow
      // that never fires — while the `$HOME` deny above, already resolved,
      // would. The pair reads as "we allowed it and it was refused anyway".
      allowedExecRoots: _withResolvedPaths(spec.execGrantRoots),
      policy: spec.copyWith(
        readOnlyMounts: _withResolvedPaths(spec.readOnlyMounts),
        runnerStateDirs: _withResolvedPaths(spec.runnerStateDirs),
        execGrantRoots: _withResolvedPaths(spec.execGrantRoots),
      ),
    );
  }

  /// Returns [paths] plus the real path of every entry that is a symlink,
  /// preserving order and dropping duplicates.
  ///
  /// A deny rule is matched by the kernel against the **resolved** path, so a
  /// rule written against a symlinked one silently never fires. macOS makes
  /// this the common case rather than the exotic one — `/tmp` is
  /// `/private/tmp` and `/var/folders/…` is `/private/var/folders/…` — so a
  /// protected checkout reached through either would have been writable while
  /// the profile appeared to forbid it. Emitting both spellings costs a line
  /// in the profile and closes that hole.
  ///
  /// A path that does not resolve (missing, or a dangling link) is kept as
  /// written: it may exist by the time the sandboxed process runs and a deny
  /// rule for a nonexistent path is harmless.
  static List<String> _withResolvedPaths(List<String> paths) {
    final out = <String>{};
    for (final p in paths) {
      out.add(p);
      // Globs and regex-shaped entries are not filesystem paths.
      if (p.contains('*') || p.contains('?')) {
        continue;
      }
      try {
        final resolved = Directory(p).existsSync()
            ? Directory(p).resolveSymbolicLinksSync()
            : File(p).resolveSymbolicLinksSync();
        if (resolved != p) {
          out.add(resolved);
        }
      } on Object {
        // Unresolvable — keep the literal only.
      }
    }
    return out.toList(growable: false);
  }

  /// Resolves exec-deny tokens to absolute paths, expanding `mkfs.*`-style
  /// globs against the standard bin directories. The wrap shell and its
  /// realpath are always excluded so the sandbox can still invoke it.
  Future<List<String>> _resolveExecDenies(List<String> tokens) async {
    final excluded = _shellRealpaths();
    final resolved = <String>{};

    for (final token in tokens) {
      if (token.endsWith('.*')) {
        // Glob: expand against bin directories (e.g. mkfs.* → mkfs.ext4 …).
        final prefix = token.substring(0, token.length - 2);
        for (final path in _globBinaries(prefix)) {
          if (!_isExcluded(path, excluded)) {
            resolved.add(path);
          }
        }
      } else {
        final path = await _resolveAbsolute(token);
        if (path == null) {
          continue;
        }
        if (!_isExcluded(path, excluded)) {
          resolved.add(path);
        }
      }
    }
    return resolved.toList()..sort();
  }

  /// Resolves [binary] to an ABSOLUTE path, or null when it cannot be pinned.
  ///
  /// Probes the known install prefixes and an absolute `PATH` scan only — no
  /// `--version` subprocess. A sandbox profile rule is matched against a
  /// path: `(allow process-exec (literal "dart"))` matches nothing, so the
  /// tool stayed blocked by the writable-dir exec deny — fvm puts `dart` and
  /// `flutter` under `$HOME`, so on an fvm-managed checkout an agent could not
  /// run either one. The same shape on the deny side is worse: a bare `(deny
  /// process-exec (literal "rm"))` is a deny that silently never fires.
  ///
  /// (`resolveBinaryPath`'s `--version` last resort is deliberately NOT used
  /// here: its answer for a PATH-only binary is the bare token, which this
  /// method discards anyway — and this builder resolves ~18 runtime tools per
  /// spec, where a slow `binary --version` (a cold `flutter` rebuilds its
  /// tool) would dominate the build.)
  static Future<String?> _resolveAbsolute(String binary) async {
    for (final candidate in candidateBinaryPaths(binary)) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    final scanned = _scanPath(binary);
    if (scanned == null) {
      CcInfraLog.warning(
        'SandboxConfigBuilder: "$binary" could not be pinned '
        'to an absolute path; its sandbox exec rule is omitted rather than '
        'emitted as an inert relative rule.',
      );
    }
    return scanned;
  }

  /// First executable named [binary] on `PATH`. Relative `PATH` entries are
  /// skipped — they resolve against the cwd, which the profile cannot pin.
  static String? _scanPath(String binary) {
    final raw = Platform.environment['PATH'] ?? '';
    final sep = Platform.isWindows ? ';' : ':';
    for (final dir in raw.split(sep)) {
      if (dir.isEmpty || !p.isAbsolute(dir)) {
        continue;
      }
      final candidate = p.join(dir, binary);
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  /// Common runtime tools that CLIs spawn as subprocesses. Resolved to
  /// absolute paths and added as explicit exec allows so the writable-dir
  /// exec block doesn't break fnm/nvm/pyenv/fvm-managed runtimes.
  static const List<String> _runtimeTools = [
    'node',
    'npm',
    'npx',
    'pnpm',
    'yarn',
    'python',
    'python3',
    'pip',
    'pip3',
    'uv',
    'dart',
    'flutter',
    'bun',
    'deno',
    'cargo',
    'rustc',
    'go',
    'git',
  ];

  Future<List<String>> _resolveRuntimeTools(String? homeDir) async {
    final resolved = <String>{};
    for (final tool in _runtimeTools) {
      final path = await _resolveAbsolute(tool);
      if (path != null) {
        resolved.add(path);
        // Also resolve realpath (symlink targets under fnm/nvm/fvm). The kernel
        // matches an exec rule against the RESOLVED path, so for a tool reached
        // through a symlink this entry — not the one above — is what fires.
        try {
          final real = File(path).resolveSymbolicLinksSync();
          resolved.add(real);
        } catch (_) {}
      }
    }
    return resolved.toList()..sort();
  }

  /// Returns the wrap shell + its realpath so exec-deny never blocks the
  /// sandbox's own invocation wrapper.
  Set<String> _shellRealpaths() {
    final excluded = <String>{wrapShell};
    try {
      final real = File(wrapShell).resolveSymbolicLinksSync();
      excluded.add(real);
    } catch (_) {
      // /bin/bash may not resolve on all platforms; non-fatal.
    }
    return excluded;
  }

  bool _isExcluded(String path, Set<String> excluded) =>
      excluded.contains(path);

  /// Scans the standard bin directories for executables whose name starts
  /// with [prefix] + `.` (so `mkfs` matches `mkfs.ext4` but not `mkfs`).
  Iterable<String> _globBinaries(String prefix) sync* {
    final pattern = RegExp('^${RegExp.escape(prefix)}\\..+');
    for (final dir in _binDirectories) {
      final d = Directory(dir);
      if (!d.existsSync()) {
        continue;
      }
      try {
        for (final entry in d.listSync(followLinks: false)) {
          final name = entry.uri.pathSegments.last;
          if (pattern.hasMatch(name)) {
            yield entry.path;
          }
        }
      } catch (_) {
        // Permission errors on system dirs — skip silently.
      }
    }
  }

  /// Directories scanned for exec-deny glob expansion.
  static const List<String> _binDirectories = [
    '/sbin',
    '/usr/sbin',
    '/usr/bin',
    '/bin',
    '/usr/local/sbin',
    '/usr/local/bin',
  ];

  /// Expands `SandboxPolicyResolver.homeMandatoryDenyRels` +
  /// `SandboxPolicyResolver.homeRcDenyRels` against `spec.homeDir`. These
  /// are paths that must NEVER be writable (Claude config, CC plist,
  /// credential stores, shell rc).
  List<String> _expandHomeMandatoryDeny(SandboxPolicySpec spec) {
    final home = spec.homeDir;
    if (home == null || home.isEmpty) {
      return const [];
    }
    return [
      for (final rel in SandboxPolicyResolver.homeMandatoryDenyRels)
        '$home/$rel',
      for (final rel in SandboxPolicyResolver.homeRcDenyRels) '$home/$rel',
    ];
  }

  /// Recursively scans each writable root (up to [_dangerousScanDepth]
  /// levels) for dangerous files/directories that must never be writable —
  /// shell dotfiles, editor configs, `.git/hooks`, `.claude/commands`, etc.
  /// Returns absolute paths to shadow with deny-write rules.
  ///
  /// Skips `node_modules` and `.git` internals (except hooks/config) for
  /// performance. Items directly in the root are included.
  List<String> _scanDangerousPaths(SandboxPolicySpec spec) {
    final results = <String>{};
    final dangerousNames = {
      ...SandboxPolicyResolver.dangerousFiles,
      ...SandboxPolicyResolver.dangerousExtraFiles,
    };
    final dangerousDirNames = SandboxPolicyResolver.dangerousDirectories
        .toSet();
    final gitPaths = SandboxPolicyResolver.dangerousGitPaths.toSet();

    for (final root in spec.allowWrite) {
      if (root.isEmpty) {
        continue;
      }
      _scanDir(
        Directory(root),
        root,
        0,
        dangerousNames,
        dangerousDirNames,
        gitPaths,
        results,
      );
      // Direct git internals under the root.
      for (final g in SandboxPolicyResolver.dangerousGitPaths) {
        final p = '$root/$g';
        if (FileSystemEntity.typeSync(p, followLinks: false) !=
            FileSystemEntityType.notFound) {
          results.add(p);
        }
      }
      for (final f in SandboxPolicyResolver.dangerousExtraFiles) {
        final p = '$root/$f';
        if (FileSystemEntity.typeSync(p, followLinks: false) !=
            FileSystemEntityType.notFound) {
          results.add(p);
        }
      }
    }
    return results.toList()..sort();
  }

  static const int _dangerousScanDepth = 3;

  void _scanDir(
    Directory dir,
    String root,
    int depth,
    Set<String> dangerousNames,
    Set<String> dangerousDirNames,
    Set<String> gitPaths,
    Set<String> results,
  ) {
    if (depth > _dangerousScanDepth) {
      return;
    }
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      return;
    }
    for (final entry in entries) {
      final name = entry.uri.pathSegments.last;

      if (dangerousNames.contains(name)) {
        results.add(entry.path);
        continue;
      }

      if (entry is Directory) {
        if (dangerousDirNames.contains(name)) {
          results.add(entry.path);
          continue;
        }
        // Peek inside .git for hooks/config (without counting against
        // depth or descending into the full git internals).
        if (name == '.git') {
          for (final g in gitPaths) {
            // p.join, not '$path/leaf': the deny rules are host paths and a
            // literal '/' join produced mixed separators on Windows (which
            // then never matched the caller's own p.join-built expectations).
            final candidate = p.join(entry.path, g.split('/').last);
            if (FileSystemEntity.typeSync(candidate, followLinks: false) !=
                FileSystemEntityType.notFound) {
              results.add(candidate);
            }
          }
          continue;
        }
        // Skip performance-heavy subtrees.
        if (name == 'node_modules') {
          continue;
        }
        if (depth < _dangerousScanDepth) {
          _scanDir(
            entry,
            root,
            depth + 1,
            dangerousNames,
            dangerousDirNames,
            gitPaths,
            results,
          );
        }
      }
    }
  }
}

/// Convenience: resolve a [SandboxPolicySpec] into a [SandboxConfig] using a
/// shared [SandboxConfigBuilder] instance. Logs (does not throw) when the
/// exec-deny resolution finds nothing — the sandbox still applies filesystem
/// + network isolation.
Future<SandboxConfig> buildSandboxConfigFromPolicy(
  SandboxPolicySpec spec,
) async {
  try {
    return await const SandboxConfigBuilder().build(spec);
  } on Object catch (e) {
    CcInfraLog.warning(
      'SandboxConfigBuilder: exec-deny resolution failed; '
      'falling back to no exec-deny: $e',
    );
    return SandboxConfig(
      sessionId: spec.sessionId,
      network: spec.networkOn
          ? NetworkConfig(
              allowAll: false,
              allowedDomains: spec.allowedDomains,
              deniedDomains: spec.deniedDomains,
            )
          : const NetworkConfig(allowAll: false),
      filesystem: FilesystemConfig(
        denyRead: spec.denyRead,
        allowWrite: spec.allowWrite,
        denyWrite: spec.denyWrite,
      ),
      policy: spec,
    );
  }
}
