import 'dart:io';

import 'package:control_center/core/infrastructure/code_index/code_languages.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A source file discovered by [SourceFileWalker].
class SourceFile {
  const SourceFile({required this.absolutePath, required this.relativePath});

  /// Absolute path on disk.
  final String absolutePath;

  /// Path relative to the repo root (stored as `code_symbols.filePath`).
  final String relativePath;
}

/// Recursively enumerates indexable source files under a repo root.
///
/// Reuses `DartFileSearch`'s skip-dir set and 50k soft cap, specialised for
/// code indexing: filters by extension and excludes generated Dart so the
/// graph isn't polluted by machine output that churns on every codegen run.
class SourceFileWalker {
  const SourceFileWalker({Set<String>? extensions, this.maxEntries = 50000})
    : _extensionsOverride = extensions;

  /// Optional override of indexable extensions (without dot). When null, every
  /// extension known to [kLanguageByExtension] is indexed.
  final Set<String>? _extensionsOverride;

  /// Soft cap on visited entries (matches `DartFileSearch`).
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

  /// Walks [rootPath], returning indexable files. Tolerates permission errors
  /// and vanished directories (skips and continues with partial results).
  List<SourceFile> walk(String rootPath) {
    final root = Directory(rootPath);
    if (!root.existsSync()) {
      return const [];
    }
    final out = <SourceFile>[];
    var visited = 0;
    final stack = <Directory>[root];

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
