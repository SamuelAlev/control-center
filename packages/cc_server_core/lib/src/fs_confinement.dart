/// The one check that a host path a caller named stays inside a directory.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// [path]'s real location when it is [root] or inside it once every symlink
/// on either side is resolved; null when it escapes.
///
/// A lexical `isWithin` is not enough: a symlink committed to a repository or
/// made by an agent in its worktree (`link -> /`) keeps the joined path
/// inside the root while the file it opens is anywhere on the host. A path
/// that does not exist yet resolves through its deepest existing ancestor, so
/// a write cannot be steered out through a linked parent directory either;
/// a dangling link is refused, since writing through it would create its
/// target wherever it points.
String? confinedRealPath(String root, String path) {
  final realRoot = _realPath(p.normalize(p.absolute(root)));
  final real = _realPath(p.normalize(p.absolute(path)));
  if (realRoot == null || real == null) {
    return null;
  }
  return p.equals(realRoot, real) || p.isWithin(realRoot, real) ? real : null;
}

String? _realPath(String absolute) {
  var existing = absolute;
  final missing = <String>[];
  while (FileSystemEntity.typeSync(existing, followLinks: false) ==
      FileSystemEntityType.notFound) {
    final parent = p.dirname(existing);
    if (parent == existing) {
      return null;
    }
    missing.insert(0, p.basename(existing));
    existing = parent;
  }
  try {
    return p.joinAll([File(existing).resolveSymbolicLinksSync(), ...missing]);
  } on FileSystemException {
    return null; // A dangling link.
  }
}
