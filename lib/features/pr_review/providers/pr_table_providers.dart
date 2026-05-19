import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One repo section of the repo-grouped PR table: the repo and the pull
/// requests that belong to it (already filtered for the surface; the section
/// card sorts them for display). Reuses [PrInboxItem] (`pr` + `repo`) as the
/// row model so the inbox row widget can render both surfaces.
typedef PrRepoSectionData = ({Repo repo, List<PrInboxItem> items});

/// Multi-select state for the repo-grouped PR table (queue + user profile).
///
/// Keyed by the item's stable `owner/repo#number` identity ([PrInboxItem.key]),
/// NOT by PR number: numbers are unique only *within* a repo, so a
/// number-keyed set would conflate two repos that each hold, say, PR #1. The
/// composite key keeps a cross-repo selection unambiguous, which the bulk
/// close / assign / request-review actions rely on to resolve each selected
/// key back to its `(pr, repo)`.
class PrTableSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Toggles whether [key] is selected.
  void toggle(String key) {
    final next = Set<String>.of(state);
    if (!next.add(key)) {
      next.remove(key);
    }
    state = next;
  }

  /// Adds every key in [keys] to the selection (e.g. a repo's "select all").
  void addAll(Iterable<String> keys) {
    state = {...state, ...keys};
  }

  /// Drops every key in [keys] from the selection (e.g. after they close away,
  /// or a repo's "deselect all").
  void removeAll(Iterable<String> keys) {
    if (state.isEmpty) {
      return;
    }
    state = Set<String>.of(state)..removeAll(keys);
  }

  /// Clears the selection, exiting selection mode.
  void clear() => state = const {};
}

/// Batch-selection state for the repo-grouped PR table. Selection mode is
/// *derived* (`state.isNotEmpty`) so it can never get stuck on with nothing
/// selected. The user-profile queue overrides this in its own [ProviderScope]
/// so browsing a profile never disturbs the main queue's selection.
final prTableSelectionProvider =
    NotifierProvider<PrTableSelectionNotifier, Set<String>>(
      PrTableSelectionNotifier.new,
    );
