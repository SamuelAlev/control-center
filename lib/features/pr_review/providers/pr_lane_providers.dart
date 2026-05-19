import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The active decision-lane filter for the PR queue. `null` means "all open
/// PRs" (no lane filter). Selecting a lane narrows the queue to that lane;
/// re-selecting the active lane clears the filter.
class DecisionLaneFilterNotifier extends Notifier<DecisionLane?> {
  @override
  DecisionLane? build() => null;

  /// Sets the active lane, or clears the filter when [lane] is null.
  void select(DecisionLane? lane) => state = lane;

  /// Toggles [lane]: activates it, or clears the filter if it's already active.
  void toggle(DecisionLane lane) => state = state == lane ? null : lane;

  /// Clears the lane filter (show all).
  void clear() => state = null;
}

/// Provides the active decision-lane filter.
final decisionLaneFilterProvider =
    NotifierProvider<DecisionLaneFilterNotifier, DecisionLane?>(
      DecisionLaneFilterNotifier.new,
    );

/// Ordering applied within each repo group of the PR queue.
enum PrListSort {
  /// Most recently updated first (the default, mirrors fetch order).
  recent,

  /// Least recently updated first.
  oldest,

  /// Largest diff (additions + deletions) first.
  largest,
}

/// Provides the active queue sort order.
class PrListSortNotifier extends Notifier<PrListSort> {
  @override
  PrListSort build() => PrListSort.recent;

  /// Sets the active sort order.
  void set(PrListSort sort) => state = sort;
}

/// Provides the active queue sort order.
final prListSortProvider = NotifierProvider<PrListSortNotifier, PrListSort>(
  PrListSortNotifier.new,
);

/// Multi-select state for batch operations on the PR queue.
class PrSelectionState {
  /// Creates a [PrSelectionState].
  const PrSelectionState({this.selected = const {}});

  /// The set of selected PR numbers.
  final Set<int> selected;

  /// Whether selection mode is active — i.e. at least one PR is selected.
  ///
  /// Selection mode is *derived* from the selection set rather than tracked
  /// separately, so it can never get stuck "on" with nothing selected. While
  /// active, every row's checkbox stays visible and a row tap toggles selection
  /// instead of opening the PR; deselecting the last PR returns the queue to its
  /// resting state (checkboxes on hover, taps open the PR).
  bool get selecting => selected.isNotEmpty;

  /// Whether no PR is selected.
  bool get isEmpty => selected.isEmpty;

  /// Whether [number] is currently selected.
  bool contains(int number) => selected.contains(number);
}

/// Drives the batch-selection checkboxes and the batch action bar.
class PrSelectionNotifier extends Notifier<PrSelectionState> {
  @override
  PrSelectionState build() => const PrSelectionState();

  /// Toggles whether [number] is selected.
  void toggle(int number) {
    final next = Set<int>.of(state.selected);
    if (!next.add(number)) {
      next.remove(number);
    }
    state = PrSelectionState(selected: next);
  }

  /// Drops [numbers] from the selection (e.g. after they merge away).
  void removeAll(Iterable<int> numbers) {
    if (state.selected.isEmpty) {
      return;
    }
    final next = Set<int>.of(state.selected)..removeAll(numbers);
    state = PrSelectionState(selected: next);
  }

  /// Clears the selection, exiting selection mode.
  void clear() => state = const PrSelectionState();
}

/// Provides batch-selection state for the PR queue.
final prSelectionProvider =
    NotifierProvider<PrSelectionNotifier, PrSelectionState>(
      PrSelectionNotifier.new,
    );

/// The set of PR numbers whose inline peek panel is expanded.
class PeekedPrsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  /// Expands or collapses the peek panel for [number].
  void toggle(int number) {
    final next = Set<int>.of(state);
    if (!next.add(number)) {
      next.remove(number);
    }
    state = next;
  }
}

/// Provides the set of PRs whose peek panel is expanded.
final peekedPrsProvider = NotifierProvider<PeekedPrsNotifier, Set<int>>(
  PeekedPrsNotifier.new,
);
