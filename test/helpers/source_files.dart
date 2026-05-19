import 'dart:io';

import 'package:path/path.dart' as p;

/// Enumerates the repo's Dart SOURCE files for the source-scanning ratchets
/// (architecture constraints, lib boundary, keyboard hygiene, l10n, …).
///
/// Use this instead of `Directory(root).listSync(recursive: true)`. That call
/// enumerates the whole subtree BEFORE any filtering, so a skip list applied
/// to the results does not prevent the walk — and `apps/cc_server/data/` is a
/// runtime data dir holding provisioned worktree clones plus a vendored
/// code-server install. Measured on a real dev tree: ~1.9 MILLION files under
/// `apps/`, which took one such test 9m34s of a ~19m suite. Nothing under
/// there is repo source.
///
/// Enumeration therefore comes from git — `git ls-files --cached --others
/// --exclude-standard` — the same mechanism `SourceFileWalker` uses in
/// production:
///
///  * it is one process (~20ms for ~3.5k files, versus minutes of `stat`),
///  * `--exclude-standard` honours `.gitignore`, so every generated/vendored/
///    runtime tree (`data/`, `build/`, `.dart_tool/`, cargo `target/`) is
///    excluded automatically — a NEW artifact dir needs no new skip entry,
///  * `--others` keeps untracked-but-not-ignored files in scope, so a file a
///    developer has not staged yet is still policed locally, exactly as CI
///    would police it once committed.
///
/// Falls back to a pruning manual walk when git is unavailable (a tarball
/// export, a sandbox without the binary) so the ratchets still run.
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
/// dependency trees, Flutter's plugin scaffolding, and the server's runtime
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
///  * `listSync(recursive: true)` FOLLOWS symlinks, and this tree contains
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
