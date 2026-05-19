import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/review_pull_request_use_case.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the VCS provider registry — flipped to the cc_data
/// [RpcForgeProviderFactory] over the desktop's in-process RPC server (the
/// composition flip). The UI resolves PR-review repositories over RPC; the
/// host owns GitHub auth, the SWR disk cache, the diff sources and draft
/// persistence. Server-side EXECUTION wires the Dao-backed
/// `GitHubForgeProviderFactory` into the catalog instead (see
/// `remoteRpcCatalogProvider`).
final forgeProviderRegistryProvider = Provider<ForgeProviderRegistry>((ref) {
  return ForgeProviderRegistry([
    RpcForgeProviderFactory(ref.watch(rpcClientProvider)),
  ]);
});

/// The `(owner, repo)` the open PR-detail surface is scoped to, taken from the
/// route's URL. PR numbers are unique only within a repo, so the (number-keyed)
/// detail provider graph resolves its repository from this — see
/// [currentPrRepoProvider].
typedef PrDetailRepoScope = ({String owner, String repo});

/// Holds the repo the PR-detail surface is currently scoped to.
///
/// Driven from the URL by `prDetailRouteScopeSyncProvider` — the same
/// URL-is-the-source-of-truth pattern `workspaceUrlSyncProvider` uses for the
/// active workspace: the sync writes the route's `(owner, repo)` here on every
/// navigation and `null` on any non-PR route.
///
/// It is deliberately NOT pushed from the screen's `initState`. go_router reuses
/// one `PullRequestDetailScreen` State across PR→PR hops (the page key is the
/// route *pattern*, not the resolved params), so `initState`/`dispose` never
/// re-run on a hop — an `initState` pin went stale on a cross-repo hop and the
/// number-keyed streams re-subscribed against the WRONG repo, flooding the API.
/// A single URL-driven writer has no staleness and no set/release race.
class PrDetailRepoScopeNotifier extends Notifier<PrDetailRepoScope?> {
  @override
  PrDetailRepoScope? build() => null;

  /// Sets the scope to [scope] (or clears it with `null`). Written only by the
  /// route→scope sync, from a deferred microtask that may run after the
  /// container is torn down (test teardown / app shutdown) — guard the Ref.
  /// Idempotent: an unchanged scope is a no-op (also lets a test pre-seed the
  /// same value without tripping the "modified a provider during build" guard).
  void set(PrDetailRepoScope? scope) {
    if (!ref.mounted) {
      return;
    }
    if (state == scope) {
      return;
    }
    state = scope;
  }
}

/// The repo `(owner, repo)` the open PR detail is scoped to (from the URL), or
/// null when no PR detail is open. Driven by `prDetailRouteScopeSyncProvider`.
final prDetailRepoScopeProvider =
    NotifierProvider<PrDetailRepoScopeNotifier, PrDetailRepoScope?>(
      PrDetailRepoScopeNotifier.new,
    );

/// The [Repo] an open PR detail is pinned to by its URL (`:owner/:repo`), or
/// null on every other route — and null too while the workspace's repos are
/// still loading, or when the pinned repo isn't linked to the active workspace.
///
/// **There is deliberately no fallback to the active repo.** A PR number is
/// meaningful only inside its repo, so every PR-number-keyed read resolves
/// through this. When the pin is gone the read must not happen at all rather
/// than be retried against whatever repo happens to be active: leaving the
/// detail route clears the scope one microtask *before* the screen is torn down,
/// so a fallback let the still-mounted, number-keyed streams re-subscribe
/// against another repo.
final prDetailRepoProvider = Provider<Repo?>((ref) {
  final scope = ref.watch(prDetailRepoScopeProvider);
  if (scope == null) {
    return null;
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
    if (r.remoteOwner.toLowerCase() == owner &&
        r.remoteName.toLowerCase() == name) {
      return r;
    }
  }
  return null;
});

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
  if (ref.watch(prDetailRepoScopeProvider) != null) {
    return ref.watch(prDetailRepoProvider);
  }
  return ref.watch(activeRepoProvider);
});

/// The PR-scoped review repository: bound to the repo an open PR detail pins by
/// URL, or **null** when nothing is pinned or the pin isn't resolvable yet.
///
/// Fail-closed by construction — this is what every PR-number-keyed read and
/// mutation goes through (via [_pinnedStream] for streams), so a number can
/// never be sent to a repo it doesn't belong to. Repo-level reads that carry no
/// PR number use [prReviewRepositoryProvider] instead.
final prScopedReviewRepositoryProvider = Provider<PrReviewRepository?>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  final repo = ref.watch(prDetailRepoProvider);
  if (workspace == null || repo == null) {
    return null;
  }
  final registry = ref.watch(forgeProviderRegistryProvider);
  return registry.resolve(
    ForgeProviderContext(repo: repo, workspaceId: workspace.id),
  );
});

/// Subscribes [read] on the PR-scoped repository.
///
/// While no repo is pinned (or its pin isn't resolvable yet) this yields a
/// stream that never emits, so the surface stays in its loading state and — the
/// point — issues no request. It must never fall back to the active repo: see
/// [prDetailRepoProvider].
Stream<T> _pinnedStream<T>(
  Ref ref,
  Stream<T> Function(PrReviewRepository repository) read,
) {
  final repository = ref.watch(prScopedReviewRepositoryProvider);
  if (repository == null) {
    return const Stream.empty();
  }
  return read(repository);
}

/// Provides the cached PR review repository for **repo-level** work — reads and
/// writes that carry no PR number (the assignee/reviewer pickers, which the
/// compose screen shows with no PR in play).
///
/// Resolved over RPC ([RpcForgeProviderFactory]); GitHub auth lives on the HOST,
/// not this thin client, so this does NOT gate on a client-local token — the
/// server serves the PR-review surface from its own gh-authenticated client
/// (and degrades to an empty repository there when it holds no token). Gating on
/// the client token here would wrongly blank the PR detail page on web.
///
/// Scoped to [currentPrRepoProvider]: the open PR detail's repo (from its URL),
/// or the active repo elsewhere. Anything keyed by a PR number must use
/// [prScopedReviewRepositoryProvider], which has no active-repo fallback.
final prReviewRepositoryProvider = Provider<PrReviewRepository>((ref) {
  // On a PR detail route the pinned repo wins and nothing may stand in for it:
  // an unresolved pin degrades to the inert repository, never the active repo.
  if (ref.watch(prDetailRepoScopeProvider) != null) {
    return ref.watch(prScopedReviewRepositoryProvider) ??
        const EmptyPrReviewRepository();
  }
  final workspace = ref.watch(activeWorkspaceProvider);
  final repo = ref.watch(activeRepoProvider);
  if (workspace == null || repo == null) {
    return const EmptyPrReviewRepository();
  }
  final registry = ref.watch(forgeProviderRegistryProvider);
  return registry.resolve(
    ForgeProviderContext(repo: repo, workspaceId: workspace.id),
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
    return _pinnedStream(
      ref,
      (repository) => repository
          .watchFiles(prNumber)
          .map((files) => PrFilesLoad(files: files, isComplete: true)),
    );
  },
);

/// Stream of pull request details by number.
final prDetailProvider = StreamProvider.autoDispose.family<PullRequest?, int>((
  ref,
  prNumber,
) {
  return _pinnedStream(ref, (r) => r.watchPullRequest(prNumber));
});

/// Identifies a PR by its own repo so it can be fetched independently of the
/// active repo.
typedef PeekContentKey = ({String owner, String repo, int number});

/// What the peek panel fetches on demand: the raw markdown `body` plus GitHub's
/// rendered `bodyHtml` (used to splice pre-signed attachment URLs) and the
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
  return _pinnedStream(ref, (r) => r.watchDiff(prNumber));
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

/// Whether [gitRef] names an immutable commit rather than a moving branch.
///
/// A commit SHA pins content forever; `main` does not. Every read below that
/// is treated as cacheable keys off this one predicate, so the distinction is
/// stated once instead of assumed in each provider — and it fails CLOSED: an
/// abbreviated-looking branch name (`deadbee`) would be misread as a SHA, so
/// the bar is hex-only, which no conventional branch name is.
bool isImmutableGitRef(String gitRef) =>
    gitRef.length >= 7 &&
    gitRef.length <= 40 &&
    _hexOnly.hasMatch(gitRef);

final _hexOnly = RegExp(r'^[0-9a-f]+$');

/// Holds this provider's value for [_immutableReadTtl] after its last listener.
///
/// The alternative is what `autoDispose` does by default: drop it, and re-pull
/// the whole file the moment the reader tabs back. Bounded by TIME rather than
/// by bytes, deliberately — the values are per-file and a reader who visits
/// hundreds of files in two minutes has bigger costs than this; the point is
/// that a tab switch is free, not that the client keeps a repository.
void _holdBriefly(Ref ref) {
  final link = ref.keepAlive();
  final timer = Timer(_immutableReadTtl, link.close);
  ref.onDispose(timer.cancel);
}

const _immutableReadTtl = Duration(minutes: 2);

/// Stream of full file content at a specific ref.
///
/// At a commit SHA the content CANNOT change, so this takes one value and drops
/// the subscription instead of holding an open server subscription per visited
/// file — the PR detail screen already opens a dozen, and file navigation was
/// churning a full-content one per file with nothing retained between visits.
/// A branch ref keeps the live subscription: there the content really can move.
final prFileContentProvider = StreamProvider.autoDispose
    .family<String, PrFileContentKey>((ref, key) {
      final stream = _pinnedStream(
        ref,
        (r) => r.watchFileContent(key.path, key.ref),
      );
      if (!isImmutableGitRef(key.ref)) {
        return stream;
      }
      _holdBriefly(ref);
      return stream.take(1);
    });

/// Stream of commits in a PR.
final prCommitsProvider = StreamProvider.autoDispose
    .family<List<PrCommit>, int>((ref, prNumber) {
      return _pinnedStream(ref, (r) => r.watchCommits(prNumber));
    });

/// Stream of files changed in a single commit.
///
/// A commit's file list is as immutable as its content — same treatment as
/// [prFileContentProvider], for the same reason: stepping through a PR's
/// commits re-pulled each one's file list every time it came back on screen.
final prCommitFilesProvider = StreamProvider.autoDispose
    .family<List<PrFile>, String>((ref, sha) {
      final stream = _pinnedStream(ref, (r) => r.watchCommitFiles(sha));
      if (!isImmutableGitRef(sha)) {
        return stream;
      }
      _holdBriefly(ref);
      return stream.take(1);
    });

/// Stream of review submissions for a PR.
final prReviewsProvider = StreamProvider.autoDispose
    .family<List<PrReviewSubmission>, int>((ref, prNumber) {
      return _pinnedStream(ref, (r) => r.watchReviews(prNumber));
    });

/// Stream of enriched reviewers (users + teams, with code-owner flags and the
/// team↔member review merge) for a PR. Feeds the detail sidebar's reviewer rail.
final prReviewersProvider = StreamProvider.autoDispose
    .family<List<PrReviewer>, int>((ref, prNumber) {
      return _pinnedStream(ref, (r) => r.watchReviewers(prNumber));
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

/// GitHub's suggested reviewers for a PR (recommended from git-blame authorship
/// and prior review history). PR-scoped; backs the "Suggested reviewers" group
/// in the reviewer picker.
final suggestedReviewersProvider = FutureProvider.autoDispose
    .family<List<PrUser>, int>((ref, prNumber) async {
      // PR-keyed: no pinned repo means no suggestions, never another repo's.
      final repository = ref.watch(prScopedReviewRepositoryProvider);
      if (repository == null) {
        return const [];
      }
      return repository.listSuggestedReviewers(prNumber);
    });

/// Key for [issueSearchProvider]: the repo to search and the free-text query.
typedef IssueSearchKey = ({String owner, String repo, String query});

/// Searches issues + PRs in a repo for the `#`-reference autocomplete in the
/// body editor. Best-effort and auto-disposing; debounced by the caller. Runs
/// SERVER-SIDE over RPC (the thin client holds no GitHub token).
final issueSearchProvider = FutureProvider.autoDispose
    .family<List<({int number, String title})>, IssueSearchKey>((
      ref,
      key,
    ) async {
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
      return _pinnedStream(ref, (r) => r.watchReviewComments(prNumber));
    });

/// Stream of top-level issue comments for a PR.
final prIssueCommentsProvider = StreamProvider.autoDispose
    .family<List<IssueComment>, int>((ref, prNumber) {
      return _pinnedStream(ref, (r) => r.watchIssueComments(prNumber));
    });

/// Stream of conversation-timeline events (review requests / removals) for a
/// PR — the Overview activity feed's event rows.
final prTimelineEventsProvider = StreamProvider.autoDispose
    .family<List<PrTimelineEvent>, int>((ref, prNumber) {
      return _pinnedStream(ref, (r) => r.watchTimelineEvents(prNumber));
    });

/// Stream of CI check runs for a PR.
final prCheckRunsProvider = StreamProvider.autoDispose
    .family<List<CheckRun>, int>((ref, prNumber) {
      return _pinnedStream(ref, (r) => r.watchCheckRuns(prNumber));
    });

/// Live detail (step progress + logs) for one GitHub Actions job. Polls every
/// 4 s while the job is unfinished — and briefly after completion, because
/// GitHub publishes logs a few seconds late — and stops at the terminal state
/// with logs attached. Auto-disposed: polling runs only while a job's steps
/// accordion is on screen.
final prJobRunDetailProvider = StreamProvider.autoDispose
    .family<JobRunDetail?, int>((ref, jobId) async* {
      final repository = ref.watch(prReviewRepositoryProvider);
      const interval = Duration(seconds: 4);
      const maxLogWaitPolls = 15; // ~1 min of post-completion log waiting
      var logWaitPolls = 0;
      while (true) {
        final detail = await repository.getJobRunDetail(jobId);
        yield detail;
        if (detail == null) {
          return;
        }
        if (detail.isComplete) {
          if (detail.logs != null || ++logWaitPolls >= maxLogWaitPolls) {
            return;
          }
        }
        await Future<void>.delayed(interval);
      }
    });

/// Parsed job graph (`needs` edges) for one workflow run. Fetched once per
/// expansion — the YAML is immutable per (path, head SHA).
final prWorkflowGraphProvider = FutureProvider.autoDispose
    .family<WorkflowGraph?, int>((ref, workflowRunId) {
      return ref
          .watch(prReviewRepositoryProvider)
          .getWorkflowGraph(workflowRunId);
    });

/// Stream of commit statuses for a PR head (the Statuses API — distinct from
/// check runs). Feeds deploy-preview detection via each status's `target_url`.
final prCommitStatusesProvider = StreamProvider.autoDispose
    .family<List<CommitStatus>, int>((ref, prNumber) {
      return _pinnedStream(ref, (r) => r.watchCommitStatuses(prNumber));
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
    .family<ReviewChannelAssociation?, String>((ref, prExternalId) {
      // Scope the lookup to the active workspace: PR node ids are global, so an
      // unscoped lookup could surface another workspace's review channel.
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(null);
      }
      return ref
          .watch(reviewChannelRepositoryProvider)
          .watchByPr(workspaceId, prExternalId);
    });

/// Stream of the review channel association for a *channel* — the reverse of
/// [reviewChannelForPrProvider]. Used by the sidebar to resolve what (if any)
/// PR a conversation is about, without parsing the channel title. Local DB
/// stream, emits immediately.
final reviewChannelForChannelProvider = StreamProvider.autoDispose
    .family<ReviewChannelAssociation?, String>((ref, channelId) {
      return ref
          .watch(reviewChannelRepositoryProvider)
          .watchByChannel(ref.requireWorkspaceId(), channelId);
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
      // Only serve a repo the workspace actually links. The host enforces this
      // too, but enforcing it here keeps the client from opening a doomed
      // subscription per association row when a review channel outlives its
      // repo link (server rejects it, the provider retries and every sidebar
      // pass re-spawns the cycle — the "Repository is not linked to this
      // workspace" log storm). While the repo list is still loading this
      // returns the empty repository; the watch below rebuilds it once the
      // list lands.
      final linked =
          ref.watch(reposForWorkspaceProvider(key.workspaceId)).value ??
          const [];
      final isLinked = linked.any(
        (r) =>
            r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
            r.remoteName.toLowerCase() == repo.toLowerCase(),
      );
      if (!isLinked) {
        return const EmptyPrReviewRepository();
      }
      // Flipped to RPC: the sidebar resolves a repo-scoped repository over the
      // in-process server, which owns the shared workspace-wide SWR disk cache —
      // so a read here hits the same `prDetail` cache the detail screen
      // populates. The host re-validates the (owner, repo) link before
      // returning any row.
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

/// Stream of *every* review-channel association for a channel — a channel can
/// carry multiple PRs across one or more repos. Workspace-scoped (the host /
/// DAO scopes by the bound workspace). Local DB stream / RPC subscription.
final channelReviewAssociationsProvider = StreamProvider.autoDispose
    .family<List<ReviewChannelAssociation>, String>((ref, channelId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(const []);
      }
      return ref
          .watch(reviewChannelRepositoryProvider)
          .watchAllByChannel(workspaceId, channelId);
    });

/// The SWR-cached [PullRequest] for a single association (keyed by its
/// workspace + repo + PR number), resolved through the repo-scoped cache.
final _associationPrProvider = StreamProvider.autoDispose
    .family<
      PullRequest?,
      ({String workspaceId, String repoFullName, int prNumber})
    >((ref, key) {
      final repo = ref.watch(
        repoScopedPrReviewRepositoryProvider((
          workspaceId: key.workspaceId,
          repoFullName: key.repoFullName,
        )),
      );
      return repo.watchPullRequest(key.prNumber);
    });

/// Every [PullRequest] a channel is about, resolved from its associations.
/// Non-blocking and SWR: returns whatever PRs have hydrated from cache so far,
/// growing as fresh state arrives. Drives the sidebar's aggregate PR glyph and
/// open-PR count badge.
final channelPrsProvider = Provider.autoDispose
    .family<List<PullRequest>, String>((ref, channelId) {
      final assocs =
          ref.watch(channelReviewAssociationsProvider(channelId)).value ??
          const [];
      final prs = <PullRequest>[];
      for (final a in assocs) {
        final pr = ref
            .watch(
              _associationPrProvider((
                workspaceId: a.workspaceId,
                repoFullName: a.repoFullName,
                prNumber: a.prNumber,
              )),
            )
            .value;
        if (pr != null) {
          prs.add(pr);
        }
      }
      return prs;
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
