import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/review_pull_request_use_case.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the VCS provider registry — flipped to the cc_data
/// [RpcVcsProviderFactory] over the desktop's in-process RPC server (the
/// composition flip). The UI resolves PR-review repositories over RPC; the
/// host owns GitHub auth, the SWR disk cache, the diff sources, and draft
/// persistence. Server-side EXECUTION wires the Dao-backed
/// `GitHubVcsProviderFactory` into the catalog instead (see
/// `remoteRpcCatalogProvider`).
final vcsProviderRegistryProvider = Provider<VcsProviderRegistry>((ref) {
  return VcsProviderRegistry([
    RpcVcsProviderFactory(ref.watch(rpcClientProvider)),
  ]);
});

/// The `(owner, repo)` an open PR-detail view is pinned to, taken from its URL.
typedef PrDetailRepoScope = ({String owner, String repo});

/// Holds the repo the PR-detail surface is currently scoped to, pushed from the
/// route by `PullRequestDetailScreen`. PR numbers are unique only within a repo,
/// so the (number-keyed) detail provider graph must resolve its repository from
/// THIS — see [currentPrRepoProvider].
class PrDetailRepoScopeNotifier extends Notifier<PrDetailRepoScope?> {
  @override
  PrDetailRepoScope? build() => null;

  /// Pins the PR-review surface to [scope] (or clears it with `null`). The
  /// screen sets this from a deferred microtask, which may run after the
  /// container is torn down (test teardown / app shutdown) — guard the Ref.
  void set(PrDetailRepoScope? scope) {
    if (!ref.mounted) {
      return;
    }
    state = scope;
  }

  /// Releases the pin only if it still equals [scope]. Navigating PR→PR sets
  /// the new screen's scope before the old screen's release runs, so an
  /// unconditional clear would clobber it.
  void release(PrDetailRepoScope scope) {
    if (!ref.mounted) {
      return;
    }
    if (state == scope) {
      state = null;
    }
  }
}

/// PR numbers are per-repo, so an open PR detail pins the PR-review surface to
/// the repo named in its URL. Null when no PR detail is open.
final prDetailRepoScopeProvider =
    NotifierProvider<PrDetailRepoScopeNotifier, PrDetailRepoScope?>(
      PrDetailRepoScopeNotifier.new,
    );

/// The [Repo] the PR-review surface operates on: the repo pinned by an open PR
/// detail (from its URL), or the workspace's active repo everywhere else.
///
/// PR numbers are unique only within a repo and the queue spans every linked
/// repo, so detail-scoped reads must resolve owner/repo from THIS rather than
/// [activeRepoProvider] (which a deep-link or reload may not match). When a
/// scope is set but its repo isn't resolvable yet (repos still loading), this
/// returns null rather than the active repo, so the surface never briefly loads
/// a *different* repo's PR of the same number.
final currentPrRepoProvider = Provider<Repo?>((ref) {
  final scope = ref.watch(prDetailRepoScopeProvider);
  if (scope == null) {
    return ref.watch(activeRepoProvider);
  }
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final repos =
      ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  final owner = scope.owner.toLowerCase();
  final name = scope.repo.toLowerCase();
  for (final r in repos) {
    if (r.githubOwner.toLowerCase() == owner &&
        r.githubRepoName.toLowerCase() == name) {
      return r;
    }
  }
  return null;
});

/// Provides the cached PR review repository.
///
/// Resolved over RPC ([RpcVcsProviderFactory]); GitHub auth lives on the HOST,
/// not this thin client, so this does NOT gate on a client-local token — the
/// server serves the PR-review surface from its own gh-authenticated client
/// (and degrades to an empty repository there when it holds no token). Gating on
/// the client token here would wrongly blank the PR detail page on web.
///
/// Scoped to [currentPrRepoProvider]: the open PR detail's repo (from its URL),
/// or the active repo elsewhere.
final prReviewRepositoryProvider = Provider<PrReviewRepository>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  final repo = ref.watch(currentPrRepoProvider);
  if (workspace == null || repo == null) {
    return const EmptyPrReviewRepository();
  }
  final registry = ref.watch(vcsProviderRegistryProvider);
  return registry.resolve(
    VcsProviderContext(repo: repo, workspaceId: workspace.id),
  );
});

/// Provides the full [PrFilesLoad] stream so the UI can react to clone
/// progress (phase, message) as well as the file list itself.
///
/// Over RPC the repository is the cc_data [RpcPrReviewRepository], whose domain
/// surface exposes only `watchFiles` (the host owns the clone/SWR machinery), so
/// this wraps that stream as a completed load. Clone-progress phases are not
/// streamed over the wire (a known limitation of the RPC PR-files path); the
/// final file list still arrives.
final prFilesLoadProvider = StreamProvider.autoDispose.family<PrFilesLoad, int>(
  (ref, prNumber) {
    return ref
        .watch(prReviewRepositoryProvider)
        .watchFiles(prNumber)
        .map((files) => PrFilesLoad(files: files, isComplete: true));
  },
);

/// Stream of pull request details by number.
final prDetailProvider = StreamProvider.autoDispose.family<PullRequest?, int>((
  ref,
  prNumber,
) {
  return ref.watch(prReviewRepositoryProvider).watchPullRequest(prNumber);
});

/// Identifies a PR by its own repo so it can be fetched independently of the
/// active repo.
typedef PeekContentKey = ({String owner, String repo, int number});

/// What the peek panel fetches on demand: the raw markdown `body` plus GitHub's
/// rendered `bodyHtml` (used to splice pre-signed attachment URLs), and the
/// peek-only metrics (`changedFiles`/`commitsCount`). These metrics are
/// deliberately NOT in the PR-list batch query — they're shown only here, so
/// they ride along on this same `full+json` call instead of being pulled
/// list-wide for every open PR.
typedef PeekContent = ({
  String body,
  String? bodyHtml,
  int changedFiles,
  int commitsCount,
});

/// Fetches a PR's description for an explicit `(owner, repo, number)` rather
/// than the active repo. The PR-list peek panel spans repos, so it can't reuse
/// [prDetailProvider] (active-repo-scoped) — and the list itself comes from a
/// GraphQL batch that omits `body`/`body_html` to stay cheap, so the peek has
/// no description to show until this runs.
///
/// One `full+json` REST call returns both: the `body` markdown and the
/// `body_html` that carries the pre-signed `private-user-images.*` URLs
/// `GitHubMarkdownBody` splices over the raw `github.com/user-attachments/*`
/// references — the only way inline screenshots in a private repo load with a
/// PAT. Returns an empty body on failure (the peek then shows "no description").
final peekPrContentProvider = FutureProvider.autoDispose
    .family<PeekContent, PeekContentKey>((ref, key) async {
      const empty = (
        body: '',
        bodyHtml: null,
        changedFiles: 0,
        commitsCount: 0,
      );
      if (key.owner.isEmpty || key.repo.isEmpty) {
        return empty;
      }
      try {
        // Fetched SERVER-SIDE over RPC (the thin client holds no GitHub token);
        // the host validates (owner, repo) is linked to the bound workspace.
        final data = await ref.watch(rpcClientProvider).call(
          'github.prContent',
          {'owner': key.owner, 'repo': key.repo, 'number': key.number},
        );
        final c = data['content'];
        if (c is! Map) {
          return empty;
        }
        final m = c.cast<String, dynamic>();
        return (
          body: m['body'] as String? ?? '',
          bodyHtml: m['body_html'] as String?,
          changedFiles: (m['changed_files'] as num?)?.toInt() ?? 0,
          commitsCount: (m['commits_count'] as num?)?.toInt() ?? 0,
        );
      } catch (_) {
        return empty;
      }
    });

/// Stream of the unified diff for a PR.
final prDiffProvider = StreamProvider.autoDispose.family<String, int>((
  ref,
  prNumber,
) {
  return ref.watch(prReviewRepositoryProvider).watchDiff(prNumber);
});

/// Stream of changed files for a PR.
///
/// Bridges from `prFilesLoadProvider` via `ref.listen` so the clone/compute
/// pipeline only runs ONCE, regardless of how many widgets watch either
/// provider. Emits only when the file list is non-empty.
final prFilesProvider = StreamProvider.autoDispose.family<List<PrFile>, int>((
  ref,
  prNumber,
) {
  final controller = StreamController<List<PrFile>>();
  ref.onDispose(controller.close);

  ref.listen<AsyncValue<PrFilesLoad>>(prFilesLoadProvider(prNumber), (_, next) {
    final files = next.value?.files;
    if (files != null && files.isNotEmpty && !controller.isClosed) {
      controller.add(List<PrFile>.unmodifiable(files));
    }
    final error = next.error;
    if (error != null && !controller.isClosed) {
      controller.addError(error, next.stackTrace);
    }
  });

  return controller.stream;
});

/// Pr file content key.
typedef PrFileContentKey = ({String path, String ref});

/// Stream of full file content at a specific ref.
final prFileContentProvider = StreamProvider.autoDispose
    .family<String, PrFileContentKey>((ref, key) {
      return ref
          .watch(prReviewRepositoryProvider)
          .watchFileContent(key.path, key.ref);
    });

/// Stream of commits in a PR.
final prCommitsProvider = StreamProvider.autoDispose
    .family<List<PrCommit>, int>((ref, prNumber) {
      return ref.watch(prReviewRepositoryProvider).watchCommits(prNumber);
    });

/// Stream of files changed in a single commit.
final prCommitFilesProvider = StreamProvider.autoDispose
    .family<List<PrFile>, String>((ref, sha) {
      return ref.watch(prReviewRepositoryProvider).watchCommitFiles(sha);
    });

/// Stream of review submissions for a PR.
final prReviewsProvider = StreamProvider.autoDispose
    .family<List<PrReviewSubmission>, int>((ref, prNumber) {
      return ref.watch(prReviewRepositoryProvider).watchReviews(prNumber);
    });

/// Stream of enriched reviewers (users + teams, with code-owner flags and the
/// team↔member review merge) for a PR. Feeds the detail sidebar's reviewer rail.
final prReviewersProvider = StreamProvider.autoDispose
    .family<List<PrReviewer>, int>((ref, prNumber) {
      return ref.watch(prReviewRepositoryProvider).watchReviewers(prNumber);
    });

/// Users who can be assigned / requested as individual reviewers on the active
/// repo. Backs the assignee and reviewer pickers (TTL-cached in the repo).
final assignableUsersProvider = FutureProvider.autoDispose<List<PrUser>>((ref) {
  return ref.watch(prReviewRepositoryProvider).listAssignableUsers();
});

/// Reviewer candidates (users + teams) for the reviewer picker.
final requestableReviewersProvider =
    FutureProvider.autoDispose<List<PrReviewerCandidate>>((ref) {
      return ref.watch(prReviewRepositoryProvider).listRequestableReviewers();
    });

/// Key for [issueSearchProvider]: the repo to search and the free-text query.
typedef IssueSearchKey = ({String owner, String repo, String query});

/// Searches issues + PRs in a repo for the `#`-reference autocomplete in the
/// body editor. Best-effort and auto-disposing; debounced by the caller. Runs
/// SERVER-SIDE over RPC (the thin client holds no GitHub token).
final issueSearchProvider = FutureProvider.autoDispose
    .family<List<({int number, String title})>, IssueSearchKey>((ref, key) async {
      if (key.owner.isEmpty || key.repo.isEmpty) {
        return const [];
      }
      try {
        final data = await ref.watch(rpcClientProvider).call(
          'github.searchIssues',
          {'owner': key.owner, 'repo': key.repo, 'query': key.query},
        );
        return [
          for (final i in (data['issues'] as List? ?? const []))
            (
              number: ((i as Map)['number'] as num?)?.toInt() ?? 0,
              title: i['title'] as String? ?? '',
            ),
        ];
      } catch (_) {
        return const [];
      }
    });

/// Stream of inline review comments for a PR.
final prReviewCommentsProvider = StreamProvider.autoDispose
    .family<List<PrCodeReviewComment>, int>((ref, prNumber) {
      return ref
          .watch(prReviewRepositoryProvider)
          .watchReviewComments(prNumber);
    });

/// Stream of top-level issue comments for a PR.
final prIssueCommentsProvider = StreamProvider.autoDispose
    .family<List<IssueComment>, int>((ref, prNumber) {
      return ref.watch(prReviewRepositoryProvider).watchIssueComments(prNumber);
    });

/// Stream of CI check runs for a PR.
final prCheckRunsProvider = StreamProvider.autoDispose
    .family<List<CheckRun>, int>((ref, prNumber) {
      return ref.watch(prReviewRepositoryProvider).watchCheckRuns(prNumber);
    });

/// Provider for optimistic review submission state, keyed by PR number.
final prOptimisticReviewStateProvider =
    NotifierProvider<
      PrOptimisticReviewStateNotifier,
      Map<int, PrReviewSubmissionState?>
    >(PrOptimisticReviewStateNotifier.new);

/// Notifier that tracks optimistic review submission states per PR.
class PrOptimisticReviewStateNotifier
    extends Notifier<Map<int, PrReviewSubmissionState?>> {
  static const _maxEntries = 50;

  @override
  /// Builds the initial empty review state map.
  Map<int, PrReviewSubmissionState?> build() => {};

  /// Sets the optimistic review state for a PR, evicting oldest on overflow.
  void set(int prNumber, PrReviewSubmissionState? value) {
    final map = Map<int, PrReviewSubmissionState?>.from(state);
    map.remove(prNumber);
    map[prNumber] = value;
    while (map.length > _maxEntries) {
      map.remove(map.keys.first);
    }
    state = Map.unmodifiable(map);
  }
}

/// Review action.
enum ReviewAction {
  /// Approve.
  approve,

  /// Request changes.
  requestChanges,

  /// Comment.
  comment,
}

/// Provider for the review pull request use case.
final reviewPullRequestUseCaseProvider = Provider<ReviewPullRequestUseCase>(
  (ref) => ReviewPullRequestUseCase(
    repository: ref.watch(prReviewRepositoryProvider),
  ),
);

/// Stream of the review channel association for a PR, scoped to the active workspace.
final reviewChannelForPrProvider = StreamProvider.autoDispose
    .family<ReviewChannelAssociation?, String>((ref, prNodeId) {
      // Scope the lookup to the active workspace: PR node ids are global, so an
      // unscoped lookup could surface another workspace's review channel.
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(null);
      }
      return ref
          .watch(reviewChannelRepositoryProvider)
          .watchByPr(workspaceId, prNodeId);
    });

/// Stream of the review channel association for a *channel* — the reverse of
/// [reviewChannelForPrProvider]. Used by the sidebar to resolve what (if any)
/// PR a conversation is about, without parsing the channel title. Local DB
/// stream, emits immediately.
final reviewChannelForChannelProvider = StreamProvider.autoDispose
    .family<ReviewChannelAssociation?, String>((ref, channelId) {
      return ref
          .watch(reviewChannelRepositoryProvider)
          .watchByChannel(channelId);
    });

/// Key for a repo-scoped PR review repository: the workspace plus the GitHub
/// `owner/repo` full name.
typedef RepoScopedPrReviewKey = ({String workspaceId, String repoFullName});

/// A SWR-cached [PrReviewRepository] bound to an explicit repo, independent of
/// the active repo. The sidebar spans repos, so it can't reuse
/// [prReviewRepositoryProvider] (active-repo-scoped); this resolves the right
/// repository for the channel's PR from its association. The disk SWR cache is
/// shared workspace-wide, so reads hit the same `prDetail` cache the detail
/// screen populates when one exists.
final repoScopedPrReviewRepositoryProvider = Provider.autoDispose
    .family<PrReviewRepository, RepoScopedPrReviewKey>((ref, key) {
      final slash = key.repoFullName.indexOf('/');
      if (slash <= 0 || slash == key.repoFullName.length - 1) {
        return const EmptyPrReviewRepository();
      }
      final owner = key.repoFullName.substring(0, slash);
      final repo = key.repoFullName.substring(slash + 1);
      // Flipped to RPC: the sidebar resolves a repo-scoped repository over the
      // in-process server, which owns the shared workspace-wide SWR disk cache —
      // so a read here hits the same `prDetail` cache the detail screen
      // populates. The host validates the (owner, repo) is linked to the bound
      // workspace before returning any row.
      return RpcPrReviewRepository(
        ref.watch(rpcClientProvider),
        workspaceId: key.workspaceId,
        owner: owner,
        repo: repo,
      );
    });

/// The GitHub [PullRequest] a channel's review is about, or null for non-review
/// channels. Served SWR: emits the cached PR detail first so the sidebar paints
/// immediately (cached → non-blocking), then revalidates from GitHub and emits
/// the fresh state if it changed. Never throws — a fetch failure leaves the
/// cached value in place, so the sidebar never breaks on a network hiccup.
final channelPrDetailProvider = StreamProvider.autoDispose
    .family<PullRequest?, String>((ref, channelId) {
      final assoc = ref.watch(reviewChannelForChannelProvider(channelId)).value;
      if (assoc == null) {
        return Stream.value(null);
      }
      final repo = ref.watch(
        repoScopedPrReviewRepositoryProvider((
          workspaceId: assoc.workspaceId,
          repoFullName: assoc.repoFullName,
        )),
      );
      return repo.watchPullRequest(assoc.prNumber);
    });

/// Repo permission key.
typedef RepoKey = ({String owner, String repo});

/// Fetches the current user's permission level on a repo.
///
/// Returns one of: "admin", "write", "read", "none".
/// Cached per repo, auto-disposes when no longer watched.
final repoPermissionProvider = FutureProvider.autoDispose
    .family<String, RepoKey>((ref, key) async {
      // Resolved SERVER-SIDE over RPC: the host uses ITS authenticated gh user
      // (the thin client holds no token) and validates (owner, repo) is linked
      // to the bound workspace.
      try {
        final data = await ref.watch(rpcClientProvider).call(
          'github.repoPermission',
          {'owner': key.owner, 'repo': key.repo},
        );
        return data['permission'] as String? ?? 'none';
      } catch (_) {
        return 'none';
      }
    });

/// Whether the current user may edit the given PR's title/body: the PR author,
/// or a user with write/admin permission on the repo. Mirrors the derivation
/// behind the title-bar merge/close actions.
final prCanEditProvider = Provider.autoDispose.family<bool, int>((
  ref,
  prNumber,
) {
  final pr = ref.watch(prDetailProvider(prNumber)).value;
  if (pr == null) {
    return false;
  }
  final login = ref
      .watch(githubUserProvider)
      .maybeWhen(
        data: (user) => user?.login.toLowerCase() ?? '',
        orElse: () => '',
      );
  final isAuthor = login.isNotEmpty && pr.author?.login.toLowerCase() == login;
  final parts = pr.repoFullName.split('/');
  final owner = parts.isNotEmpty ? parts[0] : '';
  final repoName = parts.length > 1 ? parts[1] : '';
  final hasWriteAccess =
      ref
          .watch(repoPermissionProvider((owner: owner, repo: repoName)))
          .whenOrNull(data: (perm) => perm == 'admin' || perm == 'write') ??
      false;
  return isAuthor || hasWriteAccess;
});
