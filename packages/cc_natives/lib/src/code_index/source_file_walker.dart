import 'dart:io';

import 'package:cc_natives/src/code_index/code_languages.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A source file discovered by [SourceFileWalker].
class SourceFile {
  /// Creates a [SourceFile].
  const SourceFile({required this.absolutePath, required this.relativePath});

  /// Absolute path on disk.
  final String absolutePath;

  /// Path relative to the repo root (stored as `code_symbols.filePath`).
  final String relativePath;
}

/// Enumerates indexable source files under a repo root.
///
/// When the root is a git work tree (the normal case — indexing targets a
/// checked-out repo) enumeration defers to git itself via
/// `git ls-files --cached --others --exclude-standard`, so `.gitignore`,
/// nested `.gitignore` files, `.git/info/exclude`, and the global excludes
/// file are all honoured. This is what keeps `node_modules/`, build output,
/// and other ignored trees out of the graph — reusing git's own ignore engine
/// rather than a hardcoded skip list that can never match a project's actual
/// `.gitignore`.
///
/// For non-git directories (e.g. tests, or a path that isn't a work tree) it
/// falls back to a manual walk with a hardcoded skip set and a soft cap.
///
/// Regardless of how files are discovered, results are filtered by extension
/// and exclude generated Dart: generated files are typically committed (so git
/// alone wouldn't drop them) yet churn on every codegen run, which would
/// pollute the graph.
class SourceFileWalker {
  /// Creates a [SourceFileWalker].
  const SourceFileWalker({Set<String>? extensions, this.maxEntries = 50000})
    : _extensionsOverride = extensions;

  /// Optional override of indexable extensions (without dot). When null, every
  /// extension known to [kLanguageByExtension] is indexed.
  final Set<String>? _extensionsOverride;

  /// Soft cap on visited entries / emitted files (matches `DartFileSearch`).
  final int maxEntries;

  static const _skipDirs = {
    '.git',
    '.dart_tool',
    'node_modules',
    'build',
    '.build',
    'target',
    '.next',
    '.idea',
    '.vscode',
    '.cache',
    '.gradle',
    'Pods',
    '.venv',
    'venv',
    '__pycache__',
    '.fvm',
    'vendor',
    'dist',
    'coverage',
  };

  static const _skipSuffixes = {
    '.g.dart',
    '.freezed.dart',
    '.config.dart',
    '.gr.dart',
    '.mocks.dart',
    '.min.js',
  };

  /// Enumerates indexable files under [rootPath]. Tolerates permission errors
  /// and vanished directories (skips and continues with partial results).
  Future<List<SourceFile>> walk(String rootPath) async {
    final root = Directory(rootPath);
    if (!root.existsSync()) {
      return const [];
    }
    final tracked = await _gitListedPaths(rootPath);
    if (tracked != null) {
      return _fromRelativePaths(rootPath, tracked);
    }
    return _manualWalk(rootPath);
  }

  /// Asks git for the paths it would surface in [rootPath]: tracked files plus
  /// untracked-but-not-ignored files (`--cached --others --exclude-standard`),
  /// NUL-separated so paths with spaces/newlines survive. Returns repo-relative
  /// POSIX paths, or `null` when [rootPath] is not a git work tree or git is
  /// unavailable, signalling the caller to fall back to a manual walk.
  Future<List<String>?> _gitListedPaths(String rootPath) async {
    ProcessResult result;
    try {
      result = await Process.run(
        'git',
        const [
          'ls-files',
          '--cached',
          '--others',
          '--exclude-standard',
          '-z',
        ],
        workingDirectory: rootPath,
      );
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) {
      return null;
    }
    final stdout = result.stdout as String;
    return stdout.split('\u0000').where((path) => path.isNotEmpty).toList();
  }

  /// Maps git's repo-relative POSIX paths to [SourceFile]s, applying the
  /// extension + generated-file filters. Skips entries that no longer exist on
  /// disk (deleted-but-tracked files) or aren't regular files (submodule
  /// gitlinks), preserving the invariant that every returned file is readable.
  List<SourceFile> _fromRelativePaths(String rootPath, List<String> relPaths) {
    final out = <SourceFile>[];
    final seen = <String>{};
    for (final rel in relPaths) {
      if (out.length >= maxEntries) {
        break;
      }
      // git emits POSIX separators; rebuild a platform-native relative path so
      // stored `filePath`s stay consistent with the manual-walk fallback.
      final relativePath = p.joinAll(rel.split('/'));
      if (!seen.add(relativePath)) {
        continue;
      }
      if (!_isIndexable(p.basename(relativePath))) {
        continue;
      }
      final absolutePath = p.normalize(p.join(rootPath, relativePath));
      if (!File(absolutePath).existsSync()) {
        continue;
      }
      out.add(
        SourceFile(absolutePath: absolutePath, relativePath: relativePath),
      );
    }
    return out;
  }

  /// Manual recursive walk for non-git directories: uses the hardcoded skip
  /// set and entry cap. (Git work trees never reach this — git's ignore engine
  /// handles them.)
  List<SourceFile> _manualWalk(String rootPath) {
    final out = <SourceFile>[];
    var visited = 0;
    final stack = <Directory>[Directory(rootPath)];

    while (stack.isNotEmpty) {
      if (visited >= maxEntries) {
        break;
      }
      final dir = stack.removeLast();
      List<FileSystemEntity> entries;
      try {
        entries = dir.listSync(followLinks: false);
      } on FileSystemException {
        continue;
      }
      for (final entity in entries) {
        if (visited >= maxEntries) {
          break;
        }
        visited++;
        final name = p.basename(entity.path);
        if (entity is Directory) {
          if (_skipDirs.contains(name) || name.startsWith('.')) {
            continue;
          }
          stack.add(entity);
        } else if (entity is File) {
          if (!_isIndexable(name)) {
            continue;
          }
          out.add(
            SourceFile(
              absolutePath: entity.path,
              relativePath: p.relative(entity.path, from: rootPath),
            ),
          );
        }
      }
    }
    return out;
  }

  bool _isIndexable(String fileName) {
    final ext = p.extension(fileName);
    if (ext.isEmpty) {
      return false;
    }
    final bare = ext.substring(1).toLowerCase();
    final allowed =
        _extensionsOverride?.contains(bare) ??
        kLanguageByExtension.containsKey(bare);
    if (!allowed) {
      return false;
    }
    for (final suffix in _skipSuffixes) {
      if (fileName.endsWith(suffix)) {
        return false;
      }
    }
    return true;
  }

  /// SHA-256 of a file's bytes, used to skip unchanged files on re-index.
  Future<String> hashFile(String absolutePath) async {
    final bytes = await File(absolutePath).readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
