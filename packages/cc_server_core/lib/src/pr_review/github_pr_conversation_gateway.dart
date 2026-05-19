import 'package:cc_infra/cc_infra.dart'
    show
        GitHubApiClient,
        GitHubAppClient,
        GitHubIssueComment,
        GitHubReviewComment,
        GitHubViewerPr;

/// The PR label that asks the server's bot for a review — the stand-in for
/// assigning a reviewer, which GitHub's API does not offer to app accounts
/// (`requested_reviewers` accepts users and teams only). An operator adds it
/// in the PR's Labels menu; adding it is the explicit ask.
const String kGithubPrReviewLabel = 'ai-review';

/// The GitHub operations the PR-conversation surface needs, as one seam so the
/// bridge and poller run their whole behaviour against an in-memory fake.
///
/// Everything here is executed as the SERVER's identity (the app, falling back
/// to the owner's credential and then the environment): a PR comment is
/// background work no human clicked, which is the attribution rule the forge
/// seams already follow.
abstract interface class GitHubPrConversationGateway {
  /// The bot account login (`<slug>[bot]`) commenters must @mention, or ''
  /// when this server has no app identity — in which case the whole surface
  /// idles, because there is no bot to talk to.
  Future<String> botLogin();

  /// Open PRs the bot is being invoked on: PRs whose conversation mentions the
  /// bot ([GitHubPrConversationGateway.botLogin]), and PRs carrying the
  /// configured review label. [since] bounds only the mention lane; the label
  /// lane is an unbounded set whose membership is itself the trigger state.
  Future<
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> shortMentioned,
      List<GitHubViewerPr> labeled,
    })
  >
  searchCandidates({DateTime? since});

  /// Conversation-timeline comments on one PR.
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int prNumber,
  );

  /// Inline review comments (diff-anchored threads) on one PR.
  Future<List<GitHubReviewComment>> listReviewComments(
    String owner,
    String repo,
    int prNumber,
  );

  /// Acknowledges an inbound conversation comment with a 👀 reaction.
  Future<void> acknowledgeIssueComment(
    String owner,
    String repo,
    int commentId,
  );

  /// Acknowledges an inbound inline review comment with a 👀 reaction.
  Future<void> acknowledgeReviewComment(
    String owner,
    String repo,
    int commentId,
  );

  /// Posts a top-level comment on the PR conversation timeline.
  Future<void> postConversationComment(
    String owner,
    String repo, {
    required int prNumber,
    required String body,
  });

  /// Replies inside an existing inline review-comment thread.
  Future<void> replyInReviewThread(
    String owner,
    String repo, {
    required int prNumber,
    required int parentCommentId,
    required String body,
  });
}

/// Production gateway over the app identity and the per-owner GitHub clients.
///
/// Search coverage is the subtle part: an installation token only sees the
/// repos of ITS installation, so a single server-wide client would silently
/// miss every PR under the app's other installations. The candidate search
/// therefore runs once per installation account, each on that owner's
/// client, and merges the lanes deduplicated by PR. A failing owner is
/// skipped rather than failing the sweep — partial coverage beats none, and
/// the next sweep retries.
class AppBackedGitHubPrConversationGateway
    implements GitHubPrConversationGateway {
  /// Creates an [AppBackedGitHubPrConversationGateway].
  AppBackedGitHubPrConversationGateway({
    required Future<GitHubAppClient?> Function() app,
    required GitHubApiClient Function(String owner) clientForOwner,
    String reviewLabel = kGithubPrReviewLabel,
    void Function(String message)? onWarning,
  }) : _app = app,
       _clientForOwner = clientForOwner,
       _reviewLabel = reviewLabel,
       _onWarning = onWarning;

  final Future<GitHubAppClient?> Function() _app;
  final GitHubApiClient Function(String owner) _clientForOwner;
  final String _reviewLabel;
  final void Function(String message)? _onWarning;

  @override
  Future<String> botLogin() async {
    final info = await (await _app())?.botInfo();
    return info?.botLogin ?? '';
  }

  @override
  Future<
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> shortMentioned,
      List<GitHubViewerPr> labeled,
    })
  >
  searchCandidates({DateTime? since}) async {
    final app = await _app();
    if (app == null) {
      return (
        mentioned: const <GitHubViewerPr>[],
        shortMentioned: const <GitHubViewerPr>[],
        labeled: const <GitHubViewerPr>[],
      );
    }
    final info = await app.botInfo();
    final botLogin = info?.botLogin ?? '';
    if (botLogin.isEmpty) {
      return (
        mentioned: const <GitHubViewerPr>[],
        shortMentioned: const <GitHubViewerPr>[],
        labeled: const <GitHubViewerPr>[],
      );
    }
    final mentioned = <String, GitHubViewerPr>{};
    final shortMentioned = <String, GitHubViewerPr>{};
    final labeled = <String, GitHubViewerPr>{};
    for (final installation in await app.installations()) {
      final owner = installation.account;
      if (owner.isEmpty) {
        continue;
      }
      try {
        final result = await _clientForOwner(
          owner,
        ).graphql.searchBotConversationCandidates(
          botLogin: botLogin,
          label: _reviewLabel,
          since: since,
        );
        for (final pr in result.mentioned) {
          mentioned[pr.key] = pr;
        }
        for (final pr in result.shortMentioned) {
          shortMentioned[pr.key] = pr;
        }
        for (final pr in result.labeled) {
          labeled[pr.key] = pr;
        }
      } on Object catch (e) {
        // One dead installation must not blind the sweep to the others.
        _onWarning?.call(
          'github_pr_conversation: search failed for owner $owner: $e',
        );
      }
    }
    return (
      mentioned: mentioned.values.toList(growable: false),
      shortMentioned: shortMentioned.values.toList(growable: false),
      labeled: labeled.values.toList(growable: false),
    );
  }

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int prNumber,
  ) => _clientForOwner(owner).pr.listIssueComments(owner, repo, prNumber);

  @override
  Future<List<GitHubReviewComment>> listReviewComments(
    String owner,
    String repo,
    int prNumber,
  ) => _clientForOwner(owner).pr.listPullRequestReviewComments(
    owner,
    repo,
    prNumber,
  );

  @override
  Future<void> acknowledgeIssueComment(
    String owner,
    String repo,
    int commentId,
  ) async {
    await _clientForOwner(owner).pr.createIssueCommentReaction(
      owner,
      repo,
      commentId: commentId,
      content: 'eyes',
    );
  }

  @override
  Future<void> acknowledgeReviewComment(
    String owner,
    String repo,
    int commentId,
  ) async {
    await _clientForOwner(owner).pr.createReviewCommentReaction(
      owner,
      repo,
      commentId: commentId,
      content: 'eyes',
    );
  }

  @override
  Future<void> postConversationComment(
    String owner,
    String repo, {
    required int prNumber,
    required String body,
  }) async {
    await _clientForOwner(owner).pr.createIssueComment(
      owner,
      repo,
      prNumber: prNumber,
      body: body,
    );
  }

  @override
  Future<void> replyInReviewThread(
    String owner,
    String repo, {
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {
    await _clientForOwner(owner).pr.replyToReviewComment(
      owner,
      repo,
      prNumber: prNumber,
      parentCommentId: parentCommentId,
      body: body,
    );
  }
}
