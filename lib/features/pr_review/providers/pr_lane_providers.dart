import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ordering applied to the rows of a repo section in the PR table.
enum PrListSort {
  /// Most recently updated first (the default, mirrors fetch order).
  recent,

  /// Least recently updated first.
  oldest,

  /// Largest diff (additions + deletions) first.
  largest,
}

/// Provides the active row sort order. Seeds the shared PR-table column sort
/// (`inboxSortProvider`) and is the value the display-options "Ordering" select
/// drives; the user-profile queue overrides it in its own scope.
class PrListSortNotifier extends Notifier<PrListSort> {
  @override
  PrListSort build() => PrListSort.recent;

  /// Sets the active sort order.
  void set(PrListSort sort) => state = sort;
}

/// Provides the active row sort order.
final prListSortProvider = NotifierProvider<PrListSortNotifier, PrListSort>(
  PrListSortNotifier.new,
);
