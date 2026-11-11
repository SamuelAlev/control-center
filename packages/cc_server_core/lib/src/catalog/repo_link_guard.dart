import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/forge/repo_access_registry.dart'
    show RepoAccessIssue;

/// Whether saving [repo] over [existing] names another forge repository
/// than the one linked: another forge, owner or name (letter case aside),
/// an empty remote included. Only the link path may do that.
bool changesForgeIdentity(Repo existing, Repo repo) =>
    existing.forge != repo.forge ||
    existing.remoteOwner.toLowerCase() != repo.remoteOwner.toLowerCase() ||
    existing.remoteName.toLowerCase() != repo.remoteName.toLowerCase();

/// A forge link lets automation mint tokens for that repository in the
/// caller's workspace, so making one is an admin decision, as granting a
/// member repository access is (`members.setRepoGrant`). The caller's own
/// forge sign-in must also see the repository (`verifyRepoLink`), checked
/// after this. A workspace-scoped op always carries the caller's role; a
/// missing one is refused.
void requireRepoLinkAdmin(RepoOpContext ctx) {
  if (!(ctx.role?.isAdmin ?? false)) {
    throw const AuthException('Only a workspace admin can link a repository');
  }
}

/// The `access_warnings` a link answers: what automation will meet on the
/// new link (`{state, message, install_url?}`), already recorded in the repo
/// access registry. Empty when nothing stands in its way.
List<Map<String, Object?>> accessWarningsWire(List<RepoAccessIssue> issues) =>
    [
      for (final issue in issues)
        {
          'state': issue.state.wire,
          'message': issue.message,
          'install_url': ?issue.installUrl,
        },
    ];
