import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_infra/cc_infra.dart'
    show
        GitHubApiClient,
        GitHubIssueComment,
        GitHubReaction,
        GitHubReviewComment,
        GitHubViewerPr;
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

  /// The App's bot account (`<slug>[bot]`): loop guard and mention alias.
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

  /// The person had already left it (HTTP 200): another server of theirs,
  /// or an earlier attempt, owns the work.
  alreadyClaimed,
}

/// The GitHub operations the PR-conversation surface needs, as one seam so the
/// bridge and poller run their whole behaviour against an in-memory fake.
///
/// One gateway serves exactly one workspace: reads ride that workspace's
/// one-repository tokens bounded by its accountable human, replies are
/// bounded by the member who asked, and claims are that member's own
/// reaction. There is no server-wide identity to fall back to.
abstract interface class GitHubPrConversationGateway {
  /// The bot and lane the workspace converses as, or null when it has no
  /// GitHub lane (the conversation surface idles).
  Future<GitHubConversationIdentity?> identity();

  /// Open PRs addressed via @usectrl or the App bot's compatible mentions,
  /// and PRs carrying the configured review label. [since] bounds only
  /// mention lanes; the label lane's membership is itself trigger state.
  Future<
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> botMentioned,
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

  /// Who most recently added [label] to the PR (its latest `labeled` issue
  /// event), or null when no such event is visible.
  Future<GitHubPrActor?> latestLabeler(
    String owner,
    String repo,
    int prNumber, {
    String label,
  });

  /// Whether this server can mint a `bot` token for [owner]/[repo] bounded
  /// by [actingUserId]: the App is installed there and that member can push.
  /// A token clamped below `bot` (no push) is a refusal.
  Future<bool> canPostAs(
    String owner,
    String repo, {
    required String actingUserId,
  });

  /// Claims an inbound conversation comment with [asUserId]'s own 👀.
  /// Throws when the reaction could not be left.
  Future<GitHubReactionClaim> claimIssueComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  });

  /// Claims an inbound inline review comment with [asUserId]'s own 👀.
  Future<GitHubReactionClaim> claimReviewComment(
    String owner,
    String repo,
    int commentId, {
    required String asUserId,
  });

  /// Claims a labelled PR with [asUserId]'s own 👀 on the PR itself.
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
/// per-owner GitHub clients.
///
/// Search coverage is the subtle part: a token only sees the repositories of
/// one installation, so a single client would silently miss every PR under
/// the bot's other installations. The candidate search therefore runs once
/// per installed account, each on that owner's client, and merges the lanes
/// deduplicated by PR. A failing owner is skipped rather than failing the
/// sweep — partial coverage beats none, and the next sweep retries.
class WorkspaceGitHubPrConversationGateway
    implements GitHubPrConversationGateway {
  /// Creates a [WorkspaceGitHubPrConversationGateway].
  ///
  /// `clientForOwner` is the workspace's automation client for an owner,
  /// bounded by `actingUserId` when given; `personClient` is a member's own
  /// sign-in; `mint` is the workspace's scoped-token broker.
  WorkspaceGitHubPrConversationGateway({
    required this._presence,
    required this._lane,
    required this._clientForOwner,
    required this._personClient,
    required this._mint,
    this._reviewLabel = kGithubPrReviewLabel,
    this._onWarning,
  });

  final Future<GitHubBotPresence?> Function() _presence;
  final Future<GitHubLane> Function() _lane;
  final GitHubApiClient Function(String owner, {String? actingUserId})
  _clientForOwner;
  final GitHubApiClient Function(String userId) _personClient;
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
  Future<
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> botMentioned,
      List<GitHubViewerPr> shortMentioned,
      List<GitHubViewerPr> labeled,
    })
  >
  searchCandidates({DateTime? since}) async {
    final presence = await _presence();
    final botLogin = presence?.botLogin ?? '';
    if (presence == null || botLogin.isEmpty) {
      return (
        mentioned: const <GitHubViewerPr>[],
        botMentioned: const <GitHubViewerPr>[],
        shortMentioned: const <GitHubViewerPr>[],
        labeled: const <GitHubViewerPr>[],
      );
    }
    final mentioned = <String, GitHubViewerPr>{};
    final botMentioned = <String, GitHubViewerPr>{};
    final shortMentioned = <String, GitHubViewerPr>{};
    final labeled = <String, GitHubViewerPr>{};
    for (final owner in presence.owners) {
      if (owner.isEmpty ||
          presence.suspendedOwners.contains(owner.toLowerCase())) {
        continue;
      }
      try {
        final result = await _clientForOwner(owner).graphql
            .searchBotConversationCandidates(
              botLogin: botLogin,
              label: _reviewLabel,
              since: since,
            );
        for (final pr in result.mentioned) {
          mentioned[pr.key] = pr;
        }
        for (final pr in result.botMentioned) {
          botMentioned[pr.key] = pr;
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
      botMentioned: botMentioned.values.toList(growable: false),
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
  }) async {
    try {
      final grant = await _mint(
        owner,
        repo,
        scope: GitHubTokenScope.bot,
        actingUserId: actingUserId,
      );
      return grant.scope == GitHubTokenScope.bot;
    } on Object catch (e) {
      _onWarning?.call(
        'github_pr_conversation: no bot token for $owner/$repo bounded by '
        '$actingUserId: $e',
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
    await _personClient(asUserId).pr.createIssueCommentReaction(
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
    await _personClient(asUserId).pr.createReviewCommentReaction(
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
    await _personClient(asUserId).pr.createIssueReaction(
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
