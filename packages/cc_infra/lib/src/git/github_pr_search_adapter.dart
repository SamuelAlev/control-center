import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/pr_search_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/pr_review_mapper.dart';

/// [PrSearchPort] backed by GitHub's GraphQL `search`.
///
/// One chunked `search` resolves the whole workspace's matches at once and
/// pulls the same rich list fields the by-repo batch uses (diff size, check
/// rollup, requested reviewers) — only for the PRs that actually matched. This
/// replaced an older per-repo `/search/issues` + `fetchPullRequestMetrics` pair
/// that fetched metrics for 100 PRs *per repo* (including the expensive
/// `mergeStateStatus`), which made search slow. The `reviewed-by-me` signal is
/// still absent (no `latestReviews` in the list fields); the list overlays it
/// lazily when that filter is active.
class GitHubPrSearchAdapter implements PrSearchPort {
  /// Creates a [GitHubPrSearchAdapter] backed by [_client].
  GitHubPrSearchAdapter(this._client);

  final GitHubApiClient _client;

  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<List<RepoPullRequests>> search({
    required PrSearchQuery query,
    required List<Repo> repos,
  }) async {
    if (!query.isActive || repos.isEmpty) {
      return const [];
    }

    final nodes = await _client.graphql.searchPullRequestNodes(
      searchQualifiers: query.toQualifiers(),
      repos: repos
          .map((r) => (owner: r.githubOwner, name: r.githubRepoName))
          .toList(growable: false),
    );

    // Group the cross-repo matches back onto the workspace's repos by
    // `owner/name`; the search is scoped to these repos, so a miss is
    // unexpected and simply dropped.
    final repoByFullName = {for (final r in repos) r.fullName.toLowerCase(): r};
    final prsByRepoId = <String, List<PullRequest>>{};
    for (final node in nodes) {
      final number = (node['number'] as num?)?.toInt() ?? 0;
      final title = node['title'] as String? ?? '';
      if (number <= 0 || title.isEmpty) {
        continue;
      }
      final fullName =
          (node['repository'] as Map<String, dynamic>?)?['nameWithOwner']
              as String?;
      final repo = fullName == null
          ? null
          : repoByFullName[fullName.toLowerCase()];
      if (repo == null) {
        continue;
      }
      (prsByRepoId[repo.id] ??= []).add(
        pullRequestFromGraphQlNode(node, repoFullName: repo.fullName),
      );
    }

    final out = <RepoPullRequests>[];
    for (final repo in repos) {
      final prs = prsByRepoId[repo.id];
      if (prs == null || prs.isEmpty) {
        continue;
      }
      prs.sort(
        (a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch),
      );
      out.add(RepoPullRequests(repo: repo, prs: prs));
    }
    out.sort((a, b) => _topUpdated(b).compareTo(_topUpdated(a)));
    return out;
  }

  DateTime _topUpdated(RepoPullRequests group) =>
      group.prs.isNotEmpty ? (group.prs.first.updatedAt ?? _epoch) : _epoch;
}
