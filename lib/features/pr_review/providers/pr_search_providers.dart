import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/data/datasources/github_pr_search_adapter.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/ports/pr_search_port.dart';
import 'package:control_center/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Binds the PR search port to its GitHub adapter.
final prSearchPortProvider = Provider<PrSearchPort>((ref) {
  return GitHubPrSearchAdapter(ref.watch(githubApiClientProvider));
});

/// Holds the raw PR search text from the queue's search field. The field
/// debounces writes here, so this state changes at most once per pause in
/// typing rather than per keystroke.
class PrSearchInputNotifier extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the raw search text.
  void set(String value) => state = value;

  /// Clears the search.
  void clear() => state = '';
}

/// Provides the raw (debounced) PR search input.
final prSearchInputProvider = NotifierProvider<PrSearchInputNotifier, String>(
  PrSearchInputNotifier.new,
);

/// The parsed [PrSearchQuery] derived from the raw input. Equality on
/// [PrSearchQuery] keeps downstream search from re-firing on cosmetic edits
/// (e.g. trailing whitespace) that parse to the same query.
final prSearchQueryProvider = Provider<PrSearchQuery>((ref) {
  return PrSearchQuery.parse(ref.watch(prSearchInputProvider));
});

/// Open PRs across the active workspace's repos matching the active query,
/// resolved through the [PrSearchPort]. Returns an empty list — without
/// touching the network — whenever the query is inactive.
final prSearchResultsProvider = FutureProvider<List<RepoPullRequests>>((
  ref,
) async {
  final query = ref.watch(prSearchQueryProvider);
  if (!query.isActive) {
    return const [];
  }
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const [];
  }
  final repos = githubLinkedReposOf(
    ref.watch(reposForWorkspaceProvider(workspaceId)),
  );
  if (repos.isEmpty) {
    return const [];
  }
  final port = ref.watch(prSearchPortProvider);
  return port.search(query: query, repos: repos);
});
