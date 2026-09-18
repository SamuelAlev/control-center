import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// One repo's enriched open-PR group (checks already overlaid), matching the
/// catalog's `OpenPrListFetcher` result shape.
typedef OpenPrGroup = ({Repo repo, List<PullRequest> prs, bool hasMore});

/// One fetch's result: the enriched groups plus the ids of the repos GitHub
/// actually answered for.
///
/// The two are NOT the same set — a repo with no open pull requests resolves
/// successfully and contributes no group — and the difference is load-bearing.
/// The batch query tolerates partial failure (an errored repo alias comes back
/// null and is skipped), so "no groups" is ambiguous on its own: it means
/// either an empty queue or a GitHub that answered for nothing. Reporting the
/// resolved ids lets the poller tell those apart instead of persisting an
/// outage as an empty inbox.
typedef OpenPrFetchResult = ({
  List<OpenPrGroup> groups,
  Set<String> resolvedRepoIds,
});

/// One PR's slice of the checks-pass enrichment: the raw check-rollup state
/// string plus the raw `reviewDecision` string (both null when absent).
typedef PrStatusOverlay = ({String? checksRollup, String? reviewDecision});

/// The GitHub fetch surface the open-PR poller runs on. Kept as a thin port so
/// tests drive the poller with an in-memory fake; the production adapter wraps
/// the server's gh-authenticated `GitHubApiClient`.
abstract interface class OpenPrFetchPort {
  /// Conditional (ETag) probe of [repo]'s open-PR list. `changed: false` means
  /// GitHub answered 304 — free against the rate limit — and the list is
  /// byte-identical since [etag].
  Future<({bool changed, String? etag})> probeRepo(Repo repo, String? etag);

  /// The full enriched open-PR groups (first page per repo, checks overlaid),
  /// with the ids of the repos GitHub actually answered for.
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos);

  /// The check-rollup + review-decision overlay per repo id, per PR number,
  /// for the first page of open PRs — the cheap status-only pass between full
  /// fetches.
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(List<Repo> repos);

  /// Whether a PR that vanished from the open list was merged (true), closed
  /// unmerged (false), or couldn't be resolved (null).
  Future<bool?> wasMerged(Repo repo, int prNumber);

  /// The forge's own mergeable verdict for ONE pull request.
  ///
  /// Deliberately not part of the list query: `mergeStateStatus` forces the
  /// forge to compute mergeability per PR and caused HTTP 504s across a
  /// 20-repo batch. This is the targeted escape hatch, called only on a
  /// readiness transition and capped per pass, so "ready to merge" is
  /// confirmed by the forge rather than guessed from a check rollup.
  ///
  /// [PrMergeableState.unknown] is a legitimate answer (the forge computes it
  /// lazily too) and means "not confirmed" — never "not mergeable".
  Future<PrMergeableState> mergeState(Repo repo, int prNumber);

  /// The login of the most recent approving review, or null when it cannot be
  /// determined. Used only to put a name on an approval whose reviewer could
  /// not be read off the requested-reviewer diff.
  Future<String?> latestApprover(Repo repo, int prNumber);

  /// The first failing check on a pull request, so a "checks failed"
  /// notification can name it. Null when none can be read — the rollup already
  /// said CI failed, so the name is an improvement on the message, never a
  /// precondition for sending it.
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  );
}
