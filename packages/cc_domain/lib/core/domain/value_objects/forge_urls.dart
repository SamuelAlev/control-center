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

  /// A branch's web page.
  String branch(String owner, String name, String ref) => switch (forge) {
    ForgeHost.github => '${repo(owner, name)}/tree/$ref',
    ForgeHost.gitlab => '${repo(owner, name)}/-/tree/$ref',
    ForgeHost.bitbucket => '${repo(owner, name)}/src/$ref',
    ForgeHost.local => '',
  };

  /// A user's profile page.
  ///
  /// Bitbucket addresses profiles by account id rather than a handle, so a
  /// nickname-based link is not guaranteed to resolve; callers should prefer a
  /// forge-supplied profile URL where they have one.
  String user(String login) => switch (forge) {
    ForgeHost.github || ForgeHost.gitlab => '${forge.webBaseUrl}/$login',
    ForgeHost.bitbucket => '${forge.webBaseUrl}/$login/',
    ForgeHost.local => '',
  };

  /// The forge's public status page, for the "is it me or them?" banner.
  String get statusPage => switch (forge) {
    ForgeHost.github => 'https://www.githubstatus.com/',
    ForgeHost.gitlab => 'https://status.gitlab.com/',
    ForgeHost.bitbucket => 'https://bitbucket.status.atlassian.com/',
    ForgeHost.local => '',
  };

  /// The Statuspage v2 summary endpoint backing [statusPage].
  ///
  /// All three forges run Statuspage, so one parser serves them — only the host
  /// differs.
  String get statusSummaryUrl => switch (forge) {
    ForgeHost.github => 'https://www.githubstatus.com/api/v2/summary.json',
    ForgeHost.gitlab => 'https://status.gitlab.com/api/v2/summary.json',
    ForgeHost.bitbucket =>
      'https://bitbucket.status.atlassian.com/api/v2/summary.json',
    ForgeHost.local => '',
  };

  /// Where an operator creates a personal access token for this forge, for the
  /// "connect" affordance to link to.
  String get tokenSettingsUrl => switch (forge) {
    ForgeHost.github => 'https://github.com/settings/tokens',
    ForgeHost.gitlab =>
      'https://gitlab.com/-/user_settings/personal_access_tokens',
    ForgeHost.bitbucket =>
      'https://id.atlassian.com/manage-profile/security/api-tokens',
    ForgeHost.local => '',
  };
}
