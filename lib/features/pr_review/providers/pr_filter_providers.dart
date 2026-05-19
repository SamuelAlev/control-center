import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable filter state for the PR list. Filters are additive: between
/// categories they AND together; within authors the selected logins OR
/// together. An empty authors set means no author filter.
class PrListFilters {
  /// Creates a [PrListFilters] with the given settings.
  const PrListFilters({
    this.awaitingReview = false,
    this.createdByMe = false,
    this.reviewedByMe = false,
    this.authors = const {},
  });

  /// Whether to show only PRs awaiting the operator's review.
  final bool awaitingReview;

  /// Whether to show only PRs authored by the operator.
  final bool createdByMe;

  /// Whether to show only PRs already reviewed by the operator.
  final bool reviewedByMe;

  /// Set of author logins to filter by (empty means no author filter).
  final Set<String> authors;

  /// Whether any filter is currently active.
  bool get isActive =>
      awaitingReview || createdByMe || reviewedByMe || authors.isNotEmpty;

  /// Total number of active filter criteria.
  int get count =>
      (awaitingReview ? 1 : 0) +
      (createdByMe ? 1 : 0) +
      (reviewedByMe ? 1 : 0) +
      authors.length;

  /// Returns a copy with the given fields replaced.
  PrListFilters copyWith({
    bool? awaitingReview,
    bool? createdByMe,
    bool? reviewedByMe,
    Set<String>? authors,
  }) {
    return PrListFilters(
      awaitingReview: awaitingReview ?? this.awaitingReview,
      createdByMe: createdByMe ?? this.createdByMe,
      reviewedByMe: reviewedByMe ?? this.reviewedByMe,
      authors: authors ?? this.authors,
    );
  }
}

/// Default filter applied on first render. The relationship filter rail has
/// been replaced by the queue's search field, so the list opens unfiltered
/// (all open PRs) and the search query is the sole narrowing axis.
const defaultPrListFilters = PrListFilters();

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

  /// Toggles an author login in the author filter set.
  void toggleAuthor(String login) {
    final next = Set<String>.from(state.authors);
    if (!next.add(login)) {
      next.remove(login);
    }
    state = state.copyWith(authors: next);
  }

  /// Clears all filters, restoring the default state.
  void clear() => state = const PrListFilters();
}

/// Provides global filter state for the by-repo PR list.
final prListFiltersProvider =
    NotifierProvider<PrListFiltersNotifier, PrListFilters>(
      PrListFiltersNotifier.new,
    );

/// Login of the currently authenticated GitHub user, lowercased. Empty when
/// no user is loaded.
final currentUserLoginProvider = Provider<String>((ref) {
  return ref
      .watch(githubUserProvider)
      .maybeWhen(
        data: (user) => user?.login.toLowerCase() ?? '',
        orElse: () => '',
      );
});

/// Tracks which repository sections are currently collapsed in the by-repo
/// list. Keyed by `Repo.id` so state survives filter changes.
class CollapsedReposNotifier extends Notifier<Set<String>> {
  @override
  /// Builds the initial set (no sections collapsed).
  Set<String> build() => const {};

  /// Toggles the collapsed state of a repository section.
  void toggle(String repoId) {
    final next = Set<String>.from(state);
    if (!next.add(repoId)) {
      next.remove(repoId);
    }
    state = next;
  }

  /// Collapses a repository section.
  void collapse(String repoId) {
    state = Set<String>.from(state)..add(repoId);
  }

  /// Expands a repository section.
  void expand(String repoId) {
    state = Set<String>.from(state)..remove(repoId);
  }
}

/// Set of repo IDs whose sections are collapsed in the by-repo list.
final collapsedReposProvider =
    NotifierProvider<CollapsedReposNotifier, Set<String>>(
      CollapsedReposNotifier.new,
    );
