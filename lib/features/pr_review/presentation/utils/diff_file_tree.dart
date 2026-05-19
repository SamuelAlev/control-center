import 'dart:math' as math;
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:flutter/foundation.dart';

@immutable
/// Diff tree node.
class DiffTreeNode {
  /// Diff tree node.dir.
  const DiffTreeNode.dir({
    required this.name,
    required this.path,
    required this.children,
    required this.additions,
    required this.deletions,
    required this.fileCount,
  }) : fileIndex = null,
       status = '';

  /// Diff tree node.file.
  const DiffTreeNode.file({
    required this.name,
    required this.path,
    required this.additions,
    required this.deletions,
    required this.status,
    required this.fileIndex,
  }) : children = const [],
       fileCount = 1;

  /// Node name (file name or directory segment).
  final String name;

  /// Full path of this node.
  final String path;

  /// Child nodes for directories.
  final List<DiffTreeNode> children;

  /// Total added lines under this node.
  final int additions;

  /// Total deleted lines under this node.
  final int deletions;

  /// Total files under this node.
  final int fileCount;

  /// Git file status (added, modified, removed, renamed).
  final String status;

  /// int?.
  final int? fileIndex;

  /// Whether this node represents a directory.
  bool get isDirectory => fileIndex == null;
}

/// Build diff file tree.
List<DiffTreeNode> buildDiffFileTree(
  List<PrFile> files, {
  bool collapseSingleChildDirs = true,
}) {
  if (files.isEmpty) {
    return const [];
  }

  final root = _MutableDir(name: '', path: '');
  for (var i = 0; i < files.length; i++) {
    final f = files[i];
    final parts = f.filename.split('/');
    var cursor = root;
    for (var j = 0; j < parts.length - 1; j++) {
      final segment = parts[j];
      cursor = cursor.dirs.putIfAbsent(
        segment,
        () => _MutableDir(
          name: segment,
          path: cursor.path.isEmpty ? segment : '${cursor.path}/$segment',
        ),
      );
    }
    cursor.files.add(
      _MutableFile(
        name: parts.last,
        path: f.filename,
        additions: f.additions,
        deletions: f.deletions,
        status: f.status.name,
        fileIndex: i,
      ),
    );
  }

  return _freeze(
    root,
    collapseSingleChildDirs: collapseSingleChildDirs,
  ).children;
}

/// Returns file paths in the depth-first traversal order of the diff tree.
///
/// This is the order files visually appear in the tree sidebar: directories
/// sorted by the earliest file they contain, files within a directory sorted
/// by their original list index.
List<String> flattenDiffFileTreePaths(List<DiffTreeNode> roots) {
  final result = <String>[];
  void visit(DiffTreeNode node) {
    if (!node.isDirectory) {
      result.add(node.path);
      return;
    }
    for (final c in node.children) {
      visit(c);
    }
  }

  for (final root in roots) {
    visit(root);
  }
  return result;
}

/// Reorders [files] to match the visual order of the diff tree.
///
/// Calling [buildDiffFileTree] on the returned list produces a tree whose
/// `fileIndex` values equal each file's position in the list, keeping
/// jump-to-file actions and flat-list iteration in sync.
List<PrFile> sortFilesByTreeOrder(List<PrFile> files) {
  if (files.length < 2) {
    return files;
  }
  final orderedPaths = flattenDiffFileTreePaths(buildDiffFileTree(files));
  final byPath = {for (final f in files) f.filename: f};
  return [for (final p in orderedPaths) byPath[p]!];
}

DiffTreeNode _freeze(_MutableDir dir, {required bool collapseSingleChildDirs}) {
  final children = <DiffTreeNode>[];
  final dirEntries = dir.dirs.values.toList()
    ..sort((a, b) => a.minFileIndex.compareTo(b.minFileIndex));
  for (final d in dirEntries) {
    var frozen = _freeze(d, collapseSingleChildDirs: collapseSingleChildDirs);
    while (collapseSingleChildDirs &&
        frozen.isDirectory &&
        frozen.children.length == 1 &&
        frozen.children.single.isDirectory) {
      final only = frozen.children.single;
      frozen = DiffTreeNode.dir(
        name: '${frozen.name}/${only.name}',
        path: only.path,
        children: only.children,
        additions: only.additions,
        deletions: only.deletions,
        fileCount: only.fileCount,
      );
    }
    children.add(frozen);
  }
  final fileEntries = [...dir.files]
    ..sort((a, b) => a.fileIndex.compareTo(b.fileIndex));
  for (final f in fileEntries) {
    children.add(
      DiffTreeNode.file(
        name: f.name,
        path: f.path,
        additions: f.additions,
        deletions: f.deletions,
        status: f.status,
        fileIndex: f.fileIndex,
      ),
    );
  }

  var additions = 0;
  var deletions = 0;
  var fileCount = 0;
  for (final c in children) {
    additions += c.additions;
    deletions += c.deletions;
    fileCount += c.fileCount;
  }
  return DiffTreeNode.dir(
    name: dir.name,
    path: dir.path,
    children: children,
    additions: additions,
    deletions: deletions,
    fileCount: fileCount,
  );
}

class _MutableDir {
  _MutableDir({required this.name, required this.path});
  final String name;
  final String path;
  final Map<String, _MutableDir> dirs = {};
  final List<_MutableFile> files = [];

  /// Minimum file index among all descendant files.
  int get minFileIndex {
    // A sentinel larger than any real file index. Uses JS's max safe integer
    // (2^53-1) rather than the int64 max so this compiles for the web target;
    // file indices are small diff positions, so the bound is never approached.
    const noIndexSentinel = 0x1FFFFFFFFFFFFF;
    var min = files.isEmpty
        ? dirs.isEmpty
              ? noIndexSentinel
              : dirs.values.map((d) => d.minFileIndex).reduce(math.min)
        : files.map((f) => f.fileIndex).reduce(math.min);
    if (dirs.isNotEmpty) {
      final dirMin = dirs.values.map((d) => d.minFileIndex).reduce(math.min);
      if (dirMin < min) {
        min = dirMin;
      }
    }
    return min;
  }
}

class _MutableFile {
  _MutableFile({
    required this.name,
    required this.path,
    required this.additions,
    required this.deletions,
    required this.status,
    required this.fileIndex,
  });
  final String name;
  final String path;
  final int additions;
  final int deletions;
  final String status;
  final int fileIndex;
}
