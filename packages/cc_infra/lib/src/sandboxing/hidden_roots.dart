import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:path/path.dart' as p;

/// [config] with [paths] added to its [FilesystemConfig.hiddenRoots], each in
/// its written and its resolved spelling.
///
/// The kernel matches rules against the resolved path (`/tmp` and `/var` are
/// links into `/private` on macOS), so a root written only through a link
/// would never be hidden.
SandboxConfig withHiddenRoots(SandboxConfig config, List<String> paths) {
  if (paths.isEmpty) {
    return config;
  }
  final fs = config.filesystem;
  return config.copyWith(
    filesystem: fs.copyWith(
      hiddenRoots: _spellings([...fs.hiddenRoots, ...paths]),
    ),
  );
}

/// What a config's hidden roots leave reachable, for the platform emitters.
///
/// A hidden root is closed as a whole and then re-opened for exactly the
/// paths inside it the config names: the paths it may write, its read-only
/// mounts and read allowances, its run dir, runner state dirs and tool dirs.
/// Nothing is re-opened because an ancestor of it was granted: `$HOME` being
/// writable does not make a data directory under it readable, and an exec
/// grant on a space root does not make the space's other runs readable.
final class HiddenRoots {
  HiddenRoots._(this.roots, this.readable, this.writable);

  /// The plan for [config].
  factory HiddenRoots.of(SandboxConfig config) {
    final roots = [
      for (final root in config.filesystem.hiddenRoots)
        if (root.isNotEmpty) p.normalize(root),
    ];
    if (roots.isEmpty) {
      return HiddenRoots._(const [], const [], const []);
    }
    final policy = config.policy;
    bool inside(String path) =>
        roots.any((root) => root != path && p.isWithin(root, path));
    List<String> within(Iterable<String?> candidates) => [
      for (final path in _spellings([
        for (final c in candidates)
          if (c != null && c.isNotEmpty && !c.contains('*')) p.normalize(c),
      ]))
        if (inside(path)) path,
    ];
    final writable = within([
      ...config.filesystem.allowWrite,
      policy?.runDir,
      ...?policy?.runnerStateDirs,
    ]);
    final readable = within([
      ...writable,
      ...config.filesystem.allowRead,
      ...?policy?.readOnlyMounts,
      ...?policy?.toolDirs,
    ]);
    return HiddenRoots._(roots, readable, writable);
  }

  /// The hidden trees and files.
  final List<String> roots;

  /// Paths strictly inside a root that stay readable.
  final List<String> readable;

  /// Of [readable], the paths that stay writable.
  final List<String> writable;

  /// Whether [path] lies inside a hidden root (or is one).
  bool covers(String path) {
    final normal = p.normalize(path);
    return roots.any((root) => root == normal || p.isWithin(root, normal));
  }

  /// Whether [path] is hidden: inside a root and not inside anything
  /// [readable].
  bool hides(String path) {
    final normal = p.normalize(path);
    return covers(normal) &&
        !readable.any((open) => open == normal || p.isWithin(open, normal));
  }

  /// The directories between each root and each [readable] path, the root
  /// included and the path itself excluded.
  ///
  /// Their metadata stays readable, never their listings. `getcwd`, `git` and
  /// every `realpath` walk these, and fail outright when they cannot.
  List<String> get traversal {
    final out = <String>{};
    for (final open in readable) {
      for (final root in roots) {
        if (!p.isWithin(root, open)) {
          continue;
        }
        var dir = p.dirname(open);
        while (dir == root || p.isWithin(root, dir)) {
          out.add(dir);
          if (dir == root) {
            break;
          }
          dir = p.dirname(dir);
        }
      }
    }
    return out.toList()..sort();
  }

  /// The directories above [root], nearest first, `/` excluded. Renaming one
  /// would move the root to a path no rule names.
  static List<String> ancestorsOf(String root) {
    final out = <String>[];
    var dir = p.dirname(p.normalize(root));
    while (dir != p.dirname(dir)) {
      out.add(dir);
      dir = p.dirname(dir);
    }
    return out;
  }
}

/// [paths] plus the resolved spelling of each one that resolves differently,
/// in order and without duplicates.
List<String> _spellings(List<String> paths) {
  final out = <String>{};
  for (final path in paths) {
    out.add(path);
    try {
      final type = FileSystemEntity.typeSync(path);
      final String resolved;
      if (type == FileSystemEntityType.directory) {
        resolved = Directory(path).resolveSymbolicLinksSync();
      } else if (type == FileSystemEntityType.notFound) {
        // Not there yet: its parent may still be a link (`/tmp`).
        final parent = Directory(p.dirname(path));
        if (!parent.existsSync()) {
          continue;
        }
        resolved = p.join(parent.resolveSymbolicLinksSync(), p.basename(path));
      } else {
        resolved = File(path).resolveSymbolicLinksSync();
      }
      out.add(resolved);
    } on FileSystemException {
      // Unresolvable: the written spelling is all there is.
    }
  }
  return out.toList(growable: false);
}
