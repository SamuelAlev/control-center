/// GitHub login: 1–39 characters, alphanumeric or single hyphens, no
/// leading or trailing hyphen.
const String kGitHubLoginPattern =
    r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?';

final _userAppUrl = RegExp(
  '^control-center://user/($kGitHubLoginPattern)\$',
  caseSensitive: false,
);

final _teamAppUrl = RegExp(
  '^control-center://team/($kGitHubLoginPattern)/($kGitHubLoginPattern)\$',
  caseSensitive: false,
);

final _atUserLabel = RegExp('^@($kGitHubLoginPattern)\$');

final _atTeamLabel = RegExp(
  '^@($kGitHubLoginPattern)/($kGitHubLoginPattern)\$',
);

/// An `@user` or `@org/team` mention that should render as a chip.
class GitHubMentionLink {
  /// Creates a [GitHubMentionLink].
  const GitHubMentionLink({required this.login, this.isTeam = false});

  /// GitHub login, or `org/slug` when [isTeam].
  final String login;

  /// Whether this is an org team rather than a user.
  final bool isTeam;
}

/// Resolves a markdown link to a mention chip target.
///
/// Claims preprocessor-emitted `control-center://user|team/…` hrefs and
/// author-written links whose visible label is `@login` / `@org/team` (the
/// form GitHub's HTML sometimes round-trips as).
GitHubMentionLink? parseGitHubMentionLink({
  required String url,
  String label = '',
}) {
  final userUrl = _userAppUrl.firstMatch(url);
  if (userUrl != null) {
    return GitHubMentionLink(login: userUrl.group(1)!);
  }
  final teamUrl = _teamAppUrl.firstMatch(url);
  if (teamUrl != null) {
    return GitHubMentionLink(
      login: '${teamUrl.group(1)}/${teamUrl.group(2)}',
      isTeam: true,
    );
  }
  final trimmed = label.trim();
  final teamLabel = _atTeamLabel.firstMatch(trimmed);
  if (teamLabel != null) {
    return GitHubMentionLink(
      login: '${teamLabel.group(1)}/${teamLabel.group(2)}',
      isTeam: true,
    );
  }
  final userLabel = _atUserLabel.firstMatch(trimmed);
  if (userLabel != null) {
    return GitHubMentionLink(login: userLabel.group(1)!);
  }
  return null;
}
