import 'dart:async';
import 'dart:io';

import 'package:cc_natives/src/file_search/file_search.dart';
import 'package:path/path.dart' as p;

/// Pure-Dart [FileSearch]. Walks roots with [Directory.list] (recursive),
/// caches the flat list per root, then filters in-memory on each query.
///
/// Sized for "open a typical project tree": skips common bloat dirs and bails
/// after [_softCap] entries per root.
class DartFileSearch implements FileSearch {
  /// Creates a new [Dart file search].
  DartFileSearch();

  static const int _softCap = 50000;
  static const Set<String> _skipDirs = {
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
  };

  final Map<String, List<_Entry>> _cache = {};
  final Map<String, Future<void>> _inflight = {};

  @override
  Future<void> warmUp(List<String> roots) async {
    await Future.wait([for (final r in roots) _ensureLoaded(r)]);
  }

  @override
  void invalidate(List<String> roots) {
    for (final r in roots) {
      _cache.remove(r);
      _inflight.remove(r);
    }
  }

  Future<void> _ensureLoaded(String root) {
    if (_cache.containsKey(root)) {
      return Future.value();
    }
    final existing = _inflight[root];
    if (existing != null) {
      return existing;
    }
    final future = _load(root);
    _inflight[root] = future;
    return future.whenComplete(() => _inflight.remove(root));
  }

  Future<void> _load(String root) async {
    final dir = Directory(root);
    if (!dir.existsSync()) {
      _cache[root] = const [];
      return;
    }
    final out = <_Entry>[];
    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        await _walk(entity, root, out);
        if (out.length >= _softCap) {
          break;
        }
      }
    } on FileSystemException {
      // permission denied / vanished — leave whatever we collected.
    }
    _cache[root] = out;
  }

  Future<void> _walk(
    FileSystemEntity entity,
    String root,
    List<_Entry> out,
  ) async {
    final name = p.basename(entity.path);
    if (name.startsWith('.') &&
        name != '.env.template' &&
        name != '.gitignore') {
      return;
    }
    if (entity is Directory) {
      if (_skipDirs.contains(name)) {
        return;
      }
      out.add(_Entry(
        absolutePath: entity.path,
        relativePath: p.relative(entity.path, from: root),
        isDirectory: true,
      ));
      try {
        await for (final child
            in entity.list(recursive: false, followLinks: false)) {
          await _walk(child, root, out);
          if (out.length >= _softCap) {
            return;
          }
        }
      } on FileSystemException {
        // ignore unreadable dirs.
      }
    } else if (entity is File) {
      out.add(_Entry(
        absolutePath: entity.path,
        relativePath: p.relative(entity.path, from: root),
        isDirectory: false,
      ));
    }
  }

  @override
  Stream<List<FileSearchHit>> search({
    required List<String> roots,
    required String query,
    int limit = 25,
  }) {
    final controller = StreamController<List<FileSearchHit>>();
    () async {
      final hits = <FileSearchHit>[];
      final q = query.toLowerCase();
      for (final root in roots) {
        await _ensureLoaded(root);
        final entries = _cache[root] ?? const [];
        for (final e in entries) {
          final score = _score(e.relativePath, q);
          if (score == null) {
            continue;
          }
          hits.add(FileSearchHit(
            absolutePath: e.absolutePath,
            relativePath: e.relativePath,
            rootPath: root,
            isDirectory: e.isDirectory,
            score: score,
          ));
        }
      }
      hits.sort((a, b) => b.score.compareTo(a.score));
      controller.add(hits.take(limit).toList(growable: false));
      await controller.close();
    }();
    return controller.stream;
  }

  /// Returns null when no match, otherwise a relevance score (higher = better).
  ///
  /// Strategy:
  /// - empty query → return all entries with score 0 (caller sorts by path)
  /// - basename startsWith → highest
  /// - basename contains → high
  /// - relative path contains → medium
  /// - subsequence match against basename (fuzzy) → low
  static double? _score(String relPath, String q) {
    if (q.isEmpty) {
      return 0;
    }
    final relLower = relPath.toLowerCase();
    final base = p.basename(relPath).toLowerCase();
    if (base.startsWith(q)) {
      return 100 - base.length / 100.0;
    }
    if (base.contains(q)) {
      return 80 - base.indexOf(q).toDouble();
    }
    if (relLower.contains(q)) {
      return 50 - relLower.indexOf(q) / 5.0;
    }
    if (_isSubsequence(q, base)) {
      return 20;
    }
    return null;
  }

  static bool _isSubsequence(String needle, String haystack) {
    var i = 0;
    for (var j = 0; j < haystack.length && i < needle.length; j++) {
      if (haystack[j] == needle[i]) {
        i++;
      }
    }
    return i == needle.length;
  }
}

class _Entry {
  _Entry({
    required this.absolutePath,
    required this.relativePath,
    required this.isDirectory,
  });

  final String absolutePath;
  final String relativePath;
  final bool isDirectory;
}

