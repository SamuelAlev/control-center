import 'package:cc_domain/cc_domain.dart'
    show AuthException, NeedsSignInException;
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';

/// Refuses [userId] reading the code of [repoId] in [workspaceId] unless
/// their own forge sign-in can read that repository. Throws
/// [NeedsSignInException] when they are not signed in to its forge and
/// [AuthException] when their sign-in cannot read it or the forge could not
/// confirm that it can.
typedef RepoForgeReadCheck =
    Future<void> Function({
      required String workspaceId,
      required String userId,
      required String repoId,
    });

/// The one decision of whether a person's forge sign-in lets them read a
/// linked repository's code, used by every grant gate (the op dispatcher's
/// per-repo gates and the catalog's grant checks) on top of the grant.
///
/// Code follows the forge exactly as pull request data does
/// ([PrRepoVisibility.requireForgeAccess]): workspace admins are not exempt,
/// and a forge that cannot be asked right now refuses (fail closed, as PR
/// data reads `checking`) until it answers. The server owner is exempt: they
/// own the host and its disk, which keeps a desktop usable before sign-in. A
/// repository with no forge remote has no forge to ask and is governed by
/// the grant alone, as is an id no repository carries (the op answers that).
///
/// Without [visibility] every forge repository is refused.
RepoForgeReadCheck repoForgeReadCheck({
  required RepoRepository repos,
  required PrRepoVisibility? visibility,
  required String? serverOwnerUserId,
}) => ({required workspaceId, required userId, required repoId}) async {
  if (serverOwnerUserId != null &&
      serverOwnerUserId.isNotEmpty &&
      userId == serverOwnerUserId) {
    return;
  }
  final repo = await repos.getById(workspaceId, repoId);
  if (repo == null || !repo.hasForgeRemote) {
    return;
  }
  if (visibility == null) {
    throw const AuthException(
      'This server cannot ask the forge who may read this repository.',
    );
  }
  await visibility.requireForgeAccess(workspaceId, userId, repo);
};

/// What [check] says about [userId] reading [repoId], as the warning an admin
/// sees after granting it to them: null when they can read it, otherwise
/// `{state, message}` with state `not_signed_in` (no sign-in on its forge),
/// `cannot_read` (their sign-in cannot read it) or `unconfirmed` (the forge
/// could not be asked; they are refused until it answers).
Future<Map<String, String>?> memberForgeReadWarning(
  RepoForgeReadCheck check, {
  required String workspaceId,
  required String userId,
  required String repoId,
}) async {
  try {
    await check(workspaceId: workspaceId, userId: userId, repoId: repoId);
    return null;
  } on NeedsSignInException {
    return const {
      'state': 'not_signed_in',
      'message':
          'They are not signed in to this forge, so they cannot read this '
          'repository until they are.',
    };
  } on AuthException catch (e) {
    return e.code == forgeAccessUnconfirmedCode
        ? const {
            'state': 'unconfirmed',
            'message':
                'The forge could not confirm that they can read this '
                'repository yet.',
          }
        : const {
            'state': 'cannot_read',
            'message':
                'Their forge account cannot read this repository, so the '
                'grant gives them nothing until it can.',
          };
  }
}
