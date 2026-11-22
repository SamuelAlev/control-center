import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:path/path.dart' as p;

/// The host's executable directories: every entry of [path] (the server's
/// `PATH` by default) and every directory `binary_resolver` probes, each with
/// the real path after every symlink on the way, plus the symlinks themselves
/// and the trees the symlinked direct children of [scanRoots] directories
/// resolve into.
///
/// Computed once at server start (the sandbox manager does it) and handed to
/// every sandbox profile as data. Relative `PATH` entries are skipped: they
/// resolve against a working directory no rule can name. Missing directories
/// stay in the list, since a sandbox must not be able to create one the host
/// would then search.
///
/// Children are only listed for directories under [scanRoots] (`$HOME` and
/// the temp trees by default), the only trees a sandbox can write that a
/// `PATH` reaches into; a system prefix with hundreds of links (Homebrew's
/// `bin`) is never listed. An install root that would cover a whole
/// writable root, a [protectedRoots] entry or one of the directories
/// themselves (an SDK whose `bin` is on `PATH`) is dropped, and only the
/// child's target file is kept.
///
/// [extraDirs] are further directories the host runs programs from without
/// a `PATH` entry naming them (the code mode runner's directories); they are
/// treated exactly like `PATH` entries.
HostExecutableDirs scanHostExecutables({
  String? path,
  String? home,
  List<String>? scanRoots,
  List<String> protectedRoots = const [],
  List<String> extraDirs = const [],
}) {
  final env = Platform.environment;
  final homeDir = home ?? env['HOME'] ?? '';
  final sep = Platform.isWindows ? ';' : ':';
  final written = <String>{
    for (final entry in (path ?? env['PATH'] ?? '').split(sep))
      if (entry.isNotEmpty && p.isAbsolute(entry)) p.normalize(entry),
    for (final candidate in candidateBinaryPaths(_probeName))
      p.dirname(candidate),
    for (final dir in extraDirs)
      if (dir.isNotEmpty && p.isAbsolute(dir)) p.normalize(dir),
  };
  final roots = [
    for (final root in scanRoots ?? _defaultScanRoots(homeDir))
      if (root.isNotEmpty) p.normalize(root),
  ];
  bool under(String path) =>
      roots.any((root) => root == path || p.isWithin(root, path));

  final dirs = <String>{};
  final links = <String>{};
  for (final dir in written) {
    dirs.addAll(_hops(dir, links));
  }

  final installRoots = <String>{};
  final targets = <String>{};
  for (final dir in [...dirs]) {
    if (!under(dir) || !Directory(dir).existsSync()) {
      continue;
    }
    final List<FileSystemEntity> children;
    try {
      children = Directory(dir).listSync(followLinks: false);
    } on FileSystemException {
      continue;
    }
    for (final child in children.whereType<Link>()) {
      final chain = _hops(child.path, links);
      final target = chain.last;
      if (target == child.path || !under(target)) {
        continue;
      }
      if (dirs.contains(p.dirname(target))) {
        // A link to a sibling: the sibling is a direct child already.
        continue;
      }
      final root = _installRoot(target);
      final blocked = [
        homeDir,
        ...roots,
        ...protectedRoots,
        ...dirs,
      ].where((path) => path.isNotEmpty);
      if (blocked.any((path) => path == root || p.isWithin(root, path))) {
        targets.add(target);
      } else {
        installRoots.add(root);
      }
    }
  }
  return HostExecutableDirs(
    dirs: dirs.toList()..sort(),
    links: links.toList()..sort(),
    installRoots: {...installRoots, ...targets}.toList()..sort(),
  );
}

/// A name no install has; only the directories [candidateBinaryPaths] yields
/// for it are used.
const String _probeName = 'cc-host-executable-probe';

List<String> _defaultScanRoots(String home) => [
  if (home.isNotEmpty) home,
  '/tmp',
  '/private/tmp',
  '/var/folders',
  '/private/var/folders',
  Directory.systemTemp.path,
];

/// [path], and its spelling after each symlink on the way, ending with the
/// real path (as far as it exists). Every symlink met is added to [links].
List<String> _hops(String path, Set<String> links) {
  final spellings = <String>[p.normalize(path)];
  var current = spellings.first;
  for (var depth = 0; depth < 40; depth++) {
    final next = _firstHop(current, links);
    if (next == null || spellings.contains(next)) {
      break;
    }
    spellings.add(next);
    current = next;
  }
  return spellings;
}

/// [path] with its first symlinked component replaced by that link's target,
/// or null when no component of [path] is a symlink. The link is added to
/// [links].
String? _firstHop(String path, Set<String> links) {
  final parts = p.split(path);
  var prefix = parts.first;
  for (var i = 1; i < parts.length; i++) {
    prefix = p.join(prefix, parts[i]);
    final FileSystemEntityType type;
    try {
      type = FileSystemEntity.typeSync(prefix, followLinks: false);
    } on FileSystemException {
      return null;
    }
    if (type == FileSystemEntityType.notFound) {
      return null;
    }
    if (type != FileSystemEntityType.link) {
      continue;
    }
    final String target;
    try {
      target = Link(prefix).targetSync();
    } on FileSystemException {
      return null;
    }
    links.add(prefix);
    final resolved = p.isAbsolute(target)
        ? target
        : p.join(p.dirname(prefix), target);
    return p.normalize(p.joinAll([resolved, ...parts.skip(i + 1)]));
  }
  return null;
}

/// The tree a link's [target] belongs to: the npm package that holds it
/// (`…/node_modules/<pkg>` or `…/node_modules/@scope/<pkg>`), else the
/// target's directory, or that directory's parent when it is a `bin`.
String _installRoot(String target) {
  final parts = p.split(target);
  final modules = parts.lastIndexOf('node_modules');
  if (modules >= 0 && modules + 1 < parts.length - 1) {
    final scoped = parts[modules + 1].startsWith('@');
    final end = modules + (scoped ? 3 : 2);
    if (end <= parts.length - 1) {
      return p.joinAll(parts.take(end));
    }
  }
  final dir = p.dirname(target);
  return p.basename(dir) == 'bin' ? p.dirname(dir) : dir;
}

/// The part of [all] a sandbox with [writableRoots] could change: each path
/// that is a writable root or lies inside one.
HostExecutableDirs hostExecutablesUnder(
  HostExecutableDirs all,
  Iterable<String> writableRoots,
) {
  final roots = [
    for (final root in writableRoots)
      if (root.isNotEmpty && !root.contains('*')) p.normalize(root),
  ];
  List<String> keep(List<String> paths) => [
    for (final path in paths)
      if (roots.any((root) => root == path || p.isWithin(root, path))) path,
  ];
  return HostExecutableDirs(
    dirs: keep(all.dirs),
    links: keep(all.links),
    installRoots: keep(all.installRoots),
  );
}

/// The directories strictly between the outermost of [writableRoots] holding
/// [path] and [path] itself, outermost first. Renaming any of them would move
/// [path] to a place no rule names.
List<String> ancestorsBelowWritableRoot(
  String path,
  Iterable<String> writableRoots,
) {
  final normal = p.normalize(path);
  String? outer;
  for (final root in writableRoots) {
    if (root.isEmpty || root.contains('*')) {
      continue;
    }
    final r = p.normalize(root);
    if (p.isWithin(r, normal) && (outer == null || p.isWithin(r, outer))) {
      outer = r;
    }
  }
  if (outer == null) {
    return const [];
  }
  final out = <String>[];
  var dir = p.dirname(normal);
  while (p.isWithin(outer, dir)) {
    out.add(dir);
    dir = p.dirname(dir);
  }
  return out.reversed.toList();
}
