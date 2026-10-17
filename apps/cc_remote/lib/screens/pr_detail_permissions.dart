part of 'pr_detail_screen.dart';

extension _PrDetailPermissions on _PrDetailScreenState {
  bool _hasWriteAccess() {
    final perm = ref.read(prRepoPermissionProvider(_coords)).value;
    return perm == 'admin' || perm == 'write';
  }

  String _viewerLogin() {
    final repo = ref.read(prRepoProvider(_coords));
    final logins = ref.read(viewerLoginsProvider).value ?? const {};
    if (repo == null) {
      return '';
    }
    return logins[repo.forge] ?? '';
  }

  bool _canEditPrBody(PullRequest pr) {
    final login = _viewerLogin();
    final isAuthor =
        login.isNotEmpty && pr.author?.login.toLowerCase() == login;
    return isAuthor || _hasWriteAccess();
  }

  bool _canEditComment(PrUser? author) {
    final login = _viewerLogin();
    final isAuthor = login.isNotEmpty && author?.login.toLowerCase() == login;
    return isAuthor || _hasWriteAccess();
  }
}
