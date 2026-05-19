import 'dart:io';

import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:path/path.dart' as p;

/// A [DirectoryBrowserPort] over `dart:io`, constrained to a set of allow-listed
/// roots on the SERVER's filesystem.
///
/// Every requested path is normalised and checked against the configured roots
/// before anything is read: a path that is not at, or within, one of the roots
/// is refused (so a client can never `..`-escape above an allowed root). Hidden
/// dot-folders are omitted from listings to keep the picker focused on project
/// directories.
class FilesystemDirectoryBrowser implements DirectoryBrowserPort {
  /// Creates a browser scoped to [allowedRoots].
  ///
  /// Each root is normalised to an absolute path; non-absolute or empty entries
  /// are dropped. With no usable roots the browser refuses every request.
  FilesystemDirectoryBrowser({required List<String> allowedRoots})
      : _roots = _normaliseRoots(allowedRoots);

  /// Browser rooted at the current OS user's home directory, falling back to the
  /// process working directory when no home is resolvable. The default for hosts
  /// that do not configure explicit roots.
  factory FilesystemDirectoryBrowser.forHome() =>
      FilesystemDirectoryBrowser(allowedRoots: [_homeDir()]);

  final List<String> _roots;

  @override
  Future<DirectoryListing> browse({String? path}) async {
    if (_roots.isEmpty) {
      throw const DirectoryAccessException(
        'No browsable directories are configured on the server.',
      );
    }

    final target = path == null
        ? _roots.first
        : p.normalize(p.absolute(path.trim()));

    if (!_isWithinRoots(target)) {
      throw const DirectoryAccessException(
        'That folder is outside the directories the server allows.',
      );
    }

    final dir = Directory(target);
    if (!dir.existsSync()) {
      throw const DirectoryAccessException(
        'Folder not found or not accessible on the server.',
      );
    }

    final List<FileSystemEntity> children;
    try {
      children = dir.listSync(followLinks: false);
    } on FileSystemException {
      throw const DirectoryAccessException(
        'Folder not found or not accessible on the server.',
      );
    }

    final entries = <DirectoryEntry>[];
    for (final child in children) {
      if (child is! Directory) {
        continue;
      }
      final name = p.basename(child.path);
      if (name.startsWith('.')) {
        continue;
      }
      entries.add(
        DirectoryEntry(
          name: name,
          path: child.path,
          isGitRepo: _hasGit(child.path),
        ),
      );
    }
    entries.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final isRoot = _roots.any((r) => p.equals(r, target));
    return DirectoryListing(
      path: target,
      parent: isRoot ? null : p.dirname(target),
      isGitRepo: _hasGit(target),
      roots: List.unmodifiable(_roots),
      entries: entries,
    );
  }

  bool _isWithinRoots(String target) =>
      _roots.any((r) => p.equals(r, target) || p.isWithin(r, target));

  /// A directory is a git work tree when it holds a `.git` directory (a normal
  /// checkout) or a `.git` file (a linked worktree / submodule).
  static bool _hasGit(String dir) {
    try {
      final marker = p.join(dir, '.git');
      return Directory(marker).existsSync() || File(marker).existsSync();
    } on FileSystemException {
      return false;
    }
  }

  static List<String> _normaliseRoots(List<String> roots) {
    final out = <String>[];
    for (final raw in roots) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final normalised = p.normalize(p.absolute(trimmed));
      if (!out.contains(normalised)) {
        out.add(normalised);
      }
    }
    return out;
  }

  static String _homeDir() {
    final env = Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'];
    if (home != null && home.trim().isNotEmpty) {
      return p.normalize(p.absolute(home.trim()));
    }
    return Directory.current.path;
  }
}
