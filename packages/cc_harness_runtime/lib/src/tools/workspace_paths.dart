import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves [relative] against [workspaceRoot] and returns the absolute path
/// only when it stays inside the workspace; otherwise null.
///
/// The workspace is the union of [workspaceRoot] and [sharedRoots] — extra
/// directories that are part of the agent's workspace but live outside its
/// cwd on disk (the per-conversation shared `repos/` worktrees dir, which the
/// overlay cwd only reaches through a `repos → ../../repos` symlink). Callers
/// may hand in either the symlinked or the real form of such a path.
///
/// Absolute inputs are accepted only when already inside one of the roots, so
/// the filesystem tools (read/write/edit/search/find) cannot reach
/// `/etc/passwd`, `~/.ssh`, or any path outside the agent's workspace. When
/// the target itself is a symlink, its real destination is checked too, so a
/// symlink inside the workspace cannot be used to escape it.
String? resolveInsideWorkspace(
  String workspaceRoot,
  String relative, {
  List<String> sharedRoots = const [],
}) {
  final root = p.normalize(p.absolute(workspaceRoot));
  final roots = <String>[
    root,
    for (final shared in sharedRoots) p.normalize(p.absolute(shared)),
  ];
  final resolved = p.isAbsolute(relative)
      ? p.normalize(relative)
      : p.normalize(p.join(root, relative));
  final inside = roots.any(
    (r) => p.equals(resolved, r) || p.isWithin(r, resolved),
  );
  if (!inside) {
    return null;
  }
  // Symlink hardening: if the target already exists as a symlink, verify its
  // real destination is still inside one of the (real) workspace roots.
  try {
    if (FileSystemEntity.typeSync(resolved, followLinks: false) ==
        FileSystemEntityType.link) {
      final realTarget = File(resolved).resolveSymbolicLinksSync();
      final insideReal = roots.any((r) {
        final realRoot = Directory(r).existsSync()
            ? Directory(r).resolveSymbolicLinksSync()
            : r;
        return p.equals(realTarget, realRoot) ||
            p.isWithin(realRoot, realTarget);
      });
      if (!insideReal) {
        return null;
      }
    }
  } on FileSystemException {
    // Can't verify the link target — refuse rather than risk an escape.
    return null;
  }
  return resolved;
}

/// Human-readable list of the workspace roots for refusal messages, so the
/// agent learns where it IS allowed to look instead of retrying blind.
String describeWorkspaceRoots(
  String workspaceRoot, {
  List<String> sharedRoots = const [],
}) {
  final roots = <String>[
    p.normalize(p.absolute(workspaceRoot)),
    for (final shared in sharedRoots) p.normalize(p.absolute(shared)),
  ];
  return roots.join(', ');
}

/// Builds the refusal message for a path outside the workspace, naming the
/// accessible roots and steering the agent to `repos/` when worktrees exist —
/// without this, agents retry the original checkout path blind.
String outsideWorkspaceMessage(
  String action,
  String path, {
  required String workspaceRoot,
  List<String> sharedRoots = const [],
}) {
  final roots = describeWorkspaceRoots(workspaceRoot, sharedRoots: sharedRoots);
  final buffer = StringBuffer(
    'Refusing to $action outside the workspace: $path. '
    'Accessible roots: $roots.',
  );
  if (sharedRoots.isNotEmpty) {
    buffer.write(
      ' Repository working copies are available under `repos/` in your '
      'working directory; never operate on an original checkout.',
    );
  }
  return buffer.toString();
}

/// Recursively lists [base] without following symlinks, then additionally
/// walks direct-child symlinks of [base] that resolve inside the workspace
/// (the provisioner's `repos → ../../repos` overlay link), keeping the
/// symlinked prefix so results stay addressable from the cwd.
///
/// Without the expansion, a workspace-wide `find`/`search` from the cwd
/// silently misses every repo worktree (symlinks are never followed), which
/// pushes agents toward absolute original-checkout paths.
List<FileSystemEntity> listWorkspaceTree(
  String base, {
  required String workspaceRoot,
  List<String> sharedRoots = const [],
}) {
  final entities = Directory(
    base,
  ).listSync(recursive: true, followLinks: false);
  final result = [...entities];
  final normalizedBase = p.normalize(p.absolute(base));
  for (final entity in entities) {
    if (entity is! Link || !p.equals(p.dirname(entity.path), normalizedBase)) {
      continue;
    }
    final allowed = resolveInsideWorkspace(
      workspaceRoot,
      entity.path,
      sharedRoots: sharedRoots,
    );
    if (allowed == null ||
        FileSystemEntity.typeSync(entity.path) !=
            FileSystemEntityType.directory) {
      continue;
    }
    try {
      result.addAll(
        Directory(entity.path).listSync(recursive: true, followLinks: false),
      );
    } on FileSystemException {
      // Best-effort: an unreadable link target is skipped, not fatal.
    }
  }
  return result;
}
