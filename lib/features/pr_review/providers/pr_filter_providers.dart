import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/pr_needs_your_review.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status facets for the PR list filter menu. Facets are derived views over
/// `state` / `isDraft` / `reviewDecision`, so one PR can match several facets
/// (a draft is also open); within the category selected facets OR together.
enum PrStatusFilter {
  /// Draft PRs (`isDraft`).
  draft,

  /// Open, non-draft PRs.
  open,

  /// Open PRs still waiting on a review (`reviewDecision == reviewRequired`).
  inReview,

  /// Open PRs where a reviewer requested changes.
  changesRequested,

  /// Approved PRs.
  approved,

  /// Merged PRs.
  merged,

  /// Closed-without-merge PRs.
  closed,
}

/// Relative time windows for the opened/updated date filters ("within the
/// last …").
enum PrDateWindow {
  /// Within the last day.
  day,

  /// Within the last 3 days.
  threeDays,

  /// Within the last week.
  week,

  /// Within the last month.
  month,

  /// Within the last 3 months.
  threeMonths,

  /// Within the last 6 months.
  sixMonths,

  /// Within the last year.
  year;

  /// The window's duration (months approximated as 30 days).
  Duration get duration => switch (this) {
    PrDateWindow.day => const Duration(days: 1),
    PrDateWindow.threeDays => const Duration(days: 3),
    PrDateWindow.week => const Duration(days: 7),
    PrDateWindow.month => const Duration(days: 30),
    PrDateWindow.threeMonths => const Duration(days: 90),
    PrDateWindow.sixMonths => const Duration(days: 180),
    PrDateWindow.year => const Duration(days: 365),
  };
}

/// Immutable filter state for the PR list. Filters are additive: between
/// categories they AND together; within a category the selected values OR
/// together. An empty set / null / empty string means "no filter on this
/// axis". All login/name sets hold lowercased values.
class PrListFilters {
  /// Creates a [PrListFilters] with the given settings.
  const PrListFilters({
    this.awaitingReview = false,
    this.createdByMe = false,
    this.reviewedByMe = false,
    this.statuses = const {},
    this.authors = const {},
    this.reviewers = const {},
    this.content = '',
    this.repoOwners = const {},
    this.repoNames = const {},
    this.openedWithin,
    this.updatedWithin,
    this.quickToReview = false,
  });

  /// Whether to show only PRs awaiting the operator's review.
  final bool awaitingReview;

  /// Whether to show only PRs authored by the operator.
  final bool createdByMe;

  /// Whether to show only PRs already reviewed by the operator.
  final bool reviewedByMe;

  /// Selected status facets (empty means no status filter).
  final Set<PrStatusFilter> statuses;

  /// Author logins to filter by, lowercased (empty means no author filter).
  final Set<String> authors;

  /// Requested-reviewer logins to filter by, lowercased (empty means no
  /// reviewer filter).
  final Set<String> reviewers;

  /// Case-insensitive text the PR title/body must contain (empty means no
  /// content filter).
  final String content;

  /// Repository owners to filter by, lowercased (empty means no owner filter).
  final Set<String> repoOwners;

  /// Repository names (without owner) to filter by, lowercased (empty means
  /// no name filter).
  final Set<String> repoNames;

  /// Only PRs opened within this window (null means no opened-date filter).
  final PrDateWindow? openedWithin;

  /// Only PRs updated within this window (null means no updated-date filter).
  final PrDateWindow? updatedWithin;

  /// Only PRs small enough to review quickly (see `isQuickToReview`).
  final bool quickToReview;

  /// Whether any filter is currently active.
  bool get isActive =>
      awaitingReview ||
      createdByMe ||
      reviewedByMe ||
      statuses.isNotEmpty ||
      authors.isNotEmpty ||
      reviewers.isNotEmpty ||
      content.isNotEmpty ||
      repoOwners.isNotEmpty ||
      repoNames.isNotEmpty ||
      openedWithin != null ||
      updatedWithin != null ||
      quickToReview;

  /// Total number of active filter criteria (drives the filter-button badge).
  int get count =>
      (awaitingReview ? 1 : 0) +
      (createdByMe ? 1 : 0) +
      (reviewedByMe ? 1 : 0) +
      statuses.length +
      authors.length +
      reviewers.length +
      (content.isNotEmpty ? 1 : 0) +
      repoOwners.length +
      repoNames.length +
      (openedWithin != null ? 1 : 0) +
      (updatedWithin != null ? 1 : 0) +
      (quickToReview ? 1 : 0);

  /// Returns a copy with the given fields replaced. The nullable date windows
  /// use sentinel-free dedicated setters on the notifier instead of copyWith
  /// (copyWith cannot null a field), so they are replaced wholesale here.
  PrListFilters copyWith({
    bool? awaitingReview,
    bool? createdByMe,
    bool? reviewedByMe,
    Set<PrStatusFilter>? statuses,
    Set<String>? authors,
    Set<String>? reviewers,
    String? content,
    Set<String>? repoOwners,
    Set<String>? repoNames,
    PrDateWindow? Function()? openedWithin,
    PrDateWindow? Function()? updatedWithin,
    bool? quickToReview,
  }) {
    return PrListFilters(
      awaitingReview: awaitingReview ?? this.awaitingReview,
      createdByMe: createdByMe ?? this.createdByMe,
      reviewedByMe: reviewedByMe ?? this.reviewedByMe,
      statuses: statuses ?? this.statuses,
      authors: authors ?? this.authors,
      reviewers: reviewers ?? this.reviewers,
      content: content ?? this.content,
      repoOwners: repoOwners ?? this.repoOwners,
      repoNames: repoNames ?? this.repoNames,
      openedWithin: openedWithin != null ? openedWithin() : this.openedWithin,
      updatedWithin: updatedWithin != null
          ? updatedWithin()
          : this.updatedWithin,
      quickToReview: quickToReview ?? this.quickToReview,
    );
  }
}

/// Default filter applied on first render: the list opens unfiltered (all
/// open PRs); the filter menu and the search query are the narrowing axes.
const defaultPrListFilters = PrListFilters();

/// Toggles [value] in a copy of [set].
Set<T> _toggled<T>(Set<T> set, T value) {
  final next = Set<T>.from(set);
  if (!next.add(value)) {
    next.remove(value);
  }
  return next;
}

/// Global (single) filter state for the by-repo PR list.
class PrListFiltersNotifier extends Notifier<PrListFilters> {
  @override
  /// Builds the initial filter state (unfiltered).
  PrListFilters build() => defaultPrListFilters;

  /// Toggles the "awaiting review" filter.
  void toggleAwaitingReview() =>
      state = state.copyWith(awaitingReview: !state.awaitingReview);

  /// Toggles the "created by me" filter.
  void toggleCreatedByMe() =>
      state = state.copyWith(createdByMe: !state.createdByMe);

  /// Toggles the "reviewed by me" filter.
  void toggleReviewedByMe() =>
      state = state.copyWith(reviewedByMe: !state.reviewedByMe);

  /// Toggles a status facet.
  void toggleStatus(PrStatusFilter status) =>
      state = state.copyWith(statuses: _toggled(state.statuses, status));

  /// Toggles an author login in the author filter set.
  void toggleAuthor(String login) => state = state.copyWith(
    authors: _toggled(state.authors, login.toLowerCase()),
  );

  /// Toggles a requested-reviewer login in the reviewer filter set.
  void toggleReviewer(String login) => state = state.copyWith(
    reviewers: _toggled(state.reviewers, login.toLowerCase()),
  );

  /// Sets the content (title/body text) filter.
  void setContent(String query) =>
      state = state.copyWith(content: query.trim());

  /// Toggles a repository owner in the owner filter set.
  void toggleRepoOwner(String owner) => state = state.copyWith(
    repoOwners: _toggled(state.repoOwners, owner.toLowerCase()),
  );

  /// Toggles a repository name in the name filter set.
  void toggleRepoName(String name) => state = state.copyWith(
    repoNames: _toggled(state.repoNames, name.toLowerCase()),
  );

  /// Sets the opened-date window; selecting the active window clears it.
  void setOpenedWithin(PrDateWindow? window) => state = state.copyWith(
    openedWithin: () => state.openedWithin == window ? null : window,
  );

  /// Sets the updated-date window; selecting the active window clears it.
  void setUpdatedWithin(PrDateWindow? window) => state = state.copyWith(
    updatedWithin: () => state.updatedWithin == window ? null : window,
  );

  /// Toggles the quick-to-review filter.
  void toggleQuickToReview() =>
      state = state.copyWith(quickToReview: !state.quickToReview);

  /// Replaces the whole filter state (the filter bar's chip-clear path, which
  /// computes the next state with `clearCategory` and writes it wholesale).
  void replace(PrListFilters next) => state = next;

  /// Clears all filters, restoring the default state.
  void clear() => state = const PrListFilters();
}

/// Provides global filter state for the by-repo PR list.
final prListFiltersProvider =
    NotifierProvider<PrListFiltersNotifier, PrListFilters>(
      PrListFiltersNotifier.new,
    );

/// Provides the inbox's own filter state — the same axes and menu as the PR
/// list, but an independent instance so narrowing the inbox never silently
/// narrows the queue (and vice versa).
final inboxListFiltersProvider =
    NotifierProvider<PrListFiltersNotifier, PrListFilters>(
      PrListFiltersNotifier.new,
    );

/// Binds a filter surface to its state and population: which
/// [PrListFilters] instance the menu/bar mutate and which loaded PRs the
/// facet counts run over. The PR list and the inbox each carry their own.
class PrFilterScope {
  /// Creates a [PrFilterScope].
  const PrFilterScope({required this.filters, required this.population});

  /// The surface's filter state instance.
  final NotifierProvider<PrListFiltersNotifier, PrListFilters> filters;

  /// Every PR loaded into the surface, flattened across repos.
  final Provider<List<PullRequest>> population;
}

/// Whether [pr] matches the [facet] status filter. Facets are derived views,
/// so one PR can match several (a draft is also open).
bool prMatchesStatus(PullRequest pr, PrStatusFilter facet) {
  return switch (facet) {
    PrStatusFilter.draft => pr.isDraft,
    PrStatusFilter.open => pr.isOpen && !pr.isDraft,
    PrStatusFilter.inReview =>
      pr.isOpen && pr.reviewDecision == PrReviewDecision.reviewRequired,
    PrStatusFilter.changesRequested =>
      pr.reviewDecision == PrReviewDecision.changesRequested,
    PrStatusFilter.approved => pr.reviewDecision == PrReviewDecision.approved,
    PrStatusFilter.merged => pr.isMerged,
    PrStatusFilter.closed => pr.isClosed,
  };
}

/// Whether [pr] is small enough to review quickly: a known diff of at most
/// 50 changed lines across at most 3 files. Un-enriched PRs (no metrics yet)
/// never qualify — an unknown diff is not a small one.
bool isQuickToReview(PullRequest pr) {
  final churn = pr.additions + pr.deletions;
  return pr.changedFiles > 0 && pr.changedFiles <= 3 && churn <= 50;
}

/// The owner half of [PullRequest.repoFullName], lowercased ('' when absent).
String prRepoOwnerOf(PullRequest pr) {
  final i = pr.repoFullName.indexOf('/');
  return i <= 0 ? '' : pr.repoFullName.substring(0, i).toLowerCase();
}

/// The name half of [PullRequest.repoFullName], lowercased ('' when absent).
String prRepoNameOf(PullRequest pr) {
  final i = pr.repoFullName.indexOf('/');
  return i < 0 || i == pr.repoFullName.length - 1
      ? pr.repoFullName.toLowerCase()
      : pr.repoFullName.substring(i + 1).toLowerCase();
}

/// Whether [date] falls within the trailing [window] (false when unknown).
bool _withinWindow(DateTime? date, PrDateWindow window) {
  if (date == null) {
    return false;
  }
  return DateTime.now().difference(date) <= window.duration;
}

/// Whether a single [pr] passes [filters] for [currentLogin]. When
/// [includeDrafts] is false (the "show drafts" display option), draft PRs
/// never pass regardless of the filter state. Categories AND together; values
/// within a category OR together.
bool prPassesFilters(
  PullRequest pr, {
  required PrListFilters filters,
  required String currentLogin,
  bool includeDrafts = true,
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  final me = currentLogin.toLowerCase();
  if (!includeDrafts && pr.isDraft) {
    return false;
  }
  final hasReviewFilter =
      filters.awaitingReview || filters.createdByMe || filters.reviewedByMe;
  if (hasReviewFilter) {
    if (me.isEmpty) {
      return false;
    }
    bool passes = false;
    if (filters.awaitingReview) {
      passes =
          passes ||
          prNeedsYourReview(
            isDraft: pr.isDraft,
            authorLogin: pr.author?.login,
            viewerLogin: me,
            requestedUserLogins: pr.requestedReviewers.map((r) => r.login),
            requestedTeamSlugs: pr.requestedTeamSlugs,
            repoFullName: pr.repoFullName,
            viewerTeamsByOrg: viewerTeamsByOrg,
          );
    }
    if (filters.createdByMe) {
      final iAmAuthor = pr.author?.login.toLowerCase() == me;
      passes = passes || iAmAuthor;
    }
    if (filters.reviewedByMe) {
      passes = passes || pr.reviewedByMe;
    }
    if (!passes) {
      return false;
    }
  }
  if (filters.statuses.isNotEmpty &&
      !filters.statuses.any((s) => prMatchesStatus(pr, s))) {
    return false;
  }
  if (filters.authors.isNotEmpty) {
    final author = pr.author?.login.toLowerCase();
    if (author == null || !filters.authors.contains(author)) {
      return false;
    }
  }
  if (filters.reviewers.isNotEmpty &&
      !pr.requestedReviewers.any(
        (r) => filters.reviewers.contains(r.login.toLowerCase()),
      )) {
    return false;
  }
  if (filters.content.isNotEmpty) {
    final needle = filters.content.toLowerCase();
    if (!pr.title.toLowerCase().contains(needle) &&
        !pr.body.toLowerCase().contains(needle)) {
      return false;
    }
  }
  if (filters.repoOwners.isNotEmpty &&
      !filters.repoOwners.contains(prRepoOwnerOf(pr))) {
    return false;
  }
  if (filters.repoNames.isNotEmpty &&
      !filters.repoNames.contains(prRepoNameOf(pr))) {
    return false;
  }
  final opened = filters.openedWithin;
  if (opened != null && !_withinWindow(pr.createdAt, opened)) {
    return false;
  }
  final updated = filters.updatedWithin;
  if (updated != null &&
      !_withinWindow(pr.updatedAt ?? pr.createdAt, updated)) {
    return false;
  }
  if (filters.quickToReview && !isQuickToReview(pr)) {
    return false;
  }
  return true;
}

/// Capsule-filters [prs] according to [filters] and [currentLogin] (see
/// [prPassesFilters] for the semantics of each axis).
List<PullRequest> applyFilters(
  List<PullRequest> prs, {
  required PrListFilters filters,
  required String currentLogin,
  bool includeDrafts = true,
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  if (!filters.isActive && includeDrafts) {
    return prs;
  }
  return [
    for (final pr in prs)
      if (prPassesFilters(
        pr,
        filters: filters,
        currentLogin: currentLogin,
        includeDrafts: includeDrafts,
        viewerTeamsByOrg: viewerTeamsByOrg,
      ))
        pr,
  ];
}

/// The operator's login **on the forge currently in view**, lowercased. Empty
/// when no identity has resolved for it.
///
/// There is no single "current login" any more: the same human is `octocat` on
/// GitHub and something else on GitLab, so a screen scoped to one PR must
/// compare against the login for *that PR's* forge. Using the GitHub login on a
/// GitLab merge request would mark the operator's own comments as someone
/// else's and hide "you approved this".
///
/// Outside a PR-scoped screen there is no repo to resolve through, so it falls
/// back to the only connected forge, then to GitHub — the ambiguity only
/// affects surfaces that are not about a specific PR. PR-scoped surfaces use
/// [currentUserLoginForPrProvider] instead, which resolves the forge from the
/// PR's own repo.
final currentUserLoginProvider = Provider<String>((ref) {
  final logins = ref.watch(viewerLoginsProvider);
  if (logins.isEmpty) {
    return '';
  }
  if (logins.length == 1) {
    return logins.values.first;
  }
  return logins[ForgeHost.github] ?? logins.values.first;
});

/// The operator's login on this [PrRef]'s own forge — the keyed counterpart of
/// [currentUserLoginProvider], resolving the forge from the PR's repo rather
/// than ambient state.
final currentUserLoginForPrProvider = Provider.autoDispose
    .family<String, PrRef>((ref, pr) {
      final logins = ref.watch(viewerLoginsProvider);
      if (logins.isEmpty) {
        return '';
      }
      final repo = ref.watch(prRepoRowProvider(pr));
      if (repo != null) {
        return logins[repo.forge] ?? '';
      }
      if (logins.length == 1) {
        return logins.values.first;
      }
      return logins[ForgeHost.github] ?? logins.values.first;
    });

/// Tracks which queue sections are currently collapsed. Keyed by `Repo.id`
/// when grouping by repository and by the group key (`author:<login>`,
/// `status:<name>`) for the other groupings, so state survives filter changes.
class CollapsedReposNotifier extends Notifier<Set<String>> {
  @override
  /// Builds the initial set (no sections collapsed).
  Set<String> build() => const {};

  /// Toggles the collapsed state of a queue section.
  void toggle(String repoId) {
    final next = Set<String>.from(state);
    if (!next.add(repoId)) {
      next.remove(repoId);
    }
    state = next;
  }

  /// Collapses a queue section.
  void collapse(String repoId) {
    state = Set<String>.from(state)..add(repoId);
  }

  /// Expands a queue section.
  void expand(String repoId) {
    state = Set<String>.from(state)..remove(repoId);
  }
}

/// Set of section keys collapsed in the queue. See [CollapsedReposNotifier].
final collapsedReposProvider =
    NotifierProvider<CollapsedReposNotifier, Set<String>>(
      CollapsedReposNotifier.new,
    );
