import 'package:cc_domain/core/domain/entities/repo.dart' show Repo;
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// One linked repo's open pull requests, as returned by [OpenPrListRepository].
///
/// Keyed by [repoId] (not the full [Repo]) so the presentation layer joins it
/// back to the workspace's repo entities it already holds — the wire stays thin
/// and the client owns the canonical [Repo] rows.
class RepoOpenPrs {
  /// Creates a [RepoOpenPrs] group.
  const RepoOpenPrs({
    required this.repoId,
    required this.hasMore,
    required this.prs,
    this.totalCount,
  });

  /// The linked repo's id (matches a `Repo.id` in the active workspace).
  final String repoId;

  /// Whether the repo has more open PRs beyond this first page.
  final bool hasMore;

  /// The repo's open PR count across every page, as the forge reports it.
  /// Null when the forge gives no total (then only [prs] is known).
  final int? totalCount;

  /// The open pull requests for this repo, checks already overlaid.
  final List<PullRequest> prs;
}

/// The workspace's open pull requests across its linked GitHub repos, fetched
/// SERVER-SIDE on the server's GitHub client.
class WorkspaceOpenPrs {
  /// Creates a [WorkspaceOpenPrs] result.
  const WorkspaceOpenPrs({
    required this.authenticated,
    required this.groups,
    this.sweepInFlight = false,
    this.repoAccess = const [],
    this.hiddenRepos = const [],
  });

  /// An empty, authenticated result (server has a token, no PRs / no repos).
  static const WorkspaceOpenPrs empty = WorkspaceOpenPrs(
    authenticated: true,
    groups: [],
  );

  /// Whether the SERVER holds a usable GitHub token. When false the UI shows a
  /// "connect GitHub on the server" state instead of an empty list — the thin
  /// client never holds a token of its own.
  final bool authenticated;

  /// The per-repo open-PR groups.
  final List<RepoOpenPrs> groups;

  /// Whether a server-side GitHub sweep is currently running for the
  /// workspace. The snapshot itself arrives instantly (persisted), so this is
  /// the only signal that fresher data is still being fetched — it backs the
  /// client's refresh affordance between subscribe-kick and sweep landing.
  /// Only the live [OpenPrListRepository.watchOpenForWorkspace] stream
  /// carries it; one-shot reads default to false.
  final bool sweepInFlight;

  /// Linked repos automation cannot reach, and why. Their groups are absent
  /// from [groups]; the UI explains why and offers the fix instead of
  /// showing a silently empty queue.
  final List<RepoAccessIssue> repoAccess;

  /// Linked repos left out of the caller's view, as counts per forge and
  /// reason (never names): not signed in to that forge, no access on it, no
  /// grant here, or not checked yet.
  final List<HiddenRepos> hiddenRepos;
}

/// The server's live "needs your review" count (`pr.watchNeedsMyReviewCount`)
/// across every forge, plus what the caller cannot see.
class NeedsMyReviewCount {
  /// Creates a [NeedsMyReviewCount].
  const NeedsMyReviewCount({required this.count, this.hiddenRepos = const []});

  /// Nothing waiting, nothing hidden.
  static const NeedsMyReviewCount zero = NeedsMyReviewCount(count: 0);

  /// Open pull requests requesting the caller's (or their team's) review.
  final int count;

  /// Linked repos left out of [count].
  final List<HiddenRepos> hiddenRepos;
}

/// Reads the active workspace's open pull requests over RPC.
///
/// The thin client holds no forge token; the server fetches and enriches the
/// PRs of the repos the caller may see (their own grant and forge sign-in) and
/// this repository maps the wire result back to domain entities. [watchOpenForWorkspace] is the live subscription behind the PR
/// list; [listOpenForWorkspace] remains as the one-shot fallback.
abstract interface class OpenPrListRepository {
  /// Fetches the open PRs across [workspaceId]'s linked GitHub repos.
  Future<WorkspaceOpenPrs> listOpenForWorkspace(String workspaceId);

  /// Watches the open PRs across [workspaceId]'s linked GitHub repos — the
  /// live counterpart of [listOpenForWorkspace]. The server's open-PR poller
  /// pushes a fresh snapshot whenever GitHub-side state changes (new PR,
  /// merge/close, update, CI status), so subscribers never need a refresh
  /// button.
  Stream<WorkspaceOpenPrs> watchOpenForWorkspace(String workspaceId);

  /// Asks the server to sweep GitHub for [workspaceId] right now (an explicit
  /// user refresh). The result arrives over [watchOpenForWorkspace].
  Future<void> refreshOpenForWorkspace(String workspaceId);

  /// Watches the linked repos automation cannot reach in [workspaceId] — the
  /// lite feed behind the repos-settings notice, so that surface never holds
  /// the full open-PR payload just to explain an access gap. The same list
  /// rides [WorkspaceOpenPrs.repoAccess] on the full watch.
  Stream<List<RepoAccessIssue>> watchRepoAccessForWorkspace(String workspaceId);

  /// Live count of open PRs requesting the caller's review across every
  /// forge of [workspaceId]'s linked repos.
  ///
  /// The lite feed behind the inbox badge on desktop and phone: the server
  /// computes it, so an always-on badge never has to hold the full PR list
  /// (titles, bodies, checks) in client memory the way watching
  /// [watchOpenForWorkspace] would.
  Stream<NeedsMyReviewCount> watchNeedsMyReviewCount(String workspaceId);

  /// Open PRs requesting the caller's review across [workspaceId]'s linked
  /// repos they may see (the dashboard's priority reviews), each tagged with its repo id so
  /// the caller joins it back to the workspace's [Repo] entities.
  Future<List<({String repoId, PullRequest pr})>> reviewRequestedForWorkspace(
    String workspaceId,
  );

  /// `"<owner/repo>#<number>"` keys of the open PRs the caller has already
  /// reviewed across [workspaceId]'s linked repos they may see (the PR-list "reviewed by me"
  /// overlay).
  Future<Set<String>> reviewedByKeysForWorkspace(String workspaceId);

  /// Merged/closed PRs the caller authored across [workspaceId]'s linked
  /// repos (first page per repo), grouped by repo id. The server resolves
  /// the caller's account on each forge.
  Future<List<RepoOpenPrs>> closedByAuthorForWorkspace(String workspaceId);

  /// All-state GitHub PR activity authored by [login] across [workspaceId]'s
  /// linked repositories, including exact outcome counts and delivery metrics.
  Future<GitHubProfileActivity> profileActivityForUser(
    String workspaceId,
    String login,
  );

  /// All-state GitHub PR activity authored by members of [organization]/[slug]
  /// across [workspaceId]'s linked repositories.
  ///
  /// Team membership is resolved by the server on the calling user's GitHub
  /// credential. The client never supplies a member list that could drift from
  /// GitHub or silently omit private members.
  Future<GitHubProfileActivity> profileActivityForTeam(
    String workspaceId,
    String organization,
    String slug,
  );
}
