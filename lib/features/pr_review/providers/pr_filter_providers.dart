import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable filter state for the PR list. Filters are additive: between
/// categories they AND together; within authors the selected logins OR
/// together. An empty authors set means no author filter.
class PrListFilters {
  const PrListFilters({
    this.awaitingReview = false,
    this.createdByMe = false,
    this.reviewedByMe = false,
    this.authors = const {},
  });

  final bool awaitingReview;
  final bool createdByMe;
  final bool reviewedByMe;
  final Set<String> authors;

  bool get isActive =>
      awaitingReview || createdByMe || reviewedByMe || authors.isNotEmpty;

  int get count =>
      (awaitingReview ? 1 : 0) +
      (createdByMe ? 1 : 0) +
      (reviewedByMe ? 1 : 0) +
      authors.length;

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
  PrListFilters build() => defaultPrListFilters;

  void toggleAwaitingReview() =>
      state = state.copyWith(awaitingReview: !state.awaitingReview);

  void toggleCreatedByMe() =>
      state = state.copyWith(createdByMe: !state.createdByMe);

  void toggleReviewedByMe() =>
      state = state.copyWith(reviewedByMe: !state.reviewedByMe);

  void toggleAuthor(String login) {
    final next = Set<String>.from(state.authors);
    if (!next.add(login)) next.remove(login);
    state = state.copyWith(authors: next);
  }

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
  return ref.watch(githubUserProvider).maybeWhen(
    data: (user) => user?.login.toLowerCase() ?? '',
    orElse: () => '',
  );
});

/// Tracks which repository sections are currently collapsed in the by-repo
/// list. Keyed by `Repo.id` so state survives filter changes.
class CollapsedReposNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String repoId) {
    final next = Set<String>.from(state);
    if (!next.add(repoId)) next.remove(repoId);
    state = next;
  }

  void collapse(String repoId) {
    state = Set<String>.from(state)..add(repoId);
  }

  void expand(String repoId) {
    state = Set<String>.from(state)..remove(repoId);
  }
}

/// Set of repo IDs whose sections are collapsed in the by-repo list.
final collapsedReposProvider =
    NotifierProvider<CollapsedReposNotifier, Set<String>>(
      CollapsedReposNotifier.new,
    );
