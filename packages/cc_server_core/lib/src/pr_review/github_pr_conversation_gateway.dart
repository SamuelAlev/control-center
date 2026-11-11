import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_infra/cc_infra.dart'
    show
        BotConversationCandidates,
        GitHubApiClient,
        GitHubIssueComment,
        GitHubReaction,
        GitHubReviewComment;
import 'package:cc_server_core/src/forge/github_clients.dart'
    show GitHubBotPresence, GitHubLane, GitHubScopedGrant;

/// The PR label that asks the workspace's bot for a review — the stand-in for
/// assigning a reviewer, which GitHub's API does not offer to app accounts
/// (`requested_reviewers` accepts users and teams only). A member with push
/// access adds it in the PR's Labels menu; adding it is the explicit ask.
const String kGithubPrReviewLabel = 'ai-review';

/// Who a workspace's PR conversations are with right now.
final class GitHubConversationIdentity {
  /// Creates the identity.
  const GitHubConversationIdentity({
    required this.botLogin,
    required this.slug,
    required this.lane,
  });

  /// The App's bot account (`<slug>[bot]`): the loop guard.
  final String botLogin;

  /// The App's public slug.
  final String slug;

  /// The lane the workspace's automation runs on.
  final GitHubLane lane;

  /// Whether replies through [other] would post as this same identity.
  bool sameAs(GitHubConversationIdentity other) =>
      other.lane == lane &&
      other.botLogin.toLowerCase() == botLogin.toLowerCase();
}

/// A GitHub account seen on the PR (a comment author, a labeller).
final class GitHubPrActor {
  /// Creates the actor.
  const GitHubPrActor({required this.accountId, required this.login});

  /// GitHub's immutable numeric user id — the identity.
  final int accountId;

  /// The login at the time — display only.
  final String login;
}

/// The outcome of a 👀 claim.
enum GitHubReactionClaim {
  /// This server left the reaction (HTTP 201): the work is ours.
  claimed,

  /// The bot had already left it (HTTP 200): another server on the same
  /// App, or an earlier attempt, owns the work.
  alreadyClaimed,
}

/// The GitHub operations the PR-conversation surface needs, as one seam so the
/// bridge and poller run their whole behaviour against an in-memory fake.
///
/// One gateway serves exactly one workspace and speaks as its App's bot on
/// every lane: reads ride that workspace's one-repository tokens bounded by
/// its accountable human, while replies and claims are bounded by the member
/// who asked. There is no server-wide identity to fall back to, and no
/// person's own token is ever used.
abstract interface class GitHubPrConversationGateway {
  /// The bot and lane the workspace converses as, or null when it has no
  /// GitHub lane (the conversation surface idles).
  Future<GitHubConversationIdentity?> identity();

  /// Open PRs addressed via @usectrl, and PRs carrying the configured review
  /// label. [since] bounds only the mention lane; the label lane's
  /// membership is itself trigger state.
  Future<BotConversationCandidates> searchCandidates({DateTime? since});

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

  /// Who most recently added [label] to the PR (its latest `labeled` issue
  /// event), or null when no such event is visible.
  Future<GitHubPrActor?> latestLabeler(
    String owner,
    String repo,
    int prNumber, {
    String label,
  });

  /// Whether this server can mint, for [owner]/[repo] bounded by
  /// [actingUserId], the scope its claim and reply there need: `bot` inside
  /// an inline review thread ([inReviewThread]: the review-comment reaction
  /// and the thread reply), else `comment` (an issue-comment or pull request
  /// reaction and a timeline comment). The App is installed there and that
  /// member can push; a token clamped below that scope is a refusal.
  Future<bool> canPostAs(
    String owner,
    String repo, {
    required String actingUserId,
    required bool inReviewThread,
  });

  /// Claims an inbound conversation comment with the bot's 👀, on a `bot`
  /// token bounded by [asUserId]. Throws when the reaction could not be
  /// left.
  Future<GitHubReactionClaim> claimIssueComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  });

  /// Claims an inbound inline review comment with the bot's 👀, bounded by
  /// [asUserId].
  Future<GitHubReactionClaim> claimReviewComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  });

  /// Claims a labelled PR with the bot's 👀 on the PR itself, bounded by
  /// [asUserId].
  Future<GitHubReactionClaim> claimPullRequest(
    String owner,
    String repo,
    int prNumber, {
    required String asUserId,
  });

  /// Posts a top-level comment on the PR conversation timeline with a `bot`
  /// token bounded by [actingUserId].
  Future<void> postConversationComment(
    String owner,
    String repo, {
    required int prNumber,
    required String body,
    required String actingUserId,
  });

  /// Replies inside an existing inline review-comment thread with a `bot`
  /// token bounded by [actingUserId].
  Future<void> replyInReviewThread(
    String owner,
    String repo, {
    required int prNumber,
    required int parentCommentId,
    required String body,
    required String actingUserId,
  });

  /// Whether every GitHub App installation the workspace sees is suspended.
  /// The poller idles on this (the bot cannot converse) and re-checks at its
  /// idle cadence so a resume lights the lane back up. False when there is
  /// no app, or none installed — that is a missing identity, not a paused
  /// one.
  Future<bool> allInstallationsSuspended();

  /// Account logins whose GitHub App installation is currently suspended.
  /// Comment sweeps and searches for those owners are skipped: minting a
  /// token for them only 403s.
  Future<Set<String>> suspendedOwners();
}

/// Mints a one-repository token for [owner]/[repo] at [scope] bounded by
/// [actingUserId]. Throws `GitHubScopeRefused`.
typedef GitHubScopedMint =
    Future<GitHubScopedGrant> Function(
      String owner,
      String repo, {
      required GitHubTokenScope scope,
      required String actingUserId,
    });

/// Production gateway for one workspace, over its bot presence and its
/// one-repository automation clients.
///
/// The candidate search is GraphQL on each linked repository's own
/// one-repository token (`GitHubClients.forRepo`), never a person's sign-in:
/// one search per linked repository under an owner the App is installed on
/// and not suspended there.
class WorkspaceGitHubPrConversationGateway
    implements GitHubPrConversationGateway {
  /// Creates a [WorkspaceGitHubPrConversationGateway].
  ///
  /// `clientForOwner` is the workspace's automation client for an owner,
  /// bounded by `actingUserId` when given; `clientForRepo` its client for one
  /// repository; `linkedRepos` the workspace's linked GitHub repositories;
  /// `mint` is the workspace's scoped-token broker.
  WorkspaceGitHubPrConversationGateway({
    required this._presence,
    required this._lane,
    required this._clientForOwner,
    required this._clientForRepo,
    required this._linkedRepos,
    required this._mint,
    this._reviewLabel = kGithubPrReviewLabel,
    this._onWarning,
  });

  final Future<GitHubBotPresence?> Function() _presence;
  final Future<GitHubLane> Function() _lane;
  final GitHubApiClient Function(String owner, {String? actingUserId})
  _clientForOwner;
  final GitHubApiClient Function(String owner, String repo) _clientForRepo;
  final Future<List<({String owner, String repo})>> Function() _linkedRepos;
  final GitHubScopedMint _mint;
  final String _reviewLabel;
  final void Function(String message)? _onWarning;

  @override
  Future<GitHubConversationIdentity?> identity() async {
    final presence = await _presence();
    if (presence == null || presence.botLogin.isEmpty) {
      return null;
    }
    return GitHubConversationIdentity(
      botLogin: presence.botLogin,
      slug: presence.slug,
      lane: await _lane(),
    );
  }

  @override
  Future<bool> allInstallationsSuspended() async =>
      (await _presence())?.allSuspended ?? false;

  @override
  Future<Set<String>> suspendedOwners() async =>
      (await _presence())?.suspendedOwners ?? const {};

  @override
  Future<BotConversationCandidates> searchCandidates({DateTime? since}) async {
    final presence = await _presence();
    final botLogin = presence?.botLogin ?? '';
    if (presence == null || botLogin.isEmpty) {
      return BotConversationCandidates.empty;
    }
    final live = {
      for (final owner in presence.owners)
        if (owner.isNotEmpty &&
            !presence.suspendedOwners.contains(owner.toLowerCase()))
          owner.toLowerCase(): owner,
    };
    if (live.isEmpty) {
      return BotConversationCandidates.empty;
    }
    var found = BotConversationCandidates.empty;
    final List<({String owner, String repo})> linked;
    try {
      linked = await _linkedRepos();
    } on Object catch (e) {
      _onWarning?.call('github_pr_conversation: listing repos failed: $e');
      return BotConversationCandidates.empty;
    }
    for (final link in linked) {
      if (!live.containsKey(link.owner.toLowerCase())) {
        continue;
      }
      try {
        // Each repository's own token: the bot sees what it was installed
        // on, and a repository it cannot reach fails alone.
        found = found.followedBy(
          await _clientForRepo(
            link.owner,
            link.repo,
          ).graphql.searchBotConversationCandidates(
            botLogin: botLogin,
            label: _reviewLabel,
            since: since,
            repoFullName: '${link.owner}/${link.repo}',
          ),
        );
      } on Object catch (e) {
        _onWarning?.call(
          'github_pr_conversation: search in ${link.owner}/${link.repo} '
          'failed: $e',
        );
      }
    }
    return found.where((pr) => live.containsKey(pr.owner.toLowerCase()));
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
  ) => _clientForOwner(
    owner,
  ).pr.listPullRequestReviewComments(owner, repo, prNumber);

  @override
  Future<GitHubPrActor?> latestLabeler(
    String owner,
    String repo,
    int prNumber, {
    String label = kGithubPrReviewLabel,
  }) async {
    final events = await _clientForOwner(
      owner,
    ).pr.listIssueEvents(owner, repo, prNumber);
    for (final event in events.reversed) {
      final actor = event.actor;
      if (event.event == 'labeled' &&
          event.label?.name.toLowerCase() == label.toLowerCase() &&
          actor != null) {
        return actor.id <= 0
            ? null
            : GitHubPrActor(accountId: actor.id, login: actor.login);
      }
    }
    return null;
  }

  @override
  Future<bool> canPostAs(
    String owner,
    String repo, {
    required String actingUserId,
    required bool inReviewThread,
  }) async {
    final scope = inReviewThread
        ? GitHubTokenScope.bot
        : GitHubTokenScope.comment;
    try {
      final grant = await _mint(
        owner,
        repo,
        scope: scope,
        actingUserId: actingUserId,
      );
      return grant.scope == scope;
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: no ${scope.wire} token for $owner/$repo '
        'bounded by $actingUserId: $e',
      );
      return false;
    }
  }

  @override
  Future<GitHubReactionClaim> claimIssueComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  }) async => _claim(
    await _clientForOwner(
      owner,
      actingUserId: asUserId,
    ).pr.createIssueCommentReaction(
      owner,
      repo,
      commentId: commentId,
      content: 'eyes',
    ),
  );

  @override
  Future<GitHubReactionClaim> claimReviewComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  }) async => _claim(
    await _clientForOwner(
      owner,
      actingUserId: asUserId,
    ).pr.createReviewCommentReaction(
      owner,
      repo,
      commentId: commentId,
      content: 'eyes',
    ),
  );

  @override
  Future<GitHubReactionClaim> claimPullRequest(
    String owner,
    String repo,
    int prNumber, {
    required String asUserId,
  }) async => _claim(
    await _clientForOwner(owner, actingUserId: asUserId).pr.createIssueReaction(
      owner,
      repo,
      issueNumber: prNumber,
      content: 'eyes',
    ),
  );

  static GitHubReactionClaim _claim(GitHubReaction reaction) => reaction.created
      ? GitHubReactionClaim.claimed
      : GitHubReactionClaim.alreadyClaimed;

  @override
  Future<void> postConversationComment(
    String owner,
    String repo, {
    required int prNumber,
    required String body,
    required String actingUserId,
  }) async {
    await _clientForOwner(
      owner,
      actingUserId: actingUserId,
    ).pr.createIssueComment(owner, repo, prNumber: prNumber, body: body);
  }

  @override
  Future<void> replyInReviewThread(
    String owner,
    String repo, {
    required int prNumber,
    required int parentCommentId,
    required String body,
    required String actingUserId,
  }) async {
    await _clientForOwner(
      owner,
      actingUserId: actingUserId,
    ).pr.replyToReviewComment(
      owner,
      repo,
      prNumber: prNumber,
      parentCommentId: parentCommentId,
      body: body,
    );
  }
}
