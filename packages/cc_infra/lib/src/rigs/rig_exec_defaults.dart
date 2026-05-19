import 'dart:io';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show ForgeRemote, parseForgeRemote;
import 'package:cc_domain/features/sandboxing/domain/network_baseline.dart'
    show kBaselineAllowedDomains;

/// What a terminal (exec) rig may reach, and the repo its credentials scope to.
///
/// An exec rig used to be opened with an EMPTY egress allowlist, which broke
/// the feature twice over: the per-rig proxies (deny-by-default) blocked every
/// outbound byte including `apt` and `git fetch`, and the credential broker —
/// whose allowed-hosts set IS the egress allowlist — refused every mint, so
/// `git push` from an in-VM terminal was structurally impossible while the
/// capability flags said it should work.

/// Ubuntu's package mirrors, which the stock exec image needs for
/// `apt install`. Both architectures' hosts are listed because the guest's
/// architecture is the HOST's, and one list serving both keeps this from
/// silently breaking when an x86 server joins.
const List<String> kExecRigAptMirrors = [
  'archive.ubuntu.com',
  'security.ubuntu.com',
  'ports.ubuntu.com',
  'esm.ubuntu.com',
  'motd.ubuntu.com',
];

/// The egress allowlist for a terminal (exec) rig.
///
/// The sandboxed coding-agent baseline (forges, package registries, LLM
/// providers) plus apt, plus the worktree's own forge host when one was
/// detected. Deliberately the same vocabulary as the host sandbox: the
/// enclosed terminal should be able to do what the sandboxed host terminal
/// can, from inside a machine that can be thrown away.
List<String> execRigEgressAllowlist({ForgeRemote? forge}) => [
  ...kBaselineAllowedDomains,
  ...kExecRigAptMirrors,
  if (forge != null && forge.forge.gitHost.isNotEmpty) forge.forge.gitHost,
];

/// Resolves the forge coordinate of the git checkout at [path], or null when
/// the path is not a git worktree or its `origin` is not a supported forge.
///
/// Asks git itself rather than parsing `.git/config`, because `path` may be a
/// linked worktree whose real config lives in the parent repository.
Future<ForgeRemote?> detectWorktreeForge(String path) async {
  if (path.isEmpty || !Directory(path).existsSync()) {
    return null;
  }
  try {
    final result = await Process.run('git', [
      '-C',
      path,
      'remote',
      'get-url',
      'origin',
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    return parseForgeRemote('${result.stdout}'.trim());
  } on Object {
    return null;
  }
}
