import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

/// A seed path that would read or write outside its root.
class WorktreeSeedException implements Exception {
  /// Creates a [WorktreeSeedException].
  const WorktreeSeedException(this.message);

  /// Client-safe explanation.
  final String message;

  @override
  String toString() => message;
}

/// What [WorktreeSeedFiles.copy] did, by repo-relative path.
class WorktreeSeedResult {
  /// Creates a [WorktreeSeedResult].
  const WorktreeSeedResult({
    this.copied = const [],
    this.missing = const [],
    this.kept = const [],
    this.skippedForFork = false,
  });

  /// Copied into the worktree.
  final List<String> copied;

  /// Absent from the source checkout. Compose preflight names these again if
  /// anything actually mounts them.
  final List<String> missing;

  /// Already in the worktree, and left alone.
  final List<String> kept;

  /// Whether nothing was copied because the worktree holds a fork PR.
  final bool skippedForFork;
}

/// Copies one file. A seam for tests.
typedef WorktreeFileCopier =
    Future<void> Function(String source, String destination);

/// Copies `seedFiles` from the registered source checkout into a worktree.
///
/// These are usually secrets, so fork PRs never get them, and every path is
/// proven to stay inside its root with links resolved. A path can be inside by
/// string and outside by content, and it is the content that gets copied.
class WorktreeSeedFiles {
  /// Creates a [WorktreeSeedFiles].
  const WorktreeSeedFiles({this._copier = copyWorktreeFile});

  final WorktreeFileCopier _copier;

  /// Copies [seedFiles] from [sourceRoot] to [worktreeRoot].
  ///
  /// Throws [WorktreeSeedException] on a path that escapes, before anything is
  /// copied. A file already in the worktree is kept: a CoW worktree brought it
  /// along, and it may have been edited since.
  Future<WorktreeSeedResult> copy({
    required String sourceRoot,
    required String worktreeRoot,
    required List<String> seedFiles,
    bool isForkPr = false,
  }) async {
    if (isForkPr) {
      return const WorktreeSeedResult(skippedForFork: true);
    }
    final source = Directory(sourceRoot).resolveSymbolicLinksSync();
    final target = Directory(worktreeRoot).resolveSymbolicLinksSync();

    final files = <String>[];
    final missing = <String>[];
    for (final seed in seedFiles) {
      if (!isSafeRelativePath(seed)) {
        throw WorktreeSeedException(
          'Seed file $seed must be a relative path inside the repo',
        );
      }
      final path = p.join(source, seed);
      switch (FileSystemEntity.typeSync(path)) {
        case FileSystemEntityType.notFound:
          missing.add(seed);
        case FileSystemEntityType.directory:
          files.addAll(_filesUnder(source, seed));
        default:
          _assertInside(source, path, seed);
          files.add(seed);
      }
    }
    for (final file in files) {
      _assertDestinationInside(target, file);
    }

    final copied = <String>[];
    final kept = <String>[];
    for (final file in files) {
      final destination = p.join(target, file);
      if (FileSystemEntity.typeSync(destination, followLinks: false) !=
          FileSystemEntityType.notFound) {
        kept.add(file);
        continue;
      }
      await Directory(p.dirname(destination)).create(recursive: true);
      await _copier(p.join(source, file), destination);
      copied.add(file);
    }
    return WorktreeSeedResult(copied: copied, missing: missing, kept: kept);
  }

  /// Every file under [seed], walked by hand so a link is looked at instead of
  /// followed. `cp -R` would carry the link itself into the worktree.
  List<String> _filesUnder(String root, String seed) {
    _assertInside(root, p.join(root, seed), seed);
    final files = <String>[];
    final directory = Directory(p.join(root, seed));
    for (final entry in directory.listSync(followLinks: false)) {
      final relative = p.relative(entry.path, from: root);
      if (entry is Link) {
        final type = FileSystemEntity.typeSync(entry.path);
        _assertInside(root, entry.path, relative);
        if (type == FileSystemEntityType.directory) {
          files.addAll(_filesUnder(root, relative));
        } else {
          files.add(relative);
        }
      } else if (entry is Directory) {
        files.addAll(_filesUnder(root, relative));
      } else {
        files.add(relative);
      }
    }
    return files;
  }

  void _assertInside(String root, String path, String seed) {
    final String resolved;
    try {
      resolved = File(path).resolveSymbolicLinksSync();
    } on FileSystemException {
      throw WorktreeSeedException('Seed file $seed is a broken link');
    }
    if (resolved != root && !p.isWithin(root, resolved)) {
      throw WorktreeSeedException(
        'Seed file $seed resolves outside the source checkout',
      );
    }
  }

  /// The deepest part of the destination that exists has to resolve inside the
  /// worktree, or a planted `config -> ~/.ssh` would receive the copy.
  void _assertDestinationInside(String root, String seed) {
    var path = p.join(root, seed);
    while (path != root) {
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      if (type != FileSystemEntityType.notFound) {
        final String resolved;
        try {
          resolved = File(path).resolveSymbolicLinksSync();
        } on FileSystemException {
          throw WorktreeSeedException(
            'Seed file $seed is behind a broken link in the worktree',
          );
        }
        if (resolved != root && !p.isWithin(root, resolved)) {
          throw WorktreeSeedException(
            'Seed file $seed resolves outside the worktree',
          );
        }
        return;
      }
      path = p.dirname(path);
    }
  }
}

/// Copies [source] to [destination] with copy-on-write where the filesystem has
/// it: `/bin/cp -c` on macOS, `cp --reflink=auto` elsewhere, and a plain copy
/// when neither works. A CoW copy that fails is not an error: these are small
/// files, and the copy only has to arrive.
Future<void> copyWorktreeFile(String source, String destination) async {
  if (!Platform.isWindows) {
    final argv = Platform.isMacOS
        ? ['/bin/cp', '-c', '-p', source, destination]
        : ['cp', '--reflink=auto', '-p', source, destination];
    try {
      final result = await Process.run(argv.first, argv.sublist(1));
      if (result.exitCode == 0) {
        return;
      }
      CcInfraLog.debug(
        'CoW copy of ${p.basename(source)} failed: ${result.stderr}',
      );
    } on ProcessException catch (e) {
      CcInfraLog.debug('CoW copy unavailable: $e');
    }
  }
  await File(source).copy(destination);
}
