import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Builds the web URLs for one forge.
///
/// Every forge spells its paths differently — GitLab puts merge requests under
/// `/-/merge_requests/`, Bitbucket under `/pull-requests/` — so a link built by
/// string-concatenating `github.com` is wrong on two of the three. Routing all
/// of them through here means adding a forge is one `switch` arm, not a hunt
/// through the presentation layer.
///
/// Prefer a URL the forge itself supplied (`PullRequest.htmlUrl`,
/// `PrUser.avatarUrl`) whenever one is present: it is authoritative, survives
/// renames and works for self-hosted installs. These builders are the fallback
/// for when we hold only a coordinate.
class ForgeUrls {
  /// Creates a [ForgeUrls] for [forge].
  const ForgeUrls(this.forge);

  /// The forge whose URL vocabulary this speaks.
  final ForgeHost forge;

  /// The repository's web page.
  String repo(String owner, String name) => '${forge.webBaseUrl}/$owner/$name';

  /// A pull request's web page.
  String pullRequest(String owner, String name, int number) => switch (forge) {
    ForgeHost.github => '${repo(owner, name)}/pull/$number',
    ForgeHost.gitlab => '${repo(owner, name)}/-/merge_requests/$number',
    ForgeHost.bitbucket => '${repo(owner, name)}/pull-requests/$number',
    ForgeHost.local => '',
  };

  /// A commit's web page.
  String commit(String owner, String name, String sha) => switch (forge) {
    ForgeHost.github => '${repo(owner, name)}/commit/$sha',
    ForgeHost.gitlab => '${repo(owner, name)}/-/commit/$sha',
    ForgeHost.bitbucket => '${repo(owner, name)}/commits/$sha',
    ForgeHost.local => '',
  };
}
