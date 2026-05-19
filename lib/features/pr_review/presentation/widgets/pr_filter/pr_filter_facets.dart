import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';

/// The filter categories offered by the PR list filter menu.
enum PrFilterCategory {
  /// Status facets (draft / open / in review / …).
  status,

  /// PR authors.
  author,

  /// Requested reviewers.
  reviewer,

  /// Title/body text.
  content,

  /// Repository owners.
  repoOwner,

  /// Repository names.
  repoName,

  /// Opened within a window.
  openedDate,

  /// Updated within a window.
  updatedDate,
}

/// One selectable option inside a filter submenu: the raw [value], how many
/// PRs selecting it would match, whether it is currently selected, and (for
/// people options) the [user] whose avatar the row renders.
class PrFacetOption<T> {
  /// Creates a [PrFacetOption].
  const PrFacetOption({
    required this.value,
    required this.count,
    required this.selected,
    this.user,
  });

  /// The raw option value (facet enum, login, owner/name, or window).
  final T value;

  /// Matching PRs in the population narrowed by every OTHER category.
  final int count;

  /// Whether the option is part of the active filter.
  final bool selected;

  /// The user behind an author/reviewer option (drives the avatar).
  final PrUser? user;
}

/// Returns [filters] with [category]'s own selections cleared — the standard
/// faceted-count population: an option's count reflects what selecting it
/// would show, given every other active category.
PrListFilters clearCategory(PrListFilters filters, PrFilterCategory category) {
  return switch (category) {
    PrFilterCategory.status => filters.copyWith(statuses: const {}),
    PrFilterCategory.author => filters.copyWith(authors: const {}),
    PrFilterCategory.reviewer => filters.copyWith(reviewers: const {}),
    PrFilterCategory.content => filters.copyWith(content: ''),
    PrFilterCategory.repoOwner => filters.copyWith(repoOwners: const {}),
    PrFilterCategory.repoName => filters.copyWith(repoNames: const {}),
    PrFilterCategory.openedDate => filters.copyWith(openedWithin: () => null),
    PrFilterCategory.updatedDate => filters.copyWith(updatedWithin: () => null),
  };
}

/// The population used to count [category]'s options: every loaded PR run
/// through the filters minus that category (and minus the lane rail, which is
/// a separate triage overlay on top of these filters).
List<PullRequest> facetPopulation(
  List<PullRequest> allPrs, {
  required PrFilterCategory category,
  required PrListFilters filters,
  required String currentLogin,
  required bool includeDrafts,
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  return applyFilters(
    allPrs,
    filters: clearCategory(filters, category),
    currentLogin: currentLogin,
    includeDrafts: includeDrafts,
    viewerTeamsByOrg: viewerTeamsByOrg,
  );
}

/// Status facet options with counts over [population].
List<PrFacetOption<PrStatusFilter>> statusFacetOptions(
  List<PullRequest> population, {
  required PrListFilters filters,
}) {
  return [
    for (final facet in PrStatusFilter.values)
      PrFacetOption(
        value: facet,
        count: population.where((pr) => prMatchesStatus(pr, facet)).length,
        selected: filters.statuses.contains(facet),
      ),
  ];
}

/// Author options with counts over [population]. Options are collected from
/// [allPrs] (so a selected author never vanishes when other filters zero it
/// out) and the operator's own login sorts first.
List<PrFacetOption<String>> authorFacetOptions(
  List<PullRequest> allPrs,
  List<PullRequest> population, {
  required PrListFilters filters,
  required String currentLogin,
}) {
  final counts = <String, int>{};
  for (final pr in population) {
    final login = pr.author?.login.toLowerCase();
    if (login != null && login.isNotEmpty) {
      counts[login] = (counts[login] ?? 0) + 1;
    }
  }
  final options = [
    for (final user in collectAuthors(allPrs))
      PrFacetOption(
        value: user.login.toLowerCase(),
        count: counts[user.login.toLowerCase()] ?? 0,
        selected: filters.authors.contains(user.login.toLowerCase()),
        user: user,
      ),
  ];
  if (currentLogin.isNotEmpty) {
    options.sort((a, b) {
      final aMe = a.value == currentLogin ? 0 : 1;
      final bMe = b.value == currentLogin ? 0 : 1;
      return aMe != bMe ? aMe.compareTo(bMe) : 0;
    });
  }
  return options;
}

/// Requested-reviewer options with counts over [population].
List<PrFacetOption<String>> reviewerFacetOptions(
  List<PullRequest> allPrs,
  List<PullRequest> population, {
  required PrListFilters filters,
  required String currentLogin,
}) {
  final counts = <String, int>{};
  for (final pr in population) {
    for (final reviewer in pr.requestedReviewers) {
      final login = reviewer.login.toLowerCase();
      if (login.isNotEmpty) {
        counts[login] = (counts[login] ?? 0) + 1;
      }
    }
  }
  final options = [
    for (final user in collectReviewers(allPrs))
      PrFacetOption(
        value: user.login.toLowerCase(),
        count: counts[user.login.toLowerCase()] ?? 0,
        selected: filters.reviewers.contains(user.login.toLowerCase()),
        user: user,
      ),
  ];
  if (currentLogin.isNotEmpty) {
    options.sort((a, b) {
      final aMe = a.value == currentLogin ? 0 : 1;
      final bMe = b.value == currentLogin ? 0 : 1;
      return aMe != bMe ? aMe.compareTo(bMe) : 0;
    });
  }
  return options;
}

/// Repository owner/name options with counts over [population]. [ownerAxis]
/// selects which half of `repoFullName` the options come from.
List<PrFacetOption<String>> repoFacetOptions(
  List<PullRequest> allPrs,
  List<PullRequest> population, {
  required PrListFilters filters,
  required bool ownerAxis,
}) {
  String keyOf(PullRequest pr) =>
      ownerAxis ? prRepoOwnerOf(pr) : prRepoNameOf(pr);
  final selectedSet = ownerAxis ? filters.repoOwners : filters.repoNames;

  final counts = <String, int>{};
  for (final pr in population) {
    final key = keyOf(pr);
    if (key.isNotEmpty) {
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  final keys = <String>{
    for (final pr in allPrs)
      if (keyOf(pr).isNotEmpty) keyOf(pr),
  }.toList()..sort();
  return [
    for (final key in keys)
      PrFacetOption(
        value: key,
        count: counts[key] ?? 0,
        selected: selectedSet.contains(key),
      ),
  ];
}

/// Date-window options with (cumulative) counts over [population].
/// [openedAxis] selects the opened vs updated timestamp.
List<PrFacetOption<PrDateWindow>> dateFacetOptions(
  List<PullRequest> population, {
  required PrListFilters filters,
  required bool openedAxis,
}) {
  final now = DateTime.now();
  final selected = openedAxis ? filters.openedWithin : filters.updatedWithin;
  DateTime? stampOf(PullRequest pr) =>
      openedAxis ? pr.createdAt : (pr.updatedAt ?? pr.createdAt);
  return [
    for (final window in PrDateWindow.values)
      PrFacetOption(
        value: window,
        count: population.where((pr) {
          final stamp = stampOf(pr);
          return stamp != null && now.difference(stamp) <= window.duration;
        }).length,
        selected: selected == window,
      ),
  ];
}

/// How many PRs the quick-to-review toggle would keep, counted over the
/// population narrowed by every other filter.
int quickToReviewCount(
  List<PullRequest> allPrs, {
  required PrListFilters filters,
  required String currentLogin,
  required bool includeDrafts,
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  final population = applyFilters(
    allPrs,
    filters: filters.copyWith(quickToReview: false),
    currentLogin: currentLogin,
    includeDrafts: includeDrafts,
    viewerTeamsByOrg: viewerTeamsByOrg,
  );
  return population.where(isQuickToReview).length;
}
