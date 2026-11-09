import 'dart:io';

import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart' show RigWorktreeGuard;
import 'package:path/path.dart' as p;

/// A compose stack did not come up in its rig.
class EnvironmentRigStackFailure implements Exception {
  /// Creates an [EnvironmentRigStackFailure].
  const EnvironmentRigStackFailure(this.message);

  /// What went wrong, with the guest's own words where there are some.
  final String message;

  @override
  String toString() => 'EnvironmentRigStackFailure: $message';
}

/// Refuses any [paths] that are not one of [allowedRoots], after following
/// symlinks, then quarantines all of them before a rig sees them.
///
/// Every path is checked before any is quarantined, so a refusal leaves
/// nothing quarantined behind it. The quarantine is lifted by
/// [releaseEnvironmentRigMounts] whenever the rig goes, however it goes.
void admitEnvironmentRigMounts(
  Iterable<String> allowedRoots,
  Iterable<String> paths,
) {
  final allowed = {
    for (final root in allowedRoots)
      if (Directory(root).existsSync()) _real(root),
  };
  final admitted = paths.toList(growable: false);
  for (final path in admitted) {
    if (!Directory(path).existsSync() || !allowed.contains(_real(path))) {
      throw EnvironmentRigStackFailure(
        'Refusing to mount $path: it is not one of this space\'s worktrees.',
      );
    }
  }
  for (final path in admitted) {
    RigWorktreeGuard.quarantine(path);
  }
}

String _real(String path) =>
    p.normalize(Directory(path).resolveSymbolicLinksSync());

/// Lifts the quarantine of every worktree [rig] mounted, unless its git
/// metadata changed: that one stays guarded until a person looks.
///
/// Idempotent, and a no-op for anything but an environment rig.
void releaseEnvironmentRigMounts(Rig rig) {
  if (!rig.spec.isEnvironment) {
    return;
  }
  releaseEnvironmentRigPaths(rig.id, [
    ?rig.spec.worktreePath,
    ...rig.spec.extraMounts.values,
  ]);
}

/// [releaseEnvironmentRigMounts] for paths no rig row names yet.
void releaseEnvironmentRigPaths(String rigId, Iterable<String> paths) {
  for (final path in paths) {
    try {
      if (!Directory(path).existsSync()) {
        // Released with its worktree: no git of ours can run there again,
        // and a registry entry for it would outlive it forever.
        RigWorktreeGuard.forceRelease(path);
        continue;
      }
      if (!RigWorktreeGuard.release(path)) {
        CcInfraLog.warning(
          'rig/$rigId: the git metadata of $path changed while it was '
          'mounted; it stays quarantined',
        );
      }
    } on FileSystemException catch (e) {
      // The worktree went first. Its registry entry went with it.
      CcInfraLog.warning('rig/$rigId: could not release $path: $e');
    }
  }
}
