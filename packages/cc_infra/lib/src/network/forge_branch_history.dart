/// The most pages a branch-history walk reads before giving up.
///
/// A branch with more PRs than this is pathological; failing loudly beats
/// returning a truncated history that a caller would read as "every PR from
/// this branch".
const int kMaxBranchHistoryPages = 100;

/// Walks one forge's branch-scoped pull-request listing to the end and keeps
/// the entries whose head ref is exactly [branch] (the forge's own filter may
/// be a prefix or case-insensitive match).
///
/// [fetchPage] is called with page numbers from 1 and answers that page plus
/// whether another follows. An entry with no identity or head ref throws a
/// [FormatException], and running past [kMaxBranchHistoryPages] a
/// [StateError]: a history the walk could not read completely must never look
/// like a complete one (`ForgeBranchPrHistoryClient`'s contract).
Future<List<T>> collectBranchHistory<T>({
  required String forgeName,
  required String branch,
  required Future<({List<T> items, bool hasMore})> Function(int page) fetchPage,
  required String Function(T item) headRefOf,
  required int Function(T item) numberOf,
}) async {
  final found = <T>[];
  for (var page = 1; page <= kMaxBranchHistoryPages; page++) {
    final batch = await fetchPage(page);
    for (final item in batch.items) {
      if (headRefOf(item).isEmpty || numberOf(item) <= 0) {
        throw FormatException(
          '$forgeName returned a pull request without an identity/head ref',
        );
      }
      if (headRefOf(item) == branch) {
        found.add(item);
      }
    }
    if (!batch.hasMore) {
      return found;
    }
  }
  throw StateError(
    '$forgeName branch PR history exceeded $kMaxBranchHistoryPages pages',
  );
}
