import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// The git-level conventions that differ between forges.
///
/// Everything here is plumbing a `git` command needs and an API call does not:
/// how to address a pull request's head commit, how to build an authenticated
/// clone URL, and which credential shape the remote expects. Keeping them in
/// one value object is what lets the worktree/clone/diff services stay
/// forge-agnostic instead of growing a `switch` each.
class ForgeGitConventions {
  const ForgeGitConventions._(this.forge);

  /// The conventions for [forge].
  factory ForgeGitConventions.of(ForgeHost forge) =>
      ForgeGitConventions._(forge);

  /// The forge these conventions describe.
  final ForgeHost forge;

  /// The remote ref that resolves to pull request [number]'s head commit, or
  /// `null` when the forge publishes no such ref.
  ///
  /// GitHub and GitLab both maintain a server-side ref, which is what lets a
  /// PR be checked out even after its source branch is deleted or when it comes
  /// from a fork. Bitbucket does not: callers get `null` and must fetch the
  /// source branch by name, which fails once that branch is gone.
  String? prHeadRef(int number) => switch (forge) {
    ForgeHost.github => 'refs/pull/$number/head',
    ForgeHost.gitlab => 'refs/merge-requests/$number/head',
    ForgeHost.bitbucket => null,
    ForgeHost.local => null,
  };

  /// The local ref a fetched PR head is parked at.
  String prFetchTarget(int number) => 'refs/cc/pr/$number';

  /// The public HTTPS clone URL for `owner/name`.
  String cloneUrl(String owner, String name) =>
      '${forge.webBaseUrl}/$owner/$name.git';

  /// A clone URL with [token] embedded as basic-auth userinfo.
  ///
  /// Each forge names the username half differently and treats it as
  /// significant, so this is not a shared string with a swapped host:
  /// GitHub expects `x-access-token`, GitLab expects `oauth2`, and Bitbucket
  /// authenticates with the account's email address rather than a placeholder.
  ///
  /// Prefer [authHeaderConfig] where possible — a URL with a token in it lands
  /// in `.git/config`, reflog and error output; a header does not.
  String authenticatedCloneUrl(
    String owner,
    String name,
    String token, {
    String? username,
  }) {
    final user = switch (forge) {
      ForgeHost.github => 'x-access-token',
      ForgeHost.gitlab => 'oauth2',
      ForgeHost.bitbucket => username ?? 'x-token-auth',
      ForgeHost.local => 'git',
    };
    return 'https://$user:$token@${forge.gitHost}/$owner/$name.git';
  }

  /// The `git -c <key>=<value>` pair that attaches an `Authorization` header to
  /// requests for this forge's host, as `(key, value)`.
  ///
  /// The header form keeps the token out of `.git/config` and out of any URL
  /// that might be logged.
  (String, String) authHeaderConfig(String basicAuthValue) => (
    'http.${forge.webBaseUrl}/.extraHeader',
    'Authorization: Basic $basicAuthValue',
  );

  /// Whether a checkout of a PR can rely on [prHeadRef].
  bool get hasServerSidePrHeadRef => prHeadRef(1) != null;
}
