import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_infra/src/network/github_api_client.dart';

/// Builds one GitHub profile's workspace-scoped PR history and delivery metrics.
///
/// GitHub search supplies the detailed sample while four `issueCount` lanes
/// supply exact state totals. Percentiles remain honest when the sample reaches
/// GitHub's 1,000-result cap because [GitHubProfileMetrics.resultsTruncated]
/// records the limitation explicitly.
class GitHubProfileActivityAdapter {
  /// Creates an adapter backed by [client].
  const GitHubProfileActivityAdapter(this.client);

  /// GitHub API facade.
  final GitHubApiClient client;

  /// Fetches activity authored by any of [logins] across the GitHub subset of
  /// [repos].
  Future<GitHubProfileActivity> fetch({
    required List<Repo> repos,
    required List<String> logins,
  }) async {
    final githubRepos = repos
        .where(
          (repo) =>
              repo.forge == ForgeHost.github &&
              repo.remoteOwner.isNotEmpty &&
              repo.remoteName.isNotEmpty,
        )
        .toList(growable: false);
    final authors = logins
        .map((login) => login.trim())
        .where((login) => login.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (githubRepos.isEmpty || authors.isEmpty) {
      return GitHubProfileActivity.empty;
    }

    final coordinates = [
      for (final repo in githubRepos)
        (owner: repo.remoteOwner, name: repo.remoteName),
    ];
    final results = await Future.wait([
      client.graphql.prCountsByAuthors(logins: authors, repos: coordinates),
      client.graphql.searchProfilePullRequestNodes(
        logins: authors,
        repos: coordinates,
      ),
    ]);
    final counts =
        results[0] as ({int open, int draft, int merged, int closed});
    final search =
        results[1] as ({List<Map<String, dynamic>> nodes, bool truncated});

    final repoByName = {
      for (final repo in githubRepos) repo.fullName.toLowerCase(): repo,
    };
    final prsByRepo = <String, List<PullRequest>>{};
    final lines = <double>[];
    final mergeHours = <double>[];
    final firstReviewHours = <double>[];
    var analyzedMerged = 0;
    var reviewedMerged = 0;

    for (final node in search.nodes) {
      final repoFullName =
          (node['repository'] as Map<String, dynamic>?)?['nameWithOwner']
              as String?;
      final repo = repoFullName == null
          ? null
          : repoByName[repoFullName.toLowerCase()];
      final number = (node['number'] as num?)?.toInt() ?? 0;
      final title = node['title'] as String? ?? '';
      if (repo == null || number <= 0 || title.isEmpty) {
        continue;
      }

      final createdAt = DateTime.tryParse(node['createdAt'] as String? ?? '');
      final mergedAt = DateTime.tryParse(node['mergedAt'] as String? ?? '');
      final author = node['author'] as Map<String, dynamic>?;
      final authorLogin = author?['login'] as String? ?? '';
      final additions = (node['additions'] as num?)?.toInt() ?? 0;
      final deletions = (node['deletions'] as num?)?.toInt() ?? 0;
      final reviews = node['reviews'] as Map<String, dynamic>?;
      final externalReviewTimes = <DateTime>[];
      for (final raw in reviews?['nodes'] as List? ?? const []) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }
        final reviewer = raw['author'] as Map<String, dynamic>?;
        final reviewerLogin = reviewer?['login'] as String? ?? '';
        final submittedAt = DateTime.tryParse(
          raw['submittedAt'] as String? ?? '',
        );
        if (submittedAt != null &&
            reviewerLogin.isNotEmpty &&
            reviewerLogin.toLowerCase() != authorLogin.toLowerCase()) {
          externalReviewTimes.add(submittedAt);
        }
      }
      externalReviewTimes.sort();

      final state = mergedAt != null
          ? PrState.merged
          : node['state'] == 'CLOSED'
          ? PrState.closed
          : PrState.open;
      final comments = node['comments'] as Map<String, dynamic>?;
      final pr = PullRequest(
        id: number,
        number: number,
        title: title,
        body: '',
        state: state,
        isDraft: node['isDraft'] as bool? ?? false,
        author: authorLogin.isEmpty
            ? null
            : PrUser(
                login: authorLogin,
                avatarUrl: author?['avatarUrl'] as String? ?? '',
              ),
        createdAt: createdAt,
        updatedAt: DateTime.tryParse(node['updatedAt'] as String? ?? ''),
        repoFullName: repo.fullName,
        htmlUrl: node['url'] as String? ?? '',
        externalId: node['id'] as String? ?? '',
        headSha: node['headRefOid'] as String? ?? '',
        baseRef: node['baseRefName'] as String? ?? '',
        headRef: node['headRefName'] as String? ?? '',
        mergedAt: mergedAt,
        additions: additions,
        deletions: deletions,
        commentsCount: (comments?['totalCount'] as num?)?.toInt() ?? 0,
      );
      (prsByRepo[repo.id] ??= <PullRequest>[]).add(pr);
      lines.add((additions + deletions).toDouble());

      if (createdAt != null && externalReviewTimes.isNotEmpty) {
        firstReviewHours.add(
          externalReviewTimes.first.difference(createdAt).inMinutes / 60,
        );
      }
      if (createdAt != null && mergedAt != null) {
        analyzedMerged++;
        mergeHours.add(mergedAt.difference(createdAt).inMinutes / 60);
        if (externalReviewTimes.isNotEmpty) {
          reviewedMerged++;
        }
      }
    }

    final groups = <GitHubProfileRepoPullRequests>[];
    for (final repo in githubRepos) {
      final prs = prsByRepo[repo.id];
      if (prs == null || prs.isEmpty) {
        continue;
      }
      prs.sort((a, b) {
        final left = a.updatedAt ?? a.createdAt ?? DateTime(1970);
        final right = b.updatedAt ?? b.createdAt ?? DateTime(1970);
        return right.compareTo(left);
      });
      groups.add(GitHubProfileRepoPullRequests(repoId: repo.id, prs: prs));
    }

    return GitHubProfileActivity(
      metrics: GitHubProfileMetrics(
        open: counts.open,
        draft: counts.draft,
        merged: counts.merged,
        closed: counts.closed,
        analyzedPullRequests: lines.length,
        resultsTruncated: search.truncated,
        medianLinesChanged: _percentile(lines, 50),
        p90LinesChanged: _percentile(lines, 90),
        medianHoursToMerge: _percentile(mergeHours, 50),
        p90HoursToMerge: _percentile(mergeHours, 90),
        medianHoursToFirstReview: _percentile(firstReviewHours, 50),
        reviewCoveragePercent: analyzedMerged == 0
            ? null
            : reviewedMerged * 100 / analyzedMerged,
      ),
      repos: groups,
    );
  }

  double? _percentile(List<double> values, int percent) {
    if (values.isEmpty) {
      return null;
    }
    final sorted = values.toList()..sort();
    final rank = ((percent / 100) * sorted.length).ceil().clamp(
      1,
      sorted.length,
    );
    return sorted[rank - 1];
  }
}
