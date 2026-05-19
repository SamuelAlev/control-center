
/// Parsed reference to a GitHub pull request or issue.
sealed class GitHubReference {
  const GitHubReference._();

  /// The GitHub organization/owner.
  String get owner;

  /// The GitHub repository name.
  String get repo;

  /// The issue or PR number.
  int get number;
}

/// A reference to a GitHub pull request.
class GitHubPrReference extends GitHubReference {
  const GitHubPrReference({
    required this.owner,
    required this.repo,
    required this.number,
  }) : super._();

  @override
  final String owner;

  @override
  final String repo;

  @override
  final int number;

  @override
  String toString() => 'GitHubPrReference($owner/$repo#$number)';
}

/// A reference to a GitHub issue.
class GitHubIssueReference extends GitHubReference {
  const GitHubIssueReference({
    required this.owner,
    required this.repo,
    required this.number,
  }) : super._();

  @override
  final String owner;

  @override
  final String repo;

  @override
  final int number;

  @override
  String toString() => 'GitHubIssueReference($owner/$repo#$number)';
}

/// A reference to a single GitHub commit by SHA.
class GitHubCommitReference extends GitHubReference {
  /// Creates a [GitHubCommitReference].
  const GitHubCommitReference({
    required this.owner,
    required this.repo,
    required this.sha,
  }) : super._();

  @override
  final String owner;

  @override
  final String repo;

  /// Full or shortened commit SHA (hex).
  final String sha;

  /// `number` is not meaningful for commits; returns 0.
  @override
  int get number => 0;

  /// Short 7-char SHA for display.
  String get shortSha => sha.length >= 7 ? sha.substring(0, 7) : sha;

  @override
  String toString() => 'GitHubCommitReference($owner/$repo@$shortSha)';
}

// ---------------------------------------------------------------------------
// Full URL parsing
// ---------------------------------------------------------------------------

/// Matches `https://github.com/<owner>/<repo>/pull/<number>` (with optional
/// trailing slash or query string).
final _prUrlPattern = RegExp(
  r'^https?://github\.com/'
  r'([^/]+)/' // owner
  r'([^/]+)/' // repo
  r'pull/'
  r'(\d+)' // number
  r'(?:[/?#].*)?$',
  caseSensitive: false,
);

/// Matches `https://github.com/<owner>/<repo>/issues/<number>`.
final _issueUrlPattern = RegExp(
  r'^https?://github\.com/'
  r'([^/]+)/' // owner
  r'([^/]+)/' // repo
  r'issues/'
  r'(\d+)' // number
  r'(?:[/?#].*)?$',
  caseSensitive: false,
);

/// Matches `https://github.com/<owner>/<repo>/commit/<sha>` (singular path
/// segment — the GitHub web URL for an individual commit). `commits/<sha>`
/// is also accepted because GitHub redirects between the two.
final _commitUrlPattern = RegExp(
  r'^https?://github\.com/'
  r'([^/]+)/' // owner
  r'([^/]+)/' // repo
  r'commits?/'
  r'([a-f0-9]{7,40})' // sha (7-40 hex chars)
  r'(?:[/?#].*)?$',
  caseSensitive: false,
);

/// Parses a full GitHub HTML URL into a [GitHubReference].
///
/// Recognises:
///   * `https://github.com/<owner>/<repo>/pull/<number>`
///   * `https://github.com/<owner>/<repo>/issues/<number>`
///
/// Returns `null` when the URL does not match a known GitHub pattern.
GitHubReference? parseGitHubUrl(String url) {
  final prMatch = _prUrlPattern.firstMatch(url);
  if (prMatch != null) {
    return GitHubPrReference(
      owner: prMatch.group(1)!,
      repo: prMatch.group(2)!,
      number: int.parse(prMatch.group(3)!),
    );
  }

  final issueMatch = _issueUrlPattern.firstMatch(url);
  if (issueMatch != null) {
    return GitHubIssueReference(
      owner: issueMatch.group(1)!,
      repo: issueMatch.group(2)!,
      number: int.parse(issueMatch.group(3)!),
    );
  }

  final commitMatch = _commitUrlPattern.firstMatch(url);
  if (commitMatch != null) {
    return GitHubCommitReference(
      owner: commitMatch.group(1)!,
      repo: commitMatch.group(2)!,
      sha: commitMatch.group(3)!.toLowerCase(),
    );
  }

  return null;
}

// ---------------------------------------------------------------------------
// App deep-link scheme parsing (`control-center://pr/...`)
//
// The markdown preprocessor emits the same scheme the OS uses to launch
// the app from external links, so a copy-paste of a rendered chip is a
// real, working deep link.
// ---------------------------------------------------------------------------

/// Matches `control-center://pr/<owner>/<repo>/<number>`.
final _appPrPattern = RegExp(
  r'^control-center://pr/'
  r'([^/]+)/' // owner
  r'([^/]+)/' // repo
  r'(\d+)$',
  caseSensitive: false,
);

/// Parses an internal `control-center://` deep link into a [GitHubReference].
///
/// Returns `null` when the URL does not match a known shape.
GitHubReference? parseGitHubAppScheme(String url) {
  final match = _appPrPattern.firstMatch(url);
  if (match == null) {
    return null;
  }
  return GitHubPrReference(
    owner: match.group(1)!,
    repo: match.group(2)!,
    number: int.parse(match.group(3)!),
  );
}

/// Tries both [parseGitHubUrl] and [parseGitHubAppScheme] in sequence.
///
/// [currentOwner] and [currentRepo] are retained for source compatibility
/// with call sites that haven't been updated; they're no longer used now
/// that the app scheme always carries owner/repo explicitly.
GitHubReference? parseAnyGitHubReference(
  String url, {
  required String currentOwner,
  required String currentRepo,
}) {
  return parseGitHubUrl(url) ?? parseGitHubAppScheme(url);
}
