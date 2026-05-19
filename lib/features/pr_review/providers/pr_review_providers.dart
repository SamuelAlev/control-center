import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
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
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter/foundation.dart';
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

/// Identifies one pull request the way GitHub does: the workspace context, the
/// `owner/repo` it lives in, and the number.
///
/// A PR number is unique only *within* its repo, so the coords ARE the
/// identity: every PR-keyed provider below takes a [PrRef] and resolves its
/// repository from the key, never from ambient navigation state. (The former
/// design — bare-`int` families resolving through a URL-synced global scope
/// updated on a deferred microtask — let a cross-repo hop subscribe the NEW
/// number against the PREVIOUS repo for a frame, which is exactly the
/// wrong-repo `GET /repos/<other-repo>/pulls/<n>` 404 class.)
typedef PrRef = ({String workspaceId, String repoFullName, int number});

/// The linked [Repo] row for this [PrRef]'s `owner/repo`, or null while the
/// workspace's repo rows haven't resolved or don't link that repo.
///
/// Matched case-insensitively, keyed by [PrRef] — never resolved from the
/// active repo or a route-synced scope. Null means "can't answer yet", never
/// "try another repo".
final prRepoRowProvider = Provider.autoDispose.family<Repo?, PrRef>((ref, pr) {
  final slash = pr.repoFullName.indexOf('/');
  if (slash <= 0 || slash == pr.repoFullName.length - 1) {
    return null;
  }
  final owner = pr.repoFullName.substring(0, slash).toLowerCase();
  final name = pr.repoFullName.substring(slash + 1).toLowerCase();
  final repos =
      ref.watch(reposForWorkspaceProvider(pr.workspaceId)).value ?? const [];
  for (final r in repos) {
    if (r.remoteOwner.toLowerCase() == owner &&
        r.remoteName.toLowerCase() == name) {
      return r;
    }
  }
  return null;
});

/// The review repository bound to this [PrRef]'s own `owner/repo`, or null
/// while [prRepoRowProvider] hasn't resolved.
///
/// Fail-closed by construction — this is what every PR-keyed read and mutation
/// goes through (via [_prStream] for streams), so a number can never be sent
/// to a repo it doesn't belong to. The host re-validates the repo link before
/// serving any row. Resolving null (repos still loading, repo not linked)
/// keeps callers in their loading state rather than erroring.
final prRepositoryProvider =
    Provider.autoDispose.family<PrReviewRepository?, PrRef>((ref, pr) {
      final repo = ref.watch(prRepoRowProvider(pr));
      if (repo == null) {
        return null;
      }
      final registry = ref.watch(forgeProviderRegistryProvider);
      return registry.resolve(
        ForgeProviderContext(repo: repo, workspaceId: pr.workspaceId),
      );
    });

/// Subscribes [read] on the repository bound to [pr]'s own repo.
///
/// While that repo hasn't resolved this yields a stream that never emits, so
/// the surface stays in its loading state and — the point — issues no request.
/// It must never fall back to another repo: a PR number is meaningless outside
/// its own repo.
Stream<T> _prStream<T>(
  Ref ref,
  PrRef pr,
  Stream<T> Function(PrReviewRepository repository) read,
) {
  final repository = ref.watch(prRepositoryProvider(pr));
  if (repository == null) {
    return const Stream.empty();
  }
  return read(repository);
}

/// Provides the cached PR review repository for **repo-level** work — reads and
/// writes that carry no PR identity at all (the assignee/reviewer pickers the
/// compose screen shows with no PR in play).
///
/// Bound to the workspace's ACTIVE repo by design: UI selection state is a
/// legitimate binding for a read that names no PR. Anything keyed by a PR must
/// resolve through [prRepositoryProvider] with the PR's own [PrRef] instead —
/// a PR number is meaningless outside its repo, and this provider's binding is
/// exactly the mutable selection state it must never ride.
///
/// Resolved over RPC ([RpcForgeProviderFactory]); GitHub auth lives on the HOST,
/// not this thin client, so this does NOT gate on a client-local token — the
/// server serves the PR-review surface from its own gh-authenticated client
/// (and degrades to an empty repository there when it holds no token). Gating on
/// the client token here would wrongly blank the PR detail page on web.
final prReviewRepositoryProvider = Provider<PrReviewRepository>((ref) {
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
final prFilesLoadProvider = StreamProvider.autoDispose
    .family<PrFilesLoad, PrRef>((ref, pr) {
      return _prStream(
        ref,
        pr,
        (repository) => repository
            .watchFiles(pr.number)
            .map((files) => PrFilesLoad(files: files, isComplete: true)),
      );
    });

/// Stream of pull request details, keyed by the PR's own `(owner, repo)`.
final prDetailProvider = StreamProvider.autoDispose.family<PullRequest?, PrRef>(
  (ref, pr) {
    return _prStream(ref, pr, (r) => r.watchPullRequest(pr.number));
  },
);

/// The row for `prNumber` out of the last open-PR snapshot, or null.
///
/// Everything on a PR page waited on [prDetailProvider], so a cold detail cache
/// meant a forge round trip before ANY chrome appeared — title, author,
/// branches, state, reviewers, all of it blank behind a skeleton. But the row
/// the operator just clicked was already in hand: the list query carries the
/// whole entity except `body`/`body_html`, and [lastGoodOpenPrsProvider] keeps
/// the snapshot alive across the navigation (the list provider itself is
/// autoDispose and dies with the list).
///
/// Scoped to the repo the URL pinned, never merely matched on number: a PR
/// number is unique only inside its repo, and a workspace routinely links
/// several. A same-numbered PR from a sibling repo would seed the page with
/// another PR's title and author.
///
/// **Chrome only.** The seed's `body` is empty because the list query never
/// asked for one — which is indistinguishable from a PR that genuinely has no
/// description. Rendering the empty-description placeholder off a seed would
/// state something false and then reflow when the real body lands, so callers
/// gate the description on [prDetailPendingProvider] instead.
final prDetailSeedProvider = Provider.autoDispose.family<PullRequest?, PrRef>((
  ref,
  pr,
) {
  final snapshot = ref.watch(lastGoodOpenPrsProvider)[pr.workspaceId];
  if (snapshot == null) {
    return null;
  }
  return findSeedPullRequest(
    snapshot.repos,
    repoFullName: pr.repoFullName,
    prNumber: pr.number,
  );
});

/// The PR numbered [prNumber] belonging to [repoFullName], out of [groups].
///
/// Split out of [prDetailSeedProvider] because the repo match is the part that
/// has to be right: a PR number is unique only inside its repo, and a workspace
/// routinely links several. Matching on number alone would seed the page with a
/// sibling repo's PR — right layout, wrong title, wrong author, wrong branches.
@visibleForTesting
PullRequest? findSeedPullRequest(
  List<RepoPullRequests> groups, {
  required String repoFullName,
  required int prNumber,
}) {
  final wanted = repoFullName.toLowerCase();
  for (final group in groups) {
    for (final pr in group.prs) {
      if (pr.number == prNumber && pr.repoFullName.toLowerCase() == wanted) {
        return pr;
      }
    }
  }
  return null;
}

/// The PR to render right now: the fetched detail when there is one, otherwise
/// the list-row seed. Null only when neither exists yet.
final prDetailOrSeedProvider = Provider.autoDispose.family<PullRequest?, PrRef>((
  ref,
  pr,
) {
  final detail = ref.watch(prDetailProvider(pr));
  // Gated on `hasValue`, not on the value being non-null: a resolved-but-absent
  // PR (a 404, or one deleted since the list snapshot) is a real answer, and
  // falling back to the seed for it would keep showing a page for something the
  // forge says is gone.
  if (detail.hasValue) {
    return detail.value;
  }
  if (detail.hasError) {
    return null;
  }
  return ref.watch(prDetailSeedProvider(pr));
});

/// True while the page is showing SEEDED chrome and the real detail — the only
/// source of `body`/`body_html` — has not arrived.
///
/// The one thing a seed cannot stand in for. Surfaces read this to hold a
/// description skeleton rather than claim there is no description.
///
/// Gated on a seed existing, not merely on the detail being unresolved: what
/// this answers is "is the PR on screen right now a stand-in?", and with no
/// seed there is nothing to stand in — the page is either showing a real
/// fetched PR or the whole-page loading body, and in neither case is a
/// description skeleton the right answer.
final prDetailPendingProvider = Provider.autoDispose.family<bool, PrRef>((
  ref,
  pr,
) {
  final detail = ref.watch(prDetailProvider(pr));
  if (detail.hasValue || detail.hasError) {
    return false;
  }
  return ref.watch(prDetailSeedProvider(pr)) != null;
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
/// than the active repo. The PR-list peek panel spans repos, so it keys its
/// fetch by the PR's own coords — and the list itself comes from a GraphQL
/// batch that omits `body`/`body_html` to stay cheap, so the peek has
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
final prDiffProvider = StreamProvider.autoDispose.family<String, PrRef>((
  ref,
  pr,
) {
  return _prStream(ref, pr, (r) => r.watchDiff(pr.number));
});

/// Stream of changed files for a PR.
///
/// Bridges from `prFilesLoadProvider` via `ref.listen` so the clone/compute
/// pipeline only runs ONCE, regardless of how many widgets watch either
/// provider. Emits only when the file list is non-empty.
final prFilesProvider =
    StreamProvider.autoDispose.family<List<PrFile>, PrRef>((ref, pr) {
      final controller = StreamController<List<PrFile>>();
      ref.onDispose(controller.close);

      ref.listen<AsyncValue<PrFilesLoad>>(prFilesLoadProvider(pr), (_, next) {
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

/// Pr file content key: the PR the file belongs to (its repo binds the
/// repository), the path, and the ref to read.
typedef PrFileContentKey = ({PrRef pr, String path, String ref});

/// Whether [gitRef] names an immutable commit rather than a moving branch.
///
/// A commit SHA pins content forever; `main` does not. Every read below that
/// is treated as cacheable keys off this one predicate, so the distinction is
/// stated once instead of assumed in each provider — and it fails CLOSED: an
/// abbreviated-looking branch name (`deadbee`) would be misread as a SHA, so
/// the bar is hex-only, which no conventional branch name is.
bool isImmutableGitRef(String gitRef) =>
    gitRef.length >= 7 && gitRef.length <= 40 && _hexOnly.hasMatch(gitRef);

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
      final stream = _prStream(
        ref,
        key.pr,
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
    .family<List<PrCommit>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchCommits(pr.number));
    });

/// The family key for [prCommitFilesProvider]: the PR's [PrRef] plus the
/// commit SHA whose files are listed.
typedef PrCommitFilesKey = ({PrRef pr, String sha});

/// Stream of files changed in a single commit.
///
/// A commit's file list is as immutable as its content — same treatment as
/// [prFileContentProvider], for the same reason: stepping through a PR's
/// commits re-pulled each one's file list every time it came back on screen.
/// Keyed by the PR as well as the SHA: the SHA alone can't pick the repo the
/// commit files are read from.
final prCommitFilesProvider = StreamProvider.autoDispose
    .family<List<PrFile>, PrCommitFilesKey>((ref, key) {
      final stream = _prStream(ref, key.pr, (r) => r.watchCommitFiles(key.sha));
      if (!isImmutableGitRef(key.sha)) {
        return stream;
      }
      _holdBriefly(ref);
      return stream.take(1);
    });

/// Stream of review submissions for a PR.
final prReviewsProvider = StreamProvider.autoDispose
    .family<List<PrReviewSubmission>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchReviews(pr.number));
    });

/// Stream of enriched reviewers (users + teams, with code-owner flags and the
/// team↔member review merge) for a PR. Feeds the detail sidebar's reviewer rail.
final prReviewersProvider = StreamProvider.autoDispose
    .family<List<PrReviewer>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchReviewers(pr.number));
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
    .family<List<PrUser>, PrRef>((ref, pr) async {
      // PR-keyed: an unresolved repo means no suggestions, never another
      // repo's.
      final repository = ref.watch(prRepositoryProvider(pr));
      if (repository == null) {
        return const [];
      }
      return repository.listSuggestedReviewers(pr.number);
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
    .family<List<PrCodeReviewComment>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchReviewComments(pr.number));
    });

/// Stream of top-level issue comments for a PR.
final prIssueCommentsProvider = StreamProvider.autoDispose
    .family<List<IssueComment>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchIssueComments(pr.number));
    });

/// Stream of conversation-timeline events (review requests / removals) for a
/// PR — the Overview activity feed's event rows.
final prTimelineEventsProvider = StreamProvider.autoDispose
    .family<List<PrTimelineEvent>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchTimelineEvents(pr.number));
    });

/// Stream of CI check runs for a PR.
final prCheckRunsProvider = StreamProvider.autoDispose
    .family<List<CheckRun>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchCheckRuns(pr.number));
    });

/// Key for [prJobRunDetailProvider]: the PR whose repo binds the repository,
/// plus the GitHub Actions job id.
typedef PrJobRunKey = ({PrRef pr, int jobId});

/// Live detail (step progress + logs) for one GitHub Actions job. Polls every
/// 4 s while the job is unfinished — and briefly after completion, because
/// GitHub publishes logs a few seconds late — and stops at the terminal state
/// with logs attached. Auto-disposed: polling runs only while a job's steps
/// accordion is on screen.
final prJobRunDetailProvider = StreamProvider.autoDispose
    .family<JobRunDetail?, PrJobRunKey>((ref, key) async* {
      final repository = ref.watch(prRepositoryProvider(key.pr));
      if (repository == null) {
        return;
      }
      const interval = Duration(seconds: 4);
      const maxLogWaitPolls = 15; // ~1 min of post-completion log waiting
      var logWaitPolls = 0;
      while (true) {
        final detail = await repository.getJobRunDetail(key.jobId);
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

/// Key for [prWorkflowGraphProvider]: the PR whose repo binds the repository,
/// plus the workflow run id.
typedef PrWorkflowGraphKey = ({PrRef pr, int workflowRunId});

/// Parsed job graph (`needs` edges) for one workflow run. Fetched once per
/// expansion — the YAML is immutable per (path, head SHA).
final prWorkflowGraphProvider = FutureProvider.autoDispose
    .family<WorkflowGraph?, PrWorkflowGraphKey>((ref, key) {
      final repository = ref.watch(prRepositoryProvider(key.pr));
      if (repository == null) {
        return Future.value();
      }
      return repository.getWorkflowGraph(key.workflowRunId);
    });

/// Stream of commit statuses for a PR head (the Statuses API — distinct from
/// check runs). Feeds deploy-preview detection via each status's `target_url`.
final prCommitStatusesProvider = StreamProvider.autoDispose
    .family<List<CommitStatus>, PrRef>((ref, pr) {
      return _prStream(ref, pr, (r) => r.watchCommitStatuses(pr.number));
    });

/// Provider for optimistic review submission state, keyed by PR identity
/// (repo + number — the number alone is ambiguous across repos).
final prOptimisticReviewStateProvider =
    NotifierProvider<
      PrOptimisticReviewStateNotifier,
      Map<PrRef, PrReviewSubmissionState?>
    >(PrOptimisticReviewStateNotifier.new);

/// Notifier that tracks optimistic review submission states per PR.
class PrOptimisticReviewStateNotifier
    extends Notifier<Map<PrRef, PrReviewSubmissionState?>> {
  static const _maxEntries = 50;

  @override
  /// Builds the initial empty review state map.
  Map<PrRef, PrReviewSubmissionState?> build() => {};

  /// Sets the optimistic review state for a PR, evicting oldest on overflow.
  void set(PrRef pr, PrReviewSubmissionState? value) {
    final map = Map<PrRef, PrReviewSubmissionState?>.from(state);
    map.remove(pr);
    map[pr] = value;
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

/// Stream of the review space association for a PR, scoped to the active workspace.
final reviewSpaceForPrProvider = StreamProvider.autoDispose
    .family<ReviewSpaceAssociation?, String>((ref, prExternalId) {
      // Scope the lookup to the active workspace: PR node ids are global, so an
      // unscoped lookup could surface another workspace's review space.
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(null);
      }
      return ref
          .watch(reviewSpaceRepositoryProvider)
          .watchByPr(workspaceId, prExternalId);
    });

/// Stream of the review space association for a *space* — the reverse of
/// [reviewSpaceForPrProvider]. Used by the sidebar to resolve what (if any)
/// PR a conversation is about, without parsing the space title. Local DB
/// stream, emits immediately.
final reviewSpaceForSpaceProvider = StreamProvider.autoDispose
    .family<ReviewSpaceAssociation?, String>((ref, spaceId) {
      return ref
          .watch(reviewSpaceRepositoryProvider)
          .watchBySpace(ref.requireWorkspaceId(), spaceId);
    });

/// Key for a repo-scoped PR review repository: the workspace plus the GitHub
/// `owner/repo` full name.
typedef RepoScopedPrReviewKey = ({String workspaceId, String repoFullName});

/// A SWR-cached [PrReviewRepository] bound to an explicit repo, independent of
/// the active repo. The sidebar spans repos, so it can't reuse
/// [prReviewRepositoryProvider] (active-repo-scoped); this resolves the right
/// repository for the space's PR from its association. The disk SWR cache is
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
      // subscription per association row when a review space outlives its
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

/// The GitHub [PullRequest] a space's review is about, or null for non-review
/// spaces. Served SWR: emits the cached PR detail first so the sidebar paints
/// immediately (cached → non-blocking), then revalidates from GitHub and emits
/// the fresh state if it changed. Never throws — a fetch failure leaves the
/// cached value in place, so the sidebar never breaks on a network hiccup.
final spacePrDetailProvider = StreamProvider.autoDispose
    .family<PullRequest?, String>((ref, spaceId) {
      final assoc = ref.watch(reviewSpaceForSpaceProvider(spaceId)).value;
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

/// Stream of *every* review-space association for a space — a space can
/// carry multiple PRs across one or more repos. Workspace-scoped (the host /
/// DAO scopes by the bound workspace). Local DB stream / RPC subscription.
final spaceReviewAssociationsProvider = StreamProvider.autoDispose
    .family<List<ReviewSpaceAssociation>, String>((ref, spaceId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(const []);
      }
      return ref
          .watch(reviewSpaceRepositoryProvider)
          .watchAllBySpace(workspaceId, spaceId);
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

/// Every [PullRequest] a space is about, resolved from its associations.
/// Non-blocking and SWR: returns whatever PRs have hydrated from cache so far,
/// growing as fresh state arrives. Drives the sidebar's aggregate PR glyph and
/// open-PR count badge.
final spacePrsProvider = Provider.autoDispose.family<List<PullRequest>, String>(
  (ref, spaceId) {
    final assocs =
        ref.watch(spaceReviewAssociationsProvider(spaceId)).value ?? const [];
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
  },
);

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
final prCanEditProvider = Provider.autoDispose.family<bool, PrRef>((
  ref,
  pr,
) {
  final prEntity = ref.watch(prDetailProvider(pr)).value;
  if (prEntity == null) {
    return false;
  }
  final login = ref
      .watch(githubUserProvider)
      .maybeWhen(
        data: (user) => user?.login.toLowerCase() ?? '',
        orElse: () => '',
      );
  final isAuthor =
      login.isNotEmpty && prEntity.author?.login.toLowerCase() == login;
  final parts = prEntity.repoFullName.split('/');
  final owner = parts.isNotEmpty ? parts[0] : '';
  final repoName = parts.length > 1 ? parts[1] : '';
  final hasWriteAccess =
      ref
          .watch(repoPermissionProvider((owner: owner, repo: repoName)))
          .whenOrNull(data: (perm) => perm == 'admin' || perm == 'write') ??
      false;
  return isAuthor || hasWriteAccess;
});
