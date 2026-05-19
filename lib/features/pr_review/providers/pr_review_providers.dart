import 'dart:async';

import 'package:control_center/core/domain/entities/review_channel_association.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/data/providers/github_vcs_provider.dart';
import 'package:control_center/features/pr_review/data/repositories/cached_pr_review_repository.dart';
import 'package:control_center/features/pr_review/data/services/dispatch_reviewers_service.dart';
import 'package:control_center/features/pr_review/data/sources/local_git_pr_diff_source.dart';
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/issue_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:control_center/features/pr_review/domain/usecases/review_pull_request_use_case.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [DispatchReviewersService] shared by the MCP tool and any
/// pipeline step that fans out specialist reviewers.
final dispatchReviewersServiceProvider = Provider<DispatchReviewersService>((ref) {
  return DispatchReviewersService(
    agents: ref.watch(agentRepositoryProvider),
    messaging: ref.watch(messagingRepositoryProvider),
    reviewChannels: ref.watch(reviewChannelRepositoryProvider),
    messagingPort: ref.watch(messagingServiceProvider),
    workspaces: ref.watch(workspaceRepositoryProvider),
    filesystemPort: ref.watch(workspaceFilesystemPortProvider),
  );
});

/// Provides the [LocalGitPrDiffSource] (host-neutral, shared across repos).
final localGitDiffSourceProvider = Provider<LocalGitPrDiffSource>((ref) {
  return LocalGitPrDiffSource(
    git: ref.watch(gitCommandPortProvider),
    filesystem: ref.watch(workspaceFilesystemPortProvider),
    githubToken: ref.watch(githubAuthTokenProvider),
    rift: ref.watch(riftClientProvider),
  );
});

/// Provides the VCS provider registry.
final vcsProviderRegistryProvider = Provider<VcsProviderRegistry>((ref) {
  final gitHubFactory = GitHubVcsProviderFactory(
    cacheDao: ref.watch(cacheDaoProvider),
    draftDao: ref.watch(reviewDaoProvider),
    gitHubClient: ref.watch(githubApiClientProvider),
    localGitSource: ref.watch(localGitDiffSourceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
  return VcsProviderRegistry([gitHubFactory]);
});

/// Provides the cached PR review repository.
final prReviewRepositoryProvider = Provider<PrReviewRepository>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  final repo = ref.watch(activeRepoProvider);
  final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
  if (!isAuthed || workspace == null || repo == null) {
    return const EmptyPrReviewRepository();
  }
  final registry = ref.watch(vcsProviderRegistryProvider);
  return registry.resolve(VcsProviderContext(
    repo: repo,
    workspaceId: workspace.id,
  ));
});

/// Provides the full [PrFilesLoad] stream so the UI can react to clone
/// progress (phase, message) as well as the file list itself.
final prFilesLoadProvider =
    StreamProvider.autoDispose.family<PrFilesLoad, int>((ref, prNumber) {
  final repo = ref.watch(prReviewRepositoryProvider);
  if (repo is CachedPrReviewRepository) {
    return repo.watchFilesLoad(prNumber);
  }
  // Fallback: wrap the plain files stream with a completed load.
  return repo.watchFiles(prNumber).map(
    (files) => PrFilesLoad(files: files, isComplete: true),
  );
});

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
      if (key.owner.isEmpty || key.repo.isEmpty) {
        return (body: '', bodyHtml: null, changedFiles: 0, commitsCount: 0);
      }
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      try {
        final gh = await ref
            .read(githubApiClientProvider)
            .pr
            .getPullRequest(
              key.owner,
              key.repo,
              key.number,
              cancelToken: cancelToken,
            );
        return (
          body: gh?.body ?? '',
          bodyHtml: gh?.bodyHtml,
          changedFiles: gh?.changedFiles ?? 0,
          commitsCount: gh?.commitsCount ?? 0,
        );
      } catch (_) {
        return (body: '', bodyHtml: null, changedFiles: 0, commitsCount: 0);
      }
    });

final prDiffProvider = StreamProvider.autoDispose.family<String, int>((ref, prNumber) {
  return ref.watch(prReviewRepositoryProvider).watchDiff(prNumber);
});

/// Stream of changed files for a PR.
///
/// Bridges from [prFilesLoadProvider] via [ref.listen] so the clone/compute
/// pipeline only runs ONCE, regardless of how many widgets watch either
/// provider. Emits only when the file list is non-empty.
final prFilesProvider = StreamProvider.autoDispose.family<List<PrFile>, int>((
  ref,
  prNumber,
) {
  final controller = StreamController<List<PrFile>>();
  ref.onDispose(controller.close);

  ref.listen<AsyncValue<PrFilesLoad>>(
    prFilesLoadProvider(prNumber),
    (_, next) {
      final files = next.value?.files;
      if (files != null && files.isNotEmpty && !controller.isClosed) {
        controller.add(List<PrFile>.unmodifiable(files));
      }
      final error = next.error;
      if (error != null && !controller.isClosed) {
        controller.addError(error, next.stackTrace);
      }
    },
  );

  return controller.stream;
});

/// Pr file content key.
typedef PrFileContentKey = ({String path, String ref});

/// Stream of full file content at a specific ref.
final prFileContentProvider = StreamProvider.autoDispose.family<String, PrFileContentKey>((
  ref,
  key,
) {
  return ref
      .watch(prReviewRepositoryProvider)
      .watchFileContent(key.path, key.ref);
});

/// Stream of commits in a PR.
final prCommitsProvider = StreamProvider.autoDispose.family<List<PrCommit>, int>((
  ref,
  prNumber,
) {
  return ref.watch(prReviewRepositoryProvider).watchCommits(prNumber);
});

/// Stream of files changed in a single commit.
final prCommitFilesProvider = StreamProvider.autoDispose.family<List<PrFile>, String>((
  ref,
  sha,
) {
  return ref.watch(prReviewRepositoryProvider).watchCommitFiles(sha);
});

/// Stream of review submissions for a PR.
final prReviewsProvider = StreamProvider.autoDispose.family<List<PrReviewSubmission>, int>((
  ref,
  prNumber,
) {
  return ref.watch(prReviewRepositoryProvider).watchReviews(prNumber);
});

/// Stream of enriched reviewers (users + teams, with code-owner flags and the
/// team↔member review merge) for a PR. Feeds the detail sidebar's reviewer rail.
final prReviewersProvider =
    StreamProvider.autoDispose.family<List<PrReviewer>, int>((ref, prNumber) {
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
/// body editor. Best-effort and auto-disposing; debounced by the caller.
final issueSearchProvider = FutureProvider.autoDispose
    .family<List<({int number, String title})>, IssueSearchKey>((ref, key) {
  if (key.owner.isEmpty || key.repo.isEmpty) {
    return Future.value(const []);
  }
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.read(githubApiClientProvider).pr.searchIssues(
        key.owner,
        key.repo,
        key.query,
        cancelToken: cancelToken,
      );
});

/// Stream of inline review comments for a PR.
final prReviewCommentsProvider =
    StreamProvider.autoDispose.family<List<PrCodeReviewComment>, int>((ref, prNumber) {
      return ref
          .watch(prReviewRepositoryProvider)
          .watchReviewComments(prNumber);
    });

/// Stream of top-level issue comments for a PR.
final prIssueCommentsProvider = StreamProvider.autoDispose.family<List<IssueComment>, int>((
  ref,
  prNumber,
) {
  return ref.watch(prReviewRepositoryProvider).watchIssueComments(prNumber);
});

/// Stream of CI check runs for a PR.
final prCheckRunsProvider = StreamProvider.autoDispose.family<List<CheckRun>, int>((
  ref,
  prNumber,
) {
  return ref.watch(prReviewRepositoryProvider).watchCheckRuns(prNumber);
});

final prOptimisticReviewStateProvider =
    NotifierProvider<PrOptimisticReviewStateNotifier, Map<int, PrReviewSubmissionState?>>(
  PrOptimisticReviewStateNotifier.new,
);

class PrOptimisticReviewStateNotifier extends Notifier<Map<int, PrReviewSubmissionState?>> {
  static const _maxEntries = 50;

  @override
  Map<int, PrReviewSubmissionState?> build() => {};

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

final reviewPullRequestUseCaseProvider = Provider<ReviewPullRequestUseCase>(
  (ref) => ReviewPullRequestUseCase(
    repository: ref.watch(prReviewRepositoryProvider),
  ),
);

final reviewChannelForPrProvider =
    StreamProvider.autoDispose.family<ReviewChannelAssociation?, String>(
  (ref, prNodeId) {
    // Scope the lookup to the active workspace: PR node ids are global, so an
    // unscoped lookup could surface another workspace's review channel.
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return Stream.value(null);
    }
    return ref
        .watch(reviewChannelRepositoryProvider)
        .watchByPr(workspaceId, prNodeId);
  },
);


/// Repo permission key.
typedef RepoKey = ({String owner, String repo});

/// Fetches the current user's permission level on a repo.
///
/// Returns one of: "admin", "write", "read", "none".
/// Cached per repo, auto-disposes when no longer watched.
final repoPermissionProvider =
    FutureProvider.autoDispose.family<String, RepoKey>((ref, key) async {
  final client = ref.watch(githubApiClientProvider);
  final user = await ref.watch(githubUserProvider.future);
  if (user == null) return 'none';
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  try {
    return await client.content.getCollaboratorPermission(
      key.owner,
      key.repo,
      user.login,
      cancelToken: cancelToken,
    );
  } on Exception {
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
  final login = ref.watch(githubUserProvider).maybeWhen(
        data: (user) => user?.login.toLowerCase() ?? '',
        orElse: () => '',
      );
  final isAuthor = login.isNotEmpty && pr.author?.login.toLowerCase() == login;
  final parts = pr.repoFullName.split('/');
  final owner = parts.isNotEmpty ? parts[0] : '';
  final repoName = parts.length > 1 ? parts[1] : '';
  final hasWriteAccess = ref
          .watch(repoPermissionProvider((owner: owner, repo: repoName)))
          .whenOrNull(data: (perm) => perm == 'admin' || perm == 'write') ??
      false;
  return isAuthor || hasWriteAccess;
});
