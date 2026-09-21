import 'dart:io';

import 'package:path/path.dart' as p;

/// Enumerates Dart SOURCE files for scanning ratchets via `git ls-files`
/// (not recursive `listSync` — `apps/cc_server/data/` alone is ~1.9M files).
/// Honours `.gitignore`; includes untracked-but-not-ignored. Falls back to a
/// pruning walk when git is unavailable.
List<File> dartSourceFiles({
  List<String> roots = const ['lib', 'packages', 'apps'],
  bool includeTests = false,
}) {
  final existing = roots.where((r) => Directory(r).existsSync()).toList();
  if (existing.isEmpty) {
    return const [];
  }
  final paths = _gitListed(existing) ?? _prunedWalk(existing);
  return [
    for (final path in paths)
      if (path.endsWith('.dart') &&
          (includeTests || !_isTestPath(path)) &&
          File(path).existsSync())
        File(path),
  ];
}

/// Whether [path] lives in a package's or the app's test tree. The ratchets
/// police PRODUCTION code; test/tooling files legitimately do things
/// production must not (call `HardwareKeyboard.clearState()`, import
/// `package:cc_infra`, hardcode strings).
bool _isTestPath(String path) {
  final posix = path.replaceAll(r'\', '/');
  return posix.startsWith('test/') || posix.contains('/test/');
}

/// Paths git would surface under [roots], or null when git can't answer.
List<String>? _gitListed(List<String> roots) {
  ProcessResult result;
  try {
    result = Process.runSync('git', [
      'ls-files',
      '--cached',
      '--others',
      '--exclude-standard',
      '-z',
      '--',
      ...roots,
    ]);
  } on ProcessException {
    return null;
  }
  if (result.exitCode != 0) {
    return null;
  }
  return (result.stdout as String)
      .split('\u0000')
      .where((path) => path.isNotEmpty)
      .toList();
}

/// Directory names never worth descending into: generated output, vendored
/// dependency trees, Flutter's plugin scaffolding and the server's runtime
/// data dir. Dot-directories are pruned separately (see [_prunedWalk]).
const _prunedDirs = {
  'build',
  'target',
  'node_modules',
  'Pods',
  'ephemeral',
  'coverage',
  // apps/cc_server/data — provisioned worktrees + a vendored code-server.
  'data',
};

/// Manual walk that PRUNES before descending — the fallback when git is
/// unavailable. Pruning (rather than filtering results) is the whole point;
/// see the library doc.
///
/// Two hazards this must not reintroduce, both learned the hard way by
/// `architecture_constraints_test.dart`'s own walker:
///  * `listSync(recursive: true)` FOLLOWS symlinks and this tree contains
///    cyclic/huge link farms (agent skill symlinks, worktrees under
///    `apps/cc_server/data/`, plugin `.symlinks`) that made a scan consume
///    tens of GB of RAM. `followLinks: false` returns links as [Link]
///    entities, which fall through both branches below and are skipped, so a
///    cycle can never recurse;
///  * dot-directories (`.git`, `.dart_tool`, `.fvm`, `.symlinks`, …) are never
///    first-party source and are pruned wholesale rather than enumerated.
List<String> _prunedWalk(List<String> roots) {
  final out = <String>[];
  final stack = <Directory>[for (final root in roots) Directory(root)];
  while (stack.isNotEmpty) {
    final dir = stack.removeLast();
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      continue;
    }
    for (final entity in entries) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        if (!name.startsWith('.') && !_prunedDirs.contains(name)) {
          stack.add(entity);
        }
      } else if (entity is File) {
        out.add(entity.path);
      }
    }
  }
  return out;
}
