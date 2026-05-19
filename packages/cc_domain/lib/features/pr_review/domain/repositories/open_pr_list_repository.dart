import 'package:cc_domain/core/domain/entities/repo.dart' show Repo;
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
  });

  /// The linked repo's id (matches a `Repo.id` in the active workspace).
  final String repoId;

  /// Whether the repo has more open PRs beyond this first page.
  final bool hasMore;

  /// The open pull requests for this repo, checks already overlaid.
  final List<PullRequest> prs;
}

/// The workspace's open pull requests across its linked GitHub repos, fetched
/// SERVER-SIDE on the host's `gh`-authenticated client.
class WorkspaceOpenPrs {
  /// Creates a [WorkspaceOpenPrs] result.
  const WorkspaceOpenPrs({
    required this.authenticated,
    required this.groups,
    this.sweepInFlight = false,
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
}

/// Reads the active workspace's open pull requests over RPC.
///
/// The thin client holds no GitHub token; the gh-authenticated server fetches +
/// enriches the PRs and this repository maps the wire result back to domain
/// entities. [watchOpenForWorkspace] is the live subscription behind the PR
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

  /// Live count of open PRs requesting the server user's review across
  /// [workspaceId]'s linked repos.
  ///
  /// The lite feed behind the sidebar's inbox badge: the count is computed
  /// server-side from the open-PR poller's snapshot, so an always-on badge
  /// never has to hold the full PR list (titles, bodies, checks) in client
  /// memory the way watching [watchOpenForWorkspace] would.
  Stream<int> watchNeedsMyReviewCount(String workspaceId);

  /// Open PRs requesting the server user's review across [workspaceId]'s linked
  /// repos (the dashboard's priority reviews), each tagged with its repo id so
  /// the caller joins it back to the workspace's [Repo] entities.
  Future<List<({String repoId, PullRequest pr})>> reviewRequestedForWorkspace(
    String workspaceId,
  );

  /// `"<owner/repo>#<number>"` keys of the open PRs the server user has already
  /// reviewed across [workspaceId]'s linked repos (the PR-list "reviewed by me"
  /// overlay).
  Future<Set<String>> reviewedByKeysForWorkspace(String workspaceId);

  /// Merged/closed PRs authored by [login] across [workspaceId]'s linked repos
  /// (first page per repo), grouped by repo id (the user profile's history).
  Future<List<RepoOpenPrs>> closedByAuthorForWorkspace(
    String workspaceId,
    String login,
  );
}
