import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:path/path.dart' as p;

/// Fuzzy-searches the WHOLE agent workspace — [workspaceRoot] plus every entry
/// in [sharedRoots] — and returns hits whose paths stay addressable from
/// [workspaceRoot].
///
/// Searching [workspaceRoot] alone is not enough. On a per-agent overlay cwd the
/// conversation's repo worktrees live in a shared root (`<convRoot>/repos`)
/// outside it, reached only through the provisioner's `repos → ../../repos`
/// symlink — and the production engine (cc_natives' Rust `fff`) does NOT descend
/// symlinks, so an overlay-only search silently returns nothing for every repo
/// file. Each root is therefore searched directly, in its real form.
///
/// A hit from a shared root is re-labelled with the symlink that reaches it
/// (`repos/<…>`) when [workspaceRoot] has one, so the agent can pass the result
/// straight back to `read`/`edit`; without a link it falls back to the absolute
/// path, which those tools also accept (any path inside a shared root is in the
/// workspace). Results are merged by descending score, ties broken by the order
/// the engine returned them, and de-duplicated by display path.
Future<List<FileSearchMatch>> searchWorkspaceFiles(
  FileSearchPort fileSearch,
  String query, {
  required String workspaceRoot,
  List<String> sharedRoots = const [],
  int limit = 25,
}) async {
  final root = p.normalize(p.absolute(workspaceRoot));
  final roots = <String>[root];
  for (final shared in sharedRoots) {
    final normalized = p.normalize(p.absolute(shared));
    if (!roots.any((r) => p.equals(r, normalized))) {
      roots.add(normalized);
    }
  }

  final ranked = <({double score, int order, FileSearchMatch match})>[];
  final seen = <String>{};
  var order = 0;
  for (final searchRoot in roots) {
    final hits = await fileSearch.search(query, root: searchRoot, limit: limit);
    final prefix = p.equals(searchRoot, root)
        ? null
        : _linkPrefixFor(searchRoot, root);
    for (final hit in hits) {
      final display = p.equals(searchRoot, root)
          ? hit.path
          : p.join(prefix ?? searchRoot, hit.path);
      if (!seen.add(display)) {
        continue;
      }
      ranked.add((
        score: hit.score,
        order: order++,
        match: FileSearchMatch(
          path: display,
          isDirectory: hit.isDirectory,
          score: hit.score,
        ),
      ));
    }
  }
  // Descending score; the engine's own ordering breaks ties (List.sort is not
  // guaranteed stable, so the tiebreaker is explicit).
  ranked.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.order.compareTo(b.order);
  });
  return [for (final entry in ranked.take(limit)) entry.match];
}

/// The name of a direct-child symlink of [workspaceRoot] that resolves to
/// [sharedRoot] (the overlay's `repos`), or null when none does. Mirrors
/// `listWorkspaceTree`'s expansion so `search_files` labels hits the same way
/// `search`/`find` do.
String? _linkPrefixFor(String sharedRoot, String workspaceRoot) {
  final String realShared;
  try {
    realShared = Directory(sharedRoot).resolveSymbolicLinksSync();
  } on FileSystemException {
    return null;
  }
  final List<FileSystemEntity> children;
  try {
    children = Directory(workspaceRoot).listSync(followLinks: false);
  } on FileSystemException {
    return null;
  }
  for (final child in children) {
    if (child is! Link) {
      continue;
    }
    try {
      if (p.equals(
        Directory(child.path).resolveSymbolicLinksSync(),
        realShared,
      )) {
        return p.basename(child.path);
      }
    } on FileSystemException {
      // Broken link — keep looking.
    }
  }
  return null;
}
