import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long to wait before re-asking the server for the operator's forge
/// identity while nothing has resolved.
///
/// Retrying at all is the point, and it is the difference between an inbox
/// that recovers and one that lies. EVERY inbox section is classified relative
/// to the viewer's login on each forge — with no login the classifier returns
/// nothing — so a lookup that failed once and stuck leaves the phone showing
/// "You're all caught up" over a queue of review requests. These are RPCs to
/// the host (its own identity cache bounds the calls it makes to each forge),
/// so re-asking is cheap.
const Duration kForgeIdentityRetryInterval = Duration(seconds: 30);

/// The operator's account name on each forge, lower-cased — resolved SERVER-side
/// (`forge.listConnections`, which never carries a token).
///
/// A map rather than one login because a workspace may mix forges and the same
/// human is `octocat` on GitHub and someone else on GitLab; every "is this
/// mine?" test resolves through the forge of the repo in hand. A forge with no
/// connection is simply absent, which reads as "none of its PRs are mine"
/// rather than matching everything.
///
/// Never completes with an error: a failure resolves to an empty map and
/// schedules a retry, so consumers keep their "unresolved reads as absent"
/// contract instead of having to handle an error state each.
final viewerLoginsProvider = FutureProvider<Map<ForgeHost, String>>((
  ref,
) async {
  void retryLater() {
    final timer = Timer(kForgeIdentityRetryInterval, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  final client = ref.watch(rpcClientProvider).value;
  if (client == null) {
    return const {};
  }
  try {
    final data = await client.call('forge.listConnections', const {});
    final raw = data['connections'];
    if (raw is! List) {
      retryLater();
      return const {};
    }
    final connections = [
      for (final c in raw.whereType<Map<String, dynamic>>())
        ForgeConnection.fromJson(c),
    ];
    // Nothing connected yet: the host may still be resolving credentials.
    // Ask again rather than settling into a permanently empty identity.
    if (!connections.any((c) => c.authenticated)) {
      retryLater();
    }
    return {
      for (final c in connections)
        if (c.authenticated && c.username.isNotEmpty)
          c.forge: c.username.toLowerCase(),
    };
  } on Object {
    retryLater();
    return const {};
  }
});

/// The operator's GitHub teams, keyed by lower-case org login.
///
/// GitHub drops a team from a PR's `reviewRequests` as soon as ANY member
/// reviews, so a slug still on the request means no teammate has covered it —
/// which makes team membership the difference between "Needs your review"
/// listing a PR and silently skipping it. Empty when the lookup fails or the
/// operator belongs to no team; matching then stays user-only rather than
/// erroring.
final viewerTeamsProvider = FutureProvider<Map<String, Set<String>>>((
  ref,
) async {
  void retryLater() {
    final timer = Timer(kForgeIdentityRetryInterval, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  final client = ref.watch(rpcClientProvider).value;
  if (client == null) {
    return const {};
  }
  try {
    final data = await client.call('github.currentUser', const {});
    if (data['user'] is! Map) {
      retryLater();
    }
    final raw = data['teams'];
    if (raw is! List) {
      return const {};
    }
    final byOrg = <String, Set<String>>{};
    for (final entry in raw.whereType<Map>()) {
      final org = (entry['org'] as String?)?.toLowerCase() ?? '';
      final slug = (entry['slug'] as String?)?.toLowerCase() ?? '';
      if (org.isEmpty || slug.isEmpty) {
        continue;
      }
      (byOrg[org] ??= <String>{}).add(slug);
    }
    return byOrg;
  } on Object {
    retryLater();
    return const {};
  }
});

/// The live open-PR snapshot for the active workspace, across EVERY linked
/// repo (`pr.watchOpenForWorkspace`).
///
/// The server's poller owns the GitHub fetching and the persisted snapshot, so
/// this is one subscription for the whole workspace rather than a per-repo fan
/// out — the same feed the desktop's PR queue renders.
final openPrsProvider = StreamProvider<WorkspaceOpenPrs>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return RpcOpenPrListRepository(client).watchOpenForWorkspace(workspaceId);
});

/// The open-PR snapshot joined back to the workspace's canonical [Repo]
/// entities — the shape both the PR queue and the inbox classifier consume.
///
/// A group whose repo has not arrived yet is dropped rather than rendered
/// against a placeholder: the repo carries the forge, and the forge is what
/// decides whose PRs are "mine". Guessing it would mis-classify the whole
/// group for the seconds before the repo stream emits.
final prsByRepoProvider = Provider<AsyncValue<List<RepoPullRequests>>>((ref) {
  final snapshot = ref.watch(openPrsProvider);
  final repos = ref.watch(workspaceReposProvider).value ?? const <Repo>[];
  final byId = {for (final r in repos) r.id: r};
  return snapshot.whenData(
    (state) => [
      for (final group in state.groups)
        if (byId[group.repoId] case final repo?)
          RepoPullRequests(repo: repo, prs: group.prs),
    ],
  );
});

/// Every open PR in the workspace, flattened and newest-activity first, each
/// paired with the repo it came from.
final flatOpenPrsProvider = Provider<AsyncValue<List<PrInboxItem>>>((ref) {
  return ref.watch(prsByRepoProvider).whenData((groups) {
    final items = [
      for (final g in groups)
        for (final pr in g.prs) PrInboxItem(pr: pr, repo: g.repo),
    ];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    items.sort(
      (a, b) => (b.pr.updatedAt ?? b.pr.createdAt ?? epoch).compareTo(
        a.pr.updatedAt ?? a.pr.createdAt ?? epoch,
      ),
    );
    return items;
  });
});

/// The classified PR inbox for the active workspace — the same
/// [ClassifyPrInboxUseCase] the desktop runs, over the same feed.
///
/// The phone deliberately feeds it only the OPEN snapshot: the merged-history
/// section costs a separate server-side GitHub search per load and answers
/// "where did my PRs land", which is a desk question. What needs the operator
/// now — review requests, changes requested, red CI, approved-and-ready — all
/// comes from the open snapshot.
final prInboxProvider = Provider<AsyncValue<PrInboxData>>((ref) {
  final logins = ref.watch(viewerLoginsProvider).value ?? const {};
  final teams = ref.watch(viewerTeamsProvider).value ?? const {};
  return ref
      .watch(prsByRepoProvider)
      .whenData(
        (groups) => const ClassifyPrInboxUseCase().execute(
          openByRepo: groups,
          viewerLoginByForge: logins,
          viewerTeamsByOrg: teams,
        ),
      );
});

/// The number on the Inbox tab: blocked agents plus PRs that name the
/// operator as a reviewer or have come back to them.
///
/// Deliberately NOT "everything in the inbox". A badge counts things the
/// operator has to act on; folding in "waiting for reviewers" and "recently
/// merged" would make it a number that is never zero, which is the same as no
/// badge at all. It is derived from feeds the app already holds, so the badge
/// costs no extra subscription.
final inboxAttentionCountProvider = Provider<int>((ref) {
  final blocked =
      ref.watch(workspacePendingConfirmationsProvider).value?.length ?? 0;
  final inbox = ref.watch(prInboxProvider).value;
  if (inbox == null) {
    return blocked;
  }
  return blocked +
      inbox.of(PrInboxSection.needsYourReview).length +
      inbox.of(PrInboxSection.returnedToYou).length;
});

/// Coordinates identifying one PR across the phone's routes: the workspace's
/// repo plus the PR number. A PR number is only unique within a repo, so both
/// travel together everywhere.
typedef PrCoords = ({String repoId, int number});

/// The `(owner, repo)`-scoped review repository for [coords], or null while the
/// client or the repo row has not resolved.
///
/// Built per coords rather than held: it is a thin façade over the RPC client
/// (the host owns auth, the SWR cache and every GitHub call) and its identity
/// is the coordinates.
RpcPrReviewRepository? prReviewRepositoryFor(Ref ref, PrCoords coords) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  final repos = ref.watch(workspaceReposProvider).value ?? const <Repo>[];
  if (client == null || workspaceId == null) {
    return null;
  }
  final repo = repos.where((r) => r.id == coords.repoId).firstOrNull;
  final owner = repo?.remoteOwner;
  final name = repo?.remoteName;
  if (owner == null || name == null || owner.isEmpty || name.isEmpty) {
    return null;
  }
  return RpcPrReviewRepository(
    client,
    workspaceId: workspaceId,
    owner: owner,
    repo: name,
  );
}

/// The review repository for [coords] as a provider, so screens and their
/// action handlers resolve the same instance.
final prReviewRepositoryProvider = Provider.autoDispose
    .family<RpcPrReviewRepository?, PrCoords>(prReviewRepositoryFor);

/// The repo row behind [coords] (for the header's `owner/name`).
final prRepoProvider = Provider.autoDispose.family<Repo?, PrCoords>((
  ref,
  coords,
) {
  final repos = ref.watch(workspaceReposProvider).value ?? const <Repo>[];
  return repos.where((r) => r.id == coords.repoId).firstOrNull;
});

/// The live PR row for [coords].
///
/// Seeded from the workspace snapshot so the detail screen opens with the row
/// the list already had, then replaced by the per-PR watch (which carries the
/// fields the list feed omits). Without the seed, tapping a PR shows a spinner
/// over data that is already in memory.
final prDetailProvider = StreamProvider.autoDispose
    .family<PullRequest?, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      final seed = ref
          .watch(flatOpenPrsProvider)
          .value
          ?.where(
            (i) => i.repo.id == coords.repoId && i.pr.number == coords.number,
          )
          .firstOrNull
          ?.pr;
      if (repository == null) {
        return seed == null ? const Stream.empty() : Stream.value(seed);
      }
      final live = repository.watchPullRequest(coords.number);
      return seed == null ? live : live.startWith(seed);
    });

/// Live review submissions (approvals, change requests, review comments).
final prReviewsProvider = StreamProvider.autoDispose
    .family<List<PrReviewSubmission>, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      if (repository == null) return const Stream.empty();
      return repository.watchReviews(coords.number);
    });

/// Live top-level conversation comments.
final prIssueCommentsProvider = StreamProvider.autoDispose
    .family<List<IssueComment>, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      if (repository == null) return const Stream.empty();
      return repository.watchIssueComments(coords.number);
    });

/// Live CI check runs for the PR's head commit.
final prCheckRunsProvider = StreamProvider.autoDispose
    .family<List<CheckRun>, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      if (repository == null) return const Stream.empty();
      return repository.watchCheckRuns(coords.number);
    });

/// Live requested/completed reviewers.
final prReviewersProvider = StreamProvider.autoDispose
    .family<List<PrReviewer>, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      if (repository == null) return const Stream.empty();
      return repository.watchReviewers(coords.number);
    });

/// Live changed files — the phone renders the file list with its churn
/// counters rather than a full diff, which is the read a small screen can
/// actually serve.
final prFilesProvider = StreamProvider.autoDispose
    .family<List<PrFile>, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      if (repository == null) return const Stream.empty();
      return repository.watchFiles(coords.number);
    });

/// Prepends [value] to a stream — the seed-then-live shape used above.
extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
