import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;

/// Whether saving [repo] over [existing] makes a forge link: a new repo with
/// a forge remote, or one retargeted at another forge repository. Renames,
/// reorders and local edits of a link already made are not.
bool isNewForgeLink(Repo? existing, Repo repo) {
  if (!repo.hasForgeRemote) {
    return false;
  }
  return existing == null ||
      existing.forge != repo.forge ||
      existing.remoteOwner.toLowerCase() != repo.remoteOwner.toLowerCase() ||
      existing.remoteName.toLowerCase() != repo.remoteName.toLowerCase();
}

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
